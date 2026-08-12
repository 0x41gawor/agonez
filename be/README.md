# Agonez Atlas API

Public FastAPI service bridging the existing Agonez PostgreSQL database and the Vue 3
Atlas frontend. Atlas intentionally has no authentication or per-user state. Its only
mutation is the narrowly validated addition of YouTube demonstration links. The module
boundary leaves room for future authenticated Plans and Dashboard services.

The implementation and handoff record is in `IMPLEMENTATION_PLAN.md`. The supplied
frontend materials are preserved in `docs/api-contract.md` and
`docs/frontend-handoff.md` so later UI work has a local source of truth.

## Endpoints

- `GET /api/atlas/exercises`
- `GET /api/atlas/exercises/{slug}`
- `POST /api/atlas/exercises/{slug}/videos`
- `GET /api/atlas/muscles`
- `GET /api/atlas/muscles/{slug}`
- `GET /api/atlas/muscles/{slug}/exercises`
- `GET /api/atlas/meta`
- `GET /assets/anatomy.svg`
- `GET /health/live` and `GET /health/ready`
- Interactive OpenAPI: `GET /docs`

Repeat a filter key to select several values, for example:

```text
/api/atlas/exercises?body_part=Upper&body_part=Core&sort=load_capacity&order=desc
```

Pagination defaults to `page=1&per_page=50` and permits at most 100 rows per page.

## Configuration

`NOME`, `AGANDSKODE`, `MINA`, and `MAMMOONE` are required exported environment
variables. The database user and password come from `NOME` and `AGANDSKODE`, `MINA`
is the PostgreSQL host port, and `MAMMOONE` is the API host port. `DB_PORT` remains an
accepted compatibility fallback for direct Python deployments. Compose does not use an
`env_file`; see `environment.example` for a `.bashrc` template. Secrets are never baked
into the image or returned by health endpoints.
The Atlas connection enforces a 10-second statement timeout. The configured database
role needs `SELECT` access plus `UPDATE (video_links)` on `core.exercises` for the video
link feature.

The `.bashrc` assignments must use `export`, then be loaded in the current shell:

```bash
export NOME="database-user"
export AGANDSKODE="database-password"
export MINA=33327
export MAMMOONE=8000
source ~/.bashrc
```

## Local Python development

Python 3.10+ is supported.

```bash
python3 -m venv .venv
.venv/bin/pip install -e '.[dev]'
.venv/bin/uvicorn agonez_api.main:app --reload --host 0.0.0.0 --port "${MAMMOONE}"
```

Run checks:

```bash
.venv/bin/ruff check .
.venv/bin/mypy src
.venv/bin/pytest
```

## Docker deployment

Keep PostgreSQL listening on the host port stored in `MINA`, ensure the exported
variables are loaded in the current shell, then run:

```bash
docker compose up --build -d
docker compose ps
curl "http://127.0.0.1:${MAMMOONE}/health/ready"
```

Compose maps `host.docker.internal` to the Linux host gateway and explicitly passes the
exported variables into the container. It mounts `${MEDIA_HOST_PATH:-../media}` read-only at
`/app/media`; the current default therefore serves `/home/agonez/media/exercises`.
Production runtime dependencies are pinned in `requirements.lock`.

For a remote database, set `DB_HOST` and `MINA` and remove the `DB_HOST` override from
`compose.yml`, or deploy with equivalent orchestrator environment variables. The API
continues listening on port 8000 inside its container; Compose maps `MAMMOONE:8000`.
Put a reverse proxy in front of the `MAMMOONE` host port for TLS in production.

## Media contract

- Exercise hero: `media/exercises/{slug}.{supported_extension}`
- Muscle hero: `media/muscles/{slug}.{supported_extension}`
- Muscle gallery: `media/galleries/muscles/{slug}/*.{supported_extension}`
- Anatomy asset: `media/anatomy.svg`, exposed as `/assets/anatomy.svg`

Supported image extensions are AVIF, WebP, PNG, JPG, and JPEG. The API checks files
before generating URLs: missing hero images serialize as `null`, and missing galleries
as `[]`. Set `PUBLIC_MEDIA_BASE_URL` to return CDN URLs without changing database rows.

## Architecture

`agonez_api.app.create_app` wires infrastructure. `modules/atlas/router.py` owns HTTP
concerns, `service.py` owns response shaping and related-exercise policy, and
`repository.py` owns PostgreSQL SQL. `modules/plans/` is reserved only as a boundary;
when plans become user-specific it can acquire authentication or move to a separate
image without coupling that policy to Atlas.
