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
import { ExamTypesService } from './exam-types.service';
import { CreateExamTypeDto, UpdateExamTypeDto } from './dto';
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

@Controller('exam-types')
@UseGuards(JwtAuthGuard, RolesGuard)
export class ExamTypesController {
  constructor(private readonly service: ExamTypesService) {}

  private getClinicId(req: AuthenticatedRequest): string {
    const clinicId = req.user.clinicId;
    if (!clinicId) {
      throw new Error('Clinic ID not found');
    }
    return clinicId;
  }

  @Get()
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  async findAll(
    @Request() req: AuthenticatedRequest,
    @Query('includeInactive') includeInactive?: string,
  ) {
    const clinicId = this.getClinicId(req);
    return this.service.findAll(clinicId, includeInactive === 'true');
  }

  @Get(':id')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  async findOne(
    @Request() req: AuthenticatedRequest,
    @Param('id') id: string,
  ) {
    const clinicId = this.getClinicId(req);
    return this.service.findOne(clinicId, id);
  }

  @Post()
  @Roles('CLINIC_ADMIN')
  async create(
    @Request() req: AuthenticatedRequest,
    @Body() dto: CreateExamTypeDto,
  ) {
    const clinicId = this.getClinicId(req);
    return this.service.create(clinicId, dto);
  }

  @Put(':id')
  @Roles('CLINIC_ADMIN')
  async update(
    @Request() req: AuthenticatedRequest,
    @Param('id') id: string,
    @Body() dto: UpdateExamTypeDto,
  ) {
    const clinicId = this.getClinicId(req);
    return this.service.update(clinicId, id, dto);
  }

  @Delete(':id')
  @Roles('CLINIC_ADMIN')
  async remove(
    @Request() req: AuthenticatedRequest,
    @Param('id') id: string,
  ) {
    const clinicId = this.getClinicId(req);
    return this.service.remove(clinicId, id);
  }

  @Post(':id/reactivate')
  @Roles('CLINIC_ADMIN')
  async reactivate(
    @Request() req: AuthenticatedRequest,
    @Param('id') id: string,
  ) {
    const clinicId = this.getClinicId(req);
    return this.service.reactivate(clinicId, id);
  }

  @Post('seed-defaults')
  @Roles('CLINIC_ADMIN')
  async seedDefaults(@Request() req: AuthenticatedRequest) {
    const clinicId = this.getClinicId(req);
    return this.service.seedDefaultTypes(clinicId);
  }
}
