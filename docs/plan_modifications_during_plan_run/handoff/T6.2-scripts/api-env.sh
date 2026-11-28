# Source with: . api-env.sh <db_name>   — points the API settings at the scratch container agonez-it-t62 ONLY
_S="$(dirname "${BASH_SOURCE[0]}")"
. "$_S/env-t62.sh"
_rest="${AGONEZ_TEST_DATABASE_URL#postgresql://}"
export NOME="${_rest%%:*}"
_rest="${_rest#*:}"; export AGANDSKODE="${_rest%%@*}"
_rest="${_rest#*@127.0.0.1:}"; export MINA="${_rest%%/*}"
export DB_HOST=127.0.0.1 DB_NAME="${1:-agonez_db}"
case "$MINA" in 33327|3421) echo "REFUSING: production port" >&2; return 1;; esac
[ "$(docker port agonez-it-t62 5432/tcp)" = "127.0.0.1:$MINA" ] || { echo "REFUSING: port is not agonez-it-t62" >&2; return 1; }
unset _rest
