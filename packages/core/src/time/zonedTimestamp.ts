import { ValidationError } from '../errors.js';

/**
 * An instant stored in UTC together with the time zone it was observed in.
 * See docs/architecture/0002-time-and-missing-data.md.
 */
export interface ZonedTimestamp {
  /** ISO 8601 UTC instant with millisecond precision, e.g. `2026-11-26T16:00:00.000Z`. */
  readonly utc: string;
  /** IANA time zone name, e.g. `Europe/Budapest`. */
  readonly timeZone: string;
  /** Offset from UTC in minutes that was in effect in `timeZone` at `utc`. */
  readonly utcOffsetMinutes: number;
}

const EXPLICIT_OFFSET = /(?:Z|[+-]\d{2}:?\d{2})$/i;
const ISO_DATE_TIME = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}/;

const formatterCache = new Map<string, Intl.DateTimeFormat>();

function formatterFor(timeZone: string): Intl.DateTimeFormat {
  let formatter = formatterCache.get(timeZone);
  if (!formatter) {
    formatter = new Intl.DateTimeFormat('en-US', {
      timeZone,
      hourCycle: 'h23',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    });
    formatterCache.set(timeZone, formatter);
  }
  return formatter;
}

export function isValidTimeZone(timeZone: string): boolean {
  if (typeof timeZone !== 'string' || timeZone.length === 0) {
    return false;
  }
  try {
    formatterFor(timeZone);
    return true;
  } catch {
    return false;
  }
}

function localParts(instant: Date, timeZone: string): Record<string, number> {
  const parts: Record<string, number> = {};
  for (const part of formatterFor(timeZone).formatToParts(instant)) {
    if (part.type !== 'literal') {
      parts[part.type] = Number(part.value);
    }
  }
  return parts;
}

/** Offset in minutes of `timeZone` from UTC at `instant` (positive east of Greenwich). */
export function offsetMinutesAt(instant: Date, timeZone: string): number {
  if (!isValidTimeZone(timeZone)) {
    throw new ValidationError('timeZone', `"${timeZone}" is not a valid IANA time zone.`);
  }
  const p = localParts(instant, timeZone);
  const localAsUtc = Date.UTC(p.year!, p.month! - 1, p.day!, p.hour!, p.minute!, p.second!);
  const instantWholeSeconds = Math.floor(instant.getTime() / 1000) * 1000;
  return Math.round((localAsUtc - instantWholeSeconds) / 60_000);
}

function parseInstant(input: Date | string): Date {
  if (input instanceof Date) {
    if (Number.isNaN(input.getTime())) {
      throw new ValidationError('instant', 'Date is invalid.');
    }
    return new Date(input.getTime());
  }
  if (typeof input !== 'string' || !ISO_DATE_TIME.test(input)) {
    throw new ValidationError('instant', 'Expected an ISO 8601 date-time string.');
  }
  if (!EXPLICIT_OFFSET.test(input)) {
    throw new ValidationError(
      'instant',
      'Timestamp has no UTC offset or "Z" suffix; local times without an offset are ambiguous.',
    );
  }
  const parsed = new Date(input);
  if (Number.isNaN(parsed.getTime())) {
    throw new ValidationError('instant', `"${input}" is not a valid date-time.`);
  }
  return parsed;
}

export function createZonedTimestamp(instant: Date | string, timeZone: string): ZonedTimestamp {
  const date = parseInstant(instant);
  return {
    utc: date.toISOString(),
    timeZone,
    utcOffsetMinutes: offsetMinutesAt(date, timeZone),
  };
}

/** Validates a timestamp received from storage or the network. */
export function parseZonedTimestamp(value: unknown): ZonedTimestamp {
  if (typeof value !== 'object' || value === null) {
    throw new ValidationError('zonedTimestamp', 'Expected an object.');
  }
  const { utc, timeZone, utcOffsetMinutes } = value as Record<string, unknown>;
  if (typeof utc !== 'string' || !utc.endsWith('Z')) {
    throw new ValidationError('zonedTimestamp.utc', 'Expected an ISO 8601 UTC string ending in "Z".');
  }
  if (typeof timeZone !== 'string') {
    throw new ValidationError('zonedTimestamp.timeZone', 'Expected an IANA time zone name.');
  }
  const normalized = createZonedTimestamp(utc, timeZone);
  if (utcOffsetMinutes !== normalized.utcOffsetMinutes) {
    throw new ValidationError(
      'zonedTimestamp.utcOffsetMinutes',
      `Offset ${String(utcOffsetMinutes)} does not match ${normalized.utcOffsetMinutes} for ${timeZone} at ${normalized.utc}.`,
    );
  }
  return normalized;
}

/** Calendar date (`YYYY-MM-DD`) in the zone where the event happened. */
export function localDateOf(timestamp: ZonedTimestamp): string {
  const p = localParts(new Date(timestamp.utc), timestamp.timeZone);
  const pad = (n: number | undefined, width = 2): string => String(n).padStart(width, '0');
  return `${pad(p.year, 4)}-${pad(p.month)}-${pad(p.day)}`;
}

export function compareZonedTimestamps(a: ZonedTimestamp, b: ZonedTimestamp): number {
  return Date.parse(a.utc) - Date.parse(b.utc);
}
