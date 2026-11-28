-- Constraint tests for the tables that existed before the Prisma port (users,
-- check_ins, consent_decisions, applied_sync_operations). They run unchanged
-- against the Prisma migration to prove no constraint was lost. Run after
-- `prisma migrate deploy`:
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f db/tests/01_ported_constraints.test.sql
-- Everything runs in a transaction that is rolled back, so no data is left behind.

\o /dev/null

BEGIN;

CREATE FUNCTION pg_temp.expect_failure(statement text, expected_sqlstate text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        EXECUTE statement;
    EXCEPTION WHEN OTHERS THEN
        IF SQLSTATE <> expected_sqlstate THEN
            RAISE EXCEPTION 'Expected SQLSTATE % but got % (%) for: %', expected_sqlstate, SQLSTATE, SQLERRM, statement;
        END IF;
        RETURN;
    END;
    RAISE EXCEPTION 'Expected failure (SQLSTATE %) but statement succeeded: %', expected_sqlstate, statement;
END;
$$;

INSERT INTO users (id, home_time_zone) VALUES ('11111111-1111-4111-8111-111111111111', 'Europe/Budapest');

-- Valid check-ins: all inputs present, and inputs explicitly missing.
INSERT INTO check_ins (id, user_id, recorded_at_utc, recorded_time_zone, recorded_utc_offset_minutes,
                       self_reported_energy, sleep_duration_minutes, sleep_duration_source)
VALUES ('22222222-2222-4222-8222-222222222222', '11111111-1111-4111-8111-111111111111',
        '2026-11-26T07:30:00Z', 'Europe/Budapest', 60, 4, 432, 'manual_check_in');

INSERT INTO check_ins (id, user_id, recorded_at_utc, recorded_time_zone, recorded_utc_offset_minutes,
                       self_reported_energy_missing_reason, sleep_duration_missing_reason)
VALUES ('33333333-3333-4333-8333-333333333333', '11111111-1111-4111-8111-111111111111',
        '2026-11-26T12:00:00Z', 'Europe/Budapest', 60, 'user_skipped', 'no_consent');

-- A value must be either present or explicitly missing, never both and never neither.
SELECT pg_temp.expect_failure($sql$
    INSERT INTO check_ins (id, user_id, recorded_at_utc, recorded_time_zone, recorded_utc_offset_minutes,
                           sleep_duration_missing_reason)
    VALUES (gen_random_uuid(), '11111111-1111-4111-8111-111111111111', now(), 'UTC', 0, 'not_recorded')
$sql$, '23514');

SELECT pg_temp.expect_failure($sql$
    INSERT INTO check_ins (id, user_id, recorded_at_utc, recorded_time_zone, recorded_utc_offset_minutes,
                           self_reported_energy, self_reported_energy_missing_reason, sleep_duration_missing_reason)
    VALUES (gen_random_uuid(), '11111111-1111-4111-8111-111111111111', now(), 'UTC', 0, 3, 'user_skipped', 'not_recorded')
$sql$, '23514');

-- Out-of-range values and unknown reasons are rejected.
SELECT pg_temp.expect_failure($sql$
    INSERT INTO check_ins (id, user_id, recorded_at_utc, recorded_time_zone, recorded_utc_offset_minutes,
                           self_reported_energy, sleep_duration_missing_reason)
    VALUES (gen_random_uuid(), '11111111-1111-4111-8111-111111111111', now(), 'UTC', 0, 6, 'not_recorded')
$sql$, '23514');

SELECT pg_temp.expect_failure($sql$
    INSERT INTO check_ins (id, user_id, recorded_at_utc, recorded_time_zone, recorded_utc_offset_minutes,
                           self_reported_energy, sleep_duration_missing_reason)
    VALUES (gen_random_uuid(), '11111111-1111-4111-8111-111111111111', now(), 'UTC', 0, 3, 'assumed_zero')
$sql$, '22P02'); -- missing reasons are a PostgreSQL enum since the Prisma port

-- A sleep value needs a source.
SELECT pg_temp.expect_failure($sql$
    INSERT INTO check_ins (id, user_id, recorded_at_utc, recorded_time_zone, recorded_utc_offset_minutes,
                           self_reported_energy, sleep_duration_minutes)
    VALUES (gen_random_uuid(), '11111111-1111-4111-8111-111111111111', now(), 'UTC', 0, 3, 420)
$sql$, '23514');

-- Consent: valid grant and revocation; invalid scopes; append-only.
INSERT INTO consent_decisions (id, user_id, source_id, state, scopes, policy_version,
                               decided_at_utc, decided_time_zone, decided_utc_offset_minutes)
VALUES ('44444444-4444-4444-8444-444444444444', '11111111-1111-4111-8111-111111111111', 'apple_health', 'granted',
        ARRAY['sleep_duration'], '2026-11-26', '2026-11-26T10:00:00Z', 'Europe/Budapest', 60),
       ('55555555-5555-4555-8555-555555555555', '11111111-1111-4111-8111-111111111111', 'apple_health', 'revoked',
        '{}', '2026-11-26', '2026-11-26T11:00:00Z', 'Europe/Budapest', 60);

-- Undeclared scope. Originally 'heart_rate', which decision 0014 declared.
SELECT pg_temp.expect_failure($sql$
    INSERT INTO consent_decisions (id, user_id, source_id, state, scopes, policy_version,
                                   decided_at_utc, decided_time_zone, decided_utc_offset_minutes)
    VALUES (gen_random_uuid(), '11111111-1111-4111-8111-111111111111', 'apple_health', 'granted',
            ARRAY['blood_glucose'], '2026-11-26', now(), 'UTC', 0)
$sql$, '23514');

SELECT pg_temp.expect_failure($sql$
    INSERT INTO consent_decisions (id, user_id, source_id, state, scopes, policy_version,
                                   decided_at_utc, decided_time_zone, decided_utc_offset_minutes)
    VALUES (gen_random_uuid(), '11111111-1111-4111-8111-111111111111', 'browser_history', 'granted',
            ARRAY['sleep_duration'], '2026-11-26', now(), 'UTC', 0)
$sql$, '23514');

SELECT pg_temp.expect_failure($sql$
    UPDATE consent_decisions SET state = 'granted', scopes = ARRAY['sleep_duration']
    WHERE id = '55555555-5555-4555-8555-555555555555'
$sql$, '23001');

-- Idempotency: an operation ID can be recorded only once.
INSERT INTO applied_sync_operations (operation_id, user_id, entity_type, entity_id, payload_fingerprint, result)
VALUES ('66666666-6666-4666-8666-666666666666', '11111111-1111-4111-8111-111111111111', 'check_in',
        '22222222-2222-4222-8222-222222222222', '{"kind":"upsert"}', '{"version":1}');

SELECT pg_temp.expect_failure($sql$
    INSERT INTO applied_sync_operations (operation_id, user_id, entity_type, entity_id, payload_fingerprint, result)
    VALUES ('66666666-6666-4666-8666-666666666666', '11111111-1111-4111-8111-111111111111', 'check_in',
            '22222222-2222-4222-8222-222222222222', '{"kind":"upsert"}', '{"version":1}')
$sql$, '23505');

-- Deleting a user removes all of their data.
DELETE FROM users WHERE id = '11111111-1111-4111-8111-111111111111';
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM check_ins) OR EXISTS (SELECT 1 FROM consent_decisions)
       OR EXISTS (SELECT 1 FROM applied_sync_operations) THEN
        RAISE EXCEPTION 'User deletion left data behind';
    END IF;
END;
$$;

\o
SELECT 'all schema tests passed' AS result;

ROLLBACK;
