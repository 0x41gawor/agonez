# Execution domain invariants

This document separates database enforcement from workflow rules that require application
context. `DB trigger` means a deferred constraint trigger evaluated at transaction commit.

| Invariant | Owner / enforcement |
| --- | --- |
| A workout session belongs to exactly one plan run and one concrete microcycle occurrence. | Composite FK `(plan_run_id, microcycle_id)` plus NOT NULL. |
| A session's microcycle and workout track belong to the same plan run. | Composite FKs to `microcycles` and `workout_unit_tracks`. |
| At most one occurrence of a workout track exists in a microcycle. | UNIQUE `(microcycle_id, workout_unit_track_id)`. |
| Microcycle ordinal is positive and unique inside a run. | CHECK plus UNIQUE `(plan_run_id, ordinal)`. |
| A microcycle has a non-empty date interval. | CHECK `ends_on >= starts_on`. |
| Microcycle dates exactly partition the run and use its duration. | Plan-run creation transaction/application logic; seed and tests verify it. Cross-row arithmetic is not duplicated in triggers. |
| Run end date follows the initial revision duration snapshot. | Stored generated `ends_on`; positive count/duration checks. Creation logic must obtain duration from the initial revision's day count. |
| No paused plan-run state exists. | Database enum omits `paused`. Breaks use missed/cancelled sessions and events. |
| Completion state and completion mode are separate. | Separate enums/columns plus CHECK: mode exists only for `completed`. |
| Fallback completion identifies a fallback source unit. | CHECK requiring `fallback_source_plan_workout_unit_id`; nullable hook only, no fallback subsystem. |
| Completed sessions have timestamps and a finalized performance. | CHECK for timestamps; deferred DB trigger for performance artifact/state. |
| In-progress sessions have a start time and draft performance. | CHECK plus deferred DB trigger. |
| Scheduled, cancelled, and missed sessions have no performance artifact. | Deferred DB trigger. Missed/cancelled semantics remain separate enum values. |
| A performance is attributable to exactly one workout prescription. | NOT NULL UNIQUE FK from performance to prescription. |
| One session has at most one prescription and one performance. | UNIQUE session FK on prescription; UNIQUE prescription FK on performance. |
| Historical prescription meaning survives plan mutation. | Normalized snapshots at workout/exercise/set levels plus restrictive source FKs. Rows are treated as immutable after exposure starts. |
| Historical performed facts survive plan mutation. | Performance rows reference execution snapshots/tracks and core exercise IDs, not mutable plan fields. |
| Prescribed load is queryable per set. | Relational `set_prescriptions.prescribed_load_kg`. |
| Actual load/reps/RIR are queryable per set. | Relational `set_performances` columns and range checks. |
| Skipped performed sets contain no fabricated actual values. | CHECK on `performed_set_status`. |
| Additional sets remain distinguishable. | Nullable `prescribed_set_id`; actual set ordinal remains unique inside exercise performance. |
| Exercise substitution/addition/skip is explicit. | `exercise_execution_mode` plus mode-specific CHECKs for prescribed/actual exercise FKs. |
| Set ordinals are nonnegative and unique within their exercise artifact. | CHECK plus UNIQUE on prescription and performance tables. |
| Workout/exercise traces survive revision-local plan IDs. | Stable run-scoped track FKs; see [Repeatable Unit Identity](repeatable-unit-identity.md). |
| A later exercise prescription is based on prior performance for the same trace. | Nullable FK provides attribution. The Post-Workout-Analysis transaction verifies same track, finalized state, temporal order, and latest eligible performance. |
| First exposure in a trace can be prescribed without prior performance. | `previous_exercise_performance_id` is nullable. Application permits null only when no earlier finalized exposure exists. |
| Independent traces do not block each other. | Prior-performance link is exercise-level, never global/microcycle-wide. |
| A microcycle governs one revision and historical sessions use its child rows. | Stored revision on microcycle and source FKs on session/prescription. Projection transaction validates that source rows belong to that revision. |
| A revision transition never rewrites earlier microcycles/sessions. | Workflow rule: append/update only future projections; plan source FKs are restrictive. |
| Events are positioned in calendar time and optionally run time. | NOT NULL `occurred_at`; composite run/microcycle FK when microcycle is present. |
| Revision-change events identify distinct old/new revisions. | CHECK plus two restrictive revision FKs. Application validates both revisions belong to the run's plan. |
| Core execution facts are not hidden in JSON. | Loads, reps, RIR, identities, dates, ordinals, states, and comments are relational. JSON is limited to flexible event metadata and optional ETU provenance. |

## Transaction boundaries

The following operations should be single transactions in the future backend:

1. Create run, materialize microcycles/tracks/sessions, and validate the initial revision day
   count.
2. Start session and create its draft performance.
3. Finalize all performance rows and mark the session completed.
4. Perform Post-Workout-Analysis and create the next exercise prescription with its prior
   performance link.
5. Apply a plan revision only to future microcycles/sessions and append a revision-change event.

The deferred session/performance trigger permits temporary statement-order inconsistency within
these transactions but rejects an invalid committed state.

