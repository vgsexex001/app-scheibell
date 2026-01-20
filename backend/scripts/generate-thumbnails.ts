/**
 * Script para gerar thumbnails de videos no Supabase
 * Usa ffmpeg para extrair um frame do video
 *
 * Uso: npx ts-node scripts/generate-thumbnails.ts [videoId]
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

// Configuracao
const SUPABASE_URL = process.env.SUPABASE_URL || 'https://tkzwxcsibamlkrtzzsew.supabase.co';
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRrend4Y3NpYmFtbGtydHp6c2V3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc5NTkzMzAsImV4cCI6MjA4MzUzNTMzMH0.5t_914orQU4Hyucf0Af8CjRom94cg7uHLd5atgUmKco';

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

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
          if (fs.existsSync(destPath)) fs.unlinkSync(destPath);
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

// Gerar thumbnail usando ffmpeg
async function generateThumbnail(videoPath: string, thumbnailPath: string): Promise<void> {
  // Captura frame no segundo 1 do video, redimensiona para 640px de largura
  const ffmpegPath = '/opt/homebrew/bin/ffmpeg';
  const command = `${ffmpegPath} -i "${videoPath}" -ss 1 -vframes 1 -vf "scale=640:-1" -y "${thumbnailPath}"`;

  try {
    await execAsync(command, { timeout: 30000 });
  } catch (error: any) {
    // Se falhar no segundo 1, tenta no segundo 0
    const fallbackCommand = `${ffmpegPath} -i "${videoPath}" -ss 0 -vframes 1 -vf "scale=640:-1" -y "${thumbnailPath}"`;
    await execAsync(fallbackCommand, { timeout: 30000 });
  }
}

// Funcao principal
async function generateThumbnails(videoId?: string) {
  console.log('🖼️  Gerador de Thumbnails para Videos\n');

  // Buscar videos sem thumbnail ou especifico
  let query = supabase
    .from('clinic_videos')
    .select('*');

  if (videoId) {
    query = query.eq('id', videoId);
  } else {
    // Buscar videos sem thumbnail
    query = query.is('thumbnailUrl', null);
  }

  const { data: videos, error } = await query;

  if (error) {
    console.error('❌ Erro ao buscar videos:', error);
    return;
  }

  if (!videos || videos.length === 0) {
    console.log('ℹ️  Nenhum video sem thumbnail encontrado');
    return;
  }

  console.log(`📹 Encontrados ${videos.length} video(s) para processar\n`);

  const tempDir = path.join(process.cwd(), 'temp');
  if (!fs.existsSync(tempDir)) {
    fs.mkdirSync(tempDir, { recursive: true });
  }

  for (const video of videos) {
    console.log(`\n🎥 Processando: ${video.title}`);
    console.log(`   ID: ${video.id}`);
    console.log(`   URL: ${video.videoUrl}`);

    const videoPath = path.join(tempDir, `${video.id}.mp4`);
    const thumbnailPath = path.join(tempDir, `${video.id}_thumb.jpg`);

    try {
      // 1. Baixar video
      console.log('   📥 Baixando video...');
      await downloadFile(video.videoUrl, videoPath);

      // 2. Verificar se o download foi bem sucedido
      if (!fs.existsSync(videoPath)) {
        throw new Error('Falha no download do video');
      }

      const stats = fs.statSync(videoPath);
      console.log(`   📁 Tamanho do video: ${(stats.size / 1024 / 1024).toFixed(2)} MB`);

      // 3. Gerar thumbnail
      console.log('   🖼️  Gerando thumbnail...');
      await generateThumbnail(videoPath, thumbnailPath);

      // 4. Verificar se a thumbnail foi gerada
      if (!fs.existsSync(thumbnailPath)) {
        throw new Error('Falha ao gerar thumbnail');
      }

      // 5. Upload para Supabase Storage
      console.log('   ☁️  Enviando para Supabase Storage...');
      const storagePath = `thumbnails/${video.clinicId}/${video.id}.jpg`;

      const { error: uploadError } = await supabase.storage
        .from('media')
        .upload(storagePath, fs.readFileSync(thumbnailPath), {
          contentType: 'image/jpeg',
          upsert: true,
        });

      if (uploadError) {
        throw new Error(`Upload failed: ${uploadError.message}`);
      }

      const { data: urlData } = supabase.storage
        .from('media')
        .getPublicUrl(storagePath);

      // 6. Atualizar registro no banco
      const { error: updateError } = await supabase
        .from('clinic_videos')
        .update({
          thumbnailUrl: urlData.publicUrl,
        })
        .eq('id', video.id);

      if (updateError) {
        throw new Error(`Update failed: ${updateError.message}`);
      }

      console.log('   ✅ Thumbnail gerada com sucesso!');
      console.log(`   🔗 URL: ${urlData.publicUrl}`);

    } catch (error: any) {
      console.error(`   ❌ Erro: ${error.message}`);
    } finally {
      // Limpar arquivos temporarios
      [videoPath, thumbnailPath].forEach(file => {
        if (fs.existsSync(file)) {
          try {
            fs.unlinkSync(file);
          } catch (e) {
            // Ignorar erros de limpeza
          }
        }
      });
    }
  }

  console.log('\n🏁 Processamento concluido!');
}

// Executar
const videoId = process.argv[2];
generateThumbnails(videoId).catch(console.error);
