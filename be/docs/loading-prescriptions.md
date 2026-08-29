# Loading prescriptions

PlanCreator stores loading intent separately from the concrete repetition range. This
keeps the current workout executable while preserving the intended loading strategy for
future modulation.

## Catalog recommendation

`core.exercises.recommended_rep_profile` is exposed by both Atlas exercise endpoints as:

```json
{
  "high_load": null,
  "moderate_load": { "min": 8, "max": 12 },
  "low_load": { "min": 12, "max": 20 }
}
```

All three keys are required. Each value is either a range or `null`; `null` means that
the loading mode is not recommended for that exercise. For ranges, both positive integer
bounds are required and the maximum cannot be smaller than the minimum. These are
exercise-specific authoring recommendations, not universal physiological boundaries.

## Plan fields

The `plans.loading_mode` enum uses the JSON/SQL values `high_load`, `moderate_load`, and
`low_load`.

An exercise slot has:

- `loading_mode`: required static default; existing and new slots default to
  `moderate_load`;
- `loading_cycle`: optional repeating sequence of 2–52 loading modes.

A set-infrastructure prescription has:

- `loading_mode`: optional static override; `null` means inherit;
- `loading_cycle`: optional repeating override of 2–52 loading modes.

Effective loading is resolved with this precedence:

1. set `loading_cycle`;
2. set `loading_mode`;
3. slot `loading_cycle`;
4. slot `loading_mode`.

Cycle position zero describes the first execution of this plan microcycle. The pattern
repeats indefinitely: `[low_load, high_load]` alternates, while
`[high_load, high_load, low_load]` inserts a low-load exposure every third repetition.

## Repetition ranges

The loading prescription is metadata and the saved `reps.min`/`reps.max` remains the
concrete prescription. When the editor creates a set, it initializes the reps from the
selected exercise profile and the first effective loading mode. Later loading-mode or
cycle edits do not overwrite manually edited repetition ranges.

If an author explicitly uses a mode marked `null`, the editor identifies it as not
recommended and uses the generic mode range only as an editable initialization fallback.

The current Analysis V1 snapshot evaluates concrete reps and RIR. Applying a later
loading-cycle position to produce a different concrete plan belongs to the future
Modulation resolver.

## Compact JSON interchange

`agonez-plan-sanity-v1` remains a resolved, concrete sanity-check format and therefore
exports reps/RIR only. Importing that format creates moderate-load slots whose sets
inherit. A future interchange version can carry unresolved loading patterns without
changing V1 semantics.
