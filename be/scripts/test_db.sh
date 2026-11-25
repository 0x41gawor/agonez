#!/usr/bin/env bash
# Disposable PostgreSQL 15 for the integration tests (`pytest -m integration`).
#
#   eval "$(scripts/test_db.sh)"     start (or reuse) and export the connection variables
#   scripts/test_db.sh stop          remove the container and all of its data
#
# The server listens on 127.0.0.1 only, on a random port, with a random password, and keeps
# its data in memory. Set AGONEZ_TEST_DB_CONTAINER (prefix `agonez-it-`) to run a second one
# next to the default, for example one per git worktree.
set -euo pipefail

readonly IMAGE="postgres:15"
# tests/integration/conftest.py refuses to use a container without this label.
readonly LABEL="agonez.integration-test"
readonly CONTAINER="${AGONEZ_TEST_DB_CONTAINER:-agonez-it-db}"
readonly DB_USER="postgres"
readonly STARTUP_WAIT_SECONDS=60

die() {
    echo "test_db.sh: $*" >&2
    exit 1
}

container_exists() {
    docker container inspect "$CONTAINER" >/dev/null 2>&1
}

require_own_container() {
    local label
    label="$(docker container inspect -f "{{ index .Config.Labels \"$LABEL\" }}" "$CONTAINER")"
    [[ "$label" == "true" ]] || die "container '$CONTAINER' was not created by this script"
}

start() {
    if container_exists; then
        require_own_container
        if [[ "$(docker container inspect -f '{{.State.Running}}' "$CONTAINER")" != "true" ]]; then
            docker rm -f -v "$CONTAINER" >/dev/null
        fi
    fi

    if ! container_exists; then
        local new_password
        new_password="$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')"
        # `-e POSTGRES_PASSWORD` without a value keeps the password off the command line.
        POSTGRES_PASSWORD="$new_password" docker run --detach --rm \
            --name "$CONTAINER" \
            --label "$LABEL=true" \
            --env POSTGRES_PASSWORD \
            --publish 127.0.0.1::5432 \
            --tmpfs /var/lib/postgresql/data \
            "$IMAGE" -c fsync=off >/dev/null
        echo "test_db.sh: started $IMAGE as '$CONTAINER'" >&2
    fi

    # The image first runs a temporary server on the Unix socket only, so ask over TCP.
    local attempt
    for ((attempt = 1; attempt <= STARTUP_WAIT_SECONDS; attempt++)); do
        if docker exec "$CONTAINER" pg_isready -q -h 127.0.0.1 -U "$DB_USER"; then
            break
        fi
        ((attempt < STARTUP_WAIT_SECONDS)) || die "PostgreSQL in '$CONTAINER' did not become ready"
        sleep 1
    done

    local password port
    password="$(docker container inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$CONTAINER" |
        sed -n 's/^POSTGRES_PASSWORD=//p')"
    port="$(docker port "$CONTAINER" 5432/tcp | sed -n 's/^127\.0\.0\.1:\([0-9]\+\)$/\1/p')"
    [[ -n "$password" && -n "$port" ]] || die "could not read the connection data of '$CONTAINER'"

    echo "export AGONEZ_TEST_DATABASE_URL='postgresql://$DB_USER:$password@127.0.0.1:$port/postgres'"
    echo "export AGONEZ_TEST_DB_CONTAINER='$CONTAINER'"
}

stop() {
    if ! container_exists; then
        echo "test_db.sh: no container '$CONTAINER'" >&2
        return
    fi
    require_own_container
    docker rm -f -v "$CONTAINER" >/dev/null
    echo "test_db.sh: removed '$CONTAINER'" >&2
}

[[ "$CONTAINER" == agonez-it-* ]] || die "AGONEZ_TEST_DB_CONTAINER must start with 'agonez-it-'"

case "${1:-start}" in
    start) start ;;
    stop) stop ;;
    *) die "usage: test_db.sh [start|stop]" ;;
esac
