import { IsString, IsNotEmpty, IsOptional, Matches } from 'class-validator';

export class LogMedicationDto {
  @IsString()
  @IsNotEmpty()
  contentId: string; // ID da medicação no ClinicContent

  @IsString()
  @IsNotEmpty()
  @Matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, {
    message: 'scheduledTime deve estar no formato HH:mm',
  })
  scheduledTime: string; // Horário que deveria tomar

  @IsOptional()
  @IsString()
  takenAt?: string; // ISO date string, se não informado usa now()
}
