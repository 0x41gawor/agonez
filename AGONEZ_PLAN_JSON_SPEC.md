# Agonez Plan JSON specification

Version: `agonez-plan-sanity-v4`

Purpose: exchange a compact, AI-friendly PlanCreator prescription.

Media type: `application/json`

Encoding: UTF-8

This is an interchange format, not a database backup and not a Plan-Execution payload.
It describes the resolved day/exercise/set skeleton plus metadata that a future execution
module can use. It never contains an athlete's actual load, progression state, workout
history, or performed sets.

The same contract is produced by **Export JSON** and accepted by **Import JSON**. New
documents should use V4. V1–V3 remain importable as described below.

## Canonical example

```json
{
  "format": "agonez-plan-sanity-v4",
  "plan_name": "Three-day strength plan",
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
          "name": "Smith Machine Incline Bench Press",
          "slug": "smith_machine_incline_bench_press",
          "progression_model": "e1rm_top_set_backoffs",
          "progression_id": "e3aee2b7-a8c9-4b4c-9fd9-7f919c3c3668",
          "active_working_sets": { "min": 3, "max": 3 },
          "sets": [
            {
              "reps": { "min": 6, "max": 8, "semantics": "undefined" },
              "rir": "NOT_APPLICABLE",
              "role": "rampup",
              "load_spec": { "kind": "relative_to_set", "ref_set_idx": 2, "pct": 50 }
            },
            {
              "reps": { "min": 6, "max": 8, "semantics": "undefined" },
              "rir": "NOT_APPLICABLE",
              "role": "rampup",
              "load_spec": { "kind": "relative_to_set", "ref_set_idx": 2, "pct": 80 }
            },
            {
              "reps": { "min": 6, "max": 8, "semantics": "estimate" },
              "rir": "RIR2",
              "role": "working_topset",
              "load_spec": { "kind": "athlete_selected" }
            },
            {
              "reps": { "min": 6, "max": 8, "semantics": "estimate" },
              "rir": "UNDEFINED",
              "role": "working_backoff",
              "load_spec": { "kind": "relative_to_set", "ref_set_idx": 2, "pct": 92 }
            },
            {
              "reps": { "min": 5, "max": 5, "semantics": "gating" },
              "rir": "UNDEFINED",
              "role": "working_amrap",
              "load_spec": { "kind": "relative_to_set", "ref_set_idx": 2, "pct": 92 }
            }
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
    }
  ]
}
```

## General rules

- JSON must be strict: no comments, trailing commas, `NaN`, or `Infinity`.
- Unknown object fields are rejected.
- Strings described as non-blank are trimmed during import.
- The browser accepts a maximum file size of 1 MiB.
- Arrays are ordered. Do not encode ordering in names or slugs.
- Set indices used by `load_spec` are zero-based positions in that exercise's `sets`
  array. `ref_set_idx: 2` points to the third set.

## Root document

| Field | Type | Constraints and meaning |
|---|---|---|
| `format` | string | Exactly `agonez-plan-sanity-v4`. |
| `plan_name` | string | Non-blank, at most 200 characters. The new plan's name. |
| `resolution_context` | object | Provenance for the resolved set list; it does not create Modulation configuration. |
| `days` | array | 0–365 chronological day objects. A microcycle may be longer than seven days. |

### `resolution_context`

| Field | Type | Constraints and meaning |
|---|---|---|
| `global_volume_level` | integer | 0–32767. Use `0` for the basic/default artifact. |
| `focus_area` | string or `null` | At most 100 characters. Use `null` when no focus was resolved. |
| `axis_overrides` | object | Keys are 1–100 characters; values are integers 0–32767. Use `{}` when absent. |

Imported sets are concrete prescriptions stored at basic volume level. The context is
retained only as provenance.

## Day object

| Field | Type | Constraints and meaning |
|---|---|---|
| `day` | integer | 1–365 and equal to the one-based array position. |
| `name` | string | Non-blank, at most 200 characters. |
| `weekday` | string or `null` | `Monday` through `Sunday`, or `null`. It is display metadata, not ordering. |
| `rest` | boolean | An explicit rest day when `true`. |
| `exercises` | array | 0–100 exercise objects; must be empty for a rest day. |

Repeated weekday names are valid in microcycles longer than one week. `rest: false` with
an empty exercise list creates an empty workout day.

## Exercise object

An exercise object is the compact representation of one concrete default exercise unit.
PlanCreator creates the surrounding slot and generates its stable database identity.

| Field | Type | Constraints and meaning |
|---|---|---|
| `name` | string | Non-blank, at most 200 characters. Human-readable slot label. |
| `slug` | string | 1–200 characters; `^[a-z0-9_]+$`. Authoritative Atlas exercise identity. |
| `progression_model` | string or `null` | Known `core.progression_models.slug`, or `null`. Descriptions are deliberately not repeated. |
| `progression_id` | UUID string | Progression-loop identity. Reuse the exact UUID on multiple exercise units to couple their loop. |
| `active_working_sets` | object or `null` | Optional future-execution range `{ "min": int, "max": int }`. `null` means fixed prescribed count. |
| `sets` | array | 0–100 ordered set prescriptions. |

`slug`, not `name`, selects the Atlas exercise. Unknown exercise and progression-model
slugs reject the entire import.

`progression_id` is not the exercise-unit identity. Each stored variant already receives
its own stable backend ID. `progression_id` identifies only a progression loop:

- give each exercise unit a different UUID for independent loops;
- give two or more units the same UUID to share one loop;
- when omitted on import, Agonez generates a new independent UUID.

For `active_working_sets`, both bounds are integers from 0–32767, `max >= min`, and `max`
must not exceed the number of prescribed working-role sets. Ramp-up sets do not count.
Omission or `null` preserves fixed-set-count behavior. Canonical exports emit either the
object or `null`.

## Set object

| Field | Type | Constraints and meaning |
|---|---|---|
| `reps` | object | Inclusive range with `min`, `max`, and `semantics`. |
| `rir` | string | `RIR0`–`RIR4`, `NOT_APPLICABLE`, or `UNDEFINED`. |
| `role` | string | One of the set roles below. Defaults to `working` if omitted. |
| `load_spec` | object | Tagged unresolved load metadata. Defaults to `{ "kind": "absolute" }` if omitted. |

`reps.min` and `reps.max` are integers from 1–32767, and `max >= min`.
`reps.semantics` is one of:

- `gating`: reaching a position in the range may affect a later progression decision;
- `estimate`: expected performance, but not itself a progression gate;
- `undefined`: the creator intentionally leaves the interpretation unspecified.

Semantics defaults to `undefined` if omitted. Canonical V4 exports always include it.

RIR meanings:

- `RIR0`–`RIR4`: numerical repetitions in reserve;
- `NOT_APPLICABLE`: the set is not subject to RIR, typically a ramp-up;
- `UNDEFINED`: intensity will be known only after performance.

Analysis V1 excludes ramp-up sets and cannot calculate stimulus for a working set whose
RIR is nonnumeric. It does not invent an RIR value.

Set roles are:

- `rampup` — preparatory; excluded from the working-set count;
- `working` — ordinary working set;
- `working_topset` — primary/top working set;
- `working_backoff` — working set derived after a top set;
- `working_amrap` — working AMRAP/evaluation set.

Emit each set separately. There is no `count`, `rounds`, or implicit repetition shortcut.

## `load_spec` tagged union

`load_spec` records author intent only. PlanCreator stores and validates it but does not
resolve an athlete's actual load.

| `kind` | Required fields | Meaning |
|---|---|---|
| `absolute` | none | Execution will later supply a concrete absolute load. Default. |
| `athlete_selected` | none | Athlete selects the load at execution time. |
| `relative_to_set` | `ref_set_idx`, `pct` | Percentage of another set's load in the same exercise. |
| `relative_to_working` | `pct` | Percentage of the future resolved working load. |
| `table_derived` | `ref_set_idx`, `table` | A named table such as `apre10` derives the load from a referenced set. |
| `ordinal_variant` | `level` | Ordinal exercise/load variant, such as a bodyweight progression level. |

Constraints:

- `pct` is a positive finite number and represents percent, so `92` means 92%;
- `ref_set_idx` is an integer 0–32767 and must point inside the same exercise's set list;
- `relative_to_set` cannot reference its own set;
- `table` is 1–100 lowercase letters, digits, or underscores;
- `level` is an integer 1–32767;
- reference chains are stored but deliberately not evaluated in PlanCreator.

## Mapping to PlanCreator

Import creates the full draft atomically:

| JSON | PlanCreator entity |
|---|---|
| Root | New workout plan and draft revision |
| Rest day | Day prescription without a workout unit |
| Training day | Day plus workout unit |
| Exercise | Exercise slot with one `DEFAULT` exercise variant |
| `progression_model` | Progression-model slug on that variant |
| `progression_id` | Shareable progression-loop UUID on that variant |
| Set | Basic-level set-infrastructure prescription |

Database IDs, revision numbers, lock versions, ordinals, and fallback variants are never
supplied by this interchange format.

Because the compact format has no exercise-slot role field, roles are inferred per day:

1. first exercise → `PRIMARY_PROGRESSIVE`;
2. second exercise → `SECONDARY_PROGRESSIVE`;
3. later exercises → `ACCESSORY`.

`VOLUME_ACCUMULATION` is not inferred. Slot goals/descriptions, fallback exercises,
intentional target muscles, warm-up/stretch notes, and volume axes begin empty and remain
editable in PlanCreator.

## Validation and atomicity

The browser validates syntax, strict fields, types, bounds, day numbering, rest-day
consistency, load references, and active working-set bounds before review. The backend
repeats domain validation and verifies catalog slugs inside the import transaction. Any
failure prevents creation of the plan.

## Backward compatibility

- V1 has no `progression_model` and numeric RIR 0–4.
- V2 carries `progression_model` as a rich object or `null` and numeric RIR.
- V3 carries only a progression-model slug or `null` and numeric RIR.
- V4 adds progression-loop, active-set, set-role, load-spec, rep-semantics, and extended
  RIR metadata.

V1–V3 imports receive V4-compatible defaults: independent generated progression IDs,
fixed-set-count behavior, `working`, `absolute`, and `undefined` semantics. New exports
always use V4. Do not generate new legacy documents.

## LLM authoring checklist

1. Return one strict JSON object with no Markdown wrapper or explanatory prose.
2. Use only Atlas exercise slugs and progression-model slugs known to the target instance.
3. Start day numbering at 1 and keep it consecutive in chronological order.
4. Model rest days explicitly with `rest: true` and `exercises: []`.
5. Emit every concrete set separately and choose its role intentionally.
6. Use `NOT_APPLICABLE` for ramp-up sets unless RIR truly applies; use `UNDEFINED` when
   execution determines RIR later.
7. Keep every load reference inside the same exercise and use zero-based indices.
8. Never infer actual kilograms, execution history, or progression state.
9. Reuse a `progression_id` only when units intentionally share one progression loop.
10. Verify active-set bounds against only the four working roles.
11. Use the default resolution context unless another resolved context is explicitly known.
12. Validate the final result as strict JSON before returning it.
