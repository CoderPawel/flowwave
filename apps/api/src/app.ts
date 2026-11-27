import 'reflect-metadata';
import { type INestApplication, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { Logger } from 'nestjs-pino';
import { AppModule } from './appModule.js';
import type { AppConfig } from './config/appConfig.js';
import { setupSwagger } from './openapi/openApiDocument.js';

export const API_PREFIX = 'v1';

/** Applies the global HTTP setup shared by the server, tests, and the OpenAPI generator. */
export function configureApp(app: INestApplication, config: AppConfig): INestApplication {
  app.useLogger(app.get(Logger));
  app.setGlobalPrefix(API_PREFIX);
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  if (config.corsOrigins.length > 0) {
    app.enableCors({ origin: [...config.corsOrigins], credentials: true });
  }
  app.enableShutdownHooks();
  if (config.swaggerEnabled) {
    setupSwagger(app);
  }
  return app;
}

export async function createApp(config: AppConfig): Promise<INestApplication> {
  const app = await NestFactory.create(AppModule.forRoot(config), { bufferLogs: true });
  return configureApp(app, config);
}
