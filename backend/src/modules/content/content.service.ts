import { Injectable, NotFoundException, BadRequestException, ForbiddenException, Inject, forwardRef, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ContentType, ContentCategory, AdjustmentType } from '@prisma/client';
import { TrainingService } from '../training/training.service';
import { CreateTemplateDto } from './dto/create-template.dto';
import { UpdateTemplateDto } from './dto/update-template.dto';
import { CreateOverrideDto } from './dto/create-override.dto';
import { UpdateOverrideDto } from './dto/update-override.dto';

// Tipos temporários até rodar prisma generate
type OverrideAction = 'ADD' | 'DISABLE' | 'MODIFY';

@Injectable()
export class ContentService {
  constructor(
    private prisma: PrismaService,
    @Inject(forwardRef(() => TrainingService))
    private trainingService: TrainingService,
  ) {}

  // ==================== CONTEÚDOS DA CLÍNICA ====================

  async getClinicContents(
    clinicId: string,
    type: ContentType,
    category?: ContentCategory,
  ) {
    const where: any = { clinicId, type, isActive: true };
    if (category) where.category = category;

    return this.prisma.clinicContent.findMany({
      where,
      orderBy: [{ category: 'asc' }, { sortOrder: 'asc' }],
    });
  }

  async getClinicContentsByType(clinicId: string, type: ContentType) {
    return this.prisma.clinicContent.findMany({
      where: { clinicId, type },
      orderBy: [{ category: 'asc' }, { sortOrder: 'asc' }],
    });
  }

  // ==================== CONTEÚDOS PARA PACIENTE (via clinicId) ====================

  async getPatientClinicContent(
    patientId: string,
    type: ContentType,
    category?: ContentCategory,
  ) {
    // Buscar o clinicId do paciente
    const patient = await this.prisma.patient.findUnique({
      where: { id: patientId },
      select: { clinicId: true },
    });

    if (!patient) throw new NotFoundException('Paciente não encontrado');

    const where: any = { clinicId: patient.clinicId, type, isActive: true };
    if (category) where.category = category;

    return this.prisma.clinicContent.findMany({
      where,
      orderBy: [{ category: 'asc' }, { sortOrder: 'asc' }],
    });
  }

  async getPatientAllClinicContentByType(patientId: string, type: ContentType) {
    // Buscar o clinicId do paciente
    const patient = await this.prisma.patient.findUnique({
      where: { id: patientId },
      select: { clinicId: true },
    });

    if (!patient) throw new NotFoundException('Paciente não encontrado');

    return this.prisma.clinicContent.findMany({
      where: { clinicId: patient.clinicId, type },
      orderBy: [{ category: 'asc' }, { sortOrder: 'asc' }],
    });
  }

  async createClinicContent(
    clinicId: string,
    data: {
      type: ContentType;
      category: ContentCategory;
      title: string;
      description?: string;
      validFromDay?: number;
      validUntilDay?: number;
    },
  ) {
    const maxOrder = await this.prisma.clinicContent.aggregate({
      where: { clinicId, type: data.type },
      _max: { sortOrder: true },
    });

    return this.prisma.clinicContent.create({
      data: {
        clinicId,
        ...data,
        sortOrder: (maxOrder._max.sortOrder ?? 0) + 1,
        isCustom: true,
      },
    });
  }

  async updateClinicContent(
    id: string,
    clinicId: string,
    data: {
      title?: string;
      description?: string;
      category?: ContentCategory;
      validFromDay?: number;
      validUntilDay?: number;
    },
  ) {
    const content = await this.prisma.clinicContent.findFirst({
      where: { id, clinicId },
    });

    if (!content) throw new NotFoundException('Conteúdo não encontrado');

    return this.prisma.clinicContent.update({
      where: { id },
      data,
    });
  }

  async toggleClinicContent(id: string, clinicId: string) {
    const content = await this.prisma.clinicContent.findFirst({
      where: { id, clinicId },
    });

    if (!content) throw new NotFoundException('Conteúdo não encontrado');

    return this.prisma.clinicContent.update({
      where: { id },
      data: { isActive: !content.isActive },
    });
  }

  async deleteClinicContent(id: string, clinicId: string) {
    const content = await this.prisma.clinicContent.findFirst({
      where: { id, clinicId },
    });

    if (!content) throw new NotFoundException('Conteúdo não encontrado');

    return this.prisma.clinicContent.delete({ where: { id } });
  }

  async reorderClinicContents(clinicId: string, contentIds: string[]) {
    const updates = contentIds.map((id, index) =>
      this.prisma.clinicContent.updateMany({
        where: { id, clinicId },
        data: { sortOrder: index },
      }),
    );

    await this.prisma.$transaction(updates);
    return { success: true, reordered: contentIds.length };
  }

  // ==================== AJUSTES POR PACIENTE ====================

  async getPatientAdjustments(patientId: string) {
    return this.prisma.patientContentAdjustment.findMany({
      where: { patientId, isActive: true },
      include: { baseContent: true },
    });
  }

  async addPatientContent(
    patientId: string,
    data: {
      contentType: ContentType;
      category: ContentCategory;
      title: string;
      description?: string;
      validFromDay?: number;
      validUntilDay?: number;
      reason?: string;
    },
    createdBy: string,
  ) {
    // Validar se o paciente existe
    const patient = await this.prisma.patient.findUnique({
      where: { id: patientId },
      select: { id: true },
    });

    if (!patient) {
      throw new NotFoundException(`Paciente com ID ${patientId} nao encontrado`);
    }

    return this.prisma.patientContentAdjustment.create({
      data: {
        patientId,
        adjustmentType: AdjustmentType.ADD,
        contentType: data.contentType,
        category: data.category,
        title: data.title,
        description: data.description,
        validFromDay: data.validFromDay,
        validUntilDay: data.validUntilDay,
        reason: data.reason,
        createdBy,
      },
    });
  }

  async disableContentForPatient(
    patientId: string,
    baseContentId: string,
    reason: string,
    createdBy: string,
  ) {
    return this.prisma.patientContentAdjustment.create({
      data: {
        patientId,
        baseContentId,
        adjustmentType: AdjustmentType.DISABLE,
        reason,
        createdBy,
      },
    });
  }

  async modifyContentForPatient(
    patientId: string,
    baseContentId: string,
    data: {
      title?: string;
      description?: string;
      category?: ContentCategory;
      reason?: string;
    },
    createdBy: string,
  ) {
    return this.prisma.patientContentAdjustment.create({
      data: {
        patientId,
        baseContentId,
        adjustmentType: AdjustmentType.MODIFY,
        ...data,
        createdBy,
      },
    });
  }

  async removePatientAdjustment(adjustmentId: string) {
    return this.prisma.patientContentAdjustment.delete({
      where: { id: adjustmentId },
    });
  }

  // ==================== MEDICAÇÃO PESSOAL DO PACIENTE ====================

  async addPatientMedication(
    patientId: string,
    data: {
      title: string;
      description?: string;
      dosage?: string;
      frequency?: string;
      times?: string[];
    },
  ) {
    // Monta a descrição completa com dosagem, frequência e horários
    let fullDescription = '';
    if (data.dosage) fullDescription += `Dosagem: ${data.dosage}`;
    if (data.frequency) {
      fullDescription += fullDescription ? ` | Frequência: ${data.frequency}` : `Frequência: ${data.frequency}`;
    }
    if (data.times && data.times.length > 0) {
      fullDescription += fullDescription ? ` | Horários: ${data.times.join(', ')}` : `Horários: ${data.times.join(', ')}`;
    }
    if (data.description) {
      fullDescription += fullDescription ? ` | ${data.description}` : data.description;
    }

    return this.prisma.patientContentAdjustment.create({
      data: {
        patientId,
        adjustmentType: AdjustmentType.ADD,
        contentType: ContentType.MEDICATIONS,
        category: ContentCategory.INFO,
        title: data.title,
        description: fullDescription || data.description,
        reason: 'Medicação adicionada pelo paciente',
        createdBy: patientId,
      },
    });
  }

  async updatePatientMedication(
    patientId: string,
    medicationId: string,
    data: {
      title?: string;
      description?: string;
      dosage?: string;
      frequency?: string;
      times?: string[];
    },
  ) {
    // Verificar se a medicação pertence ao paciente
    const medication = await this.prisma.patientContentAdjustment.findFirst({
      where: {
        id: medicationId,
        patientId,
        adjustmentType: AdjustmentType.ADD,
        contentType: ContentType.MEDICATIONS,
      },
    });

    if (!medication) {
      throw new Error('Medicação não encontrada ou não pertence ao paciente');
    }

    // Monta a descrição completa com dosagem, frequência e horários
    let fullDescription = '';
    if (data.dosage) fullDescription += `Dosagem: ${data.dosage}`;
    if (data.frequency) {
      fullDescription += fullDescription ? ` | Frequência: ${data.frequency}` : `Frequência: ${data.frequency}`;
    }
    if (data.times && data.times.length > 0) {
      fullDescription += fullDescription ? ` | Horários: ${data.times.join(', ')}` : `Horários: ${data.times.join(', ')}`;
    }
    if (data.description) {
      fullDescription += fullDescription ? ` | ${data.description}` : data.description;
    }

    return this.prisma.patientContentAdjustment.update({
      where: { id: medicationId },
      data: {
        title: data.title,
        description: fullDescription || data.description || medication.description,
      },
    });
  }

  async deletePatientMedication(patientId: string, medicationId: string) {
    // Verificar se a medicação pertence ao paciente
    const medication = await this.prisma.patientContentAdjustment.findFirst({
      where: {
        id: medicationId,
        patientId,
        adjustmentType: AdjustmentType.ADD,
        contentType: ContentType.MEDICATIONS,
      },
    });

    if (!medication) {
      throw new Error('Medicação não encontrada ou não pertence ao paciente');
    }

    return this.prisma.patientContentAdjustment.delete({
      where: { id: medicationId },
    });
  }

  // ==================== CONTEÚDO FINAL DO PACIENTE ====================

  async getPatientContent(
    patientId: string,
    type: ContentType,
    dayPostOp?: number,
  ) {
    // Buscar paciente
    const patient = await this.prisma.patient.findUnique({
      where: { id: patientId },
      select: { clinicId: true },
    });

    if (!patient) throw new NotFoundException('Paciente não encontrado');

    // Para MEDICATIONS, não buscar conteúdos de template da clínica
    // Apenas medicamentos adicionados especificamente para o paciente serão mostrados
    let baseContents: any[] = [];
    if (type !== ContentType.MEDICATIONS) {
      baseContents = await this.prisma.clinicContent.findMany({
        where: { clinicId: patient.clinicId, type, isActive: true },
        orderBy: [{ category: 'asc' }, { sortOrder: 'asc' }],
      });
    }

    // Buscar ajustes do paciente
    const adjustments = await this.prisma.patientContentAdjustment.findMany({
      where: {
        patientId,
        isActive: true,
        OR: [
          { contentType: type },
          { baseContent: { type } },
        ],
      },
    });

    // Processar ajustes
    const disabledIds = new Set(
      adjustments
        .filter((a) => a.adjustmentType === 'DISABLE')
        .map((a) => a.baseContentId),
    );

    const modifications = new Map(
      adjustments
        .filter((a) => a.adjustmentType === 'MODIFY')
        .map((a) => [a.baseContentId, a]),
    );

    const addedItems = adjustments.filter((a) => a.adjustmentType === 'ADD');

    // Montar lista final
    let finalContent = baseContents
      .filter((item) => !disabledIds.has(item.id))
      .map((item) => {
        const mod = modifications.get(item.id);
        return {
          id: item.id,
          type: item.type,
          category: mod?.category ?? item.category,
          title: mod?.title ?? item.title,
          description: mod?.description ?? item.description,
          validFromDay: item.validFromDay,
          validUntilDay: item.validUntilDay,
          isModified: !!mod,
          isCustom: false,
          customReason: mod?.reason,
        };
      });

    // Adicionar itens customizados do paciente
    addedItems.forEach((item) => {
      finalContent.push({
        id: item.id,
        type: item.contentType!,
        category: item.category!,
        title: item.title!,
        description: item.description,
        validFromDay: item.validFromDay,
        validUntilDay: item.validUntilDay,
        isModified: false,
        isCustom: true,
        customReason: item.reason,
      });
    });

    // Filtrar por dia pós-op
    if (dayPostOp !== undefined) {
      finalContent = finalContent.filter((item) => {
        const from = item.validFromDay ?? 0;
        const until = item.validUntilDay ?? 999;
        return dayPostOp >= from && dayPostOp <= until;
      });
    }

    // Ordenar por categoria
    const categoryOrder: Record<string, number> = {
      NORMAL: 0, ALLOWED: 0,
      WARNING: 1, RESTRICTED: 1,
      EMERGENCY: 2, PROHIBITED: 2,
      INFO: 3,
    };

    finalContent.sort((a, b) =>
      (categoryOrder[a.category] ?? 99) - (categoryOrder[b.category] ?? 99)
    );

    return {
      type,
      items: finalContent,
      totalCount: finalContent.length,
    };
  }

  // ==================== SINCRONIZAR NOVOS TEMPLATES ====================

  async syncTemplatesForClinic(clinicId: string) {
    const existingTemplateIds = await this.prisma.clinicContent.findMany({
      where: { clinicId, templateId: { not: null } },
      select: { templateId: true },
    });

    const existingIds = new Set(existingTemplateIds.map((c) => c.templateId));

    const newTemplates = await this.prisma.systemContentTemplate.findMany({
      where: {
        isActive: true,
        id: { notIn: Array.from(existingIds) as string[] },
      },
    });

    if (newTemplates.length > 0) {
      await this.prisma.clinicContent.createMany({
        data: newTemplates.map((t) => ({
          clinicId,
          templateId: t.id,
          type: t.type,
          category: t.category,
          title: t.title,
          description: t.description,
          validFromDay: t.validFromDay,
          validUntilDay: t.validUntilDay,
          sortOrder: t.sortOrder,
          isCustom: false,
        })),
      });
    }

    return { synced: newTemplates.length };
  }

  // ==================== PROTOCOLO DE TREINO POR SEMANA ====================

  async getPatientTrainingProtocol(patientId: string) {
    // Delega para o TrainingService que usa o banco de dados
    return this.trainingService.getTrainingProtocol(patientId);
  }

  // ==================== ESTATÍSTICAS ====================

  async getContentStats(clinicId: string) {
    const counts = await this.prisma.clinicContent.groupBy({
      by: ['type'],
      where: { clinicId, isActive: true },
      _count: true,
    });

    const stats: Record<string, number> = {};
    counts.forEach((c) => {
      stats[c.type] = c._count;
    });

    return stats;
  }

  // ==================== CONTENT TEMPLATES (NOVO) ====================

  private readonly logger = new Logger(ContentService.name);

  async getTemplates(clinicId: string, type?: ContentType) {
    const where: any = { clinicId };
    if (type) where.type = type;

    return this.prisma.contentTemplate.findMany({
      where,
      orderBy: [{ type: 'asc' }, { sortOrder: 'asc' }],
    });
  }

  async getTemplateById(id: string, clinicId: string) {
    const template = await this.prisma.contentTemplate.findFirst({
      where: { id, clinicId },
    });

    if (!template) throw new NotFoundException('Template não encontrado');
    return template;
  }

  async createTemplate(clinicId: string, dto: CreateTemplateDto, createdBy: string) {
    // Buscar maior sortOrder para o tipo
    const maxOrder = await this.prisma.contentTemplate.aggregate({
      where: { clinicId, type: dto.type },
      _max: { sortOrder: true },
    });

    return this.prisma.contentTemplate.create({
      data: {
        clinicId,
        type: dto.type,
        category: dto.category,
        title: dto.title,
        description: dto.description,
        validFromDay: dto.validFromDay,
        validUntilDay: dto.validUntilDay,
        sortOrder: dto.sortOrder ?? (maxOrder._max.sortOrder ?? 0) + 1,
        createdBy,
      },
    });
  }

  async updateTemplate(id: string, clinicId: string, dto: UpdateTemplateDto) {
    const template = await this.prisma.contentTemplate.findFirst({
      where: { id, clinicId },
    });

    if (!template) throw new NotFoundException('Template não encontrado');

    const updated = await this.prisma.contentTemplate.update({
      where: { id },
      data: dto,
    });

    // Incrementar versão de todos pacientes da clínica que têm overrides deste template
    await this.incrementVersionForClinicPatients(clinicId);

    return updated;
  }

  async toggleTemplate(id: string, clinicId: string) {
    const template = await this.prisma.contentTemplate.findFirst({
      where: { id, clinicId },
    });

    if (!template) throw new NotFoundException('Template não encontrado');

    const updated = await this.prisma.contentTemplate.update({
      where: { id },
      data: { isActive: !template.isActive },
    });

    await this.incrementVersionForClinicPatients(clinicId);
    return updated;
  }

  async deleteTemplate(id: string, clinicId: string) {
    const template = await this.prisma.contentTemplate.findFirst({
      where: { id, clinicId },
    });

    if (!template) throw new NotFoundException('Template não encontrado');

    await this.prisma.contentTemplate.delete({ where: { id } });
    await this.incrementVersionForClinicPatients(clinicId);

    return { success: true };
  }

  async reorderTemplates(clinicId: string, templateIds: string[]) {
    const updates = templateIds.map((id, index) =>
      this.prisma.contentTemplate.updateMany({
        where: { id, clinicId },
        data: { sortOrder: index },
      }),
    );

    await this.prisma.$transaction(updates);
    return { success: true, reordered: templateIds.length };
  }

  // ==================== PATIENT CONTENT OVERRIDES (NOVO) ====================

  async getPatientOverrides(patientId: string, clinicId: string) {
    // Verificar se paciente pertence à clínica
    const patient = await this.prisma.patient.findFirst({
      where: { id: patientId, clinicId },
    });

    if (!patient) throw new ForbiddenException('Paciente não pertence a esta clínica');

    return this.prisma.patientContentOverride.findMany({
      where: { patientId, isActive: true },
      include: { template: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createOverride(
    patientId: string,
    clinicId: string,
    dto: CreateOverrideDto,
    createdBy: string,
  ) {
    // Verificar se paciente pertence à clínica
    const patient = await this.prisma.patient.findFirst({
      where: { id: patientId, clinicId },
    });

    if (!patient) throw new ForbiddenException('Paciente não pertence a esta clínica');

    // Validação para ADD: type e title são obrigatórios
    if (dto.action === 'ADD') {
      if (!dto.type || !dto.title) {
        throw new BadRequestException('Para ADD, type e title são obrigatórios');
      }
    }

    // Validação para DISABLE e MODIFY: templateId é obrigatório
    if ((dto.action === 'DISABLE' || dto.action === 'MODIFY') && !dto.templateId) {
      throw new BadRequestException('Para DISABLE ou MODIFY, templateId é obrigatório');
    }

    // Se tem templateId, verificar se pertence à clínica
    if (dto.templateId) {
      const template = await this.prisma.contentTemplate.findFirst({
        where: { id: dto.templateId, clinicId },
      });
      if (!template) throw new NotFoundException('Template não encontrado');
    }

    const override = await this.prisma.patientContentOverride.create({
      data: {
        patientId,
        templateId: dto.templateId,
        action: dto.action as any,
        type: dto.type,
        category: dto.category,
        title: dto.title,
        description: dto.description,
        validFromDay: dto.validFromDay,
        validUntilDay: dto.validUntilDay,
        reason: dto.reason,
        createdBy,
      },
      include: { template: true },
    });

    // Incrementar versão do paciente
    await this.incrementPatientVersion(patientId);

    return override;
  }

  async updateOverride(
    overrideId: string,
    patientId: string,
    clinicId: string,
    dto: UpdateOverrideDto,
  ) {
    // Verificar se paciente pertence à clínica
    const patient = await this.prisma.patient.findFirst({
      where: { id: patientId, clinicId },
    });

    if (!patient) throw new ForbiddenException('Paciente não pertence a esta clínica');

    // Verificar se override existe e pertence ao paciente
    const override = await this.prisma.patientContentOverride.findFirst({
      where: { id: overrideId, patientId },
    });

    if (!override) throw new NotFoundException('Override não encontrado');

    const updated = await this.prisma.patientContentOverride.update({
      where: { id: overrideId },
      data: dto,
      include: { template: true },
    });

    await this.incrementPatientVersion(patientId);

    return updated;
  }

  async deleteOverride(overrideId: string, patientId: string, clinicId: string) {
    // Verificar se paciente pertence à clínica
    const patient = await this.prisma.patient.findFirst({
      where: { id: patientId, clinicId },
    });

    if (!patient) throw new ForbiddenException('Paciente não pertence a esta clínica');

    // Verificar se override existe e pertence ao paciente
    const override = await this.prisma.patientContentOverride.findFirst({
      where: { id: overrideId, patientId },
    });

    if (!override) throw new NotFoundException('Override não encontrado');

    await this.prisma.patientContentOverride.delete({ where: { id: overrideId } });
    await this.incrementPatientVersion(patientId);

    return { success: true };
  }

  // ==================== PATIENT CONTENT (com Templates) ====================

  async getPatientContentFromTemplates(patientId: string, type?: ContentType) {
    // Buscar paciente com clinicId e surgeryDate
    const patient = await this.prisma.patient.findUnique({
      where: { id: patientId },
      select: { id: true, clinicId: true, surgeryDate: true },
    });

    if (!patient) throw new NotFoundException('Paciente não encontrado');

    // Calcular dia pós-operatório
    const daysPostOp = this.calculateDaysPostOp(patient.surgeryDate);

    // Buscar templates ativos da clínica
    const whereTemplates: any = {
      clinicId: patient.clinicId,
      isActive: true,
    };
    if (type) whereTemplates.type = type;

    const templates = await this.prisma.contentTemplate.findMany({
      where: whereTemplates,
      orderBy: [{ type: 'asc' }, { sortOrder: 'asc' }],
    });

    // Buscar overrides do paciente
    const overrides = await this.prisma.patientContentOverride.findMany({
      where: {
        patientId,
        isActive: true,
      },
    });

    // Mesclar templates com overrides
    const contents = this.mergeTemplatesWithOverrides(templates, overrides, daysPostOp);

    // Buscar/criar estado de sync
    const state = await this.getOrCreatePatientState(patientId);

    return {
      version: state.version,
      lastUpdated: state.updatedAt,
      contents,
    };
  }

  private mergeTemplatesWithOverrides(
    templates: any[],
    overrides: any[],
    daysPostOp: number | null,
  ) {
    const result: any[] = [];

    // Map de overrides por templateId
    const overrideMap = new Map<string, any>();
    const disabledTemplates = new Set<string>();
    const addedContents: any[] = [];

    for (const override of overrides) {
      if (override.action === 'DISABLE' && override.templateId) {
        disabledTemplates.add(override.templateId);
      } else if (override.action === 'MODIFY' && override.templateId) {
        overrideMap.set(override.templateId, override);
      } else if (override.action === 'ADD') {
        addedContents.push(override);
      }
    }

    // Processar templates
    for (const template of templates) {
      // Pular se desabilitado
      if (disabledTemplates.has(template.id)) continue;

      // Verificar validade temporal
      if (!this.isContentValidForDay(template, daysPostOp)) continue;

      const override = overrideMap.get(template.id);

      result.push({
        id: template.id,
        type: template.type,
        category: override?.category ?? template.category,
        title: override?.title ?? template.title,
        description: override?.description ?? template.description,
        validFromDay: override?.validFromDay ?? template.validFromDay,
        validUntilDay: override?.validUntilDay ?? template.validUntilDay,
        source: 'template',
        isModified: !!override,
      });
    }

    // Adicionar conteúdos ADD
    for (const added of addedContents) {
      if (!this.isContentValidForDay(added, daysPostOp)) continue;

      result.push({
        id: added.id,
        type: added.type,
        category: added.category,
        title: added.title,
        description: added.description,
        validFromDay: added.validFromDay,
        validUntilDay: added.validUntilDay,
        source: 'override',
        isModified: false,
      });
    }

    return result;
  }

  private isContentValidForDay(content: any, daysPostOp: number | null): boolean {
    if (daysPostOp === null) return true; // Sem data de cirurgia, mostra tudo

    const from = content.validFromDay ?? 0;
    const until = content.validUntilDay ?? 9999;

    return daysPostOp >= from && daysPostOp <= until;
  }

  private calculateDaysPostOp(surgeryDate: Date | null): number | null {
    if (!surgeryDate) return null;

    const now = new Date();
    const surgery = new Date(surgeryDate);
    const diffTime = now.getTime() - surgery.getTime();
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));

    return diffDays >= 0 ? diffDays : null;
  }

  // ==================== SYNC / VERSIONING ====================

  async checkSync(patientId: string, clientVersion: number) {
    const state = await this.prisma.patientContentState.findUnique({
      where: { patientId },
    });

    const currentVersion = state?.version ?? 1;

    return {
      hasChanges: currentVersion > clientVersion,
      currentVersion,
      clientVersion,
    };
  }

  async getOrCreatePatientState(patientId: string) {
    let state = await this.prisma.patientContentState.findUnique({
      where: { patientId },
    });

    if (!state) {
      state = await this.prisma.patientContentState.create({
        data: { patientId, version: 1 },
      });
    }

    return state;
  }

  private async incrementPatientVersion(patientId: string): Promise<void> {
    await this.prisma.patientContentState.upsert({
      where: { patientId },
      update: { version: { increment: 1 } },
      create: { patientId, version: 1 },
    });
  }

  private async incrementVersionForClinicPatients(clinicId: string): Promise<void> {
    // Buscar todos pacientes da clínica
    const patients = await this.prisma.patient.findMany({
      where: { clinicId },
      select: { id: true },
    });

    if (patients.length === 0) return;

    // Incrementar versão de cada um
    await this.prisma.$transaction(
      patients.map((p) =>
        this.prisma.patientContentState.upsert({
          where: { patientId: p.id },
          update: { version: { increment: 1 } },
          create: { patientId: p.id, version: 1 },
        }),
      ),
    );
  }

  // ==================== PREVIEW (Admin) ====================

  async getPatientContentPreview(patientId: string, clinicId: string, type?: ContentType) {
    // Verificar se paciente pertence à clínica
    const patient = await this.prisma.patient.findFirst({
      where: { id: patientId, clinicId },
      select: { id: true, surgeryDate: true },
    });

    if (!patient) throw new ForbiddenException('Paciente não pertence a esta clínica');

    return this.getPatientContentFromTemplates(patientId, type);
  }
}
