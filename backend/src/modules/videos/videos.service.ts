import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AzureStorageService } from '../../common/services/azure-storage.service';
import { MediaCategory } from '@prisma/client';
import { exec } from 'child_process';
import { promisify } from 'util';
import * as fs from 'fs';
import * as path from 'path';

const execAsync = promisify(exec);

export interface VideoUploadDto {
  title: string;
  description?: string;
  category?: string;
  clinicId: string;
  uploadedBy: string;
}

// Mapear string para MediaCategory
function mapCategory(category?: string): MediaCategory {
  const categoryMap: Record<string, MediaCategory> = {
    'GERAL': MediaCategory.GERAL,
    'EXERCICIO': MediaCategory.EXERCICIO,
    'POS_OPERATORIO': MediaCategory.POS_OPERATORIO,
    'ORIENTACAO': MediaCategory.ORIENTACAO,
    'CONSENTIMENTO': MediaCategory.CONSENTIMENTO,
    'RESULTADO': MediaCategory.RESULTADO,
  };
  return categoryMap[category?.toUpperCase() || ''] || MediaCategory.GERAL;
}

export interface VideoResponse {
  id: string;
  clinicId: string;
  title: string;
  description: string | null;
  videoUrl: string;
  thumbnailUrl: string | null;
  category: string;
  duration: number;
  isActive: boolean;
  sortOrder: number;
  subtitleStatus: string;
  subtitleUrl: string | null;
  createdAt: Date;
  updatedAt: Date;
}

@Injectable()
export class VideosService {
  private readonly logger = new Logger(VideosService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly azureStorage: AzureStorageService,
  ) {}

  /**
   * Faz upload de um vídeo para o Azure e salva no banco
   */
  async uploadVideo(
    file: Express.Multer.File,
    dto: VideoUploadDto,
  ): Promise<VideoResponse> {
    this.logger.log(`Uploading video: ${dto.title} for clinic ${dto.clinicId}`);

    // Fazer upload para Azure
    const { url } = await this.azureStorage.uploadVideo(
      file.buffer,
      dto.clinicId,
      file.originalname,
    );

    this.logger.log(`Video uploaded to Azure: ${url}`);

    // Contar vídeos existentes para sortOrder
    const videoCount = await this.prisma.clinicVideo.count({
      where: { clinicId: dto.clinicId },
    });

    // Salvar no banco de dados
    const video = await this.prisma.clinicVideo.create({
      data: {
        clinic: { connect: { id: dto.clinicId } },
        title: dto.title,
        description: dto.description || null,
        videoUrl: url,
        category: mapCategory(dto.category),
        duration: 0,
        isActive: true,
        sortOrder: videoCount,
        uploadedBy: dto.uploadedBy ? { connect: { id: dto.uploadedBy } } : undefined,
        subtitleStatus: 'PENDING',
        thumbnailUrl: null,
      },
    });

    this.logger.log(`Video saved to database: ${video.id}`);

    // Gerar thumbnail em background (não bloqueia o upload)
    this.generateThumbnailInBackground(video.id, url, dto.clinicId);

    return this.mapToResponse(video);
  }

  /**
   * Gera thumbnail do vídeo em background
   */
  private async generateThumbnailInBackground(
    videoId: string,
    videoUrl: string,
    clinicId: string,
  ): Promise<void> {
    try {
      this.logger.log(`Starting thumbnail generation for video ${videoId}`);
      const thumbnailUrl = await this.generateThumbnail(videoUrl, clinicId, videoId);

      if (thumbnailUrl) {
        await this.prisma.clinicVideo.update({
          where: { id: videoId },
          data: { thumbnailUrl },
        });
        this.logger.log(`Thumbnail generated and saved for video ${videoId}: ${thumbnailUrl}`);
      }
    } catch (error) {
      this.logger.error(`Failed to generate thumbnail for video ${videoId}:`, error);
    }
  }

  /**
   * Gera thumbnail de um vídeo usando ffmpeg
   */
  private async generateThumbnail(
    videoUrl: string,
    clinicId: string,
    videoId: string,
  ): Promise<string | null> {
    const tempDir = path.join(process.cwd(), 'temp');
    const thumbnailPath = path.join(tempDir, `${videoId}_thumb.jpg`);

    try {
      // Criar diretório temporário se não existir
      if (!fs.existsSync(tempDir)) {
        fs.mkdirSync(tempDir, { recursive: true });
      }

      // Gerar thumbnail no segundo 1 do vídeo (ou primeiro frame se muito curto)
      // -ss 1: pula para 1 segundo
      // -vframes 1: captura apenas 1 frame
      // -vf scale=640:-1: redimensiona para 640px de largura mantendo proporção
      const command = `ffmpeg -i "${videoUrl}" -ss 1 -vframes 1 -vf "scale=640:-1" -y "${thumbnailPath}"`;

      await execAsync(command, { timeout: 30000 });

      // Verificar se o arquivo foi criado
      if (!fs.existsSync(thumbnailPath)) {
        this.logger.warn(`Thumbnail file not created for video ${videoId}`);
        return null;
      }

      // Ler o arquivo e fazer upload para Azure
      const thumbnailBuffer = fs.readFileSync(thumbnailPath);
      const { url } = await this.azureStorage.uploadThumbnail(
        thumbnailBuffer,
        clinicId,
        videoId,
      );

      return url;
    } catch (error) {
      this.logger.error(`Error generating thumbnail: ${error.message}`);
      return null;
    } finally {
      // Limpar arquivo temporário
      if (fs.existsSync(thumbnailPath)) {
        try {
          fs.unlinkSync(thumbnailPath);
        } catch (e) {
          this.logger.warn(`Failed to cleanup thumbnail temp file: ${e.message}`);
        }
      }
    }
  }

  /**
   * Lista vídeos de uma clínica
   */
  async getVideosByClinic(clinicId: string): Promise<VideoResponse[]> {
    const videos = await this.prisma.clinicVideo.findMany({
      where: {
        clinicId,
        isActive: true,
      },
      orderBy: { sortOrder: 'asc' },
    });

    return videos.map((v) => this.mapToResponse(v));
  }

  /**
   * Busca um vídeo por ID
   */
  async getVideoById(id: string): Promise<VideoResponse> {
    const video = await this.prisma.clinicVideo.findUnique({
      where: { id },
    });

    if (!video) {
      throw new NotFoundException('Video not found');
    }

    return this.mapToResponse(video);
  }

  /**
   * Atualiza informações de um vídeo
   */
  async updateVideo(
    id: string,
    data: Partial<{
      title: string;
      description: string;
      category: string;
      isActive: boolean;
      sortOrder: number;
      duration: number;
    }>,
  ): Promise<VideoResponse> {
    // Preparar dados para atualização com tipos corretos
    const updateData: any = { ...data };
    if (data.category) {
      updateData.category = mapCategory(data.category);
    }

    const video = await this.prisma.clinicVideo.update({
      where: { id },
      data: updateData,
    });

    return this.mapToResponse(video);
  }

  /**
   * Deleta um vídeo (soft delete ou hard delete com remoção do Azure)
   */
  async deleteVideo(id: string, hardDelete = false): Promise<void> {
    const video = await this.prisma.clinicVideo.findUnique({
      where: { id },
    });

    if (!video) {
      throw new NotFoundException('Video not found');
    }

    if (hardDelete) {
      // Extrair blob path da URL e deletar do Azure
      if (video.videoUrl) {
        const blobPath = this.azureStorage.extractBlobPath(video.videoUrl);
        if (blobPath) {
          await this.azureStorage.deleteVideoFiles(video.clinicId, id, blobPath);
        }
      }

      // Deletar do banco
      await this.prisma.clinicVideo.delete({
        where: { id },
      });
    } else {
      // Soft delete
      await this.prisma.clinicVideo.update({
        where: { id },
        data: { isActive: false },
      });
    }
  }

  /**
   * Atualiza a URL da legenda de um vídeo
   */
  async updateSubtitle(
    id: string,
    subtitleUrl: string,
    status: 'PENDING' | 'PROCESSING' | 'COMPLETED' | 'FAILED',
  ): Promise<VideoResponse> {
    const video = await this.prisma.clinicVideo.update({
      where: { id },
      data: {
        subtitleUrl,
        subtitleStatus: status,
      },
    });

    return this.mapToResponse(video);
  }

  /**
   * Faz upload de legenda para Azure e atualiza o vídeo
   */
  async uploadSubtitle(
    videoId: string,
    content: string,
    format: 'vtt' | 'srt' = 'vtt',
  ): Promise<VideoResponse> {
    const video = await this.prisma.clinicVideo.findUnique({
      where: { id: videoId },
    });

    if (!video) {
      throw new NotFoundException('Video not found');
    }

    // Upload para Azure
    const { url } = await this.azureStorage.uploadSubtitle(
      content,
      video.clinicId,
      videoId,
      format,
    );

    // Atualizar vídeo
    return this.updateSubtitle(videoId, url, 'COMPLETED');
  }

  /**
   * Regenera thumbnail para um vídeo existente
   */
  async regenerateThumbnail(videoId: string): Promise<{
    success: boolean;
    message: string;
    thumbnailUrl?: string;
  }> {
    const video = await this.prisma.clinicVideo.findUnique({
      where: { id: videoId },
    });

    if (!video) {
      return { success: false, message: 'Video not found' };
    }

    if (!video.videoUrl) {
      return { success: false, message: 'Video URL not found' };
    }

    try {
      const thumbnailUrl = await this.generateThumbnail(
        video.videoUrl,
        video.clinicId,
        videoId,
      );

      if (thumbnailUrl) {
        await this.prisma.clinicVideo.update({
          where: { id: videoId },
          data: { thumbnailUrl },
        });

        return {
          success: true,
          message: 'Thumbnail generated successfully',
          thumbnailUrl,
        };
      }

      return { success: false, message: 'Failed to generate thumbnail' };
    } catch (error) {
      this.logger.error(`Error regenerating thumbnail for video ${videoId}:`, error);
      return { success: false, message: error.message || 'Thumbnail generation failed' };
    }
  }

  /**
   * Gera thumbnails para todos os vídeos de uma clínica que não têm thumbnail
   */
  async generateMissingThumbnails(clinicId: string): Promise<{
    count: number;
    videoIds: string[];
  }> {
    // Busca vídeos sem thumbnail
    const videosWithoutThumbnail = await this.prisma.clinicVideo.findMany({
      where: {
        clinicId,
        isActive: true,
        OR: [
          { thumbnailUrl: null },
          { thumbnailUrl: '' },
        ],
      },
      select: {
        id: true,
        videoUrl: true,
      },
    });

    const videoIds = videosWithoutThumbnail.map((v) => v.id);

    // Gera thumbnails em background para cada vídeo
    for (const video of videosWithoutThumbnail) {
      if (video.videoUrl) {
        this.generateThumbnailInBackground(video.id, video.videoUrl, clinicId);
      }
    }

    return {
      count: videoIds.length,
      videoIds,
    };
  }

  private mapToResponse(video: any): VideoResponse {
    return {
      id: video.id,
      clinicId: video.clinicId,
      title: video.title,
      description: video.description,
      videoUrl: video.videoUrl,
      thumbnailUrl: video.thumbnailUrl,
      category: video.category,
      duration: video.duration,
      isActive: video.isActive,
      sortOrder: video.sortOrder,
      subtitleStatus: video.subtitleStatus || 'PENDING',
      subtitleUrl: video.subtitleUrl,
      createdAt: video.createdAt,
      updatedAt: video.updatedAt,
    };
  }
}
