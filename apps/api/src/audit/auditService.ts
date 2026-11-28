import { Injectable } from '@nestjs/common';
import { assertNoForbiddenFields } from '@flowwave/core';
import type { AuditAction } from '../../generated/prisma/enums.js';
import type { Prisma } from '../../generated/prisma/client.js';
import { PrismaService } from '../prisma/prismaService.js';

type AuditWriter = Pick<Prisma.TransactionClient, 'auditEvent'>;

export interface AuditEntry {
  readonly userId: string | null;
  readonly action: AuditAction;
  readonly entity?: { readonly type: string; readonly id: string };
  /**
   * Non-health context only: no health values, tokens, passwords, emails, or
   * IP addresses (decision 0013). Limited to 2 KB by the database.
   */
  readonly metadata?: Readonly<Record<string, string | number | boolean | null>>;
}

@Injectable()
export class AuditService {
  constructor(private readonly prisma: PrismaService) {}

  /** Writes inside the caller's transaction when one is given, so the event and the change commit together. */
  async record(entry: AuditEntry, writer: AuditWriter = this.prisma): Promise<string> {
    const metadata = entry.metadata ?? {};
    assertNoForbiddenFields(metadata);
    const event = await writer.auditEvent.create({
      data: {
        userId: entry.userId,
        action: entry.action,
        entityType: entry.entity?.type ?? null,
        entityId: entry.entity?.id ?? null,
        metadata,
      },
      select: { id: true },
    });
    return event.id;
  }
}
