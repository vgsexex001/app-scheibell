import { Injectable, NotFoundException, ConflictException, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AppointmentType } from '@prisma/client';
import { CreateScheduleDto, UpdateScheduleDto, CreateBlockedDateDto, UpdateBlockedDateDto } from './dto';

// Configuração padrão dos tipos de atendimento
export const APPOINTMENT_TYPE_CONFIG = {
  [AppointmentType.SPLINT_REMOVAL]: {
    name: 'Retirada de Splint',
    defaultDuration: 30,
    icon: 'healing',
  },
  [AppointmentType.CONSULTATION]: {
    name: 'Consulta',
    defaultDuration: 30,
    icon: 'stethoscope',
  },
  [AppointmentType.PHYSIOTHERAPY]: {
    name: 'Fisioterapia',
    defaultDuration: 60,
    icon: 'fitness_center',
  },
  [AppointmentType.RETURN_VISIT]: {
    name: 'Retorno',
    defaultDuration: 20,
    icon: 'event_repeat',
  },
  [AppointmentType.EVALUATION]: {
    name: 'Avaliação',
    defaultDuration: 45,
    icon: 'assignment',
  },
  [AppointmentType.EXAM]: {
    name: 'Exame',
    defaultDuration: 30,
    icon: 'biotech',
  },
  [AppointmentType.SURGERY]: {
    name: 'Cirurgia',
    defaultDuration: 120,
    icon: 'local_hospital',
  },
  [AppointmentType.OTHER]: {
    name: 'Outro',
    defaultDuration: 30,
    icon: 'event',
  },
};

// Tipos principais que aparecem na interface de configuração
export const MAIN_APPOINTMENT_TYPES = [
  AppointmentType.SPLINT_REMOVAL,
  AppointmentType.CONSULTATION,
  AppointmentType.PHYSIOTHERAPY,
];

@Injectable()
export class SchedulesService {
  private readonly logger = new Logger(SchedulesService.name);

  constructor(private readonly prisma: PrismaService) {}

  // ==================== APPOINTMENT TYPES ====================

  getAppointmentTypes() {
    return MAIN_APPOINTMENT_TYPES.map(type => ({
      type,
      ...APPOINTMENT_TYPE_CONFIG[type],
    }));
  }

  // ==================== CLINIC SCHEDULES ====================

  async getSchedules(clinicId: string, appointmentType?: AppointmentType) {
    this.logger.debug(`getSchedules: clinicId=${clinicId}, appointmentType=${appointmentType}, typeOf=${typeof appointmentType}`);

    // Validar clinicId
    if (!clinicId) {
      this.logger.warn('getSchedules: clinicId não fornecido');
      return [];
    }

    try {
      // Verificar se a clínica existe
      const clinic = await this.prisma.clinic.findUnique({
        where: { id: clinicId },
        select: { id: true, name: true, isActive: true },
      });

      if (!clinic) {
        this.logger.warn(`getSchedules: clínica não encontrada - clinicId=${clinicId}`);
        return [];
      }

      this.logger.debug(`getSchedules: clínica encontrada - ${clinic.name} (active: ${clinic.isActive})`);

      // Se appointmentType for fornecido, busca por esse tipo
      // Se não, busca todos os schedules da clínica
      const where: any = { clinicId };
      if (appointmentType) {
        // Validar se o appointmentType é um valor válido do enum
        const validTypes = Object.values(AppointmentType);
        if (!validTypes.includes(appointmentType)) {
          this.logger.warn(`getSchedules: appointmentType inválido - ${appointmentType}`);
          return [];
        }
        where.appointmentType = appointmentType;
      }

      this.logger.debug(`getSchedules: query where = ${JSON.stringify(where)}`);

      const schedules = await this.prisma.clinicSchedule.findMany({
        where,
        orderBy: { dayOfWeek: 'asc' },
      });

      this.logger.debug(`getSchedules: encontrados ${schedules.length} horários`);
      return schedules;
    } catch (error: any) {
      this.logger.error(`getSchedules: erro ao buscar horários - ${error.message}`);
      this.logger.error(`getSchedules: stack - ${error.stack}`);
      // Retorna array vazio em vez de lançar erro para evitar 500
      return [];
    }
  }

  async getSchedulesByType(clinicId: string, appointmentType: AppointmentType) {
    this.logger.log(`getSchedulesByType: clinicId=${clinicId}, appointmentType=${appointmentType}, type=${typeof appointmentType}`);

    const schedules = await this.prisma.clinicSchedule.findMany({
      where: {
        clinicId,
        appointmentType,
      },
      orderBy: { dayOfWeek: 'asc' },
    });

    this.logger.log(`getSchedulesByType: found ${schedules.length} schedules`);
    return schedules;
  }

  async getAllSchedulesGroupedByType(clinicId: string) {
    const schedules = await this.prisma.clinicSchedule.findMany({
      where: { clinicId },
      include: {
        clinicAppointmentType: true,
      },
      orderBy: [{ appointmentType: 'asc' }, { dayOfWeek: 'asc' }],
    });

    // Agrupar por tipo
    const grouped: Record<string, any[]> = {};

    for (const schedule of schedules) {
      const key = schedule.appointmentTypeId ?? schedule.appointmentType ?? 'GENERAL';
      if (!grouped[key]) {
        grouped[key] = [];
      }
      grouped[key].push(schedule);
    }

    return grouped;
  }

  /**
   * Busca schedules por appointmentTypeId (tipo de consulta personalizado)
   */
  async getSchedulesByAppointmentTypeId(clinicId: string, appointmentTypeId: string) {
    this.logger.log(`getSchedulesByAppointmentTypeId: clinicId=${clinicId}, appointmentTypeId=${appointmentTypeId}`);

    const schedules = await this.prisma.clinicSchedule.findMany({
      where: {
        clinicId,
        appointmentTypeId,
      },
      include: {
        clinicAppointmentType: true,
      },
      orderBy: { dayOfWeek: 'asc' },
    });

    this.logger.log(`getSchedulesByAppointmentTypeId: found ${schedules.length} schedules`);
    return schedules;
  }

  /**
   * Busca schedules gerais (sem appointmentTypeId e sem appointmentType)
   * Estes são os horários de fallback usados quando um tipo não tem horários específicos
   */
  async getGeneralSchedules(clinicId: string) {
    this.logger.log(`getGeneralSchedules: clinicId=${clinicId}`);

    const schedules = await this.prisma.clinicSchedule.findMany({
      where: {
        clinicId,
        appointmentTypeId: null,
        appointmentType: null,
      },
      orderBy: { dayOfWeek: 'asc' },
    });

    this.logger.log(`getGeneralSchedules: found ${schedules.length} schedules`);
    return schedules;
  }

  async getScheduleByDay(clinicId: string, dayOfWeek: number, appointmentType?: AppointmentType) {
    const schedule = await this.prisma.clinicSchedule.findFirst({
      where: {
        clinicId,
        dayOfWeek,
        appointmentType: appointmentType ?? null,
      },
    });

    return schedule;
  }

  async createOrUpdateSchedule(clinicId: string, dto: CreateScheduleDto) {
    const { dayOfWeek, appointmentType, appointmentTypeId, ...data } = dto;

    // Determina o critério de busca baseado em appointmentTypeId ou appointmentType
    const whereClause: any = {
      clinicId,
      dayOfWeek,
    };

    if (appointmentTypeId) {
      // Se temos appointmentTypeId, usamos ele (tipo personalizado)
      whereClause.appointmentTypeId = appointmentTypeId;
    } else if (appointmentType) {
      // Se temos appointmentType (enum legado), usamos ele
      whereClause.appointmentType = appointmentType;
      whereClause.appointmentTypeId = null;
    } else {
      // Horário geral (sem tipo específico)
      whereClause.appointmentType = null;
      whereClause.appointmentTypeId = null;
    }

    // Encontrar registro existente
    const existing = await this.prisma.clinicSchedule.findFirst({
      where: whereClause,
    });

    if (existing) {
      // Atualizar existente
      const schedule = await this.prisma.clinicSchedule.update({
        where: { id: existing.id },
        data: {
          ...data,
          updatedAt: new Date(),
        },
      });

      this.logger.log(`Schedule updated for clinic ${clinicId}, day ${dayOfWeek}, appointmentTypeId=${appointmentTypeId}, type=${appointmentType ?? 'GENERAL'}`);
      return schedule;
    }

    // Criar novo
    const schedule = await this.prisma.clinicSchedule.create({
      data: {
        clinicId,
        dayOfWeek,
        appointmentType: appointmentTypeId ? null : (appointmentType ?? null),
        appointmentTypeId: appointmentTypeId ?? null,
        openTime: dto.openTime,
        closeTime: dto.closeTime,
        breakStart: dto.breakStart,
        breakEnd: dto.breakEnd,
        slotDuration: dto.slotDuration ?? APPOINTMENT_TYPE_CONFIG[appointmentType ?? AppointmentType.CONSULTATION]?.defaultDuration ?? 30,
        maxAppointments: dto.maxAppointments,
        isActive: dto.isActive ?? true,
      },
    });

    this.logger.log(`Schedule created for clinic ${clinicId}, day ${dayOfWeek}, appointmentTypeId=${appointmentTypeId}, type=${appointmentType ?? 'GENERAL'}`);
    return schedule;
  }

  async updateSchedule(clinicId: string, dayOfWeek: number, dto: UpdateScheduleDto, appointmentType?: AppointmentType, appointmentTypeId?: string) {
    // Monta o where clause baseado em appointmentTypeId ou appointmentType
    const whereClause: any = { clinicId, dayOfWeek };
    if (appointmentTypeId) {
      whereClause.appointmentTypeId = appointmentTypeId;
    } else if (appointmentType) {
      whereClause.appointmentType = appointmentType;
      whereClause.appointmentTypeId = null;
    } else {
      whereClause.appointmentType = null;
      whereClause.appointmentTypeId = null;
    }

    const existing = await this.prisma.clinicSchedule.findFirst({
      where: whereClause,
    });

    if (!existing) {
      throw new NotFoundException(`Schedule not found for day ${dayOfWeek}`);
    }

    const schedule = await this.prisma.clinicSchedule.update({
      where: { id: existing.id },
      data: {
        ...dto,
        updatedAt: new Date(),
      },
    });

    this.logger.log(`Schedule updated for clinic ${clinicId}, day ${dayOfWeek}, appointmentTypeId=${appointmentTypeId}, type=${appointmentType ?? 'GENERAL'}`);
    return schedule;
  }

  async toggleSchedule(clinicId: string, dayOfWeek: number, appointmentType?: AppointmentType, appointmentTypeId?: string) {
    this.logger.log(`toggleSchedule: clinicId=${clinicId}, dayOfWeek=${dayOfWeek}, appointmentType=${appointmentType}, appointmentTypeId=${appointmentTypeId}`);

    try {
      // Monta o where clause baseado em appointmentTypeId ou appointmentType
      const whereClause: any = { clinicId, dayOfWeek };
      if (appointmentTypeId) {
        whereClause.appointmentTypeId = appointmentTypeId;
      } else if (appointmentType) {
        whereClause.appointmentType = appointmentType;
        whereClause.appointmentTypeId = null;
      } else {
        whereClause.appointmentType = null;
        whereClause.appointmentTypeId = null;
      }

      this.logger.log(`toggleSchedule: whereClause=${JSON.stringify(whereClause)}`);

      const existing = await this.prisma.clinicSchedule.findFirst({
        where: whereClause,
      });

      this.logger.log(`toggleSchedule: existing=${existing ? existing.id : 'null'}`);

      if (!existing) {
        // Se não existe, cria com valores padrão ativo
        const defaultDuration = APPOINTMENT_TYPE_CONFIG[appointmentType ?? AppointmentType.CONSULTATION]?.defaultDuration ?? 30;

        this.logger.log(`toggleSchedule: criando novo schedule, defaultDuration=${defaultDuration}`);

        const schedule = await this.prisma.clinicSchedule.create({
          data: {
            clinicId,
            dayOfWeek,
            appointmentType: appointmentTypeId ? null : (appointmentType ?? null),
            appointmentTypeId: appointmentTypeId ?? null,
            openTime: '08:00',
            closeTime: '18:00',
            slotDuration: defaultDuration,
            isActive: true,
          },
        });
        this.logger.log(`toggleSchedule: schedule criado com id=${schedule.id}`);
        return schedule;
      }

      const schedule = await this.prisma.clinicSchedule.update({
        where: { id: existing.id },
        data: {
          isActive: !existing.isActive,
          updatedAt: new Date(),
        },
      });

      this.logger.log(`Schedule toggled for clinic ${clinicId}, day ${dayOfWeek}, appointmentTypeId=${appointmentTypeId}, type=${appointmentType ?? 'GENERAL'}: ${schedule.isActive}`);
      return schedule;
    } catch (error: any) {
      this.logger.error(`toggleSchedule ERRO: ${error.message}`, error.stack);
      this.logger.error(`toggleSchedule ERRO code: ${error.code}, meta: ${JSON.stringify(error.meta)}`);
      throw error;
    }
  }

  async deleteSchedule(clinicId: string, dayOfWeek: number, appointmentType?: AppointmentType, appointmentTypeId?: string) {
    // Monta o where clause baseado em appointmentTypeId ou appointmentType
    const whereClause: any = { clinicId, dayOfWeek };
    if (appointmentTypeId) {
      whereClause.appointmentTypeId = appointmentTypeId;
    } else if (appointmentType) {
      whereClause.appointmentType = appointmentType;
      whereClause.appointmentTypeId = null;
    } else {
      whereClause.appointmentType = null;
      whereClause.appointmentTypeId = null;
    }

    const existing = await this.prisma.clinicSchedule.findFirst({
      where: whereClause,
    });

    if (!existing) {
      throw new NotFoundException(`Schedule not found for day ${dayOfWeek}`);
    }

    await this.prisma.clinicSchedule.delete({
      where: { id: existing.id },
    });

    this.logger.log(`Schedule deleted for clinic ${clinicId}, day ${dayOfWeek}, appointmentTypeId=${appointmentTypeId}, type=${appointmentType ?? 'GENERAL'}`);
    return { message: 'Schedule deleted successfully' };
  }

  // ==================== BLOCKED DATES ====================

  async getBlockedDates(clinicId: string, options?: { fromDate?: Date; appointmentType?: AppointmentType }) {
    // Buscar datas bloqueadas globais
    const globalWhere: any = { clinicId };
    if (options?.fromDate) {
      globalWhere.date = { gte: options.fromDate };
    }

    const globalBlockedDates = await this.prisma.clinicBlockedDate.findMany({
      where: globalWhere,
      orderBy: { date: 'asc' },
    });

    // Buscar datas bloqueadas por tipo (se aplicável)
    let typeBlockedDates: any[] = [];
    if (options?.appointmentType) {
      const typeWhere: any = {
        clinicId,
        appointmentType: options.appointmentType,
      };
      if (options?.fromDate) {
        typeWhere.date = { gte: options.fromDate };
      }

      typeBlockedDates = await this.prisma.clinicBlockedDateByType.findMany({
        where: typeWhere,
        orderBy: { date: 'asc' },
      });
    }

    return {
      global: globalBlockedDates,
      byType: typeBlockedDates,
      // Combinar para compatibilidade
      all: [
        ...globalBlockedDates.map(d => ({ ...d, isGlobal: true })),
        ...typeBlockedDates.map(d => ({ ...d, isGlobal: false })),
      ].sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime()),
    };
  }

  async getBlockedDatesByType(clinicId: string, appointmentType: AppointmentType, options?: { fromDate?: Date }) {
    const where: any = {
      clinicId,
      appointmentType,
    };
    if (options?.fromDate) {
      where.date = { gte: options.fromDate };
    }

    const blockedDates = await this.prisma.clinicBlockedDateByType.findMany({
      where,
      orderBy: { date: 'asc' },
    });

    return blockedDates;
  }

  async getBlockedDateById(clinicId: string, id: string) {
    const blockedDate = await this.prisma.clinicBlockedDate.findFirst({
      where: { id, clinicId },
    });

    if (!blockedDate) {
      throw new NotFoundException('Blocked date not found');
    }

    return blockedDate;
  }

  async createBlockedDate(clinicId: string, dto: CreateBlockedDateDto) {
    const date = new Date(dto.date);
    date.setHours(0, 0, 0, 0);

    // Se tem appointmentType, cria bloqueio específico
    if (dto.appointmentType) {
      const existing = await this.prisma.clinicBlockedDateByType.findFirst({
        where: {
          clinicId,
          appointmentType: dto.appointmentType,
          date,
        },
      });

      if (existing) {
        throw new ConflictException('Esta data já está bloqueada para este tipo de atendimento');
      }

      const blockedDate = await this.prisma.clinicBlockedDateByType.create({
        data: {
          clinicId,
          appointmentType: dto.appointmentType,
          date,
          reason: dto.reason,
        },
      });

      this.logger.log(`Blocked date created for clinic ${clinicId}, type ${dto.appointmentType}: ${dto.date}`);
      return { ...blockedDate, isGlobal: false };
    }

    // Bloqueio global
    const existing = await this.prisma.clinicBlockedDate.findUnique({
      where: {
        clinicId_date: { clinicId, date },
      },
    });

    if (existing) {
      throw new ConflictException('Esta data já está bloqueada');
    }

    const blockedDate = await this.prisma.clinicBlockedDate.create({
      data: {
        clinicId,
        date,
        reason: dto.reason,
      },
    });

    this.logger.log(`Blocked date created for clinic ${clinicId}: ${dto.date}`);
    return { ...blockedDate, isGlobal: true };
  }

  async updateBlockedDate(clinicId: string, id: string, dto: UpdateBlockedDateDto) {
    const existing = await this.prisma.clinicBlockedDate.findFirst({
      where: { id, clinicId },
    });

    if (!existing) {
      throw new NotFoundException('Blocked date not found');
    }

    const blockedDate = await this.prisma.clinicBlockedDate.update({
      where: { id },
      data: {
        reason: dto.reason,
        updatedAt: new Date(),
      },
    });

    this.logger.log(`Blocked date updated for clinic ${clinicId}: ${id}`);
    return blockedDate;
  }

  async deleteBlockedDate(clinicId: string, id: string, appointmentType?: AppointmentType) {
    // Tentar deletar do bloqueio por tipo primeiro
    if (appointmentType) {
      const existingByType = await this.prisma.clinicBlockedDateByType.findFirst({
        where: { id, clinicId },
      });

      if (existingByType) {
        await this.prisma.clinicBlockedDateByType.delete({
          where: { id },
        });

        this.logger.log(`Blocked date by type deleted for clinic ${clinicId}: ${id}`);
        return { message: 'Blocked date deleted successfully' };
      }
    }

    // Tentar deletar do bloqueio global
    const existing = await this.prisma.clinicBlockedDate.findFirst({
      where: { id, clinicId },
    });

    if (!existing) {
      // Última tentativa: buscar em blockedDateByType sem filtro de appointmentType
      const existingAnyType = await this.prisma.clinicBlockedDateByType.findFirst({
        where: { id, clinicId },
      });

      if (existingAnyType) {
        await this.prisma.clinicBlockedDateByType.delete({
          where: { id },
        });

        this.logger.log(`Blocked date by type deleted for clinic ${clinicId}: ${id}`);
        return { message: 'Blocked date deleted successfully' };
      }

      throw new NotFoundException('Blocked date not found');
    }

    await this.prisma.clinicBlockedDate.delete({
      where: { id },
    });

    this.logger.log(`Blocked date deleted for clinic ${clinicId}: ${id}`);
    return { message: 'Blocked date deleted successfully' };
  }

  // ==================== UTILITY ====================

  async isDateBlocked(clinicId: string, date: Date, appointmentType?: AppointmentType): Promise<boolean> {
    const normalizedDate = new Date(date);
    normalizedDate.setHours(0, 0, 0, 0);

    // Verificar bloqueio global
    const globalBlocked = await this.prisma.clinicBlockedDate.findUnique({
      where: {
        clinicId_date: { clinicId, date: normalizedDate },
      },
    });

    if (globalBlocked) return true;

    // Verificar bloqueio por tipo
    if (appointmentType) {
      const typeBlocked = await this.prisma.clinicBlockedDateByType.findFirst({
        where: {
          clinicId,
          appointmentType,
          date: normalizedDate,
        },
      });

      if (typeBlocked) return true;
    }

    return false;
  }

  async getAvailableSlots(clinicId: string, date: Date, appointmentType?: AppointmentType, appointmentTypeId?: string) {
    // IMPORTANTE: Usar getUTCDay() para evitar problemas de timezone
    // A data vem como "2026-01-19T00:00:00.000Z" (meia-noite UTC)
    // Se usarmos getDay() no Brasil (UTC-3), pode retornar o dia anterior
    const dayOfWeek = date.getUTCDay();

    this.logger.log(`getAvailableSlots: clinicId=${clinicId}, date=${date.toISOString()}, dayOfWeek=${dayOfWeek} (UTC), appointmentType=${appointmentType}, appointmentTypeId=${appointmentTypeId}`);

    // Verifica se a data está bloqueada
    if (await this.isDateBlocked(clinicId, date, appointmentType)) {
      this.logger.log(`getAvailableSlots: Data bloqueada`);
      return { available: false, reason: 'Data bloqueada', slots: [] };
    }

    let schedule = null;

    // Primeiro, tenta buscar por appointmentTypeId (tipo personalizado)
    if (appointmentTypeId) {
      this.logger.log(`getAvailableSlots: Buscando schedule com appointmentTypeId=${appointmentTypeId}`);
      schedule = await this.prisma.clinicSchedule.findFirst({
        where: {
          clinicId,
          dayOfWeek,
          appointmentTypeId,
        },
      });
      this.logger.log(`getAvailableSlots: Schedule encontrado por appointmentTypeId? ${schedule ? 'SIM' : 'NÃO'}`);
    }

    // Se não encontrou por appointmentTypeId, busca por appointmentType (enum legado)
    if (!schedule && appointmentType) {
      this.logger.log(`getAvailableSlots: Buscando schedule com appointmentType=${appointmentType}`);
      schedule = await this.prisma.clinicSchedule.findFirst({
        where: {
          clinicId,
          dayOfWeek,
          appointmentType,
        },
      });
      this.logger.log(`getAvailableSlots: Schedule encontrado por tipo? ${schedule ? 'SIM' : 'NÃO'}`);
    }

    // Se não encontrou por tipo, tentar buscar schedule geral (legado)
    if (!schedule) {
      this.logger.log(`getAvailableSlots: Tentando buscar schedule geral (legado)`);
      schedule = await this.prisma.clinicSchedule.findFirst({
        where: {
          clinicId,
          dayOfWeek,
          appointmentType: null,
          appointmentTypeId: null,
        },
      });
      this.logger.log(`getAvailableSlots: Schedule geral encontrado? ${schedule ? 'SIM' : 'NÃO'}`);
    }

    if (!schedule || !schedule.isActive) {
      this.logger.log(`getAvailableSlots: Clínica não atende - schedule=${!!schedule}, isActive=${schedule?.isActive}`);
      return { available: false, reason: 'Clínica não atende neste dia', slots: [] };
    }

    // Gera os slots disponíveis
    const allSlots = this.generateTimeSlots(
      schedule.openTime,
      schedule.closeTime,
      schedule.slotDuration,
      schedule.breakStart,
      schedule.breakEnd,
    );

    this.logger.log(`getAvailableSlots: Slots gerados: ${allSlots.length}`);

    // Buscar agendamentos existentes neste dia para marcar slots ocupados
    const startOfDay = new Date(date);
    startOfDay.setUTCHours(0, 0, 0, 0);
    const endOfDay = new Date(date);
    endOfDay.setUTCHours(23, 59, 59, 999);

    const existingAppointments = await this.prisma.appointment.findMany({
      where: {
        clinicId,
        date: {
          gte: startOfDay,
          lte: endOfDay,
        },
        status: { notIn: ['CANCELLED'] },
        deletedAt: null,
      },
      select: { time: true, type: true, duration: true },
    });

    this.logger.log(`getAvailableSlots: Agendamentos existentes: ${existingAppointments.length}`);

    // Calcular todos os slots ocupados considerando a duração de cada consulta
    const bookedSlots = new Set<string>();
    const slotDurationMinutes = schedule.slotDuration;

    for (const apt of existingAppointments) {
      // Usar a duração armazenada no agendamento, ou buscar do schedule atual como fallback
      let aptDuration = apt.duration;

      if (!aptDuration) {
        // Fallback para agendamentos antigos sem duração: buscar do schedule atual
        const aptSchedule = await this.prisma.clinicSchedule.findFirst({
          where: {
            clinicId,
            dayOfWeek,
            appointmentType: apt.type,
          },
          select: { slotDuration: true },
        });
        aptDuration = aptSchedule?.slotDuration || slotDurationMinutes;
      }
      const [aptHour, aptMinute] = apt.time.split(':').map(Number);
      const aptStartMinutes = aptHour * 60 + aptMinute;
      const aptEndMinutes = aptStartMinutes + aptDuration;

      this.logger.log(`getAvailableSlots: Consulta ${apt.time} (${apt.type}) ocupa ${aptStartMinutes}-${aptEndMinutes} (${aptDuration}min)`);

      // Marcar todos os slots que são ocupados por esta consulta
      for (const slotTime of allSlots) {
        const [slotHour, slotMinute] = slotTime.split(':').map(Number);
        const slotStartMinutes = slotHour * 60 + slotMinute;
        const slotEndMinutes = slotStartMinutes + slotDurationMinutes;

        // Um slot está ocupado se há sobreposição com a consulta existente
        // Sobreposição: início do slot < fim da consulta E fim do slot > início da consulta
        if (slotStartMinutes < aptEndMinutes && slotEndMinutes > aptStartMinutes) {
          bookedSlots.add(slotTime);
          this.logger.log(`getAvailableSlots: Slot ${slotTime} marcado como ocupado`);
        }
      }
    }

    // Retornar slots com status de disponibilidade
    const slotsWithStatus = allSlots.map(time => ({
      time,
      available: !bookedSlots.has(time),
    }));

    // Também retornar apenas os horários disponíveis (para compatibilidade)
    const availableSlots = allSlots.filter(time => !bookedSlots.has(time));

    this.logger.log(`getAvailableSlots: Slots disponíveis: ${availableSlots.length}/${allSlots.length}`);
    return {
      available: true,
      schedule,
      slots: availableSlots, // Apenas os disponíveis (compatibilidade)
      allSlots: slotsWithStatus, // Todos os slots com status
      bookedCount: bookedSlots.size,
    };
  }

  private generateTimeSlots(
    openTime: string,
    closeTime: string,
    slotDuration: number,
    breakStart?: string | null,
    breakEnd?: string | null,
  ): string[] {
    const slots: string[] = [];

    const [openHour, openMinute] = openTime.split(':').map(Number);
    const [closeHour, closeMinute] = closeTime.split(':').map(Number);

    let breakStartMinutes: number | null = null;
    let breakEndMinutes: number | null = null;

    if (breakStart && breakEnd) {
      const [bsH, bsM] = breakStart.split(':').map(Number);
      const [beH, beM] = breakEnd.split(':').map(Number);
      breakStartMinutes = bsH * 60 + bsM;
      breakEndMinutes = beH * 60 + beM;
    }

    let currentMinutes = openHour * 60 + openMinute;
    const endMinutes = closeHour * 60 + closeMinute;

    while (currentMinutes + slotDuration <= endMinutes) {
      // Verifica se está no intervalo
      if (breakStartMinutes !== null && breakEndMinutes !== null) {
        if (currentMinutes >= breakStartMinutes && currentMinutes < breakEndMinutes) {
          currentMinutes = breakEndMinutes;
          continue;
        }
      }

      const hours = Math.floor(currentMinutes / 60);
      const minutes = currentMinutes % 60;
      slots.push(`${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`);

      currentMinutes += slotDuration;
    }

    return slots;
  }
}
