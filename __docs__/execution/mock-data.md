# Execution mock dataset

## Source plan

The seed resolves an existing plan by exact name:

```text
5x week, Push-Pull-Legs, upper focus, volume redukcyjne
```

In the inspected database this is plan `6`, revision `1`, with seven days, five workout-units,
41 exercise-slots, and two rest days. The seed never relies on those numeric IDs; it resolves
the plan and revision at runtime and fails clearly if they are absent.

The selected revision is currently `DRAFT` because the repository has no release endpoint. The
seed creates one clearly marked `RELEASED` demo revision under the same existing plan, copies
the full relational tree, preserves each `progression_id`, and adds a Bench Press revision note.
The marker lives in `plan_revisions.snapshot.seed_key`, so rerunning the seed refreshes only the
demo-owned revision.

## Plan-run story

| Property | Value |
| --- | --- |
| Run | `Execution Demo — PPL Upper Focus 2026` |
| Dates | 2026-09-01 through 2026-10-26 |
| Duration | 8 seven-day microcycles |
| Revision transition | Revision 1 in microcycles 1–3; demo revision 2 from microcycle 4 |
| Deload/reload | Microcycle 4 deload; microcycle 5 reload |
| Current point | 2026-10-07: Push A completed, Pull A in progress, later sessions scheduled |

The deterministic dataset contains:

- 8 microcycles and 40 projected workout sessions;
- 25 completed workouts, one in-progress workout, one missed workout, one cancelled workout,
  and future scheduled workouts;
- 30 workout prescriptions through the current microcycle;
- prescription and performance comments at exercise and set scope;
- resolved load per set and actual load/reps/RIR;
- a Smith incline substitution when the prescribed machine is unavailable;
- a skipped California Press exercise-unit and explicit skipped set;
- a Bench Press load reduction plus one unplanned additional back-off set;
- partial/draft set synchronization for the in-progress workout;
- plan start, training break, personal record, revision change, deload, and reload events;
- optional ETU-vector snapshots copied from current `engine.exercises` rows.

The seed is [0001_execution_demo.sql](../../be/src/agonez_api/migrations/seeds/0001_execution_demo.sql).
It is packaged but not run by the automatic migration runner.

## Bench Press story

| Microcycle | Date | Revision | Prescribed / performed summary |
| --- | --- | --- | --- |
| 1 | 2026-09-01 | 1 | 65 kg prescribed; 7/6/5 performed |
| 2 | 2026-09-08 | 1 | 65 kg; 7/7/6 |
| 3 | 2026-09-15 | 1 | 67.5 kg; final set reduced to 65 kg; additional back-off set |
| 4 | 2026-09-22 | demo 2 | Deload at 60 kg; 7/7/7 |
| 5 | 2026-09-29 | demo 2 | Reload at 65 kg; 7/6/5 |
| 6 | 2026-10-06 | demo 2 | 67.5 kg; 7/6/5 with technique notes |

All rows use one `exercise_unit_track_id` even though plan revision and all revision-local plan
child IDs change at microcycle 4.

