import { ValidationError } from '@flowwave/core';

interface DriverAdapterCause {
  readonly originalCode?: unknown;
  readonly originalMessage?: unknown;
}

function driverCause(error: unknown): DriverAdapterCause | undefined {
  if (typeof error !== 'object' || error === null) return undefined;
  const meta = (error as { meta?: { driverAdapterError?: { cause?: DriverAdapterCause } } }).meta;
  return meta?.driverAdapterError?.cause;
}

/**
 * Turns PostgreSQL CHECK and foreign-key violations into a ValidationError
 * naming only the constraint. The original error is deliberately not attached:
 * its detail lists the failing row's values, which can be health data.
 */
export function translateDatabaseError(error: unknown): unknown {
  const cause = driverCause(error);
  if (!cause || typeof cause.originalMessage !== 'string') {
    return error;
  }
  const constraint = /constraint "([A-Za-z0-9_]+)"/.exec(cause.originalMessage)?.[1] ?? 'unknown';
  if (cause.originalCode === '23514') {
    return new ValidationError('record', `Violates database rule "${constraint}".`);
  }
  if (cause.originalCode === '23503') {
    return new ValidationError('record', `References a row that does not exist for this user ("${constraint}").`);
  }
  return error;
}

/** True for a unique constraint violation, whether reported by Prisma (P2002) or by the driver adapter (23505). */
export function isUniqueViolation(error: unknown): boolean {
  if (typeof error !== 'object' || error === null) return false;
  return (error as { code?: unknown }).code === 'P2002' || driverCause(error)?.originalCode === '23505';
}

export async function withDatabaseErrors<T>(operation: () => Promise<T>): Promise<T> {
  try {
    return await operation();
  } catch (error) {
    throw translateDatabaseError(error);
  }
}
