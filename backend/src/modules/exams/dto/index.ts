import { IsString, IsOptional, IsEnum, IsNumber, IsDateString, Min, Max, IsUUID } from 'class-validator';
import { Type, Transform } from 'class-transformer';
import { ExamStatus, PatientFileType, AiAnalysisStatus } from '@prisma/client';

// ========== CREATE EXAM DTO ==========
export class CreateExamDto {
  @IsUUID()
  patientId: string;

  @IsString()
  title: string;

  @IsString()
  type: string;

  @IsDateString()
  date: string;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsString()
  result?: string;

  @IsOptional()
  @IsEnum(ExamStatus)
  status?: ExamStatus;
}

// ========== UPDATE EXAM DTO ==========
export class UpdateExamDto {
  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsString()
  type?: string;

  @IsOptional()
  @IsDateString()
  date?: string;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsString()
  result?: string;

  @IsOptional()
  @IsEnum(ExamStatus)
  status?: ExamStatus;
}

// ========== ATTACH FILE DTO ==========
export class AttachFileDto {
  @IsString()
  fileUrl: string;

  @IsString()
  fileName: string;

  @IsNumber()
  fileSize: number;

  @IsString()
  mimeType: string;
}

// ========== EXAM LIST QUERY DTO ==========
export class ExamListQueryDto {
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
  @IsEnum(ExamStatus)
  status?: ExamStatus;

  @IsOptional()
  @IsUUID()
  patientId?: string;

  @IsOptional()
  @IsDateString()
  dateFrom?: string;

  @IsOptional()
  @IsDateString()
  dateTo?: string;

  @IsOptional()
  @IsString()
  search?: string;
}

// ========== EXAM RESPONSE DTO ==========
export class ExamResponseDto {
  id: string;
  patientId: string;
  title: string;
  type: string;
  date: Date;
  status: ExamStatus;
  fileUrl?: string;
  fileName?: string;
  fileSize?: number;
  mimeType?: string;
  notes?: string;
  result?: string;
  createdAt: Date;
  updatedAt: Date;
}

// ========== EXAM LIST RESPONSE DTO ==========
export class ExamListResponseDto {
  items: ExamResponseDto[];
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

// ========== EXAM STATS RESPONSE DTO ==========
export class ExamStatsResponseDto {
  total: number;
  pending: number;
  available: number;
  viewed: number;
}

// ========== CLINIC EXAM STATS DTO ==========
export class ClinicExamStatsDto {
  totalExams: number;
  pendingExams: number;
  availableExams: number;
  viewedExams: number;
  totalPatients: number;
  examsThisMonth: number;
  examsLastMonth: number;
}

// ========== PATIENT UPLOAD FILE DTO ==========
export class PatientUploadFileDto {
  @IsString()
  title: string;

  @IsEnum(PatientFileType)
  fileType: PatientFileType;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsDateString()
  date?: string;

  @IsOptional()
  @IsString()
  type?: string; // Tipo do exame: HEMOGRAMA, ULTRASSOM, etc
}

// ========== PATIENT FILES QUERY DTO ==========
export class PatientFilesQueryDto {
  @IsOptional()
  @IsEnum(PatientFileType)
  fileType?: PatientFileType;

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
}

// ========== EXAM WITH AI RESPONSE DTO ==========
export class ExamWithAiResponseDto {
  id: string;
  patientId: string;
  title: string;
  type: string;
  date: Date;
  status: ExamStatus;
  fileUrl?: string;
  fileName?: string;
  fileSize?: number;
  mimeType?: string;
  notes?: string;
  result?: string;
  fileType: PatientFileType;
  aiStatus: AiAnalysisStatus;
  aiSummary?: string;
  createdByRole?: string;
  createdById?: string;
  createdAt: Date;
  updatedAt: Date;
}
