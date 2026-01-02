import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { LogMedicationDto } from './dto';

@Injectable()
export class MedicationsService {
  constructor(private prisma: PrismaService) {}

  // Registrar que o paciente tomou uma medicação
  async logMedication(patientId: string, dto: LogMedicationDto) {
    const takenAt = dto.takenAt ? new Date(dto.takenAt) : new Date();

    return this.prisma.medicationLog.create({
      data: {
        patientId,
        contentId: dto.contentId,
        scheduledTime: dto.scheduledTime,
        takenAt,
      },
    });
  }

  // Buscar histórico de medicações do paciente
  async getMedicationLogs(
    patientId: string,
    options?: {
      startDate?: Date;
      endDate?: Date;
      contentId?: string;
      limit?: number;
    },
  ) {
    const where: any = { patientId };

    if (options?.contentId) {
      where.contentId = options.contentId;
    }

    if (options?.startDate || options?.endDate) {
      where.takenAt = {};
      if (options?.startDate) {
        where.takenAt.gte = options.startDate;
      }
      if (options?.endDate) {
        where.takenAt.lte = options.endDate;
      }
    }

    return this.prisma.medicationLog.findMany({
      where,
      orderBy: { takenAt: 'desc' },
      take: options?.limit || 100,
    });
  }

  // Buscar logs de hoje
  async getTodayLogs(patientId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    return this.prisma.medicationLog.findMany({
      where: {
        patientId,
        takenAt: {
          gte: today,
          lt: tomorrow,
        },
      },
      orderBy: { takenAt: 'desc' },
    });
  }

  // Calcular adesão (porcentagem de medicações tomadas)
  async getAdherence(
    patientId: string,
    options?: {
      days?: number; // Últimos N dias (default: 7)
    },
  ) {
    const days = options?.days || 7;
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    startDate.setHours(0, 0, 0, 0);

    // Buscar paciente para pegar clinicId
    const patient = await this.prisma.patient.findUnique({
      where: { id: patientId },
      select: { clinicId: true, surgeryDate: true },
    });

    if (!patient) {
      return { adherence: 0, taken: 0, expected: 0 };
    }

    // Buscar medicações ativas da clínica
    const medications = await this.prisma.clinicContent.findMany({
      where: {
        clinicId: patient.clinicId,
        type: 'MEDICATIONS',
        isActive: true,
      },
    });

    if (medications.length === 0) {
      return { adherence: 100, taken: 0, expected: 0 };
    }

    // Contar logs do período
    const logs = await this.prisma.medicationLog.count({
      where: {
        patientId,
        takenAt: {
          gte: startDate,
        },
      },
    });

    // Estimativa simples: cada medicação deve ser tomada 1x por dia
    // (pode ser refinado com horários específicos no futuro)
    const expected = medications.length * days;
    const adherence = expected > 0 ? Math.min(100, Math.round((logs / expected) * 100)) : 100;

    return {
      adherence,
      taken: logs,
      expected,
      days,
      medicationsCount: medications.length,
    };
  }

  // Verificar se uma medicação específica foi tomada hoje em um horário
  async wasTakenToday(patientId: string, contentId: string, scheduledTime: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const log = await this.prisma.medicationLog.findFirst({
      where: {
        patientId,
        contentId,
        scheduledTime,
        takenAt: {
          gte: today,
          lt: tomorrow,
        },
      },
    });

    return !!log;
  }

  // Desfazer registro de medicação
  async undoLog(patientId: string, logId: string) {
    // Verifica se o log pertence ao paciente
    const log = await this.prisma.medicationLog.findFirst({
      where: {
        id: logId,
        patientId,
      },
    });

    if (!log) {
      return null;
    }

    return this.prisma.medicationLog.delete({
      where: { id: logId },
    });
  }
}
