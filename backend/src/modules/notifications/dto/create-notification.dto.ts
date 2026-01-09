import { IsString, IsNotEmpty, IsEnum, IsOptional } from 'class-validator';

export enum NotificationType {
  NEW_APPOINTMENT = 'NEW_APPOINTMENT',
  APPOINTMENT_APPROVED = 'APPOINTMENT_APPROVED',
  APPOINTMENT_REJECTED = 'APPOINTMENT_REJECTED',
  ALERT_CREATED = 'ALERT_CREATED',
  REMINDER = 'REMINDER',
  OTHER = 'OTHER',
}

export class CreateNotificationDto {
  @IsString()
  @IsNotEmpty()
  userId: string;

  @IsEnum(NotificationType)
  type: NotificationType;

  @IsString()
  @IsNotEmpty()
  title: string;

  @IsString()
  @IsOptional()
  body?: string;
}
