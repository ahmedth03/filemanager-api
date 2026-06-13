import { NestFactory } from '@nestjs/core';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { NestExpressApplication } from '@nestjs/platform-express';
import * as compression from 'compression';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/http-exception.filter';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';
import { LoggingInterceptor } from './common/interceptors/logging.interceptor';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    logger: ['error', 'warn', 'log', 'debug'],
  });

  const configService = app.get(ConfigService);
  const port = configService.get<number>('port', 3000);
  const appUrl = configService.get<string>('appUrl', 'http://localhost:3000');
  const nodeEnv = configService.get<string>('nodeEnv', 'development');
  const frontendUrl = configService.get<string>('frontendUrl', 'http://localhost:8080');

  // Security
  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
  app.use(compression());

  // CORS
  app.enableCors({
    origin: nodeEnv === 'production'
      ? [frontendUrl, /\.harfidar\.dz$/]
      : [frontendUrl, 'http://localhost:3000', 'http://localhost:5000'],
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept-Language', 'x-refresh-token'],
    credentials: true,
  });

  // Versioning
  app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });

  // Global prefix
  app.setGlobalPrefix('api');

  // Global pipes
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  // Global filters & interceptors
  app.useGlobalFilters(new AllExceptionsFilter());
  app.useGlobalInterceptors(new LoggingInterceptor(), new TransformInterceptor());

  // Swagger
  if (nodeEnv !== 'production') {
    const config = new DocumentBuilder()
      .setTitle('HarfiDar API')
      .setDescription('حرفي دار - منصة البحث عن الحرفيين وكراء العقارات في الجزائر')
      .setVersion('1.0')
      .addBearerAuth(
        { type: 'http', scheme: 'bearer', bearerFormat: 'JWT', name: 'JWT', in: 'header' },
        'JWT-auth',
      )
      .addServer(appUrl)
      .addTag('auth', 'Authentication endpoints')
      .addTag('users', 'User management')
      .addTag('craftsmen', 'Craftsmen profiles and search')
      .addTag('listings', 'Real estate property listings')
      .addTag('chat', 'Messaging and chat rooms')
      .addTag('reviews', 'Reviews and ratings')
      .addTag('favorites', 'Saved favorites')
      .addTag('notifications', 'Push notifications')
      .addTag('specialties', 'Craftsman specialties')
      .addTag('upload', 'File uploads')
      .addTag('admin', 'Admin management')
      .build();

    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api/docs', app, document, {
      swaggerOptions: {
        persistAuthorization: true,
        tagsSorter: 'alpha',
        operationsSorter: 'alpha',
      },
    });
    console.log(`📚 Swagger docs: ${appUrl}/api/docs`);
  }

  await app.listen(port, '0.0.0.0');
  console.log(`🚀 HarfiDar API running on: ${appUrl}/api/v1`);
}

bootstrap();
