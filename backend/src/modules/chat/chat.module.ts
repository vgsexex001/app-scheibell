import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MulterModule } from '@nestjs/platform-express';
import * as multer from 'multer';
import { ChatController } from './chat.controller';
import { ChatService } from './chat.service';
import { StorageService } from './storage.service';
import { PrismaModule } from '../../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';
import { QueueModule } from '../queue/queue.module';

@Module({
  imports: [
    ConfigModule,
    PrismaModule,
    AuthModule,
    QueueModule,
    MulterModule.register({
      storage: multer.memoryStorage(), // Armazena em memória para ter acesso ao buffer
      limits: {
        fileSize: 25 * 1024 * 1024, // 25MB para áudios
      },
    }),
  ],
  controllers: [ChatController],
  providers: [ChatService, StorageService],
  exports: [ChatService, StorageService],
})
export class ChatModule {}
