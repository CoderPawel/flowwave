import { Inject, Injectable } from '@nestjs/common';
import { NotFoundError } from '@flowwave/core';
import { AuditService } from '../audit/auditService.js';
import { AuthService, type AuthContext } from '../auth/authService.js';
import { CLOCK, type Clock } from '../common/clock.js';
import { PrismaService } from '../prisma/prismaService.js';
import { RateLimiter } from '../rateLimit/rateLimiter.js';

export interface AccountView {
  readonly userId: string;
  readonly email: string | null;
  readonly homeTimeZone: string;
  readonly sleepGoalMinutes: number | null;
  readonly createdAt: Date;
}

export interface DeletionReceipt {
  /** ID of the `account_deleted` audit event, which outlives the account. */
  readonly receiptId: string;
  readonly deletedAt: Date;
}

@Injectable()
export class AccountService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auth: AuthService,
    private readonly audit: AuditService,
    private readonly limiter: RateLimiter,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  async get(userId: string): Promise<AccountView> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        homeTimeZone: true,
        sleepGoalMinutes: true,
        createdAtUtc: true,
        credential: { select: { email: true } },
      },
    });
    if (!user) throw new NotFoundError('Account');
    return {
      userId: user.id,
      email: user.credential?.email ?? null,
      homeTimeZone: user.homeTimeZone,
      sleepGoalMinutes: user.sleepGoalMinutes,
      createdAt: user.createdAtUtc,
    };
  }

  /**
   * Deletes the account and every row that belongs to it in one transaction
   * (decision 0014). Audit events stay, detached from the account.
   */
  async delete(auth: AuthContext, password: string): Promise<DeletionReceipt> {
    this.limiter.consume('account.delete', `user:${auth.userId}`);
    await this.auth.verifyPassword(auth.userId, password);
    const deletedAt = this.clock.now();
    const receiptId = await this.prisma.$transaction(async (tx) => {
      const deleted = await tx.user.deleteMany({ where: { id: auth.userId } });
      if (deleted.count !== 1) throw new NotFoundError('Account');
      return this.audit.record({ userId: null, action: 'account_deleted' }, tx);
    });
    return { receiptId, deletedAt };
  }
}
