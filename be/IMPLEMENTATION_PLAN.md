# Agonez Backend Implementation Plan

Status: complete implementation and handoff record (2026-08-10)  
Scope: public Atlas API; no authentication or per-user state

## Context verified

- Frontend contract: the attached `api-contract.md` (v0.1).
- PostgreSQL: database `agonez_db`, exposed on host port `33327`.
- Credentials: user must come from `NOME`; password must come from `AGANDSKODE`.
- Source schemas: `core.exercises`, `core.muscles`, `core.muscle_exercise_mappings`, and optional evaluation data in `engine.exercises`.
- Existing reference service: `/home/jacques` uses independently deployable services, factory wiring, repository/service/HTTP separation, direct psycopg access, health checks, and Docker images.
- Existing exercise artwork is present in `/home/agonez/media/exercises`; this service will define a portable `media/` contract so content can be mounted or copied without database changes.

## Architecture

One independently deployable FastAPI service now, with module boundaries that can later be split into services:

```text
be/
  src/agonez_api/
    app.py                 # application factory and lifespan
    main.py                # ASGI entry point
    core/                  # settings, database pool, logging, errors
    modules/
      atlas/               # public Atlas router/service/repository/schemas
      plans/               # reserved package boundary (future, authenticated)
  media/
    exercises/             # {exercise_slug}.{png|webp|jpg|jpeg|avif}
    muscles/               # {muscle_slug}.{png|webp|jpg|jpeg|avif}
    galleries/muscles/     # {muscle_slug}/{ordered gallery files}
  tests/
  Dockerfile
  compose.yml
  pyproject.toml
```

The Atlas HTTP layer depends on an Atlas service, which depends on an Atlas repository. Database SQL and schema knowledge stay in the repository. Media URL resolution is isolated from the database so images can live in a bind mount, object store, or CDN later.

## API work

1. Implement `/api/atlas/exercises` with repeatable filters, validated sorting, pagination, facets, engine-vector presence, and slug-based image URLs.
2. Implement `/api/atlas/exercises/{slug}` with the core vector and the optional engine vector bundle. Preserve the distinction between `null` (not evaluated) and `{}` (evaluated but empty).
3. Implement `/api/atlas/muscles` with repeatable filters, sorting, pagination, facets, display names, and image URLs.
4. Implement `/api/atlas/muscles/{slug}` with all morphology, architecture, programming, article/video, gallery, and image fields.
5. Implement related exercises from measured `engine.exercises.etu_vector` entries, followed by conservative target-category fallbacks.
6. Implement `/api/atlas/meta`, `/health/live`, and `/health/ready`.
7. Mount media at `/media`, expose `media/anatomy.svg` at `/assets/anatomy.svg`, and
   return `null` for absent files; never advertise broken URLs.

## Configuration and deployment

- Required exported shell variables: `NOME`, `AGANDSKODE`, `MINA`, and `MAMMOONE`.
- Database port: `MINA` (`DB_PORT` remains a direct-deployment fallback); database name
  defaults to `agonez_db` and host to `127.0.0.1`.
- API host port: `MAMMOONE`; the container continues listening on port 8000.
- Compose inherits variables exported by the invoking shell (for example via `.bashrc`)
  and does not use an `env_file`.
- Docker Compose uses `host.docker.internal` plus Linux `host-gateway` to reach the already-running PostgreSQL host port.
- Runtime image: unprivileged user, health check, deterministic dependency install, one Uvicorn worker by default (configurable).
- CORS origins and public media base URL are environment-configurable for the future Vue deployment.

## Verification checklist

- Unit tests for media resolution, response shaping, settings validation, and related-exercise logic.
- Static/type/style checks via Ruff and mypy where practical.
- Import/startup test without opening a database connection.
- Live smoke tests against the PostgreSQL host port resolved from `MINA` when
  local tooling/container access permits.
- Docker image build and container health smoke test when Docker daemon access permits.
- Compare OpenAPI response models and query parameters against all six contract sections.

## Handoff notes

- Do not add authentication to Atlas. Future `plans`/dashboard modules should use a separate router/service boundary and can become separate images without changing Atlas URLs.
- Do not bake credentials into the image, Compose file, examples, logs, or DSNs shown in errors.
- Keep `media/` writable by the operator but read-only inside the API container.
- The database dump is descriptive, not an application migration: this API must not
  recreate the existing database. The one approved mutation is appending validated
  YouTube links to `core.exercises.video_links`.

## Verification results

- `pytest`: 19 passed after the video endpoint addition.
- `ruff check .`: passed.
- strict `mypy src`: passed with no issues across 17 source files.
- Live PostgreSQL validation: all repository/service queries passed against 49 exercises,
  47 muscles, and the available engine rows.
- End-to-end HTTP validation: lists, filters, sorting, both details, related exercises,
  metadata, 404 behavior, an exercise PNG, and the anatomy SVG all returned expected
  statuses and content types.
- Docker: final image built from the pinned runtime lock, started as an unprivileged
  user, reached the host PostgreSQL port, served media from the read-only bind mount,
  and reported healthy. The configured role has `UPDATE` permission on the exercise
  `video_links` column. The image is tagged `agonez-atlas-api:local`; temporary
  validation containers were removed.

## Progress

- [x] Inspect design handoff, API contract, database dump, repository, and Jacques conventions.
- [x] Decide service boundaries and deployment approach.
- [x] Implement application and Atlas endpoints.
- [x] Add media directories and deployment artifacts.
- [x] Run automated, live-database, HTTP, and Docker validation.

## Post-v0.1 video feature

- [x] Add a YouTube-only, canonicalizing exercise-video write endpoint.
- [x] Deduplicate short/watch/embed variants by video ID.
- [x] Keep media and future per-user modules outside this mutation boundary.

## Post-v0.1 muscle galleries

- [x] Resolve ordered supported images from
  `media/galleries/muscles/{slug}/` on the muscle detail endpoint.
- [x] Keep gallery enumeration detail-only so list browsing does not scan or transfer
  unused image collections.

## PlanCreator foundation (2026-08-17)

- [x] Audit the existing Psycopg/FastAPI architecture and live catalog key types.
- [x] Document the PlanCreator domain boundary and the temporary public/no-owner model.
- [x] Add checksum-tracked, transactional SQL migrations and the relational `plans`
  schema.
- [x] Add Plan, DRAFT revision, day, optional workout unit, stable slot, target muscle,
  exercise variant, and set infra-prescription persistence.
- [x] Add nested create/list/detail/delete/draft load/draft save endpoints.
- [x] Reconcile children by stable ID inside one transaction and reject foreign IDs.
- [x] Add optimistic concurrency with `lock_version` and HTTP 409 responses.
- [x] Add Pydantic/domain constraints for ordinals, slugs, variants, rep ranges, and RIR.
- [x] Run Ruff, strict mypy, and 26 unit/contract tests successfully.
- [x] Run all 12 required live API/database scenarios successfully, including cascade
  verification, against PostgreSQL 15 and remove the temporary plans.
- [x] Rebuild and deploy `agonez-atlas-api:local`; startup applied
  `0001_plancreator_foundation.sql` and the container reports healthy.

Intentionally deferred: authentication/ownership, draft release, snapshots, resolver,
analyzers, Analysis/Modulation tabs, macrocycles, PlanExecution, and progression.

## PlanCreator Analysis V1 (2026-08-18)

Status: complete implementation and deployed handoff

### Reconnaissance findings

- Analysis remains request-time derived data. No migration or analysis persistence is
  required.
- The persisted source aggregate is the existing DRAFT revision and its ordered day,
  optional workout-unit, stable slot, target-muscle, variant, and set rows.
- All 49 current `engine.exercises` rows have non-null, non-empty JSON objects for ETU,
  active tension, recovery modifiers, and joint load. Per exercise, the three muscle
  vector key sets align exactly.
- Muscle-vector keys are the 47 canonical `core.muscles.slug` values. Joint vectors use
  11 observed canonical slugs; no separate joint catalog exists yet.
- Observed value ranges are: ETU 0.48–179.19, active tension 0.60–155.82,
  recovery modifier 0.95–1.15, and joint load 0.06–0.90.
- All 47 muscles currently have positive authoritative projected FCSA values
  (`pcsa_projected_fcsa_cm2`), ranging from 4.50 to 243.17 cm².
- Production data is complete today, but the evaluator will still emit per-vector
  diagnostics and partial results if future catalog rows are incomplete.

### Planned architecture

```text
Persisted PlanDraft + engine/FCSA snapshot
  -> PlanResolver (DEFAULT variant and active volume-level sets)
  -> immutable ResolvedPlan
  -> contribution evaluator (ETU, MRU, JRU with provenance)
  -> 168-hour periodic recovery simulator
  -> separate PlanAnalysisResult API response
```

- Add a read-only, consistent repository snapshot for draft plus relevant engine and
  muscle rows.
- Keep analysis DTOs, domain objects, calibration parameters, resolver, evaluator, and
  service in a dedicated `plans.analysis` boundary.
- Add `POST /api/plans/{plan_id}/draft/analysis`; it will not mutate the draft or its
  lock version.
- Include ordered rest days, explicit timing assumptions, model parameters, summaries,
  per-day before/after recovery snapshots, contribution provenance, and diagnostics.
- Calibrate the two global V1 velocities from real catalog exercises with a reproducible
  read-only utility and preserve the raw anchor output in the handoff documentation.

### Verification plan

- Deterministic unit coverage for resolution, formulas, classification, cumulative
  penalties, volume gating, provenance, linear decay, periodic convergence/divergence,
  diagnostics, immutability, and model version.
- Contract/OpenAPI and mocked endpoint coverage plus a live persisted-draft analysis.
- Full pytest, Ruff, strict mypy, Docker rebuild, health check, and live endpoint smoke.

Explicitly out of scope: Analysis frontend, modulation UI/policy, non-local fatigue
models, execution data, progression, persisted/cached results, and automatic plan edits.

### Implementation progress

- [x] Add repeatable-read, read-only draft + engine/FCSA source snapshot.
- [x] Add immutable DEFAULT-only resolver with volume gating and weekly timing.
- [x] Add explainable ETU/MRU/JRU evaluator and contribution provenance.
- [x] Add periodic 168-hour muscle/joint recovery simulation and divergence diagnostics.
- [x] Add separate Analysis V1 request/response models and POST endpoint.
- [x] Calibrate and freeze real-catalog V1 velocities with a reproducible utility.
- [x] Add deterministic unit/contract coverage and full implementation handoff.
- [x] Rebuild/deploy the backend and complete live HTTP verification.

Final result: 34 tests, Ruff, strict mypy, calibration reproduction, and all 13 live
PlanCreator scenarios passed. The rebuilt `be-atlas-api-1` container is healthy on host
port 33287. Existing plan 6 returns a fully explainable result plus an explicit
`RECOVERY_DIVERGENCE` diagnostic (20 muscles and 7 joints), which is preserved for manual
calibration review rather than clamped.
