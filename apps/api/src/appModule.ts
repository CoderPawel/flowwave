import { type DynamicModule, Module } from '@nestjs/common';
import { LoggerModule } from 'nestjs-pino';
import { APP_CONFIG, type AppConfig } from './config/appConfig.js';
import { HealthModule } from './health/healthModule.js';
import { ImportedRecordsModule } from './importedRecords/importedRecordsModule.js';
import { loggerOptions } from './logging/loggerOptions.js';
import { PrismaModule } from './prisma/prismaModule.js';

@Module({})
export class AppModule {
  /** The validated configuration is passed in, so tests and tools can build the app without process.env. */
  static forRoot(config: AppConfig): DynamicModule {
    return {
      module: AppModule,
      global: true,
      imports: [LoggerModule.forRoot(loggerOptions(config)), PrismaModule, HealthModule, ImportedRecordsModule],
      providers: [{ provide: APP_CONFIG, useValue: config }],
      exports: [APP_CONFIG],
    };
  }
}
