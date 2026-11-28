-- Reverses 20261127220000_initial_schema. Prisma Migrate does not run this
-- file; it is applied with `prisma db execute` or psql, followed by
-- `prisma migrate resolve --rolled-back 20261127220000_initial_schema`.
-- scripts/verify-migrations.sh applies it in CI to prove the migration is reversible.

BEGIN;

DROP TABLE IF EXISTS "audit_events";
DROP TABLE IF EXISTS "applied_sync_operations";
DROP TABLE IF EXISTS "sync_checkpoints";
DROP TABLE IF EXISTS "recommendations";
DROP TABLE IF EXISTS "rhythm_buckets";
DROP TABLE IF EXISTS "daily_scores";
DROP TABLE IF EXISTS "focus_sessions";
DROP TABLE IF EXISTS "rest_events";
DROP TABLE IF EXISTS "caffeine_events";
DROP TABLE IF EXISTS "meal_events";
DROP TABLE IF EXISTS "check_ins";
DROP TABLE IF EXISTS "device_usage_buckets";
DROP TABLE IF EXISTS "activity_sessions";
DROP TABLE IF EXISTS "sleep_sessions";
DROP TABLE IF EXISTS "health_samples";
DROP TABLE IF EXISTS "health_data_sources";
DROP TABLE IF EXISTS "consent_decisions";
DROP TABLE IF EXISTS "devices";
DROP TABLE IF EXISTS "users";

DROP FUNCTION IF EXISTS audit_events_forbid_update();
DROP FUNCTION IF EXISTS consent_decisions_forbid_update();
DROP FUNCTION IF EXISTS flowwave_set_updated_at();
DROP FUNCTION IF EXISTS flowwave_is_valid_explanation(jsonb);
DROP FUNCTION IF EXISTS flowwave_is_valid_time_zone(text);

DROP TYPE IF EXISTS "audit_action";
DROP TYPE IF EXISTS "recommendation_status";
DROP TYPE IF EXISTS "recommendation_kind";
DROP TYPE IF EXISTS "rhythm_state";
DROP TYPE IF EXISTS "calculation_status";
DROP TYPE IF EXISTS "score_type";
DROP TYPE IF EXISTS "focus_outcome";
DROP TYPE IF EXISTS "rest_type";
DROP TYPE IF EXISTS "portion_size";
DROP TYPE IF EXISTS "meal_type";
DROP TYPE IF EXISTS "activity_intensity";
DROP TYPE IF EXISTS "activity_type";
DROP TYPE IF EXISTS "measurement_unit";
DROP TYPE IF EXISTS "health_metric";
DROP TYPE IF EXISTS "health_source_kind";
DROP TYPE IF EXISTS "device_platform";
DROP TYPE IF EXISTS "check_in_sleep_source";
DROP TYPE IF EXISTS "missing_reason";

COMMIT;
