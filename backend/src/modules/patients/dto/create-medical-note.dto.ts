import { IsString, IsNotEmpty, IsOptional } from 'class-validator';

export class CreateMedicalNoteDto {
  @IsString()
  @IsNotEmpty({ message: 'Conteúdo da nota é obrigatório' })
  content: string;

  @IsOptional()
  @IsString()
  author?: string;
}
