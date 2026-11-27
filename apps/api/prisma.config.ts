import { existsSync } from 'node:fs';
import { defineConfig } from 'prisma/config';

if (existsSync('.env')) {
  process.loadEnvFile('.env');
}

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
    seed: 'node --enable-source-maps dist/src/scripts/seed.js',
  },
  datasource: {
    url: process.env['DATABASE_URL'] ?? '',
  },
});
