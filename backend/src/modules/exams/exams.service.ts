import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ExamStatus, Prisma } from '@prisma/client';
import { ExamListQueryDto, ClinicExamStatsDto } from './dto';

@Injectable()
export class ExamsService {
  constructor(private prisma: PrismaService) {}

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

    const { page = 1, limit = 20, status, dateFrom, dateTo } = query;
    const skip = (page - 1) * limit;

    const where: Prisma.ExamWhereInput = {
      patientId,
      ...(status && { status }),
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
}
