import { IsString, IsOptional, IsDateString } from 'class-validator';

export class UpdateProfileDto {
  // Dados pessoais
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsString()
  cpf?: string;

  @IsOptional()
  @IsDateString()
  birthDate?: string;

  @IsOptional()
  @IsDateString()
  surgeryDate?: string;

  @IsOptional()
  @IsString()
  surgeryType?: string;

  // Endereço
  @IsOptional()
  @IsString()
  cep?: string;

  @IsOptional()
  @IsString()
  street?: string;

  @IsOptional()
  @IsString()
  streetNumber?: string;

  @IsOptional()
  @IsString()
  city?: string;

  @IsOptional()
  @IsString()
  state?: string;

  // Saúde
  @IsOptional()
  @IsString()
  bloodType?: string;

  @IsOptional()
  @IsString()
  allergies?: string;

  @IsOptional()
  @IsString()
  medicalNotes?: string;

  // Contato de emergência
  @IsOptional()
  @IsString()
  emergencyContactName?: string;

  @IsOptional()
  @IsString()
  emergencyContactRelation?: string;

  @IsOptional()
  @IsString()
  emergencyContactPhone?: string;
}
