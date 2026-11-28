import { writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createApp } from '../app.js';
import type { AppConfig } from '../config/appConfig.js';
import { buildOpenApiDocument } from '../openapi/openApiDocument.js';

/** Never connects: Prisma connects lazily and no request is served. */
const GENERATOR_CONFIG: AppConfig = {
  environment: 'development',
  port: 0,
  databaseUrl: 'postgresql://openapi-generator@127.0.0.1:1/unused',
  logLevel: 'silent',
  swaggerEnabled: false,
  corsOrigins: [],
  auth: { accessTokenTtlSeconds: 900, refreshTokenTtlDays: 30, registrationEnabled: false },
  trustProxyHops: 0,
  rateLimitEnabled: true,
  backgroundJobsEnabled: false,
};

const here = dirname(fileURLToPath(import.meta.url));
const output = resolve(here, '../../../../../packages/contracts/openapi.json');

const app = await createApp(GENERATOR_CONFIG);
await app.init();
const document = buildOpenApiDocument(app);
writeFileSync(output, `${JSON.stringify(document, null, 2)}\n`);
await app.close();
console.log(`OpenAPI document written to ${output}`);
