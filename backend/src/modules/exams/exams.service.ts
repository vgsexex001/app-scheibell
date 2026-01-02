import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ExamStatus } from '@prisma/client';

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
}
