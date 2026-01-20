import {
  Controller,
  Post,
  Get,
  Delete,
  Patch,
  Param,
  Body,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
  Query,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { VideosService, VideoUploadDto } from './videos.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@Controller('api/videos')
@UseGuards(JwtAuthGuard, RolesGuard)
export class VideosController {
  constructor(private readonly videosService: VideosService) {}

  /**
   * Upload de vídeo para Azure Storage
   * POST /api/videos/upload
   */
  @Post('upload')
  @Roles('ADMIN', 'CLINIC_ADMIN')
  @UseInterceptors(
    FileInterceptor('video', {
      limits: {
        fileSize: 100 * 1024 * 1024, // 100MB
      },
      fileFilter: (req, file, callback) => {
        if (!file.mimetype.startsWith('video/')) {
          return callback(
            new BadRequestException('Only video files are allowed'),
            false,
          );
        }
        callback(null, true);
      },
    }),
  )
  async uploadVideo(
    @UploadedFile() file: Express.Multer.File,
    @Body('title') title: string,
    @Body('description') description: string,
    @Body('category') category: string,
    @Body('clinicId') clinicId: string,
    @CurrentUser() user: any,
  ) {
    if (!file) {
      throw new BadRequestException('Video file is required');
    }

    if (!title) {
      throw new BadRequestException('Title is required');
    }

    if (!clinicId) {
      throw new BadRequestException('Clinic ID is required');
    }

    const dto: VideoUploadDto = {
      title,
      description,
      category,
      clinicId,
      uploadedBy: user.id,
    };

    const video = await this.videosService.uploadVideo(file, dto);

    return {
      success: true,
      message: 'Video uploaded successfully',
      data: video,
    };
  }

  /**
   * Lista vídeos de uma clínica
   * GET /api/videos/clinic/:clinicId
   */
  @Get('clinic/:clinicId')
  @Roles('ADMIN', 'CLINIC_ADMIN', 'PATIENT')
  async getVideosByClinic(@Param('clinicId') clinicId: string) {
    const videos = await this.videosService.getVideosByClinic(clinicId);
    return {
      success: true,
      data: videos,
    };
  }

  /**
   * Busca um vídeo por ID
   * GET /api/videos/:id
   */
  @Get(':id')
  @Roles('ADMIN', 'CLINIC_ADMIN', 'PATIENT')
  async getVideoById(@Param('id') id: string) {
    const video = await this.videosService.getVideoById(id);
    return {
      success: true,
      data: video,
    };
  }

  /**
   * Atualiza informações de um vídeo
   * PATCH /api/videos/:id
   */
  @Patch(':id')
  @Roles('ADMIN', 'CLINIC_ADMIN')
  async updateVideo(
    @Param('id') id: string,
    @Body()
    body: {
      title?: string;
      description?: string;
      category?: string;
      isActive?: boolean;
      sortOrder?: number;
      duration?: number;
    },
  ) {
    const video = await this.videosService.updateVideo(id, body);
    return {
      success: true,
      message: 'Video updated successfully',
      data: video,
    };
  }

  /**
   * Deleta um vídeo
   * DELETE /api/videos/:id
   */
  @Delete(':id')
  @Roles('ADMIN', 'CLINIC_ADMIN')
  async deleteVideo(
    @Param('id') id: string,
    @Query('hard') hard: string,
  ) {
    const hardDelete = hard === 'true';
    await this.videosService.deleteVideo(id, hardDelete);
    return {
      success: true,
      message: hardDelete
        ? 'Video permanently deleted'
        : 'Video deactivated successfully',
    };
  }

  /**
   * Faz upload de legenda para um vídeo
   * POST /api/videos/:id/subtitle
   */
  @Post(':id/subtitle')
  @Roles('ADMIN', 'CLINIC_ADMIN')
  async uploadSubtitle(
    @Param('id') id: string,
    @Body('content') content: string,
    @Body('format') format: 'vtt' | 'srt',
  ) {
    if (!content) {
      throw new BadRequestException('Subtitle content is required');
    }

    const video = await this.videosService.uploadSubtitle(
      id,
      content,
      format || 'vtt',
    );

    return {
      success: true,
      message: 'Subtitle uploaded successfully',
      data: video,
    };
  }

  /**
   * Gera thumbnail para um vídeo existente
   * POST /api/videos/:id/generate-thumbnail
   */
  @Post(':id/generate-thumbnail')
  @Roles('ADMIN', 'CLINIC_ADMIN')
  async generateThumbnail(@Param('id') id: string) {
    const result = await this.videosService.regenerateThumbnail(id);
    return {
      success: result.success,
      message: result.message,
      thumbnailUrl: result.thumbnailUrl,
    };
  }

  /**
   * Gera thumbnails para todos os vídeos de uma clínica que não têm thumbnail
   * POST /api/videos/clinic/:clinicId/generate-thumbnails
   */
  @Post('clinic/:clinicId/generate-thumbnails')
  @Roles('ADMIN', 'CLINIC_ADMIN')
  async generateAllThumbnails(@Param('clinicId') clinicId: string) {
    const result = await this.videosService.generateMissingThumbnails(clinicId);
    return {
      success: true,
      message: `Thumbnails generation started for ${result.count} videos`,
      videoIds: result.videoIds,
    };
  }
}
