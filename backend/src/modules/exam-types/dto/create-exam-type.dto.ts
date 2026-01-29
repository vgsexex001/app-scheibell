import { IsString, IsOptional, IsInt, IsBoolean, IsArray, Min } from 'class-validator';

export class CreateExamTypeDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsString()
  icon?: string;

  @IsOptional()
  @IsString()
  color?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  validityDays?: number;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  urgencyKeywords?: string[];

  @IsOptional()
  urgencyRules?: any;

  @IsOptional()
  @IsString()
  urgencyInstructions?: string;

  @IsOptional()
  referenceValues?: any;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;

  @IsOptional()
  @IsBoolean()
  requiresDoctorReview?: boolean;
}
