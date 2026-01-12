import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { APP_GUARD, APP_FILTER } from '@nestjs/core';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { PrismaModule } from './prisma/prisma.module';
import { CommonModule } from './common/common.module';
import { HttpExceptionFilter } from './common/filters';
import { AuthModule } from './modules/auth/auth.module';
import { ContentModule } from './modules/content/content.module';
import { HealthModule } from './modules/health/health.module';
import { AppointmentsModule } from './modules/appointments/appointments.module';
import { MedicationsModule } from './modules/medications/medications.module';
import { ChatModule } from './modules/chat/chat.module';
import { ExamsModule } from './modules/exams/exams.module';
import { TrainingModule } from './modules/training/training.module';
import { AdminModule } from './modules/admin/admin.module';
import { PatientsModule } from './modules/patients/patients.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { ConnectionModule } from './modules/connection/connection.module';
import { WebsocketModule } from './websocket/websocket.module';
import { ExternalEventsModule } from './modules/external-events/external-events.module';
import { StorageModule } from './modules/storage/storage.module';
import { QueueModule } from './modules/queue/queue.module';

@Module({
  imports: [
    // Configuration
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),

    // Rate Limiting - Proteção contra DDoS
    ThrottlerModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ([
        {
          ttl: configService.get<number>('THROTTLE_TTL') || 60000, // 1 minuto em ms
          limit: configService.get<number>('THROTTLE_LIMIT') || 100, // 100 requests por minuto
        },
      ]),
    }),

    // Database
    PrismaModule,

    // Common (Logger, etc)
    CommonModule,

    // Feature modules
    AuthModule,
    ContentModule,
    HealthModule,
    AppointmentsModule,
    MedicationsModule,
    ChatModule,
    ExamsModule,
    TrainingModule,
    AdminModule,
    PatientsModule,
    NotificationsModule,
    ConnectionModule,
    WebsocketModule,
    ExternalEventsModule,
    StorageModule,
    QueueModule,
  ],
  controllers: [],
  providers: [
    // Aplicar rate limiting globalmente
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
    // Exception filter global para logging estruturado
    {
      provide: APP_FILTER,
      useClass: HttpExceptionFilter,
    },
  ],
})
export class AppModule {}
