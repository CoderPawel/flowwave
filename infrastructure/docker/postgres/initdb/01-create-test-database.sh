#!/bin/sh
# Runs once, when the data volume is first created. The test database is
# disposable: migration verification drops and recreates everything in it.
set -eu

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-SQL
	CREATE DATABASE flowwave_test OWNER "$POSTGRES_USER";
SQL
