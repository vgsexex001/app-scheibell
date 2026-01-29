import { Module } from '@nestjs/common';
import { NurseAnnotationsController } from './nurse-annotations.controller';
import { NurseAnnotationsService } from './nurse-annotations.service';

@Module({
  controllers: [NurseAnnotationsController],
  providers: [NurseAnnotationsService],
  exports: [NurseAnnotationsService],
})
export class NurseAnnotationsModule {}
