import {
  IsEmail,
  IsNotEmpty,
  IsString,
  IsOptional,
  IsDateString,
} from 'class-validator';

export class InvitePatientDto {
  @IsString({ message: 'Nome deve ser uma string' })
  @IsNotEmpty({ message: 'Nome é obrigatório' })
  name: string;

  @IsEmail({}, { message: 'Email inválido' })
  @IsNotEmpty({ message: 'Email é obrigatório' })
  email: string;

  @IsString()
  @IsOptional()
  phone?: string;

  @IsDateString({}, { message: 'Data da cirurgia deve ser uma data válida' })
  @IsOptional()
  surgeryDate?: string;

  @IsString()
  @IsOptional()
  surgeryType?: string;
}
