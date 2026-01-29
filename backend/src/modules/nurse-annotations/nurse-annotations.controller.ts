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
  Request,
  BadRequestException,
} from '@nestjs/common';
import { NurseAnnotationsService } from './nurse-annotations.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { Request as ExpressRequest } from 'express';
import { CreateNurseAnnotationDto, UpdateNurseAnnotationDto, NurseAnnotationQueryDto } from './dto';

interface AuthenticatedRequest extends ExpressRequest {
  user: {
    sub: string;
    email: string;
    role: string;
    name?: string;
    clinicId?: string;
  };
}

@Controller('nurse-annotations')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
export class NurseAnnotationsController {
  constructor(private readonly service: NurseAnnotationsService) {}

  private getClinicId(req: AuthenticatedRequest): string {
    const clinicId = req.user.clinicId;
    if (!clinicId) {
      throw new BadRequestException('Clinic ID not found');
    }
    return clinicId;
  }

  // GET /api/nurse-annotations - Listar anotações
  @Get()
  async findAll(
    @Request() req: AuthenticatedRequest,
    @Query() query: NurseAnnotationQueryDto,
  ) {
    const clinicId = this.getClinicId(req);
    return this.service.findAll(clinicId, query);
  }

  // GET /api/nurse-annotations/stats - Contadores
  @Get('stats')
  async getStats(@Request() req: AuthenticatedRequest) {
    const clinicId = this.getClinicId(req);
    return this.service.getStats(clinicId);
  }

  // GET /api/nurse-annotations/:id - Buscar por ID
  @Get(':id')
  async findById(
    @Request() req: AuthenticatedRequest,
    @Param('id') id: string,
  ) {
    const clinicId = this.getClinicId(req);
    return this.service.findById(clinicId, id);
  }

  // POST /api/nurse-annotations - Criar anotação
  @Post()
  async create(
    @Request() req: AuthenticatedRequest,
    @Body() dto: CreateNurseAnnotationDto,
  ) {
    const clinicId = this.getClinicId(req);
    const userId = req.user.sub;
    const userName = req.user.name || req.user.email;
    return this.service.create(clinicId, userId, userName, dto);
  }

  // PUT /api/nurse-annotations/:id - Atualizar anotação
  @Put(':id')
  async update(
    @Request() req: AuthenticatedRequest,
    @Param('id') id: string,
    @Body() dto: UpdateNurseAnnotationDto,
  ) {
    const clinicId = this.getClinicId(req);
    return this.service.update(clinicId, id, dto);
  }

  // PATCH /api/nurse-annotations/:id/resolve - Marcar como resolvida
  @Patch(':id/resolve')
  async resolve(
    @Request() req: AuthenticatedRequest,
    @Param('id') id: string,
  ) {
    const clinicId = this.getClinicId(req);
    const userId = req.user.sub;
    const userName = req.user.name || req.user.email;
    return this.service.resolve(clinicId, id, userId, userName);
  }

  // DELETE /api/nurse-annotations/:id - Deletar anotação
  @Delete(':id')
  async delete(
    @Request() req: AuthenticatedRequest,
    @Param('id') id: string,
  ) {
    const clinicId = this.getClinicId(req);
    return this.service.delete(clinicId, id);
  }
}
