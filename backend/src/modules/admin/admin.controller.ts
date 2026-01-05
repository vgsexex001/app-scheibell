import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  ParseIntPipe,
  DefaultValuePipe,
} from '@nestjs/common';
import { AdminService } from './admin.service';
import { AlertService } from './services/alert.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { ApproveAppointmentDto, RejectAppointmentDto, CreateAlertDto } from './dto';
import { AlertStatus } from '@prisma/client';

@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
export class AdminController {
  constructor(
    private adminService: AdminService,
    private alertService: AlertService,
  ) {}

  /**
   * Retorna o resumo do dashboard (indicadores)
   * GET /api/admin/dashboard/summary
   */
  @Get('dashboard/summary')
  async getDashboardSummary(@CurrentUser('clinicId') clinicId: string) {
    return this.adminService.getDashboardSummary(clinicId);
  }

  /**
   * Lista consultas pendentes de aprovação
   * GET /api/admin/appointments/pending
   */
  @Get('appointments/pending')
  async getPendingAppointments(
    @CurrentUser('clinicId') clinicId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number,
  ) {
    return this.adminService.getPendingAppointments(clinicId, page, limit);
  }

  /**
   * Aprova uma consulta
   * POST /api/admin/appointments/:id/approve
   */
  @Post('appointments/:id/approve')
  async approveAppointment(
    @Param('id') appointmentId: string,
    @CurrentUser('clinicId') clinicId: string,
    @CurrentUser('sub') userId: string,
    @Body() dto: ApproveAppointmentDto,
  ) {
    return this.adminService.approveAppointment(
      appointmentId,
      clinicId,
      userId,
      dto.notes,
    );
  }

  /**
   * Rejeita uma consulta
   * POST /api/admin/appointments/:id/reject
   */
  @Post('appointments/:id/reject')
  async rejectAppointment(
    @Param('id') appointmentId: string,
    @CurrentUser('clinicId') clinicId: string,
    @CurrentUser('sub') userId: string,
    @Body() dto: RejectAppointmentDto,
  ) {
    return this.adminService.rejectAppointment(
      appointmentId,
      clinicId,
      userId,
      dto.reason,
    );
  }

  /**
   * Lista pacientes em recuperação
   * GET /api/admin/recovery/patients
   */
  @Get('recovery/patients')
  async getRecoveryPatients(
    @CurrentUser('clinicId') clinicId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number,
  ) {
    return this.adminService.getRecoveryPatients(clinicId, page, limit);
  }

  // ==================== ALERTAS ====================

  /**
   * Lista alertas da clínica
   * GET /api/admin/alerts
   */
  @Get('alerts')
  async getAlerts(
    @CurrentUser('clinicId') clinicId: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number,
    @Query('status') status?: AlertStatus,
  ) {
    return this.alertService.getAlerts(clinicId, page, limit, status);
  }

  /**
   * Cria um alerta manual
   * POST /api/admin/alerts
   */
  @Post('alerts')
  async createAlert(
    @CurrentUser('clinicId') clinicId: string,
    @CurrentUser('sub') userId: string,
    @Body() dto: CreateAlertDto,
  ) {
    return this.alertService.createAlert(clinicId, userId, dto);
  }

  /**
   * Resolve um alerta
   * PATCH /api/admin/alerts/:id/resolve
   */
  @Patch('alerts/:id/resolve')
  async resolveAlert(
    @Param('id') alertId: string,
    @CurrentUser('clinicId') clinicId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.alertService.resolveAlert(alertId, clinicId, userId);
  }

  /**
   * Dispensa um alerta (ignora)
   * PATCH /api/admin/alerts/:id/dismiss
   */
  @Patch('alerts/:id/dismiss')
  async dismissAlert(
    @Param('id') alertId: string,
    @CurrentUser('clinicId') clinicId: string,
    @CurrentUser('sub') userId: string,
  ) {
    return this.alertService.dismissAlert(alertId, clinicId, userId);
  }

  /**
   * Executa verificação de alertas automáticos
   * POST /api/admin/alerts/check
   */
  @Post('alerts/check')
  @Roles('CLINIC_ADMIN')
  async checkAlerts(@CurrentUser('clinicId') clinicId: string) {
    return this.alertService.checkAndGenerateAlerts(clinicId);
  }
}
