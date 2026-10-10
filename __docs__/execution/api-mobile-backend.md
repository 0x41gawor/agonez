# Mobile workout execution API

## Outcome and boundary

FastAPI exposes the offline-first workout execution surface under `/api/v1/mobile`. It
reuses the existing `exec` prescription, performance, session, trace, and Atlas facts rather
than creating a parallel workout domain. A finalized mobile workout is therefore immediately
visible to the desktop Execution trace reads.

This delivery is backend-only. It does not include Flutter code, authentication, athlete
ownership, push synchronization, or a server-side rest timer. `X-Agonez-Device-Id` is a
write-lease identity only and must not be treated as a user credential.

## Endpoint catalogue

| Method | Path | Status | Purpose |
| --- | --- | --- | --- |
| `GET` | `/api/v1/mobile/context` | Implemented | Selected run, today, week/microcycle days, expected session, alternatives, active workout, and recent results. |
| `GET` | `/api/v1/mobile/plan-runs` | Implemented | Compact run selector. |
| `GET` | `/api/v1/mobile/sessions/{session_id}/prescription` | Implemented | Immutable prescription plus history, alternatives, and offline Atlas peeks. |
| `POST` | `/api/v1/mobile/workouts` | Implemented | Idempotently start using a client-generated workout UUID. |
| `GET` | `/api/v1/mobile/workouts/active` | Implemented | Find the one resumable workout in a plan run. |
| `GET` | `/api/v1/mobile/workouts/{workout_id}` | Implemented | Authoritative prescription/performance snapshot. |
| `POST` | `/api/v1/mobile/workouts/{workout_id}/claim` | Implemented | Explicitly move the write lease to this device and start a new epoch. |
| `POST` | `/api/v1/mobile/workouts/{workout_id}/ops` | Implemented | Apply or acknowledge ordered offline operations. |
| `POST` | `/api/v1/mobile/workouts/{workout_id}/finalize` | Implemented | Atomically close the workout and session. |
| `GET` | `/api/v1/mobile/atlas/exercises/{exercise_id}/peek` | Implemented | Compact technique/body-map data for the workout UI. |
| `GET` | `/api/v1/mobile/atlas/exercises` | Implemented | Compact substitution search, optionally with run-local history. |

Every endpoint requires `X-Agonez-Device-Id`. `X-Agonez-Client` is optional but reserved for
client name/version diagnostics. Localized reads negotiate `Accept-Language`. Context and
workout snapshots return an `ETag` and honor `If-None-Match` with `304`.

## Reconciliation with the existing domain

The mobile contract's identities map to existing rows as follows:

```text
client workout UUID  -> exec.workout_unit_performances.client_uuid
client exercise UUID -> exec.exercise_unit_performances.client_uuid
client set UUID      -> exec.set_performances.client_uuid
server prescription ids remain the existing integer primary keys
```

Prescribed exercise-performance UUIDs are derived deterministically from the workout UUID and
exercise-prescription id. This lets a client address the full prescribed tree offline while
keeping retries stable. Truly unplanned exercises have no `exercise_unit_track_id` and store
the existing database enum value `additional`; the API deliberately renders that value as
`added`, matching the mobile contract without changing desktop semantics.

`prescription_version` is a deterministic SHA-256 digest of the ordered relational
prescription tree, not the timestamp of one row. Start locks the plan run, rechecks the
version, and freezes the current prescription by linking the draft performance to it. A stale
start returns `409 prescription_changed` with the fresh prescription embedded at
`error.details.prescription`.

The existing full Atlas article remains `/api/atlas/exercises/{slug}`. Mobile payloads always
carry both the stable catalog integer id and slug, so Flutter can reuse that route without a
second full-article implementation.

## Database extension

Migrations `0008` and `0009` extend, rather than replace, the Execution schema:

- add `not_performed` to exercise and set enums;
- add stable client UUIDs and entity revisions;
- add workout lease epoch/device, applied/final sequence, revision, and cursor fields;
- add set `performed_at`, server `received_at`, and `heart_rate_bpm`;
- permit a nullable exercise track only for a genuine unplanned exercise;
- add an append-only `exec.mobile_sync_ops` operation/audit log;
- enforce one draft/in-progress workout per plan run with a partial unique index;
- enforce unique performed ordering and client identity constraints.

Existing rows are backfilled with UUIDs, revisions, timestamps, and a sentinel legacy lease.
The lifecycle constraint is forced before columns become non-null, which keeps restoration and
upgrade of an existing database transactional. Enum additions are isolated in their own
migration because PostgreSQL cannot safely use a newly added enum value in the same
transaction.

## Ordered sync and conflicts

A workout has one `(lease_device_id, lease_epoch, applied_seq)` stream. The operations endpoint
accepts at most 200 operations, contiguous from the request's `base_seq + 1`, and serializes
writes by locking the workout row.

- Exact `(epoch, seq, op_id)` replays return `duplicate` without changing entity or workout
  revisions.
- Reusing a sequence with another operation id returns request-level `409 seq_mismatch`.
- A client ahead of the authoritative stream receives `409 seq_gap` and `expected_seq`.
- A lease moved to another device returns `409 superseded`; only an explicit claim can move it
  back.
- `if_rev` is entity-level optimistic concurrency. A stale write that already describes the
  current normalized state is accepted. A stale differing write is consumed as a per-operation
  `conflict`, allowing later operations in the same batch to continue.
- Product-rule violations such as substitution after performed sets are consumed as
  per-operation `rejected` results. There is no silent discard endpoint.

The implemented discriminated operation catalogue is:

```text
upsert_set, skip_set, clear_set, set_exercise_comment, skip_exercise,
substitute_exercise, add_unplanned_exercise, reorder_exercises,
set_cursor, set_workout_comment
```

All ten are implemented. `upsert_set` covers both prescribed and additional sets;
`skip_set`, `clear_set`, exercise/workout comments, deliberate exercise skip, plan/Atlas
substitution, unplanned exercise creation, complete-list reorder, and cursor updates each write
their corresponding normalized fact or resume hint. Substitution after a performed set is a
consumed per-operation rejection named `substitution_after_sets`, allowing later sequence
numbers to continue.

Set operations accept and persist `heart_rate_bpm`. Decimal scale and timezone offsets are
normalized before idempotent stale-state comparison.

## Finalization semantics

Finalization locks the workout, validates its lease and `final_seq`, and rejects pending ops.
When incomplete data exists it requires `acknowledged_incomplete=true`. It then materializes
any untouched prescribed exercise rows and every missing prescribed set as explicit
`not_performed`; `skipped` remains a separate athlete choice. In the same transaction it:

1. finalizes the workout performance;
2. completes the calendar session with existing completion mode `as_prescribed`;
3. records the final sequence and finish time;
4. returns counts for prescribed, performed, skipped, not-performed, additional,
   substitutions, skipped/added exercises, and reordered state.

Retrying the same finalization is idempotent. A different `final_seq` after completion is a
conflict. Off-schedule starts remain intentionally unsupported and return
`422 off_schedule_not_supported`; the reserved acknowledgement shape is accepted only so this
future rule can be introduced explicitly.

## Request-level error audit

| Code | Status | Notes |
| --- | --- | --- |
| `active_workout_exists` | Implemented, `409` | Includes the resumable workout id. |
| `prescription_changed` | Implemented, `409` | Includes the fresh prescription payload. |
| `session_not_startable` | Implemented, `409` | Includes the current session status. |
| `prescription_missing` | Implemented, `409` on read / `422` on start | Start can opt into unresolved nullable loads. |
| `off_schedule_not_supported` | Implemented, `422` | Reserved DTO accepted; semantics intentionally absent. |
| `seq_gap` | Implemented, `409` | Includes the authoritative next sequence. |
| `seq_mismatch` | Implemented, `409` | Detects both sequence reuse and global op-id misuse. |
| `superseded` | Implemented, `409` | Includes current epoch and device id. |
| `workout_finalized` | Implemented, `409` | Protects ops, claim, and incompatible finalize retry. |
| `workout_not_found` | Implemented, `404` | Lets an offline client send its queued start first. |
| `ops_pending` | Implemented, `409` | Includes current `applied_seq`. |
| `incomplete_not_acknowledged` | Implemented, `409` | Includes the unrecorded set count. |
| `substitution_after_sets` | Implemented as consumed op rejection | Returned in the operation result, as required by the ordered protocol. |

Malformed request DTOs use the same stable `request_validation` envelope. Additional diagnostic
codes cover missing plan/session/exercise resources, mismatched claim device ids, and a finish
time before workout start. Structural field failures are consumed operation rejections with
the contract codes (`load_out_of_range`, `reps_out_of_range`, `rir_out_of_range`,
`heart_rate_out_of_range`, `ordinal_conflict`, `unknown_prescription_ref`,
`prescription_ref_mismatch`, and `exercise_not_found`).

## Contract audit and intentional adaptations

| Contract area | Status | Implementation note |
| --- | --- | --- |
| Context, selector, prescription, active/snapshot | Implemented | Reads reconcile scheduled run/session state and expose localized DTOs. |
| Client-generated performance identities | Implemented | UUID constraints and deterministic prescribed exercise UUIDs. |
| Offline retry and operation audit | Implemented | Epoch/seq/op-id persistence, duplicates, gaps, mismatches, per-op outcomes. |
| Device takeover | Implemented | Explicit claim increments epoch and resets that epoch's sequence. |
| Full operation catalogue | Implemented | All ten discriminated operation types. |
| Finalize and incomplete acknowledgement | Implemented | Missing facts become `not_performed`; no fabricated performance values. |
| Atlas peek/search | Implemented | Reuses localized Atlas and engine muscle/ETU data. |
| Prescription with unresolved loads | Adapted | The read remains `200` with nullable loads so the athlete can inspect it; start still returns `422 prescription_missing` unless explicitly allowed. |
| `human.svg` / body-map v2 name | Adapted | Returns the installed `/assets/anatomy.svg` asset and its existing region ids; no nonexistent asset URL is invented. |
| API `added` execution mode | Adapted | Persisted as existing database value `additional`, rendered as `added`. |
| Full Atlas article | Reused with documented limitation | Flutter opens the existing slug route. It is not duplicated under `/mobile`; project-wide ETag support for that older route remains future work. |
| Off-schedule/fallback execution | Reserved | Context shape exists; start is rejected until product semantics are defined. |
| Authentication/athlete ownership | Deferred | Network restriction remains required. Device id is not authentication. |
| Server rest timer | Not applicable | Client-only by contract; `performed_at` preserves reconstructible intervals. |

The sync log has no time-based pruning in v1. Rows are retained for the life of the workout
aggregate and cascade only if that aggregate is deliberately deleted. Snapshots never replay
the log; they read normalized performance tables. A later retention policy may archive old
audit rows after operational/idempotency requirements are defined.

## Verification

Automated coverage validates the discriminated operation schema, ordered batches, normalized
conflict comparison, Atlas body-map adaptation, headers/OpenAPI surface, stable ETags, stale
prescription recovery, and the shared error envelope, in addition to all existing Atlas,
Plans, and desktop Execution regressions.

The migrations and HTTP workflow were also exercised against a PostgreSQL 15 database restored
from the 2026-10-08 Agonez backup. The disposable scenario covered:

- migration and legacy-row backfill;
- start and idempotent retry;
- offline batch apply and exact replay;
- sequence gap, sequence mismatch, entity conflict, and product rejection;
- second-device claim and old-lease rejection;
- performed/skipped/cleared/substituted/added/reordered operations including heart rate;
- incomplete-finalize refusal, acknowledged finalization, and finalize retry;
- ETag `304` handling;
- visibility of the finalized mobile data in the existing desktop exercise trace.

The executable version of that workflow is
`be/tests/live_mobile_execution_api_scenarios.py`. It refuses to run unless
`MOBILE_API_ALLOW_DESTRUCTIVE_TEST=1` is supplied because finalized demo sessions cannot be
losslessly rolled back. `be/tests/live_mobile_migration_checks.py` separately verifies the
applied migration checksums, enum values, required columns, UUID/operation uniqueness,
heart-rate constraint, operation-log foreign key, and partial active-workout index through the
PostgreSQL catalogue.

Run the local checks with:

```bash
.venv/bin/ruff check .
.venv/bin/mypy src
.venv/bin/pytest -q
```

The packaged migration runner applies the new files under the existing advisory lock and
refuses edited checksums. Deploy the API normally; migrations run before Uvicorn starts.
