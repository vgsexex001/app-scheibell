import {
  Controller,
  Get,
  Post,
  Put,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  ParseIntPipe,
  Logger,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { UserRole, AppointmentType } from '@prisma/client';
import { SchedulesService } from './schedules.service';
import { CreateScheduleDto, UpdateScheduleDto, CreateBlockedDateDto, UpdateBlockedDateDto } from './dto';

@ApiTags('schedules')
@ApiBearerAuth()
@Controller('schedules')
@UseGuards(JwtAuthGuard, RolesGuard)
export class SchedulesController {
  private readonly logger = new Logger(SchedulesController.name);

  constructor(private readonly schedulesService: SchedulesService) {}

  // ==================== APPOINTMENT TYPES ====================

  @Get('appointment-types')
  @Roles(UserRole.CLINIC_ADMIN, UserRole.CLINIC_STAFF, UserRole.PATIENT)
  @ApiOperation({ summary: 'Lista os tipos de atendimento disponíveis' })
  getAppointmentTypes() {
    return this.schedulesService.getAppointmentTypes();
  }

  // ==================== CLINIC SCHEDULES ====================

  @Get()
  @Roles(UserRole.CLINIC_ADMIN, UserRole.CLINIC_STAFF)
  @ApiOperation({ summary: 'Lista todos os horários da clínica' })
  @ApiQuery({ name: 'appointmentType', required: false, enum: AppointmentType })
  async getSchedules(
    @CurrentUser() user: any,
    @Query('appointmentType') appointmentType?: AppointmentType,
  ) {
    this.logger.debug(`getSchedules: user=${JSON.stringify(user)}, appointmentType=${appointmentType}`);

    if (!user) {
      this.logger.warn('getSchedules: user is undefined');
      return [];
    }

    const clinicId = user.clinicId;
    this.logger.debug(`getSchedules: clinicId=${clinicId}`);

    if (!clinicId) {
      this.logger.warn('getSchedules: user não tem clinicId');
      return { error: 'Usuário não está vinculado a uma clínica' };
    }

    try {
      return await this.schedulesService.getSchedules(clinicId, appointmentType);
    } catch (error: any) {
      this.logger.error(`getSchedules: erro - ${error.message}`);
      return [];
    }
  }

  @Get('grouped')
  @Roles(UserRole.CLINIC_ADMIN, UserRole.CLINIC_STAFF)
  @ApiOperation({ summary: 'Lista todos os horários agrupados por tipo de atendimento' })
  async getSchedulesGrouped(@CurrentUser() user: any) {
    const clinicId = user.clinicId;
    if (!clinicId) {
      return { error: 'Usuário não está vinculado a uma clínica' };
    }
    return this.schedulesService.getAllSchedulesGroupedByType(clinicId);
  }

  @Get('by-type/:appointmentType')
  @Roles(UserRole.CLINIC_ADMIN, UserRole.CLINIC_STAFF, UserRole.PATIENT)
  @ApiOperation({ summary: 'Lista horários de um tipo de atendimento específico' })
  async getSchedulesByType(
    @CurrentUser() user: any,
    @Param('appointmentType') appointmentType: AppointmentType,
  ) {
    const clinicId = user.clinicId;
    if (!clinicId) {
      return { error: 'Usuário não está vinculado a uma clínica' };
    }
    return this.schedulesService.getSchedulesByType(clinicId, appointmentType);
  }

  @Get(':dayOfWeek')
  @Roles(UserRole.CLINIC_ADMIN, UserRole.CLINIC_STAFF)
  @ApiOperation({ summary: 'Busca horário de um dia específico' })
  @ApiQuery({ name: 'appointmentType', required: false, enum: AppointmentType })
  async getScheduleByDay(
    @CurrentUser() user: any,
    @Param('dayOfWeek', ParseIntPipe) dayOfWeek: number,
    @Query('appointmentType') appointmentType?: AppointmentType,
  ) {
    const clinicId = user.clinicId;
    if (!clinicId) {
      return { error: 'Usuário não está vinculado a uma clínica' };
    }
    return this.schedulesService.getScheduleByDay(clinicId, dayOfWeek, appointmentType);
  }

  @Post()
  @Roles(UserRole.CLINIC_ADMIN, UserRole.CLINIC_STAFF)
  @ApiOperation({ summary: 'Cria ou atualiza horário de um dia' })
  async createOrUpdateSchedule(
    @CurrentUser() user: any,
    @Body() dto: CreateScheduleDto,
  ) {
    const clinicId = user.clinicId;
    if (!clinicId) {
      return { error: 'Usuário não está vinculado a uma clínica' };
    }
    return this.schedulesService.createOrUpdateSchedule(clinicId, dto);
  }

  @Put(':dayOfWeek')
  @Roles(UserRole.CLINIC_ADMIN, UserRole.CLINIC_STAFF)
  @ApiOperation({ summary: 'Atualiza horário de um dia' })
  @ApiQuery({ name: 'appointmentType', required: false, enum: AppointmentType })
  async updateSchedule(
    @CurrentUser() user: any,
    @Param('dayOfWeek', ParseIntPipe) dayOfWeek: number,
    @Body() dto: UpdateScheduleDto,
    @Query('appointmentType') appointmentType?: AppointmentType,
  ) {
    const clinicId = user.clinicId;
    if (!clinicId) {
      return { error: 'Usuário não está vinculado a uma clínica' };
    }
    return this.schedulesService.updateSchedule(clinicId, dayOfWeek, dto, appointmentType);
  }

  @Patch(':dayOfWeek/toggle')
  @Roles(UserRole.CLINIC_ADMIN, UserRole.CLINIC_STAFF)
  @ApiOperation({ summary: 'Ativa/desativa um dia' })
  @ApiQuery({ name: 'appointmentType', required: false, enum: AppointmentType })
  async toggleSchedule(
    @CurrentUser() user: any,
    @Param('dayOfWeek', ParseIntPipe) dayOfWeek: number,
    @Query('appointmentType') appointmentType?: AppointmentType,
  ) {
    const clinicId = user.clinicId;
    if (!clinicId) {
      return { error: 'Usuário não está vinculado a uma clínica' };
    }
    return this.schedulesService.toggleSchedule(clinicId, dayOfWeek, appointmentType);
  }

  @Delete(':dayOfWeek')
  @Roles(UserRole.CLINIC_ADMIN, UserRole.CLINIC_STAFF)
  @ApiOperation({ summary: 'Remove horário de um dia' })
  @ApiQuery({ name: 'appointmentType', required: false, enum: AppointmentType })
  async deleteSchedule(
    @CurrentUser() user: any,
    @Param('dayOfWeek', ParseIntPipe) dayOfWeek: number,
    @Query('appointmentType') appointmentType?: AppointmentType,
  ) {
    const clinicId = user.clinicId;
    if (!clinicId) {
      return { error: 'Usuário não está vinculado a uma clínica' };
    }
    return this.schedulesService.deleteSchedule(clinicId, dayOfWeek, appointmentType);
  }

  // ==================== BLOCKED DATES ====================

  @Get('blocked-dates/list')
  @Roles(UserRole.CLINIC_ADMIN, UserRole.CLINIC_STAFF, UserRole.PATIENT)
  @ApiOperation({ summary: 'Lista datas bloqueadas da clínica' })
  @ApiQuery({ name: 'fromToday', required: false })
  @ApiQuery({ name: 'appointmentType', required: false, enum: AppointmentType })
  async getBlockedDates(
    @CurrentUser() user: any,
    @Query('fromToday') fromToday?: string,
    @Query('appointmentType') appointmentType?: AppointmentType,
  ) {
    const clinicId = user.clinicId;
    if (!clinicId) {
      return { error: 'Usuário não está vinculado a uma clínica' };
    }

    const options: any = {};
    if (fromToday === 'true') {
      options.fromDate = new Date();
    }
    if (appointmentType) {
      options.appointmentType = appointmentType;
    }

    return this.schedulesService.getBlockedDates(clinicId, Object.keys(options).length > 0 ? options : undefined);
  }

  @Post('blocked-dates')
  @Roles(UserRole.CLINIC_ADMIN, UserRole.CLINIC_STAFF)
  @ApiOperation({ summary: 'Cria uma data bloqueada' })
  async createBlockedDate(
    @CurrentUser() user: any,
    @Body() dto: CreateBlockedDateDto,
  ) {
    const clinicId = user.clinicId;
    if (!clinicId) {
      return { error: 'Usuário não está vinculado a uma clínica' };
    }
    return this.schedulesService.createBlockedDate(clinicId, dto);
  }

  @Put('blocked-dates/:id')
  @Roles(UserRole.CLINIC_ADMIN, UserRole.CLINIC_STAFF)
  @ApiOperation({ summary: 'Atualiza uma data bloqueada' })
  async updateBlockedDate(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Body() dto: UpdateBlockedDateDto,
  ) {
    const clinicId = user.clinicId;
    if (!clinicId) {
      return { error: 'Usuário não está vinculado a uma clínica' };
    }
    return this.schedulesService.updateBlockedDate(clinicId, id, dto);
  }

  @Delete('blocked-dates/:id')
  @Roles(UserRole.CLINIC_ADMIN, UserRole.CLINIC_STAFF)
  @ApiOperation({ summary: 'Remove uma data bloqueada' })
  @ApiQuery({ name: 'appointmentType', required: false, enum: AppointmentType })
  async deleteBlockedDate(
    @CurrentUser() user: any,
    @Param('id') id: string,
    @Query('appointmentType') appointmentType?: AppointmentType,
  ) {
    const clinicId = user.clinicId;
    if (!clinicId) {
      return { error: 'Usuário não está vinculado a uma clínica' };
    }
    return this.schedulesService.deleteBlockedDate(clinicId, id, appointmentType);
  }

  // ==================== UTILITY ENDPOINTS ====================

  @Get('available-slots/:date')
  @Roles(UserRole.CLINIC_ADMIN, UserRole.CLINIC_STAFF, UserRole.PATIENT)
  @ApiOperation({ summary: 'Busca slots disponíveis para uma data' })
  @ApiQuery({ name: 'appointmentType', required: false, enum: AppointmentType })
  async getAvailableSlots(
    @CurrentUser() user: any,
    @Param('date') dateStr: string,
    @Query('appointmentType') appointmentType?: AppointmentType,
  ) {
    const clinicId = user.clinicId;
    if (!clinicId) {
      return { error: 'Usuário não está vinculado a uma clínica' };
    }
    const date = new Date(dateStr);
    return this.schedulesService.getAvailableSlots(clinicId, date, appointmentType);
  }
}
