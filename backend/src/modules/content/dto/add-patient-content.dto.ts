import { IsString, IsOptional, IsInt, IsEnum, Min } from 'class-validator';
import { ContentType, ContentCategory } from '@prisma/client';

export class AddPatientContentDto {
  @IsEnum(ContentType)
  contentType: ContentType;

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
  validUntilDay?: number;

  @IsString()
  @IsOptional()
  reason?: string;
}
