import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { AppointmentTypesService } from './appointment-types.service';
import { CreateAppointmentTypeDto, UpdateAppointmentTypeDto } from './dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { Request as ExpressRequest } from 'express';

interface AuthenticatedRequest extends ExpressRequest {
  user: {
    sub: string;
    email: string;
    role: string;
    clinicId?: string;
  };
}

@Controller('appointment-types')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AppointmentTypesController {
  constructor(private readonly service: AppointmentTypesService) {}

  private getClinicId(req: AuthenticatedRequest): string {
    const clinicId = req.user.clinicId;
    if (!clinicId) {
      throw new Error('Clinic ID not found');
    }
    return clinicId;
  }

  /**
   * GET /api/appointment-types
   * Lista tipos de consulta da clínica do usuário logado
   * Acessível por: PATIENT, CLINIC_ADMIN, CLINIC_STAFF
   */
  @Get()
  @Roles('PATIENT', 'CLINIC_ADMIN', 'CLINIC_STAFF')
  async findAll(
    @Request() req: AuthenticatedRequest,
    @Query('includeInactive') includeInactive?: string,
  ) {
    const clinicId = this.getClinicId(req);
    const isAdmin = ['CLINIC_ADMIN', 'CLINIC_STAFF'].includes(req.user.role);

    // Pacientes só veem tipos ativos
    const showInactive = isAdmin && includeInactive === 'true';

    return this.service.findAll(clinicId, showInactive);
  }

  /**
   * GET /api/appointment-types/:id
   * Busca um tipo de consulta específico
   */
  @Get(':id')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  async findOne(
    @Request() req: AuthenticatedRequest,
    @Param('id') id: string,
  ) {
    const clinicId = this.getClinicId(req);
    return this.service.findOne(clinicId, id);
  }

  /**
   * POST /api/appointment-types
   * Cria um novo tipo de consulta
   */
  @Post()
  @Roles('CLINIC_ADMIN')
  async create(
    @Request() req: AuthenticatedRequest,
    @Body() dto: CreateAppointmentTypeDto,
  ) {
    const clinicId = this.getClinicId(req);
    return this.service.create(clinicId, dto);
  }

  /**
   * PUT /api/appointment-types/:id
   * Atualiza um tipo de consulta
   */
  @Put(':id')
  @Roles('CLINIC_ADMIN')
  async update(
    @Request() req: AuthenticatedRequest,
    @Param('id') id: string,
    @Body() dto: UpdateAppointmentTypeDto,
  ) {
    const clinicId = this.getClinicId(req);
    return this.service.update(clinicId, id, dto);
  }

  /**
   * DELETE /api/appointment-types/:id
   * Desativa um tipo de consulta (soft delete)
   */
  @Delete(':id')
  @Roles('CLINIC_ADMIN')
  async remove(
    @Request() req: AuthenticatedRequest,
    @Param('id') id: string,
  ) {
    const clinicId = this.getClinicId(req);
    return this.service.remove(clinicId, id);
  }

  /**
   * POST /api/appointment-types/:id/reactivate
   * Reativa um tipo de consulta desativado
   */
  @Post(':id/reactivate')
  @Roles('CLINIC_ADMIN')
  async reactivate(
    @Request() req: AuthenticatedRequest,
    @Param('id') id: string,
  ) {
    const clinicId = this.getClinicId(req);
    return this.service.reactivate(clinicId, id);
  }

  /**
   * POST /api/appointment-types/seed-defaults
   * Cria os tipos padrão para a clínica (admin only)
   */
  @Post('seed-defaults')
  @Roles('CLINIC_ADMIN')
  async seedDefaults(@Request() req: AuthenticatedRequest) {
    const clinicId = this.getClinicId(req);
    await this.service.seedDefaultTypes(clinicId);
    return { message: 'Tipos padrão criados com sucesso' };
  }
}
