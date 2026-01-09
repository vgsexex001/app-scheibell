import { IsString, IsOptional, IsInt, IsEnum, IsBoolean, Min } from 'class-validator';
import { ContentCategory } from '@prisma/client';

export class UpdateOverrideDto {
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

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}
