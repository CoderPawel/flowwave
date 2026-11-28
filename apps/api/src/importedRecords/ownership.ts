import { isUuid, ValidationError } from '@flowwave/core';
import type { PrismaClient } from '../../generated/prisma/client.js';
import type { HealthSourceKind } from '../../generated/prisma/enums.js';

export function requireUuid(field: string, value: string): string {
  if (!isUuid(value)) {
    throw new ValidationError(field, 'Must be a UUID.');
  }
  return value;
}

/**
 * Rejects data sources that belong to another user or were disconnected. The
 * composite foreign keys enforce the same rule in the database; this check
 * gives callers a domain error instead of a constraint violation. Returns the
 * source kind, which decides the consent the import needs.
 */
export async function requireActiveDataSource(
  prisma: PrismaClient,
  userId: string,
  dataSourceId: string,
): Promise<HealthSourceKind> {
  const source = await prisma.healthDataSource.findFirst({
    where: { id: requireUuid('dataSourceId', dataSourceId), userId, deletedAtUtc: null },
    select: { kind: true },
  });
  if (!source) {
    throw new ValidationError('dataSourceId', 'Unknown or disconnected data source.');
  }
  return source.kind;
}

export async function requireActiveDevice(prisma: PrismaClient, userId: string, deviceId: string): Promise<void> {
  const device = await prisma.device.findFirst({
    where: { id: requireUuid('deviceId', deviceId), userId, deletedAtUtc: null },
    select: { id: true },
  });
  if (!device) {
    throw new ValidationError('deviceId', 'Unknown or signed-out device.');
  }
}
