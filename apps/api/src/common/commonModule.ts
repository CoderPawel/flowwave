import { Global, Module } from '@nestjs/common';
import { AuditService } from '../audit/auditService.js';
import { RateLimiter } from '../rateLimit/rateLimiter.js';
import { CLOCK, systemClock } from './clock.js';

/** Services every feature module uses. Tests replace `CLOCK` to move time. */
@Global()
@Module({
  providers: [{ provide: CLOCK, useValue: systemClock }, RateLimiter, AuditService],
  exports: [CLOCK, RateLimiter, AuditService],
})
export class CommonModule {}
