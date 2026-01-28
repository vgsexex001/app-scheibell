import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module';
import { AppointmentTypesController } from './appointment-types.controller';
import { AppointmentTypesService } from './appointment-types.service';

@Module({
  imports: [PrismaModule],
  controllers: [AppointmentTypesController],
  providers: [AppointmentTypesService],
  exports: [AppointmentTypesService],
})
export class AppointmentTypesModule {}
