# Prompt 3: data model (verbatim)

Source: the owner's Copilot plan, pasted on 2026-11-27. Kept verbatim so later
steps can refer to the exact wording. How it was implemented, and where it was
adapted to the project rules, is in [roadmap step 3](../roadmap.md) and
[decision 0012](../architecture/0012-data-model.md).

```text
Prompt 3: model danych

Design and implement the initial PostgreSQL schema using Prisma.

Entities:
- User
- Device
- Consent
- HealthDataSource
- HealthSample
- SleepSession
- ActivitySession
- DeviceUsageBucket
- SelfCheckIn
- MealEvent
- CaffeineEvent
- RestEvent
- FocusSession
- DailyScore
- RhythmBucket
- Recommendation
- SyncCheckpoint
- AuditEvent

Requirements:
- UUID primary keys
- timestamps stored in UTC
- original timezone field where relevant
- createdAt and updatedAt
- soft deletion where appropriate
- idempotencyKey for imported records
- sourceRecordId for Health Connect records
- uniqueness constraints preventing duplicate synchronization
- explicit units for numerical measurements
- support missing values without inserting zero
- health provider/source metadata
- user-level data isolation

Do not store raw URLs, window titles, message content, file names or keystrokes.

Create:
- Prisma schema
- migration
- seed data using clearly marked synthetic records
- ER diagram in Mermaid
- repository tests for idempotent inserts
- data dictionary documentation
```
