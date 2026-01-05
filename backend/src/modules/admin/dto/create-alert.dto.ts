import { IsEnum, IsOptional, IsString, IsUUID } from 'class-validator';
import { AlertType } from '@prisma/client';

export class CreateAlertDto {
  @IsOptional()
  @IsUUID()
  patientId?: string;

  @IsEnum(AlertType)
  type: AlertType;

  @IsString()
  title: string;

  @IsOptional()
  @IsString()
  description?: string;
}

export class AlertDto {
  id: string;
  patientId: string | null;
  patientName: string | null;
  type: string;
  title: string;
  description: string | null;
  status: string;
  isAutomatic: boolean;
  createdAt: string;
}

export class AlertsResponseDto {
  items: AlertDto[];
  page: number;
  limit: number;
  total: number;
}
