BEGIN;

DROP TABLE IF EXISTS applied_sync_operations;
DROP TABLE IF EXISTS check_ins;
DROP TRIGGER IF EXISTS consent_decisions_append_only ON consent_decisions;
DROP TABLE IF EXISTS consent_decisions;
DROP FUNCTION IF EXISTS consent_decisions_forbid_update();
DROP TABLE IF EXISTS users;

COMMIT;
