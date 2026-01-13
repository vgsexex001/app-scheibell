import { IsString, IsNumber, IsBoolean, IsOptional, Min, Matches } from 'class-validator';

// ==================== RESPONSE DTOs ====================

export class HomeItemDto {
  id: string;
  type: 'MEDICATION' | 'VIDEO' | 'TASK' | 'APPOINTMENT';
  priority: number;
  status: 'PENDING' | 'IN_PROGRESS' | 'OVERDUE' | 'UPCOMING';
  title: string;
  subtitle?: string;
  scheduledTime?: string;
  action?: {
    type: 'TAKE' | 'WATCH' | 'COMPLETE' | 'VIEW';
    label: string;
  };
  metadata?: Record<string, any>;
}

export class HomeSummaryDto {
  medicationsPending: number;
  tasksPending: number;
  videosIncomplete: number;
}

export class NextAppointmentDto {
  id: string;
  date: string;
  type: string;
  title: string;
}

export class HomeResponseDto {
  greeting: string;
  dayPostOp: number;
  summary: HomeSummaryDto;
  items: HomeItemDto[];
  nextAppointment?: NextAppointmentDto;
}

// ==================== ACTION DTOs ====================

export class TakeMedicationDto {
  @IsString()
  contentId: string;

  @IsString()
  @Matches(/^\d{2}:\d{2}$/, { message: 'scheduledTime deve estar no formato HH:mm' })
  scheduledTime: string;
}

export class CompleteTaskDto {
  @IsString()
  taskId: string;

  @IsOptional()
  @IsString()
  notes?: string;
}

export class UpdateVideoProgressDto {
  @IsString()
  contentId: string;

  @IsNumber()
  @Min(0)
  watchedSeconds: number;

  @IsNumber()
  @Min(0)
  totalSeconds: number;

  @IsOptional()
  @IsBoolean()
  isCompleted?: boolean;
}

// ==================== CREATE TASK DTO ====================

export class CreateTaskDto {
  @IsString()
  title: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsString()
  priority?: string;

  @IsOptional()
  @IsString()
  scheduledDate?: string;

  @IsOptional()
  @IsString()
  @Matches(/^\d{2}:\d{2}$/, { message: 'scheduledTime deve estar no formato HH:mm' })
  scheduledTime?: string;

  @IsOptional()
  @IsBoolean()
  isRecurring?: boolean;

  @IsOptional()
  @IsString()
  recurrenceRule?: string;
}
