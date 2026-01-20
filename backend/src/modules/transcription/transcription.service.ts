import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ConfigService } from '@nestjs/config';
import * as fs from 'fs';
import * as path from 'path';
import * as https from 'https';
import * as http from 'http';
import { exec } from 'child_process';
import { promisify } from 'util';
import { AzureStorageService } from '../../common/services/azure-storage.service';

const execAsync = promisify(exec);

interface WhisperSegment {
  id: number;
  seek: number;
  start: number;
  end: number;
  text: string;
  tokens: number[];
  temperature: number;
  avg_logprob: number;
  compression_ratio: number;
  no_speech_prob: number;
}

interface WhisperResponse {
  task: string;
  language: string;
  duration: number;
  text: string;
  segments: WhisperSegment[];
}

@Injectable()
export class TranscriptionService {
  private readonly logger = new Logger(TranscriptionService.name);
  private readonly openaiApiKey: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    private readonly azureStorage: AzureStorageService,
  ) {
    this.openaiApiKey = this.configService.get<string>('OPENAI_API_KEY') || '';
  }

  /**
   * Inicia o processo de transcrição para um vídeo
   * Executa em background (não bloqueia)
   */
  async startTranscription(videoId: string): Promise<void> {
    if (!this.openaiApiKey) {
      this.logger.warn('OPENAI_API_KEY not configured, skipping transcription');
      return;
    }

    // Atualiza status para PROCESSING
    await this.prisma.clinicVideo.update({
      where: { id: videoId },
      data: { subtitleStatus: 'PROCESSING' },
    });

    // Executa transcrição em background
    this.processTranscription(videoId).catch((error) => {
      this.logger.error(`Transcription failed for video ${videoId}:`, error);
    });
  }

  /**
   * Processo completo de transcrição
   */
  private async processTranscription(videoId: string): Promise<void> {
    const tempDir = path.join(process.cwd(), 'temp');
    const audioPath = path.join(tempDir, `${videoId}.mp3`);

    try {
      // Busca informações do vídeo
      const video = await this.prisma.clinicVideo.findUnique({
        where: { id: videoId },
      });

      if (!video) {
        throw new Error('Video not found');
      }

      this.logger.log(`Starting transcription for video: ${video.title}`);

      // Cria diretório temporário
      if (!fs.existsSync(tempDir)) {
        fs.mkdirSync(tempDir, { recursive: true });
      }

      // 1. Baixa o vídeo e extrai áudio
      this.logger.log('Extracting audio from video...');
      await this.extractAudio(video.videoUrl, audioPath);

      // 2. Envia para Whisper API
      this.logger.log('Sending to Whisper API...');
      const transcription = await this.transcribeWithWhisper(audioPath);

      // 3. Converte para formato VTT
      this.logger.log('Converting to VTT format...');
      const vttContent = this.convertToVTT(transcription);

      // 4. Faz upload do arquivo VTT diretamente para Azure (sem salvar em disco)
      this.logger.log('Uploading subtitle file...');
      const subtitleUrl = await this.uploadSubtitleContent(vttContent, video.clinicId, videoId);

      // 5. Atualiza registro do vídeo
      await this.prisma.clinicVideo.update({
        where: { id: videoId },
        data: {
          subtitleUrl,
          subtitleStatus: 'COMPLETED',
          subtitleLanguage: transcription.language || 'pt',
          subtitleError: null,
        },
      });

      this.logger.log(`Transcription completed for video: ${video.title}`);
    } catch (error) {
      this.logger.error(`Transcription error for video ${videoId}:`, error);

      // Atualiza status com erro
      await this.prisma.clinicVideo.update({
        where: { id: videoId },
        data: {
          subtitleStatus: 'FAILED',
          subtitleError: error.message || 'Transcription failed',
        },
      });
    } finally {
      // Limpa arquivos temporários (apenas áudio, VTT agora é enviado direto pro Azure)
      this.cleanupTempFiles([audioPath]);
    }
  }

  /**
   * Extrai áudio do vídeo usando ffmpeg
   */
  private async extractAudio(videoUrl: string, outputPath: string): Promise<void> {
    // Primeiro baixa o vídeo
    const videoPath = outputPath.replace('.mp3', '.mp4');
    await this.downloadFile(videoUrl, videoPath);

    try {
      // Extrai áudio usando ffmpeg (qualidade alta para melhor transcrição)
      // -q:a 2 = qualidade alta, -ar 16000 = sample rate ideal para Whisper, -ac 1 = mono
      const command = `ffmpeg -i "${videoPath}" -vn -acodec libmp3lame -q:a 2 -ar 16000 -ac 1 -y "${outputPath}"`;
      await execAsync(command);
    } catch (error) {
      // Se ffmpeg não estiver instalado, tenta usar o vídeo diretamente
      // O Whisper aceita arquivos de vídeo também
      this.logger.warn('ffmpeg not available, using video file directly');
      fs.copyFileSync(videoPath, outputPath.replace('.mp3', '.mp4'));
      throw new Error('ffmpeg not installed. Please install ffmpeg to extract audio.');
    } finally {
      // Remove arquivo de vídeo temporário
      if (fs.existsSync(videoPath)) {
        fs.unlinkSync(videoPath);
      }
    }
  }

  /**
   * Baixa arquivo de uma URL
   */
  private downloadFile(url: string, destPath: string): Promise<void> {
    return new Promise((resolve, reject) => {
      const file = fs.createWriteStream(destPath);
      const protocol = url.startsWith('https') ? https : http;

      protocol.get(url, (response) => {
        // Handle redirects
        if (response.statusCode === 301 || response.statusCode === 302) {
          const redirectUrl = response.headers.location;
          if (redirectUrl) {
            file.close();
            fs.unlinkSync(destPath);
            return this.downloadFile(redirectUrl, destPath).then(resolve).catch(reject);
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

  /**
   * Envia áudio para OpenAI Whisper API
   */
  private async transcribeWithWhisper(audioPath: string): Promise<WhisperResponse> {
    const FormData = (await import('form-data')).default;
    const form = new FormData();

    // Verifica se é mp3 ou mp4
    const filePath = fs.existsSync(audioPath)
      ? audioPath
      : audioPath.replace('.mp3', '.mp4');

    form.append('file', fs.createReadStream(filePath));
    form.append('model', 'whisper-1');
    form.append('response_format', 'verbose_json');
    form.append('language', 'pt'); // Português
    // Prompt para melhorar a transcrição em português brasileiro
    form.append('prompt', 'Transcrição em português brasileiro. Recuperação pós-operatória, cirurgia plástica, cuidados médicos.');

    return new Promise((resolve, reject) => {
      const req = https.request({
        hostname: 'api.openai.com',
        path: '/v1/audio/transcriptions',
        method: 'POST',
        headers: {
          ...form.getHeaders(),
          'Authorization': `Bearer ${this.openaiApiKey}`,
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
            const result = JSON.parse(data);
            resolve(result);
          } catch (e) {
            reject(new Error(`Failed to parse Whisper response: ${e.message}`));
          }
        });
      });

      req.on('error', reject);
      form.pipe(req);
    });
  }

  /**
   * Converte resposta do Whisper para formato WebVTT
   */
  private convertToVTT(transcription: WhisperResponse): string {
    let vtt = 'WEBVTT\n\n';

    if (!transcription.segments || transcription.segments.length === 0) {
      // Se não houver segmentos, cria um único bloco com todo o texto
      vtt += `1\n00:00:00.000 --> 00:00:30.000\n${transcription.text}\n`;
      return vtt;
    }

    transcription.segments.forEach((segment, index) => {
      const startTime = this.formatVTTTime(segment.start);
      const endTime = this.formatVTTTime(segment.end);
      const text = segment.text.trim();

      vtt += `${index + 1}\n`;
      vtt += `${startTime} --> ${endTime}\n`;
      vtt += `${text}\n\n`;
    });

    return vtt;
  }

  /**
   * Formata tempo para formato VTT (HH:MM:SS.mmm)
   */
  private formatVTTTime(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    const ms = Math.round((seconds % 1) * 1000);

    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}.${ms.toString().padStart(3, '0')}`;
  }

  /**
   * Faz upload do conteúdo de legendas para Azure Blob Storage
   * @param vttContent Conteúdo do arquivo VTT em UTF-8
   * @param clinicId ID da clínica
   * @param videoId ID do vídeo
   */
  private async uploadSubtitleContent(
    vttContent: string,
    clinicId: string,
    videoId: string,
  ): Promise<string> {
    // Upload direto para Azure Blob Storage (sem salvar em disco)
    // O conteúdo já está em UTF-8 na memória
    const result = await this.azureStorage.uploadSubtitle(
      vttContent,
      clinicId,
      videoId,
      'vtt',
    );

    this.logger.log(`Subtitle uploaded to Azure: ${result.url}`);
    return result.url;
  }

  /**
   * Remove arquivos temporários
   */
  private cleanupTempFiles(files: string[]): void {
    for (const file of files) {
      try {
        if (fs.existsSync(file)) {
          fs.unlinkSync(file);
        }
        // Também tenta remover versão .mp4
        const mp4File = file.replace('.mp3', '.mp4');
        if (fs.existsSync(mp4File)) {
          fs.unlinkSync(mp4File);
        }
      } catch (e) {
        this.logger.warn(`Failed to cleanup temp file ${file}: ${e.message}`);
      }
    }
  }

  /**
   * Reprocessa transcrição de um vídeo (retry manual)
   */
  async retryTranscription(videoId: string): Promise<{ success: boolean; message: string }> {
    const video = await this.prisma.clinicVideo.findUnique({
      where: { id: videoId },
    });

    if (!video) {
      return { success: false, message: 'Video not found' };
    }

    if (!this.openaiApiKey) {
      return { success: false, message: 'OpenAI API key not configured' };
    }

    // Inicia nova transcrição
    await this.startTranscription(videoId);

    return { success: true, message: 'Transcription started' };
  }

  /**
   * Obtém status da transcrição de um vídeo
   */
  async getTranscriptionStatus(videoId: string): Promise<{
    status: string;
    subtitleUrl?: string;
    error?: string;
    language?: string;
  }> {
    const video = await this.prisma.clinicVideo.findUnique({
      where: { id: videoId },
      select: {
        subtitleStatus: true,
        subtitleUrl: true,
        subtitleError: true,
        subtitleLanguage: true,
      },
    });

    if (!video) {
      return { status: 'NOT_FOUND' };
    }

    return {
      status: video.subtitleStatus,
      subtitleUrl: video.subtitleUrl || undefined,
      error: video.subtitleError || undefined,
      language: video.subtitleLanguage || undefined,
    };
  }
}
