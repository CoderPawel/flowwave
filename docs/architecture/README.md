# Architecture

## Overview documents

- [System overview](system-overview.md): components, vocabulary, quality attributes
- [Data flow](data-flow.md): what is collected, where it is stored, how it syncs
- [Security boundaries](security-boundaries.md): trust zones, controls, threats

## Decision notes

Write a short note here **before** changing architecture (new package, new
dependency, storage model change, sync protocol change, new external data
source). Number notes sequentially and never rewrite an accepted note; supersede
it with a new one instead.

| # | Title | Status |
| --- | --- | --- |
| [0001](0001-monorepo-and-shared-core.md) | Monorepo with a dependency-free shared core | Accepted |
| [0002](0002-time-and-missing-data.md) | Zoned UTC timestamps and explicit missing data | Accepted |
| [0003](0003-privacy-and-consent.md) | Data minimization and append-only consent | Accepted |
| [0004](0004-offline-first-idempotent-sync.md) | Offline-first storage with idempotent sync operations | Accepted |
| [0005](0005-android-first-native-kotlin.md) | Android first, with a native Kotlin app | Superseded by 0009 |
| [0006](0006-health-connect-wearable-gateway.md) | Health Connect as the only wearable gateway | Accepted |
| [0007](0007-android-offline-first-storage.md) | Android offline-first storage and background work | Partly superseded by 0009 |
| [0008](0008-nestjs-sync-api.md) | NestJS for the sync API | Accepted; database access superseded by 0010 |
| [0009](0009-flutter-mobile-app.md) | Flutter mobile app | Accepted |
| [0010](0010-prisma-schema-and-data-access.md) | Prisma for the schema and data access | Accepted |

## Template

```markdown
# NNNN. Title

- Status: Proposed | Accepted | Superseded by NNNN
- Date: YYYY-MM-DD

## Context
What problem or constraint forces a decision?

## Decision
What we will do.

## Consequences
What becomes easier, harder, or riskier. New dependencies and why they are required.
```
