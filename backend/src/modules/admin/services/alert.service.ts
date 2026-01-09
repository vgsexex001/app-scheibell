import { Injectable, Logger, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { AlertType, AlertStatus, AppointmentStatus } from '@prisma/client';
import { CreateAlertDto } from '../dto';

@Injectable()
export class AlertService {
  private readonly logger = new Logger(AlertService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Lista alertas ativos da clínica
   */
  async getAlerts(
    clinicId: string,
    page: number = 1,
    limit: number = 10,
    status?: AlertStatus,
  ) {
    this.logger.log(`[getAlerts] clinicId=${clinicId}, status=${status}`);

    const skip = (page - 1) * limit;
    const whereClause = {
      clinicId,
      ...(status && { status }),
    };

    const [alerts, total] = await Promise.all([
      this.prisma.alert.findMany({
        where: whereClause,
        include: {
          patient: {
            include: {
              user: { select: { name: true } },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.alert.count({ where: whereClause }),
    ]);

    const items = alerts.map((alert) => ({
      id: alert.id,
      type: alert.type,
      title: alert.title,
      description: alert.description,
      status: alert.status,
      isAutomatic: alert.isAutomatic,
      patientId: alert.patientId,
      patientName: alert.patient?.user?.name || alert.patient?.name || null,
      createdAt: alert.createdAt.toISOString(),
      resolvedAt: alert.resolvedAt?.toISOString() || null,
    }));

    return { items, page, limit, total };
  }

  /**
   * Cria um alerta manual
   */
  async createAlert(clinicId: string, userId: string, dto: CreateAlertDto) {
    this.logger.log(`[createAlert] clinicId=${clinicId}, type=${dto.type}`);

    // Se patientId foi fornecido, verificar se pertence à clínica
    if (dto.patientId) {
      const patient = await this.prisma.patient.findUnique({
        where: { id: dto.patientId },
      });

      if (!patient || patient.clinicId !== clinicId) {
        throw new ForbiddenException('Paciente não encontrado ou não pertence à clínica');
      }
    }

    const alert = await this.prisma.alert.create({
      data: {
        clinicId,
        patientId: dto.patientId,
        type: dto.type,
        title: dto.title,
        description: dto.description,
        isAutomatic: false,
      },
      include: {
        patient: {
          include: {
            user: { select: { name: true } },
          },
        },
      },
    });

    return {
      id: alert.id,
      type: alert.type,
      title: alert.title,
      description: alert.description,
      status: alert.status,
      patientName: alert.patient?.user?.name || alert.patient?.name || null,
      createdAt: alert.createdAt.toISOString(),
    };
  }

  /**
   * Resolve um alerta
   */
  async resolveAlert(alertId: string, clinicId: string, userId: string) {
    this.logger.log(`[resolveAlert] alertId=${alertId}, userId=${userId}`);

    const alert = await this.prisma.alert.findUnique({
      where: { id: alertId },
    });

    if (!alert) {
      throw new NotFoundException('Alerta não encontrado');
    }

    if (alert.clinicId !== clinicId) {
      throw new ForbiddenException('Acesso negado a este alerta');
    }

    const updated = await this.prisma.alert.update({
      where: { id: alertId },
      data: {
        status: AlertStatus.RESOLVED,
        resolvedAt: new Date(),
        resolvedBy: userId,
      },
    });

    return { success: true, alert: updated };
  }

  /**
   * Dispensa um alerta (ignora sem resolver)
   */
  async dismissAlert(alertId: string, clinicId: string, userId: string) {
    this.logger.log(`[dismissAlert] alertId=${alertId}, userId=${userId}`);

    const alert = await this.prisma.alert.findUnique({
      where: { id: alertId },
    });

    if (!alert) {
      throw new NotFoundException('Alerta não encontrado');
    }

    if (alert.clinicId !== clinicId) {
      throw new ForbiddenException('Acesso negado a este alerta');
    }

    const updated = await this.prisma.alert.update({
      where: { id: alertId },
      data: {
        status: AlertStatus.DISMISSED,
        resolvedAt: new Date(),
        resolvedBy: userId,
      },
    });

    return { success: true, alert: updated };
  }

  /**
   * Verifica e gera alertas automáticos para a clínica
   * Deve ser chamado periodicamente (cron job) ou sob demanda
   */
  async checkAndGenerateAlerts(clinicId: string) {
    this.logger.log(`[checkAndGenerateAlerts] clinicId=${clinicId}`);

    const alertsCreated: string[] = [];

    // 1. Verificar baixa adesão (últimos 3 dias)
    const lowAdherenceAlerts = await this.checkLowAdherence(clinicId);
    alertsCreated.push(...lowAdherenceAlerts);

    // 2. Verificar consultas perdidas
    const missedAppointmentAlerts = await this.checkMissedAppointments(clinicId);
    alertsCreated.push(...missedAppointmentAlerts);

    this.logger.log(`[checkAndGenerateAlerts] ${alertsCreated.length} alertas criados`);

    return {
      alertsCreated: alertsCreated.length,
      alerts: alertsCreated,
    };
  }

  /**
   * Verifica pacientes com baixa adesão a medicamentos
   */
  private async checkLowAdherence(clinicId: string): Promise<string[]> {
    const threeDaysAgo = new Date();
    threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);

    // Buscar pacientes da clínica com cirurgia
    const patients = await this.prisma.patient.findMany({
      where: {
        clinicId,
        surgeryDate: { not: null },
      },
      include: {
        user: { select: { name: true } },
      },
    });

    const alertsCreated: string[] = [];

    for (const patient of patients) {
      // Contar logs de medicação nos últimos 3 dias
      const medicationLogs = await this.prisma.medicationLog.count({
        where: {
          patientId: patient.id,
          takenAt: { gte: threeDaysAgo },
        },
      });

      // Esperado: 3 doses/dia * 3 dias = 9
      const expected = 9;
      const adherenceRate = expected > 0 ? (medicationLogs / expected) * 100 : 0;

      // Se adesão < 50%, verificar se já existe alerta ativo
      if (adherenceRate < 50) {
        const existingAlert = await this.prisma.alert.findFirst({
          where: {
            clinicId,
            patientId: patient.id,
            type: AlertType.LOW_ADHERENCE,
            status: AlertStatus.ACTIVE,
          },
        });

        if (!existingAlert) {
          const alert = await this.prisma.alert.create({
            data: {
              clinicId,
              patientId: patient.id,
              type: AlertType.LOW_ADHERENCE,
              title: 'Baixa Adesão a Medicamentos',
              description: `${patient.user?.name || patient.name || 'Paciente'} apresenta adesão de ${Math.round(adherenceRate)}% nos últimos 3 dias.`,
              isAutomatic: true,
            },
          });
          alertsCreated.push(alert.id);
        }
      }
    }

    return alertsCreated;
  }

  /**
   * Verifica consultas confirmadas que passaram sem ser concluídas
   */
  private async checkMissedAppointments(clinicId: string): Promise<string[]> {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(23, 59, 59, 999);

    // Buscar consultas CONFIRMED que passaram da data
    const missedAppointments = await this.prisma.appointment.findMany({
      where: {
        patient: { clinicId },
        status: AppointmentStatus.CONFIRMED,
        date: { lt: yesterday },
      },
      include: {
        patient: {
          include: {
            user: { select: { name: true } },
          },
        },
      },
    });

    const alertsCreated: string[] = [];

    for (const appointment of missedAppointments) {
      // Verificar se já existe alerta ativo para esta consulta
      const existingAlert = await this.prisma.alert.findFirst({
        where: {
          clinicId,
          patientId: appointment.patientId,
          type: AlertType.MISSED_APPOINTMENT,
          status: AlertStatus.ACTIVE,
          description: { contains: appointment.id },
        },
      });

      if (!existingAlert) {
        const alert = await this.prisma.alert.create({
          data: {
            clinicId,
            patientId: appointment.patientId,
            type: AlertType.MISSED_APPOINTMENT,
            title: 'Consulta Perdida',
            description: `${appointment.patient.user?.name || appointment.patient.name || 'Paciente'} não compareceu à consulta "${appointment.title}" de ${new Date(appointment.date).toLocaleDateString('pt-BR')}. (ID: ${appointment.id})`,
            isAutomatic: true,
          },
        });
        alertsCreated.push(alert.id);
      }
    }

    return alertsCreated;
  }
}
