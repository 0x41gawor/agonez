# Agonez Plan JSON specification

Version: `agonez-plan-sanity-v1`  
Purpose: create a new Agonez PlanCreator draft from an AI-friendly, resolved training plan.  
Media type: `application/json`  
Text encoding: UTF-8

This is an interchange format, not a database backup. It deliberately describes days,
exercises, and concrete set prescriptions without exposing PlanCreator IDs, revisions,
exercise-slot IDs, fallbacks, or other persistence details.

Loading modes and loading cycles are intentionally not part of V1. Exported repetition
ranges are already concrete. Import creates `moderate_load` slots and leaves each set in
inherit mode; richer unresolved loading patterns require a future interchange version.

The same format is produced by PlanCreator's **Export JSON** action and accepted by the
**Import JSON** action on the **My Plans** page.

## Canonical example

```json
{
  "format": "agonez-plan-sanity-v1",
  "plan_name": "Three-day full body strength",
  "resolution_context": {
    "global_volume_level": 0,
    "focus_area": null,
    "axis_overrides": {}
  },
  "days": [
    {
      "day": 1,
      "name": "Full Body A",
      "weekday": "Monday",
      "rest": false,
      "exercises": [
        {
          "name": "High-Bar Barbell Back Squat",
          "slug": "high_bar_back_squat",
          "sets": [
            { "reps": { "min": 5, "max": 7 }, "rir": 2 },
            { "reps": { "min": 5, "max": 7 }, "rir": 2 },
            { "reps": { "min": 5, "max": 7 }, "rir": 1 }
          ]
        },
        {
          "name": "Barbell Bench Press",
          "slug": "barbell_bench_press",
          "sets": [
            { "reps": { "min": 6, "max": 8 }, "rir": 2 },
            { "reps": { "min": 6, "max": 8 }, "rir": 1 }
          ]
        },
        {
          "name": "Pendlay Row",
          "slug": "pendlay_row",
          "sets": [
            { "reps": { "min": 6, "max": 10 }, "rir": 2 },
            { "reps": { "min": 6, "max": 10 }, "rir": 1 }
          ]
        }
      ]
    },
    {
      "day": 2,
      "name": "Rest",
      "weekday": "Tuesday",
      "rest": true,
      "exercises": []
    },
    {
      "day": 3,
      "name": "Full Body B",
      "weekday": "Wednesday",
      "rest": false,
      "exercises": [
        {
          "name": "Pendlay Row",
          "slug": "pendlay_row",
          "sets": [
            { "reps": { "min": 5, "max": 8 }, "rir": 2 },
            { "reps": { "min": 5, "max": 8 }, "rir": 1 }
          ]
        }
      ]
    }
  ]
}
```

## Structural contract

All fields shown below are required. Objects are strict: fields not listed in this
specification are rejected. JSON comments, trailing commas, `NaN`, and `Infinity` are not
valid JSON and must not be emitted. The browser accepts files up to 1 MiB.

### Root document

| Field | JSON type | Constraints | Meaning |
|---|---|---|---|
| `format` | string | Exactly `agonez-plan-sanity-v1` | Selects this contract and prevents accidental import of unrelated JSON. |
| `plan_name` | string | Non-blank; maximum 200 characters | Name of the new independent PlanCreator plan. Duplicate names are allowed. |
| `resolution_context` | object | See below | Records which volume/focus context produced the concrete set list. |
| `days` | array | 0–365 day objects | The complete microcycle in chronological order. A microcycle may exceed seven days. |

### `resolution_context`

| Field | JSON type | Constraints | Meaning |
|---|---|---|---|
| `global_volume_level` | integer | 0–32767 | Volume level used when resolving the source plan. Use `0` for a basic/default plan. |
| `focus_area` | string or `null` | Maximum 100 characters | Focus-area variant used by the source resolver. Use `null` when none was applied. |
| `axis_overrides` | object | Keys: 1–100 characters; values: integers 0–32767 | Per-axis volume-level overrides used by the source resolver. Use `{}` when none were applied. |

The import treats the listed sets as the final, concrete prescription. The resolution
context is provenance; it does not create Modulation configuration. Every imported set is
stored at PlanCreator's basic volume level (`min_volume_level = 0`).

### Day object

| Field | JSON type | Constraints | Meaning |
|---|---|---|---|
| `day` | integer | 1–365; must equal its one-based array position | Stable human-readable day number. `days[0].day` is `1`, `days[1].day` is `2`, and so on. |
| `name` | string | Non-blank; maximum 200 characters | Session or rest-day name shown in PlanCreator. |
| `weekday` | string or `null` | Full English weekday name; see allowed values below | Optional calendar label. It does not control array order. |
| `rest` | boolean | `true` or `false` | When `true`, PlanCreator creates an explicit rest day with no workout unit. |
| `exercises` | array | 0–100 exercise objects | Ordered exercises for this day. Must be empty when `rest` is `true`. |

Allowed weekday strings are exactly:

`Monday`, `Tuesday`, `Wednesday`, `Thursday`, `Friday`, `Saturday`, `Sunday`.

Use `null` when the microcycle is not tied to weekdays. Weekday names may repeat in a
microcycle longer than seven days. The order of the `days` array is always authoritative.

`rest: false` with an empty `exercises` array is valid and creates an empty workout day.

### Exercise object

| Field | JSON type | Constraints | Meaning |
|---|---|---|---|
| `name` | string | Non-blank; maximum 200 characters | Human-readable label used as the imported exercise-slot name. |
| `slug` | string | 1–200 characters; regex `^[a-z0-9_]+$` | Authoritative Atlas exercise identity. It must already exist in `core.exercises`. |
| `sets` | array | 0–100 set objects | Concrete ordered work sets for this exercise. |

The `slug`, not `name`, selects the exercise. A correct display name does not compensate
for an unknown or misspelled slug. Import is rejected atomically if any slug does not exist
in the live Atlas catalog. Repeating a slug is allowed and creates separate exercise slots.

### Set object

| Field | JSON type | Constraints | Meaning |
|---|---|---|---|
| `reps` | object | Contains exactly `min` and `max` | Inclusive prescribed repetition range. |
| `reps.min` | integer | 1–32767 | Lowest acceptable repetitions for the set. |
| `reps.max` | integer | 1–32767 and greater than or equal to `reps.min` | Highest acceptable repetitions for the set. |
| `rir` | integer | 0–4 | Repetitions in reserve at the end of the set. `0` means no reps left; `4` means about four reps left. |

Every set is an individual array item. To prescribe three identical sets, emit three set
objects; do not use a `count`, `sets`, or `rounds` shortcut.

## How import maps to PlanCreator

The import endpoint creates a complete new draft in one database transaction:

| JSON concept | Created PlanCreator concept |
|---|---|
| Root document | New workout plan and draft revision |
| Day with `rest: true` | Day prescription without a workout unit |
| Day with `rest: false` | Day prescription plus a workout unit named after the day |
| Exercise | Exercise slot with one `DEFAULT` exercise variant |
| Set | Basic-level set-infrastructure prescription |

Internal IDs, ordinals, revision numbers, and lock versions are generated by Agonez and
must never be supplied in JSON.

Because this compact format intentionally has no exercise-slot role field, roles are
derived from exercise order independently for each non-rest day:

1. First exercise → `PRIMARY_PROGRESSIVE`
2. Second exercise → `SECONDARY_PROGRESSIVE`
3. Third and later exercises → `ACCESSORY`

`VOLUME_ACCUMULATION` is not inferred. Adjust roles in the PLAN editor after import when a
different classification is intended.

The compact format also does not carry fallback exercises, intentional target-muscle
slugs, slot goals/descriptions, plan/day descriptions, warm-up notes, stretch notes, or
volume axes. These begin empty and can be added in the editor. Consequently, imported
analysis may initially classify contributions as unclassified until intentional target
muscles are set.

## Validation and atomicity

Validation occurs twice:

1. The web application validates JSON syntax, all fields, types, ranges, array limits,
   day numbering, weekday spelling, and rest-day consistency before showing a review.
2. The backend repeats structural validation and resolves every exercise slug against the
   current Atlas catalog inside the import transaction.

If validation fails, no plan is created. Typical errors include an unsupported `format`,
unknown fields, non-consecutive day numbers, a populated rest day, invalid RIR, reversed
rep ranges, and unknown exercise slugs.

## LLM authoring rules

When generating this format:

1. Output one JSON object only—no Markdown fences or prose in the file.
2. Use only exercise slugs known to the target Agonez Atlas instance. Never invent slugs.
3. Preserve intended chronological order in the `days` array and use consecutive `day`
   values beginning at `1`.
4. Represent rest days explicitly with `rest: true` and `exercises: []`.
5. Emit each concrete set separately and keep `rir` within `0`–`4`.
6. Put the main progressive exercise first and the secondary progressive exercise second
   when the default role inference is desired.
7. Use `resolution_context.global_volume_level: 0`, `focus_area: null`, and
   `axis_overrides: {}` unless another resolved context is explicitly known.
8. Do not include IDs, roles, target muscles, comments, units, load values, tempos, rest
   times, or any other fields not defined by this version.

Before returning the document, verify that it parses as strict JSON and that every object
contains exactly the keys shown in this specification.
