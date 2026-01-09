import { IsString, Length, Matches } from 'class-validator';

export class ConnectPatientDto {
  @IsString()
  @Length(6, 6, { message: 'Código de conexão deve ter exatamente 6 caracteres' })
  @Matches(/^[A-Z0-9]+$/, { message: 'Código de conexão deve conter apenas letras maiúsculas e números' })
  connectionCode: string;
}
