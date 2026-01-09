import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateAppointmentDto, UpdateStatusDto } from './dto';
import { AppointmentStatus, NotificationType, NotificationStatus } from '@prisma/client';

@Injectable()
export class AppointmentsService {
  constructor(private prisma: PrismaService) {}

  /**
   * Lista todas as consultas do paciente
   */
  async getPatientAppointments(patientId: string, status?: AppointmentStatus) {
    const where: any = { patientId };
    if (status) {
      where.status = status;
    }

    return this.prisma.appointment.findMany({
      where,
      orderBy: { date: 'asc' },
    });
  }

  /**
   * Lista próximas consultas (não canceladas, futuras)
   */
  async getUpcomingAppointments(patientId: string, limit = 5) {
    return this.prisma.appointment.findMany({
      where: {
        patientId,
        status: { not: AppointmentStatus.CANCELLED },
        date: { gte: new Date() },
      },
      orderBy: { date: 'asc' },
      take: limit,
    });
  }

  /**
   * Busca uma consulta específica
   */
  async getAppointmentById(id: string, patientId: string) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { id },
    });

    if (!appointment) {
      throw new NotFoundException('Consulta não encontrada');
    }

    if (appointment.patientId !== patientId) {
      throw new ForbiddenException('Acesso negado a esta consulta');
    }

    return appointment;
  }

  /**
   * Cria uma nova consulta e notifica admins da clínica
   */
  async createAppointment(patientId: string, dto: CreateAppointmentDto) {
    // Busca dados do paciente e clínica
    const patient = await this.prisma.patient.findUnique({
      where: { id: patientId },
      include: {
        user: { select: { name: true } },
        clinic: { select: { id: true } },
      },
    });

    if (!patient) {
      throw new NotFoundException('Paciente não encontrado');
    }

    // Cria o agendamento
    const appointment = await this.prisma.appointment.create({
      data: {
        patientId,
        title: dto.title,
        description: dto.description,
        date: new Date(dto.date),
        time: dto.time,
        type: dto.type,
        location: dto.location,
        notes: dto.notes,
        status: AppointmentStatus.PENDING,
      },
    });

    // Busca admins e staff da clínica para notificar
    const admins = await this.prisma.user.findMany({
      where: {
        clinicId: patient.clinicId,
        role: { in: ['CLINIC_ADMIN', 'CLINIC_STAFF'] },
      },
    });

    // Cria notificação para cada admin/staff
    const patientName = patient.user?.name || patient.name || 'Paciente';
    for (const admin of admins) {
      await this.prisma.notification.create({
        data: {
          userId: admin.id,
          type: NotificationType.NEW_APPOINTMENT,
          title: 'Novo Agendamento Pendente',
          body: `${patientName} solicitou agendamento: ${dto.title}`,
          data: { appointmentId: appointment.id, patientId },
          status: NotificationStatus.PENDING,
        },
      });
    }

    return appointment;
  }

  /**
   * Atualiza o status de uma consulta
   */
  async updateStatus(id: string, patientId: string, dto: UpdateStatusDto) {
    // Verifica se a consulta existe e pertence ao paciente
    await this.getAppointmentById(id, patientId);

    return this.prisma.appointment.update({
      where: { id },
      data: { status: dto.status },
    });
  }

  /**
   * Cancela uma consulta
   */
  async cancelAppointment(id: string, patientId: string) {
    return this.updateStatus(id, patientId, { status: AppointmentStatus.CANCELLED });
  }

  /**
   * Confirma uma consulta
   */
  async confirmAppointment(id: string, patientId: string) {
    return this.updateStatus(id, patientId, { status: AppointmentStatus.CONFIRMED });
  }

  /**
   * Lista agendamentos da equipe (CONFIRMED futuros)
   * Para uso do CLINIC_STAFF e CLINIC_ADMIN
   */
  async getTeamAppointments(clinicId: string, startDate?: string, endDate?: string) {
    const where: any = {
      patient: { clinicId },
      status: AppointmentStatus.CONFIRMED,
      date: { gte: new Date() },
    };

    if (startDate) {
      where.date = { ...where.date, gte: new Date(startDate) };
    }
    if (endDate) {
      where.date = { ...where.date, lte: new Date(endDate) };
    }

    return this.prisma.appointment.findMany({
      where,
      include: {
        patient: {
          include: {
            user: { select: { name: true, email: true } },
          },
        },
      },
      orderBy: { date: 'asc' },
    });
  }

  /**
   * Lista histórico completo de agendamentos do paciente
   * Inclui todos os status (PENDING, CONFIRMED, CANCELLED, COMPLETED)
   */
  async getAppointmentHistory(patientId: string) {
    return this.prisma.appointment.findMany({
      where: { patientId },
      orderBy: { date: 'desc' },
    });
  }
}
