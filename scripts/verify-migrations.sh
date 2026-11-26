#!/usr/bin/env bash
# Applies every up migration, runs the schema tests, rolls everything back with
# the down migrations, and applies the up migrations again to prove they are
# reversible. Requires psql and DATABASE_URL pointing at a disposable database.
set -euo pipefail

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "DATABASE_URL must point to a disposable PostgreSQL database." >&2
  exit 1
fi

cd "$(dirname "$0")/.."
PSQL=(psql "$DATABASE_URL" --quiet --no-psqlrc -v ON_ERROR_STOP=1)

apply_up() {
  for file in $(ls db/migrations/*.up.sql | sort); do
    echo "apply  $file"
    "${PSQL[@]}" -f "$file"
  done
}

apply_down() {
  for file in $(ls db/migrations/*.down.sql | sort -r); do
    echo "revert $file"
    "${PSQL[@]}" -f "$file"
  done
}

run_tests() {
  for file in $(ls db/tests/*.test.sql 2>/dev/null | sort); do
    echo "test   $file"
    "${PSQL[@]}" -f "$file"
  done
}

apply_up
run_tests
apply_down

remaining=$("${PSQL[@]}" -tA -c "SELECT count(*) FROM pg_tables WHERE schemaname = 'public'")
if [[ "$remaining" != "0" ]]; then
  echo "Down migrations left $remaining table(s) in the public schema." >&2
  exit 1
fi

apply_up
echo "Migrations verified."
