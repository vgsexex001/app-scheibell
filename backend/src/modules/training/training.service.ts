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

    // Calcular dias desde a cirurgia
    const now = new Date();
    const surgeryDate = new Date(patient.surgeryDate);
    const daysSinceSurgery = Math.floor(
      (now.getTime() - surgeryDate.getTime()) / (1000 * 60 * 60 * 24),
    );

    // Semana atual (sempre começa em 1)
    const currentWeekNumber = Math.max(1, Math.floor(daysSinceSurgery / 7) + 1);

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
   */
  async getTrainingProtocol(patientId: string) {
    const dashboard = await this.getTrainingDashboard(patientId);

    return {
      currentWeek: dashboard.currentWeek,
      daysSinceSurgery: dashboard.daysSinceSurgery,
      basalHeartRate: dashboard.basalHeartRate,
      weeks: dashboard.weeks.map((week) => ({
        weekNumber: week.weekNumber,
        title: week.title,
        dayRange: week.dayRange,
        status: week.status,
        objective: week.objective,
        maxHeartRate: week.maxHeartRate,
        heartRateLabel: week.heartRateLabel,
        canDo: week.canDo,
        avoid: week.avoid,
      })),
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
}
