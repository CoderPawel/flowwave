#!/usr/bin/env bash
# Verifies the Prisma migrations in apps/api/prisma/migrations:
#   1. reverts migrations applied by a previous run (their down.sql, newest first),
#   2. applies all migrations with `prisma migrate deploy`,
#   3. checks that the database matches schema.prisma (no drift),
#   4. runs the SQL constraint tests in db/tests,
#   5. reverts everything with the down.sql files and checks nothing is left,
#   6. applies each migration with psql and checks that its down.sql restores
#      exactly the schema from before it (compared with pg_dump),
#   7. applies the migrations again, leaving a migrated database behind.
# Requires psql, pg_dump, `npm ci`, and DATABASE_URL pointing at a disposable database.
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
  local tracked
  tracked=$("${PSQL[@]}" -tA -c "SELECT to_regclass('_prisma_migrations') IS NOT NULL")
  if [[ "$tracked" == "t" ]]; then
    for name in $("${PSQL[@]}" -tA -c "SELECT migration_name FROM _prisma_migrations
        WHERE finished_at IS NOT NULL AND rolled_back_at IS NULL ORDER BY migration_name DESC"); do
      echo "revert $name"
      "${PSQL[@]}" -f "$MIGRATIONS_DIR/$name/down.sql"
    done
  fi
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

schema_dump() {
  pg_dump --schema-only --no-owner --no-privileges "$DATABASE_URL" | grep -v -E '^\\(un)?restrict '
}

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT
migrations=($(ls -d "$MIGRATIONS_DIR"/*/ | sort))
for index in "${!migrations[@]}"; do
  schema_dump > "$workdir/before_$index.sql"
  "${PSQL[@]}" --single-transaction -f "${migrations[$index]}migration.sql"
done
for (( index=${#migrations[@]}-1; index>=0; index-- )); do
  "${PSQL[@]}" -f "${migrations[$index]}down.sql"
  echo "check  ${migrations[$index]}down.sql restores the previous schema"
  if ! schema_dump | diff -u "$workdir/before_$index.sql" - ; then
    echo "${migrations[$index]}down.sql does not restore the schema from before the migration." >&2
    exit 1
  fi
done

prisma migrate deploy
echo "Migrations verified."
