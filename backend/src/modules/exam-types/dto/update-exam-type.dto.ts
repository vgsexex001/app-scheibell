import { PartialType } from '@nestjs/mapped-types';
import { CreateExamTypeDto } from './create-exam-type.dto';
import { IsOptional, IsBoolean } from 'class-validator';

export class UpdateExamTypeDto extends PartialType(CreateExamTypeDto) {
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
