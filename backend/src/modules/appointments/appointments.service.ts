import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateAppointmentDto, UpdateStatusDto } from './dto';
import { AppointmentStatus } from '@prisma/client';

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
   * Cria uma nova consulta
   */
  async createAppointment(patientId: string, dto: CreateAppointmentDto) {
    return this.prisma.appointment.create({
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
}
