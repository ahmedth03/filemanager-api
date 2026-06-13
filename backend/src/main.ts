import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.setGlobalPrefix('api/v1');

  app.enableCors({
    origin: process.env.FRONTEND_URL || '*',
    credentials: true,
  });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  const config = new DocumentBuilder()
    .setTitle('HarfiDar API')
    .setDescription(
      'HarfiDar Platform — Find Craftsmen & Rent Properties in Algeria\n\n' +
      'Use this page to explore and test all available API endpoints.',
    )
    .setVersion('1.0')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document, {
    swaggerOptions: { persistAuthorization: true },
  });

  const port = parseInt(process.env.PORT, 10) || 3000;
  await app.listen(port);
  console.log(`\n✅ HarfiDar API is running on http://localhost:${port}/api/v1`);
  console.log(`📖 API Docs available at http://localhost:${port}/api/docs\n`);
}

bootstrap();
