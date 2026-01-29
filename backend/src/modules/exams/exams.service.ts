import { Injectable, NotFoundException, ForbiddenException, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ExamStatus, Prisma, PatientFileType, AiAnalysisStatus, ExamResultStatus } from '@prisma/client';
import { ExamListQueryDto, ClinicExamStatsDto, PatientUploadFileDto, PatientFilesQueryDto, AdminUploadFileDto } from './dto';
import { StorageService } from '../storage/storage.service';
import { v4 as uuidv4 } from 'uuid';
import {
  EXAM_ANALYSIS_SYSTEM_PROMPT,
  EXAM_ANALYSIS_USER_PROMPT,
  EXAM_ANALYSIS_FALLBACK,
  validateAiResponse,
  mapSuggestedStatusToEnum,
} from '../../ai/prompts/exam-analysis.prompt';

@Injectable()
export class ExamsService {
  private readonly logger = new Logger(ExamsService.name);

  constructor(
    private prisma: PrismaService,
    private storageService: StorageService,
  ) {}

  // Buscar todos os exames do paciente
  async getPatientExams(patientId: string, status?: ExamStatus) {
    return this.prisma.exam.findMany({
      where: {
        patientId,
        ...(status && { status }),
      },
      orderBy: { date: 'desc' },
    });
  }

  // Buscar um exame específico
  async getExamById(patientId: string, examId: string) {
    const exam = await this.prisma.exam.findUnique({
      where: { id: examId },
    });

    if (!exam) {
      throw new NotFoundException('Exame não encontrado');
    }

    if (exam.patientId !== patientId) {
      throw new ForbiddenException('Acesso negado');
    }

    return exam;
  }

  // Marcar exame como visualizado
  async markAsViewed(patientId: string, examId: string) {
    const exam = await this.getExamById(patientId, examId);

    if (exam.status === ExamStatus.AVAILABLE) {
      return this.prisma.exam.update({
        where: { id: examId },
        data: { status: ExamStatus.VIEWED },
      });
    }

    return exam;
  }

  // Criar exame (para staff/admin)
  async createExam(data: {
    patientId: string;
    title: string;
    type: string;
    date: Date;
    notes?: string;
    result?: string;
    fileUrl?: string;
    fileName?: string;
    fileSize?: number;
    mimeType?: string;
    status?: ExamStatus;
  }) {
    return this.prisma.exam.create({
      data: {
        patientId: data.patientId,
        title: data.title,
        type: data.type,
        date: data.date,
        notes: data.notes,
        result: data.result,
        fileUrl: data.fileUrl,
        fileName: data.fileName,
        fileSize: data.fileSize,
        mimeType: data.mimeType,
        status: data.status || ExamStatus.PENDING,
      },
    });
  }

  // Atualizar exame (para staff/admin)
  async updateExam(
    examId: string,
    data: {
      title?: string;
      type?: string;
      date?: Date;
      notes?: string;
      result?: string;
      fileUrl?: string;
      fileName?: string;
      fileSize?: number;
      mimeType?: string;
      status?: ExamStatus;
    },
  ) {
    return this.prisma.exam.update({
      where: { id: examId },
      data,
    });
  }

  // Deletar exame (para staff/admin)
  async deleteExam(examId: string) {
    return this.prisma.exam.delete({
      where: { id: examId },
    });
  }

  // Upload de arquivo para exame
  async attachFile(
    examId: string,
    fileData: {
      fileUrl: string;
      fileName: string;
      fileSize: number;
      mimeType: string;
    },
  ) {
    return this.prisma.exam.update({
      where: { id: examId },
      data: {
        ...fileData,
        status: ExamStatus.AVAILABLE,
      },
    });
  }

  // Estatísticas de exames do paciente
  async getExamStats(patientId: string) {
    const [total, pending, available, viewed] = await Promise.all([
      this.prisma.exam.count({ where: { patientId } }),
      this.prisma.exam.count({ where: { patientId, status: ExamStatus.PENDING } }),
      this.prisma.exam.count({ where: { patientId, status: ExamStatus.AVAILABLE } }),
      this.prisma.exam.count({ where: { patientId, status: ExamStatus.VIEWED } }),
    ]);

    return { total, pending, available, viewed };
  }

  // ========== ADMIN METHODS ==========

  /**
   * Listar exames de um paciente específico (admin)
   */
  async getPatientExamsForAdmin(
    clinicId: string,
    patientId: string,
    query: ExamListQueryDto,
  ) {
    // Verificar se paciente pertence à clínica
    const patient = await this.prisma.patient.findFirst({
      where: { id: patientId, clinicId },
    });

    if (!patient) {
      throw new NotFoundException('Paciente não encontrado nesta clínica');
    }

    const { page = 1, limit = 20, status, dateFrom, dateTo, fileType } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.ExamWhereInput = {
      patientId,
      ...(status && { status }),
      ...(fileType && { fileType }),
      ...(dateFrom && { date: { gte: new Date(dateFrom) } }),
      ...(dateTo && { date: { lte: new Date(dateTo) } }),
    };

    const [items, total] = await Promise.all([
      this.prisma.exam.findMany({
        where,
        orderBy: { date: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.exam.count({ where }),
    ]);

    return {
      items,
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    };
  }

  /**
   * Listar todos exames da clínica (admin)
   */
  async getClinicExams(clinicId: string, query: ExamListQueryDto) {
    const { page = 1, limit = 20, status, patientId, dateFrom, dateTo, search } = query;
    const skip = (page - 1) * limit;

    // Build where clause
    const where: Prisma.ExamWhereInput = {
      patient: { clinicId },
      ...(status && { status }),
      ...(patientId && { patientId }),
      ...(dateFrom || dateTo
        ? {
            date: {
              ...(dateFrom && { gte: new Date(dateFrom) }),
              ...(dateTo && { lte: new Date(dateTo) }),
            },
          }
        : {}),
      ...(search && {
        OR: [
          { title: { contains: search, mode: 'insensitive' } },
          { type: { contains: search, mode: 'insensitive' } },
        ],
      }),
    };

    const [items, total] = await Promise.all([
      this.prisma.exam.findMany({
        where,
        include: {
          patient: {
            select: {
              id: true,
              name: true,
              user: { select: { name: true } },
            },
          },
        },
        orderBy: { date: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.exam.count({ where }),
    ]);

    // Map items to include patient name
    const mappedItems = items.map((exam) => ({
      ...exam,
      patientName: exam.patient.user?.name || exam.patient.name || 'Paciente',
    }));

    return {
      items: mappedItems,
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    };
  }

  /**
   * Estatísticas de exames da clínica (admin)
   */
  async getClinicExamStats(clinicId: string): Promise<ClinicExamStatsDto> {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const endOfLastMonth = new Date(now.getFullYear(), now.getMonth(), 0);

    const whereClinic = { patient: { clinicId } };

    const [
      totalExams,
      pendingExams,
      availableExams,
      viewedExams,
      totalPatients,
      examsThisMonth,
      examsLastMonth,
    ] = await Promise.all([
      this.prisma.exam.count({ where: whereClinic }),
      this.prisma.exam.count({ where: { ...whereClinic, status: ExamStatus.PENDING } }),
      this.prisma.exam.count({ where: { ...whereClinic, status: ExamStatus.AVAILABLE } }),
      this.prisma.exam.count({ where: { ...whereClinic, status: ExamStatus.VIEWED } }),
      this.prisma.patient.count({ where: { clinicId } }),
      this.prisma.exam.count({
        where: { ...whereClinic, createdAt: { gte: startOfMonth } },
      }),
      this.prisma.exam.count({
        where: {
          ...whereClinic,
          createdAt: { gte: startOfLastMonth, lte: endOfLastMonth },
        },
      }),
    ]);

    return {
      totalExams,
      pendingExams,
      availableExams,
      viewedExams,
      totalPatients,
      examsThisMonth,
      examsLastMonth,
    };
  }

  /**
   * Buscar exame por ID (admin) - com validação de clínica
   */
  async getExamByIdForAdmin(clinicId: string, examId: string) {
    const exam = await this.prisma.exam.findUnique({
      where: { id: examId },
      include: {
        patient: {
          select: {
            id: true,
            name: true,
            clinicId: true,
            user: { select: { name: true } },
          },
        },
      },
    });

    if (!exam) {
      throw new NotFoundException('Exame não encontrado');
    }

    if (exam.patient.clinicId !== clinicId) {
      throw new ForbiddenException('Acesso negado a este exame');
    }

    return {
      ...exam,
      patientName: exam.patient.user?.name || exam.patient.name || 'Paciente',
    };
  }

  // ========== PATIENT UPLOAD METHODS ==========

  /**
   * Upload de arquivo pelo paciente (exame ou documento)
   */
  async uploadPatientFile(
    patientId: string,
    userId: string,
    file: Express.Multer.File,
    dto: PatientUploadFileDto,
  ) {
    this.logger.log(`[UPLOAD] ═══════════════════════════════════════════`);
    this.logger.log(`[UPLOAD] Início do upload`);
    this.logger.log(`[UPLOAD] patientId: ${patientId}`);
    this.logger.log(`[UPLOAD] userId: ${userId}`);
    this.logger.log(`[UPLOAD] fileType: ${dto.fileType}`);
    this.logger.log(`[UPLOAD] title: ${dto.title}`);
    this.logger.log(`[UPLOAD] file.originalname: ${file.originalname}`);
    this.logger.log(`[UPLOAD] file.mimetype: ${file.mimetype}`);
    this.logger.log(`[UPLOAD] file.size: ${file.size}`);
    this.logger.log(`[UPLOAD] file.buffer exists: ${!!file.buffer}`);
    this.logger.log(`[UPLOAD] file.buffer length: ${file.buffer?.length ?? 'null'}`);

    // Gerar nome único para o arquivo
    const ext = file.originalname.split('.').pop() || 'bin';
    const uniqueFilename = `${uuidv4()}.${ext}`;

    // Determinar bucket baseado no tipo
    const bucket = dto.fileType === PatientFileType.EXAM ? 'exam-files' : 'patient-documents';
    const filePath = `${patientId}/${uniqueFilename}`;

    this.logger.log(`[UPLOAD] bucket: ${bucket}`);
    this.logger.log(`[UPLOAD] filePath: ${filePath}`);

    // Upload para Supabase Storage
    let uploadResult;
    try {
      this.logger.log(`[UPLOAD] Iniciando upload para storage...`);
      uploadResult = await this.storageService.uploadFile(
        bucket,
        filePath,
        file.buffer,
        file.mimetype,
      );
      this.logger.log(`[UPLOAD] Upload OK: ${JSON.stringify(uploadResult)}`);
    } catch (error) {
      this.logger.error(`[UPLOAD] ERRO no storage upload: ${error.message}`);
      this.logger.error(`[UPLOAD] Stack: ${error.stack}`);
      throw new Error(`Falha ao fazer upload do arquivo: ${error.message}`);
    }

    // Documentos não passam por análise de IA - apenas exames
    const isDocument = dto.fileType === PatientFileType.DOCUMENT;

    // Criar registro no banco
    this.logger.log(`[UPLOAD] Criando registro no banco...`);
    let exam;
    try {
      exam = await this.prisma.exam.create({
        data: {
          patientId,
          title: dto.title,
          type: dto.type || 'OUTROS',
          date: dto.date ? new Date(dto.date) : new Date(),
          status: ExamStatus.PENDING_REVIEW,
          fileUrl: uploadResult.publicUrl,
          fileName: file.originalname,
          fileSize: file.size,
          mimeType: file.mimetype,
          notes: dto.notes,
          fileType: dto.fileType,
          aiStatus: isDocument ? AiAnalysisStatus.SKIPPED : AiAnalysisStatus.PENDING,
          createdByRole: 'PATIENT',
          createdById: userId,
        },
      });
      this.logger.log(`[UPLOAD] Registro criado: ${exam.id}`);
    } catch (error) {
      this.logger.error(`[UPLOAD] ERRO ao criar registro no banco: ${error.message}`);
      this.logger.error(`[UPLOAD] Stack: ${error.stack}`);
      throw new Error(`Falha ao salvar no banco: ${error.message}`);
    }

    // Disparar análise IA de forma assíncrona (apenas para exames)
    if (!isDocument) {
      this.logger.log(`[UPLOAD] Disparando análise IA assíncrona...`);
      this.analyzeFileAsync(exam.id, uploadResult.path, file.mimetype, bucket);
    }

    this.logger.log(`[UPLOAD] Upload concluído com sucesso`);
    this.logger.log(`[UPLOAD] ═══════════════════════════════════════════`);
    return exam;
  }

  /**
   * Upload de arquivo pelo admin/staff para um paciente
   */
  async uploadAdminFile(
    clinicId: string,
    userId: string,
    role: string,
    file: Express.Multer.File,
    dto: AdminUploadFileDto,
  ) {
    this.logger.log(`Admin ${userId} uploading ${dto.fileType} for patient ${dto.patientId}: ${dto.title}`);

    // Verificar se o paciente pertence à clínica
    const patient = await this.prisma.patient.findFirst({
      where: {
        id: dto.patientId,
        clinicId: clinicId,
      },
    });

    if (!patient) {
      // Tenta buscar via user.clinicId como fallback
      const patientViaUser = await this.prisma.patient.findFirst({
        where: {
          id: dto.patientId,
          user: { clinicId },
        },
      });

      if (!patientViaUser) {
        throw new ForbiddenException('Paciente não encontrado ou não pertence à sua clínica');
      }
    }

    // Gerar nome único para o arquivo
    const ext = file.originalname.split('.').pop() || 'bin';
    const uniqueFilename = `${uuidv4()}.${ext}`;

    // Determinar bucket baseado no tipo
    const bucket = dto.fileType === PatientFileType.EXAM ? 'exam-files' : 'patient-documents';

    // Upload para Supabase Storage
    let uploadResult;
    try {
      uploadResult = await this.storageService.uploadFile(
        bucket,
        `${dto.patientId}/${uniqueFilename}`,
        file.buffer,
        file.mimetype,
      );
    } catch (error) {
      this.logger.error(`Upload failed: ${error.message}`);
      throw new Error('Falha ao fazer upload do arquivo');
    }

    // Criar registro no banco
    const exam = await this.prisma.exam.create({
      data: {
        patientId: dto.patientId,
        title: dto.title,
        type: dto.type || 'OUTROS',
        date: dto.date ? new Date(dto.date) : new Date(),
        status: ExamStatus.AVAILABLE,
        fileUrl: uploadResult.publicUrl,
        fileName: file.originalname,
        fileSize: file.size,
        mimeType: file.mimetype,
        notes: dto.notes,
        fileType: dto.fileType,
        aiStatus: AiAnalysisStatus.SKIPPED, // Admin uploads não precisam de análise IA
        aiSummary: 'Enviado pela clínica.',
        createdByRole: role, // 'CLINIC_ADMIN' ou 'CLINIC_STAFF'
        createdById: userId,
      },
    });

    this.logger.log(`Admin uploaded file ${exam.id} for patient ${dto.patientId}`);

    return exam;
  }

  /**
   * Análise assíncrona do arquivo com OpenAI Vision
   * Após análise, status muda para PENDING_REVIEW aguardando aprovação médica
   */
  private async analyzeFileAsync(
    examId: string,
    storagePath: string,
    mimeType: string,
    bucket: string,
  ) {
    // Marcar como processando
    await this.prisma.exam.update({
      where: { id: examId },
      data: { aiStatus: AiAnalysisStatus.PROCESSING },
    });

    try {
      // Se for PDF, marcar para revisão manual
      if (mimeType === 'application/pdf') {
        await this.prisma.exam.update({
          where: { id: examId },
          data: {
            aiStatus: AiAnalysisStatus.SKIPPED,
            aiSummary: 'Este documento será analisado pela equipe médica.',
            aiJson: EXAM_ANALYSIS_FALLBACK as object,
            status: ExamStatus.PENDING_REVIEW,
          },
        });
        return;
      }

      // Baixar arquivo para análise
      const fileBuffer = await this.storageService.downloadFile(bucket, storagePath);

      // Chamar OpenAI Vision para análise estruturada
      const aiResponse = await this.analyzeImageWithOpenAI(fileBuffer, mimeType);

      // Validar e sanitizar resposta
      const validatedResponse = validateAiResponse(aiResponse);

      // Atualizar com resultado - status PENDING_REVIEW aguarda aprovação médica
      await this.prisma.exam.update({
        where: { id: examId },
        data: {
          aiStatus: AiAnalysisStatus.COMPLETED,
          aiSummary: validatedResponse.patient_summary,
          aiJson: validatedResponse as object,
          aiAnalyzedAt: new Date(),
          aiConfidence: validatedResponse.confidence,
          status: ExamStatus.PENDING_REVIEW, // Aguardando revisão médica
        },
      });

      this.logger.log(`AI analysis completed for exam ${examId} - suggested: ${validatedResponse.suggested_status}`);
    } catch (error) {
      this.logger.error(`AI analysis failed for exam ${examId}: ${error.message}`);

      await this.prisma.exam.update({
        where: { id: examId },
        data: {
          aiStatus: AiAnalysisStatus.FAILED,
          aiSummary: 'Análise automática não disponível. Aguardando revisão médica.',
          aiJson: EXAM_ANALYSIS_FALLBACK as object,
          status: ExamStatus.PENDING_REVIEW,
        },
      });
    }
  }

  /**
   * Análise de imagem com OpenAI Vision - retorna objeto estruturado
   */
  private async analyzeImageWithOpenAI(fileBuffer: Buffer, mimeType: string): Promise<unknown> {
    const OpenAI = require('openai');
    const openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY,
    });

    const base64Image = fileBuffer.toString('base64');
    const imageUrl = `data:${mimeType};base64,${base64Image}`;

    const response = await openai.chat.completions.create({
      model: 'gpt-4o',
      messages: [
        {
          role: 'system',
          content: EXAM_ANALYSIS_SYSTEM_PROMPT,
        },
        {
          role: 'user',
          content: [
            {
              type: 'text',
              text: EXAM_ANALYSIS_USER_PROMPT,
            },
            {
              type: 'image_url',
              image_url: {
                url: imageUrl,
                detail: 'high',
              },
            },
          ],
        },
      ],
      max_tokens: 1500,
      response_format: { type: 'json_object' },
    });

    const content = response.choices[0]?.message?.content;
    if (!content) {
      return EXAM_ANALYSIS_FALLBACK;
    }

    try {
      return JSON.parse(content);
    } catch {
      this.logger.warn('Failed to parse AI response as JSON, using fallback');
      return EXAM_ANALYSIS_FALLBACK;
    }
  }

  // ========== APPROVAL METHODS ==========

  /**
   * Aprovar exame e liberar análise para o paciente
   * O médico revisa a análise da IA e aprova (com ou sem edições)
   */
  async approveExam(
    clinicId: string,
    examId: string,
    approvedBy: string,
    data: {
      status: string;
      analysis: string;
    },
  ) {
    // Buscar exame com validação de clínica
    const exam = await this.prisma.exam.findUnique({
      where: { id: examId },
      include: {
        patient: {
          select: { clinicId: true },
        },
      },
    });

    if (!exam) {
      throw new NotFoundException('Exame não encontrado');
    }

    if (exam.patient.clinicId !== clinicId) {
      throw new ForbiddenException('Acesso negado a este exame');
    }

    // Mapear status string para enum
    const resultStatus = mapSuggestedStatusToEnum(data.status) as ExamResultStatus;

    // Atualizar exame com aprovação
    const updatedExam = await this.prisma.exam.update({
      where: { id: examId },
      data: {
        status: ExamStatus.AVAILABLE, // Libera para o paciente
        resultStatus,
        approvedAnalysis: data.analysis,
        approvedBy,
        approvedAt: new Date(),
      },
    });

    this.logger.log(`Exam ${examId} approved by ${approvedBy} with status ${resultStatus}`);

    return updatedExam;
  }

  /**
   * Listar exames pendentes de revisão médica
   */
  async getPendingReviewExams(clinicId: string, query: { page?: number; limit?: number; fileType?: PatientFileType }) {
    const { page = 1, limit = 20, fileType } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.ExamWhereInput = {
      patient: { clinicId },
      status: ExamStatus.PENDING_REVIEW,
      createdByRole: 'PATIENT', // Apenas exames enviados por pacientes
      ...(fileType && { fileType }),
    };

    const [items, total] = await Promise.all([
      this.prisma.exam.findMany({
        where,
        include: {
          patient: {
            select: {
              id: true,
              name: true,
              user: { select: { name: true } },
            },
          },
        },
        orderBy: { createdAt: 'asc' }, // Mais antigos primeiro
        skip,
        take: limit,
      }),
      this.prisma.exam.count({ where }),
    ]);

    // Map items to include patient name
    const mappedItems = items.map((exam) => ({
      ...exam,
      patientName: exam.patient.user?.name || exam.patient.name || 'Paciente',
    }));

    return {
      items: mappedItems,
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    };
  }

  /**
   * Listar arquivos do paciente com filtro por tipo
   */
  async getPatientFiles(patientId: string, query: PatientFilesQueryDto) {
    const { fileType, page = 1, limit = 20 } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.ExamWhereInput = {
      patientId,
      ...(fileType && { fileType }),
    };

    const [items, total] = await Promise.all([
      this.prisma.exam.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.exam.count({ where }),
    ]);

    return {
      items,
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    };
  }

  /**
   * Deletar arquivo do paciente (somente se criado por ele)
   */
  async deletePatientFile(patientId: string, examId: string) {
    const exam = await this.prisma.exam.findUnique({
      where: { id: examId },
    });

    if (!exam) {
      throw new NotFoundException('Arquivo não encontrado');
    }

    if (exam.patientId !== patientId) {
      throw new ForbiddenException('Acesso negado');
    }

    // Verificar se foi criado pelo paciente
    if (exam.createdByRole !== 'PATIENT') {
      throw new ForbiddenException('Você não pode deletar arquivos criados pela clínica');
    }

    // Deletar do storage se existir URL
    if (exam.fileUrl) {
      try {
        const bucket = exam.fileType === PatientFileType.EXAM ? 'exam-files' : 'patient-documents';
        const path = `${patientId}/${exam.fileUrl.split('/').pop()}`;
        await this.storageService.deleteFile(bucket, path);
      } catch (error) {
        this.logger.warn(`Failed to delete file from storage: ${error.message}`);
      }
    }

    return this.prisma.exam.delete({
      where: { id: examId },
    });
  }
}
