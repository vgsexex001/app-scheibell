import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { TrainingWeekStatus } from '@prisma/client';

@Injectable()
export class TrainingService {
  constructor(private prisma: PrismaService) {}

  /**
   * Retorna o dashboard de treino do paciente
   * Inclui: semana atual, dias desde cirurgia, progresso, semanas com status
   */
  async getTrainingDashboard(patientId: string) {
    // Buscar dados do paciente
    const patient = await this.prisma.patient.findUnique({
      where: { id: patientId },
      select: { surgeryDate: true, clinicId: true },
    });

    if (!patient) {
      throw new NotFoundException('Paciente não encontrado');
    }

    if (!patient.surgeryDate) {
      throw new BadRequestException('Data de cirurgia não definida');
    }

    // Calcular dias desde a cirurgia (normalizado para evitar problemas de timezone)
    const now = new Date();
    const surgery = new Date(patient.surgeryDate);

    // Normalizar para "dia" (sem hora) para evitar problemas de timezone
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const surgeryDay = new Date(
      surgery.getFullYear(),
      surgery.getMonth(),
      surgery.getDate(),
    );

    const daysSinceSurgery = Math.floor(
      (today.getTime() - surgeryDay.getTime()) / (1000 * 60 * 60 * 24),
    );

    // Semana atual (sempre começa em 1): dias 0-6 = semana 1, dias 7-13 = semana 2, etc.
    const currentWeekNumber = Math.max(1, Math.floor(daysSinceSurgery / 7) + 1);

    console.log(
      `[Training] surgeryDate=${surgeryDay.toISOString()}, today=${today.toISOString()}, daysSince=${daysSinceSurgery}, currentWeek=${currentWeekNumber}`,
    );

    // Buscar protocolo (preferência: clínica > padrão)
    let protocol = await this.prisma.trainingProtocol.findFirst({
      where: {
        clinicId: patient.clinicId,
        isActive: true,
      },
      include: {
        weeks: {
          orderBy: { weekNumber: 'asc' },
          include: {
            sessions: { orderBy: { sessionNumber: 'asc' } },
          },
        },
      },
    });

    if (!protocol) {
      protocol = await this.prisma.trainingProtocol.findFirst({
        where: { isDefault: true, isActive: true },
        include: {
          weeks: {
            orderBy: { weekNumber: 'asc' },
            include: {
              sessions: { orderBy: { sessionNumber: 'asc' } },
            },
          },
        },
      });
    }

    if (!protocol) {
      throw new NotFoundException('Protocolo de treino não encontrado');
    }

    // Buscar ou criar progresso do paciente
    await this.ensurePatientProgress(patientId, protocol.id, currentWeekNumber);

    // Buscar progresso atualizado
    const patientProgress = await this.prisma.patientTrainingProgress.findMany({
      where: { patientId },
      include: { week: true },
    });

    // Buscar sessões completadas
    const completedSessions = await this.prisma.patientSessionCompletion.findMany({
      where: { patientId },
      select: { sessionId: true },
    });
    const completedSessionIds = new Set(completedSessions.map((s) => s.sessionId));

    // Calcular progresso geral
    const totalWeeks = protocol.weeks.length;
    const completedWeeks = patientProgress.filter(
      (p) => p.status === TrainingWeekStatus.COMPLETED,
    ).length;
    const progressPercent = Math.round((completedWeeks / totalWeeks) * 100);

    // Montar resposta com semanas e status
    const weeks = protocol.weeks.map((week) => {
      const progress = patientProgress.find((p) => p.weekId === week.id);

      // Determinar status baseado nos dias desde a cirurgia
      let status: string;
      if (week.weekNumber < currentWeekNumber) {
        status = 'COMPLETED';
      } else if (week.weekNumber === currentWeekNumber) {
        status = 'CURRENT';
      } else {
        status = 'FUTURE';
      }

      // Sessões da semana com status de conclusão
      const sessions = week.sessions.map((session) => ({
        id: session.id,
        sessionNumber: session.sessionNumber,
        name: session.name,
        description: session.description,
        duration: session.duration,
        intensity: session.intensity,
        completed: completedSessionIds.has(session.id),
      }));

      const completedSessionsCount = sessions.filter((s) => s.completed).length;

      return {
        id: week.id,
        weekNumber: week.weekNumber,
        title: week.title,
        dayRange: week.dayRange,
        objective: week.objective,
        maxHeartRate: week.maxHeartRate,
        heartRateLabel: week.heartRateLabel,
        canDo: week.canDo,
        avoid: week.avoid,
        safetyCriteria: week.safetyCriteria,
        status,
        sessions,
        totalSessions: sessions.length,
        completedSessions: completedSessionsCount,
        sessionProgress: sessions.length > 0
          ? Math.round((completedSessionsCount / sessions.length) * 100)
          : 0,
      };
    });

    // Dados da semana atual
    const currentWeek = weeks.find((w) => w.weekNumber === currentWeekNumber);

    return {
      protocol: {
        id: protocol.id,
        name: protocol.name,
        totalWeeks: protocol.totalWeeks,
      },
      daysSinceSurgery,
      currentWeek: Math.min(currentWeekNumber, protocol.totalWeeks),
      basalHeartRate: 65, // Valor padrão, pode ser configurável
      progressPercent,
      completedWeeks,
      totalWeeks,
      weeks,
      currentWeekDetails: currentWeek || null,
    };
  }

  /**
   * Retorna o protocolo de treino formatado para o front-end
   * (formato esperado pelo endpoint /content/patient/training-protocol)
   * Inclui personalizações feitas pelo admin para este paciente
   */
  async getTrainingProtocol(patientId: string) {
    const dashboard = await this.getTrainingDashboard(patientId);

    // Buscar personalizações do paciente
    const adjustments = await this.prisma.patientContentAdjustment.findMany({
      where: {
        patientId,
        contentType: 'TRAINING',
        isActive: true,
      },
    });

    console.log(`[Training] getTrainingProtocol - patientId: ${patientId}`);
    console.log(`[Training] adjustments encontrados: ${adjustments.length}`);
    adjustments.forEach((adj, i) => {
      console.log(`[Training] adjustment[${i}]: type=${adj.adjustmentType}, title=${adj.title}, fromDay=${adj.validFromDay}, untilDay=${adj.validUntilDay}`);
    });

    // Aplicar personalizações às semanas
    const weeksWithAdjustments = dashboard.weeks.map((week) => {
      // Filtrar personalizações válidas para esta semana
      const weekStartDay = (week.weekNumber - 1) * 7 + 1;
      const weekEndDay = week.weekNumber * 7;

      const weekAdjustments = adjustments.filter((adj) => {
        // Verificar se o ajuste é válido para esta semana
        const fromDay = adj.validFromDay ?? 0;
        const untilDay = adj.validUntilDay ?? 999;
        return fromDay <= weekEndDay && untilDay >= weekStartDay;
      });

      // Adicionar exercícios personalizados à lista de sessões
      const customExercises = weekAdjustments
        .filter((adj) => adj.adjustmentType === 'ADD')
        .map((adj) => ({
          id: adj.id,
          name: adj.title || 'Exercício personalizado',
          description: adj.description,
          isCustom: true,
        }));

      // Buscar ajuste MODIFY para canDo/avoid desta semana
      const modifyAdjustment = weekAdjustments.find(
        (adj) => adj.adjustmentType === 'MODIFY'
      );

      // Aplicar ajustes de canDo/avoid se existirem
      const canDo = modifyAdjustment?.canDo?.length ? modifyAdjustment.canDo : week.canDo;
      const avoid = modifyAdjustment?.avoid?.length ? modifyAdjustment.avoid : week.avoid;

      return {
        weekNumber: week.weekNumber,
        title: week.title,
        dayRange: week.dayRange,
        status: week.status,
        objective: week.objective,
        maxHeartRate: week.maxHeartRate,
        heartRateLabel: week.heartRateLabel,
        canDo,
        avoid,
        safetyCriteria: week.safetyCriteria,
        customExercises,
      };
    });

    return {
      currentWeek: dashboard.currentWeek,
      daysSinceSurgery: dashboard.daysSinceSurgery,
      basalHeartRate: dashboard.basalHeartRate,
      weeks: weeksWithAdjustments,
    };
  }

  /**
   * Marca uma sessão como concluída
   */
  async completeSession(patientId: string, sessionId: string, notes?: string) {
    // Verificar se a sessão existe
    const session = await this.prisma.trainingSession.findUnique({
      where: { id: sessionId },
      include: { week: true },
    });

    if (!session) {
      throw new NotFoundException('Sessão não encontrada');
    }

    // Verificar se já está completa
    const existing = await this.prisma.patientSessionCompletion.findUnique({
      where: {
        patientId_sessionId: {
          patientId,
          sessionId,
        },
      },
    });

    if (existing) {
      // Atualizar notas se houver
      if (notes) {
        await this.prisma.patientSessionCompletion.update({
          where: { id: existing.id },
          data: { notes },
        });
      }
      return { message: 'Sessão já marcada como concluída', alreadyCompleted: true };
    }

    // Marcar como concluída
    await this.prisma.patientSessionCompletion.create({
      data: {
        patientId,
        sessionId,
        notes,
      },
    });

    // Verificar se todas as sessões da semana foram concluídas
    await this.checkWeekCompletion(patientId, session.weekId);

    return { message: 'Sessão marcada como concluída', alreadyCompleted: false };
  }

  /**
   * Remove a conclusão de uma sessão
   */
  async uncompleteSession(patientId: string, sessionId: string) {
    const existing = await this.prisma.patientSessionCompletion.findUnique({
      where: {
        patientId_sessionId: {
          patientId,
          sessionId,
        },
      },
    });

    if (!existing) {
      throw new NotFoundException('Sessão não estava marcada como concluída');
    }

    await this.prisma.patientSessionCompletion.delete({
      where: { id: existing.id },
    });

    return { message: 'Conclusão da sessão removida' };
  }

  /**
   * Retorna detalhes de uma semana específica
   */
  async getWeekDetails(patientId: string, weekNumber: number) {
    const dashboard = await this.getTrainingDashboard(patientId);
    const week = dashboard.weeks.find((w) => w.weekNumber === weekNumber);

    if (!week) {
      throw new NotFoundException(`Semana ${weekNumber} não encontrada`);
    }

    return week;
  }

  /**
   * Retorna o progresso geral do paciente no treino
   */
  async getProgress(patientId: string) {
    const dashboard = await this.getTrainingDashboard(patientId);

    return {
      currentWeek: dashboard.currentWeek,
      totalWeeks: dashboard.totalWeeks,
      completedWeeks: dashboard.completedWeeks,
      progressPercent: dashboard.progressPercent,
      daysSinceSurgery: dashboard.daysSinceSurgery,
      weeks: dashboard.weeks.map((w) => ({
        weekNumber: w.weekNumber,
        title: w.title,
        status: w.status,
        sessionProgress: w.sessionProgress,
        completedSessions: w.completedSessions,
        totalSessions: w.totalSessions,
      })),
    };
  }

  // ==================== MÉTODOS PRIVADOS ====================

  /**
   * Garante que o paciente tem progresso inicializado para todas as semanas
   */
  private async ensurePatientProgress(
    patientId: string,
    protocolId: string,
    currentWeekNumber: number,
  ) {
    const protocol = await this.prisma.trainingProtocol.findUnique({
      where: { id: protocolId },
      include: { weeks: { orderBy: { weekNumber: 'asc' } } },
    });

    if (!protocol) return;

    for (const week of protocol.weeks) {
      const existing = await this.prisma.patientTrainingProgress.findUnique({
        where: {
          patientId_weekId: {
            patientId,
            weekId: week.id,
          },
        },
      });

      if (!existing) {
        let status: TrainingWeekStatus;
        if (week.weekNumber < currentWeekNumber) {
          status = TrainingWeekStatus.COMPLETED;
        } else if (week.weekNumber === currentWeekNumber) {
          status = TrainingWeekStatus.CURRENT;
        } else {
          status = TrainingWeekStatus.FUTURE;
        }

        await this.prisma.patientTrainingProgress.create({
          data: {
            patientId,
            weekId: week.id,
            status,
            startedAt: week.weekNumber <= currentWeekNumber ? new Date() : null,
          },
        });
      }
    }
  }

  /**
   * Verifica se todas as sessões da semana foram concluídas
   */
  private async checkWeekCompletion(patientId: string, weekId: string) {
    const week = await this.prisma.trainingWeek.findUnique({
      where: { id: weekId },
      include: { sessions: true },
    });

    if (!week) return;

    const completedSessions = await this.prisma.patientSessionCompletion.count({
      where: {
        patientId,
        sessionId: { in: week.sessions.map((s) => s.id) },
      },
    });

    // Se todas as sessões foram concluídas, marcar semana como completa
    if (completedSessions >= week.sessions.length) {
      await this.prisma.patientTrainingProgress.updateMany({
        where: { patientId, weekId },
        data: {
          status: TrainingWeekStatus.COMPLETED,
          completedAt: new Date(),
        },
      });
    }
  }

  // ==================== MÉTODOS ADMIN ====================

  /**
   * Lista protocolos para admin
   */
  async getProtocolsForAdmin(clinicId: string) {
    // Buscar protocolos da clínica e o padrão
    const protocols = await this.prisma.trainingProtocol.findMany({
      where: {
        OR: [
          { clinicId },
          { isDefault: true },
        ],
        isActive: true,
      },
      include: {
        weeks: {
          orderBy: { weekNumber: 'asc' },
          include: {
            _count: { select: { sessions: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return protocols.map(protocol => ({
      id: protocol.id,
      name: protocol.name,
      surgeryType: protocol.surgeryType,
      description: protocol.description,
      totalWeeks: protocol.totalWeeks,
      isDefault: protocol.isDefault,
      isClinicOwned: protocol.clinicId === clinicId,
      weeks: protocol.weeks.map(week => ({
        id: week.id,
        weekNumber: week.weekNumber,
        title: week.title,
        dayRange: week.dayRange,
        objective: week.objective,
        heartRateLabel: week.heartRateLabel,
        sessionsCount: week._count.sessions,
      })),
    }));
  }

  /**
   * Detalhes completos de um protocolo para admin
   */
  async getProtocolDetailsForAdmin(protocolId: string, clinicId: string) {
    const protocol = await this.prisma.trainingProtocol.findUnique({
      where: { id: protocolId },
      include: {
        weeks: {
          orderBy: { weekNumber: 'asc' },
          include: {
            sessions: { orderBy: { sortOrder: 'asc' } },
          },
        },
      },
    });

    if (!protocol) {
      throw new NotFoundException('Protocolo não encontrado');
    }

    // Verificar permissão (clínica dona ou protocolo padrão)
    if (protocol.clinicId && protocol.clinicId !== clinicId && !protocol.isDefault) {
      throw new NotFoundException('Protocolo não encontrado');
    }

    return {
      id: protocol.id,
      name: protocol.name,
      surgeryType: protocol.surgeryType,
      description: protocol.description,
      totalWeeks: protocol.totalWeeks,
      isDefault: protocol.isDefault,
      isClinicOwned: protocol.clinicId === clinicId,
      weeks: protocol.weeks.map(week => ({
        id: week.id,
        weekNumber: week.weekNumber,
        title: week.title,
        dayRange: week.dayRange,
        objective: week.objective,
        maxHeartRate: week.maxHeartRate,
        heartRateLabel: week.heartRateLabel,
        canDo: week.canDo,
        avoid: week.avoid,
        sessions: week.sessions.map(session => ({
          id: session.id,
          sessionNumber: session.sessionNumber,
          name: session.name,
          description: session.description,
          duration: session.duration,
          intensity: session.intensity,
          sortOrder: session.sortOrder,
        })),
      })),
    };
  }

  /**
   * Lista semanas de um protocolo
   */
  async getWeeksForAdmin(protocolId: string, clinicId: string) {
    const protocol = await this.prisma.trainingProtocol.findUnique({
      where: { id: protocolId },
      include: {
        weeks: {
          orderBy: { weekNumber: 'asc' },
          include: {
            sessions: { orderBy: { sortOrder: 'asc' } },
          },
        },
      },
    });

    if (!protocol) {
      throw new NotFoundException('Protocolo não encontrado');
    }

    if (protocol.clinicId && protocol.clinicId !== clinicId && !protocol.isDefault) {
      throw new NotFoundException('Protocolo não encontrado');
    }

    return protocol.weeks.map(week => ({
      id: week.id,
      weekNumber: week.weekNumber,
      title: week.title,
      dayRange: week.dayRange,
      objective: week.objective,
      maxHeartRate: week.maxHeartRate,
      heartRateLabel: week.heartRateLabel,
      canDo: week.canDo,
      avoid: week.avoid,
      sessions: week.sessions,
    }));
  }

  /**
   * Detalhes de uma semana
   */
  async getWeekDetailsForAdmin(weekId: string, clinicId: string) {
    const week = await this.prisma.trainingWeek.findUnique({
      where: { id: weekId },
      include: {
        protocol: true,
        sessions: { orderBy: { sortOrder: 'asc' } },
      },
    });

    if (!week) {
      throw new NotFoundException('Semana não encontrada');
    }

    if (week.protocol.clinicId && week.protocol.clinicId !== clinicId && !week.protocol.isDefault) {
      throw new NotFoundException('Semana não encontrada');
    }

    return {
      id: week.id,
      weekNumber: week.weekNumber,
      title: week.title,
      dayRange: week.dayRange,
      objective: week.objective,
      maxHeartRate: week.maxHeartRate,
      heartRateLabel: week.heartRateLabel,
      canDo: week.canDo,
      avoid: week.avoid,
      sessions: week.sessions.map(session => ({
        id: session.id,
        sessionNumber: session.sessionNumber,
        name: session.name,
        description: session.description,
        duration: session.duration,
        intensity: session.intensity,
        sortOrder: session.sortOrder,
      })),
    };
  }

  /**
   * Atualiza uma semana
   */
  async updateWeekForAdmin(weekId: string, dto: any, clinicId: string) {
    const week = await this.prisma.trainingWeek.findUnique({
      where: { id: weekId },
      include: { protocol: true },
    });

    if (!week) {
      throw new NotFoundException('Semana não encontrada');
    }

    // Verificar se a clínica pode editar (só pode editar se for dona do protocolo)
    if (week.protocol.clinicId !== clinicId) {
      throw new BadRequestException('Você não tem permissão para editar este protocolo');
    }

    return this.prisma.trainingWeek.update({
      where: { id: weekId },
      data: {
        title: dto.title,
        dayRange: dto.dayRange,
        objective: dto.objective,
        maxHeartRate: dto.maxHeartRate,
        heartRateLabel: dto.heartRateLabel,
        canDo: dto.canDo,
        avoid: dto.avoid,
      },
    });
  }

  /**
   * Cria uma sessão
   */
  async createSessionForAdmin(dto: any, clinicId: string) {
    const week = await this.prisma.trainingWeek.findUnique({
      where: { id: dto.weekId },
      include: { protocol: true, sessions: true },
    });

    if (!week) {
      throw new NotFoundException('Semana não encontrada');
    }

    if (week.protocol.clinicId !== clinicId) {
      throw new BadRequestException('Você não tem permissão para editar este protocolo');
    }

    const maxSessionNumber = week.sessions.reduce((max, s) => Math.max(max, s.sessionNumber), 0);
    const maxSortOrder = week.sessions.reduce((max, s) => Math.max(max, s.sortOrder), 0);

    return this.prisma.trainingSession.create({
      data: {
        weekId: dto.weekId,
        sessionNumber: maxSessionNumber + 1,
        name: dto.name,
        description: dto.description,
        duration: dto.duration,
        intensity: dto.intensity,
        sortOrder: maxSortOrder + 1,
      },
    });
  }

  /**
   * Atualiza uma sessão
   */
  async updateSessionForAdmin(sessionId: string, dto: any, clinicId: string) {
    const session = await this.prisma.trainingSession.findUnique({
      where: { id: sessionId },
      include: { week: { include: { protocol: true } } },
    });

    if (!session) {
      throw new NotFoundException('Sessão não encontrada');
    }

    if (session.week.protocol.clinicId !== clinicId) {
      throw new BadRequestException('Você não tem permissão para editar este protocolo');
    }

    return this.prisma.trainingSession.update({
      where: { id: sessionId },
      data: {
        name: dto.name,
        description: dto.description,
        duration: dto.duration,
        intensity: dto.intensity,
      },
    });
  }

  /**
   * Remove uma sessão
   */
  async deleteSessionForAdmin(sessionId: string, clinicId: string) {
    const session = await this.prisma.trainingSession.findUnique({
      where: { id: sessionId },
      include: { week: { include: { protocol: true } } },
    });

    if (!session) {
      throw new NotFoundException('Sessão não encontrada');
    }

    if (session.week.protocol.clinicId !== clinicId) {
      throw new BadRequestException('Você não tem permissão para editar este protocolo');
    }

    await this.prisma.trainingSession.delete({
      where: { id: sessionId },
    });

    return { message: 'Sessão removida com sucesso' };
  }

  /**
   * Reordena sessões
   */
  async reorderSessionsForAdmin(weekId: string, sessionIds: string[], clinicId: string) {
    const week = await this.prisma.trainingWeek.findUnique({
      where: { id: weekId },
      include: { protocol: true },
    });

    if (!week) {
      throw new NotFoundException('Semana não encontrada');
    }

    if (week.protocol.clinicId !== clinicId) {
      throw new BadRequestException('Você não tem permissão para editar este protocolo');
    }

    // Atualizar sortOrder de cada sessão
    await Promise.all(
      sessionIds.map((sessionId, index) =>
        this.prisma.trainingSession.update({
          where: { id: sessionId },
          data: { sortOrder: index },
        }),
      ),
    );

    return { message: 'Ordem atualizada com sucesso' };
  }

  /**
   * Lista pacientes com status de treino
   */
  async getPatientsTrainingStatus(clinicId: string) {
    const patients = await this.prisma.patient.findMany({
      where: { clinicId },
      include: {
        user: { select: { name: true, email: true } },
        trainingProgress: {
          include: { week: true },
          orderBy: { week: { weekNumber: 'asc' } },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return patients.map(patient => {
      const currentProgress = patient.trainingProgress.find(
        p => p.status === TrainingWeekStatus.CURRENT,
      );
      const completedWeeks = patient.trainingProgress.filter(
        p => p.status === TrainingWeekStatus.COMPLETED,
      ).length;

      // Calcular dias desde cirurgia
      let daysSinceSurgery = 0;
      if (patient.surgeryDate) {
        const now = new Date();
        const surgery = new Date(patient.surgeryDate);
        daysSinceSurgery = Math.floor(
          (now.getTime() - surgery.getTime()) / (1000 * 60 * 60 * 24),
        );
      }

      return {
        id: patient.id,
        name: patient.user?.name || patient.name || 'Sem nome',
        email: patient.user?.email || patient.email,
        surgeryDate: patient.surgeryDate,
        daysSinceSurgery,
        currentWeek: currentProgress?.week?.weekNumber || 1,
        completedWeeks,
        totalWeeks: patient.trainingProgress.length || 8,
      };
    });
  }

  /**
   * Obtém treino de um paciente para admin
   * Lida com pacientes sem data de cirurgia retornando dados básicos
   */
  async getPatientTrainingForAdmin(patientId: string, clinicId: string) {
    const patient = await this.prisma.patient.findUnique({
      where: { id: patientId },
      include: { user: { select: { name: true, email: true } } },
    });

    if (!patient || patient.clinicId !== clinicId) {
      throw new NotFoundException('Paciente não encontrado');
    }

    // Buscar ajustes personalizados
    const adjustments = await this.prisma.patientContentAdjustment.findMany({
      where: {
        patientId,
        contentType: 'TRAINING',
        isActive: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    // Se não tem data de cirurgia, retornar estrutura básica com o protocolo
    if (!patient.surgeryDate) {
      // Buscar protocolo (preferência: clínica > padrão)
      let protocol = await this.prisma.trainingProtocol.findFirst({
        where: {
          clinicId: patient.clinicId,
          isActive: true,
        },
        include: {
          weeks: {
            orderBy: { weekNumber: 'asc' },
            include: {
              sessions: { orderBy: { sessionNumber: 'asc' } },
            },
          },
        },
      });

      if (!protocol) {
        protocol = await this.prisma.trainingProtocol.findFirst({
          where: { isDefault: true, isActive: true },
          include: {
            weeks: {
              orderBy: { weekNumber: 'asc' },
              include: {
                sessions: { orderBy: { sessionNumber: 'asc' } },
              },
            },
          },
        });
      }

      // Montar semanas do protocolo sem status de progresso
      const weeks = protocol?.weeks.map((week) => {
        // Buscar ajuste MODIFY para esta semana
        const weekStartDay = (week.weekNumber - 1) * 7 + 1;
        const weekEndDay = week.weekNumber * 7;
        const weekAdjustment = adjustments.find((adj) => {
          if (adj.adjustmentType !== 'MODIFY') return false;
          const fromDay = adj.validFromDay ?? 0;
          const untilDay = adj.validUntilDay ?? 999;
          return fromDay >= weekStartDay && untilDay <= weekEndDay;
        });

        // Aplicar ajustes se existirem
        const canDo = weekAdjustment?.canDo?.length ? weekAdjustment.canDo : week.canDo;
        const avoid = weekAdjustment?.avoid?.length ? weekAdjustment.avoid : week.avoid;

        return {
          id: week.id,
          weekNumber: week.weekNumber,
          title: week.title,
          dayRange: week.dayRange,
          objective: week.objective,
          maxHeartRate: week.maxHeartRate,
          heartRateLabel: week.heartRateLabel,
          canDo,
          avoid,
          safetyCriteria: week.safetyCriteria,
          status: 'FUTURE', // Todas as semanas são futuras se não tem data de cirurgia
          sessions: week.sessions.map((session) => ({
            id: session.id,
            sessionNumber: session.sessionNumber,
            name: session.name,
            description: session.description,
            duration: session.duration,
            intensity: session.intensity,
            completed: false,
          })),
          totalSessions: week.sessions.length,
          completedSessions: 0,
          sessionProgress: 0,
          hasAdjustment: !!weekAdjustment,
        };
      }) || [];

      return {
        patient: {
          id: patient.id,
          name: patient.user?.name || patient.name || 'Sem nome',
          email: patient.user?.email || patient.email,
          surgeryDate: null,
        },
        protocol: protocol ? {
          id: protocol.id,
          name: protocol.name,
          totalWeeks: protocol.totalWeeks,
        } : null,
        daysSinceSurgery: 0,
        currentWeek: 1,
        basalHeartRate: 65,
        progressPercent: 0,
        completedWeeks: 0,
        totalWeeks: protocol?.totalWeeks || 8,
        weeks,
        currentWeekDetails: weeks[0] || null,
        adjustments,
        noSurgeryDate: true, // Flag para o frontend saber que não tem data de cirurgia
      };
    }

    // Buscar dashboard do paciente (tem data de cirurgia)
    const dashboard = await this.getTrainingDashboard(patientId);

    // Aplicar ajustes de canDo/avoid às semanas
    const weeksWithAdjustments = dashboard.weeks.map((week: any) => {
      const weekStartDay = (week.weekNumber - 1) * 7 + 1;
      const weekEndDay = week.weekNumber * 7;
      const weekAdjustment = adjustments.find((adj) => {
        if (adj.adjustmentType !== 'MODIFY') return false;
        const fromDay = adj.validFromDay ?? 0;
        const untilDay = adj.validUntilDay ?? 999;
        return fromDay >= weekStartDay && untilDay <= weekEndDay;
      });

      // Aplicar ajustes se existirem
      const canDo = weekAdjustment?.canDo?.length ? weekAdjustment.canDo : week.canDo;
      const avoid = weekAdjustment?.avoid?.length ? weekAdjustment.avoid : week.avoid;

      return {
        ...week,
        canDo,
        avoid,
        hasAdjustment: !!weekAdjustment,
      };
    });

    return {
      patient: {
        id: patient.id,
        name: patient.user?.name || patient.name || 'Sem nome',
        email: patient.user?.email || patient.email,
        surgeryDate: patient.surgeryDate,
      },
      ...dashboard,
      weeks: weeksWithAdjustments,
      adjustments,
      noSurgeryDate: false,
    };
  }

  /**
   * Cria personalização de treino para paciente
   */
  async createPatientAdjustment(
    patientId: string,
    dto: any,
    clinicId: string,
    userId: string,
  ) {
    const patient = await this.prisma.patient.findUnique({
      where: { id: patientId },
    });

    if (!patient || patient.clinicId !== clinicId) {
      throw new NotFoundException('Paciente não encontrado');
    }

    return this.prisma.patientContentAdjustment.create({
      data: {
        patientId,
        baseContentId: dto.baseSessionId,
        adjustmentType: dto.adjustmentType,
        contentType: 'TRAINING',
        category: 'INFO',
        title: dto.name,
        description: dto.description,
        validFromDay: dto.validFromDay,
        validUntilDay: dto.validUntilDay,
        reason: dto.reason,
        canDo: dto.canDo || [],
        avoid: dto.avoid || [],
        isActive: true,
        createdBy: userId,
      },
    });
  }

  /**
   * Remove personalização de treino
   */
  async deletePatientAdjustment(adjustmentId: string, clinicId: string) {
    const adjustment = await this.prisma.patientContentAdjustment.findUnique({
      where: { id: adjustmentId },
      include: { patient: true },
    });

    if (!adjustment || adjustment.patient.clinicId !== clinicId) {
      throw new NotFoundException('Ajuste não encontrado');
    }

    await this.prisma.patientContentAdjustment.delete({
      where: { id: adjustmentId },
    });

    return { message: 'Ajuste removido com sucesso' };
  }
}
