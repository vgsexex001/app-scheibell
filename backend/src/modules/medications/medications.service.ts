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

    // Buscar paciente para pegar clinicId e data da cirurgia
    const patient = await this.prisma.patient.findUnique({
      where: { id: patientId },
      select: { clinicId: true, surgeryDate: true },
    });

    if (!patient) {
      return { adherence: 0, taken: 0, expected: 0, days, medicationsCount: 0 };
    }

    // Calcular dia pós-operatório atual
    const today = new Date();
    const dayPostOp = patient.surgeryDate
      ? Math.floor((today.getTime() - new Date(patient.surgeryDate).getTime()) / (1000 * 60 * 60 * 24))
      : 0;

    // 1. Buscar medicações adicionadas especificamente para o paciente (PatientContentAdjustment ADD)
    const patientAddedMeds = await this.prisma.patientContentAdjustment.findMany({
      where: {
        patientId,
        contentType: 'MEDICATIONS',
        adjustmentType: 'ADD',
        isActive: true,
      },
    });

    // 2. Buscar medicações desabilitadas para o paciente (PatientContentAdjustment DISABLE)
    const disabledMedIds = await this.prisma.patientContentAdjustment.findMany({
      where: {
        patientId,
        adjustmentType: 'DISABLE',
        isActive: true,
        baseContentId: { not: null },
      },
      select: { baseContentId: true },
    });
    const disabledIds = disabledMedIds.map(d => d.baseContentId).filter(Boolean) as string[];

    // 3. Buscar medicações da clínica ativas e válidas para o D+ atual
    const clinicMedications = await this.prisma.clinicContent.findMany({
      where: {
        clinicId: patient.clinicId,
        type: 'MEDICATIONS',
        isActive: true,
        id: { notIn: disabledIds },
        OR: [
          // Medicação válida para o período pós-op atual
          {
            AND: [
              { validFromDay: { lte: dayPostOp } },
              { validUntilDay: { gte: dayPostOp } },
            ],
          },
          // Medicação sem período definido (sempre válida)
          {
            validFromDay: null,
            validUntilDay: null,
          },
          // Apenas validFromDay definido
          {
            validFromDay: { lte: dayPostOp },
            validUntilDay: null,
          },
        ],
      },
    });

    // Total de medicações ativas para o paciente
    const totalMedications = patientAddedMeds.length + clinicMedications.length;

    if (totalMedications === 0) {
      return { adherence: 100, taken: 0, expected: 0, days, medicationsCount: 0 };
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

    // Cálculo: assumir 1 dose por dia por medicação (conservador)
    // Para medicações com múltiplas doses, o schema precisaria de campo 'frequency'
    const expected = totalMedications * days;
    const adherence = expected > 0 ? Math.min(100, Math.round((logs / expected) * 100)) : 100;

    return {
      adherence,
      taken: logs,
      expected,
      days,
      medicationsCount: totalMedications,
      details: {
        fromClinic: clinicMedications.length,
        addedForPatient: patientAddedMeds.length,
        disabled: disabledIds.length,
      },
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
