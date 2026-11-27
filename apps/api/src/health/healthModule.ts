import { Module } from '@nestjs/common';
import { DatabaseHealth } from './databaseHealth.js';
import { HealthController } from './healthController.js';

@Module({
  controllers: [HealthController],
  providers: [DatabaseHealth],
})
export class HealthModule {}
