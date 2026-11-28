import type { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { configureApp } from '../../src/app.js';
import { AppModule } from '../../src/appModule.js';
import type { AppConfig } from '../../src/config/appConfig.js';

export interface ProviderOverride {
  readonly provide: unknown;
  readonly useValue: unknown;
}

export const TEST_CONFIG: AppConfig = {
  environment: 'test',
  port: 0,
  databaseUrl: 'postgresql://flowwave:unused@127.0.0.1:1/flowwave_unused',
  logLevel: 'silent',
  swaggerEnabled: true,
  corsOrigins: [],
  auth: { accessTokenTtlSeconds: 900, refreshTokenTtlDays: 30, registrationEnabled: true },
  trustProxyHops: 0,
  rateLimitEnabled: false,
  backgroundJobsEnabled: false,
};

/** Builds the app with selected providers replaced and starts it on a random local port. */
export async function startTestApp(
  config: AppConfig = TEST_CONFIG,
  overrides: readonly ProviderOverride[] = [],
): Promise<{ app: INestApplication; baseUrl: string }> {
  let builder = Test.createTestingModule({ imports: [AppModule.forRoot(config)] });
  for (const override of overrides) {
    builder = builder.overrideProvider(override.provide).useValue(override.useValue);
  }
  const moduleRef = await builder.compile();
  const app = configureApp(moduleRef.createNestApplication({ bufferLogs: true }), config);
  await app.listen(0, '127.0.0.1');
  return { app, baseUrl: await app.getUrl() };
}
