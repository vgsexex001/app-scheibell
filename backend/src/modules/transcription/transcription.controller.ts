import {
  Controller,
  Get,
  Post,
  Param,
  UseGuards,
} from '@nestjs/common';
import { TranscriptionService } from './transcription.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

@Controller('api/transcription')
@UseGuards(JwtAuthGuard, RolesGuard)
export class TranscriptionController {
  constructor(private readonly transcriptionService: TranscriptionService) {}

  /**
   * Obtém status da transcrição de um vídeo
   */
  @Get('status/:videoId')
  @Roles('ADMIN', 'CLINIC_ADMIN', 'PATIENT')
  async getStatus(@Param('videoId') videoId: string) {
    return this.transcriptionService.getTranscriptionStatus(videoId);
  }

  /**
   * Reprocessa transcrição de um vídeo (retry)
   */
  @Post('retry/:videoId')
  @Roles('ADMIN', 'CLINIC_ADMIN')
  async retryTranscription(@Param('videoId') videoId: string) {
    return this.transcriptionService.retryTranscription(videoId);
  }

  /**
   * Inicia transcrição manualmente para um vídeo
   */
  @Post('start/:videoId')
  @Roles('ADMIN', 'CLINIC_ADMIN')
  async startTranscription(@Param('videoId') videoId: string) {
    await this.transcriptionService.startTranscription(videoId);
    return { success: true, message: 'Transcription started' };
  }
}
