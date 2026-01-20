import { IsString, IsOptional, IsNumber, Min, Max, IsIn, IsDateString } from 'class-validator';

export class UpdatePatientDto {
  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsString()
  @IsIn(['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'], {
    message: 'Tipo sanguíneo inválido',
  })
  bloodType?: string;

  @IsOptional()
  @IsNumber()
  @Min(20, { message: 'Peso mínimo é 20kg' })
  @Max(300, { message: 'Peso máximo é 300kg' })
  weightKg?: number;

  @IsOptional()
  @IsNumber()
  @Min(100, { message: 'Altura mínima é 100cm' })
  @Max(250, { message: 'Altura máxima é 250cm' })
  heightCm?: number;

  @IsOptional()
  @IsString()
  emergencyContact?: string;

  @IsOptional()
  @IsString()
  emergencyPhone?: string;

  // Campos de cirurgia
  @IsOptional()
  @IsString()
  surgeryType?: string;

  @IsOptional()
  @IsDateString({}, { message: 'Data da cirurgia deve ser uma data válida' })
  surgeryDate?: string;

  @IsOptional()
  @IsString()
  surgeon?: string;
}
