import { IsString, Length, Matches, IsOptional, IsNumber, Min, Max, IsEnum } from 'class-validator';
import { Type } from 'class-transformer';
import { ConnectionStatus } from '@prisma/client';

export class ConnectPatientDto {
  @IsString()
  @Length(6, 6, { message: 'Código de conexão deve ter exatamente 6 caracteres' })
  @Matches(/^[A-Z0-9]+$/, { message: 'Código de conexão deve conter apenas letras maiúsculas e números' })
  connectionCode: string;
}

export class ConnectionListQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  @Max(100)
  limit?: number = 20;

  @IsOptional()
  @IsEnum(ConnectionStatus)
  status?: ConnectionStatus;

  @IsOptional()
  @IsString()
  patientId?: string;
}

export class ConnectionResponseDto {
  id: string;
  connectionCode: string;
  status: ConnectionStatus;
  patientId: string;
  patientName?: string;
  clinicId: string;
  codeGeneratedAt: Date;
  codeExpiresAt: Date;
  connectedAt?: Date;
  revokedAt?: Date;
  generatedByName?: string;
  createdAt: Date;
}

export class ConnectionListResponseDto {
  items: ConnectionResponseDto[];
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export class ConnectionStatsDto {
  totalConnections: number;
  pendingConnections: number;
  activeConnections: number;
  expiredConnections: number;
  revokedConnections: number;
}
