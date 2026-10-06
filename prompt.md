# Plan spec update

We need to extend the metadata carried by the plan spec. The data-model should be able to carry more specific information than it is as for now.

The role of the current plan spec into "My plans" module is to define an scaffold/skeleton/prescription/infrastucture for the future "Plan-Execution" module. It has to give the plan-creator a possibility to model of all the roles, intents etc.. except of the actual load that will be resolved only for specific athelte for specific workout-unit.

First, get to know with the current data-model. Second I will list the "changes". Get to know with them and implement them all at once in each domain. Database, backend, frontend. Changes chapter will give few hints how to implement selected domains.

All of the changes should be included/closed in the current modules. Do not create new database schemas or UI tabs. The plan-execution module is planned for later and this prompt has a mission to close the plan-creation module.

Before modifying anything:

1. Inspect the existing plan-creation implementation end-to-end:
   - database schema and migrations,
   - ORM/domain models,
   - API schemas,
   - serialization/deserialization,
   - validation,
   - plan creation/editing frontend,
   - existing tests.

2. Identify the current canonical representation of:
   - plan,
   - exercise unit / exercise slot,
   - set prescription,
   - progression model,
   - RIR,
   - rep range.

3. Extend the existing architecture rather than introducing parallel models.

4. Implement all changes below end-to-end:
   database -> backend/domain/API -> frontend -> tests.

5. Preserve backward compatibility with existing stored plans wherever reasonably possible.
   Existing plan records that do not contain the new metadata must remain readable/editable.

6. Do not implement Plan-Execution or load-resolution logic.
   This task only adds metadata required by that future module.

Do not infer or calculate actual training loads.
Do not implement progression execution.
Do not implement progression state.
Do not implement workout history.
Do not create execution/session entities.

## Changes

### Each set should have a role

For the case if someone wants to model warmup, rampup sets and distiguish them explicitlly from the working sets. Also if a progression models allows for even a working sets distinction, why not to model it here.

Each set should have:
```json
role: "rampup" | "working" | "working_topset" | "working_backoff" | "working_amrap"
```


### Set prescription should have load_spec field

This change has its goal into being a metadata for future agents that will create the prescriptions. You dont need to understand these change.

Just prepare field `load_spec` that can be selected for each set. I will list the possible values below in a json format with some comments. Some of the values will allow for a fields that precise them even more.

```json
load_spec =
  | { kind: "absolute"}                                         // default option, later in the plan-execution module, the additional field 'value' will be known on the resoltuion stage
  | { kind: "athlete_selected" }                                // for the e1RM top set progression
  | { kind: "relative_to_set", ref_set_idx: 2, pct: 92 }         // for the e1RM back-off
  | { kind: "relative_to_working", pct: 50 }                    // rampup50
  | { kind: "table_derived",   ref_set_idx: 2, table: "apre10" } // APRE set 4
  | { kind: "ordinal_variant", level: 3 }                     // bodyweight
```

`pct` always means percentafe of the reference load (e.g. 92 means 92%)

Prepare the backend accordingly. And think of a good UI for this.

For `load_spec.kind == "relative_to_set"`:

- `ref_set_idx` is required.
- `pct` is required.
- `ref_set_idx` must reference another set within the same exercise unit.
- A set must not reference itself.
- Do not resolve or evaluate reference chains in this task; only validate/store them.

For `table_derived`:
- `ref_set_idx` is required.
- `table` is required.

For `ordinal_variant`:
- `level` is required.

For `absolute` and `athlete_selected`:
- no additional fields are required.

### Each exericse should have progression_id

If someone wants to have a single progression_loop for two disting exercise_units during the microcycle we should let them do it.

Each exercise should have its progression_id, so two distinct exercise_units can be coupled together.

The UI behind this should allow for a progression_id field with options:
- "own" 
- "shared" - with the selection of an exercise unit to link it with, the identification [see X below] of exerise here should be a string contatenation of day, exercise_slot_name, exercise_name e.g. depending on the filled values by the user.

Also this gives us the problem of the exercise unit identity during the microcycle, which should be also (if not yet) implemented on the backend side (the UI does not have to show this).
 
### The 'X' below

#### Exercise-unit identity

Every exercise unit within a plan/microcycle must have its own stable backend identity.
This identity is independent from exercise slug, day position, display name or ordering.

Use the existing entity identity mechanism if one already exists.
Otherwise introduce a stable UUID for the exercise unit within the existing model/schema.

Do not use a concatenated UI label as the persisted identity.

The concatenation:
"<day> / <exercise_slot_name> / <exercise_name>"
is only a human-readable UI label for selecting another exercise unit.

#### progression_id semantics

`progression_id` identifies a progression loop, not an exercise unit.

By default, every exercise unit receives its own progression_id.

When the user selects "shared" in the UI, the exercise unit should reuse
the progression_id of the selected exercise unit.

Therefore multiple exercise units may have the same progression_id.

The frontend concepts "own" and "shared" are configuration controls only.
They do not have to be persisted as literal values in the domain model.

### RIR can be 'NOT_APPLICABLE' or 'UNDEFINED'

Current 'rir' field allows for `| "RIR0" | "RIR1"| "RIR2" | "RIR3" | "RIR4" |` values. But warmup sets should not be the subject for RIR analysis. Hence the value 'NOT_APPLICABLE'. Similiar case is with the locked-in-reps-number sets, we don't know the intensity during set prescription, hence we can assign "UNDEFINED" with the meaning that it will be known "later", after the performance.

### RepRange can have semantics

Sometimes the rep number performed by the athlete will be a gate for a higher load next time, sometimes rep range in the prescr is just an estimation of the actual reps that we expect from the athlete. This need to be modeled.

For each rep range add accordigly:
```json
rep_range: {
 min: int,
 max: int,
 semantics: GATING | ESTIMATE | UNDEFINED,
}
```

gating:
Reaching a position in the range may affect progression decisions.

estimate:
The range describes the expected performance range but does not itself
constitute a progression gate.

undefined:
The plan creator intentionally does not specify how the range should be
interpreted.

### exercise unit can define range for active_working_sets

This is for the Triple Progression model (but hence the agonez-plan-creator is elastic as possible, can be used under any of the policies), where number of active sets is a function of time. in other words - it can change during the plan-run. The plan-creator here can model what is the minimum and the maximum number of sets for this exercise_slot. Later, during the execution phase, the progression-policy-resolver-agent will decide how many sets to activate. 

No additional metadata in the sets itself is needed here.

```json
plan = {
  exercise: dumbbell_lateral_raise,
  policy: "cascade_driven_independent_reprange_triple_progression",
  active_working_sets: { min: 3, max: 4 },
```

`active_working_sets.max` must not exceed the number of prescribed sets whose role is a working-set role.

Ramp-up sets do not count toward active_working_sets.

Working-set roles are:
- working
- working_topset
- working_backoff
- working_amrap


### Summary of the changes

These changes should only extend the current model. Do not delete any of the existing features.

Also these changes are to provide additional information. It is the plan-creator decision if he includes it or not. 

Backward-compatible defaults:

- set.role -> "working"
- set.load_spec -> { kind: "absolute" }
- rep_range.semantics -> "undefined"
- active_working_sets -> absent means the existing fixed-set-count behavior, min and max are the same number
- progression_id -> automatically assigned if absent

In general, the UI should not force the user to model all of that. Only the aware user should fill out all of the forms. Let's not overwhelm newbies.

## Exemplary plan for single exercise unit after the changes in a json format

```pseudo-json
plan.exericses[n] = {
	policy: e1rm_top_set_backoffs,
	progression_id: 'e3aee2b7-a8c9-4b4c-9fd9-7f919c3c3668',
	exercise: smith_machine_incline_bench_press,
    "active_working_sets": {
        "min": 5,
        "max": 5
    },
	sets: [
		{
			idx: 0,
			rep_range: {min: 6, max: 8, semantics: 'undefined'},
			load_spec: {kind: 'relative_to_set', ref_set_idx: 2, pct: 50},
			RIR: 'NOT_APPLICABLE',
			role: 'rampup',
			comment: 'pierwszy set rozgrzekowy, przygotowanie układu nerwowego, celuj w 50% tego co będzie w topset'
		},
		{
			idx: 1,
			rep_range: {min: 6, max: 8, semantics: 'undefined'},
			load_spec: {kind: 'relative_to_set', ref_set_idx: 2, pct: 80},
			RIR: 'NOT_APPLICABLE',
			role: 'rampup',
			comment: 'drugi set rozgrzekowy, przygotowanie układu nerwowego, celuj w 80% tego co będzie w topset'
		},
		{
			idx: 2,
			rep_range: {min: 6, max: 8, semantics: 'estimate'},
			load_spec: {kind: 'athlete_selected'},
			RIR: 'RIR2',
			role: 'working_topset',
			comment: 'Tak zwany top-set, Twój najważniejszy set. Na jego podstawie szacowane jest e1RM.'
		},
		{
			idx: 3,
			rep_range: {min: 6, max: 8, semantics: 'estimate'},
			load_spec: {kind: 'relative_to_set', ref_set_idx: 2, pct: 92},
			RIR: 'UNDEFINED',
			role: 'working_backoff',
			comment: 'Backoff, ciężar -8% względem topset, ustalona liczba powtórzeń. RIR wyjdzie jaki wyjdzie'
		},
		{
			idx: 4,
			rep_range: {min: 5, max: 5, semantics: 'estimate'},
			load_spec: {kind: 'relative_to_set', ref_set_idx: 2, pct: 92},
			RIR: 'UNDEFINED',
			role: 'working_backoff',
			comment: 'Backoff, ciężar -8% względem topset, ustalona liczba powtórzeń. RIR wyjdzie jaki wyjdzie'
		},
	]
}
```

## Implementation guidance

Prefer typed/domain-level representations over unstructured JSON blobs where the existing architecture allows it.

In particular:
- model `load_spec` as a discriminated union keyed by `kind`,
- model set `role` as an enum,
- extend the existing RIR enum rather than introducing a parallel field,
- extend the existing rep-range structure rather than creating another representation,
- reuse existing IDs, DTOs, forms and validation patterns where possible.

Do not redesign unrelated parts of the plan model.
Do not perform broad refactors unless required for these changes.