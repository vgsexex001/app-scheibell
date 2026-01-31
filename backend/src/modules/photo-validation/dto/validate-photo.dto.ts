import { IsEnum, IsNotEmpty } from 'class-validator';

export enum PhotoType {
  FRONTAL = 'frontal',
  PERFIL_DIREITO = 'perfil_direito',
  PERFIL_ESQUERDO = 'perfil_esquerdo',
}

export class ValidatePhotoDto {
  @IsNotEmpty({ message: 'Tipo da foto é obrigatório' })
  @IsEnum(PhotoType, { message: 'Tipo de foto deve ser: frontal, perfil_direito ou perfil_esquerdo' })
  photoType: PhotoType;
}
