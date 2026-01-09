import { IsString, IsOptional, IsInt, IsEnum, IsBoolean, Min } from 'class-validator';
import { ContentType, ContentCategory } from '@prisma/client';

export class UpdateTemplateDto {
  @IsEnum(ContentType)
  @IsOptional()
  type?: ContentType;

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

  @IsInt()
  @IsOptional()
  sortOrder?: number;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}
