# Desktop Execution API implementation

The FastAPI module at `be/src/agonez_api/modules/execution/` implements the UI-oriented
contract under `/api/v1/exec`. It follows the existing application shape:

```text
router.py -> service.py -> repository.py -> PostgreSQL
               |
               +-> domain.py (shared derived rules)
```

`schemas.py` owns explicit request/response DTOs and enums. `errors.py` owns the stable
Execution error envelope. The app factory wires one repository and service against the
existing async Psycopg pool.

## Compatibility assessment

The storage model directly supports run, microcycle, session, track, prescription,
performance, set, event, and load-history reads. The existing views validate the intended
grain, but the API bulk-loads the normalized rows because its payloads combine several
views and also need plan-source metadata.

Application aggregation is required for overview, queue, exercise trace, workout matrix,
timeline, calendar, event positioning, and load series. The following contract rules are
application-owned rather than new persisted domain concepts:

- current run/microcycle position and attendance;
- prescription completeness and divergence flags;
- authoritative next target/basis/readiness resolution;
- revision slot-change comparison;
- lazy workout-prescription creation and prescription snapshotting;
- automatic missed-session reconciliation;
- deload/reload event creation and event provenance;
- optimistic concurrency and lifecycle transition validation.

Migration `0007_execution_api_versions.sql` adds only `updated_at` to the two mutable
prescription tables. It creates no new domain entity and no index. Run and microcycle rows
already had suitable versions. Event provenance is stored in reserved metadata key
`_source` and projected as top-level `source`; the reserved key is removed from public
`metadata`.

## Read and transaction strategy

A run read uses one `RunBundle`: bounded bulk queries load the run, microcycles, tracks,
sessions, prescription/performance trees, events, and the small set of governing plan
revisions. Services then build screen DTOs without per-row SQL calls.

Preview and creation use the same day-count/date projection functions. Creation is one
transaction materializing the run, concrete microcycles, run-scoped tracks, sessions, and
the system `run_created` observation.

The prescription PUT is one transaction. It locks the target session, reloads current
state, calls the shared readiness resolver, checks target and basis, validates set ordinals
and loads, lazily creates the workout snapshot, upserts the exercise snapshot, and replaces
its set rows from the target revision. All prescription mutations first require the session
to remain `scheduled`.

## Readiness resolver

`domain.resolve_next()` is the sole implementation used by queue reads, exercise-trace
reads, the standalone `next` read, and the prescription transaction. It selects the latest
finalized exercise performance as basis, then the earliest later scheduled occurrence of
the same workout track as target. Run state and intervening in-progress state are evaluated
in contract order. Missed and cancelled occurrences do not block. A started saved final
occurrence is exposed as `locked` when no later scheduled target exists.

The contract's `previous_exposure_not_performed` condition is retained in the resolver.
Under the literal target definition, the earliest scheduled prescribed occurrence is itself
the target, so it is editable rather than an intervening occurrence; the reason becomes
observable only if target selection is later extended to a requested future occurrence.

## Concurrency

Versions are RFC 3339 strings produced from row `updated_at`. Mutations lock the row,
compare `expected_version`, and return `409 version_conflict` with `details.current`.

The supplied contract requires a version for the workout-comment PATCH but does not expose
that resource's version in any read DTO. The implementation therefore adds the documented
field `next.prescription.workout_prescription_version`. This is the only response-field
extension. The PATCH response also returns its new version.

## Missed sessions

There is no scheduler subsystem in the backend. Every run-scoped read first performs one
central reconciliation transaction:

- a scheduled run whose start date has arrived becomes active;
- a past scheduled session with no performance becomes missed.

The plan-run list performs the same reconciliation for all runs. Consequently every API
screen observes the same stored state rather than applying local display-only projections.

## Revision transitions and metrics

Exercise transitions compare consecutive microcycles' source plan slots/variants/sets by
the stable run-scoped track's day and slot keys. Changes are emitted as `plan_comment`,
`exercise`, `set_count`, `rep_range`, `target_rir`, and `role`. No redundant transition
detail is persisted.

Load analytics use finalized exercise/set facts. Substitutions and skipped exercises emit
null points, missed/cancelled sessions emit no point, and no case fabricates a zero. MARKER.X
and automated progression remain `null`/unimplemented.

## Contract deviations and clarifications

- `seed_loads_from_plan_run_id` is intentionally omitted from v1. It is optional in the
  contract and would add no value to the core readiness/write flow yet.
- `current_plan.load_step_kg` is `null`: neither `plans` nor `exec` stores a load increment.
- `next.prescription.workout_prescription_version` is the concurrency extension described
  above.
- Obvious resource-not-found and malformed-filter failures add stable codes such as
  `plan_run_not_found`, `workout_trace_not_found`, `microcycle_not_found`, `event_not_found`,
  `invalid_limit`, and `request_validation`; documented contract codes remain unchanged.
- Plan revision transition authoring, mobile start/finalize, fallback authoring, identity,
  MARKER.X, and automated progression remain outside this release.

## Endpoint audit

| Contract endpoint | Status |
| --- | --- |
| `GET /plan-runs` | implemented |
| `GET /plan-runs/preview` | implemented |
| `POST /plan-runs` | implemented; optional seed-load field omitted |
| `GET /plan-runs/{id}/overview` | implemented |
| `PATCH /plan-runs/{id}` | implemented |
| `GET /plan-runs/{id}/analysis/queue` | implemented |
| `GET /plan-runs/{id}/exercise-traces/{trace}` | implemented |
| `GET /plan-runs/{id}/exercise-traces/{trace}/next` | implemented |
| `PUT /plan-runs/{id}/sessions/{session}/exercise-prescriptions/{trace}` | implemented |
| `DELETE /plan-runs/{id}/sessions/{session}/exercise-prescriptions/{trace}` | implemented |
| `PATCH /plan-runs/{id}/sessions/{session}/prescription` | implemented with documented version-field extension |
| `GET /plan-runs/{id}/workout-traces` | implemented |
| `GET /plan-runs/{id}/workout-traces/{trace}` | implemented |
| `GET /plan-runs/{id}/microcycles` | implemented |
| `PATCH /plan-runs/{id}/microcycles/{ordinal}` | implemented |
| `GET /plan-runs/{id}/calendar` | implemented |
| `PATCH /plan-runs/{id}/sessions/{session}` | implemented |
| `GET /plan-runs/{id}/events` | implemented |
| `POST /plan-runs/{id}/events` | implemented |
| `PATCH /plan-runs/{id}/events/{event}` | implemented |
| `DELETE /plan-runs/{id}/events/{event}` | implemented |
| `GET /plan-runs/{id}/load-series` | implemented |

## Verification

Default tests cover projection, readiness order, first exposure, missed/cancelled handling,
locked/no-target/run-state cases, divergence, attendance, completeness, load validation,
event restrictions, OpenAPI routes, and all pre-existing backend tests.

`be/tests/live_execution_api_scenarios.py` is the opt-in seeded acceptance flow. It reads
the overview and queue, opens the Bench Press trace across revisions, saves the valid next
prescription, reloads it, verifies a stale write conflict, removes the temporary save, and
loads workout trace, timeline, calendar, events, and load analytics.
