#!/bin/bash
# Creates the pawa database for the Pawa Discord recording bot.
# This script runs automatically on first Postgres container init.
# If the container already has data, this script is skipped by Postgres.
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    SELECT 'CREATE DATABASE pawa' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'pawa')\gexec
    GRANT ALL PRIVILEGES ON DATABASE pawa TO $POSTGRES_USER;
EOSQL
