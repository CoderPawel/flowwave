-- Constraint tests for the step 3 data model (decision note 0012). Run after
-- `prisma migrate deploy`:
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f db/tests/02_data_model.test.sql
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

-- Two users, so isolation can be tested.
INSERT INTO users (id, home_time_zone) VALUES
    ('aaaaaaaa-0000-4000-8000-000000000001', 'Europe/Budapest'),
    ('bbbbbbbb-0000-4000-8000-000000000002', 'America/Argentina/Buenos_Aires');

INSERT INTO devices (id, user_id, platform, app_version) VALUES
    ('aaaaaaaa-0000-4000-8000-0000000000d1', 'aaaaaaaa-0000-4000-8000-000000000001', 'android', '0.1.0');

INSERT INTO health_data_sources (id, user_id, kind, source_key, provider_package, provider_name,
                                 recording_device_type, recording_device_manufacturer, recording_device_model) VALUES
    ('aaaaaaaa-0000-4000-8000-0000000000a1', 'aaaaaaaa-0000-4000-8000-000000000001', 'health_connect',
     'health_connect:com.mi.health', 'com.mi.health', 'Mi Fitness', 'fitness_band', 'Xiaomi', 'Smart Band 7'),
    ('bbbbbbbb-0000-4000-8000-0000000000b1', 'bbbbbbbb-0000-4000-8000-000000000002', 'manual_entry',
     'manual_entry', NULL, NULL, NULL, NULL, NULL);

-- Time zones -----------------------------------------------------------------
SELECT pg_temp.expect_failure($sql$
    INSERT INTO users (home_time_zone) VALUES ('Mars/Olympus_Mons')
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO users (home_time_zone) VALUES ('UTC+3')
$sql$, '23514');
SELECT pg_temp.expect(flowwave_is_valid_time_zone('Etc/GMT+3'), 'Etc/GMT+3 is a valid IANA zone');
SELECT pg_temp.expect(flowwave_is_valid_time_zone('America/Port-au-Prince'), 'hyphenated zones are valid');
SELECT pg_temp.expect(NOT flowwave_is_valid_time_zone(''), 'empty zone is invalid');

-- Consent scopes may not be NULL (Prisma creates list columns as nullable) ----
SELECT pg_temp.expect_failure($sql$
    INSERT INTO consent_decisions (user_id, source_id, state, scopes, policy_version,
                                   decided_at_utc, decided_time_zone, decided_utc_offset_minutes)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'health_connect', 'granted', NULL, '2026-11-26', now(), 'UTC', 0)
$sql$, '23514');

-- Health data sources --------------------------------------------------------
SELECT pg_temp.expect_failure($sql$
    INSERT INTO health_data_sources (user_id, kind, source_key)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'health_connect', 'apple_health:x')
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO health_data_sources (user_id, kind, source_key, provider_package)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'health_connect', 'health_connect:bad', 'https://example.com')
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO health_data_sources (user_id, kind, source_key)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'health_connect', 'health_connect:com.mi.health')
$sql$, '23505');

-- Health samples: units, windows, missing values, duplicates, isolation --------
INSERT INTO health_samples (user_id, data_source_id, metric, unit,
                            start_at_utc, start_time_zone, start_utc_offset_minutes,
                            end_at_utc, end_time_zone, end_utc_offset_minutes,
                            value, source_updated_at_utc, idempotency_key) VALUES
    ('aaaaaaaa-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-0000000000a1', 'steps', 'count',
     '2026-11-26T07:00:00Z', 'Europe/Budapest', 60, '2026-11-26T08:00:00Z', 'Europe/Budapest', 60,
     1234, now(), 'hc:steps:2026-11-26T07:00Z');

-- An hour without step data is missing, not zero.
INSERT INTO health_samples (user_id, data_source_id, metric, unit,
                            start_at_utc, start_time_zone, start_utc_offset_minutes,
                            end_at_utc, end_time_zone, end_utc_offset_minutes,
                            value_missing_reason, source_updated_at_utc, idempotency_key) VALUES
    ('aaaaaaaa-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-0000000000a1', 'steps', 'count',
     '2026-11-26T08:00:00Z', 'Europe/Budapest', 60, '2026-11-26T09:00:00Z', 'Europe/Budapest', 60,
     'not_recorded', now(), 'hc:steps:2026-11-26T08:00Z');

INSERT INTO health_samples (user_id, data_source_id, metric, unit,
                            start_at_utc, start_time_zone, start_utc_offset_minutes,
                            end_at_utc, end_time_zone, end_utc_offset_minutes,
                            value, min_value, max_value, sample_count, source_updated_at_utc, idempotency_key) VALUES
    ('aaaaaaaa-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-0000000000a1', 'heart_rate', 'beats_per_minute',
     '2026-11-26T07:00:00Z', 'Europe/Budapest', 60, '2026-11-26T07:05:00Z', 'Europe/Budapest', 60,
     72.5, 64, 88, 5, now(), 'hc:heart_rate:2026-11-26T07:00Z');

SELECT pg_temp.expect_failure($sql$
    INSERT INTO health_samples (user_id, data_source_id, metric, unit, start_at_utc, start_time_zone, start_utc_offset_minutes,
                                end_at_utc, end_time_zone, end_utc_offset_minutes, value, source_updated_at_utc, idempotency_key)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-0000000000a1', 'steps', 'beats_per_minute',
            '2026-11-26T09:00:00Z', 'UTC', 0, '2026-11-26T10:00:00Z', 'UTC', 0, 10, now(), 'wrong-unit')
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO health_samples (user_id, data_source_id, metric, unit, start_at_utc, start_time_zone, start_utc_offset_minutes,
                                end_at_utc, end_time_zone, end_utc_offset_minutes, value, source_updated_at_utc, idempotency_key)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-0000000000a1', 'steps', 'count',
            '2026-11-26T09:00:00Z', 'UTC', 0, '2026-11-26T11:00:00Z', 'UTC', 0, 10, now(), 'two-hour-window')
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO health_samples (user_id, data_source_id, metric, unit, start_at_utc, start_time_zone, start_utc_offset_minutes,
                                end_at_utc, end_time_zone, end_utc_offset_minutes, value, value_missing_reason,
                                source_updated_at_utc, idempotency_key)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-0000000000a1', 'steps', 'count',
            '2026-11-26T09:00:00Z', 'UTC', 0, '2026-11-26T10:00:00Z', 'UTC', 0, 0, 'not_recorded', now(), 'both-set')
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO health_samples (user_id, data_source_id, metric, unit, start_at_utc, start_time_zone, start_utc_offset_minutes,
                                end_at_utc, end_time_zone, end_utc_offset_minutes, value, source_updated_at_utc, idempotency_key)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-0000000000a1', 'heart_rate', 'beats_per_minute',
            '2026-11-26T09:00:00Z', 'UTC', 0, '2026-11-26T09:05:00Z', 'UTC', 0, 70, now(), 'heart-rate-without-range')
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO health_samples (user_id, data_source_id, metric, unit, start_at_utc, start_time_zone, start_utc_offset_minutes,
                                end_at_utc, end_time_zone, end_utc_offset_minutes, value, min_value, max_value,
                                source_updated_at_utc, idempotency_key)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-0000000000a1', 'heart_rate', 'beats_per_minute',
            '2026-11-26T09:00:00Z', 'UTC', 0, '2026-11-26T09:05:00Z', 'UTC', 0, 300, 280, 320, now(), 'heart-rate-out-of-range')
$sql$, '23514');

-- The same import key twice is rejected; the repository turns this into a no-op.
SELECT pg_temp.expect_failure($sql$
    INSERT INTO health_samples (user_id, data_source_id, metric, unit, start_at_utc, start_time_zone, start_utc_offset_minutes,
                                end_at_utc, end_time_zone, end_utc_offset_minutes, value, source_updated_at_utc, idempotency_key)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-0000000000a1', 'steps', 'count',
            '2026-11-26T07:00:00Z', 'UTC', 0, '2026-11-26T08:00:00Z', 'UTC', 0, 1234, now(), 'hc:steps:2026-11-26T07:00Z')
$sql$, '23505');

INSERT INTO health_samples (user_id, data_source_id, metric, unit, start_at_utc, start_time_zone, start_utc_offset_minutes,
                            end_at_utc, end_time_zone, end_utc_offset_minutes, value, source_record_id,
                            source_updated_at_utc, idempotency_key)
VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-0000000000a1', 'resting_heart_rate', 'beats_per_minute',
        '2026-11-26T00:00:00Z', 'UTC', 0, '2026-11-26T23:59:00Z', 'UTC', 0, 58, 'hc-record-1', now(), 'hc:rhr:hc-record-1');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO health_samples (user_id, data_source_id, metric, unit, start_at_utc, start_time_zone, start_utc_offset_minutes,
                                end_at_utc, end_time_zone, end_utc_offset_minutes, value, source_record_id,
                                source_updated_at_utc, idempotency_key)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-0000000000a1', 'resting_heart_rate', 'beats_per_minute',
            '2026-11-26T00:00:00Z', 'UTC', 0, '2026-11-26T23:59:00Z', 'UTC', 0, 58, 'hc-record-1', now(), 'different-key')
$sql$, '23505');

-- A row can never reference another user's data source.
SELECT pg_temp.expect_failure($sql$
    INSERT INTO health_samples (user_id, data_source_id, metric, unit, start_at_utc, start_time_zone, start_utc_offset_minutes,
                                end_at_utc, end_time_zone, end_utc_offset_minutes, value, source_updated_at_utc, idempotency_key)
    VALUES ('bbbbbbbb-0000-4000-8000-000000000002', 'aaaaaaaa-0000-4000-8000-0000000000a1', 'steps', 'count',
            '2026-11-26T07:00:00Z', 'UTC', 0, '2026-11-26T08:00:00Z', 'UTC', 0, 1, now(), 'cross-user')
$sql$, '23503');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO device_usage_buckets (user_id, device_id, bucket_start_at_utc, bucket_start_time_zone,
                                      bucket_start_utc_offset_minutes, missing_reason, idempotency_key, source_updated_at_utc)
    VALUES ('bbbbbbbb-0000-4000-8000-000000000002', 'aaaaaaaa-0000-4000-8000-0000000000d1',
            '2026-11-26T07:00:00Z', 'UTC', 0, 'no_consent', 'cross-user-device', now())
$sql$, '23503');

-- The same import key is fine for a different user.
INSERT INTO health_samples (user_id, data_source_id, metric, unit, start_at_utc, start_time_zone, start_utc_offset_minutes,
                            end_at_utc, end_time_zone, end_utc_offset_minutes, value, source_updated_at_utc, idempotency_key)
VALUES ('bbbbbbbb-0000-4000-8000-000000000002', 'bbbbbbbb-0000-4000-8000-0000000000b1', 'steps', 'count',
        '2026-11-26T07:00:00Z', 'UTC', 0, '2026-11-26T08:00:00Z', 'UTC', 0, 99, now(), 'hc:steps:2026-11-26T07:00Z');

-- Sleep sessions ---------------------------------------------------------------
INSERT INTO sleep_sessions (user_id, data_source_id, start_at_utc, start_time_zone, start_utc_offset_minutes,
                            end_at_utc, end_time_zone, end_utc_offset_minutes, stages_missing_reason,
                            source_updated_at_utc, idempotency_key)
VALUES ('bbbbbbbb-0000-4000-8000-000000000002', 'bbbbbbbb-0000-4000-8000-0000000000b1',
        '2026-11-25T22:30:00Z', 'Europe/Budapest', 60, '2026-11-26T06:00:00Z', 'Europe/Budapest', 60,
        'source_unavailable', now(), 'manual:sleep:1');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO sleep_sessions (user_id, data_source_id, start_at_utc, start_time_zone, start_utc_offset_minutes,
                                end_at_utc, end_time_zone, end_utc_offset_minutes, source_updated_at_utc, idempotency_key)
    VALUES ('bbbbbbbb-0000-4000-8000-000000000002', 'bbbbbbbb-0000-4000-8000-0000000000b1',
            '2026-11-26T22:30:00Z', 'UTC', 0, '2026-11-27T06:00:00Z', 'UTC', 0, now(), 'stages-neither')
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO sleep_sessions (user_id, data_source_id, start_at_utc, start_time_zone, start_utc_offset_minutes,
                                end_at_utc, end_time_zone, end_utc_offset_minutes, deep_sleep_minutes, light_sleep_minutes,
                                source_updated_at_utc, idempotency_key)
    VALUES ('bbbbbbbb-0000-4000-8000-000000000002', 'bbbbbbbb-0000-4000-8000-0000000000b1',
            '2026-11-26T22:00:00Z', 'UTC', 0, '2026-11-27T00:00:00Z', 'UTC', 0, 100, 100, now(), 'stages-too-long')
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO sleep_sessions (user_id, data_source_id, start_at_utc, start_time_zone, start_utc_offset_minutes,
                                end_at_utc, end_time_zone, end_utc_offset_minutes, stages_missing_reason,
                                source_updated_at_utc, idempotency_key)
    VALUES ('bbbbbbbb-0000-4000-8000-000000000002', 'bbbbbbbb-0000-4000-8000-0000000000b1',
            '2026-11-27T06:00:00Z', 'UTC', 0, '2026-11-26T22:00:00Z', 'UTC', 0, 'not_recorded', now(), 'ends-before-start')
$sql$, '23514');

-- Activity sessions --------------------------------------------------------------
SELECT pg_temp.expect_failure($sql$
    INSERT INTO activity_sessions (user_id, data_source_id, activity_type, start_at_utc, start_time_zone, start_utc_offset_minutes,
                                   end_at_utc, end_time_zone, end_utc_offset_minutes, source_updated_at_utc, idempotency_key)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-0000000000a1', 'running',
            '2026-11-26T17:00:00Z', 'UTC', 0, '2026-11-26T17:30:00Z', 'UTC', 0, now(), 'intensity-neither')
$sql$, '23514');

-- Device usage buckets -------------------------------------------------------------
INSERT INTO device_usage_buckets (user_id, device_id, bucket_start_at_utc, bucket_start_time_zone,
                                  bucket_start_utc_offset_minutes, screen_on_seconds, unlock_count, app_switch_count,
                                  productivity_seconds, communication_seconds, social_seconds, entertainment_seconds,
                                  games_seconds, information_seconds, other_seconds, idempotency_key, source_updated_at_utc)
VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-0000000000d1',
        '2026-11-26T07:00:00Z', 'Europe/Budapest', 60, 900, 4, 12, 600, 120, 60, 0, 0, 60, 30,
        'usage:2026-11-26T07:00Z', now());
SELECT pg_temp.expect_failure($sql$
    INSERT INTO device_usage_buckets (user_id, device_id, bucket_start_at_utc, bucket_start_time_zone,
                                      bucket_start_utc_offset_minutes, missing_reason, screen_on_seconds,
                                      idempotency_key, source_updated_at_utc)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-0000000000d1',
            '2026-11-26T07:30:00Z', 'UTC', 0, 'no_consent', 0, 'missing-with-value', now())
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO device_usage_buckets (user_id, device_id, bucket_start_at_utc, bucket_start_time_zone,
                                      bucket_start_utc_offset_minutes, screen_on_seconds, unlock_count, app_switch_count,
                                      productivity_seconds, communication_seconds, social_seconds, entertainment_seconds,
                                      games_seconds, information_seconds, other_seconds, idempotency_key, source_updated_at_utc)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-0000000000d1',
            '2026-11-26T08:00:00Z', 'UTC', 0, 100, 1, 1, 100, 100, 0, 0, 0, 0, 0, 'categories-exceed-screen', now())
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO device_usage_buckets (user_id, device_id, bucket_start_at_utc, bucket_start_time_zone,
                                      bucket_start_utc_offset_minutes, missing_reason, idempotency_key, source_updated_at_utc)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-0000000000d1',
            '2026-11-26T08:10:00Z', 'UTC', 0, 'no_consent', 'misaligned', now())
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO device_usage_buckets (user_id, device_id, bucket_start_at_utc, bucket_start_time_zone,
                                      bucket_start_utc_offset_minutes, missing_reason, idempotency_key, source_updated_at_utc)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-0000000000d1',
            '2026-11-26T07:00:00Z', 'UTC', 0, 'no_consent', 'same-bucket-other-key', now())
$sql$, '23505');

-- Life events ------------------------------------------------------------------------
INSERT INTO meal_events (user_id, eaten_at_utc, eaten_time_zone, eaten_utc_offset_minutes, meal_type, size_missing_reason)
VALUES ('aaaaaaaa-0000-4000-8000-000000000001', '2026-11-26T11:30:00Z', 'Europe/Budapest', 60, 'lunch', 'user_skipped');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO caffeine_events (user_id, consumed_at_utc, consumed_time_zone, consumed_utc_offset_minutes)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', now(), 'UTC', 0)
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO rest_events (user_id, rest_type, start_at_utc, start_time_zone, start_utc_offset_minutes, end_at_utc)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'nap', now(), 'UTC', 0, now() + interval '20 minutes')
$sql$, '23514');

-- An open focus session has no outcome or rating yet.
INSERT INTO focus_sessions (user_id, start_at_utc, start_time_zone, start_utc_offset_minutes, planned_duration_minutes)
VALUES ('aaaaaaaa-0000-4000-8000-000000000001', '2026-11-26T08:00:00Z', 'Europe/Budapest', 60, 45);
SELECT pg_temp.expect_failure($sql$
    INSERT INTO focus_sessions (user_id, start_at_utc, start_time_zone, start_utc_offset_minutes, outcome)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', now(), 'UTC', 0, 'completed')
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO focus_sessions (user_id, start_at_utc, start_time_zone, start_utc_offset_minutes,
                                end_at_utc, end_time_zone, end_utc_offset_minutes, outcome)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', '2026-11-26T08:00:00Z', 'UTC', 0,
            '2026-11-26T08:45:00Z', 'UTC', 0, 'completed')
$sql$, '23514');

-- Calculated results need an explanation with factors and a disclaimer ------------------
INSERT INTO daily_scores (user_id, local_date, time_zone, score_type, status, input_coverage_ratio,
                          calculation_version, explanation, computed_at_utc)
VALUES ('aaaaaaaa-0000-4000-8000-000000000001', '2026-11-26', 'Europe/Budapest', 'energy', 'insufficient_data', 0.2,
        '1.0.0', '{"factors": [], "missing": ["sleep_duration"], "disclaimer": "Not a medical assessment."}', now());
SELECT pg_temp.expect_failure($sql$
    INSERT INTO daily_scores (user_id, local_date, time_zone, score_type, status, score_value, input_coverage_ratio,
                              calculation_version, explanation, computed_at_utc)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', '2026-11-27', 'UTC', 'energy', 'computed', 70, 1,
            '1.0.0', '{"factors": []}', now())
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO daily_scores (user_id, local_date, time_zone, score_type, status, input_coverage_ratio,
                              calculation_version, explanation, computed_at_utc)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', '2026-11-27', 'UTC', 'energy', 'computed', 1,
            '1.0.0', '{"factors": [], "disclaimer": "Not a medical assessment."}', now())
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO rhythm_buckets (user_id, bucket_start_at_utc, bucket_start_time_zone, bucket_start_utc_offset_minutes,
                                status, state, calculation_version, explanation, computed_at_utc)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', '2026-11-26T07:00:00Z', 'UTC', 0, 'insufficient_data', 'flow',
            '1.0.0', '{"factors": [], "disclaimer": "Not a medical assessment."}', now())
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO rhythm_buckets (user_id, bucket_start_at_utc, bucket_start_time_zone, bucket_start_utc_offset_minutes,
                                status, energy_level, confidence_ratio, calculation_version, explanation, computed_at_utc)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', '2026-11-26T07:00:00Z', 'UTC', 0, 'computed', 60, 0.5,
            '1.0.0', '{"factors": [], "disclaimer": "Not a medical assessment."}', now())
$sql$, '23514');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO recommendations (user_id, kind, template_key, explanation, valid_from_at_utc, valid_from_time_zone,
                                 valid_from_utc_offset_minutes, valid_until_at_utc, status, calculation_version)
    VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'break', 'break.after_focus',
            '{"factors": [], "disclaimer": "Not a medical assessment."}', now(), 'UTC', 0, now() + interval '1 hour',
            'dismissed', '1.0.0')
$sql$, '23514');

-- updated_at_utc is maintained by the database --------------------------------------------
UPDATE devices SET updated_at_utc = '2000-01-01T00:00:00Z' WHERE id = 'aaaaaaaa-0000-4000-8000-0000000000d1';
SELECT pg_temp.expect(
    (SELECT updated_at_utc = now() FROM devices WHERE id = 'aaaaaaaa-0000-4000-8000-0000000000d1'),
    'updated_at_utc is set by the trigger');

-- Audit events are append-only but survive user deletion without the link ----------------
INSERT INTO audit_events (id, user_id, action, entity_type, entity_id)
VALUES ('aaaaaaaa-0000-4000-8000-0000000000e1', 'aaaaaaaa-0000-4000-8000-000000000001', 'device_registered',
        'device', 'aaaaaaaa-0000-4000-8000-0000000000d1');
SELECT pg_temp.expect_failure($sql$
    UPDATE audit_events SET action = 'data_exported' WHERE id = 'aaaaaaaa-0000-4000-8000-0000000000e1'
$sql$, '23001');
SELECT pg_temp.expect_failure($sql$
    INSERT INTO audit_events (user_id, action, entity_type) VALUES ('aaaaaaaa-0000-4000-8000-000000000001', 'data_exported', 'device')
$sql$, '23514');

-- Deleting a user removes all of their data, in every table -------------------------------
DELETE FROM users WHERE id = 'aaaaaaaa-0000-4000-8000-000000000001';
DO $$
DECLARE
    t text;
    remaining bigint;
BEGIN
    FOR t IN
        SELECT c.table_name FROM information_schema.columns c
        JOIN information_schema.tables tb ON tb.table_schema = c.table_schema AND tb.table_name = c.table_name
        WHERE c.table_schema = current_schema() AND c.column_name = 'user_id'
          AND tb.table_type = 'BASE TABLE' AND c.table_name <> 'audit_events'
    LOOP
        EXECUTE format('SELECT count(*) FROM %I WHERE user_id = %L', t, 'aaaaaaaa-0000-4000-8000-000000000001')
            INTO remaining;
        IF remaining > 0 THEN
            RAISE EXCEPTION 'User deletion left % row(s) in %', remaining, t;
        END IF;
    END LOOP;
END;
$$;
SELECT pg_temp.expect(
    (SELECT user_id IS NULL FROM audit_events WHERE id = 'aaaaaaaa-0000-4000-8000-0000000000e1'),
    'audit event kept without the deleted user');
SELECT pg_temp.expect(
    (SELECT count(*) = 1 FROM health_samples WHERE user_id = 'bbbbbbbb-0000-4000-8000-000000000002'),
    'other users keep their data');

-- No column may hold data FlowWave never collects (project rule 5) ------------------------
SELECT pg_temp.expect(NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = current_schema()
      AND column_name ~ '(url|uri|href|link|window|title|message|file_?name|file_?path|keystroke|typed|clipboard|screenshot|package_name|app_name)'
), 'no forbidden column names');

\o
SELECT 'all data model tests passed' AS result;

ROLLBACK;
