import {
  Injectable,
  NotFoundException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateExamTypeDto, UpdateExamTypeDto } from './dto';

@Injectable()
export class ExamTypesService {
  private readonly logger = new Logger(ExamTypesService.name);

  constructor(private readonly prisma: PrismaService) {}

  async findAll(clinicId: string, includeInactive = false) {
    const where: any = { clinicId };
    if (!includeInactive) {
      where.isActive = true;
    }

    return this.prisma.examType.findMany({
      where,
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
    });
  }

  async findOne(clinicId: string, id: string) {
    const examType = await this.prisma.examType.findFirst({
      where: { id, clinicId },
    });

    if (!examType) {
      throw new NotFoundException('Tipo de exame não encontrado');
    }

    return examType;
  }

  async create(clinicId: string, dto: CreateExamTypeDto) {
    // Verifica duplicado por nome
    const existing = await this.prisma.examType.findFirst({
      where: { clinicId, name: dto.name, isActive: true },
    });

    if (existing) {
      throw new ConflictException('Já existe um tipo de exame com esse nome');
    }

    const examType = await this.prisma.examType.create({
      data: {
        clinicId,
        name: dto.name,
        description: dto.description,
        category: dto.category,
        icon: dto.icon ?? 'science',
        color: dto.color ?? '#2196F3',
        validityDays: dto.validityDays ?? 90,
        urgencyKeywords: dto.urgencyKeywords ?? [],
        urgencyRules: dto.urgencyRules ?? undefined,
        urgencyInstructions: dto.urgencyInstructions,
        referenceValues: dto.referenceValues ?? undefined,
        sortOrder: dto.sortOrder ?? 0,
        requiresDoctorReview: dto.requiresDoctorReview ?? false,
      },
    });

    this.logger.log(`ExamType criado: ${examType.id} - ${examType.name}`);
    return examType;
  }

  async update(clinicId: string, id: string, dto: UpdateExamTypeDto) {
    const existing = await this.prisma.examType.findFirst({
      where: { id, clinicId },
    });

    if (!existing) {
      throw new NotFoundException('Tipo de exame não encontrado');
    }

    // Verifica conflito de nome
    if (dto.name && dto.name !== existing.name) {
      const nameConflict = await this.prisma.examType.findFirst({
        where: { clinicId, name: dto.name, isActive: true, id: { not: id } },
      });

      if (nameConflict) {
        throw new ConflictException('Já existe um tipo de exame com esse nome');
      }
    }

    const updated = await this.prisma.examType.update({
      where: { id },
      data: {
        ...dto,
        updatedAt: new Date(),
      },
    });

    this.logger.log(`ExamType atualizado: ${id}`);
    return updated;
  }

  async remove(clinicId: string, id: string) {
    const existing = await this.prisma.examType.findFirst({
      where: { id, clinicId },
    });

    if (!existing) {
      throw new NotFoundException('Tipo de exame não encontrado');
    }

    const updated = await this.prisma.examType.update({
      where: { id },
      data: { isActive: false, updatedAt: new Date() },
    });

    this.logger.log(`ExamType desativado: ${id}`);
    return updated;
  }

  async reactivate(clinicId: string, id: string) {
    const existing = await this.prisma.examType.findFirst({
      where: { id, clinicId },
    });

    if (!existing) {
      throw new NotFoundException('Tipo de exame não encontrado');
    }

    return this.prisma.examType.update({
      where: { id },
      data: { isActive: true, updatedAt: new Date() },
    });
  }

  async seedDefaultTypes(clinicId: string) {
    const defaultTypes = [
      {
        name: 'Hemograma Completo',
        category: 'LABORATORIAL',
        icon: 'science',
        color: '#F44336',
        validityDays: 90,
        urgencyKeywords: ['anemia severa', 'leucocitose', 'plaquetopenia', 'pancitopenia'],
        urgencyInstructions: 'Marcar urgente se hemoglobina < 8, leucócitos > 20.000 ou plaquetas < 50.000',
        requiresDoctorReview: false,
        sortOrder: 1,
      },
      {
        name: 'Glicemia',
        category: 'LABORATORIAL',
        icon: 'science',
        color: '#FF9800',
        validityDays: 90,
        urgencyKeywords: ['hipoglicemia', 'hiperglicemia severa'],
        urgencyInstructions: 'Marcar urgente se glicemia > 300 mg/dL ou < 50 mg/dL',
        requiresDoctorReview: false,
        sortOrder: 2,
      },
      {
        name: 'Raio-X',
        category: 'IMAGEM',
        icon: 'image',
        color: '#2196F3',
        validityDays: 180,
        urgencyKeywords: ['fratura', 'pneumotórax', 'derrame pleural', 'massa'],
        urgencyInstructions: 'Marcar urgente se identificar fratura, pneumotórax ou massa suspeita',
        requiresDoctorReview: false,
        sortOrder: 3,
      },
      {
        name: 'Tomografia',
        category: 'IMAGEM',
        icon: 'image',
        color: '#9C27B0',
        validityDays: 180,
        urgencyKeywords: ['lesão', 'massa', 'hemorragia', 'fratura'],
        urgencyInstructions: 'Marcar urgente se identificar lesões, massas ou hemorragias',
        requiresDoctorReview: true,
        sortOrder: 4,
      },
      {
        name: 'Eletrocardiograma',
        category: 'CARDIACO',
        icon: 'monitor_heart',
        color: '#E91E63',
        validityDays: 180,
        urgencyKeywords: ['arritmia', 'infarto', 'isquemia', 'bloqueio'],
        urgencyInstructions: 'Marcar urgente se sinais de isquemia, arritmia grave ou bloqueio',
        requiresDoctorReview: true,
        sortOrder: 5,
      },
      {
        name: 'Ressonância Magnética',
        category: 'IMAGEM',
        icon: 'image',
        color: '#00BCD4',
        validityDays: 365,
        urgencyKeywords: ['lesão', 'ruptura', 'massa', 'compressão'],
        requiresDoctorReview: true,
        sortOrder: 6,
      },
      {
        name: 'Outros',
        category: 'OUTROS',
        icon: 'description',
        color: '#9E9E9E',
        validityDays: 90,
        urgencyKeywords: [],
        requiresDoctorReview: false,
        sortOrder: 99,
      },
    ];

    const created: any[] = [];
    for (const type of defaultTypes) {
      const existing = await this.prisma.examType.findFirst({
        where: { clinicId, name: type.name },
      });

      if (!existing) {
        const examType = await this.prisma.examType.create({
          data: { clinicId, ...type },
        });
        created.push(examType);
      }
    }

    this.logger.log(`Seed: ${created.length} tipos de exame criados para clínica ${clinicId}`);
    return { created: created.length, types: created };
  }
}
