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
  BadRequestException,
  Patch,
} from '@nestjs/common';
import { ExamsService } from './exams.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { Request as ExpressRequest } from 'express';
import { ExamStatus } from '@prisma/client';
import {
  CreateExamDto,
  UpdateExamDto,
  AttachFileDto,
  ExamListQueryDto,
} from './dto';

interface AuthenticatedRequest extends ExpressRequest {
  user: {
    sub: string;
    email: string;
    role: string;
    patientId?: string;
    clinicId?: string;
  };
}

@Controller('exams')
@UseGuards(JwtAuthGuard, RolesGuard)
export class ExamsController {
  constructor(private readonly examsService: ExamsService) {}

  private getPatientId(req: AuthenticatedRequest): string {
    const patientId = req.user.patientId;
    if (!patientId) {
      throw new BadRequestException('Patient ID not found');
    }
    return patientId;
  }

  private getClinicId(req: AuthenticatedRequest): string {
    const clinicId = req.user.clinicId;
    if (!clinicId) {
      throw new BadRequestException('Clinic ID not found');
    }
    return clinicId;
  }

  // ========== ROTAS DO PACIENTE ==========

  // GET /api/exams/patient - Listar exames do paciente
  @Get('patient')
  @Roles('PATIENT')
  async getMyExams(
    @Request() req: AuthenticatedRequest,
    @Query('status') status?: ExamStatus,
  ) {
    const patientId = this.getPatientId(req);
    return this.examsService.getPatientExams(patientId, status);
  }

  // GET /api/exams/patient/stats - Estatísticas dos exames
  @Get('patient/stats')
  @Roles('PATIENT')
  async getMyExamStats(@Request() req: AuthenticatedRequest) {
    const patientId = this.getPatientId(req);
    return this.examsService.getExamStats(patientId);
  }

  // GET /api/exams/patient/:id - Detalhes de um exame
  @Get('patient/:id')
  @Roles('PATIENT')
  async getExamDetails(
    @Request() req: AuthenticatedRequest,
    @Param('id') examId: string,
  ) {
    const patientId = this.getPatientId(req);
    return this.examsService.getExamById(patientId, examId);
  }

  // PATCH /api/exams/patient/:id/viewed - Marcar como visualizado
  @Patch('patient/:id/viewed')
  @Roles('PATIENT')
  async markAsViewed(
    @Request() req: AuthenticatedRequest,
    @Param('id') examId: string,
  ) {
    const patientId = this.getPatientId(req);
    return this.examsService.markAsViewed(patientId, examId);
  }

  // ========== ROTAS DO STAFF/ADMIN ==========

  // GET /api/exams/admin - Listar todos exames da clínica
  @Get('admin')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  async getClinicExams(
    @Request() req: AuthenticatedRequest,
    @Query() query: ExamListQueryDto,
  ) {
    const clinicId = this.getClinicId(req);
    return this.examsService.getClinicExams(clinicId, query);
  }

  // GET /api/exams/admin/stats - Estatísticas de exames da clínica
  @Get('admin/stats')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  async getClinicExamStats(@Request() req: AuthenticatedRequest) {
    const clinicId = this.getClinicId(req);
    return this.examsService.getClinicExamStats(clinicId);
  }

  // GET /api/exams/admin/patients/:patientId - Listar exames de um paciente
  @Get('admin/patients/:patientId')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  async getPatientExamsAdmin(
    @Request() req: AuthenticatedRequest,
    @Param('patientId') patientId: string,
    @Query() query: ExamListQueryDto,
  ) {
    const clinicId = this.getClinicId(req);
    return this.examsService.getPatientExamsForAdmin(clinicId, patientId, query);
  }

  // GET /api/exams/admin/:id - Detalhes de um exame (admin)
  @Get('admin/:id')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  async getExamDetailsAdmin(
    @Request() req: AuthenticatedRequest,
    @Param('id') examId: string,
  ) {
    const clinicId = this.getClinicId(req);
    return this.examsService.getExamByIdForAdmin(clinicId, examId);
  }

  // POST /api/exams - Criar exame para paciente
  @Post()
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  async createExam(@Body() data: CreateExamDto) {
    return this.examsService.createExam({
      ...data,
      date: new Date(data.date),
    });
  }

  // PUT /api/exams/:id - Atualizar exame
  @Put(':id')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  async updateExam(
    @Param('id') examId: string,
    @Body() data: UpdateExamDto,
  ) {
    return this.examsService.updateExam(examId, {
      ...data,
      date: data.date ? new Date(data.date) : undefined,
    });
  }

  // DELETE /api/exams/:id - Deletar exame
  @Delete(':id')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  async deleteExam(@Param('id') examId: string) {
    await this.examsService.deleteExam(examId);
    return { success: true };
  }

  // POST /api/exams/:id/file - Anexar arquivo ao exame
  @Post(':id/file')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  async attachFile(
    @Param('id') examId: string,
    @Body() data: AttachFileDto,
  ) {
    return this.examsService.attachFile(examId, data);
  }
}
