import { existsSync } from 'node:fs';
import { ConfigValidationError, loadConfig } from '../config/appConfig.js';
import { PrismaService } from '../prisma/prismaService.js';
import { SYNTHETIC_USER_ID, seedSyntheticData } from '../seed/syntheticData.js';

/** Loads clearly marked synthetic records into a development database. Safe to run repeatedly. */
async function main(): Promise<void> {
  if (existsSync('.env')) {
    process.loadEnvFile('.env');
  }
  const config = loadConfig(process.env);
  if (config.environment === 'production') {
    throw new Error('Refusing to seed synthetic data with NODE_ENV=production.');
  }
  const prisma = new PrismaService(config);
  try {
    const summary = await seedSyntheticData(prisma);
    console.log(`Synthetic data ready for user ${SYNTHETIC_USER_ID} (is_synthetic = true).`);
    console.log(JSON.stringify(summary));
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((error: unknown) => {
  console.error(error instanceof ConfigValidationError || error instanceof Error ? error.message : error);
  process.exit(1);
});
