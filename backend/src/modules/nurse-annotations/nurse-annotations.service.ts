import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateNurseAnnotationDto, UpdateNurseAnnotationDto, NurseAnnotationQueryDto } from './dto';

@Injectable()
export class NurseAnnotationsService {
  private readonly logger = new Logger(NurseAnnotationsService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Criar nova anotação
   */
  async create(
    clinicId: string,
    userId: string,
    userName: string,
    dto: CreateNurseAnnotationDto,
  ) {
    const annotation = await this.prisma.nurseAnnotation.create({
      data: {
        clinicId,
        patientId: dto.patientId,
        examId: dto.examId,
        documentId: dto.documentId,
        type: dto.type || 'GENERAL',
        title: dto.title,
        annotation: dto.annotation,
        priority: dto.priority || 'NORMAL',
        status: 'PENDING',
        createdBy: userId,
        createdByName: userName,
      },
    });

    this.logger.log(`Annotation ${annotation.id} created by ${userName} for patient ${dto.patientId}`);
    return annotation;
  }

  /**
   * Listar anotações com filtros e paginação
   */
  async findAll(clinicId: string, query: NurseAnnotationQueryDto) {
    const { page = 1, limit = 20, status, patientId, type, priority } = query;
    const skip = (page - 1) * limit;

    const where: any = {
      clinicId,
      ...(status && { status }),
      ...(patientId && { patientId }),
      ...(type && { type }),
      ...(priority && { priority }),
    };

    const [items, total] = await Promise.all([
      this.prisma.nurseAnnotation.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.nurseAnnotation.count({ where }),
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
   * Buscar anotação por ID
   */
  async findById(clinicId: string, id: string) {
    const annotation = await this.prisma.nurseAnnotation.findFirst({
      where: { id, clinicId },
    });

    if (!annotation) {
      throw new NotFoundException('Anotação não encontrada');
    }

    return annotation;
  }

  /**
   * Atualizar anotação
   */
  async update(clinicId: string, id: string, dto: UpdateNurseAnnotationDto) {
    await this.findById(clinicId, id);

    return this.prisma.nurseAnnotation.update({
      where: { id },
      data: {
        ...(dto.title && { title: dto.title }),
        ...(dto.annotation && { annotation: dto.annotation }),
        ...(dto.priority && { priority: dto.priority }),
        ...(dto.type && { type: dto.type }),
      },
    });
  }

  /**
   * Marcar como resolvida
   */
  async resolve(clinicId: string, id: string, userId: string, userName: string) {
    await this.findById(clinicId, id);

    return this.prisma.nurseAnnotation.update({
      where: { id },
      data: {
        status: 'RESOLVED',
        resolvedAt: new Date(),
        resolvedBy: userId,
        resolvedByName: userName,
      },
    });
  }

  /**
   * Deletar anotação
   */
  async delete(clinicId: string, id: string) {
    await this.findById(clinicId, id);

    await this.prisma.nurseAnnotation.delete({
      where: { id },
    });

    return { success: true };
  }

  /**
   * Contadores por status (para badges)
   */
  async getStats(clinicId: string) {
    const [pending, resolved, total] = await Promise.all([
      this.prisma.nurseAnnotation.count({ where: { clinicId, status: 'PENDING' } }),
      this.prisma.nurseAnnotation.count({ where: { clinicId, status: 'RESOLVED' } }),
      this.prisma.nurseAnnotation.count({ where: { clinicId } }),
    ]);

    return { pending, resolved, total };
  }
}
