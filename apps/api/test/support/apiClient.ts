import { randomUUID } from 'node:crypto';
import type { Clock } from '../../src/common/clock.js';

export interface ApiResponse<T = Record<string, unknown>> {
  readonly status: number;
  readonly body: T;
  readonly headers: Headers;
}

export interface TokenPair {
  readonly accessToken: string;
  readonly refreshToken: string;
  readonly userId: string;
  readonly sessionId: string;
  readonly deviceId: string;
}

export const TEST_PASSWORD = 'correct horse battery staple';

/** A clock tests can move forward, injected in place of the system clock. */
export class FakeClock implements Clock {
  constructor(private current = new Date()) {}

  now(): Date {
    return new Date(this.current);
  }

  advanceSeconds(seconds: number): void {
    this.current = new Date(this.current.getTime() + seconds * 1000);
  }
}

export function apiClient(baseUrl: string) {
  async function call<T = Record<string, unknown>>(
    method: string,
    path: string,
    options: { body?: unknown; token?: string; headers?: Record<string, string> } = {},
  ): Promise<ApiResponse<T>> {
    const headers: Record<string, string> = { ...options.headers };
    if (options.body !== undefined) headers['content-type'] = 'application/json';
    if (options.token !== undefined) headers['authorization'] = `Bearer ${options.token}`;
    const response = await fetch(`${baseUrl}${path}`, {
      method,
      headers,
      ...(options.body === undefined ? {} : { body: JSON.stringify(options.body) }),
    });
    const text = await response.text();
    return { status: response.status, body: (text ? JSON.parse(text) : {}) as T, headers: response.headers };
  }

  async function register(email = `${randomUUID()}@example.org`, password = TEST_PASSWORD) {
    const response = await call<TokenPair>('POST', '/v1/auth/register', {
      body: { email, password, homeTimeZone: 'Europe/Budapest', device: { platform: 'android', appVersion: '0.1.0' } },
    });
    if (response.status !== 201) {
      throw new Error(`Registration failed with ${response.status}: ${JSON.stringify(response.body)}`);
    }
    return { email, password, tokens: response.body };
  }

  async function login(email: string, password = TEST_PASSWORD, platform = 'android') {
    return call<TokenPair>('POST', '/v1/auth/login', { body: { email, password, device: { platform } } });
  }

  return { call, register, login };
}
