import { IsString, IsOptional, IsInt, IsEnum, IsUUID, Min } from 'class-validator';
import { ContentType, ContentCategory, OverrideAction } from '@prisma/client';

export class CreateOverrideDto {
  @IsUUID()
  @IsOptional()
  templateId?: string;  // null para ADD

  @IsEnum(OverrideAction)
  action: OverrideAction;

  @IsEnum(ContentType)
  @IsOptional()
  type?: ContentType;  // Obrigatório para ADD

  @IsEnum(ContentCategory)
  @IsOptional()
  category?: ContentCategory;

  @IsString()
  @IsOptional()
  title?: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsInt()
  @IsOptional()
  @Min(0)
  validFromDay?: number;

  @IsInt()
  @IsOptional()
  @Min(0)
  validUntilDay?: number;

  @IsString()
  @IsOptional()
  reason?: string;
}
