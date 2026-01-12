import { Injectable, NotFoundException, ForbiddenException, BadRequestException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateAppointmentDto, UpdateStatusDto } from './dto';
import { AppointmentStatus, NotificationType, NotificationStatus } from '@prisma/client';
import { WebsocketService } from '../../websocket/websocket.service';

@Injectable()
export class AppointmentsService {
  constructor(
    private prisma: PrismaService,
    private websocketService: WebsocketService,
  ) {}

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
   * COM VALIDACAO DE CONFLITOS E HORARIOS
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

    const appointmentDate = new Date(dto.date);

    // VALIDACAO 1: Nao permitir agendamento no passado
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    if (appointmentDate < today) {
      throw new BadRequestException('Não é possível agendar para uma data no passado');
    }

    // VALIDACAO 2: Verificar se a clínica funciona neste dia da semana
    const dayOfWeek = appointmentDate.getDay();
    const clinicSchedule = await this.prisma.clinicSchedule.findUnique({
      where: {
        clinicId_dayOfWeek: {
          clinicId: patient.clinicId,
          dayOfWeek: dayOfWeek,
        },
      },
    });

    if (!clinicSchedule || !clinicSchedule.isActive) {
      const dayNames = ['domingo', 'segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado'];
      throw new BadRequestException(`A clínica não funciona às ${dayNames[dayOfWeek]}s`);
    }

    // VALIDACAO 3: Verificar se o horário está dentro do expediente
    const [requestedHour, requestedMinute] = dto.time.split(':').map(Number);
    const [openHour, openMinute] = clinicSchedule.openTime.split(':').map(Number);
    const [closeHour, closeMinute] = clinicSchedule.closeTime.split(':').map(Number);

    const requestedMinutes = requestedHour * 60 + requestedMinute;
    const openMinutes = openHour * 60 + openMinute;
    const closeMinutes = closeHour * 60 + closeMinute;

    if (requestedMinutes < openMinutes || requestedMinutes >= closeMinutes) {
      throw new BadRequestException(
        `O horário solicitado está fora do expediente (${clinicSchedule.openTime} - ${clinicSchedule.closeTime})`
      );
    }

    // VALIDACAO 4: Verificar conflito de horário (mesmo dia + mesmo horário)
    const startOfDay = new Date(appointmentDate);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(appointmentDate);
    endOfDay.setHours(23, 59, 59, 999);

    const conflictingAppointment = await this.prisma.appointment.findFirst({
      where: {
        patient: { clinicId: patient.clinicId },
        date: {
          gte: startOfDay,
          lte: endOfDay,
        },
        time: dto.time,
        status: { notIn: [AppointmentStatus.CANCELLED] },
        deletedAt: null,
      },
    });

    if (conflictingAppointment) {
      throw new ConflictException(
        `Já existe um agendamento para este horário (${dto.time}). Por favor, escolha outro horário.`
      );
    }

    // VALIDACAO 5: Verificar limite máximo de agendamentos no dia
    const appointmentsOnDay = await this.prisma.appointment.count({
      where: {
        patient: { clinicId: patient.clinicId },
        date: {
          gte: startOfDay,
          lte: endOfDay,
        },
        status: { notIn: [AppointmentStatus.CANCELLED] },
        deletedAt: null,
      },
    });

    if (appointmentsOnDay >= clinicSchedule.maxSlots) {
      throw new BadRequestException(
        'Este dia já está lotado. Por favor, escolha outra data.'
      );
    }

    // Todas as validacoes passaram - criar o agendamento
    const appointment = await this.prisma.appointment.create({
      data: {
        patientId,
        title: dto.title,
        description: dto.description,
        date: appointmentDate,
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

    // Notificar clínica via WebSocket
    this.websocketService.notifyNewAppointment(patient.clinicId, {
      id: appointment.id,
      title: appointment.title,
      date: appointment.date,
      time: appointment.time,
      type: appointment.type,
      status: appointment.status,
      patientId,
      patientName,
    });

    return appointment;
  }

  /**
   * Atualiza o status de uma consulta
   */
  async updateStatus(id: string, patientId: string, dto: UpdateStatusDto) {
    // Verifica se a consulta existe e pertence ao paciente
    await this.getAppointmentById(id, patientId);

    const updatedAppointment = await this.prisma.appointment.update({
      where: { id },
      data: { status: dto.status },
    });

    // Buscar clinicId do paciente para notificação
    const patient = await this.prisma.patient.findUnique({
      where: { id: patientId },
      select: { clinicId: true },
    });

    if (patient) {
      // Notificar via WebSocket
      this.websocketService.notifyAppointmentStatusChanged(patientId, patient.clinicId, {
        id: updatedAppointment.id,
        title: updatedAppointment.title,
        date: updatedAppointment.date,
        time: updatedAppointment.time,
        status: updatedAppointment.status,
      });
    }

    return updatedAppointment;
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

  // ==================== SLOTS E DISPONIBILIDADE ====================

  /**
   * Lista horários disponíveis para uma data específica
   * GET /api/appointments/available-slots?date=2024-01-15&clinicId=xxx
   */
  async getAvailableSlots(clinicId: string, dateStr: string) {
    const date = new Date(dateStr);
    const dayOfWeek = date.getDay();

    // Buscar configuração de horário da clínica
    const schedule = await this.prisma.clinicSchedule.findUnique({
      where: {
        clinicId_dayOfWeek: {
          clinicId,
          dayOfWeek,
        },
      },
    });

    if (!schedule || !schedule.isActive) {
      return {
        date: dateStr,
        available: false,
        message: 'A clínica não funciona neste dia',
        slots: [],
      };
    }

    // Gerar todos os slots possíveis
    const allSlots = this.generateTimeSlots(
      schedule.openTime,
      schedule.closeTime,
      schedule.slotDuration
    );

    // Buscar agendamentos existentes neste dia
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    const existingAppointments = await this.prisma.appointment.findMany({
      where: {
        patient: { clinicId },
        date: {
          gte: startOfDay,
          lte: endOfDay,
        },
        status: { notIn: [AppointmentStatus.CANCELLED] },
        deletedAt: null,
      },
      select: { time: true },
    });

    const bookedTimes = new Set(existingAppointments.map(a => a.time));

    // Marcar slots disponíveis/ocupados
    const slots = allSlots.map(time => ({
      time,
      available: !bookedTimes.has(time),
    }));

    const availableCount = slots.filter(s => s.available).length;

    return {
      date: dateStr,
      dayOfWeek,
      openTime: schedule.openTime,
      closeTime: schedule.closeTime,
      slotDuration: schedule.slotDuration,
      totalSlots: allSlots.length,
      availableSlots: availableCount,
      bookedSlots: bookedTimes.size,
      maxSlots: schedule.maxSlots,
      isFull: availableCount === 0 || existingAppointments.length >= schedule.maxSlots,
      slots,
    };
  }

  /**
   * Gera array de horários entre abertura e fechamento
   */
  private generateTimeSlots(openTime: string, closeTime: string, durationMinutes: number): string[] {
    const slots: string[] = [];
    const [openHour, openMinute] = openTime.split(':').map(Number);
    const [closeHour, closeMinute] = closeTime.split(':').map(Number);

    let currentMinutes = openHour * 60 + openMinute;
    const closeMinutes = closeHour * 60 + closeMinute;

    while (currentMinutes < closeMinutes) {
      const hours = Math.floor(currentMinutes / 60);
      const minutes = currentMinutes % 60;
      slots.push(`${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`);
      currentMinutes += durationMinutes;
    }

    return slots;
  }

  /**
   * Lista dias disponíveis em um período (para calendario)
   * GET /api/appointments/available-days?startDate=2024-01-01&endDate=2024-01-31&clinicId=xxx
   */
  async getAvailableDays(clinicId: string, startDateStr: string, endDateStr: string) {
    // Buscar configuração de horários da clínica
    const schedules = await this.prisma.clinicSchedule.findMany({
      where: { clinicId, isActive: true },
    });

    const activeDays = new Set(schedules.map(s => s.dayOfWeek));
    const scheduleMap = new Map(schedules.map(s => [s.dayOfWeek, s]));

    const startDate = new Date(startDateStr);
    const endDate = new Date(endDateStr);
    const days: Array<{
      date: string;
      dayOfWeek: number;
      available: boolean;
      openTime?: string;
      closeTime?: string;
      remainingSlots?: number;
    }> = [];

    // Contar agendamentos por dia no período
    const appointments = await this.prisma.appointment.findMany({
      where: {
        patient: { clinicId },
        date: {
          gte: startDate,
          lte: endDate,
        },
        status: { notIn: [AppointmentStatus.CANCELLED] },
        deletedAt: null,
      },
      select: { date: true },
    });

    // Agrupar agendamentos por dia
    const appointmentsByDay = new Map<string, number>();
    for (const apt of appointments) {
      const dayKey = apt.date.toISOString().split('T')[0];
      appointmentsByDay.set(dayKey, (appointmentsByDay.get(dayKey) || 0) + 1);
    }

    // Iterar cada dia do período
    const current = new Date(startDate);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    while (current <= endDate) {
      const dayOfWeek = current.getDay();
      const dateStr = current.toISOString().split('T')[0];
      const schedule = scheduleMap.get(dayOfWeek);
      const bookedCount = appointmentsByDay.get(dateStr) || 0;

      // Disponível se: clínica funciona, não é passado, não está lotado
      const isOpen = activeDays.has(dayOfWeek);
      const isPast = current < today;
      const isFull = schedule ? bookedCount >= schedule.maxSlots : true;

      days.push({
        date: dateStr,
        dayOfWeek,
        available: isOpen && !isPast && !isFull,
        openTime: schedule?.openTime,
        closeTime: schedule?.closeTime,
        remainingSlots: schedule ? Math.max(0, schedule.maxSlots - bookedCount) : 0,
      });

      current.setDate(current.getDate() + 1);
    }

    return {
      clinicId,
      period: { start: startDateStr, end: endDateStr },
      days,
    };
  }
}
