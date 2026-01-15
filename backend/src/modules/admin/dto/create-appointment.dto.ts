import {
  IsString,
  IsNotEmpty,
  IsDateString,
  IsEnum,
  IsOptional,
  Matches,
  IsInt,
  Min,
  Max,
} from 'class-validator';
import { AppointmentType, AppointmentStatus } from '@prisma/client';

/**
 * DTO para criação de agendamento pelo admin
 * POST /api/admin/appointments
 */
export class CreateAppointmentDto {
  @IsString()
  @IsNotEmpty()
  patientId: string;

  @IsString()
  @IsNotEmpty()
  title: string;

  @IsDateString()
  @IsNotEmpty()
  date: string;

  @IsString()
  @IsNotEmpty()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, {
    message: 'time must be in HH:mm format',
  })
  time: string;

  @IsEnum(AppointmentType)
  @IsNotEmpty()
  type: AppointmentType;

  @IsEnum(AppointmentStatus)
  @IsOptional()
  status?: AppointmentStatus;

  @IsString()
  @IsOptional()
  location?: string;

  @IsString()
  @IsOptional()
  notes?: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsInt()
  @IsOptional()
  @Min(15)
  @Max(480)
  durationMinutes?: number;
}
