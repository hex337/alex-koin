#!/bin/bash

# fail if we error out
set -e

mix local.rebar --force

# Wait for mysql to come up
until psql -h db -U "postgres" -c '\q' 2>/dev/null; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

# call the command that the compose defines
exec "$@"
