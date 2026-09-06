#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="${SCRIPT_DIR}/be"
FRONTEND_DIR="${SCRIPT_DIR}/web-fe"
MODE="${1:-all}"

usage() {
  cat <<'EOF'
Usage: ./redeploy.sh [all|backend|frontend]

  all       Rebuild backend, then frontend (default)
  backend   Rebuild only the FastAPI service
  frontend  Rebuild only the Vue/nginx service
EOF
}

case "${MODE}" in
  all | backend | frontend) ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown deployment target: ${MODE}" >&2
    usage >&2
    exit 2
    ;;
esac

required_variables=(MAMMOONE)
if [[ "${MODE}" == "all" || "${MODE}" == "backend" ]]; then
  required_variables+=(NOME AGANDSKODE MINA)
fi
if [[ "${MODE}" == "all" || "${MODE}" == "frontend" ]]; then
  required_variables+=(MERSAA)
fi

missing_variables=()
for variable_name in "${required_variables[@]}"; do
  if [[ -z "${!variable_name:-}" ]]; then
    missing_variables+=("${variable_name}")
  fi
done

# Non-interactive scripts do not normally read ~/.bashrc. Re-enter once through an
# interactive shell when required variables are missing, so the user's exported
# Agonez settings become available without copying secrets into this script.
if ((${#missing_variables[@]})) && [[ -z "${AGONEZ_REDEPLOY_ENV_LOADED:-}" ]]; then
  export AGONEZ_REDEPLOY_ENV_LOADED=1
  exec bash -ic 'exec "$0" "$@"' "${BASH_SOURCE[0]}" "$@"
fi

if ((${#missing_variables[@]})); then
  echo "Missing required exported variables: ${missing_variables[*]}" >&2
  echo "Define them in ~/.bashrc or export them before running this script." >&2
  exit 1
fi

wait_for_url() {
  local label="$1"
  local url="$2"
  local attempts="${3:-45}"

  echo "Waiting for ${label}..."
  for ((attempt = 1; attempt <= attempts; attempt += 1)); do
    if curl --fail --silent --show-error --max-time 3 --output /dev/null "${url}" 2>/dev/null; then
      echo "${label} is ready: ${url}"
      return 0
    fi
    sleep 2
  done

  echo "Timed out waiting for ${label}: ${url}" >&2
  return 1
}

show_backend_diagnostics() {
  docker compose --project-directory "${BACKEND_DIR}" \
    --file "${BACKEND_DIR}/compose.yml" ps
  docker compose --project-directory "${BACKEND_DIR}" \
    --file "${BACKEND_DIR}/compose.yml" logs --tail 100 atlas-api
}

show_frontend_diagnostics() {
  docker compose --project-directory "${FRONTEND_DIR}" \
    --file "${FRONTEND_DIR}/compose.yml" ps
  docker compose --project-directory "${FRONTEND_DIR}" \
    --file "${FRONTEND_DIR}/compose.yml" logs --tail 100 atlas-web
}

deploy_backend() {
  echo "Rebuilding FastAPI backend..."
  docker compose --project-directory "${BACKEND_DIR}" \
    --file "${BACKEND_DIR}/compose.yml" up --detach --build atlas-api

  if ! wait_for_url "backend" "http://127.0.0.1:${MAMMOONE}/health/ready"; then
    show_backend_diagnostics
    return 1
  fi
}

deploy_frontend() {
  echo "Rebuilding Vue frontend..."
  docker compose --project-directory "${FRONTEND_DIR}" \
    --file "${FRONTEND_DIR}/compose.yml" up --detach --build atlas-web

  if ! wait_for_url "frontend" "http://127.0.0.1:${MERSAA}/"; then
    show_frontend_diagnostics
    return 1
  fi

  if ! wait_for_url "frontend API proxy" "http://127.0.0.1:${MERSAA}/health/ready"; then
    show_frontend_diagnostics
    show_backend_diagnostics
    return 1
  fi
}

case "${MODE}" in
  backend)
    deploy_backend
    ;;
  frontend)
    deploy_frontend
    ;;
  all)
    deploy_backend
    deploy_frontend
    ;;
esac

echo "Deployment completed successfully (${MODE})."
