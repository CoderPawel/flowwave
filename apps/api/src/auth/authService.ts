import { createHash } from 'node:crypto';
import { ForbiddenException, Inject, Injectable } from '@nestjs/common';
import { AuthenticationError, ConflictError, NotFoundError, ValidationError, isValidTimeZone } from '@flowwave/core';
import type { Prisma } from '../../generated/prisma/client.js';
import type { DevicePlatform, SessionRevocationReason } from '../../generated/prisma/enums.js';
import { AuditService } from '../audit/auditService.js';
import { addDays, addSeconds, CLOCK, type Clock } from '../common/clock.js';
import { APP_CONFIG, type AppConfig } from '../config/appConfig.js';
import { isUniqueViolation } from '../prisma/databaseErrors.js';
import { PrismaService } from '../prisma/prismaService.js';
import { RateLimiter } from '../rateLimit/rateLimiter.js';
import { assertPasswordPolicy, PasswordHasher, PASSWORD_MAX_LENGTH } from './passwordHasher.js';
import {
  ACCESS_TOKEN_PREFIX,
  generateToken,
  hashToken,
  isWellFormedToken,
  REFRESH_TOKEN_PREFIX,
} from './tokens.js';

/** Who is calling. Taken from the access token, never from the request body. */
export interface AuthContext {
  readonly userId: string;
  readonly sessionId: string;
  readonly deviceId: string;
}

export interface DeviceInfo {
  readonly platform: DevicePlatform;
  readonly appVersion?: string;
}

export interface IssuedTokens {
  readonly accessToken: string;
  readonly accessTokenExpiresAt: Date;
  readonly refreshToken: string;
  readonly refreshTokenExpiresAt: Date;
  readonly userId: string;
  readonly sessionId: string;
  readonly deviceId: string;
}

export interface RegisterInput {
  readonly email: string;
  readonly password: string;
  readonly homeTimeZone: string;
  readonly device: DeviceInfo;
}

export interface LoginInput {
  readonly email: string;
  readonly password: string;
  readonly device: DeviceInfo;
}

export interface ActiveSession {
  readonly id: string;
  readonly deviceId: string;
  readonly platform: DevicePlatform;
  readonly appVersion: string | null;
  readonly createdAt: Date;
  readonly lastRefreshedAt: Date | null;
  readonly current: boolean;
}

const EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
const EMAIL_MAX_LENGTH = 254;

export function normalizeEmail(email: string): string {
  const normalized = email.trim().toLowerCase();
  if (normalized.length > EMAIL_MAX_LENGTH || !EMAIL.test(normalized)) {
    throw new ValidationError('email', 'Must be a valid email address.');
  }
  return normalized;
}

/** Rate-limit key for failed sign-ins; the email itself is not kept in memory. */
function emailKey(email: string): string {
  return `email:${createHash('sha256').update(email).digest('hex')}`;
}

type Tx = Prisma.TransactionClient;

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly passwords: PasswordHasher,
    private readonly audit: AuditService,
    private readonly limiter: RateLimiter,
    @Inject(CLOCK) private readonly clock: Clock,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
  ) {}

  async register(input: RegisterInput): Promise<IssuedTokens> {
    if (!this.config.auth.registrationEnabled) {
      throw new ForbiddenException({ statusCode: 403, error: 'registration_disabled', message: 'Registration is disabled.' });
    }
    const email = normalizeEmail(input.email);
    assertPasswordPolicy(input.password);
    if (!isValidTimeZone(input.homeTimeZone)) {
      throw new ValidationError('homeTimeZone', 'Must be an IANA time zone name.');
    }
    const passwordHash = await this.passwords.hash(input.password);
    const now = this.clock.now();

    try {
      return await this.prisma.$transaction(async (tx) => {
        const user = await tx.user.create({ data: { homeTimeZone: input.homeTimeZone }, select: { id: true } });
        await tx.userCredential.create({ data: { userId: user.id, email, passwordHash, passwordUpdatedAtUtc: now } });
        await this.audit.record({ userId: user.id, action: 'account_created' }, tx);
        return this.startSession(tx, user.id, input.device, now);
      });
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw new ConflictError('email', 'An account with this email already exists.');
      }
      throw error;
    }
  }

  async login(input: LoginInput): Promise<IssuedTokens> {
    if (input.password.length > PASSWORD_MAX_LENGTH * 4) {
      throw new AuthenticationError('invalid_credentials');
    }
    let email: string;
    try {
      email = normalizeEmail(input.email);
    } catch {
      await this.passwords.verifyAgainstDummy(input.password);
      throw new AuthenticationError('invalid_credentials');
    }
    const failureKey = emailKey(email);
    this.limiter.assertAvailable('auth.loginFailuresPerEmail', failureKey);

    const credential = await this.prisma.userCredential.findUnique({
      where: { email },
      select: { userId: true, passwordHash: true },
    });
    const valid = credential
      ? await this.passwords.verify(credential.passwordHash, input.password)
      : await this.passwords.verifyAgainstDummy(input.password);

    if (!credential || !valid) {
      this.limiter.record('auth.loginFailuresPerEmail', failureKey);
      if (credential) {
        await this.audit.record({ userId: credential.userId, action: 'login_failed' });
      }
      throw new AuthenticationError('invalid_credentials');
    }
    this.limiter.reset('auth.loginFailuresPerEmail', failureKey);

    const now = this.clock.now();
    const rehash = this.passwords.needsRehash(credential.passwordHash)
      ? await this.passwords.hash(input.password)
      : undefined;
    return this.prisma.$transaction(async (tx) => {
      if (rehash) {
        await tx.userCredential.update({ where: { userId: credential.userId }, data: { passwordHash: rehash } });
      }
      const tokens = await this.startSession(tx, credential.userId, input.device, now);
      await this.audit.record(
        { userId: credential.userId, action: 'login_succeeded', entity: { type: 'auth_session', id: tokens.sessionId } },
        tx,
      );
      return tokens;
    });
  }

  /** Resolves an access token to its user, session, and device, or throws `AuthenticationError`. */
  async authenticate(accessToken: string | undefined): Promise<AuthContext> {
    if (!isWellFormedToken(accessToken, ACCESS_TOKEN_PREFIX)) {
      throw new AuthenticationError('invalid_token');
    }
    const token = await this.prisma.authToken.findUnique({
      where: { accessTokenHash: hashToken(accessToken) },
      select: {
        accessExpiresAtUtc: true,
        session: { select: { id: true, userId: true, deviceId: true, revokedAtUtc: true } },
      },
    });
    if (!token) throw new AuthenticationError('invalid_token');
    if (token.session.revokedAtUtc) throw new AuthenticationError('session_revoked');
    if (token.accessExpiresAtUtc <= this.clock.now()) throw new AuthenticationError('token_expired');
    return { userId: token.session.userId, sessionId: token.session.id, deviceId: token.session.deviceId };
  }

  /**
   * Exchanges a refresh token for a new pair. Each refresh token works once;
   * presenting a used one revokes the whole session (decision 0013).
   */
  async refresh(refreshToken: string): Promise<IssuedTokens> {
    if (!isWellFormedToken(refreshToken, REFRESH_TOKEN_PREFIX)) {
      throw new AuthenticationError('invalid_token');
    }
    const now = this.clock.now();
    const token = await this.prisma.authToken.findUnique({
      where: { refreshTokenHash: hashToken(refreshToken) },
      select: {
        id: true,
        rotatedAtUtc: true,
        refreshExpiresAtUtc: true,
        session: { select: { id: true, userId: true, deviceId: true, revokedAtUtc: true } },
      },
    });
    if (!token) throw new AuthenticationError('invalid_token');
    const { session } = token;
    if (session.revokedAtUtc) throw new AuthenticationError('session_revoked');
    if (token.rotatedAtUtc) {
      await this.revokeForReuse(session.userId, session.id);
      throw new AuthenticationError('refresh_token_reused');
    }
    if (token.refreshExpiresAtUtc <= now) throw new AuthenticationError('token_expired');

    const issued = await this.prisma.$transaction(async (tx) => {
      const rotated = await tx.authToken.updateMany({
        where: { id: token.id, rotatedAtUtc: null },
        data: { rotatedAtUtc: now },
      });
      if (rotated.count !== 1) return undefined;
      const pair = await this.issueTokens(tx, session.userId, session.id, now);
      await tx.authSession.update({
        where: { id: session.id },
        data: { lastRefreshedAtUtc: now, expiresAtUtc: pair.refreshTokenExpiresAt },
      });
      await tx.device.update({ where: { id: session.deviceId }, data: { lastSeenAtUtc: now } });
      return { ...pair, userId: session.userId, sessionId: session.id, deviceId: session.deviceId };
    });
    if (!issued) {
      // A concurrent request rotated the same token first.
      await this.revokeForReuse(session.userId, session.id);
      throw new AuthenticationError('refresh_token_reused');
    }
    return issued;
  }

  async logout(auth: AuthContext): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      await this.revokeSessions(tx, auth.userId, [auth.sessionId], 'logout');
      await this.audit.record(
        { userId: auth.userId, action: 'logged_out', entity: { type: 'auth_session', id: auth.sessionId } },
        tx,
      );
    });
  }

  async logoutAll(auth: AuthContext): Promise<number> {
    return this.prisma.$transaction(async (tx) => {
      const active = await tx.authSession.findMany({
        where: { userId: auth.userId, revokedAtUtc: null },
        select: { id: true },
      });
      const revoked = await this.revokeSessions(tx, auth.userId, active.map((session) => session.id), 'logout_all');
      await this.audit.record({ userId: auth.userId, action: 'logged_out_all', metadata: { sessionsRevoked: revoked } }, tx);
      return revoked;
    });
  }

  /** Signs out another device of the same user. Sessions of other users are reported as not found. */
  async revokeSession(auth: AuthContext, sessionId: string): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      const session = await tx.authSession.findFirst({
        where: { id: sessionId, userId: auth.userId },
        select: { id: true, revokedAtUtc: true },
      });
      if (!session) throw new NotFoundError('Session');
      if (session.revokedAtUtc) return;
      await this.revokeSessions(tx, auth.userId, [session.id], 'revoked_by_user');
      await this.audit.record(
        { userId: auth.userId, action: 'session_revoked', entity: { type: 'auth_session', id: session.id } },
        tx,
      );
    });
  }

  async listSessions(auth: AuthContext): Promise<ActiveSession[]> {
    const sessions = await this.prisma.authSession.findMany({
      where: { userId: auth.userId, revokedAtUtc: null, expiresAtUtc: { gt: this.clock.now() } },
      select: {
        id: true,
        deviceId: true,
        createdAtUtc: true,
        lastRefreshedAtUtc: true,
        device: { select: { platform: true, appVersion: true } },
      },
      orderBy: { createdAtUtc: 'desc' },
    });
    return sessions.map((session) => ({
      id: session.id,
      deviceId: session.deviceId,
      platform: session.device.platform,
      appVersion: session.device.appVersion,
      createdAt: session.createdAtUtc,
      lastRefreshedAt: session.lastRefreshedAtUtc,
      current: session.id === auth.sessionId,
    }));
  }

  /** Re-checks the password for destructive actions such as account deletion. */
  async verifyPassword(userId: string, password: string): Promise<void> {
    const credential = await this.prisma.userCredential.findUnique({
      where: { userId },
      select: { passwordHash: true },
    });
    const valid = credential
      ? await this.passwords.verify(credential.passwordHash, password)
      : await this.passwords.verifyAgainstDummy(password);
    if (!valid) throw new AuthenticationError('reauthentication_failed');
  }

  private async startSession(tx: Tx, userId: string, device: DeviceInfo, now: Date): Promise<IssuedTokens> {
    const createdDevice = await tx.device.create({
      data: { userId, platform: device.platform, appVersion: device.appVersion ?? null, lastSeenAtUtc: now },
      select: { id: true },
    });
    const session = await tx.authSession.create({
      data: {
        userId,
        deviceId: createdDevice.id,
        expiresAtUtc: addDays(now, this.config.auth.refreshTokenTtlDays),
        createdAtUtc: now,
      },
      select: { id: true },
    });
    await this.audit.record(
      { userId, action: 'device_registered', entity: { type: 'device', id: createdDevice.id }, metadata: { platform: device.platform } },
      tx,
    );
    const pair = await this.issueTokens(tx, userId, session.id, now);
    return { ...pair, userId, sessionId: session.id, deviceId: createdDevice.id };
  }

  private async issueTokens(
    tx: Tx,
    userId: string,
    sessionId: string,
    now: Date,
  ): Promise<Omit<IssuedTokens, 'userId' | 'sessionId' | 'deviceId'>> {
    const accessToken = generateToken(ACCESS_TOKEN_PREFIX);
    const refreshToken = generateToken(REFRESH_TOKEN_PREFIX);
    const accessTokenExpiresAt = addSeconds(now, this.config.auth.accessTokenTtlSeconds);
    const refreshTokenExpiresAt = addDays(now, this.config.auth.refreshTokenTtlDays);
    await tx.authToken.create({
      data: {
        userId,
        sessionId,
        accessTokenHash: hashToken(accessToken),
        accessExpiresAtUtc: accessTokenExpiresAt,
        refreshTokenHash: hashToken(refreshToken),
        refreshExpiresAtUtc: refreshTokenExpiresAt,
        createdAtUtc: now,
      },
    });
    return { accessToken, accessTokenExpiresAt, refreshToken, refreshTokenExpiresAt };
  }

  private async revokeSessions(
    tx: Tx,
    userId: string,
    sessionIds: readonly string[],
    reason: SessionRevocationReason,
  ): Promise<number> {
    if (sessionIds.length === 0) return 0;
    const now = this.clock.now();
    const sessions = await tx.authSession.findMany({
      where: { id: { in: [...sessionIds] }, userId, revokedAtUtc: null },
      select: { id: true, deviceId: true },
    });
    if (sessions.length === 0) return 0;
    await tx.authSession.updateMany({
      where: { id: { in: sessions.map((session) => session.id) }, revokedAtUtc: null },
      data: { revokedAtUtc: now, revokedReason: reason },
    });
    await tx.device.updateMany({
      where: { id: { in: sessions.map((session) => session.deviceId) }, userId, deletedAtUtc: null },
      data: { deletedAtUtc: now },
    });
    return sessions.length;
  }

  private async revokeForReuse(userId: string, sessionId: string): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      const revoked = await this.revokeSessions(tx, userId, [sessionId], 'refresh_token_reused');
      if (revoked > 0) {
        await this.audit.record(
          { userId, action: 'refresh_token_reused', entity: { type: 'auth_session', id: sessionId } },
          tx,
        );
      }
    });
  }
}
