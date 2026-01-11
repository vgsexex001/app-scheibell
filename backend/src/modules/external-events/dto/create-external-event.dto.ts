import { IsString, IsOptional, IsDateString } from 'class-validator';

export class CreateExternalEventDto {
  @IsString()
  title: string;

  @IsDateString()
  date: string;

  @IsString()
  time: string; // "HH:mm"

  @IsOptional()
  @IsString()
  location?: string;

  @IsOptional()
  @IsString()
  notes?: string;
}
