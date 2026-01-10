import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { PrismaModule } from './prisma/prisma.module';
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
  ],
  controllers: [],
  providers: [
    // Aplicar rate limiting globalmente
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
