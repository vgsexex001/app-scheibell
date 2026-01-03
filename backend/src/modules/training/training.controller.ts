import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { TrainingService } from './training.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { CompleteSessionDto } from './dto/complete-session.dto';

@Controller('training')
@UseGuards(JwtAuthGuard)
export class TrainingController {
  constructor(private trainingService: TrainingService) {}

  /**
   * Retorna o dashboard completo de treino do paciente
   * GET /api/training/dashboard
   */
  @Get('dashboard')
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async getDashboard(@CurrentUser('patientId') patientId: string) {
    return this.trainingService.getTrainingDashboard(patientId);
  }

  /**
   * Retorna o protocolo de treino (formato legado para front-end)
   * GET /api/training/protocol
   */
  @Get('protocol')
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async getProtocol(@CurrentUser('patientId') patientId: string) {
    return this.trainingService.getTrainingProtocol(patientId);
  }

  /**
   * Retorna o progresso geral do paciente
   * GET /api/training/progress
   */
  @Get('progress')
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async getProgress(@CurrentUser('patientId') patientId: string) {
    return this.trainingService.getProgress(patientId);
  }

  /**
   * Retorna detalhes de uma semana específica
   * GET /api/training/weeks/:weekNumber
   */
  @Get('weeks/:weekNumber')
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async getWeekDetails(
    @CurrentUser('patientId') patientId: string,
    @Param('weekNumber') weekNumber: string,
  ) {
    return this.trainingService.getWeekDetails(patientId, parseInt(weekNumber));
  }

  /**
   * Marca uma sessão como concluída
   * POST /api/training/sessions/:sessionId/complete
   */
  @Post('sessions/:sessionId/complete')
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async completeSession(
    @CurrentUser('patientId') patientId: string,
    @Param('sessionId') sessionId: string,
    @Body() dto: CompleteSessionDto,
  ) {
    return this.trainingService.completeSession(patientId, sessionId, dto.notes);
  }

  /**
   * Remove a conclusão de uma sessão
   * DELETE /api/training/sessions/:sessionId/complete
   */
  @Delete('sessions/:sessionId/complete')
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async uncompleteSession(
    @CurrentUser('patientId') patientId: string,
    @Param('sessionId') sessionId: string,
  ) {
    return this.trainingService.uncompleteSession(patientId, sessionId);
  }
}
