import { Inject, Injectable } from '@nestjs/common';
import { RateLimitedError } from '@flowwave/core';
import { CLOCK, type Clock } from '../common/clock.js';
import { APP_CONFIG, type AppConfig } from '../config/appConfig.js';

export interface RateLimitPolicy {
  readonly limit: number;
  readonly windowSeconds: number;
}

/** Limits from decision 0013. Route policies are keyed by client IP; account policies by user. */
export const RATE_LIMIT_POLICIES = {
  default: { limit: 120, windowSeconds: 60 },
  'auth.register': { limit: 5, windowSeconds: 3600 },
  'auth.login': { limit: 10, windowSeconds: 900 },
  'auth.loginFailuresPerEmail': { limit: 5, windowSeconds: 900 },
  'auth.refresh': { limit: 30, windowSeconds: 60 },
  'account.export': { limit: 3, windowSeconds: 86_400 },
  'account.delete': { limit: 5, windowSeconds: 3600 },
} as const satisfies Record<string, RateLimitPolicy>;

export type RateLimitPolicyName = keyof typeof RATE_LIMIT_POLICIES;

interface Window {
  count: number;
  resetAtMs: number;
}

const PRUNE_THRESHOLD = 10_000;

/**
 * Fixed-window counters in memory. Correct for the single API instance of the
 * MVP; several instances need a shared store (decision 0013).
 */
@Injectable()
export class RateLimiter {
  private readonly windows = new Map<string, Window>();

  constructor(
    @Inject(CLOCK) private readonly clock: Clock,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
  ) {}

  /** Counts one request and throws `RateLimitedError` once the limit is exceeded. */
  consume(name: RateLimitPolicyName, subject: string): void {
    if (!this.config.rateLimitEnabled) return;
    const window = this.hit(name, subject);
    if (window.count > RATE_LIMIT_POLICIES[name].limit) {
      throw new RateLimitedError(this.retryAfterSeconds(window));
    }
  }

  /** Throws when the limit is already reached, without counting. Pair with `record` for failure-only limits. */
  assertAvailable(name: RateLimitPolicyName, subject: string): void {
    if (!this.config.rateLimitEnabled) return;
    const window = this.current(name, subject);
    if (window && window.count >= RATE_LIMIT_POLICIES[name].limit) {
      throw new RateLimitedError(this.retryAfterSeconds(window));
    }
  }

  record(name: RateLimitPolicyName, subject: string): void {
    if (!this.config.rateLimitEnabled) return;
    this.hit(name, subject);
  }

  reset(name: RateLimitPolicyName, subject: string): void {
    this.windows.delete(`${name}:${subject}`);
  }

  private current(name: RateLimitPolicyName, subject: string): Window | undefined {
    const window = this.windows.get(`${name}:${subject}`);
    return window && window.resetAtMs > this.clock.now().getTime() ? window : undefined;
  }

  private hit(name: RateLimitPolicyName, subject: string): Window {
    const nowMs = this.clock.now().getTime();
    if (this.windows.size >= PRUNE_THRESHOLD) this.prune(nowMs);
    const key = `${name}:${subject}`;
    const existing = this.current(name, subject);
    if (existing) {
      existing.count += 1;
      return existing;
    }
    const window = { count: 1, resetAtMs: nowMs + RATE_LIMIT_POLICIES[name].windowSeconds * 1000 };
    this.windows.set(key, window);
    return window;
  }

  private retryAfterSeconds(window: Window): number {
    return Math.max(1, Math.ceil((window.resetAtMs - this.clock.now().getTime()) / 1000));
  }

  private prune(nowMs: number): void {
    for (const [key, window] of this.windows) {
      if (window.resetAtMs <= nowMs) this.windows.delete(key);
    }
  }
}
