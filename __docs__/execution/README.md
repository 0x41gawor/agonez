# Execution domain overview

`exec` is the database boundary for a concrete athlete-like execution of a reusable
workout plan. The desktop workflow API is exposed under `/api/v1/exec`; user/athlete
identity remains intentionally deferred.

```text
plans: what the training program is
exec:  one concrete attempt to follow it over calendar time
```

## Repository discoveries

| Domain concept | Existing object | Execution consequence |
| --- | --- | --- |
| Plan | `plans.workout_plans` | Stable plan aggregate; not copied into `exec`. |
| Plan revision | `plans.plan_revisions` | A run stores its initial revision; each materialized microcycle stores the effective revision. |
| Microcycle duration | Count of `plans.day_prescriptions` rows in a revision | Snapshotted as `plan_runs.microcycle_duration_days`; no duration column exists in `plans`. |
| Plan day | `plans.day_prescriptions` | Session projection keeps the originating day FK. Ordinal, not weekday, defines offset. |
| Workout-unit | `plans.workout_unit_prescriptions` | Session projection keeps the source FK and maps it to a run-scoped workout track. |
| Exercise-slot | `plans.exercise_slots` | Becomes the source of an immutable execution exercise prescription snapshot. |
| Exercise-variant | `plans.exercise_variants` | Provides selected exercise, progression metadata, and `progression_id` lineage. |
| Set infrastructure | `plans.set_infra_prescriptions` | Rep range/RIR/role are copied into immutable set prescriptions and resolved with per-set load. |
| Exercise identity | `core.exercises.id` / `slug` | Prescribed and actual exercises use catalog FKs; names remain queryable through `core`. |
| Engine analysis | `engine.exercises`, logically joined by slug | Performance rows may snapshot the ETU vector plus an engine model label for reproducibility. |

There is no ORM. Existing database access uses explicit PostgreSQL SQL, integer identity PKs,
schema-qualified names, FKs, checks, enums, `timestamptz`, and `created_at`/`updated_at` columns.
The new schema follows those conventions.

## Core hierarchy

```text
exec.plan_runs
├── exec.microcycles
│   └── exec.workout_sessions
│       ├── exec.workout_unit_prescriptions
│       │   └── exec.exercise_unit_prescriptions
│       │       └── exec.set_prescriptions
│       └── exec.workout_unit_performances
│           └── exec.exercise_unit_performances
│               └── exec.set_performances
├── exec.workout_unit_tracks
│   └── exec.exercise_unit_tracks
└── exec.plan_run_events
```

## Plan-run and calendar model

`exec.plan_runs` stores the initial revision, start date, number of microcycles, and the
initial revision's day count. `ends_on` is a stored generated column:

```text
ends_on = starts_on + microcycle_count * microcycle_duration_days - 1 day
```

Concrete microcycles are materialized. This is intentional duplication: classification,
notes, date boundaries, and effective revision are historical execution facts and make
week/microcycle queries direct. Each session belongs to exactly one materialized microcycle
and one run-scoped workout track.

Plan revision changes are effective at the microcycle boundary in v1. A microcycle identifies
its governing revision; sessions identify concrete day/workout rows from that revision; and
prescriptions repeat the revision/source FKs while snapshotting all training instructions.

## Prescription versus performance

The two artifacts are separate normalized trees:

```text
plan infrastructure
    -> workout/exercise/set prescription snapshot (including load per set)
        -> draft or finalized workout/exercise/set performance
```

Plan descriptions and goals, prescription comments, and performance comments occupy distinct
columns. Exercise-level and set-level comments remain distinct. Performed sets carry actual
load, repetitions, RIR, status, and comment. A nullable prescribed-set FK represents an
additional set; a skipped set has an explicit status and no fabricated numeric values.

Snapshots protect history even while today's only plan revision is a mutable `DRAFT`. Source
FKs remain `RESTRICT`, while deleting an entire Execution aggregate cascades only inside
`exec`.

## Session lifecycle and in-progress synchronization

Session status and completion mode are separate. `completion_mode` is non-null only for a
completed session. A nullable `fallback_source_plan_workout_unit_id` is the future-compatible
hook for a fallback workout-unit; the schema does not invent fallback planning.

An `in_progress` session owns one `draft` performance. The draft may contain only the sets
already synchronized by a mobile client. The database constraint trigger enforces the session
and performance state pairing at transaction commit.

## Post-Workout-Analysis

Every exercise prescription can reference the prior finalized
`exercise_unit_performance` used to prepare it. The link sits at exercise-trace granularity,
so unrelated workout/exercise traces can progress independently. The first prescription in a
trace has no prior performance. A missed or cancelled calendar occurrence is not a performed
exposure; the next prescription may continue from the most recent finalized performance.

The database enforces attribution through FKs. Selecting the most recent eligible performance
and preventing speculative later prescriptions belongs to the application transaction because
those rules depend on workflow timing and intentional handling of missed/cancelled sessions.

## MARKER.X readiness

No MARKER.X formula or result table is introduced. The schema preserves its likely inputs:

- stable workout/exercise trace identity;
- microcycle and calendar time;
- per-set prescribed/performed load, reps, RIR, and set role;
- prescribed and actual exercise identity;
- plan revision and infrastructure lineage;
- optional version-labelled ETU vector snapshot.

This permits a future versioned derived calculation without turning the current tentative
formula into permanent storage architecture. How a newly introduced exercise is normalized
when it has no first-microcycle baseline remains an explicit product decision.

## Suggested model versus chosen model

| Suggested model | Chosen model | Reason | Consequence |
| --- | --- | --- | --- |
| Derive microcycles | Persist `exec.microcycles` | Revision, deload/reload, notes, and dates are important history. | Small intentional duplication; direct trace queries. |
| Put prescription/performance pointers on session | One-to-zero/one child artifacts keyed by session/prescription | Avoid bidirectional pointer drift. | Session artifacts are obtained by joins/views. |
| Reuse plan IDs as repeatable identity | Run-scoped workout/exercise tracks | Plan child IDs are revision-local and `progression_id` is non-unique. | Explicit mapping at projection time; traces survive revisions. |
| One performed copy of the prescription | Separate prescription and performance trees | Field data must represent substitutions, skipped/additional sets, and load differences. | More rows, but central facts stay relational and inspectable. |
| Persist MARKER.X | Preserve inputs and lightweight provenance only | Name/formula are unsettled. | Metrics can be recomputed/versioned later. |

## Documentation map

- [ERDs](erd.md)
- [Table catalogue](table-catalogue.md)
- [Domain invariants](invariants.md)
- [Repeatable Unit Identity](repeatable-unit-identity.md)
- [Mock dataset](mock-data.md)
- [Read models and representative queries](queries.md)
- [Desktop API implementation and compatibility audit](api-backend.md)
