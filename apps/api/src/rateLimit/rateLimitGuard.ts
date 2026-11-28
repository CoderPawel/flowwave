import { type CanActivate, type ExecutionContext, Injectable, SetMetadata } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { RateLimiter, type RateLimitPolicyName } from './rateLimiter.js';

const RATE_LIMIT_KEY = 'flowwave:rateLimit';

/** Per-IP limit for a route; routes without it use the `default` policy. `null` exempts the route (health probes). */
export const RateLimit = (policy: RateLimitPolicyName | null) => SetMetadata(RATE_LIMIT_KEY, policy);

interface RequestWithIp {
  readonly ip?: string;
  readonly socket?: { readonly remoteAddress?: string };
}

/** Runs before authentication, so floods are rejected without a token lookup. */
@Injectable()
export class RateLimitGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly limiter: RateLimiter,
  ) {}

  canActivate(context: ExecutionContext): boolean {
    if (context.getType() !== 'http') return true;
    const policy = this.reflector.getAllAndOverride<RateLimitPolicyName | null | undefined>(RATE_LIMIT_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (policy === null) return true;
    const request = context.switchToHttp().getRequest<RequestWithIp>();
    const ip = request.ip ?? request.socket?.remoteAddress ?? 'unknown';
    this.limiter.consume(policy ?? 'default', `ip:${ip}`);
    return true;
  }
}
