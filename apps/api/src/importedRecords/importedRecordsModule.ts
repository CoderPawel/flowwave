import { Module } from '@nestjs/common';
import { ConsentModule } from '../consent/consentModule.js';
import { DeviceUsageBucketRepository } from './deviceUsageBucketRepository.js';
import { HealthSampleRepository } from './healthSampleRepository.js';
import { SleepSessionRepository } from './sleepSessionRepository.js';

@Module({
  imports: [ConsentModule],
  providers: [HealthSampleRepository, SleepSessionRepository, DeviceUsageBucketRepository],
  exports: [HealthSampleRepository, SleepSessionRepository, DeviceUsageBucketRepository],
})
export class ImportedRecordsModule {}
