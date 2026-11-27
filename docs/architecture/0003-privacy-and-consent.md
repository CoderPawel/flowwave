# 0003. Data minimization and append-only consent

- Status: Accepted
- Date: 2026-11-26

## Context

Health and behavior data are sensitive. FlowWave must collect only what an
implemented feature needs, must never collect window titles, URLs, document
contents, messages, file names, or keystrokes, and must obtain explicit consent
for every external data source.

## Decision

- `docs/privacy/data-inventory.md` is the source of truth for every collected
  field, its purpose, and the feature that uses it. A field cannot be added to
  code or schema without a row there.
- Ingest payloads are validated against explicit schemas; additionally,
  `assertNoForbiddenFields` deep-scans payloads and rejects keys matching the
  never-collect list (normalized for case and separators). This is defense in
  depth, not a replacement for allowlisted schemas.
- External sources are declared in a registry (`EXTERNAL_DATA_SOURCES`) with
  the exact scopes they may provide. Manual check-ins entered by the user in
  FlowWave are not an external source.
- Consent is an append-only log of decisions (`granted` / `revoked`) per source,
  with scopes, policy version, and a zoned timestamp. The latest decision wins.
  Consent granted under an older policy version does not count as active.
- Code that reads an external source must call `assertConsent` first.

## Consequences

- Full consent history is auditable, and revocation is a new row, not a delete.
- Bumping the policy version requires users to re-consent.
- Declared sources in the registry are not integrations; no adapter exists yet,
  so no external data is collected.
