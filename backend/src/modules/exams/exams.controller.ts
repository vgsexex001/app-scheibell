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
  InternalServerErrorException,
  Logger,
  Patch,
  UseInterceptors,
  UploadedFile,
  ParseFilePipe,
  MaxFileSizeValidator,
  FileTypeValidator,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ExamsService } from './exams.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { Request as ExpressRequest } from 'express';
import { ExamStatus, PatientFileType } from '@prisma/client';
import {
  CreateExamDto,
  UpdateExamDto,
  AttachFileDto,
  ExamListQueryDto,
  PatientUploadFileDto,
  PatientFilesQueryDto,
  AdminUploadFileDto,
  ApproveExamDto,
  PendingReviewQueryDto,
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
  private readonly logger = new Logger(ExamsController.name);

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

  // GET /api/exams/patient/files - Listar arquivos do paciente (exames e documentos)
  // IMPORTANTE: Esta rota deve vir ANTES de patient/:id para evitar conflito
  @Get('patient/files')
  @Roles('PATIENT')
  async getPatientFiles(
    @Request() req: AuthenticatedRequest,
    @Query() query: PatientFilesQueryDto,
  ) {
    const patientId = this.getPatientId(req);
    return this.examsService.getPatientFiles(patientId, query);
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

  // ========== ROTAS DE UPLOAD DO PACIENTE ==========

  // POST /api/exams/patient/upload - Upload de arquivo (exame ou documento)
  @Post('patient/upload')
  @Roles('PATIENT')
  @UseInterceptors(FileInterceptor('file'))
  async uploadPatientFile(
    @Request() req: AuthenticatedRequest,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 10 * 1024 * 1024 }), // 10MB
          new FileTypeValidator({
            fileType: /(jpeg|jpg|png|heic|heif|pdf)$/i,
          }),
        ],
      }),
    )
    file: Express.Multer.File,
    @Body() dto: PatientUploadFileDto,
  ) {
    const patientId = this.getPatientId(req);
    const userId = req.user.sub;

    this.logger.log(`[UPLOAD] Controller recebeu upload de ${req.user.email}, patientId=${patientId}`);
    this.logger.log(`[UPLOAD] file: ${file?.originalname}, size=${file?.size}, mime=${file?.mimetype}`);
    this.logger.log(`[UPLOAD] dto: ${JSON.stringify(dto)}`);

    try {
      return await this.examsService.uploadPatientFile(patientId, userId, file, dto);
    } catch (error) {
      this.logger.error(`[UPLOAD] ERRO no controller: ${error.message}`);
      this.logger.error(`[UPLOAD] Stack: ${error.stack}`);
      throw new InternalServerErrorException(`Upload falhou: ${error.message}`);
    }
  }

  // DELETE /api/exams/patient/:id - Deletar arquivo próprio
  @Delete('patient/:id')
  @Roles('PATIENT')
  async deletePatientFile(
    @Request() req: AuthenticatedRequest,
    @Param('id') examId: string,
  ) {
    const patientId = this.getPatientId(req);
    await this.examsService.deletePatientFile(patientId, examId);
    return { success: true };
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

  // GET /api/exams/admin/pending - Listar exames pendentes de revisão médica
  @Get('admin/pending')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  async getPendingReviewExams(
    @Request() req: AuthenticatedRequest,
    @Query() query: PendingReviewQueryDto,
  ) {
    const clinicId = this.getClinicId(req);
    return this.examsService.getPendingReviewExams(clinicId, query);
  }

  // GET /api/exams/admin/urgent - Listar exames urgentes
  @Get('admin/urgent')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  async getUrgentExams(
    @Request() req: AuthenticatedRequest,
    @Query() query: PendingReviewQueryDto,
  ) {
    const clinicId = this.getClinicId(req);
    return this.examsService.getUrgentExams(clinicId, query);
  }

  // GET /api/exams/admin/urgent/count - Contador de exames urgentes (para badge)
  @Get('admin/urgent/count')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  async getUrgentExamCount(@Request() req: AuthenticatedRequest) {
    const clinicId = this.getClinicId(req);
    return this.examsService.getUrgentExamCount(clinicId);
  }

  // GET /api/exams/admin/history - Histórico completo de exames
  @Get('admin/history')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  async getExamsHistory(
    @Request() req: AuthenticatedRequest,
    @Query() query: { page?: number; limit?: number; urgent?: string; patientId?: string; status?: string; aiStatus?: string },
  ) {
    const clinicId = this.getClinicId(req);
    return this.examsService.getExamsHistory(clinicId, query);
  }

  // GET /api/exams/admin/ai-analyzed - Exames analisados pela IA (não urgentes)
  @Get('admin/ai-analyzed')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  async getAiAnalyzedExams(
    @Request() req: AuthenticatedRequest,
    @Query() query: { page?: number; limit?: number; patientId?: string },
  ) {
    const clinicId = this.getClinicId(req);
    return this.examsService.getAiAnalyzedExams(clinicId, query);
  }

  // PUT /api/exams/admin/:id/approve - Aprovar exame e liberar para paciente
  @Put('admin/:id/approve')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  async approveExam(
    @Request() req: AuthenticatedRequest,
    @Param('id') examId: string,
    @Body() dto: ApproveExamDto,
  ) {
    const clinicId = this.getClinicId(req);
    const userId = req.user.sub;
    return this.examsService.approveExam(clinicId, examId, userId, dto);
  }

  // POST /api/exams/admin/upload - Upload de arquivo pelo admin para paciente
  // IMPORTANTE: Esta rota deve vir ANTES de admin/:id para evitar conflito
  @Post('admin/upload')
  @Roles('CLINIC_ADMIN', 'CLINIC_STAFF')
  @UseInterceptors(FileInterceptor('file'))
  async uploadAdminFile(
    @Request() req: AuthenticatedRequest,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 10 * 1024 * 1024 }), // 10MB
          new FileTypeValidator({
            fileType: /(jpeg|jpg|png|heic|heif|pdf)$/i,
          }),
        ],
      }),
    )
    file: Express.Multer.File,
    @Body() dto: AdminUploadFileDto,
  ) {
    console.log('=== DEBUG UPLOAD ADMIN ===');
    console.log('DTO recebido:', JSON.stringify(dto, null, 2));
    console.log('File recebido:', file ? { originalname: file.originalname, mimetype: file.mimetype, size: file.size } : 'NENHUM');
    console.log('User:', req.user);
    console.log('=========================');

    const clinicId = this.getClinicId(req);
    const userId = req.user.sub;
    const role = req.user.role;

    return this.examsService.uploadAdminFile(clinicId, userId, role, file, dto);
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
