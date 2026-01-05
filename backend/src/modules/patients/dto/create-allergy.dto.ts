import { IsString, IsNotEmpty, IsOptional, IsIn } from 'class-validator';

export class CreateAllergyDto {
  @IsString()
  @IsNotEmpty({ message: 'Nome da alergia é obrigatório' })
  name: string;

  @IsOptional()
  @IsString()
  @IsIn(['MILD', 'MODERATE', 'SEVERE'], {
    message: 'Gravidade deve ser MILD, MODERATE ou SEVERE',
  })
  severity?: string;

  @IsOptional()
  @IsString()
  notes?: string;
}
