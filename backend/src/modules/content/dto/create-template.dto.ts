import { IsString, IsOptional, IsInt, IsEnum, Min } from 'class-validator';
import { ContentType, ContentCategory } from '@prisma/client';

export class CreateTemplateDto {
  @IsEnum(ContentType)
  type: ContentType;

  @IsEnum(ContentCategory)
  category: ContentCategory;

  @IsString()
  title: string;

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
}
