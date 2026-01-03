import { Module, forwardRef } from '@nestjs/common';
import { ContentController } from './content.controller';
import { ContentService } from './content.service';
import { PrismaModule } from '../../prisma/prisma.module';
import { TrainingModule } from '../training/training.module';

@Module({
  imports: [PrismaModule, forwardRef(() => TrainingModule)],
  controllers: [ContentController],
  providers: [ContentService],
  exports: [ContentService],
})
export class ContentModule {}
