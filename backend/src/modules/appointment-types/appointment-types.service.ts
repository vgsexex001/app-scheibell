import {
  Injectable,
  NotFoundException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateAppointmentTypeDto, UpdateAppointmentTypeDto } from './dto';

@Injectable()
export class AppointmentTypesService {
  private readonly logger = new Logger(AppointmentTypesService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Lista todos os tipos de consulta ativos de uma clínica
   * Inclui flag hasCustomSchedule para indicar se o tipo tem horários personalizados
   */
  async findAll(clinicId: string, includeInactive = false) {
    this.logger.debug(`Listando tipos de consulta - clinicId: ${clinicId}, includeInactive: ${includeInactive}`);

    const where: any = { clinicId };
    if (!includeInactive) {
      where.isActive = true;
    }

    const types = await this.prisma.clinicAppointmentType.findMany({
      where,
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
    });

    // Para cada tipo, verificar se tem schedules personalizados
    const typesWithScheduleInfo = await Promise.all(
      types.map(async (type) => {
        const activeScheduleCount = await this.prisma.clinicSchedule.count({
          where: {
            clinicId,
            appointmentTypeId: type.id,
            isActive: true,
          },
        });

        return {
          ...type,
          hasCustomSchedule: activeScheduleCount > 0,
          customScheduleCount: activeScheduleCount,
        };
      }),
    );

    this.logger.debug(`Encontrados ${types.length} tipos de consulta`);
    return typesWithScheduleInfo;
  }

  /**
   * Busca um tipo de consulta por ID
   */
  async findOne(clinicId: string, id: string) {
    const type = await this.prisma.clinicAppointmentType.findFirst({
      where: { id, clinicId },
    });

    if (!type) {
      throw new NotFoundException('Tipo de consulta não encontrado');
    }

    return type;
  }

  /**
   * Cria um novo tipo de consulta
   */
  async create(clinicId: string, dto: CreateAppointmentTypeDto) {
    this.logger.debug(`Criando tipo de consulta - clinicId: ${clinicId}, name: ${dto.name}`);

    // Verifica se já existe um tipo com o mesmo nome na clínica
    const existing = await this.prisma.clinicAppointmentType.findUnique({
      where: {
        clinicId_name: {
          clinicId,
          name: dto.name,
        },
      },
    });

    if (existing) {
      throw new ConflictException('Já existe um tipo de consulta com esse nome');
    }

    const type = await this.prisma.clinicAppointmentType.create({
      data: {
        clinicId,
        name: dto.name,
        description: dto.description,
        icon: dto.icon,
        color: dto.color,
        defaultDuration: dto.defaultDuration ?? 30,
        sortOrder: dto.sortOrder ?? 0,
      },
    });

    this.logger.log(`Tipo de consulta criado - id: ${type.id}, name: ${type.name}`);
    return type;
  }

  /**
   * Atualiza um tipo de consulta
   */
  async update(clinicId: string, id: string, dto: UpdateAppointmentTypeDto) {
    this.logger.debug(`Atualizando tipo de consulta - id: ${id}, clinicId: ${clinicId}`);

    // Verifica se existe
    const existing = await this.prisma.clinicAppointmentType.findFirst({
      where: { id, clinicId },
    });

    if (!existing) {
      throw new NotFoundException('Tipo de consulta não encontrado');
    }

    // Se está mudando o nome, verifica conflito
    if (dto.name && dto.name !== existing.name) {
      const nameConflict = await this.prisma.clinicAppointmentType.findUnique({
        where: {
          clinicId_name: {
            clinicId,
            name: dto.name,
          },
        },
      });

      if (nameConflict) {
        throw new ConflictException('Já existe um tipo de consulta com esse nome');
      }
    }

    const updated = await this.prisma.clinicAppointmentType.update({
      where: { id },
      data: dto,
    });

    this.logger.log(`Tipo de consulta atualizado - id: ${id}`);
    return updated;
  }

  /**
   * Soft delete de um tipo de consulta (isActive = false)
   */
  async remove(clinicId: string, id: string) {
    this.logger.debug(`Desativando tipo de consulta - id: ${id}, clinicId: ${clinicId}`);

    const existing = await this.prisma.clinicAppointmentType.findFirst({
      where: { id, clinicId },
    });

    if (!existing) {
      throw new NotFoundException('Tipo de consulta não encontrado');
    }

    // Verifica se há agendamentos futuros usando este tipo
    const futureAppointments = await this.prisma.appointment.count({
      where: {
        appointmentTypeId: id,
        date: { gte: new Date() },
        status: { in: ['PENDING', 'CONFIRMED'] },
      },
    });

    if (futureAppointments > 0) {
      throw new ConflictException(
        `Não é possível desativar: existem ${futureAppointments} agendamento(s) futuro(s) usando este tipo`,
      );
    }

    const updated = await this.prisma.clinicAppointmentType.update({
      where: { id },
      data: { isActive: false },
    });

    this.logger.log(`Tipo de consulta desativado - id: ${id}`);
    return updated;
  }

  /**
   * Reativa um tipo de consulta
   */
  async reactivate(clinicId: string, id: string) {
    const existing = await this.prisma.clinicAppointmentType.findFirst({
      where: { id, clinicId },
    });

    if (!existing) {
      throw new NotFoundException('Tipo de consulta não encontrado');
    }

    return this.prisma.clinicAppointmentType.update({
      where: { id },
      data: { isActive: true },
    });
  }

  /**
   * Seed tipos padrão para uma clínica (usado na criação da clínica)
   */
  async seedDefaultTypes(clinicId: string) {
    const defaultTypes = [
      { name: 'Consulta', icon: 'stethoscope', color: '#4CAF50', defaultDuration: 30, sortOrder: 1 },
      { name: 'Retorno', icon: 'calendar-check', color: '#2196F3', defaultDuration: 20, sortOrder: 2 },
      { name: 'Avaliação', icon: 'clipboard-list', color: '#9C27B0', defaultDuration: 45, sortOrder: 3 },
      { name: 'Retirada de Tala', icon: 'bandage', color: '#FF9800', defaultDuration: 30, sortOrder: 4 },
      { name: 'Fisioterapia', icon: 'dumbbell', color: '#00BCD4', defaultDuration: 60, sortOrder: 5 },
      { name: 'Exame', icon: 'microscope', color: '#607D8B', defaultDuration: 30, sortOrder: 6 },
      { name: 'Cirurgia', icon: 'scalpel', color: '#F44336', defaultDuration: 120, sortOrder: 7 },
      { name: 'Outro', icon: 'ellipsis-h', color: '#9E9E9E', defaultDuration: 30, sortOrder: 99 },
    ];

    for (const type of defaultTypes) {
      await this.prisma.clinicAppointmentType.upsert({
        where: {
          clinicId_name: {
            clinicId,
            name: type.name,
          },
        },
        update: {},
        create: {
          clinicId,
          ...type,
        },
      });
    }

    this.logger.log(`Tipos padrão criados para clínica ${clinicId}`);
  }
}
