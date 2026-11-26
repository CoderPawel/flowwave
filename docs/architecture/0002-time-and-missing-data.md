# 0002. Zoned UTC timestamps and explicit missing data

- Status: Accepted
- Date: 2026-11-26

## Context

Energy and focus rhythms are interpreted in the user's local day, but users
travel and devices change time zones. Storing only local time loses ordering;
storing only UTC loses the local context. Separately, health inputs are often
unavailable (no consent, device offline, user skipped a check-in). Filling such
gaps with defaults or zeros would silently invent health data.

## Decision

- Every event time is a `ZonedTimestamp`: `utc` (ISO 8601, `Z` suffix,
  millisecond precision), `timeZone` (IANA name captured at the time of the
  event), and `utcOffsetMinutes` (offset in effect at that instant).
- Input strings without an explicit offset or `Z` are rejected as ambiguous.
- In PostgreSQL the same triple is stored as `<name>_at_utc timestamptz`,
  `<name>_time_zone text`, `<name>_utc_offset_minutes smallint`.
- Every measured input is a `Measurement<T>`: either
  `{ status: 'present', value, source, recordedAt }` or
  `{ status: 'missing', reason }`. In SQL each optional input has a value
  column and a `*_missing_reason` column with a check constraint that exactly
  one of them is set.
- Out-of-range values are rejected with a `ValidationError`; they are never
  clamped or replaced.

## Consequences

- Local-day grouping uses the stored zone, so a trip does not rewrite history.
- Scoring code must handle the `missing` branch explicitly; the type system
  enforces this.
- Slightly wider rows and payloads.
