import { Injectable, NotFoundException, ForbiddenException, BadRequestException, Logger } from '@nestjs/common';
import { Response } from 'express';
import { PrismaService } from '../../prisma/prisma.service';
import { AppointmentStatus, AlertStatus, NotificationType, NotificationStatus } from '@prisma/client';
import {
  DashboardSummaryDto,
  PendingAppointmentDto,
  PendingAppointmentsResponseDto,
  RecoveryPatientDto,
  RecoveryPatientsResponseDto,
  CalendarAppointmentDto,
  CalendarResponseDto,
  TodayAppointmentDto,
  TodayAppointmentsResponseDto,
  RecentPatientDto,
  RecentPatientsResponseDto,
  CreateAppointmentDto,
} from './dto';
import { AppointmentType } from '@prisma/client';

// Mapa de tradução para tipos de agendamento
const APPOINTMENT_TYPE_LABELS: Record<string, string> = {
  CONSULTATION: 'Consulta',
  RETURN_VISIT: 'Retorno',
  EVALUATION: 'Avaliação',
  SPLINT_REMOVAL: 'Retirada de Splint',
  PHYSIOTHERAPY: 'Fisioterapia',
  EXAM: 'Exame',
  SURGERY: 'Cirurgia',
  OTHER: 'Outro',
};

function getAppointmentTypeLabel(type: string | null): string {
  if (!type) return 'Consulta';
  return APPOINTMENT_TYPE_LABELS[type] || type;
}

@Injectable()
export class AdminService {
  private readonly logger = new Logger(AdminService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Retorna o resumo do dashboard (indicadores)
   */
  async getDashboardSummary(clinicId: string): Promise<DashboardSummaryDto> {
    this.logger.log(`[getDashboardSummary] clinicId=${clinicId}`);

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // 1. Consultas hoje (CONFIRMED ou COMPLETED)
    let consultationsToday = 0;
    try {
      consultationsToday = await this.prisma.appointment.count({
        where: {
          patient: { clinicId },
          date: {
            gte: today,
            lt: tomorrow,
          },
          status: {
            in: [AppointmentStatus.CONFIRMED, AppointmentStatus.COMPLETED],
          },
        },
      });
      this.logger.log(`[getDashboardSummary] consultationsToday=${consultationsToday}`);
    } catch (e) {
      this.logger.error(`[getDashboardSummary] Erro ao contar consultas hoje: ${e.message}`, e.stack);
    }

    // 2. Consultas pendentes de aprovação
    let pendingApprovals = 0;
    try {
      pendingApprovals = await this.prisma.appointment.count({
        where: {
          patient: { clinicId },
          status: AppointmentStatus.PENDING,
        },
      });
      this.logger.log(`[getDashboardSummary] pendingApprovals=${pendingApprovals}`);
    } catch (e) {
      this.logger.error(`[getDashboardSummary] Erro ao contar pendentes: ${e.message}`, e.stack);
    }

    // 3. Alertas ativos
    let activeAlerts = 0;
    try {
      activeAlerts = await this.prisma.alert.count({
        where: {
          clinicId,
          status: AlertStatus.ACTIVE,
        },
      });
      this.logger.log(`[getDashboardSummary] activeAlerts=${activeAlerts}`);
    } catch (e) {
      this.logger.error(`[getDashboardSummary] Erro ao contar alertas: ${e.message}`, e.stack);
    }

    // 4. Taxa de adesão combinada (50% medicações + 50% treinos)
    let adherenceRate = 0;
    try {
      adherenceRate = await this.calculateCombinedAdherence(clinicId);
      this.logger.log(`[getDashboardSummary] adherenceRate=${adherenceRate}`);
    } catch (e) {
      this.logger.error(`[getDashboardSummary] Erro ao calcular adesão: ${e.message}`, e.stack);
    }

    return {
      consultationsToday,
      pendingApprovals,
      activeAlerts,
      adherenceRate: Math.round(adherenceRate),
    };
  }

  /**
   * Calcula a taxa de adesão combinada (medicações + treinos)
   */
  private async calculateCombinedAdherence(clinicId: string): Promise<number> {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    // Buscar pacientes da clínica com cirurgia
    const patients = await this.prisma.patient.findMany({
      where: {
        clinicId,
        surgeryDate: { not: null },
      },
      select: { id: true },
    });

    if (patients.length === 0) return 0;

    const patientIds = patients.map((p) => p.id);

    // Taxa de medicações: logs registrados / esperados
    let medicationRate = 0;
    try {
      const medicationLogs = await this.prisma.medicationLog.count({
        where: {
          patientId: { in: patientIds },
          takenAt: { gte: sevenDaysAgo },
        },
      });
      const expectedMedicationLogs = patients.length * 7 * 3;
      medicationRate = expectedMedicationLogs > 0
        ? Math.min(100, (medicationLogs / expectedMedicationLogs) * 100)
        : 0;
    } catch (e) {
      this.logger.error(`[calculateCombinedAdherence] Erro ao contar medicationLogs: ${e.message}`);
    }

    // Taxa de treinos: sessões completadas / total de sessões disponíveis
    let trainingRate = 0;
    try {
      const sessionsCompleted = await this.prisma.patientSessionCompletion.count({
        where: {
          patientId: { in: patientIds },
          completedAt: { gte: sevenDaysAgo },
        },
      });

      const totalSessions = await this.prisma.trainingSession.count({
        where: {
          week: {
            progress: {
              some: {
                patientId: { in: patientIds },
                status: { in: ['COMPLETED', 'CURRENT'] },
              },
            },
          },
        },
      });

      trainingRate = totalSessions > 0
        ? Math.min(100, (sessionsCompleted / totalSessions) * 100)
        : 0;
    } catch (e) {
      this.logger.error(`[calculateCombinedAdherence] Erro ao contar treinos: ${e.message}`);
    }

    // Combinado: 50% medicações + 50% treinos
    return (medicationRate * 0.5) + (trainingRate * 0.5);
  }

  /**
   * Lista consultas pendentes de aprovação
   */
  async getPendingAppointments(
    clinicId: string,
    page: number = 1,
    limit: number = 10,
  ): Promise<PendingAppointmentsResponseDto> {
    this.logger.log(`[getPendingAppointments] clinicId=${clinicId}, page=${page}, limit=${limit}`);

    const skip = (page - 1) * limit;

    const [appointments, total] = await Promise.all([
      this.prisma.appointment.findMany({
        where: {
          patient: { clinicId },
          status: AppointmentStatus.PENDING,
        },
        include: {
          patient: {
            include: {
              user: { select: { name: true } },
            },
          },
        },
        orderBy: { date: 'asc' },
        skip,
        take: limit,
      }),
      this.prisma.appointment.count({
        where: {
          patient: { clinicId },
          status: AppointmentStatus.PENDING,
        },
      }),
    ]);

    const items: PendingAppointmentDto[] = appointments.map((apt) => {
      const date = new Date(apt.date);
      return {
        id: apt.id,
        patientId: apt.patientId,
        patientName: apt.patient.user?.name || apt.patient.name || 'Paciente',
        procedureType: getAppointmentTypeLabel(apt.type),
        startsAt: `${date.toISOString().split('T')[0]}T${apt.time}:00-03:00`,
        displayDate: date.toLocaleDateString('pt-BR'),
        displayTime: apt.time,
      };
    });

    return { items, page, limit, total };
  }

  /**
   * Aprova uma consulta
   */
  async approveAppointment(
    appointmentId: string,
    clinicId: string,
    userId: string,
    notes?: string,
  ) {
    this.logger.log(`[approveAppointment] appointmentId=${appointmentId}, userId=${userId}`);

    const appointment = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
      include: {
        patient: {
          include: { user: true },
        },
      },
    });

    if (!appointment) {
      throw new NotFoundException('Consulta não encontrada');
    }

    if (appointment.patient.clinicId !== clinicId) {
      throw new ForbiddenException('Acesso negado a esta consulta');
    }

    const updated = await this.prisma.appointment.update({
      where: { id: appointmentId },
      data: {
        status: AppointmentStatus.CONFIRMED,
        notes: notes ? `${appointment.notes || ''}\n[Aprovado] ${notes}`.trim() : appointment.notes,
      },
    });

    // Criar notificação para o paciente (apenas se tiver userId vinculado)
    if (appointment.patient.userId) {
      await this.prisma.notification.create({
        data: {
          userId: appointment.patient.userId,
          type: NotificationType.APPOINTMENT_APPROVED,
          title: 'Consulta Aprovada',
          body: `Sua consulta de ${appointment.title} foi aprovada para ${new Date(appointment.date).toLocaleDateString('pt-BR')} às ${appointment.time}.`,
          data: { appointmentId: appointment.id },
          status: NotificationStatus.PENDING,
        },
      });
    }

    return { success: true, appointment: updated };
  }

  /**
   * Rejeita uma consulta
   */
  async rejectAppointment(
    appointmentId: string,
    clinicId: string,
    userId: string,
    reason?: string,
  ) {
    this.logger.log(`[rejectAppointment] appointmentId=${appointmentId}, userId=${userId}`);

    const appointment = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
      include: {
        patient: {
          include: { user: true },
        },
      },
    });

    if (!appointment) {
      throw new NotFoundException('Consulta não encontrada');
    }

    if (appointment.patient.clinicId !== clinicId) {
      throw new ForbiddenException('Acesso negado a esta consulta');
    }

    const updated = await this.prisma.appointment.update({
      where: { id: appointmentId },
      data: {
        status: AppointmentStatus.CANCELLED,
        notes: reason ? `${appointment.notes || ''}\n[Recusado] ${reason}`.trim() : appointment.notes,
      },
    });

    // Criar notificação para o paciente (apenas se tiver userId vinculado)
    if (appointment.patient.userId) {
      await this.prisma.notification.create({
        data: {
          userId: appointment.patient.userId,
          type: NotificationType.APPOINTMENT_REJECTED,
          title: 'Consulta Recusada',
          body: reason
            ? `Sua consulta de ${appointment.title} foi recusada. Motivo: ${reason}`
            : `Sua consulta de ${appointment.title} foi recusada. Entre em contato com a clínica.`,
          data: { appointmentId: appointment.id, reason },
          status: NotificationStatus.PENDING,
        },
      });
    }

    return { success: true, appointment: updated };
  }

  /**
   * Atualiza um agendamento (status, notas, tipo)
   */
  async updateAppointment(
    appointmentId: string,
    clinicId: string,
    dto: { status?: string; notes?: string; type?: string },
  ) {
    this.logger.log(`[updateAppointment] appointmentId=${appointmentId}`);

    const appointment = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
      include: { patient: true },
    });

    if (!appointment) {
      throw new NotFoundException('Consulta não encontrada');
    }

    if (appointment.patient.clinicId !== clinicId) {
      throw new ForbiddenException('Acesso negado a esta consulta');
    }

    const updateData: Record<string, unknown> = {};
    if (dto.status) {
      updateData.status = dto.status as AppointmentStatus;
    }
    if (dto.notes !== undefined) {
      updateData.notes = dto.notes;
    }
    if (dto.type) {
      updateData.type = dto.type;
    }

    const updated = await this.prisma.appointment.update({
      where: { id: appointmentId },
      data: updateData,
    });

    return { success: true, appointment: updated };
  }

  /**
   * Cancela um agendamento
   */
  async cancelAppointment(
    appointmentId: string,
    clinicId: string,
    userId: string,
    reason?: string,
  ) {
    this.logger.log(`[cancelAppointment] appointmentId=${appointmentId}, userId=${userId}`);

    const appointment = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
      include: {
        patient: {
          include: { user: true },
        },
      },
    });

    if (!appointment) {
      throw new NotFoundException('Consulta não encontrada');
    }

    if (appointment.patient.clinicId !== clinicId) {
      throw new ForbiddenException('Acesso negado a esta consulta');
    }

    const updated = await this.prisma.appointment.update({
      where: { id: appointmentId },
      data: {
        status: AppointmentStatus.CANCELLED,
        notes: reason ? `${appointment.notes || ''}\n[Cancelado] ${reason}`.trim() : appointment.notes,
      },
    });

    // Criar notificação para o paciente (apenas se tiver userId vinculado)
    if (appointment.patient.userId) {
      await this.prisma.notification.create({
        data: {
          userId: appointment.patient.userId,
          type: NotificationType.APPOINTMENT_REJECTED,
          title: 'Consulta Cancelada',
          body: reason
            ? `Sua consulta de ${appointment.title} foi cancelada. Motivo: ${reason}`
            : `Sua consulta de ${appointment.title} foi cancelada. Entre em contato com a clínica.`,
          data: { appointmentId: appointment.id, reason },
          status: NotificationStatus.PENDING,
        },
      });
    }

    return { success: true, appointment: updated };
  }

  /**
   * Lista pacientes em recuperação
   */
  async getRecoveryPatients(
    clinicId: string,
    page: number = 1,
    limit: number = 10,
  ): Promise<RecoveryPatientsResponseDto> {
    this.logger.log(`[getRecoveryPatients] clinicId=${clinicId}, page=${page}, limit=${limit}`);

    const skip = (page - 1) * limit;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [patients, total] = await Promise.all([
      this.prisma.patient.findMany({
        where: {
          clinicId,
          surgeryDate: { not: null },
        },
        include: {
          user: { select: { name: true } },
          appointments: {
            where: {
              status: AppointmentStatus.CONFIRMED,
              date: { gte: today },
            },
            orderBy: { date: 'asc' },
            take: 1,
          },
          sessionCompletions: {
            select: { id: true },
          },
          trainingProgress: {
            where: { status: { in: ['COMPLETED', 'CURRENT'] } },
            include: {
              week: {
                include: {
                  sessions: { select: { id: true } },
                },
              },
            },
          },
        },
        orderBy: { surgeryDate: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.patient.count({
        where: {
          clinicId,
          surgeryDate: { not: null },
        },
      }),
    ]);

    const items: RecoveryPatientDto[] = patients.map((patient) => {
      // Calcular dias pós-operatório
      const surgeryDate = new Date(patient.surgeryDate!);
      surgeryDate.setHours(0, 0, 0, 0);
      const dayPostOp = Math.floor(
        (today.getTime() - surgeryDate.getTime()) / (1000 * 60 * 60 * 24),
      );

      // Calcular progresso baseado em sessões completadas
      let totalSessions = 0;
      patient.trainingProgress.forEach((progress) => {
        totalSessions += progress.week.sessions.length;
      });
      const completedSessions = patient.sessionCompletions.length;
      const progressPercent = totalSessions > 0
        ? Math.round((completedSessions / totalSessions) * 100)
        : 0;

      // Próxima consulta
      const nextAppointment = patient.appointments[0];
      let nextAppointmentAt: string | null = null;
      let nextAppointmentLabel = 'Sem consultas agendadas';

      if (nextAppointment) {
        const nextDate = new Date(nextAppointment.date);
        nextAppointmentAt = nextDate.toISOString();
        nextAppointmentLabel = `Próxima: ${nextDate.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' })}`;
      }

      return {
        patientId: patient.id,
        patientName: patient.user?.name || patient.name || 'Paciente',
        procedureType: patient.surgeryType || 'Não informado',
        dayPostOp: Math.max(0, dayPostOp),
        progressPercent,
        nextAppointmentAt,
        nextAppointmentLabel,
      };
    });

    return { items, page, limit, total };
  }

  /**
   * Retorna agendamentos do mês para o calendário
   * GET /api/admin/calendar
   */
  async getCalendarAppointments(
    clinicId: string,
    month: number,
    year: number,
  ): Promise<CalendarResponseDto> {
    this.logger.log(`[getCalendarAppointments] clinicId=${clinicId}, month=${month}, year=${year}`);

    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59);

    const appointments = await this.prisma.appointment.findMany({
      where: {
        patient: { clinicId },
        date: {
          gte: startDate,
          lte: endDate,
        },
        status: {
          not: AppointmentStatus.CANCELLED,
        },
      },
      include: {
        patient: {
          include: {
            user: { select: { name: true } },
          },
        },
      },
      orderBy: [{ date: 'asc' }, { time: 'asc' }],
    });

    const items: CalendarAppointmentDto[] = appointments.map((apt) => ({
      id: apt.id,
      patientId: apt.patientId,
      patientName: apt.patient.user?.name || apt.patient.name || 'Paciente',
      procedureType: getAppointmentTypeLabel(apt.type),
      consultationType: apt.type || 'CONSULTATION',
      date: new Date(apt.date).toISOString().split('T')[0],
      time: apt.time,
      status: apt.status,
      notes: apt.notes || '',
    }));

    return {
      items,
      month,
      year,
      total: items.length,
    };
  }

  /**
   * Retorna agendamentos de hoje
   * GET /api/admin/appointments/today
   */
  async getTodayAppointments(clinicId: string): Promise<TodayAppointmentsResponseDto> {
    this.logger.log(`[getTodayAppointments] clinicId=${clinicId}`);

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const appointments = await this.prisma.appointment.findMany({
      where: {
        patient: { clinicId },
        date: {
          gte: today,
          lt: tomorrow,
        },
        status: {
          in: [AppointmentStatus.CONFIRMED, AppointmentStatus.PENDING],
        },
      },
      include: {
        patient: {
          include: {
            user: { select: { name: true } },
          },
        },
      },
      orderBy: { time: 'asc' },
    });

    const items: TodayAppointmentDto[] = appointments.map((apt) => ({
      id: apt.id,
      patientId: apt.patientId,
      patientName: apt.patient.user?.name || apt.patient.name || 'Paciente',
      procedureType: getAppointmentTypeLabel(apt.type),
      time: apt.time,
      status: apt.status,
    }));

    return {
      items,
      total: items.length,
    };
  }

  /**
   * Retorna pacientes recentes (últimos atualizados)
   * GET /api/admin/patients/recent
   */
  async getRecentPatients(clinicId: string, limit: number = 5): Promise<RecentPatientsResponseDto> {
    this.logger.log(`[getRecentPatients] clinicId=${clinicId}, limit=${limit}`);

    const patients = await this.prisma.patient.findMany({
      where: { clinicId },
      include: {
        user: { select: { name: true } },
      },
      orderBy: { updatedAt: 'desc' },
      take: limit,
    });

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const items: RecentPatientDto[] = patients.map((patient) => {
      const lastActivityDate = new Date(patient.updatedAt);
      lastActivityDate.setHours(0, 0, 0, 0);
      const daysAgo = Math.floor(
        (today.getTime() - lastActivityDate.getTime()) / (1000 * 60 * 60 * 24),
      );

      return {
        id: patient.id,
        name: patient.user?.name || patient.name || 'Paciente',
        procedureType: patient.surgeryType || 'Não informado',
        daysAgo: Math.max(0, daysAgo),
        lastActivity: patient.updatedAt.toISOString(),
      };
    });

    return {
      items,
      total: items.length,
    };
  }

  /**
   * Cria um novo agendamento
   * POST /api/admin/appointments
   */
  async createAppointment(
    clinicId: string,
    userId: string,
    dto: CreateAppointmentDto,
  ) {
    this.logger.log(`[createAppointment] clinicId=${clinicId}, patientId=${dto.patientId}`);

    // 1. Validar que paciente pertence à clínica
    const patient = await this.prisma.patient.findFirst({
      where: { id: dto.patientId, clinicId },
      include: { user: true },
    });

    if (!patient) {
      throw new NotFoundException('Paciente não encontrado nesta clínica');
    }

    // 2. Criar o agendamento
    const appointment = await this.prisma.appointment.create({
      data: {
        patientId: dto.patientId,
        clinicId: clinicId,
        title: dto.title,
        description: dto.description,
        date: new Date(dto.date),
        time: dto.time,
        type: dto.type as AppointmentType,
        status: dto.status ?? AppointmentStatus.CONFIRMED,
        location: dto.location,
        notes: dto.notes,
      },
    });

    this.logger.log(`[createAppointment] Created appointment id=${appointment.id}`);

    // 3. Criar notificação para o paciente (se tiver userId vinculado)
    if (patient.userId) {
      await this.prisma.notification.create({
        data: {
          userId: patient.userId,
          type: NotificationType.APPOINTMENT_APPROVED,
          title: 'Novo Agendamento',
          body: `Você tem uma consulta agendada: ${dto.title} em ${dto.date} às ${dto.time}`,
          data: { appointmentId: appointment.id },
          status: NotificationStatus.PENDING,
        },
      });
    }

    return { success: true, appointment };
  }

  /**
   * Exporta agendamentos em formato CSV
   * GET /api/admin/appointments/export
   */
  async exportAppointmentsCsv(
    clinicId: string,
    from: string,
    to: string,
    status: string | undefined,
    res: Response,
  ) {
    this.logger.log(`[exportAppointmentsCsv] clinicId=${clinicId}, from=${from}, to=${to}, status=${status}`);

    // 1. Validar parâmetros obrigatórios
    if (!from || !to) {
      throw new BadRequestException('Parâmetros from e to são obrigatórios');
    }

    // 2. Validar range máximo (90 dias)
    const fromDate = new Date(from);
    const toDate = new Date(to);
    const diffDays = (toDate.getTime() - fromDate.getTime()) / (1000 * 60 * 60 * 24);

    if (diffDays > 90) {
      throw new BadRequestException('Range máximo permitido: 90 dias');
    }

    if (diffDays < 0) {
      throw new BadRequestException('Data inicial deve ser anterior à data final');
    }

    // 3. Buscar agendamentos
    const whereClause: {
      patient: { clinicId: string };
      date: { gte: Date; lte: Date };
      deletedAt: null;
      status?: AppointmentStatus;
    } = {
      patient: { clinicId },
      date: {
        gte: fromDate,
        lte: toDate,
      },
      deletedAt: null,
    };

    if (status && status !== 'ALL') {
      whereClause.status = status as AppointmentStatus;
    }

    const appointments = await this.prisma.appointment.findMany({
      where: whereClause,
      include: {
        patient: {
          include: { user: { select: { name: true } } },
        },
      },
      orderBy: [{ date: 'asc' }, { time: 'asc' }],
    });

    this.logger.log(`[exportAppointmentsCsv] Found ${appointments.length} appointments`);

    // 4. Gerar CSV
    const headers = 'id,date,time,patientName,patientId,title,type,status,location,notes\n';
    const rows = appointments
      .map((apt) => {
        const patientName = apt.patient.user?.name || apt.patient.name || 'Paciente';
        const escapedNotes = (apt.notes || '').replace(/"/g, '""').replace(/\n/g, ' ');
        const escapedTitle = (apt.title || '').replace(/"/g, '""');
        const escapedLocation = (apt.location || '').replace(/"/g, '""');

        return `"${apt.id}","${apt.date.toISOString().split('T')[0]}","${apt.time}","${patientName}","${apt.patientId}","${escapedTitle}","${apt.type}","${apt.status}","${escapedLocation}","${escapedNotes}"`;
      })
      .join('\n');

    // 5. Configurar headers e enviar resposta
    const fileName = `appointments_${from}_to_${to}.csv`;
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);

    // BOM para Excel reconhecer UTF-8
    res.send('\uFEFF' + headers + rows);
  }
}
