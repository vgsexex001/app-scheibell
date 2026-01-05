import { IsOptional, IsString } from 'class-validator';

export class RejectAppointmentDto {
  @IsOptional()
  @IsString()
  reason?: string;
}

export class ApproveAppointmentDto {
  @IsOptional()
  @IsString()
  notes?: string;
}
