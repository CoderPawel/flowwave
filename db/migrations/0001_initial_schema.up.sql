-- FlowWave initial schema.
-- Conventions (docs/architecture/0002-time-and-missing-data.md):
--   * every event time is stored as <name>_at_utc + <name>_time_zone + <name>_utc_offset_minutes;
--   * every optional measured input has a value column and a *_missing_reason column,
--     and exactly one of them is set;
--   * every column here must have a row in docs/privacy/data-inventory.md.

BEGIN;

CREATE TABLE users (
    id                  uuid        PRIMARY KEY,
    home_time_zone      text        NOT NULL CHECK (char_length(home_time_zone) BETWEEN 1 AND 64),
    -- The user's own goal; NULL until the user sets it. Never defaulted silently.
    sleep_goal_minutes  smallint    CHECK (sleep_goal_minutes BETWEEN 180 AND 900),
    created_at_utc      timestamptz NOT NULL DEFAULT now(),
    updated_at_utc      timestamptz NOT NULL DEFAULT now()
);

-- Append-only log of consent decisions for external data sources
-- (docs/architecture/0003-privacy-and-consent.md). Revocation is a new row.
CREATE TABLE consent_decisions (
    id                          uuid        PRIMARY KEY,
    user_id                     uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    source_id                   text        NOT NULL CHECK (source_id IN ('apple_health', 'health_connect')),
    state                       text        NOT NULL CHECK (state IN ('granted', 'revoked')),
    scopes                      text[]      NOT NULL DEFAULT '{}',
    policy_version              text        NOT NULL CHECK (char_length(policy_version) BETWEEN 1 AND 32),
    decided_at_utc              timestamptz NOT NULL,
    decided_time_zone           text        NOT NULL CHECK (char_length(decided_time_zone) BETWEEN 1 AND 64),
    decided_utc_offset_minutes  smallint    NOT NULL CHECK (decided_utc_offset_minutes BETWEEN -840 AND 840),
    created_at_utc              timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT consent_decisions_scopes_match_state CHECK (
        (state = 'granted' AND cardinality(scopes) > 0 AND scopes <@ ARRAY['sleep_duration']::text[])
        OR (state = 'revoked' AND cardinality(scopes) = 0)
    )
);

CREATE INDEX consent_decisions_user_source_decided_idx
    ON consent_decisions (user_id, source_id, decided_at_utc DESC);

CREATE FUNCTION consent_decisions_forbid_update() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'consent_decisions is append-only; insert a new decision instead'
        USING ERRCODE = 'restrict_violation';
END;
$$;

CREATE TRIGGER consent_decisions_append_only
    BEFORE UPDATE ON consent_decisions
    FOR EACH ROW EXECUTE FUNCTION consent_decisions_forbid_update();

-- Manual check-ins. IDs are generated on the device (offline-first).
CREATE TABLE check_ins (
    id                                    uuid        PRIMARY KEY,
    user_id                               uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    recorded_at_utc                       timestamptz NOT NULL,
    recorded_time_zone                    text        NOT NULL CHECK (char_length(recorded_time_zone) BETWEEN 1 AND 64),
    recorded_utc_offset_minutes           smallint    NOT NULL CHECK (recorded_utc_offset_minutes BETWEEN -840 AND 840),

    self_reported_energy                  smallint    CHECK (self_reported_energy BETWEEN 1 AND 5),
    self_reported_energy_missing_reason   text        CHECK (self_reported_energy_missing_reason IN
        ('not_recorded', 'user_skipped', 'no_consent', 'source_unavailable', 'not_yet_synced')),

    sleep_duration_minutes                smallint    CHECK (sleep_duration_minutes BETWEEN 0 AND 1440),
    sleep_duration_source                 text        CHECK (sleep_duration_source IN ('manual_check_in', 'apple_health', 'health_connect')),
    sleep_duration_missing_reason         text        CHECK (sleep_duration_missing_reason IN
        ('not_recorded', 'user_skipped', 'no_consent', 'source_unavailable', 'not_yet_synced')),

    version                               integer     NOT NULL DEFAULT 1 CHECK (version >= 1),
    created_at_utc                        timestamptz NOT NULL DEFAULT now(),
    updated_at_utc                        timestamptz NOT NULL DEFAULT now(),
    -- Tombstone so deletions synchronize like any other change.
    deleted_at_utc                        timestamptz,

    CONSTRAINT check_ins_energy_present_xor_missing CHECK (
        (self_reported_energy IS NULL) <> (self_reported_energy_missing_reason IS NULL)
    ),
    CONSTRAINT check_ins_sleep_present_xor_missing CHECK (
        (sleep_duration_minutes IS NULL) <> (sleep_duration_missing_reason IS NULL)
    ),
    CONSTRAINT check_ins_sleep_source_iff_present CHECK (
        (sleep_duration_minutes IS NULL) = (sleep_duration_source IS NULL)
    )
);

CREATE INDEX check_ins_user_recorded_idx ON check_ins (user_id, recorded_at_utc DESC);
CREATE INDEX check_ins_user_updated_idx ON check_ins (user_id, updated_at_utc);

-- Idempotency log for sync (docs/architecture/0004-offline-first-idempotent-sync.md).
-- Insert in the same transaction as the change it records.
CREATE TABLE applied_sync_operations (
    operation_id         uuid        PRIMARY KEY,
    user_id              uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    entity_type          text        NOT NULL CHECK (entity_type ~ '^[a-z][a-z0-9_]{0,62}$'),
    entity_id            uuid        NOT NULL,
    payload_fingerprint  text        NOT NULL,
    result               jsonb       NOT NULL,
    applied_at_utc       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX applied_sync_operations_user_applied_idx
    ON applied_sync_operations (user_id, applied_at_utc);

COMMIT;
