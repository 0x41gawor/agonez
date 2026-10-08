# Repeatable Unit Identity

## Identity before `exec`

The editable DRAFT uses stable database IDs while it is reconciled in place. Those IDs do not
constitute a cross-revision contract: plan child tables are owned by one revision, and a copied
revision receives new day/workout/slot/variant/set IDs.

`plans.exercise_variants.progression_id` is valuable but insufficient as the sole repeatable
exercise-unit identity:

- it exists only at exercise-variant level;
- there is no corresponding workout-unit progression identity;
- its index is intentionally non-unique because multiple exercise units may share a progression
  loop;
- the repository contains no implemented plan-revision-copy workflow promising preservation;
- duplicating an entire plan intentionally generates new progression IDs.

Exercise-slot IDs are stable only inside the current mutable DRAFT. Core exercise identity says
which movement was used, not which logical position/exposure it occupied in a workout.

## Mechanism used now

`exec.workout_unit_tracks` and `exec.exercise_unit_tracks` are stable, run-scoped identities.
Their `logical_key` is unique within the relevant run/workout track and is assigned by the
plan-run projection transaction. Sessions and prescription/performance rows reference these
tracks directly.

`exercise_unit_tracks.source_progression_id` retains the plan's progression identity as mapping
evidence. It is intentionally not unique and is not the PK.

```text
plan revision 1 child IDs ─┐
                           ├─ projection decision ─> exec exercise track ─> trace
plan revision 2 child IDs ─┘
```

## Surviving a plan revision

When a later revision becomes effective, the projection workflow maps logically continuous
workout/exercise units onto existing tracks. New sessions and their immutable prescriptions
carry the new plan child FKs, while the track FK remains unchanged. Therefore the exercise
trace view can order all exposures by microcycle/date without matching names, ordinals, or
mutable plan IDs after the fact.

The deterministic seed demonstrates this: plan child IDs change at microcycle 4, but the Bench
Press prescription/performance rows continue to use one `exercise_unit_track_id`.

## Genuine replacement

An exercise change does not automatically decide trace continuity. The actor creating the plan
revision must choose:

- same training role/progression exposure: map the new variant to the existing track;
- genuinely new exercise-unit or incomparable progression: create a new exercise track.

The old track remains historical. A later product feature may record an explicit
"replaces/continues" reason, but a heuristic based only on exercise slug or slot ordinal is not
used in v1.

## Microcycle identity

Each `exec.microcycles.id` is a concrete calendar occurrence; `(plan_run_id, ordinal)` is unique.
This is distinct from the reusable plan definition's day sequence. Microcycle history survives
revision changes because each occurrence stores its effective revision.

