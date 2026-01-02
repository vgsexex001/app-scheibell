import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
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
    const limitNum = limit ? parseInt(limit) : 5;
    return this.appointmentsService.getUpcomingAppointments(patientId, limitNum);
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
   */
  @Post()
  @Roles('PATIENT')
  @UseGuards(RolesGuard)
  async createAppointment(
    @CurrentUser('patientId') patientId: string,
    @Body() dto: CreateAppointmentDto,
  ) {
    return this.appointmentsService.createAppointment(patientId, dto);
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
