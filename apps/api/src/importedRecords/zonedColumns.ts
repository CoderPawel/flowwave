import { parseZonedTimestamp, ValidationError, type ZonedTimestamp } from '@flowwave/core';

export interface ZonedColumns {
  readonly atUtc: Date;
  readonly timeZone: string;
  readonly utcOffsetMinutes: number;
}

/**
 * Validates a zoned timestamp (IANA zone, offset matching the zone at that
 * instant) and returns the three values stored in the database.
 */
export function zonedColumns(field: string, timestamp: ZonedTimestamp): ZonedColumns {
  let parsed: ZonedTimestamp;
  try {
    parsed = parseZonedTimestamp(timestamp);
  } catch (error) {
    throw new ValidationError(field, error instanceof Error ? error.message : 'Invalid zoned timestamp.', { cause: error });
  }
  return { atUtc: new Date(parsed.utc), timeZone: parsed.timeZone, utcOffsetMinutes: parsed.utcOffsetMinutes };
}

export function requireNonBlank(field: string, value: string, maxLength = 200): string {
  if (value.trim().length === 0 || value.length > maxLength) {
    throw new ValidationError(field, `Must be 1–${maxLength} characters.`);
  }
  return value;
}

export function requireDate(field: string, value: Date): Date {
  if (!(value instanceof Date) || Number.isNaN(value.getTime())) {
    throw new ValidationError(field, 'Must be a valid date.');
  }
  return value;
}
