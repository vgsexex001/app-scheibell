import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { RequestIdInterceptor } from './common/interceptors/request-id.interceptor';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const configService = app.get(ConfigService);

  // Security headers
  app.use(helmet());

  // CORS configuration
  const corsOrigins = configService.get<string>('CORS_ORIGINS');
  app.enableCors({
    origin: corsOrigins ? corsOrigins.split(',') : '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    credentials: true,
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
  const logger = new Logger('Bootstrap');

  // Listen on all network interfaces (0.0.0.0) to allow external connections
  await app.listen(port, '0.0.0.0');

  logger.log(`Application running on: http://localhost:${port}/api`);
  logger.log(`Swagger docs: http://localhost:${port}/api/docs`);
}

bootstrap();
