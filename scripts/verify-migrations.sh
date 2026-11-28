#!/usr/bin/env bash
# Verifies the Prisma migrations in apps/api/prisma/migrations:
#   1. reverts anything left from a previous run (every down.sql, newest first),
#   2. applies all migrations with `prisma migrate deploy`,
#   3. checks that the database matches schema.prisma (no drift),
#   4. runs the SQL constraint tests in db/tests,
#   5. reverts everything with the down.sql files and checks nothing is left,
#   6. applies the migrations again, leaving a migrated database behind.
# Requires psql, `npm ci`, and DATABASE_URL pointing at a disposable database.
set -euo pipefail

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "DATABASE_URL must point to a disposable PostgreSQL database." >&2
  exit 1
fi

cd "$(dirname "$0")/.."
PSQL=(psql "$DATABASE_URL" --quiet --no-psqlrc -v ON_ERROR_STOP=1)
MIGRATIONS_DIR=apps/api/prisma/migrations

prisma() {
  npm exec --workspace @flowwave/api --no -- prisma "$@"
}

revert_all() {
  for file in $(ls "$MIGRATIONS_DIR"/*/down.sql | sort -r); do
    echo "revert $file"
    "${PSQL[@]}" -f "$file"
  done
  "${PSQL[@]}" -c 'DROP TABLE IF EXISTS "_prisma_migrations"'
}

for dir in "$MIGRATIONS_DIR"/*/; do
  if [[ ! -f "$dir/down.sql" ]]; then
    echo "Migration $dir has no down.sql." >&2
    exit 1
  fi
done

revert_all
prisma migrate deploy

echo "drift  schema.prisma vs database"
if ! prisma migrate diff --from-config-datasource --to-schema prisma/schema.prisma --exit-code; then
  echo "The migrated database does not match apps/api/prisma/schema.prisma." >&2
  exit 1
fi

for file in $(ls db/tests/*.test.sql | sort); do
  echo "test   $file"
  "${PSQL[@]}" -f "$file"
done

revert_all
leftovers=$("${PSQL[@]}" -tA -c "
  SELECT count(*) FROM (
    SELECT tablename FROM pg_tables WHERE schemaname = current_schema()
    UNION ALL SELECT typname FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace
      WHERE n.nspname = current_schema() AND t.typtype = 'e'
    UNION ALL SELECT proname FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = current_schema()
  ) AS objects")
if [[ "$leftovers" != "0" ]]; then
  echo "down.sql left $leftovers table(s), enum type(s) or function(s) behind." >&2
  exit 1
fi

prisma migrate deploy
echo "Migrations verified."
