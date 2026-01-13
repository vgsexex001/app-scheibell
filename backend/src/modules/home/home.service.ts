import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import {
  HomeResponseDto,
  HomeItemDto,
  TakeMedicationDto,
  CompleteTaskDto,
  UpdateVideoProgressDto,
  CreateTaskDto,
} from './dto/home.dto';

@Injectable()
export class HomeService {
  constructor(private prisma: PrismaService) {}

  // ==================== MAIN HOME ENDPOINT ====================

  async getHomeData(patientId: string): Promise<HomeResponseDto> {
    const now = new Date();
    const currentHour = now.getHours();
    const today = this.startOfDay(now);

    // 1. Buscar dados do paciente
    const patient = await this.prisma.patient.findUnique({
      where: { id: patientId },
      include: {
        user: { select: { name: true } },
        clinic: { select: { id: true, name: true } },
      },
    });

    if (!patient) {
      throw new NotFoundException('Paciente não encontrado');
    }

    const patientName = patient.user?.name || patient.name || 'Paciente';
    const dayPostOp = this.calculateDayPostOp(patient.surgeryDate);

    // 2. Coletar itens de todas as fontes
    const items: HomeItemDto[] = [];

    // 2.1 MEDICAÇÕES
    const medications = await this.getMedicationsForHome(patient, dayPostOp, currentHour);
    items.push(...medications);

    // 2.2 VÍDEOS
    const videos = await this.getVideosForHome(patient, dayPostOp);
    items.push(...videos);

    // 2.3 TAREFAS
    const tasks = await this.getTasksForHome(patient, dayPostOp, today, currentHour);
    items.push(...tasks);

    // 3. Ordenar por prioridade
    items.sort((a, b) => {
      const statusOrder = { OVERDUE: 0, PENDING: 1, IN_PROGRESS: 2, UPCOMING: 3 };
      const statusDiff = statusOrder[a.status] - statusOrder[b.status];
      if (statusDiff !== 0) return statusDiff;
      return b.priority - a.priority;
    });

    // 4. Limitar quantidade
    const maxItems = 8;
    const limitedItems = items.slice(0, maxItems);

    // 5. Buscar próximo agendamento
    const nextAppointment = await this.getNextAppointment(patientId);

    // 6. Calcular sumário
    const summary = {
      medicationsPending: medications.filter(m => m.status === 'PENDING' || m.status === 'OVERDUE').length,
      tasksPending: tasks.filter(t => t.status === 'PENDING' || t.status === 'OVERDUE').length,
      videosIncomplete: videos.length,
    };

    return {
      greeting: this.getGreeting(currentHour, patientName),
      dayPostOp,
      summary,
      items: limitedItems,
      nextAppointment,
    };
  }

  // ==================== MEDICAÇÕES ====================

  private async getMedicationsForHome(
    patient: any,
    dayPostOp: number,
    currentHour: number
  ): Promise<HomeItemDto[]> {
    const items: HomeItemDto[] = [];

    // 1. Buscar medicações ativas para o dia pós-op atual
    const medications = await this.prisma.clinicContent.findMany({
      where: {
        clinicId: patient.clinicId,
        type: 'MEDICATIONS',
        isActive: true,
        OR: [
          { validFromDay: null },
          { validFromDay: { lte: dayPostOp } },
        ],
      },
    });

    // Filtrar por validUntilDay
    const validMedications = medications.filter(med => {
      if (med.validUntilDay === null) return true;
      return med.validUntilDay >= dayPostOp;
    });

    // 2. Buscar ajustes do paciente (DISABLE)
    const disabledAdjustments = await this.prisma.patientContentAdjustment.findMany({
      where: {
        patientId: patient.id,
        adjustmentType: 'DISABLE',
        isActive: true,
      },
    });

    const disabledIds = new Set(disabledAdjustments.map(a => a.baseContentId));

    // 3. Buscar logs de hoje
    const today = this.startOfDay(new Date());
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const todayLogs = await this.prisma.medicationLog.findMany({
      where: {
        patientId: patient.id,
        takenAt: {
          gte: today,
          lt: tomorrow,
        },
      },
    });

    const logMap = new Map<string, Set<string>>();
    todayLogs.forEach(log => {
      if (!logMap.has(log.contentId)) {
        logMap.set(log.contentId, new Set());
      }
      logMap.get(log.contentId)!.add(log.scheduledTime);
    });

    // 4. Processar cada medicação
    for (const med of validMedications) {
      if (disabledIds.has(med.id)) continue;

      const schedules = this.parseSchedules(med.description);

      for (const schedule of schedules) {
        const scheduleHour = parseInt(schedule.split(':')[0]);

        // Verificar se já foi tomado
        const wasTaken = logMap.get(med.id)?.has(schedule) || false;

        if (wasTaken) continue;

        // Calcular status e prioridade
        let status: 'PENDING' | 'OVERDUE' | 'UPCOMING';
        let priority: number;

        if (scheduleHour < currentHour) {
          status = 'OVERDUE';
          priority = 95;
        } else if (scheduleHour === currentHour) {
          status = 'PENDING';
          priority = 90;
        } else if (scheduleHour <= currentHour + 2) {
          status = 'UPCOMING';
          priority = 70;
        } else {
          continue; // Muito futuro
        }

        items.push({
          id: `med-${med.id}-${schedule}`,
          type: 'MEDICATION',
          priority,
          status,
          title: med.title,
          subtitle: status === 'OVERDUE'
            ? `Atrasado - era às ${schedule}`
            : `Tomar às ${schedule}`,
          scheduledTime: schedule,
          action: {
            type: 'TAKE',
            label: 'Tomar agora',
          },
          metadata: {
            contentId: med.id,
            scheduledTime: schedule,
          },
        });
      }
    }

    return items;
  }

  // ==================== VÍDEOS ====================

  private async getVideosForHome(
    patient: any,
    dayPostOp: number
  ): Promise<HomeItemDto[]> {
    const items: HomeItemDto[] = [];

    // 1. Buscar vídeos válidos (conteúdos CARE com descrição que indica vídeo)
    const videos = await this.prisma.clinicContent.findMany({
      where: {
        clinicId: patient.clinicId,
        type: { in: ['CARE', 'TRAINING'] },
        isActive: true,
        description: { contains: 'video' }, // Simplificado - idealmente teria campo videoUrl
        OR: [
          { validFromDay: null },
          { validFromDay: { lte: dayPostOp } },
        ],
      },
    });

    const validVideos = videos.filter(v => {
      if (v.validUntilDay === null) return true;
      return v.validUntilDay >= dayPostOp;
    });

    // 2. Buscar progresso do paciente
    const progress = await this.prisma.videoProgress.findMany({
      where: {
        patientId: patient.id,
        contentId: { in: validVideos.map(v => v.id) },
      },
    });

    const progressMap = new Map(progress.map(p => [p.contentId, p]));

    // 3. Filtrar apenas vídeos incompletos
    for (const video of validVideos) {
      const videoProgress = progressMap.get(video.id);

      if (videoProgress?.isCompleted) continue;

      const hasStarted = videoProgress && videoProgress.watchedSeconds > 0;

      items.push({
        id: `video-${video.id}`,
        type: 'VIDEO',
        priority: hasStarted ? 75 : 50,
        status: hasStarted ? 'IN_PROGRESS' : 'PENDING',
        title: video.title,
        subtitle: hasStarted
          ? `${Math.round(videoProgress!.progressPercent)}% assistido`
          : 'Vídeo importante',
        action: {
          type: 'WATCH',
          label: hasStarted ? 'Continuar' : 'Assistir',
        },
        metadata: {
          contentId: video.id,
          progress: videoProgress?.progressPercent || 0,
          watchedSeconds: videoProgress?.watchedSeconds || 0,
        },
      });
    }

    return items;
  }

  // ==================== TAREFAS ====================

  private async getTasksForHome(
    patient: any,
    dayPostOp: number,
    today: Date,
    currentHour: number
  ): Promise<HomeItemDto[]> {
    const items: HomeItemDto[] = [];
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // 1. Buscar tarefas válidas para hoje
    const tasks = await this.prisma.patientTask.findMany({
      where: {
        patientId: patient.id,
        status: { not: 'COMPLETED' },
        OR: [
          // Tarefas com data específica = hoje
          {
            scheduledDate: {
              gte: today,
              lt: tomorrow,
            },
          },
          // Tarefas recorrentes válidas para o dia pós-op
          {
            isRecurring: true,
            validFromDay: { lte: dayPostOp },
            validUntilDay: { gte: dayPostOp },
          },
          // Tarefas sem data específica mas válidas
          {
            scheduledDate: null,
            OR: [
              { validFromDay: null },
              {
                validFromDay: { lte: dayPostOp },
                validUntilDay: { gte: dayPostOp },
              },
            ],
          },
        ],
      },
    });

    // 2. Buscar logs de conclusão de hoje
    const completionLogs = await this.prisma.taskCompletionLog.findMany({
      where: {
        patientId: patient.id,
        scheduledFor: {
          gte: today,
          lt: tomorrow,
        },
      },
    });

    const completedTaskIds = new Set(completionLogs.map(l => l.taskId));

    // 3. Filtrar tarefas pendentes
    for (const task of tasks) {
      if (completedTaskIds.has(task.id)) continue;

      let status: 'PENDING' | 'OVERDUE' | 'UPCOMING';
      let priority: number;

      if (task.scheduledTime) {
        const taskHour = parseInt(task.scheduledTime.split(':')[0]);

        if (taskHour < currentHour) {
          status = 'OVERDUE';
          priority = task.priority === 'URGENT' ? 98 : 85;
        } else if (taskHour === currentHour) {
          status = 'PENDING';
          priority = task.priority === 'URGENT' ? 95 : 80;
        } else {
          status = 'UPCOMING';
          priority = 60;
        }
      } else {
        status = 'PENDING';
        priority = task.priority === 'URGENT' ? 90 : 65;
      }

      items.push({
        id: `task-${task.id}`,
        type: 'TASK',
        priority,
        status,
        title: task.title,
        subtitle: task.scheduledTime
          ? `${status === 'OVERDUE' ? 'Era' : 'Fazer'} às ${task.scheduledTime}`
          : task.description || undefined,
        scheduledTime: task.scheduledTime || undefined,
        action: {
          type: 'COMPLETE',
          label: 'Concluir',
        },
        metadata: {
          taskId: task.id,
          category: task.category,
        },
      });
    }

    return items;
  }

  // ==================== ACTIONS ====================

  async takeMedication(patientId: string, dto: TakeMedicationDto) {
    // Verificar se o paciente existe
    const patient = await this.prisma.patient.findUnique({
      where: { id: patientId },
    });

    if (!patient) {
      throw new NotFoundException('Paciente não encontrado');
    }

    // Criar log de medicação
    const log = await this.prisma.medicationLog.create({
      data: {
        patientId,
        contentId: dto.contentId,
        scheduledTime: dto.scheduledTime,
        takenAt: new Date(),
      },
    });

    return { success: true, logId: log.id };
  }

  async completeTask(patientId: string, dto: CompleteTaskDto) {
    // Verificar se a tarefa existe
    const task = await this.prisma.patientTask.findUnique({
      where: { id: dto.taskId },
    });

    if (!task) {
      throw new NotFoundException('Tarefa não encontrada');
    }

    const today = this.startOfDay(new Date());

    // Se for recorrente, criar log de conclusão
    if (task.isRecurring) {
      await this.prisma.taskCompletionLog.create({
        data: {
          taskId: dto.taskId,
          patientId,
          scheduledFor: today,
          notes: dto.notes,
        },
      });
    } else {
      // Se não for recorrente, atualizar status da tarefa
      await this.prisma.patientTask.update({
        where: { id: dto.taskId },
        data: {
          status: 'COMPLETED',
          completedAt: new Date(),
          completedNote: dto.notes,
        },
      });
    }

    return { success: true };
  }

  async updateVideoProgress(patientId: string, dto: UpdateVideoProgressDto) {
    const progressPercent = (dto.watchedSeconds / dto.totalSeconds) * 100;
    const isCompleted = dto.isCompleted || progressPercent >= 90;

    const progress = await this.prisma.videoProgress.upsert({
      where: {
        patientId_contentId: {
          patientId,
          contentId: dto.contentId,
        },
      },
      create: {
        patientId,
        contentId: dto.contentId,
        watchedSeconds: dto.watchedSeconds,
        totalSeconds: dto.totalSeconds,
        progressPercent,
        isCompleted,
        completedAt: isCompleted ? new Date() : null,
      },
      update: {
        watchedSeconds: dto.watchedSeconds,
        totalSeconds: dto.totalSeconds,
        progressPercent,
        isCompleted,
        lastWatchedAt: new Date(),
        completedAt: isCompleted ? new Date() : undefined,
      },
    });

    return { success: true, progress };
  }

  async createTask(patientId: string, clinicId: string, dto: CreateTaskDto) {
    const task = await this.prisma.patientTask.create({
      data: {
        patientId,
        clinicId,
        title: dto.title,
        description: dto.description,
        category: (dto.category as any) || 'CARE',
        priority: (dto.priority as any) || 'MEDIUM',
        scheduledDate: dto.scheduledDate ? new Date(dto.scheduledDate) : null,
        scheduledTime: dto.scheduledTime,
        isRecurring: dto.isRecurring || false,
        recurrenceRule: dto.recurrenceRule,
        sourceType: 'PATIENT',
      },
    });

    return task;
  }

  // ==================== HELPERS ====================

  private async getNextAppointment(patientId: string) {
    const appointment = await this.prisma.appointment.findFirst({
      where: {
        patientId,
        status: { in: ['PENDING', 'CONFIRMED'] },
        date: { gte: new Date() },
      },
      orderBy: { date: 'asc' },
    });

    if (!appointment) return undefined;

    return {
      id: appointment.id,
      date: appointment.date.toISOString(),
      type: appointment.type,
      title: appointment.title,
    };
  }

  private calculateDayPostOp(surgeryDate: Date | null): number {
    if (!surgeryDate) return 0;

    const now = new Date();
    const diffTime = now.getTime() - surgeryDate.getTime();
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));

    return Math.max(0, diffDays);
  }

  private startOfDay(date: Date): Date {
    const d = new Date(date);
    d.setHours(0, 0, 0, 0);
    return d;
  }

  private getGreeting(hour: number, name: string): string {
    let greeting: string;

    if (hour >= 5 && hour < 12) {
      greeting = 'Bom dia';
    } else if (hour >= 12 && hour < 18) {
      greeting = 'Boa tarde';
    } else {
      greeting = 'Boa noite';
    }

    const firstName = name.split(' ')[0];
    return `${greeting}, ${firstName}!`;
  }

  private parseSchedules(description: string | null): string[] {
    if (!description) return [];

    // Buscar padrão "Horários: HH:mm, HH:mm, ..."
    const match = description.match(/Hor[aá]rios?:\s*([0-9:,\s]+)/i);
    if (match) {
      return match[1].split(',').map(s => s.trim()).filter(s => /^\d{2}:\d{2}$/.test(s));
    }

    // Buscar horários isolados no formato HH:mm
    const times = description.match(/\b\d{2}:\d{2}\b/g);
    return times || [];
  }
}
