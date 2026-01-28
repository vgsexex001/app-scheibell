import { PartialType } from '@nestjs/mapped-types';
import { IsBoolean, IsOptional } from 'class-validator';
import { CreateAppointmentTypeDto } from './create-appointment-type.dto';

export class UpdateAppointmentTypeDto extends PartialType(CreateAppointmentTypeDto) {
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
