#!/usr/bin/env bash
# usage: start_api.sh <be dir of the code to run> <scratch db name> <port> <log>
# Runs the container's start sequence (migrations, then uvicorn) against agonez-it-t62 only.
set -euo pipefail
S="$(cd "$(dirname "$0")" && pwd)"; BE="$1"; DB="$2"; PORT="$3"; LOG="$4"
. "$S/api-env.sh" "$DB"
export PYTHONPATH="$BE/src" MEDIA_ROOT="$S/api-run/media" WAITLIST_PATH="$S/api-run/waitlist.jsonl" ENVIRONMENT=t62-scratch
mkdir -p "$S/api-run/media"; cd "$S/api-run"
start=$(date +%s.%N)
/home/agonez/be/.venv/bin/python -m agonez_api.migrations
echo "migrations step: $(echo "$(date +%s.%N)-$start" | bc) s" >&2
exec /home/agonez/be/.venv/bin/uvicorn agonez_api.main:app --host 127.0.0.1 --port "$PORT" > "$LOG" 2>&1
