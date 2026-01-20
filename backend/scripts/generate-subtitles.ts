/**
 * Script para gerar legendas de vídeos no Supabase
 * Usa OpenAI Whisper API para transcrição
 *
 * Uso: npx ts-node scripts/generate-subtitles.ts [videoId]
 */

import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs';
import * as path from 'path';
import * as https from 'https';
import * as http from 'http';
import { exec } from 'child_process';
import { promisify } from 'util';
import * as dotenv from 'dotenv';

dotenv.config();

const execAsync = promisify(exec);

// Configuração
const SUPABASE_URL = process.env.SUPABASE_URL || 'https://tkzwxcsibamlkrtzzsew.supabase.co';
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRrend4Y3NpYmFtbGtydHp6c2V3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc5NTkzMzAsImV4cCI6MjA4MzUzNTMzMH0.5t_914orQU4Hyucf0Af8CjRom94cg7uHLd5atgUmKco';
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

if (!OPENAI_API_KEY) {
  console.error('❌ OPENAI_API_KEY não configurada no .env');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

interface WhisperSegment {
  start: number;
  end: number;
  text: string;
}

interface WhisperResponse {
  language: string;
  duration: number;
  text: string;
  segments: WhisperSegment[];
}

// Baixar arquivo
function downloadFile(url: string, destPath: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(destPath);
    const protocol = url.startsWith('https') ? https : http;

    protocol.get(url, (response) => {
      if (response.statusCode === 301 || response.statusCode === 302) {
        const redirectUrl = response.headers.location;
        if (redirectUrl) {
          file.close();
          fs.unlinkSync(destPath);
          return downloadFile(redirectUrl, destPath).then(resolve).catch(reject);
        }
      }

      response.pipe(file);
      file.on('finish', () => {
        file.close();
        resolve();
      });
    }).on('error', (err) => {
      fs.unlink(destPath, () => {});
      reject(err);
    });
  });
}

// Extrair áudio usando ffmpeg (qualidade alta para melhor transcrição)
async function extractAudio(videoPath: string, audioPath: string): Promise<void> {
  // Usar qualidade alta (-q:a 2) e sample rate de 16kHz (ideal para Whisper)
  const command = `/opt/homebrew/bin/ffmpeg -i "${videoPath}" -vn -acodec libmp3lame -q:a 2 -ar 16000 -ac 1 -y "${audioPath}"`;
  await execAsync(command);
}

// Transcrever com Whisper
async function transcribeWithWhisper(audioPath: string): Promise<WhisperResponse> {
  const FormDataModule = await import('form-data');
  const FormData = FormDataModule.default || FormDataModule;
  const form = new FormData();

  form.append('file', fs.createReadStream(audioPath));
  form.append('model', 'whisper-1');
  form.append('response_format', 'verbose_json');
  form.append('language', 'pt');
  // Prompt para melhorar a transcrição em português brasileiro
  form.append('prompt', 'Transcrição em português brasileiro. Recuperação pós-operatória, cirurgia plástica, cuidados médicos.');

  return new Promise((resolve, reject) => {
    const req = https.request({
      hostname: 'api.openai.com',
      path: '/v1/audio/transcriptions',
      method: 'POST',
      headers: {
        ...form.getHeaders(),
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
      },
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          if (res.statusCode !== 200) {
            reject(new Error(`Whisper API error: ${res.statusCode} - ${data}`));
            return;
          }
          resolve(JSON.parse(data));
        } catch (e) {
          reject(new Error(`Failed to parse Whisper response: ${e}`));
        }
      });
    });

    req.on('error', reject);
    form.pipe(req);
  });
}

// Converter para VTT
function convertToVTT(transcription: WhisperResponse): string {
  let vtt = 'WEBVTT\n\n';

  if (!transcription.segments || transcription.segments.length === 0) {
    vtt += `1\n00:00:00.000 --> 00:00:30.000\n${transcription.text}\n`;
    return vtt;
  }

  transcription.segments.forEach((segment, index) => {
    const startTime = formatVTTTime(segment.start);
    const endTime = formatVTTTime(segment.end);
    const text = segment.text.trim();

    vtt += `${index + 1}\n`;
    vtt += `${startTime} --> ${endTime}\n`;
    vtt += `${text}\n\n`;
  });

  return vtt;
}

function formatVTTTime(seconds: number): string {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = Math.floor(seconds % 60);
  const ms = Math.round((seconds % 1) * 1000);

  return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}.${ms.toString().padStart(3, '0')}`;
}

// Função principal
async function generateSubtitles(videoId?: string) {
  console.log('🎬 Gerador de Legendas Automáticas\n');

  // Buscar vídeos pendentes ou específico
  let query = supabase
    .from('clinic_videos')
    .select('*');

  if (videoId) {
    query = query.eq('id', videoId);
  } else {
    query = query.eq('subtitle_status', 'PENDING');
  }

  const { data: videos, error } = await query;

  if (error) {
    console.error('❌ Erro ao buscar vídeos:', error);
    return;
  }

  if (!videos || videos.length === 0) {
    console.log('ℹ️  Nenhum vídeo pendente encontrado');
    return;
  }

  console.log(`📹 Encontrados ${videos.length} vídeo(s) para processar\n`);

  const tempDir = path.join(process.cwd(), 'temp');
  if (!fs.existsSync(tempDir)) {
    fs.mkdirSync(tempDir, { recursive: true });
  }

  for (const video of videos) {
    console.log(`\n🎥 Processando: ${video.title}`);
    console.log(`   ID: ${video.id}`);

    const videoPath = path.join(tempDir, `${video.id}.mp4`);
    const audioPath = path.join(tempDir, `${video.id}.mp3`);
    const vttPath = path.join(tempDir, `${video.id}.vtt`);

    try {
      // Atualizar status para PROCESSING
      await supabase
        .from('clinic_videos')
        .update({ subtitle_status: 'PROCESSING' })
        .eq('id', video.id);

      // 1. Baixar vídeo
      console.log('   📥 Baixando vídeo...');
      await downloadFile(video.videoUrl, videoPath);

      // 2. Extrair áudio
      console.log('   🔊 Extraindo áudio...');
      await extractAudio(videoPath, audioPath);

      // 3. Transcrever com Whisper
      console.log('   🤖 Transcrevendo com Whisper...');
      const transcription = await transcribeWithWhisper(audioPath);
      console.log(`   📝 Texto: "${transcription.text.substring(0, 100)}..."`);

      // 4. Converter para VTT
      console.log('   📄 Gerando arquivo VTT...');
      const vttContent = convertToVTT(transcription);
      fs.writeFileSync(vttPath, vttContent, 'utf8');

      // 5. Upload para Supabase Storage
      console.log('   ☁️  Enviando para Supabase Storage...');
      const storagePath = `subtitles/${video.clinicId}/${video.id}.vtt`;

      const { error: uploadError } = await supabase.storage
        .from('media')
        .upload(storagePath, fs.readFileSync(vttPath), {
          contentType: 'text/vtt',
          upsert: true,
        });

      if (uploadError) {
        throw new Error(`Upload failed: ${uploadError.message}`);
      }

      const { data: urlData } = supabase.storage
        .from('media')
        .getPublicUrl(storagePath);

      // 6. Atualizar registro no banco
      await supabase
        .from('clinic_videos')
        .update({
          subtitle_url: urlData.publicUrl,
          subtitle_status: 'COMPLETED',
        })
        .eq('id', video.id);

      console.log('   ✅ Legendas geradas com sucesso!');
      console.log(`   🔗 URL: ${urlData.publicUrl}`);

    } catch (error: any) {
      console.error(`   ❌ Erro: ${error.message}`);

      await supabase
        .from('clinic_videos')
        .update({
          subtitle_status: 'FAILED',
        })
        .eq('id', video.id);

    } finally {
      // Limpar arquivos temporários
      [videoPath, audioPath, vttPath].forEach(file => {
        if (fs.existsSync(file)) {
          fs.unlinkSync(file);
        }
      });
    }
  }

  console.log('\n🏁 Processamento concluído!');
}

// Executar
const videoId = process.argv[2];
generateSubtitles(videoId).catch(console.error);
