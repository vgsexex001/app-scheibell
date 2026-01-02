import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ContentType, ContentCategory, AdjustmentType } from '@prisma/client';

@Injectable()
export class ContentService {
  constructor(private prisma: PrismaService) {}

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
      reason?: string;
    },
    createdBy: string,
  ) {
    return this.prisma.patientContentAdjustment.create({
      data: {
        patientId,
        adjustmentType: AdjustmentType.ADD,
        contentType: data.contentType,
        category: data.category,
        title: data.title,
        description: data.description,
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

    // Buscar conteúdos da clínica
    const baseContents = await this.prisma.clinicContent.findMany({
      where: { clinicId: patient.clinicId, type, isActive: true },
      orderBy: [{ category: 'asc' }, { sortOrder: 'asc' }],
    });

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
    // Buscar paciente com data da cirurgia
    const patient = await this.prisma.patient.findUnique({
      where: { id: patientId },
      select: {
        clinicId: true,
        surgeryDate: true,
        phone: true,
        cpf: true,
        birthDate: true,
        surgeryType: true,
      },
    });

    // Usar frequência cardíaca basal padrão (pode ser personalizado no futuro)
    const basalHeartRate = 65;

    if (!patient) throw new NotFoundException('Paciente não encontrado');

    // Calcular dias desde a cirurgia
    // Usar apenas a data (sem hora) para evitar problemas de timezone
    const surgeryDate = patient.surgeryDate || new Date();
    const today = new Date();

    // Normalizar para meia-noite para cálculo correto de dias
    const surgeryStart = new Date(surgeryDate);
    surgeryStart.setHours(0, 0, 0, 0);
    const todayStart = new Date(today);
    todayStart.setHours(0, 0, 0, 0);

    const diffTime = todayStart.getTime() - surgeryStart.getTime();
    const daysSinceSurgery = Math.max(0, Math.floor(diffTime / (1000 * 60 * 60 * 24)));

    // Calcular semana atual (1-indexed)
    // Dia 0-6 = Semana 1, Dia 7-13 = Semana 2, etc.
    const currentWeek = Math.floor(daysSinceSurgery / 7) + 1;

    // Definir as semanas do protocolo
    const weeks = [
      {
        weekNumber: 1,
        label: 'Sem 1',
        title: 'Semana 1',
        dayRange: '+0 a +7 dias',
        startDay: 0,
        endDay: 7,
        objective: 'Repouso e recuperação inicial',
        maxHeartRate: basalHeartRate + 10,
        heartRateLabel: 'Basal + 10 bpm',
        canDo: [
          'Caminhadas leves de 5-10 min',
          'Exercícios respiratórios',
          'Alongamentos suaves no leito',
        ],
        avoid: [
          'Esforço físico',
          'Carregar peso',
          'Exercícios abdominais',
        ],
      },
      {
        weekNumber: 2,
        label: 'Sem 2',
        title: 'Semana 2',
        dayRange: '+7 a +14 dias',
        startDay: 7,
        endDay: 14,
        objective: 'Aumento gradual da mobilidade',
        maxHeartRate: basalHeartRate + 15,
        heartRateLabel: 'Basal + 15 bpm',
        canDo: [
          'Caminhadas de 15-20 min',
          'Alongamentos suaves',
          'Atividades domésticas leves',
        ],
        avoid: [
          'Exercícios intensos',
          'Peso acima de 2kg',
          'Movimentos bruscos',
        ],
      },
      {
        weekNumber: 3,
        label: 'Sem 3',
        title: 'Semana 3',
        dayRange: '+14 a +21 dias',
        startDay: 14,
        endDay: 21,
        objective: 'Introdução de isometria unilateral leve',
        maxHeartRate: basalHeartRate + 20,
        heartRateLabel: 'Basal + 20 bpm',
        canDo: [
          'Isometria unilateral MMII/MMSS',
          'Caminhadas de 20-30 min',
          'Bicicleta ergométrica leve',
        ],
        avoid: [
          'Exercícios bilaterais',
          'Peso acima de 3kg',
          'Impacto',
        ],
      },
      {
        weekNumber: 4,
        label: 'Sem 4',
        title: 'Semana 4',
        dayRange: '+21 a +28 dias',
        startDay: 21,
        endDay: 28,
        objective: 'Progressão para exercícios bilaterais leves',
        maxHeartRate: basalHeartRate + 25,
        heartRateLabel: 'Basal + 25 bpm',
        canDo: [
          'Exercícios bilaterais leves',
          'Caminhadas de 30-40 min',
          'Yoga/Pilates adaptado',
        ],
        avoid: [
          'Exercícios abdominais diretos',
          'Peso acima de 5kg',
          'Corrida',
        ],
      },
      {
        weekNumber: 5,
        label: 'Sem 5',
        title: 'Semana 5',
        dayRange: '+28 a +35 dias',
        startDay: 28,
        endDay: 35,
        objective: 'Introdução de resistência leve',
        maxHeartRate: basalHeartRate + 30,
        heartRateLabel: 'Basal + 30 bpm',
        canDo: [
          'Musculação leve (máquinas)',
          'Natação leve',
          'Exercícios funcionais adaptados',
        ],
        avoid: [
          'Exercícios de alta intensidade',
          'Peso livre pesado',
          'Impacto',
        ],
      },
      {
        weekNumber: 6,
        label: 'Sem 6',
        title: 'Semana 6',
        dayRange: '+35 a +42 dias',
        startDay: 35,
        endDay: 42,
        objective: 'Progressão para atividade moderada',
        maxHeartRate: basalHeartRate + 35,
        heartRateLabel: 'Basal + 35 bpm',
        canDo: [
          'Musculação moderada',
          'Corrida leve/caminhada rápida',
          'Exercícios aeróbicos',
        ],
        avoid: [
          'CrossFit/HIIT',
          'Exercícios abdominais intensos',
          'Competições',
        ],
      },
      {
        weekNumber: 7,
        label: 'Sem 7',
        title: 'Semana 7',
        dayRange: '+42 a +49 dias',
        startDay: 42,
        endDay: 49,
        objective: 'Retorno gradual às atividades normais',
        maxHeartRate: basalHeartRate + 40,
        heartRateLabel: 'Basal + 40 bpm',
        canDo: [
          'Maioria dos exercícios',
          'Corrida moderada',
          'Esportes recreativos',
        ],
        avoid: [
          'Atividades de alto impacto',
          'Esportes de contato',
        ],
      },
      {
        weekNumber: 8,
        label: 'Sem 8+',
        title: 'Semana 8+',
        dayRange: '+49 dias em diante',
        startDay: 49,
        endDay: 999,
        objective: 'Liberação para atividades completas (com aval médico)',
        maxHeartRate: null,
        heartRateLabel: 'Sem restrição',
        canDo: [
          'Todas as atividades (com liberação médica)',
          'Retorno completo à rotina de exercícios',
          'Esportes em geral',
        ],
        avoid: [],
      },
    ];

    // Adicionar status a cada semana
    const weeksWithStatus = weeks.map((week) => {
      let status: 'COMPLETED' | 'CURRENT' | 'FUTURE';

      if (daysSinceSurgery >= week.endDay) {
        status = 'COMPLETED';
      } else if (daysSinceSurgery >= week.startDay && daysSinceSurgery < week.endDay) {
        status = 'CURRENT';
      } else {
        status = 'FUTURE';
      }

      return {
        ...week,
        status,
      };
    });

    return {
      patientId,
      surgeryDate: surgeryDate.toISOString(),
      daysSinceSurgery,
      currentWeek,
      basalHeartRate,
      weeks: weeksWithStatus,
    };
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
}
