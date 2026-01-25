import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { RequestIdInterceptor } from './common/interceptors/request-id.interceptor';
import * as express from 'express';
import * as path from 'path';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule);
  const configService = app.get(ConfigService);

  // Security headers
  app.use(helmet());

  // CORS configuration - NUNCA usar wildcard em producao
  const corsOrigins = configService.get<string>('CORS_ORIGINS');
  const allowedOrigins = corsOrigins
    ? corsOrigins.split(',').map(origin => origin.trim())
    : [
        'http://localhost:3000',
        'http://localhost:8080',
        'http://10.0.2.2:3000', // Android emulator
        'https://api-scheibell-gfcbeddudegvbkcw.brazilsouth-01.azurewebsites.net',
      ];

  app.enableCors({
    origin: (origin, callback) => {
      // Permitir requests sem origin (mobile apps, Postman, etc)
      if (!origin) {
        return callback(null, true);
      }

      if (allowedOrigins.includes(origin)) {
        return callback(null, true);
      }

      // Log de origens rejeitadas para debug
      logger.warn(`CORS rejected origin: ${origin}`);
      return callback(new Error('Not allowed by CORS'), false);
    },
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    credentials: true,
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-ID'],
  });

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // API prefix
  app.setGlobalPrefix('api');

  // Serve static files from uploads directory (for local development)
  app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

  // Global interceptors
  app.useGlobalInterceptors(new RequestIdInterceptor());

  // Swagger API Documentation
  const config = new DocumentBuilder()
    .setTitle('App Scheibell API')
    .setDescription('API para acompanhamento pós-operatório de pacientes')
    .setVersion('1.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: 'Enter JWT token',
      },
      'JWT-auth',
    )
    .addTag('auth', 'Autenticação e autorização')
    .addTag('appointments', 'Gerenciamento de consultas')
    .addTag('chat', 'Chat com IA e atendimento humano')
    .addTag('content', 'Conteúdo educativo')
    .addTag('medications', 'Controle de medicações')
    .addTag('patients', 'Gerenciamento de pacientes')
    .addTag('admin', 'Painel administrativo')
    .addTag('health', 'Health checks')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const port = configService.get<number>('PORT') || 3000;

  // Listen on all network interfaces (0.0.0.0) to allow external connections
  await app.listen(port, '0.0.0.0');

  logger.log(`Application running on: http://localhost:${port}/api`);
  logger.log(`Swagger docs: http://localhost:${port}/api/docs`);
  logger.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  logger.log(`Deploy version: 2026-01-25-v2`);
}

bootstrap();
