import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  ValidationError,
  compareZonedTimestamps,
  createZonedTimestamp,
  isValidTimeZone,
  localDateOf,
  offsetMinutesAt,
  parseZonedTimestamp,
} from '../src/index.js';

describe('createZonedTimestamp', () => {
  it('stores the instant in UTC and keeps the original zone and offset', () => {
    const ts = createZonedTimestamp('2026-11-26T17:01:00+01:00', 'Europe/Budapest');
    assert.deepEqual(ts, {
      utc: '2026-11-26T16:01:00.000Z',
      timeZone: 'Europe/Budapest',
      utcOffsetMinutes: 60,
    });
  });

  it('captures daylight saving offsets for the specific instant', () => {
    assert.equal(createZonedTimestamp('2026-07-01T12:00:00Z', 'Europe/Budapest').utcOffsetMinutes, 120);
    assert.equal(createZonedTimestamp('2026-07-01T12:00:00Z', 'America/New_York').utcOffsetMinutes, -240);
    assert.equal(createZonedTimestamp('2026-07-01T12:00:00Z', 'Asia/Kolkata').utcOffsetMinutes, 330);
  });

  it('accepts Date instances', () => {
    const ts = createZonedTimestamp(new Date(Date.UTC(2026, 0, 1, 0, 0, 0)), 'UTC');
    assert.equal(ts.utc, '2026-01-01T00:00:00.000Z');
    assert.equal(ts.utcOffsetMinutes, 0);
  });

  it('rejects local times without an offset as ambiguous', () => {
    assert.throws(
      () => createZonedTimestamp('2026-11-26T17:01:00', 'Europe/Budapest'),
      (error: unknown) => error instanceof ValidationError && /ambiguous/.test(error.message),
    );
  });

  it('rejects invalid dates and time zones', () => {
    assert.throws(() => createZonedTimestamp('not a date', 'UTC'), ValidationError);
    assert.throws(() => createZonedTimestamp('2026-13-45T00:00:00Z', 'UTC'), ValidationError);
    assert.throws(() => createZonedTimestamp(new Date(Number.NaN), 'UTC'), ValidationError);
    assert.throws(() => createZonedTimestamp('2026-01-01T00:00:00Z', 'Mars/Olympus'), ValidationError);
  });
});

describe('time zone helpers', () => {
  it('validates IANA names', () => {
    assert.equal(isValidTimeZone('Europe/Warsaw'), true);
    assert.equal(isValidTimeZone(''), false);
    assert.equal(isValidTimeZone('Nowhere/Land'), false);
  });

  it('computes offsets on both sides of a DST transition', () => {
    // Europe/Budapest switches from UTC+1 to UTC+2 at 2026-03-29T01:00:00Z.
    assert.equal(offsetMinutesAt(new Date('2026-03-29T00:59:59Z'), 'Europe/Budapest'), 60);
    assert.equal(offsetMinutesAt(new Date('2026-03-29T01:00:00Z'), 'Europe/Budapest'), 120);
  });

  it('derives the local calendar date in the original zone', () => {
    const lateEvening = createZonedTimestamp('2026-11-26T23:30:00Z', 'Europe/Budapest');
    assert.equal(localDateOf(lateEvening), '2026-11-27');
    const sameInstantInNewYork = createZonedTimestamp('2026-11-26T23:30:00Z', 'America/New_York');
    assert.equal(localDateOf(sameInstantInNewYork), '2026-11-26');
  });

  it('orders timestamps by instant regardless of zone', () => {
    const a = createZonedTimestamp('2026-11-26T10:00:00+01:00', 'Europe/Budapest');
    const b = createZonedTimestamp('2026-11-26T05:00:00-05:00', 'America/New_York');
    assert.ok(compareZonedTimestamps(a, b) < 0);
  });
});

describe('parseZonedTimestamp', () => {
  it('round-trips a stored timestamp', () => {
    const ts = createZonedTimestamp('2026-11-26T16:01:00Z', 'Europe/Budapest');
    assert.deepEqual(parseZonedTimestamp(JSON.parse(JSON.stringify(ts))), ts);
  });

  it('rejects offsets that do not match the zone', () => {
    assert.throws(
      () => parseZonedTimestamp({ utc: '2026-11-26T16:01:00.000Z', timeZone: 'Europe/Budapest', utcOffsetMinutes: 120 }),
      ValidationError,
    );
  });

  it('rejects non-UTC strings and malformed values', () => {
    assert.throws(
      () => parseZonedTimestamp({ utc: '2026-11-26T17:01:00+01:00', timeZone: 'Europe/Budapest', utcOffsetMinutes: 60 }),
      ValidationError,
    );
    assert.throws(() => parseZonedTimestamp(null), ValidationError);
    assert.throws(() => parseZonedTimestamp({ utc: '2026-11-26T16:01:00.000Z' }), ValidationError);
  });
});
