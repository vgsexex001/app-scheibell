import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  BadRequestException,
} from '@nestjs/common';
import { AppointmentsService } from './appointments.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { CreateAppointmentDto, UpdateStatusDto } from './dto';
import { AppointmentStatus } from '@prisma/client';

@Controller('appointments')
@UseGuards(JwtAuthGuard)
export class AppointmentsController {
  constructor(private appointmentsService: AppointmentsService) {}

  /**
   * Lista todas as consultas do paciente logado
   * GET /api/appointments
   */
  @Get()
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async getMyAppointments(
    @CurrentUser('patientId') patientId: string,
    @Query('status') status?: AppointmentStatus,
  ) {
    if (!patientId) {
      throw new BadRequestException('Perfil de paciente não encontrado. Por favor, entre em contato com a clínica.');
    }
    return this.appointmentsService.getPatientAppointments(patientId, status);
  }

  /**
   * Lista próximas consultas (para o dashboard)
   * GET /api/appointments/upcoming
   */
  @Get('upcoming')
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async getUpcomingAppointments(
    @CurrentUser('patientId') patientId: string,
    @Query('limit') limit?: string,
  ) {
    if (!patientId) {
      return []; // Retorna lista vazia se não tem patientId
    }
    const limitNum = limit ? parseInt(limit) : 5;
    return this.appointmentsService.getUpcomingAppointments(patientId, limitNum);
  }

  /**
   * Lista histórico completo de agendamentos do paciente
   * GET /api/appointments/history
   */
  @Get('history')
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async getAppointmentHistory(@CurrentUser('patientId') patientId: string) {
    if (!patientId) {
      return []; // Retorna lista vazia se não tem patientId
    }
    return this.appointmentsService.getAppointmentHistory(patientId);
  }

  /**
   * Lista agendamentos da equipe (CONFIRMED futuros)
   * GET /api/appointments/team
   */
  @Get('team')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  @UseGuards(RolesGuard)
  async getTeamAppointments(
    @CurrentUser('clinicId') clinicId: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.appointmentsService.getTeamAppointments(clinicId, startDate, endDate);
  }

  // ==================== SLOTS E DISPONIBILIDADE ====================
  // IMPORTANTE: Essas rotas devem vir ANTES de @Get(':id') para não serem capturadas como parâmetro

  /**
   * Lista horários disponíveis para uma data específica
   * GET /api/appointments/available-slots?date=2024-01-15
   */
  @Get('available-slots')
  async getAvailableSlots(
    @CurrentUser('clinicId') clinicId: string,
    @Query('date') date: string,
    @Query('appointmentType') appointmentType?: string,
  ) {
    if (!date) {
      throw new BadRequestException('O parâmetro date é obrigatório (formato: YYYY-MM-DD)');
    }
    return this.appointmentsService.getAvailableSlots(clinicId, date, appointmentType);
  }

  /**
   * Lista dias disponíveis em um período (para calendário)
   * GET /api/appointments/available-days?startDate=2024-01-01&endDate=2024-01-31
   */
  @Get('available-days')
  async getAvailableDays(
    @CurrentUser('clinicId') clinicId: string,
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
    @Query('appointmentType') appointmentType?: string,
  ) {
    if (!startDate || !endDate) {
      throw new BadRequestException('Os parâmetros startDate e endDate são obrigatórios (formato: YYYY-MM-DD)');
    }
    return this.appointmentsService.getAvailableDays(clinicId, startDate, endDate, appointmentType);
  }

  /**
   * Busca uma consulta específica
   * GET /api/appointments/:id
   */
  @Get(':id')
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async getAppointment(
    @Param('id') id: string,
    @CurrentUser('patientId') patientId: string,
  ) {
    return this.appointmentsService.getAppointmentById(id, patientId);
  }

  /**
   * Cria uma nova consulta
   * POST /api/appointments
   * - PATIENT: cria para si mesmo (patientId do token)
   * - CLINIC_ADMIN/CLINIC_STAFF: cria para qualquer paciente (patientId do body)
   */
  @Post()
  @Roles('PATIENT', 'CLINIC_ADMIN', 'CLINIC_STAFF')
  @UseGuards(RolesGuard)
  async createAppointment(
    @CurrentUser('patientId') tokenPatientId: string,
    @CurrentUser('role') role: string,
    @Body() dto: CreateAppointmentDto & { patientId?: string },
  ) {
    // Se for admin/staff, usa patientId do body; se for patient, usa do token
    const targetPatientId = (role === 'CLINIC_ADMIN' || role === 'CLINIC_STAFF')
      ? dto.patientId
      : tokenPatientId;

    if (!targetPatientId) {
      throw new BadRequestException('patientId é obrigatório');
    }

    return this.appointmentsService.createAppointment(targetPatientId, dto);
  }

  /**
   * Atualiza o status de uma consulta
   * PATCH /api/appointments/:id/status
   */
  @Patch(':id/status')
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async updateStatus(
    @Param('id') id: string,
    @CurrentUser('patientId') patientId: string,
    @Body() dto: UpdateStatusDto,
  ) {
    return this.appointmentsService.updateStatus(id, patientId, dto);
  }

  /**
   * Cancela uma consulta (atalho)
   * PATCH /api/appointments/:id/cancel
   */
  @Patch(':id/cancel')
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async cancelAppointment(
    @Param('id') id: string,
    @CurrentUser('patientId') patientId: string,
  ) {
    return this.appointmentsService.cancelAppointment(id, patientId);
  }

  /**
   * Confirma uma consulta (atalho)
   * PATCH /api/appointments/:id/confirm
   */
  @Patch(':id/confirm')
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async confirmAppointment(
    @Param('id') id: string,
    @CurrentUser('patientId') patientId: string,
  ) {
    return this.appointmentsService.confirmAppointment(id, patientId);
  }
}
