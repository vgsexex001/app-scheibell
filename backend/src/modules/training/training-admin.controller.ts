import {
  Controller,
  Get,
  Post,
  Put,
  Patch,
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
import {
  UpdateWeekDto,
  CreateSessionDto,
  UpdateSessionDto,
  ReorderSessionsDto,
  CreatePatientAdjustmentDto,
} from './dto';

@Controller('training/admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
export class TrainingAdminController {
  constructor(private trainingService: TrainingService) {}

  /**
   * Lista todos os protocolos da clínica
   * GET /api/training/admin/protocols
   */
  @Get('protocols')
  async getProtocols(@CurrentUser('clinicId') clinicId: string) {
    return this.trainingService.getProtocolsForAdmin(clinicId);
  }

  /**
   * Obtém detalhes de um protocolo com todas as semanas e sessões
   * GET /api/training/admin/protocols/:protocolId
   */
  @Get('protocols/:protocolId')
  async getProtocolDetails(
    @Param('protocolId') protocolId: string,
    @CurrentUser('clinicId') clinicId: string,
  ) {
    return this.trainingService.getProtocolDetailsForAdmin(protocolId, clinicId);
  }

  /**
   * Lista todas as semanas de um protocolo
   * GET /api/training/admin/protocols/:protocolId/weeks
   */
  @Get('protocols/:protocolId/weeks')
  async getWeeks(
    @Param('protocolId') protocolId: string,
    @CurrentUser('clinicId') clinicId: string,
  ) {
    return this.trainingService.getWeeksForAdmin(protocolId, clinicId);
  }

  /**
   * Obtém detalhes de uma semana específica
   * GET /api/training/admin/weeks/:weekId
   */
  @Get('weeks/:weekId')
  async getWeekDetails(
    @Param('weekId') weekId: string,
    @CurrentUser('clinicId') clinicId: string,
  ) {
    return this.trainingService.getWeekDetailsForAdmin(weekId, clinicId);
  }

  /**
   * Atualiza uma semana
   * PATCH /api/training/admin/weeks/:weekId
   */
  @Patch('weeks/:weekId')
  async updateWeek(
    @Param('weekId') weekId: string,
    @Body() dto: UpdateWeekDto,
    @CurrentUser('clinicId') clinicId: string,
  ) {
    return this.trainingService.updateWeekForAdmin(weekId, dto, clinicId);
  }

  /**
   * Cria uma nova sessão em uma semana
   * POST /api/training/admin/sessions
   */
  @Post('sessions')
  async createSession(
    @Body() dto: CreateSessionDto,
    @CurrentUser('clinicId') clinicId: string,
  ) {
    return this.trainingService.createSessionForAdmin(dto, clinicId);
  }

  /**
   * Atualiza uma sessão
   * PATCH /api/training/admin/sessions/:sessionId
   */
  @Patch('sessions/:sessionId')
  async updateSession(
    @Param('sessionId') sessionId: string,
    @Body() dto: UpdateSessionDto,
    @CurrentUser('clinicId') clinicId: string,
  ) {
    return this.trainingService.updateSessionForAdmin(sessionId, dto, clinicId);
  }

  /**
   * Remove uma sessão
   * DELETE /api/training/admin/sessions/:sessionId
   */
  @Delete('sessions/:sessionId')
  async deleteSession(
    @Param('sessionId') sessionId: string,
    @CurrentUser('clinicId') clinicId: string,
  ) {
    return this.trainingService.deleteSessionForAdmin(sessionId, clinicId);
  }

  /**
   * Reordena as sessões de uma semana
   * PUT /api/training/admin/weeks/:weekId/reorder
   */
  @Put('weeks/:weekId/reorder')
  async reorderSessions(
    @Param('weekId') weekId: string,
    @Body() dto: ReorderSessionsDto,
    @CurrentUser('clinicId') clinicId: string,
  ) {
    return this.trainingService.reorderSessionsForAdmin(weekId, dto.sessionIds, clinicId);
  }

  // ==================== PERSONALIZAÇÕES POR PACIENTE ====================

  /**
   * Lista pacientes com seus status de treino
   * GET /api/training/admin/patients
   */
  @Get('patients')
  async getPatientsTrainingStatus(@CurrentUser('clinicId') clinicId: string) {
    return this.trainingService.getPatientsTrainingStatus(clinicId);
  }

  /**
   * Obtém o treino de um paciente específico
   * GET /api/training/admin/patients/:patientId
   */
  @Get('patients/:patientId')
  async getPatientTraining(
    @Param('patientId') patientId: string,
    @CurrentUser('clinicId') clinicId: string,
  ) {
    return this.trainingService.getPatientTrainingForAdmin(patientId, clinicId);
  }

  /**
   * Cria uma personalização de treino para um paciente
   * POST /api/training/admin/patients/:patientId/adjustments
   */
  @Post('patients/:patientId/adjustments')
  async createPatientAdjustment(
    @Param('patientId') patientId: string,
    @Body() dto: CreatePatientAdjustmentDto,
    @CurrentUser('clinicId') clinicId: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.trainingService.createPatientAdjustment(patientId, dto, clinicId, userId);
  }

  /**
   * Remove uma personalização de treino
   * DELETE /api/training/admin/adjustments/:adjustmentId
   */
  @Delete('adjustments/:adjustmentId')
  async deletePatientAdjustment(
    @Param('adjustmentId') adjustmentId: string,
    @CurrentUser('clinicId') clinicId: string,
  ) {
    return this.trainingService.deletePatientAdjustment(adjustmentId, clinicId);
  }
}
