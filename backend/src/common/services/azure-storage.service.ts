import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  BlobServiceClient,
  ContainerClient,
} from '@azure/storage-blob';
import * as path from 'path';

@Injectable()
export class AzureStorageService {
  private readonly logger = new Logger(AzureStorageService.name);
  private blobServiceClient: BlobServiceClient | null = null;
  private containerClient: ContainerClient | null = null;
  private readonly containerName: string;
  private readonly accountName: string;
  private readonly baseUrl: string;

  constructor(private readonly configService: ConfigService) {
    this.accountName = this.configService.get<string>('AZURE_STORAGE_ACCOUNT_NAME') || '';
    this.containerName = this.configService.get<string>('AZURE_STORAGE_CONTAINER') || 'clinic-videos';
    this.baseUrl = this.configService.get<string>('AZURE_STORAGE_URL') || '';

    const connectionString = this.configService.get<string>('AZURE_STORAGE_CONNECTION_STRING');

    if (connectionString) {
      try {
        this.blobServiceClient = BlobServiceClient.fromConnectionString(connectionString);
        this.containerClient = this.blobServiceClient.getContainerClient(this.containerName);
        this.logger.log(`Azure Storage initialized: ${this.accountName}/${this.containerName}`);
      } catch (error) {
        this.logger.error('Failed to initialize Azure Storage:', error);
      }
    } else {
      this.logger.warn('Azure Storage not configured - AZURE_STORAGE_CONNECTION_STRING missing');
    }
  }

  /**
   * Verifica se o Azure Storage está configurado
   */
  isConfigured(): boolean {
    return this.blobServiceClient !== null && this.containerClient !== null;
  }

  /**
   * Faz upload de um vídeo para o Azure Blob Storage
   * @param file Buffer ou caminho do arquivo
   * @param clinicId ID da clínica
   * @param originalFilename Nome original do arquivo
   * @returns URL pública do vídeo
   */
  async uploadVideo(
    file: Buffer | string,
    clinicId: string,
    originalFilename: string,
  ): Promise<{ url: string; blobPath: string }> {
    if (!this.containerClient) {
      throw new Error('Azure Storage not configured');
    }

    // Gerar nome único para o blob
    const timestamp = Date.now();
    const sanitizedFilename = this.sanitizeFilename(originalFilename);
    const extension = path.extname(sanitizedFilename) || '.mp4';
    const blobName = `clinic-${clinicId}/videos/${timestamp}_${path.basename(sanitizedFilename, extension)}${extension}`;

    this.logger.log(`Uploading video to Azure: ${blobName}`);

    const blockBlobClient = this.containerClient.getBlockBlobClient(blobName);

    // Upload do arquivo
    let fileBuffer: Buffer;
    if (typeof file === 'string') {
      // Se for caminho do arquivo, ler o conteúdo
      const fs = await import('fs');
      fileBuffer = fs.readFileSync(file);
    } else {
      fileBuffer = file;
    }

    // Determinar content type
    const contentType = this.getContentType(extension);

    await blockBlobClient.uploadData(fileBuffer, {
      blobHTTPHeaders: {
        blobContentType: contentType,
      },
    });

    // Retornar URL pública
    const url = `${this.baseUrl}/${this.containerName}/${blobName}`;

    this.logger.log(`Video uploaded successfully: ${url}`);

    return {
      url,
      blobPath: blobName,
    };
  }

  /**
   * Faz upload de um arquivo de legenda para o Azure Blob Storage
   * @param file Buffer ou conteúdo da legenda
   * @param clinicId ID da clínica
   * @param videoId ID do vídeo
   * @param format Formato da legenda (vtt ou srt)
   * @returns URL pública da legenda
   */
  async uploadSubtitle(
    file: Buffer | string,
    clinicId: string,
    videoId: string,
    format: 'vtt' | 'srt' = 'vtt',
  ): Promise<{ url: string; blobPath: string }> {
    if (!this.containerClient) {
      throw new Error('Azure Storage not configured');
    }

    const blobName = `clinic-${clinicId}/subtitles/${videoId}.${format}`;

    this.logger.log(`Uploading subtitle to Azure: ${blobName}`);

    const blockBlobClient = this.containerClient.getBlockBlobClient(blobName);

    // Converter para Buffer UTF-8 se for string (importante para acentos)
    const fileBuffer = typeof file === 'string' ? Buffer.from(file, 'utf-8') : file;

    // Content-Type com charset=utf-8 para garantir encoding correto dos acentos
    const contentType = format === 'vtt'
      ? 'text/vtt; charset=utf-8'
      : 'application/x-subrip; charset=utf-8';

    await blockBlobClient.uploadData(fileBuffer, {
      blobHTTPHeaders: {
        blobContentType: contentType,
        blobContentDisposition: 'inline',
        blobContentEncoding: 'utf-8',
      },
    });

    const url = `${this.baseUrl}/${this.containerName}/${blobName}`;

    this.logger.log(`Subtitle uploaded successfully: ${url}`);

    return {
      url,
      blobPath: blobName,
    };
  }

  /**
   * Faz upload de uma thumbnail para o Azure Blob Storage
   * @param file Buffer da imagem
   * @param clinicId ID da clínica
   * @param videoId ID do vídeo
   * @returns URL pública da thumbnail
   */
  async uploadThumbnail(
    file: Buffer,
    clinicId: string,
    videoId: string,
  ): Promise<{ url: string; blobPath: string }> {
    if (!this.containerClient) {
      throw new Error('Azure Storage not configured');
    }

    const blobName = `clinic-${clinicId}/thumbnails/${videoId}.jpg`;

    this.logger.log(`Uploading thumbnail to Azure: ${blobName}`);

    const blockBlobClient = this.containerClient.getBlockBlobClient(blobName);

    await blockBlobClient.uploadData(file, {
      blobHTTPHeaders: {
        blobContentType: 'image/jpeg',
      },
    });

    const url = `${this.baseUrl}/${this.containerName}/${blobName}`;

    this.logger.log(`Thumbnail uploaded successfully: ${url}`);

    return {
      url,
      blobPath: blobName,
    };
  }

  /**
   * Deleta um blob do Azure Storage
   * @param blobPath Caminho do blob (ex: clinic-xxx/videos/123_video.mp4)
   */
  async deleteBlob(blobPath: string): Promise<boolean> {
    if (!this.containerClient) {
      throw new Error('Azure Storage not configured');
    }

    try {
      this.logger.log(`Deleting blob from Azure: ${blobPath}`);

      const blockBlobClient = this.containerClient.getBlockBlobClient(blobPath);
      await blockBlobClient.deleteIfExists();

      this.logger.log(`Blob deleted successfully: ${blobPath}`);
      return true;
    } catch (error) {
      this.logger.error(`Failed to delete blob ${blobPath}:`, error);
      return false;
    }
  }

  /**
   * Deleta todos os arquivos de um vídeo (vídeo, thumbnail, legenda)
   * @param clinicId ID da clínica
   * @param videoId ID do vídeo
   * @param videoBlobPath Caminho do blob do vídeo
   */
  async deleteVideoFiles(
    clinicId: string,
    videoId: string,
    videoBlobPath?: string,
  ): Promise<void> {
    const deletions: Promise<boolean>[] = [];

    // Deletar vídeo se o path foi fornecido
    if (videoBlobPath) {
      deletions.push(this.deleteBlob(videoBlobPath));
    }

    // Deletar thumbnail
    deletions.push(this.deleteBlob(`clinic-${clinicId}/thumbnails/${videoId}.jpg`));

    // Deletar legendas (ambos formatos)
    deletions.push(this.deleteBlob(`clinic-${clinicId}/subtitles/${videoId}.vtt`));
    deletions.push(this.deleteBlob(`clinic-${clinicId}/subtitles/${videoId}.srt`));

    await Promise.all(deletions);
  }

  /**
   * Gera URL com SAS token para acesso temporário
   * @param blobPath Caminho do blob
   * @returns URL com SAS token
   */
  getUrlWithSas(blobPath: string): string {
    const sasToken = this.configService.get<string>('AZURE_STORAGE_SAS_TOKEN');
    if (sasToken) {
      return `${this.baseUrl}/${this.containerName}/${blobPath}?${sasToken}`;
    }
    return `${this.baseUrl}/${this.containerName}/${blobPath}`;
  }

  /**
   * Extrai o blob path de uma URL completa
   * @param url URL completa do Azure
   * @returns Blob path ou null
   */
  extractBlobPath(url: string): string | null {
    if (!url || !url.includes(this.containerName)) {
      return null;
    }

    const containerPath = `/${this.containerName}/`;
    const startIndex = url.indexOf(containerPath);
    if (startIndex === -1) {
      return null;
    }

    let blobPath = url.substring(startIndex + containerPath.length);

    // Remover query string (SAS token)
    const queryIndex = blobPath.indexOf('?');
    if (queryIndex !== -1) {
      blobPath = blobPath.substring(0, queryIndex);
    }

    return blobPath;
  }

  /**
   * Sanitiza o nome do arquivo removendo caracteres especiais
   */
  private sanitizeFilename(filename: string): string {
    return filename
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '') // Remove acentos
      .replace(/[^a-zA-Z0-9._-]/g, '_') // Substitui caracteres especiais
      .replace(/_+/g, '_') // Remove underscores duplicados
      .toLowerCase();
  }

  /**
   * Retorna o content type baseado na extensão
   */
  private getContentType(extension: string): string {
    const contentTypes: Record<string, string> = {
      '.mp4': 'video/mp4',
      '.webm': 'video/webm',
      '.mov': 'video/quicktime',
      '.avi': 'video/x-msvideo',
      '.mkv': 'video/x-matroska',
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.vtt': 'text/vtt',
      '.srt': 'application/x-subrip',
    };

    return contentTypes[extension.toLowerCase()] || 'application/octet-stream';
  }
}
