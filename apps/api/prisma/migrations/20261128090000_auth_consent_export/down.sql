-- Reverses 20261128090000_auth_consent_export. Prisma Migrate does not run this
-- file; it is applied with `prisma db execute` or psql, followed by
-- `prisma migrate resolve --rolled-back 20261128090000_auth_consent_export`.
-- scripts/verify-migrations.sh applies it in CI to prove the migration is reversible.
--
-- Data that the earlier schema cannot represent is deleted: accounts'
-- credentials, sessions and export jobs, consent decisions of the new types or
-- with the new scopes, and audit events with the new actions.

BEGIN;

DROP TABLE IF EXISTS "data_export_jobs";
DROP TABLE IF EXISTS "auth_tokens";
DROP TABLE IF EXISTS "auth_sessions";
DROP TABLE IF EXISTS "user_credentials";
DROP FUNCTION IF EXISTS auth_tokens_allow_only_rotation();
DROP TYPE IF EXISTS "export_job_status";
DROP TYPE IF EXISTS "session_revocation_reason";

ALTER TABLE "consent_decisions"
    DROP CONSTRAINT "consent_decisions_source_matches_type",
    DROP CONSTRAINT "consent_decisions_scopes_match_state";
DELETE FROM "consent_decisions"
WHERE "consent_type" <> 'health_data' OR NOT ("scopes" <@ ARRAY['sleep_duration']::text[]);
DROP INDEX "consent_decisions_user_type_source_decided_idx";
ALTER TABLE "consent_decisions"
    DROP COLUMN "consent_type",
    ALTER COLUMN "source_id" SET NOT NULL,
    ADD CONSTRAINT "consent_decisions_source_id_known" CHECK ("source_id" IN ('apple_health', 'health_connect')),
    ADD CONSTRAINT "consent_decisions_scopes_match_state" CHECK (
        ("state" = 'granted' AND cardinality("scopes") > 0 AND "scopes" <@ ARRAY['sleep_duration']::text[])
        OR ("state" = 'revoked' AND cardinality("scopes") = 0)
    );
CREATE INDEX "consent_decisions_user_source_decided_idx"
    ON "consent_decisions"("user_id", "source_id", "decided_at_utc" DESC);
DROP TYPE "consent_type";

-- PostgreSQL cannot remove enum values, so audit_action is recreated.
DELETE FROM "audit_events"
WHERE "action" IN ('login_succeeded', 'login_failed', 'logged_out', 'logged_out_all',
                   'session_revoked', 'refresh_token_reused', 'data_export_requested');
ALTER TYPE "audit_action" RENAME TO "audit_action_step4";
CREATE TYPE "audit_action" AS ENUM ('account_created', 'account_deleted', 'consent_recorded', 'device_registered',
                                    'device_revoked', 'data_exported', 'data_deleted');
ALTER TABLE "audit_events"
    ALTER COLUMN "action" TYPE "audit_action" USING "action"::text::"audit_action";
DROP TYPE "audit_action_step4";

COMMIT;
