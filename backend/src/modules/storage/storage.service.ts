import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

export interface UploadResult {
  path: string;
  publicUrl: string;
}

@Injectable()
export class StorageService implements OnModuleInit {
  private supabase: SupabaseClient | null = null;
  private readonly logger = new Logger(StorageService.name);
  private isConfigured = false;

  constructor(private configService: ConfigService) {}

  onModuleInit() {
    const supabaseUrl = this.configService.get<string>('SUPABASE_URL');
    const supabaseKey = this.configService.get<string>('SUPABASE_SERVICE_KEY');

    if (supabaseUrl && supabaseKey) {
      this.supabase = createClient(supabaseUrl, supabaseKey);
      this.isConfigured = true;
      this.logger.log('Supabase Storage initialized');
    } else {
      this.logger.warn('Supabase Storage not configured - SUPABASE_URL and SUPABASE_SERVICE_KEY required');
    }
  }

  /**
   * Verifica se o storage está configurado
   */
  isAvailable(): boolean {
    return this.isConfigured;
  }

  /**
   * Upload de arquivo para o bucket de chat-attachments
   */
  async uploadChatAttachment(
    file: Buffer,
    filename: string,
    conversationId: string,
    mimeType: string,
  ): Promise<UploadResult> {
    return this.uploadFile('chat-attachments', `${conversationId}/${filename}`, file, mimeType);
  }

  /**
   * Upload de arquivo de exame
   */
  async uploadExamFile(
    file: Buffer,
    filename: string,
    patientId: string,
    mimeType: string,
  ): Promise<UploadResult> {
    return this.uploadFile('exam-files', `${patientId}/${filename}`, file, mimeType);
  }

  /**
   * Upload de documento do paciente
   */
  async uploadPatientDocument(
    file: Buffer,
    filename: string,
    patientId: string,
    mimeType: string,
  ): Promise<UploadResult> {
    return this.uploadFile('patient-documents', `${patientId}/${filename}`, file, mimeType);
  }

  /**
   * Upload genérico de arquivo
   */
  async uploadFile(
    bucket: string,
    path: string,
    file: Buffer,
    mimeType: string,
  ): Promise<UploadResult> {
    if (!this.supabase) {
      throw new Error('Supabase Storage not configured');
    }

    const { data, error } = await this.supabase.storage
      .from(bucket)
      .upload(path, file, {
        contentType: mimeType,
        upsert: true,
      });

    if (error) {
      this.logger.error(`Upload failed: ${error.message}`);
      throw new Error(`Upload failed: ${error.message}`);
    }

    const { data: urlData } = this.supabase.storage
      .from(bucket)
      .getPublicUrl(data.path);

    return {
      path: data.path,
      publicUrl: urlData.publicUrl,
    };
  }

  /**
   * Gera URL assinada temporária para download
   */
  async getSignedUrl(bucket: string, path: string, expiresIn = 3600): Promise<string> {
    if (!this.supabase) {
      throw new Error('Supabase Storage not configured');
    }

    const { data, error } = await this.supabase.storage
      .from(bucket)
      .createSignedUrl(path, expiresIn);

    if (error) {
      this.logger.error(`Failed to create signed URL: ${error.message}`);
      throw new Error(`Failed to create signed URL: ${error.message}`);
    }

    return data.signedUrl;
  }

  /**
   * Deleta um arquivo
   */
  async deleteFile(bucket: string, path: string): Promise<void> {
    if (!this.supabase) {
      throw new Error('Supabase Storage not configured');
    }

    const { error } = await this.supabase.storage
      .from(bucket)
      .remove([path]);

    if (error) {
      this.logger.error(`Delete failed: ${error.message}`);
      throw new Error(`Delete failed: ${error.message}`);
    }
  }

  /**
   * Lista arquivos em um diretório
   */
  async listFiles(bucket: string, folder: string): Promise<string[]> {
    if (!this.supabase) {
      throw new Error('Supabase Storage not configured');
    }

    const { data, error } = await this.supabase.storage
      .from(bucket)
      .list(folder);

    if (error) {
      this.logger.error(`List failed: ${error.message}`);
      throw new Error(`List failed: ${error.message}`);
    }

    return data.map(file => `${folder}/${file.name}`);
  }

  /**
   * Download de arquivo como Buffer
   */
  async downloadFile(bucket: string, path: string): Promise<Buffer> {
    if (!this.supabase) {
      throw new Error('Supabase Storage not configured');
    }

    const { data, error } = await this.supabase.storage
      .from(bucket)
      .download(path);

    if (error) {
      this.logger.error(`Download failed: ${error.message}`);
      throw new Error(`Download failed: ${error.message}`);
    }

    const arrayBuffer = await data.arrayBuffer();
    return Buffer.from(arrayBuffer);
  }
}
