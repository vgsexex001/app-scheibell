import { Module } from '@nestjs/common';
import { ExternalEventsController } from './external-events.controller';
import { ExternalEventsService } from './external-events.service';

@Module({
  controllers: [ExternalEventsController],
  providers: [ExternalEventsService],
  exports: [ExternalEventsService],
})
export class ExternalEventsModule {}
