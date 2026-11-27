import { Module } from '@nestjs/common';
import { DeviceUsageBucketRepository } from './deviceUsageBucketRepository.js';
import { HealthSampleRepository } from './healthSampleRepository.js';
import { SleepSessionRepository } from './sleepSessionRepository.js';

@Module({
  providers: [HealthSampleRepository, SleepSessionRepository, DeviceUsageBucketRepository],
  exports: [HealthSampleRepository, SleepSessionRepository, DeviceUsageBucketRepository],
})
export class ImportedRecordsModule {}
