import { IsString, IsInt, IsBoolean, IsOptional, Min, Max, Matches, IsDateString, IsEnum, IsUUID } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { AppointmentType } from '@prisma/client';

// ==================== CLINIC SCHEDULE DTOs ====================

export class CreateScheduleDto {
  @ApiProperty({ description: 'Dia da semana (0=Domingo, 6=Sábado)', minimum: 0, maximum: 6 })
  @IsInt()
  @Min(0)
  @Max(6)
  dayOfWeek: number;

  @ApiPropertyOptional({ description: 'Tipo de atendimento (ENUM legado)', enum: AppointmentType })
  @IsOptional()
  @IsEnum(AppointmentType)
  appointmentType?: AppointmentType;

  @ApiPropertyOptional({ description: 'ID do tipo de consulta personalizado' })
  @IsOptional()
  @IsUUID()
  appointmentTypeId?: string;

  @ApiProperty({ description: 'Horário de abertura (HH:mm)', example: '08:00' })
  @IsString()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, { message: 'openTime deve estar no formato HH:mm' })
  openTime: string;

  @ApiProperty({ description: 'Horário de fechamento (HH:mm)', example: '18:00' })
  @IsString()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, { message: 'closeTime deve estar no formato HH:mm' })
  closeTime: string;

  @ApiPropertyOptional({ description: 'Início do intervalo (HH:mm)', example: '12:00' })
  @IsOptional()
  @IsString()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, { message: 'breakStart deve estar no formato HH:mm' })
  breakStart?: string;

  @ApiPropertyOptional({ description: 'Fim do intervalo (HH:mm)', example: '14:00' })
  @IsOptional()
  @IsString()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, { message: 'breakEnd deve estar no formato HH:mm' })
  breakEnd?: string;

  @ApiPropertyOptional({ description: 'Duração da consulta em minutos', default: 30 })
  @IsOptional()
  @IsInt()
  @Min(5)
  @Max(240)
  slotDuration?: number;

  @ApiPropertyOptional({ description: 'Máximo de agendamentos por dia' })
  @IsOptional()
  @IsInt()
  @Min(1)
  maxAppointments?: number;

  @ApiPropertyOptional({ description: 'Se o dia está ativo', default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdateScheduleDto {
  @ApiPropertyOptional({ description: 'Horário de abertura (HH:mm)', example: '08:00' })
  @IsOptional()
  @IsString()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, { message: 'openTime deve estar no formato HH:mm' })
  openTime?: string;

  @ApiPropertyOptional({ description: 'Horário de fechamento (HH:mm)', example: '18:00' })
  @IsOptional()
  @IsString()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, { message: 'closeTime deve estar no formato HH:mm' })
  closeTime?: string;

  @ApiPropertyOptional({ description: 'Início do intervalo (HH:mm)', example: '12:00' })
  @IsOptional()
  @IsString()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, { message: 'breakStart deve estar no formato HH:mm' })
  breakStart?: string;

  @ApiPropertyOptional({ description: 'Fim do intervalo (HH:mm)', example: '14:00' })
  @IsOptional()
  @IsString()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, { message: 'breakEnd deve estar no formato HH:mm' })
  breakEnd?: string;

  @ApiPropertyOptional({ description: 'Duração da consulta em minutos' })
  @IsOptional()
  @IsInt()
  @Min(5)
  @Max(240)
  slotDuration?: number;

  @ApiPropertyOptional({ description: 'Máximo de agendamentos por dia' })
  @IsOptional()
  @IsInt()
  @Min(1)
  maxAppointments?: number;

  @ApiPropertyOptional({ description: 'Se o dia está ativo' })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

// ==================== BLOCKED DATE DTOs ====================

export class CreateBlockedDateDto {
  @ApiProperty({ description: 'Data a ser bloqueada (YYYY-MM-DD)', example: '2026-01-01' })
  @IsDateString()
  date: string;

  @ApiPropertyOptional({ description: 'Motivo do bloqueio', example: 'Feriado - Ano Novo' })
  @IsOptional()
  @IsString()
  reason?: string;

  @ApiPropertyOptional({ description: 'Tipo de atendimento (se específico)', enum: AppointmentType })
  @IsOptional()
  @IsEnum(AppointmentType)
  appointmentType?: AppointmentType;
}

export class UpdateBlockedDateDto {
  @ApiPropertyOptional({ description: 'Motivo do bloqueio', example: 'Feriado - Ano Novo' })
  @IsOptional()
  @IsString()
  reason?: string;
}

// ==================== SCHEDULE BY TYPE DTOs ====================

export class GetSchedulesByTypeDto {
  @ApiProperty({ description: 'Tipo de atendimento', enum: AppointmentType })
  @IsEnum(AppointmentType)
  appointmentType: AppointmentType;
}

export class ToggleScheduleByTypeDto {
  @ApiProperty({ description: 'Dia da semana (0=Domingo, 6=Sábado)', minimum: 0, maximum: 6 })
  @IsInt()
  @Min(0)
  @Max(6)
  dayOfWeek: number;

  @ApiProperty({ description: 'Tipo de atendimento', enum: AppointmentType })
  @IsEnum(AppointmentType)
  appointmentType: AppointmentType;
}

// ==================== APPOINTMENT TYPE CONFIG ====================

export class AppointmentTypeConfigDto {
  @ApiProperty({ description: 'Tipo de atendimento', enum: AppointmentType })
  @IsEnum(AppointmentType)
  appointmentType: AppointmentType;

  @ApiProperty({ description: 'Nome do tipo de atendimento' })
  @IsString()
  typeName: string;

  @ApiProperty({ description: 'Duração padrão em minutos' })
  @IsInt()
  @Min(5)
  defaultDurationMinutes: number;
}
