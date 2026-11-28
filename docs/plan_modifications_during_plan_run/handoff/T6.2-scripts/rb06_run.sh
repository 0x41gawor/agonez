#!/usr/bin/env bash
# usage: rb06_run.sh <port> <db> <run_id>|<date> ...   — prescribe next targets, then the T6.2 copy of the mobile scenario
S="$(cd "$(dirname "$0")" && pwd)"; port=$1; db=$2; shift 2
ids=$(for spec in "$@"; do echo -n "${spec%|*} "; done)
(cd "$S" && python3 -I rb06_prepare.py "http://127.0.0.1:$port" $ids) | sed "s/^/$db /"
for spec in "$@"; do
  id=${spec%|*}; d=${spec#*|}; name=$("$S/q.sh" "$db" -At -c "SELECT name FROM exec.plan_runs WHERE id=$id")
  start=$(date +%s.%N)
  out=$(cd "$S/scenario" && MOBILE_API_ALLOW_DESTRUCTIVE_TEST=1 MOBILE_API_BASE_URL="http://127.0.0.1:$port" MOBILE_TEST_DATE="$d" MOBILE_TEST_PLAN_RUN="$name" /home/agonez/be/.venv/bin/python -I live_mobile_reordered.py 2>&1); rc=$?
  printf '%s run %s (date %s): rc=%s %.1fs | %s\n' "$db" "$id" "$d" "$rc" "$(echo "$(date +%s.%N)-$start" | bc)" "$(echo "$out" | tail -2 | paste -sd'|')"
done
