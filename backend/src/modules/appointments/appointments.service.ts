import { Injectable, NotFoundException, ForbiddenException, BadRequestException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateAppointmentDto, UpdateStatusDto } from './dto';
import { AppointmentStatus, AppointmentType, NotificationType, NotificationStatus } from '@prisma/client';
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
      include: {
        clinicAppointmentType: true,
      },
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
      include: {
        clinicAppointmentType: true,
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
      include: {
        clinicAppointmentType: true,
      },
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

    // Se appointmentTypeId foi fornecido, busca o tipo personalizado
    let clinicAppointmentType = null;
    let appointmentDurationFromType = null;
    if (dto.appointmentTypeId) {
      clinicAppointmentType = await this.prisma.clinicAppointmentType.findFirst({
        where: {
          id: dto.appointmentTypeId,
          clinicId: patient.clinicId,
          isActive: true,
        },
      });
      if (!clinicAppointmentType) {
        throw new BadRequestException('Tipo de consulta não encontrado ou inativo');
      }
      appointmentDurationFromType = clinicAppointmentType.defaultDuration;
    }

    const appointmentDate = new Date(dto.date);

    // VALIDACAO 1: Nao permitir agendamento no passado
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    if (appointmentDate < today) {
      throw new BadRequestException('Não é possível agendar para uma data no passado');
    }

    // VALIDACAO 2: Verificar se a clínica funciona neste dia da semana
    // IMPORTANTE: Usar getUTCDay() para evitar problemas de timezone
    // A data vem como "2026-01-19" que é interpretada como meia-noite UTC
    const dayOfWeek = appointmentDate.getUTCDay();
    // Primeiro tenta buscar schedule específico do tipo de atendimento
    let clinicSchedule = await this.prisma.clinicSchedule.findFirst({
      where: {
        clinicId: patient.clinicId,
        dayOfWeek: dayOfWeek,
        appointmentType: dto.type ?? null,
      },
    });
    // Se não encontrou, busca schedule geral (legado)
    if (!clinicSchedule) {
      clinicSchedule = await this.prisma.clinicSchedule.findFirst({
        where: {
          clinicId: patient.clinicId,
          dayOfWeek: dayOfWeek,
          appointmentType: null,
        },
      });
    }

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

    // Calcular maxSlots baseado no horário de funcionamento e duração do slot
    const maxSlots = this.calculateMaxSlots(clinicSchedule);
    if (appointmentsOnDay >= maxSlots) {
      throw new BadRequestException(
        'Este dia já está lotado. Por favor, escolha outra data.'
      );
    }

    // Todas as validacoes passaram - criar o agendamento
    // Usar duração do tipo personalizado se disponível, senão do schedule
    const appointmentDuration = appointmentDurationFromType ?? clinicSchedule.slotDuration;

    const appointment = await this.prisma.appointment.create({
      data: {
        patientId,
        clinicId: patient.clinicId,
        title: dto.title,
        description: dto.description,
        date: appointmentDate,
        time: dto.time,
        duration: appointmentDuration, // Duração em minutos
        type: dto.type || AppointmentType.CONSULTATION,
        appointmentTypeId: dto.appointmentTypeId,
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
        clinicAppointmentType: true,
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
      include: {
        clinicAppointmentType: true,
      },
      orderBy: { date: 'desc' },
    });
  }

  // ==================== SLOTS E DISPONIBILIDADE ====================

  /**
   * Lista horários disponíveis para uma data específica
   * GET /api/appointments/available-slots?date=2024-01-15&clinicId=xxx
   */
  async getAvailableSlots(clinicId: string, dateStr: string, appointmentType?: string) {
    const date = new Date(dateStr);
    // IMPORTANTE: Usar getUTCDay() para evitar problemas de timezone
    const dayOfWeek = date.getUTCDay();

    // Buscar configuração de horário da clínica (primeiro por tipo, depois geral)
    let schedule = await this.prisma.clinicSchedule.findFirst({
      where: {
        clinicId,
        dayOfWeek,
        appointmentType: appointmentType as any ?? null,
      },
    });

    // Se não encontrou por tipo, tenta buscar schedule geral
    if (!schedule && appointmentType) {
      schedule = await this.prisma.clinicSchedule.findFirst({
        where: {
          clinicId,
          dayOfWeek,
          appointmentType: null,
        },
      });
    }

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
      select: { time: true, type: true },
    });

    // Calcular todos os slots ocupados considerando a duração de cada consulta
    const bookedSlots = new Set<string>();
    const slotDurationMinutes = schedule.slotDuration;

    for (const apt of existingAppointments) {
      // Buscar a duração específica do tipo de atendimento
      const aptSchedule = await this.prisma.clinicSchedule.findFirst({
        where: {
          clinicId,
          appointmentType: apt.type,
        },
        select: { slotDuration: true },
      });

      const aptDuration = aptSchedule?.slotDuration || slotDurationMinutes;
      const [aptHour, aptMinute] = apt.time.split(':').map(Number);
      const aptStartMinutes = aptHour * 60 + aptMinute;
      const aptEndMinutes = aptStartMinutes + aptDuration;

      // Marcar todos os slots que são ocupados por esta consulta
      for (const slotTime of allSlots) {
        const [slotHour, slotMinute] = slotTime.split(':').map(Number);
        const slotStartMinutes = slotHour * 60 + slotMinute;
        const slotEndMinutes = slotStartMinutes + slotDurationMinutes;

        // Um slot está ocupado se há sobreposição com a consulta existente
        // Sobreposição: início do slot < fim da consulta E fim do slot > início da consulta
        if (slotStartMinutes < aptEndMinutes && slotEndMinutes > aptStartMinutes) {
          bookedSlots.add(slotTime);
        }
      }
    }

    // Marcar slots disponíveis/ocupados
    const slots = allSlots.map(time => ({
      time,
      available: !bookedSlots.has(time),
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
      bookedSlots: bookedSlots.size,
      maxSlots: allSlots.length,
      isFull: availableCount === 0 || existingAppointments.length >= allSlots.length,
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
   * Calcula o número máximo de slots baseado no horário de funcionamento
   */
  private calculateMaxSlots(schedule: { openTime: string; closeTime: string; slotDuration: number; breakStart?: string | null; breakEnd?: string | null }): number {
    const [openHour, openMinute] = schedule.openTime.split(':').map(Number);
    const [closeHour, closeMinute] = schedule.closeTime.split(':').map(Number);

    let totalMinutes = (closeHour * 60 + closeMinute) - (openHour * 60 + openMinute);

    // Subtrair tempo de intervalo se existir
    if (schedule.breakStart && schedule.breakEnd) {
      const [breakStartHour, breakStartMinute] = schedule.breakStart.split(':').map(Number);
      const [breakEndHour, breakEndMinute] = schedule.breakEnd.split(':').map(Number);
      const breakMinutes = (breakEndHour * 60 + breakEndMinute) - (breakStartHour * 60 + breakStartMinute);
      totalMinutes -= breakMinutes;
    }

    return Math.floor(totalMinutes / schedule.slotDuration);
  }

  /**
   * Lista dias disponíveis em um período (para calendario)
   * GET /api/appointments/available-days?startDate=2024-01-01&endDate=2024-01-31&clinicId=xxx
   */
  async getAvailableDays(clinicId: string, startDateStr: string, endDateStr: string, appointmentType?: string) {
    // Buscar configuração de horários da clínica (filtrar por tipo se fornecido)
    const schedules = await this.prisma.clinicSchedule.findMany({
      where: {
        clinicId,
        isActive: true,
        ...(appointmentType ? { appointmentType: appointmentType as any } : {}),
      },
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

    // Contar agendamentos por dia no período (filtrar por tipo se fornecido)
    const appointments = await this.prisma.appointment.findMany({
      where: {
        patient: { clinicId },
        date: {
          gte: startDate,
          lte: endDate,
        },
        status: { notIn: [AppointmentStatus.CANCELLED] },
        deletedAt: null,
        ...(appointmentType ? { type: appointmentType as any } : {}),
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
      // IMPORTANTE: Usar getUTCDay() para evitar problemas de timezone
      const dayOfWeek = current.getUTCDay();
      const dateStr = current.toISOString().split('T')[0];
      const schedule = scheduleMap.get(dayOfWeek);
      const bookedCount = appointmentsByDay.get(dateStr) || 0;

      // Disponível se: clínica funciona, não é passado, não está lotado
      const isOpen = activeDays.has(dayOfWeek);
      const isPast = current < today;
      const maxSlots = schedule ? this.calculateMaxSlots(schedule) : 0;
      const isFull = schedule ? bookedCount >= maxSlots : true;

      days.push({
        date: dateStr,
        dayOfWeek,
        available: isOpen && !isPast && !isFull,
        openTime: schedule?.openTime,
        closeTime: schedule?.closeTime,
        remainingSlots: schedule ? Math.max(0, maxSlots - bookedCount) : 0,
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
