import { IsString, IsOptional, IsInt, IsArray, Min } from 'class-validator';

export class UpdateWeekDto {
  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsString()
  dayRange?: string;

  @IsOptional()
  @IsString()
  objective?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  maxHeartRate?: number;

  @IsOptional()
  @IsString()
  heartRateLabel?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  canDo?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  avoid?: string[];
}

export class CreateSessionDto {
  @IsString()
  weekId: string;

  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  duration?: number;

  @IsOptional()
  @IsString()
  intensity?: string;
}

export class UpdateSessionDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  duration?: number;

  @IsOptional()
  @IsString()
  intensity?: string;
}

export class ReorderSessionsDto {
  @IsArray()
  @IsString({ each: true })
  sessionIds: string[];
}

export class CreatePatientAdjustmentDto {
  @IsOptional()
  @IsString()
  patientId?: string; // Opcional, pois vem da URL

  @IsOptional()
  @IsString()
  baseSessionId?: string;

  @IsString()
  adjustmentType: 'ADD' | 'REMOVE' | 'MODIFY';

  @IsOptional()
  @IsString()
  weekId?: string;

  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsInt()
  duration?: number;

  @IsOptional()
  @IsString()
  intensity?: string;

  @IsOptional()
  @IsInt()
  validFromDay?: number;

  @IsOptional()
  @IsInt()
  validUntilDay?: number;

  @IsOptional()
  @IsString()
  reason?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  canDo?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  avoid?: string[];
}
