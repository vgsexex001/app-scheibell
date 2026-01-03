import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './modules/auth/auth.module';
import { ContentModule } from './modules/content/content.module';
import { HealthModule } from './modules/health/health.module';
import { AppointmentsModule } from './modules/appointments/appointments.module';
import { MedicationsModule } from './modules/medications/medications.module';
import { ChatModule } from './modules/chat/chat.module';
import { ExamsModule } from './modules/exams/exams.module';
import { TrainingModule } from './modules/training/training.module';

@Module({
  imports: [
    // Configuration
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
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
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
