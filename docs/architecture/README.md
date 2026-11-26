# Architecture decision notes

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
