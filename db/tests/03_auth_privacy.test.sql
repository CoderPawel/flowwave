-- Constraint tests for authentication, consent types and data export
-- (roadmap step 4, decision notes 0013 and 0014). Run after `prisma migrate deploy`:
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f db/tests/03_auth_privacy.test.sql
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

CREATE FUNCTION pg_temp.expect(condition boolean, description text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    IF condition IS DISTINCT FROM true THEN
        RAISE EXCEPTION 'Expectation failed: %', description;
    END IF;
END;
$$;

INSERT INTO users (id, home_time_zone) VALUES
    ('aaaaaaaa-0000-4000-8000-000000000001', 'Europe/Budapest'),
    ('bbbbbbbb-0000-4000-8000-000000000002', 'Europe/Warsaw');
INSERT INTO devices (id, user_id, platform) VALUES
    ('aaaaaaaa-0000-4000-8000-0000000000d1', 'aaaaaaaa-0000-4000-8000-000000000001', 'android'),
    ('bbbbbbbb-0000-4000-8000-0000000000d2', 'bbbbbbbb-0000-4000-8000-000000000002', 'android');

-- Consent types -------------------------------------------------------------------------
INSERT INTO consent_decisions (user_id, consent_type, source_id, state, scopes, policy_version,
                               decided_at_utc, decided_time_zone, decided_utc_offset_minutes) VALUES
    ('aaaaaaaa-0000-4000-8000-000000000001', 'health_data', 'health_connect', 'granted', '{steps,heart_rate}',
     '2026-11-26', now(), 'Europe/Budapest', 60),
    ('aaaaaaaa-0000-4000-8000-000000000001', 'device_usage', NULL, 'granted', '{}', '2026-11-28', now(), 'Europe/Budapest', 60),
    ('aaaaaaaa-0000-4000-8000-000000000001', 'notifications', NULL, 'revoked', '{}', '2026-11-28', now(), 'Europe/Budapest', 60),
    ('aaaaaaaa-0000-4000-8000-000000000001', 'analytics', NULL, 'granted', '{}', '2026-11-28', now(), 'Europe/Budapest', 60),
    ('aaaaaaaa-0000-4000-8000-000000000001', 'health_data', 'health_connect', 'revoked', '{}', '2026-11-26', now(), 'Europe/Budapest', 60);
SELECT pg_temp.expect(
    (SELECT consent_type = 'health_data' FROM consent_decisions WHERE consent_type IS NOT NULL
     AND source_id = 'health_connect' LIMIT 1),
    'health data decisions keep their source');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO consent_decisions (user_id, consent_type, source_id, state, scopes, policy_version,
                                   decided_at_utc, decided_time_zone, decided_utc_offset_minutes)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'device_usage', 'health_connect', 'granted', '{}', '2026-11-28', now(), 'UTC', 0)
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO consent_decisions (user_id, consent_type, source_id, state, scopes, policy_version,
                                   decided_at_utc, decided_time_zone, decided_utc_offset_minutes)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'analytics', NULL, 'granted', '{steps}', '2026-11-28', now(), 'UTC', 0)
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO consent_decisions (user_id, consent_type, source_id, state, scopes, policy_version,
                                   decided_at_utc, decided_time_zone, decided_utc_offset_minutes)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'health_data', NULL, 'granted', '{steps}', '2026-11-26', now(), 'UTC', 0)
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO consent_decisions (user_id, consent_type, source_id, state, scopes, policy_version,
                                   decided_at_utc, decided_time_zone, decided_utc_offset_minutes)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'health_data', 'health_connect', 'granted', '{location}', '2026-11-26', now(), 'UTC', 0)
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO consent_decisions (user_id, consent_type, source_id, state, scopes, policy_version,
                                   decided_at_utc, decided_time_zone, decided_utc_offset_minutes)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'notifications', NULL, 'revoked', '{steps}', '2026-11-28', now(), 'UTC', 0)
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    UPDATE consent_decisions SET state = 'granted' WHERE consent_type = 'notifications'
$sql$, '23001');

-- Credentials ---------------------------------------------------------------------------
INSERT INTO user_credentials (user_id, email, password_hash) VALUES
    ('aaaaaaaa-0000-4000-8000-000000000001', 'ada@example.org', '$argon2id$v=19$m=19456,t=2,p=1$c2FsdA$aGFzaA');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO user_credentials (user_id, email, password_hash)
    VALUES ('bbbbbbbb-0000-4000-8000-000000000002', 'Ada@Example.org', '$argon2id$v=19$m=19456,t=2,p=1$c2FsdA$aGFzaA')
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO user_credentials (user_id, email, password_hash)
    VALUES ('bbbbbbbb-0000-4000-8000-000000000002', 'not-an-email', '$argon2id$v=19$m=19456,t=2,p=1$c2FsdA$aGFzaA')
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO user_credentials (user_id, email, password_hash)
    VALUES ('bbbbbbbb-0000-4000-8000-000000000002', 'bob@example.org', 'plain-text-password')
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO user_credentials (user_id, email, password_hash)
    VALUES ('bbbbbbbb-0000-4000-8000-000000000002', 'ada@example.org', '$argon2id$v=19$m=19456,t=2,p=1$c2FsdA$aGFzaA')
$sql$, '23505');

-- Sessions ------------------------------------------------------------------------------
INSERT INTO auth_sessions (id, user_id, device_id, expires_at_utc) VALUES
    ('aaaaaaaa-0000-4000-8000-0000000000f1', 'aaaaaaaa-0000-4000-8000-000000000001',
     'aaaaaaaa-0000-4000-8000-0000000000d1', now() + interval '30 days');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO auth_sessions (user_id, device_id, expires_at_utc)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'bbbbbbbb-0000-4000-8000-0000000000d2', now() + interval '1 day')
$sql$, '23503');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO auth_sessions (user_id, device_id, expires_at_utc)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-0000000000d1', now() + interval '1 day')
$sql$, '23505');
SELECT pg_temp.expect_failure($sql$
    UPDATE auth_sessions SET revoked_at_utc = now() WHERE id = 'aaaaaaaa-0000-4000-8000-0000000000f1'
$sql$, '23514');

-- Tokens --------------------------------------------------------------------------------
INSERT INTO auth_tokens (id, user_id, session_id, access_token_hash, access_expires_at_utc,
                         refresh_token_hash, refresh_expires_at_utc) VALUES
    ('aaaaaaaa-0000-4000-8000-0000000000c1', 'aaaaaaaa-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-0000000000f1',
     repeat('a', 64), now() + interval '15 minutes', repeat('b', 64), now() + interval '30 days');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO auth_tokens (user_id, session_id, access_token_hash, access_expires_at_utc, refresh_token_hash, refresh_expires_at_utc)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-0000000000f1',
            'fwat_raw_token_must_never_be_stored_here_0000000000000000000000', now() + interval '15 minutes',
            repeat('c', 64), now() + interval '30 days')
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO auth_tokens (user_id, session_id, access_token_hash, access_expires_at_utc, refresh_token_hash, refresh_expires_at_utc)
    VALUES ('bbbbbbbb-0000-4000-8000-000000000002', 'aaaaaaaa-0000-4000-8000-0000000000f1',
            repeat('d', 64), now() + interval '15 minutes', repeat('e', 64), now() + interval '30 days')
$sql$, '23503');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO auth_tokens (user_id, session_id, access_token_hash, access_expires_at_utc, refresh_token_hash, refresh_expires_at_utc)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-0000000000f1',
            repeat('a', 64), now() + interval '15 minutes', repeat('f', 64), now() + interval '30 days')
$sql$, '23505');
SELECT pg_temp.expect_failure($sql$
    UPDATE auth_tokens SET access_expires_at_utc = now() + interval '1 year' WHERE id = 'aaaaaaaa-0000-4000-8000-0000000000c1'
$sql$, '23001');
UPDATE auth_tokens SET rotated_at_utc = now() WHERE id = 'aaaaaaaa-0000-4000-8000-0000000000c1';
SELECT pg_temp.expect_failure($sql$
    UPDATE auth_tokens SET rotated_at_utc = NULL WHERE id = 'aaaaaaaa-0000-4000-8000-0000000000c1'
$sql$, '23001');

-- Export jobs ---------------------------------------------------------------------------
INSERT INTO data_export_jobs (id, user_id) VALUES
    ('aaaaaaaa-0000-4000-8000-0000000000e1', 'aaaaaaaa-0000-4000-8000-000000000001');
SELECT pg_temp.expect_failure($sql$
    UPDATE data_export_jobs SET status = 'completed', started_at_utc = now(), completed_at_utc = now()
    WHERE id = 'aaaaaaaa-0000-4000-8000-0000000000e1'
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    UPDATE data_export_jobs SET result = '{"tables": {}}' WHERE id = 'aaaaaaaa-0000-4000-8000-0000000000e1'
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    UPDATE data_export_jobs SET status = 'failed', completed_at_utc = now(), failure_code = 'Error: row (72, 64)'
    WHERE id = 'aaaaaaaa-0000-4000-8000-0000000000e1'
$sql$, '23514');
UPDATE data_export_jobs SET status = 'running', started_at_utc = now() WHERE id = 'aaaaaaaa-0000-4000-8000-0000000000e1';
UPDATE data_export_jobs
SET status = 'completed', completed_at_utc = now(), expires_at_utc = now() + interval '7 days',
    result = '{"tables": {}}', result_bytes = 14
WHERE id = 'aaaaaaaa-0000-4000-8000-0000000000e1';
SELECT pg_temp.expect(
    (SELECT updated_at_utc >= created_at_utc FROM data_export_jobs WHERE id = 'aaaaaaaa-0000-4000-8000-0000000000e1'),
    'updated_at_utc is maintained on export jobs');

-- Deleting a user removes credentials, sessions, tokens, export jobs and consents ---------
DELETE FROM users WHERE id = 'aaaaaaaa-0000-4000-8000-000000000001';
SELECT pg_temp.expect(
    (SELECT count(*) = 0 FROM user_credentials WHERE user_id = 'aaaaaaaa-0000-4000-8000-000000000001')
    AND (SELECT count(*) = 0 FROM auth_sessions WHERE user_id = 'aaaaaaaa-0000-4000-8000-000000000001')
    AND (SELECT count(*) = 0 FROM auth_tokens WHERE user_id = 'aaaaaaaa-0000-4000-8000-000000000001')
    AND (SELECT count(*) = 0 FROM data_export_jobs WHERE user_id = 'aaaaaaaa-0000-4000-8000-000000000001')
    AND (SELECT count(*) = 0 FROM consent_decisions WHERE user_id = 'aaaaaaaa-0000-4000-8000-000000000001'),
    'account deletion removes authentication, export and consent rows');
SELECT pg_temp.expect(
    (SELECT count(*) = 1 FROM devices WHERE user_id = 'bbbbbbbb-0000-4000-8000-000000000002'),
    'other users keep their devices');

\o
SELECT 'all authentication and privacy tests passed' AS result;

ROLLBACK;
