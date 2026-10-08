# Execution read models and queries

The complete executable examples are in
[exec_read_models.sql](../../be/src/agonez_api/migrations/queries/exec_read_models.sql).

## Exercise-unit trace

`exec.exercise_unit_trace` is the primary acceptance read. Its grain is one prescribed set,
plus a separate row for an additional performed set. A Bench Press filter returns:

```sql
SELECT
    microcycle_ordinal,
    scheduled_date,
    prescribed_set_ordinal,
    prescribed_load_kg,
    performed_set_ordinal,
    performed_load_kg,
    performed_repetitions,
    performed_rir,
    diverged_from_prescription
FROM exec.exercise_unit_trace
WHERE plan_run_name = 'Execution Demo — PPL Upper Focus 2026'
  AND prescribed_exercise_slug = 'barbell_bench_press'
ORDER BY microcycle_ordinal,
         COALESCE(prescribed_set_ordinal, performed_set_ordinal);
```

Validated result: 19 rows across six exposures. Microcycles 1–3 use source revision 1 and
microcycles 4–6 use the demo revision, without changing the trace ID. The query exposes the
microcycle-3 load reduction and additional set directly.

## Workout-unit trace

`exec.workout_unit_trace` returns one row per logical workout-unit occurrence. The demo Push A
trace has six completed/finalized rows followed by two scheduled rows. Revision number changes
from 1 to 2 at microcycle 4.

## Microcycle trace

`exec.microcycle_trace` exposes dates, effective revision, classification, session counts,
attendance, and performed volume-load. Validated attendance is 80% for microcycle 3 (one missed)
and 80% for microcycle 4 (one cancelled); the latter is classified `deload`.

## Calendar/history

`exec.workout_session_calendar` returns all 40 projected sessions ordered by real date. It keeps
missed and cancelled semantics separate, identifies the October 7 draft performance as
`in_progress`, and shows future sessions without pretending they already have prescriptions or
performances.

## All-loads chart

`exec.performed_load_time_series` has one performed-set row with:

```text
exercise identity + workout/exercise trace identity + date + microcycle + set + load + reps + RIR
```

No JSON parsing or comment heuristics are required. Optional ETU provenance is carried beside,
not instead of, these relational facts.

## Event history

`exec.plan_run_event_history` orders six demo events by timestamp and resolves their microcycle
ordinal. The revision-change row additionally exposes `from_plan_revision_no = 1` and
`to_plan_revision_no = 2`.

