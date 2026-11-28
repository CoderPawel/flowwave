import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { after, before, describe, it } from 'node:test';
import type { INestApplication } from '@nestjs/common';
import {
  AuthenticationError,
  ConsentRequiredError,
  RateLimitedError,
  ValidationError,
} from '@flowwave/core';
import { normalizeEmail } from '../src/auth/authService.js';
import { ARGON2ID_PARAMETERS, assertPasswordPolicy, PasswordHasher } from '../src/auth/passwordHasher.js';
import {
  ACCESS_TOKEN_PREFIX,
  bearerToken,
  generateToken,
  hashToken,
  isWellFormedToken,
  REFRESH_TOKEN_PREFIX,
} from '../src/auth/tokens.js';
import { CLOCK } from '../src/common/clock.js';
import { errorBody, errorStatus } from '../src/common/domainExceptionFilter.js';
import { PrismaService } from '../src/prisma/prismaService.js';
import { RateLimiter } from '../src/rateLimit/rateLimiter.js';
import { apiClient, FakeClock, TEST_PASSWORD, type TokenPair } from './support/apiClient.js';
import { startTestApp, TEST_CONFIG } from './support/testApp.js';

describe('tokens', () => {
  it('are prefixed, 256-bit, and recognized only with their own prefix', () => {
    const access = generateToken(ACCESS_TOKEN_PREFIX);
    assert.match(access, /^fwat_[A-Za-z0-9_-]{43}$/);
    assert.equal(isWellFormedToken(access, ACCESS_TOKEN_PREFIX), true);
    assert.equal(isWellFormedToken(access, REFRESH_TOKEN_PREFIX), false);
    assert.equal(isWellFormedToken(`${access}x`, ACCESS_TOKEN_PREFIX), false);
    assert.equal(isWellFormedToken(undefined, ACCESS_TOKEN_PREFIX), false);
    assert.notEqual(generateToken(ACCESS_TOKEN_PREFIX), access);
  });

  it('are stored as SHA-256 hex hashes', () => {
    assert.match(hashToken('fwat_x'), /^[0-9a-f]{64}$/);
    assert.equal(hashToken('fwat_x'), hashToken('fwat_x'));
  });

  it('are read from a Bearer authorization header only', () => {
    assert.equal(bearerToken('Bearer abc'), 'abc');
    assert.equal(bearerToken('bearer abc'), 'abc');
    assert.equal(bearerToken('Basic abc'), undefined);
    assert.equal(bearerToken('Bearer a b'), undefined);
    assert.equal(bearerToken(undefined), undefined);
  });
});

describe('passwords', () => {
  const hasher = new PasswordHasher();

  it('are hashed with Argon2id at the configured parameters', async () => {
    const hashed = await hasher.hash(TEST_PASSWORD);
    assert.match(hashed, /^\$argon2id\$v=19\$m=19456,t=2,p=1\$/);
    assert.equal(await hasher.verify(hashed, TEST_PASSWORD), true);
    assert.equal(await hasher.verify(hashed, 'wrong password!!'), false);
    assert.equal(await hasher.verify('not a hash', TEST_PASSWORD), false);
    assert.equal(hasher.needsRehash(hashed), false);
  });

  it('are rehashed when the parameters change', () => {
    assert.equal(hasher.needsRehash(`$argon2id$v=19$m=4096,t=3,p=1$c2FsdA$aGFzaA`), true);
    assert.equal(hasher.needsRehash('$2b$10$bcrypt'), true);
    assert.equal(ARGON2ID_PARAMETERS.memoryCost, 19_456);
  });

  it('must be 12 to 128 characters, counted as characters', () => {
    assert.throws(() => assertPasswordPolicy('short'), ValidationError);
    assert.throws(() => assertPasswordPolicy('x'.repeat(129)), ValidationError);
    assert.doesNotThrow(() => assertPasswordPolicy('ąćęłńóśźż123'));
  });

  it('emails are trimmed, lower-cased, and checked', () => {
    assert.equal(normalizeEmail('  Tester@Example.ORG '), 'tester@example.org');
    assert.throws(() => normalizeEmail('no-at-sign'), ValidationError);
    assert.throws(() => normalizeEmail(`${'a'.repeat(250)}@x.io`), ValidationError);
  });
});

describe('rate limiter', () => {
  it('rejects requests over the limit until the window ends', () => {
    const clock = new FakeClock();
    const limiter = new RateLimiter(clock, { ...TEST_CONFIG, rateLimitEnabled: true });
    for (let i = 0; i < 5; i += 1) limiter.consume('auth.register', 'ip:1');
    assert.throws(() => limiter.consume('auth.register', 'ip:1'), (error: unknown) => {
      assert.ok(error instanceof RateLimitedError);
      assert.ok(error.retryAfterSeconds > 0 && error.retryAfterSeconds <= 3600);
      return true;
    });
    limiter.consume('auth.register', 'ip:2');
    clock.advanceSeconds(3600);
    assert.doesNotThrow(() => limiter.consume('auth.register', 'ip:1'));
  });

  it('counts only recorded failures for failure limits', () => {
    const limiter = new RateLimiter(new FakeClock(), { ...TEST_CONFIG, rateLimitEnabled: true });
    for (let i = 0; i < 4; i += 1) limiter.record('auth.loginFailuresPerEmail', 'email:x');
    limiter.assertAvailable('auth.loginFailuresPerEmail', 'email:x');
    limiter.record('auth.loginFailuresPerEmail', 'email:x');
    assert.throws(() => limiter.assertAvailable('auth.loginFailuresPerEmail', 'email:x'), RateLimitedError);
    limiter.reset('auth.loginFailuresPerEmail', 'email:x');
    limiter.assertAvailable('auth.loginFailuresPerEmail', 'email:x');
  });

  it('does nothing when disabled', () => {
    const limiter = new RateLimiter(new FakeClock(), TEST_CONFIG);
    for (let i = 0; i < 20; i += 1) limiter.consume('auth.register', 'ip:1');
  });
});

describe('domain error responses', () => {
  it('map to HTTP status codes with stable bodies', () => {
    assert.equal(errorStatus(new AuthenticationError('token_expired')), 401);
    assert.equal(errorStatus(new AuthenticationError('reauthentication_failed')), 403);
    assert.equal(errorStatus(new ConsentRequiredError('device_usage')), 403);
    assert.equal(errorStatus(new RateLimitedError(10)), 429);
    assert.deepEqual(errorBody(new AuthenticationError('refresh_token_reused')), {
      statusCode: 401,
      error: 'authentication_failed',
      message: new AuthenticationError('refresh_token_reused').message,
      reason: 'refresh_token_reused',
    });
    assert.deepEqual(errorBody(new ConsentRequiredError('health_connect', 'steps')).scope, 'steps');
  });
});

const databaseUrl = process.env['FLOWWAVE_TEST_DATABASE_URL'];

describe('authentication API against PostgreSQL', { skip: !databaseUrl }, () => {
  const config = { ...TEST_CONFIG, databaseUrl: databaseUrl! };
  const clock = new FakeClock();
  let app: INestApplication;
  let api: ReturnType<typeof apiClient>;
  let prisma: PrismaService;
  const userIds: string[] = [];

  async function registerUser() {
    const registered = await api.register();
    userIds.push(registered.tokens.userId);
    return registered;
  }

  before(async () => {
    const started = await startTestApp(config, [{ provide: CLOCK, useValue: clock }]);
    app = started.app;
    api = apiClient(started.baseUrl);
    prisma = new PrismaService(config);
  });

  after(async () => {
    await prisma.user.deleteMany({ where: { id: { in: userIds } } });
    await prisma.$disconnect();
    await app.close();
  });

  it('registers, stores only hashes, and signs in with the normalized email', async () => {
    const email = `${randomUUID()}@Example.org`;
    const { tokens } = await api.register(email);
    userIds.push(tokens.userId);
    assert.match(tokens.accessToken, /^fwat_/);
    assert.match(tokens.refreshToken, /^fwrt_/);

    const credential = await prisma.userCredential.findUniqueOrThrow({ where: { userId: tokens.userId } });
    assert.equal(credential.email, email.toLowerCase());
    assert.match(credential.passwordHash, /^\$argon2id\$/);
    const stored = await prisma.authToken.findFirstOrThrow({ where: { sessionId: tokens.sessionId } });
    assert.equal(stored.accessTokenHash, hashToken(tokens.accessToken));
    assert.equal(stored.refreshTokenHash, hashToken(tokens.refreshToken));
    assert.equal(JSON.stringify(stored).includes(tokens.accessToken), false);

    const login = await api.login(email.toUpperCase());
    assert.equal(login.status, 200);
    assert.notEqual(login.body.sessionId, tokens.sessionId, 'each sign-in is its own session');

    const actions = await prisma.auditEvent.findMany({ where: { userId: tokens.userId }, select: { action: true, metadata: true } });
    assert.ok(actions.some((event) => event.action === 'account_created'));
    assert.ok(actions.some((event) => event.action === 'login_succeeded'));
    assert.equal(JSON.stringify(actions).includes('@'), false, 'audit metadata holds no email');
  });

  it('rejects duplicate emails and weak passwords', async () => {
    const { email } = await registerUser();
    const duplicate = await api.call('POST', '/v1/auth/register', {
      body: { email, password: TEST_PASSWORD, homeTimeZone: 'Europe/Budapest', device: { platform: 'android' } },
    });
    assert.equal(duplicate.status, 409);
    const weak = await api.call('POST', '/v1/auth/register', {
      body: { email: `${randomUUID()}@example.org`, password: 'short', homeTimeZone: 'Europe/Budapest', device: { platform: 'android' } },
    });
    assert.equal(weak.status, 400);
    const badZone = await api.call('POST', '/v1/auth/register', {
      body: { email: `${randomUUID()}@example.org`, password: TEST_PASSWORD, homeTimeZone: 'Mars/Base', device: { platform: 'android' } },
    });
    assert.equal(badZone.status, 400);
  });

  it('answers a wrong password and an unknown email the same way', async () => {
    const { email, tokens } = await registerUser();
    const wrong = await api.login(email, 'wrong password 123');
    const unknown = await api.login(`${randomUUID()}@example.org`);
    assert.equal(wrong.status, 401);
    assert.deepEqual(wrong.body, unknown.body);
    assert.equal(wrong.headers.get('www-authenticate'), 'Bearer');
    const failures = await prisma.auditEvent.count({ where: { userId: tokens.userId, action: 'login_failed' } });
    assert.equal(failures, 1);
  });

  it('requires an access token everywhere except public routes', async () => {
    assert.equal((await api.call('GET', '/v1/health')).status, 200);
    const missing = await api.call('GET', '/v1/auth/sessions');
    assert.equal(missing.status, 401);
    assert.equal(missing.body['reason'], 'invalid_token');
    assert.equal((await api.call('GET', '/v1/auth/sessions', { token: generateToken(ACCESS_TOKEN_PREFIX) })).status, 401);
    const { tokens } = await registerUser();
    assert.equal((await api.call('GET', '/v1/auth/sessions', { token: tokens.refreshToken })).status, 401, 'a refresh token is not an access token');
    assert.equal((await api.call('GET', '/v1/auth/sessions', { token: tokens.accessToken })).status, 200);
  });

  it('expires access tokens after their lifetime', async () => {
    const { tokens } = await registerUser();
    clock.advanceSeconds(TEST_CONFIG.auth.accessTokenTtlSeconds + 1);
    const expired = await api.call('GET', '/v1/auth/sessions', { token: tokens.accessToken });
    assert.equal(expired.status, 401);
    assert.equal(expired.body['reason'], 'token_expired');
    const refreshed = await api.call<TokenPair>('POST', '/v1/auth/refresh', { body: { refreshToken: tokens.refreshToken } });
    assert.equal(refreshed.status, 200);
    assert.equal((await api.call('GET', '/v1/auth/sessions', { token: refreshed.body.accessToken })).status, 200);
  });

  it('rotates refresh tokens: each works once and the new pair replaces the old', async () => {
    const { tokens } = await registerUser();
    const first = await api.call<TokenPair>('POST', '/v1/auth/refresh', { body: { refreshToken: tokens.refreshToken } });
    assert.equal(first.status, 200);
    assert.notEqual(first.body.refreshToken, tokens.refreshToken);
    assert.equal(first.body.sessionId, tokens.sessionId);
    const second = await api.call<TokenPair>('POST', '/v1/auth/refresh', { body: { refreshToken: first.body.refreshToken } });
    assert.equal(second.status, 200);
    const rows = await prisma.authToken.findMany({ where: { sessionId: tokens.sessionId }, orderBy: { createdAtUtc: 'asc' } });
    assert.equal(rows.length, 3);
    assert.equal(rows.filter((row) => row.rotatedAtUtc === null).length, 1);
  });

  it('revokes the whole session when a used refresh token comes back', async () => {
    const { tokens } = await registerUser();
    const rotated = await api.call<TokenPair>('POST', '/v1/auth/refresh', { body: { refreshToken: tokens.refreshToken } });
    assert.equal(rotated.status, 200);

    const reused = await api.call('POST', '/v1/auth/refresh', { body: { refreshToken: tokens.refreshToken } });
    assert.equal(reused.status, 401);
    assert.equal(reused.body['reason'], 'refresh_token_reused');

    const afterReuse = await api.call('POST', '/v1/auth/refresh', { body: { refreshToken: rotated.body.refreshToken } });
    assert.equal(afterReuse.status, 401, 'the legitimate newer token is revoked too');
    assert.equal(afterReuse.body['reason'], 'session_revoked');
    assert.equal((await api.call('GET', '/v1/auth/sessions', { token: rotated.body.accessToken })).status, 401);

    const session = await prisma.authSession.findUniqueOrThrow({ where: { id: tokens.sessionId } });
    assert.equal(session.revokedReason, 'refresh_token_reused');
    assert.equal(await prisma.auditEvent.count({ where: { userId: tokens.userId, action: 'refresh_token_reused' } }), 1);
  });

  it('lets exactly one of two concurrent refreshes with the same token win', async () => {
    const { tokens } = await registerUser();
    const results = await Promise.all([
      api.call('POST', '/v1/auth/refresh', { body: { refreshToken: tokens.refreshToken } }),
      api.call('POST', '/v1/auth/refresh', { body: { refreshToken: tokens.refreshToken } }),
    ]);
    assert.ok(results.some((result) => result.status === 401));
    const session = await prisma.authSession.findUniqueOrThrow({ where: { id: tokens.sessionId } });
    assert.equal(session.revokedReason, 'refresh_token_reused', 'a racing replay is treated as reuse');
  });

  it('logs out one device and keeps the others signed in', async () => {
    const { email, tokens: phone } = await registerUser();
    const pc = (await api.login(email, TEST_PASSWORD, 'windows')).body;
    const sessions = await api.call<Array<{ id: string; current: boolean }>>('GET', '/v1/auth/sessions', { token: phone.accessToken });
    assert.equal(sessions.body.length, 2);
    assert.equal(sessions.body.find((session) => session.current)?.id, phone.sessionId);

    assert.equal((await api.call('POST', '/v1/auth/logout', { token: phone.accessToken })).status, 204);
    assert.equal((await api.call('GET', '/v1/auth/sessions', { token: phone.accessToken })).status, 401);
    assert.equal((await api.call('POST', '/v1/auth/refresh', { body: { refreshToken: phone.refreshToken } })).status, 401);
    assert.equal((await api.call('GET', '/v1/auth/sessions', { token: pc.accessToken })).status, 200);
    const device = await prisma.device.findUniqueOrThrow({ where: { id: phone.deviceId } });
    assert.ok(device.deletedAtUtc, 'the signed-out device can no longer upload');
  });

  it('logs out every device at once', async () => {
    const { email, tokens: phone } = await registerUser();
    const pc = (await api.login(email, TEST_PASSWORD, 'windows')).body;
    const response = await api.call('POST', '/v1/auth/logout-all', { token: pc.accessToken });
    assert.equal(response.status, 200);
    assert.equal(response.body['sessionsRevoked'], 2);
    for (const tokens of [phone, pc]) {
      assert.equal((await api.call('GET', '/v1/auth/sessions', { token: tokens.accessToken })).status, 401);
    }
  });

  it('revokes another device of the same user but not of another user', async () => {
    const { email, tokens: phone } = await registerUser();
    const pc = (await api.login(email, TEST_PASSWORD, 'windows')).body;
    const { tokens: stranger } = await registerUser();

    const foreign = await api.call('POST', `/v1/auth/sessions/${pc.sessionId}/revoke`, { token: stranger.accessToken });
    assert.equal(foreign.status, 404, 'another user\'s session is indistinguishable from a missing one');
    assert.equal((await api.call('GET', '/v1/auth/sessions', { token: pc.accessToken })).status, 200);

    assert.equal((await api.call('POST', `/v1/auth/sessions/${pc.sessionId}/revoke`, { token: phone.accessToken })).status, 204);
    assert.equal((await api.call('GET', '/v1/auth/sessions', { token: pc.accessToken })).status, 401);
  });

  it('keeps each user\'s data isolated', async () => {
    const { tokens: alice } = await registerUser();
    const { tokens: bob } = await registerUser();
    const aliceSessions = await api.call<Array<{ id: string }>>('GET', '/v1/auth/sessions', { token: alice.accessToken });
    assert.deepEqual(aliceSessions.body.map((session) => session.id), [alice.sessionId]);
    const bobAccount = await api.call('GET', '/v1/account', { token: bob.accessToken });
    assert.equal(bobAccount.body['userId'], bob.userId);
    assert.equal((await api.call('GET', `/v1/account/exports/${randomUUID()}`, { token: bob.accessToken })).status, 404);
  });
});

describe('rate limits against PostgreSQL', { skip: !databaseUrl }, () => {
  const config = { ...TEST_CONFIG, databaseUrl: databaseUrl!, rateLimitEnabled: true };
  let app: INestApplication;
  let api: ReturnType<typeof apiClient>;
  let prisma: PrismaService;
  const userIds: string[] = [];

  before(async () => {
    const started = await startTestApp(config);
    app = started.app;
    api = apiClient(started.baseUrl);
    prisma = new PrismaService(config);
  });

  after(async () => {
    await prisma.user.deleteMany({ where: { id: { in: userIds } } });
    await prisma.$disconnect();
    await app.close();
  });

  it('locks an email after 5 failed sign-ins and answers 429 with Retry-After', async () => {
    const registered = await api.register();
    userIds.push(registered.tokens.userId);
    for (let i = 0; i < 5; i += 1) {
      assert.equal((await api.login(registered.email, 'wrong password 123')).status, 401);
    }
    const locked = await api.call('POST', '/v1/auth/login', {
      body: { email: registered.email, password: TEST_PASSWORD, device: { platform: 'android' } },
    });
    assert.equal(locked.status, 429, 'even the right password waits for the window');
    assert.ok(Number(locked.headers.get('retry-after')) > 0);
    assert.equal(locked.body['error'], 'rate_limited');
  });

  it('limits registrations per client address', async () => {
    const statuses: number[] = [];
    for (let i = 0; i < 6; i += 1) {
      const response = await api.call<TokenPair>('POST', '/v1/auth/register', {
        body: { email: `${randomUUID()}@example.org`, password: TEST_PASSWORD, homeTimeZone: 'UTC', device: { platform: 'web' } },
      });
      if (response.status === 201) userIds.push(response.body.userId);
      statuses.push(response.status);
    }
    assert.equal(statuses.at(-1), 429);
  });
});
