import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateExternalEventDto, UpdateExternalEventDto } from './dto';

@Injectable()
export class ExternalEventsService {
  constructor(private prisma: PrismaService) {}

  /**
   * Lista todos os eventos externos do paciente
   */
  async getPatientEvents(patientId: string) {
    return this.prisma.externalEvent.findMany({
      where: {
        patientId,
        deletedAt: null,
      },
      orderBy: { date: 'asc' },
    });
  }

  /**
   * Busca um evento específico
   */
  async getEventById(id: string, patientId: string) {
    const event = await this.prisma.externalEvent.findUnique({
      where: { id },
    });

    if (!event || event.deletedAt) {
      throw new NotFoundException('Evento não encontrado');
    }

    if (event.patientId !== patientId) {
      throw new ForbiddenException('Acesso negado a este evento');
    }

    return event;
  }

  /**
   * Cria um novo evento externo
   */
  async createEvent(patientId: string, dto: CreateExternalEventDto) {
    return this.prisma.externalEvent.create({
      data: {
        patientId,
        title: dto.title,
        date: new Date(dto.date),
        time: dto.time,
        location: dto.location,
        notes: dto.notes,
      },
    });
  }

  /**
   * Atualiza um evento existente
   */
  async updateEvent(id: string, patientId: string, dto: UpdateExternalEventDto) {
    // Verifica se o evento existe e pertence ao paciente
    const event = await this.getEventById(id, patientId);

    return this.prisma.externalEvent.update({
      where: { id: event.id },
      data: {
        ...(dto.title && { title: dto.title }),
        ...(dto.date && { date: new Date(dto.date) }),
        ...(dto.time && { time: dto.time }),
        ...(dto.location !== undefined && { location: dto.location }),
        ...(dto.notes !== undefined && { notes: dto.notes }),
      },
    });
  }

  /**
   * Exclui um evento (soft delete)
   */
  async deleteEvent(id: string, patientId: string) {
    // Verifica se o evento existe e pertence ao paciente
    const event = await this.getEventById(id, patientId);

    return this.prisma.externalEvent.update({
      where: { id: event.id },
      data: { deletedAt: new Date() },
    });
  }
}
