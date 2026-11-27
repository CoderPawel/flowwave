import type { ZonedTimestamp } from '../time/zonedTimestamp.js';
import type { DataSourceId } from '../consent/dataSources.js';

/** Why a value is absent. Missing data is never replaced by a default. */
export type MissingReason =
  | 'not_recorded'
  | 'user_skipped'
  | 'no_consent'
  | 'source_unavailable'
  | 'not_yet_synced';

export const MISSING_REASONS: readonly MissingReason[] = [
  'not_recorded',
  'user_skipped',
  'no_consent',
  'source_unavailable',
  'not_yet_synced',
];

export interface PresentMeasurement<T> {
  readonly status: 'present';
  readonly value: T;
  readonly source: DataSourceId;
  readonly recordedAt: ZonedTimestamp;
}

export interface MissingMeasurement {
  readonly status: 'missing';
  readonly reason: MissingReason;
}

export type Measurement<T> = PresentMeasurement<T> | MissingMeasurement;

export function present<T>(
  value: T,
  source: DataSourceId,
  recordedAt: ZonedTimestamp,
): PresentMeasurement<T> {
  return { status: 'present', value, source, recordedAt };
}

export function missing(reason: MissingReason): MissingMeasurement {
  return { status: 'missing', reason };
}

export function isPresent<T>(measurement: Measurement<T>): measurement is PresentMeasurement<T> {
  return measurement.status === 'present';
}

export function isMissingReason(value: unknown): value is MissingReason {
  return typeof value === 'string' && (MISSING_REASONS as readonly string[]).includes(value);
}
