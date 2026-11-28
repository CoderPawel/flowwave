import { type DynamicModule, Module } from '@nestjs/common';
import { APP_FILTER, APP_GUARD } from '@nestjs/core';
import { LoggerModule } from 'nestjs-pino';
import { AccountModule } from './account/accountModule.js';
import { AuthGuard } from './auth/authGuard.js';
import { AuthModule } from './auth/authModule.js';
import { CommonModule } from './common/commonModule.js';
import { DomainExceptionFilter } from './common/domainExceptionFilter.js';
import { ConsentModule } from './consent/consentModule.js';
import { APP_CONFIG, type AppConfig } from './config/appConfig.js';
import { HealthModule } from './health/healthModule.js';
import { ImportedRecordsModule } from './importedRecords/importedRecordsModule.js';
import { loggerOptions } from './logging/loggerOptions.js';
import { PrismaModule } from './prisma/prismaModule.js';
import { RateLimitGuard } from './rateLimit/rateLimitGuard.js';

@Module({})
export class AppModule {
  /** The validated configuration is passed in, so tests and tools can build the app without process.env. */
  static forRoot(config: AppConfig): DynamicModule {
    return {
      module: AppModule,
      global: true,
      imports: [
        LoggerModule.forRoot(loggerOptions(config)),
        PrismaModule,
        CommonModule,
        HealthModule,
        AuthModule,
        ConsentModule,
        AccountModule,
        ImportedRecordsModule,
      ],
      providers: [
        { provide: APP_CONFIG, useValue: config },
        // Guards run in this order: floods are rejected before any token lookup.
        { provide: APP_GUARD, useClass: RateLimitGuard },
        { provide: APP_GUARD, useClass: AuthGuard },
        { provide: APP_FILTER, useClass: DomainExceptionFilter },
      ],
      exports: [APP_CONFIG],
    };
  }
}
