# Execution table catalogue

## Enums

| Type | Values |
| --- | --- |
| `exec.plan_run_status` | `scheduled`, `active`, `cancelled`, `completed` |
| `exec.microcycle_classification` | `normal`, `deload`, `reload` |
| `exec.workout_session_status` | `scheduled`, `in_progress`, `completed`, `cancelled`, `missed` |
| `exec.completion_mode` | `as_prescribed`, `fallback` |
| `exec.performance_status` | `draft`, `finalized` |
| `exec.exercise_execution_mode` | `as_prescribed`, `substituted`, `skipped`, `additional` |
| `exec.performed_set_status` | `performed`, `skipped` |
| `exec.plan_run_event_type` | `plan_revision_changed`, `personal_record`, `deload_started`, `reload_started`, `vacation`, `training_break`, `observation` |

## Tables

| Table | Purpose and important columns | Keys / cardinality | Lifecycle and consumers |
| --- | --- | --- | --- |
| `exec.plan_runs` | Aggregate root; name, initial revision, start, microcycle count/duration, generated end, status. No athlete FK exists because the repository has no identity model. | PK `id`; FK initial revision; one-to-many microcycles/tracks/events. | Mutable lifecycle metadata; calendar, plan-run detail, orchestration. |
| `exec.microcycles` | Concrete run occurrence with ordinal, date range, effective revision, classification, notes. | PK `id`; unique run+ordinal; FK run/revision. | Projection facts; revision changes affect future rows only. Microcycle trace/list. |
| `exec.workout_unit_tracks` | Stable logical workout-unit identity within a run. | PK `id`; unique run+logical key; FK run. | Stable for run lifetime. Workout traces and session projection. |
| `exec.exercise_unit_tracks` | Stable logical exercise-unit identity inside workout track; optional plan `progression_id` evidence. | PK `id`; composite FK ensures workout track is in same run; unique workout track+logical key. | Stable for run lifetime. Exercise traces, Post-Workout-Analysis, charts. |
| `exec.workout_sessions` | Calendar occurrence; source day/unit, scheduled date, status, completion mode, timestamps, fallback hook. | PK `id`; composite run/microcycle and run/track FKs; unique occurrence. | State transitions from scheduled to in-progress/completed or cancelled/missed. Calendar and attendance. |
| `exec.workout_unit_prescriptions` | Immutable workout-level snapshot and exposure comment. | PK `id`; unique FK session; restrictive plan revision/unit FKs. | Created before an exposure; immutable after start. Mobile input and historical display. |
| `exec.exercise_unit_prescriptions` | Immutable slot/variant/exercise snapshot, track link, plan and prescription comments, previous-performance link. | PK `id`; unique workout prescription+ordinal/track; restrictive plan/core FKs. | Independent progression-chain node. Exercise trace and Post-Workout-Analysis. |
| `exec.set_prescriptions` | Resolved set role, rep range, target RIR, per-set load, and comment. | PK `id`; unique exercise prescription+ordinal; restrictive source set FK. | Immutable exposure instruction. Exercise trace/mobile workout. |
| `exec.workout_unit_performances` | Draft/finalized field-data artifact with workout timestamps/comment. | PK `id`; unique FK workout prescription. | Draft while syncing, finalized with completed session. |
| `exec.exercise_unit_performances` | Actual exercise choice/mode, trace link, comment, optional engine provenance. | PK `id`; unique nullable prescribed exercise FK; FKs performance/track/core/plan variant. | Draft children may be partial; finalized children are historical field data. |
| `exec.set_performances` | Actual per-set status, load, reps, RIR, comment, recorded timestamp. Nullable prescribed-set FK marks an additional set. | PK `id`; unique exercise performance+ordinal and prescribed-set link. | Append/update during draft; immutable after workout finalization. Main analytical fact. |
| `exec.plan_run_events` | Lightweight journal with calendar timestamp, optional microcycle/session/exercise position, revision transition, and flexible metadata. | PK `id`; FK run and optional related objects/revisions. | Append-oriented. Timeline and run context. |

Internal aggregate deletion cascades from run/session/prescription roots. Cross-schema source FKs
to `plans` and `core` are restrictive to protect historical attribution.

## Read views

| View | Grain and use |
| --- | --- |
| `exec.workout_session_calendar` | One row per workout session with microcycle, revision, prescription, and performance state. |
| `exec.exercise_unit_trace` | One row per prescribed set plus one row per additional performed set; spreadsheet-equivalent trace. |
| `exec.workout_unit_trace` | One row per workout-track occurrence across microcycles. |
| `exec.microcycle_trace` | One row per microcycle with status counts, attendance ratio, and performed volume-load context. |
| `exec.performed_load_time_series` | One row per performed set, chart-ready by track/exercise/date/microcycle. |
| `exec.plan_run_event_history` | One row per event with calendar and microcycle/revision context. |

