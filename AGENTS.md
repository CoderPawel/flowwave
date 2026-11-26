# FlowWave contributor and agent rules

FlowWave is a privacy-first personal energy and focus rhythm application.
These rules apply to every change, whether written by a person or an agent.

1. This is not a medical diagnostic application.
2. Never describe calculated scores as medical diagnoses.
3. Raw health data and user behavior data are sensitive.
4. Collect only data necessary for an explicitly implemented feature.
5. Never collect window titles, URLs, document contents, messages, file names, or keystrokes.
6. Every external data source requires explicit user consent.
7. All synchronization operations must be idempotent.
8. Mobile must work offline-first.
9. Store timestamps in UTC and preserve the original timezone.
10. Every calculated recommendation must include an explanation based on input factors.
11. Never silently invent health data.
12. Missing data must be represented explicitly.
13. Do not introduce a dependency without explaining why it is required.
14. Generate production-quality code, tests, migrations, documentation, and error handling.
15. Before changing architecture, write a short decision note in `docs/architecture`.
16. Do not delete existing functionality to make a task easier.
17. Follow the existing project structure and naming conventions.
18. Return a summary of changed files and commands required to test the change.

## Where the rules are enforced in code

| Rule | Enforcement |
| --- | --- |
| 1, 2, 10 | `packages/core/src/scoring` returns a disclaimer and a per-factor explanation with every score. |
| 4, 5 | `packages/core/src/privacy` rejects payloads containing forbidden fields; `docs/privacy/data-inventory.md` lists every collected field. |
| 6 | `packages/core/src/consent` requires an active, append-only consent decision per external source and scope. |
| 7 | `packages/core/src/sync` replays results for repeated operation IDs and rejects reused IDs with different payloads. |
| 9 | `packages/core/src/time` stores UTC instant + IANA time zone + offset; naive local timestamps are rejected. |
| 11, 12 | `packages/core/src/data` models every input as `present` or `missing` with a reason; scoring never imputes values. |

## Conventions

- TypeScript, strict mode, ES modules. File names are `camelCase.ts`; tests live in `packages/<name>/test/<module>.test.ts`.
- Domain errors extend `FlowWaveError` and carry a stable `code`.
- SQL migrations live in `db/migrations` as `NNNN_description.up.sql` / `NNNN_description.down.sql`.
- Architecture decisions live in `docs/architecture/NNNN-title.md` (see the index there).

## Commands

```bash
npm ci          # install pinned dev dependencies
npm run check   # strict type check + unit tests
```
