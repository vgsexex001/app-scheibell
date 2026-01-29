import { IsString, IsOptional, IsUUID, IsNumber, Min, Max, IsIn } from 'class-validator';
import { Type } from 'class-transformer';

export class CreateNurseAnnotationDto {
  @IsUUID()
  patientId: string;

  @IsOptional()
  @IsUUID()
  examId?: string;

  @IsOptional()
  @IsUUID()
  documentId?: string;

  @IsOptional()
  @IsIn(['GENERAL', 'EXAM', 'DOCUMENT'])
  type?: string;

  @IsString()
  title: string;

  @IsString()
  annotation: string;

  @IsOptional()
  @IsIn(['LOW', 'NORMAL', 'HIGH', 'URGENT'])
  priority?: string;
}

export class UpdateNurseAnnotationDto {
  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsString()
  annotation?: string;

  @IsOptional()
  @IsIn(['LOW', 'NORMAL', 'HIGH', 'URGENT'])
  priority?: string;

  @IsOptional()
  @IsIn(['GENERAL', 'EXAM', 'DOCUMENT'])
  type?: string;
}

export class NurseAnnotationQueryDto {
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
  @IsIn(['PENDING', 'RESOLVED'])
  status?: string;

  @IsOptional()
  @IsUUID()
  patientId?: string;

  @IsOptional()
  @IsIn(['GENERAL', 'EXAM', 'DOCUMENT'])
  type?: string;

  @IsOptional()
  @IsIn(['LOW', 'NORMAL', 'HIGH', 'URGENT'])
  priority?: string;
}
