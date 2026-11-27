# 0011. Monorepo layout and tooling

- Status: Accepted
- Date: 2026-11-27
- Extends: [0001](0001-monorepo-and-shared-core.md)

## Context

Roadmap step 2 adds a NestJS API, a Next.js web panel, a Flutter app, an
OpenAPI contracts package, an analytics-engine package, local infrastructure,
and CI for lint, test, and build. Decision 0001 set up npm workspaces with a
dependency-free core and the built-in Node test runner.

## Decision

Layout:

```text
apps/api/                    NestJS API (npm workspace)
apps/web/                    Next.js web panel (npm workspace)
apps/mobile/                 Flutter app (Dart; outside npm workspaces)
packages/core/               Shared domain rules (unchanged)
packages/analytics-engine/   Rhythm and score calculations (TypeScript)
packages/contracts/          OpenAPI document generated from the API, plus TypeScript types
infrastructure/docker/       Docker Compose for local PostgreSQL
db/                          Existing SQL migration and SQL tests until step 3
```

Tooling:

- **npm workspaces** stay; no extra monorepo tool. Root scripts fan out with
  `--workspaces --if-present`.
- **TypeScript 5.9** everywhere. TypeScript 7 is not yet supported by
  typescript-eslint, `@nestjs/swagger`, or openapi-typescript.
- **Node 22.18 or newer**, so `.ts` test files of the web panel run with Node's
  built-in type stripping.
- **Tests** use the built-in `node:test` runner in every TypeScript package, as
  in 0001. The API is compiled with `tsc` first, because its decorators need
  emitted metadata. HTTP tests start the app on a random port and use the
  built-in `fetch`, so no HTTP test library is needed.
- **Configuration** is validated at startup with class-validator into a typed
  `AppConfig`; the app refuses to start with invalid settings. No
  configuration library is added.
- **Contracts**: the API writes `packages/contracts/openapi.json` from its
  Swagger metadata; openapi-typescript turns it into TypeScript types. CI fails
  if the committed contract differs from the generated one.
- **Prisma 7** generates a TypeScript client into `apps/api/generated/prisma`
  (ignored by git) with ES module output, and connects through the
  `@prisma/adapter-pg` driver adapter, as Prisma 7 requires
  ([0010](0010-prisma-schema-and-data-access.md)).
- **ESLint 9**, not 10: the React, import, and accessibility plugins used by
  `eslint-config-next` declare support up to ESLint 9 only. Move to ESLint 10
  when they do. The root config lints TypeScript packages and the API with
  type-aware rules; the web panel uses its own Next.js config.
- **Mobile**: Flutter 3.50 stable with the default `flutter_lints` rules,
  `minSdk` 28 ([0006](0006-health-connect-wearable-gateway.md)), and Android backup and
  device transfer disabled, so local rhythm data leaves the phone only through
  explicit sync.
- **PostgreSQL 16** in Docker Compose and CI, matching the existing migration
  verification.

## Dependencies

| Dependency | Where | Why it is required |
| --- | --- | --- |
| `@nestjs/common`, `@nestjs/core`, `@nestjs/platform-express`, `reflect-metadata`, `rxjs` | API | NestJS framework and its required peers ([0008](0008-nestjs-sync-api.md)). |
| `@nestjs/swagger` | API | Generates the OpenAPI document and serves Swagger UI (step 2 requirement). |
| `class-validator`, `class-transformer` | API | Request and configuration validation (step 2 requirement). |
| `nestjs-pino`, `pino`, `pino-http` | API | Structured JSON logs with header redaction (step 2 requirement). |
| `@nestjs/testing` (dev) | API | Builds the app in tests with selected providers replaced, for example a fake database health check. |
| `@prisma/client`, `@prisma/adapter-pg`, `prisma` (dev) | API | Database access and migrations ([0010](0010-prisma-schema-and-data-access.md)). |
| `next`, `react`, `react-dom` | Web | Next.js web panel (owner's plan). |
| `tailwindcss`, `@tailwindcss/postcss` (dev) | Web | Styling (owner's plan). |
| `openapi-typescript` (dev) | Contracts | Generates TypeScript types from the OpenAPI document. |
| `eslint`, `@eslint/js`, `typescript-eslint` (dev) | Root | Lint step required in CI; typed lint rules for TypeScript. |
| `eslint-config-next` (dev) | Web | Next.js lint rules, including React and accessibility checks. |
| `@types/react`, `@types/react-dom` (dev) | Web | Type definitions for React. |
| `material_ui` | Mobile | Material widgets; Flutter 3.50 ships them as a package and `flutter create` adds it. |
| `flutter_lints` (dev) | Mobile | Default Flutter lint rules used by `flutter analyze`. |

## Consequences

- One `npm ci` installs everything except Flutter.
- Each app keeps its own test style, but all TypeScript tests use one runner.
- The web panel is a scaffold until step 15.

## Acceptance criteria

- `npm run lint`, `npm run check`, and `npm run build` pass from a clean clone.
- `flutter analyze`, `flutter test`, and `flutter build apk --debug` pass in
  `apps/mobile`.
- CI runs all of the above plus the database job.
