#!/usr/bin/env bash
# usage: q.sh <db> [psql args...]  — psql inside the scratch container agonez-it-t62 only
db="$1"; shift
exec docker exec -i agonez-it-t62 psql -X -v ON_ERROR_STOP=1 -U postgres -d "$db" "$@"
