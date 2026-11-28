import { Module } from '@nestjs/common';
import { ConsentController } from './consentController.js';
import { ConsentService } from './consentService.js';

@Module({
  controllers: [ConsentController],
  providers: [ConsentService],
  exports: [ConsentService],
})
export class ConsentModule {}
