import { existsSync } from 'node:fs';
import { createApp } from './app.js';
import { ConfigValidationError, loadConfig } from './config/appConfig.js';

async function main(): Promise<void> {
  if (existsSync('.env')) {
    process.loadEnvFile('.env');
  }
  const config = loadConfig(process.env);
  const app = await createApp(config);
  await app.listen(config.port, '0.0.0.0');
}

main().catch((error: unknown) => {
  if (error instanceof ConfigValidationError) {
    console.error(error.message);
  } else {
    console.error('FlowWave API failed to start:', error instanceof Error ? error.message : error);
  }
  process.exit(1);
});
