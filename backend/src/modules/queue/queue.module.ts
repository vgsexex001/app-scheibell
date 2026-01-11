import { Module } from '@nestjs/common';
import { QueueService } from './queue.service';
import { JobsController } from './jobs.controller';
import { ChatAiProcessor } from './processors/chat-ai.processor';
import { ImageAnalyzeProcessor } from './processors/image-analyze.processor';

@Module({
  controllers: [JobsController],
  providers: [
    QueueService,
    ChatAiProcessor,
    ImageAnalyzeProcessor,
  ],
  exports: [QueueService],
})
export class QueueModule {}
