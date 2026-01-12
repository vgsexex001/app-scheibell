import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { QueueService } from './queue.service';
import { JobsController } from './jobs.controller';
import { ChatAiProcessor } from './processors/chat-ai.processor';
import { ImageAnalyzeProcessor } from './processors/image-analyze.processor';
import { PrismaModule } from '../../prisma/prisma.module';

@Module({
  imports: [
    ConfigModule,
    PrismaModule,
    // WebsocketModule is @Global, no need to import
  ],
  controllers: [JobsController],
  providers: [
    QueueService,
    ChatAiProcessor,
    ImageAnalyzeProcessor,
  ],
  exports: [QueueService],
})
export class QueueModule {}
