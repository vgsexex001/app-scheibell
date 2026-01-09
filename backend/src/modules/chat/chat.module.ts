import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MulterModule } from '@nestjs/platform-express';
import { ChatController } from './chat.controller';
import { ChatService } from './chat.service';
import { StorageService } from './storage.service';
import { PrismaModule } from '../../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    ConfigModule,
    PrismaModule,
    AuthModule,
    MulterModule.register({
      limits: {
        fileSize: 10 * 1024 * 1024, // 10MB
      },
    }),
  ],
  controllers: [ChatController],
  providers: [ChatService, StorageService],
  exports: [ChatService, StorageService],
})
export class ChatModule {}
