import { Module } from '@nestjs/common';
import { TrainingController } from './training.controller';
import { TrainingAdminController } from './training-admin.controller';
import { TrainingService } from './training.service';

@Module({
  controllers: [TrainingController, TrainingAdminController],
  providers: [TrainingService],
  exports: [TrainingService],
})
export class TrainingModule {}
