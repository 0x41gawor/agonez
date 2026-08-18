# Agonez PlanCreator Analysis V1 — implementation handoff

Status: implemented and calibrated on 2026-08-18

## Scope and architecture

Analysis V1 is a read-only derived pipeline. It does not add database tables, mutate a
draft, or cache results.

```text
Persisted PlanDraft + catalog snapshot
  -> PlanResolver
  -> immutable ResolvedPlan
  -> contribution evaluator
       -> ETUAnalyzer behavior
       -> MuscleRecoveryAnalyzer behavior (MRU)
       -> JointRecoveryAnalyzer behavior (JRU)
  -> 168-hour periodic RecoverySimulator
  -> PlanAnalysisResult
```

The existing HTTP/service/repository boundary remains intact. `PlanRepository` now has
one repeatable-read, read-only snapshot operation that loads the DRAFT revision plus the
relevant engine exercises and authoritative muscle FCSA catalog. The new analysis
service assembles the existing PlanDraft response, resolves it, and invokes a pure
evaluator.

Key files:

- `src/agonez_api/modules/plans/analysis/domain.py`: immutable ResolvedPlan and catalog
  domain objects.
- `src/agonez_api/modules/plans/analysis/resolver.py`: DEFAULT-variant selection,
  volume-level gating, rest-day preservation, and weekly offsets.
- `src/agonez_api/modules/plans/analysis/evaluator.py`: ETU/MRU/JRU contribution
  generation, aggregation, diagnostics, and periodic recovery simulation.
- `src/agonez_api/modules/plans/analysis/parameters.py`: centralized, versioned V1
  calibration parameters.
- `src/agonez_api/modules/plans/analysis/schemas.py`: request and separate derived
  response contract.
- `src/agonez_api/modules/plans/analysis/service.py`: repository/resolver/evaluator
  orchestration.
- `scripts/calibrate_plan_analysis.py`: reproducible, read-only real-catalog calibration
  report.
- `tests/test_plan_analysis.py`: deterministic resolver/evaluator coverage.

No frontend Analysis tab is included in this backend-only task.

## API contract

```http
POST /api/plans/{plan_id}/draft/analysis
Content-Type: application/json
```

Default request:

```json
{
  "resolution_context": {
    "global_volume_level": 0,
    "focus_area": null,
    "axis_overrides": {}
  }
}
```

The response declares `model_version: "plan-analysis-v1"` and includes the plan,
revision, revision number, and draft lock version that were analyzed. It also returns:

- resolution context and per-day timing assumptions;
- every V1 model parameter needed to interpret/reproduce the result;
- overall convergence status and simulated cycle count;
- plan-level muscle and joint summaries;
- a chronological day timeline including explicit rest days, workload stimulus, and
  recovery state before/after each entry;
- per-set muscle and joint contribution provenance;
- explicit informational, warning, or error diagnostics.

The endpoint returns normal PlanCreator 404 behavior for a missing plan/draft and never
changes `lock_version`.

## Exact ResolvedPlan semantics

ResolvedPlan is an immutable, non-persisted snapshot containing:

- plan ID, DRAFT revision ID/number, and lock version;
- the submitted resolution context;
- all ordered plan days, including rest days;
- each day's deterministic hour offset inside a repeating 168-hour microcycle;
- ordered workout units and stable slot IDs;
- slot role, goal, volume axis, effective volume level, and intentional target slugs;
- zero or one selected exercise for each slot;
- stable IDs, ordinals, rep ranges, RIR, and minimum-volume level for active sets.

Only `DEFAULT` ExerciseVariant is selected. `FALLBACK` rows remain substitution options
and never contribute at the same time. An otherwise empty slot remains empty.

For each slot:

```text
effective_volume_level =
  axis_overrides[slot.volume_axis] when that override exists
  else global_volume_level
```

A DEFAULT set is active when:

```text
set.min_volume_level <= effective_volume_level
```

V1 UI usage is the default context (`global_volume_level = 0`, no focus area, no axis
overrides), but the abstraction is already ready for Modulation.

## Weekly timing

- Monday maps to hour 0, Tuesday to 24, through Sunday at 144.
- A day without a weekday uses `ordinal * 24` deterministically and emits
  `ORDINAL_TIMING_ASSUMPTION`.
- Ordinal offsets beyond the weekly boundary wrap modulo 168 and emit
  `ORDINAL_TIMING_WRAPPED`.
- Events sharing an offset are processed deterministically by day ordinal and stable ID.
- Exact clock times are intentionally absent; only elapsed hours matter.

## Exact ETU equation

```text
effective_reps = 5 - RIR

set_etu[muscle] =
  effective_reps * exercise.etu_vector[muscle]
```

The allowed RIR range therefore maps RIR0→5, RIR1→4, RIR2→3, RIR3→2, RIR4→1.
Rep-range fields do not change ETU in V1.

Per muscle:

```text
etu_per_fcsa_cm2 =
  total_etu / core.muscles.pcsa_projected_fcsa_cm2
```

`total_etu_scalar` is the sum of all muscle ETU contributions. It is descriptive only,
not a whole-body biological score.

Intent classification is slot-relative:

- declared target muscle: `INTENTIONAL`;
- other contributing muscle when targets exist: `INCIDENTAL`;
- every contribution from a slot without target declarations: `UNCLASSIFIED`.

## Exact MRU equation

Muscle Recovery Units are separate from ETU:

```text
base_mru =
  effective_reps
  * active_tension_exposure_vector[muscle]
  * muscle_recovery_cost_modifier_vector[muscle]

set_mru =
  base_mru
  * rir_recovery_multiplier[RIR]
  * min(1 + 0.05 * prior_contributing_sets_for_muscle, 1.30)
```

The RIR recovery multipliers are RIR4 1.00, RIR3 1.00, RIR2 1.00, RIR1 1.05,
and RIR0 1.15. Only meaningfully positive raw MRU advances the within-workout muscle
set counter.

Workout recovery time is:

```text
mru_density = workout_mru / projected_fcsa_cm2

muscle_recovery_hours_added =
  mru_density / 0.289425511
```

The velocity has units of MRU per cm² projected FCSA per hour. FCSA is a recovery
capacity denominator; V1 does not make a larger muscle slower merely for being larger.

## Exact JRU equation

```text
joint_load_exposure =
  effective_reps * joint_load_exposure_vector[joint]

set_jru =
  joint_load_exposure
  * rir_recovery_multiplier[RIR]
  * min(1 + 0.05 * prior_contributing_sets_for_joint, 1.30)

joint_recovery_hours_added =
  workout_jru / 0.312
```

V1 has no joint-specific anatomical capacity denominator. This is explicitly a
joint-load readiness/recovery model, not literal tissue-healing time.

## Periodic steady-state simulation

Muscle and joint state use `hours_to_fresh` debt. Between events:

```text
hours_to_fresh = max(0, hours_to_fresh - elapsed_hours)
```

After a workout, its calculated recovery hours are added. One full cycle processes all
day boundaries in chronological order and then decays through hour 168. The end state is
fed into the next repeated microcycle. Iteration stops when the largest start/end state
difference is no more than `0.000001` hour, with a maximum of 256 cycles.

The final fixed-point cycle supplies the response timeline, preventing an artificial
"fresh Monday" assumption. If any resource keeps accumulating debt, the response keeps
the last inspectable cycle and emits `RECOVERY_DIVERGENCE` with the affected muscles and
joints. It is never silently clamped.

## Calibration method and final parameters

The utility uses current database vectors and FCSA values without writing any rows.
Three dose bands are represented:

- light: three RIR2 sets, 30-hour central target (24–36 h band);
- standard: five sets at RIR2/RIR1, 48-hour central target (36–54 h band);
- high/failure-heavy: six sets at RIR1/RIR0, 66-hour central target (60–72 h band).

For muscle anchors it calculates raw MRU, divides by real projected FCSA, derives each
candidate velocity as density/target hours, and uses the median of all 12 candidates.
The resulting fitted value is `0.289425511033`, frozen as `0.289425511`.

| Muscle anchor | Band | Raw MRU | MRU/FCSA | Candidate velocity | Predicted h |
|---|---:|---:|---:|---:|---:|
| Bench press / sternal pec | light | 456.964200 | 8.544581 | 0.284819372 | 29.523 |
| Bench press / sternal pec | standard | 928.435200 | 17.360419 | 0.361675393 | 59.982 |
| Bench press / sternal pec | high | 1543.281740 | 28.857175 | 0.437229930 | 99.705 |
| Chest-supported row / latissimus | light | 319.405275 | 7.284043 | 0.242801425 | 25.167 |
| Chest-supported row / latissimus | standard | 648.950400 | 14.799325 | 0.308319270 | 51.133 |
| Chest-supported row / latissimus | high | 1078.711043 | 24.600024 | 0.372727633 | 84.996 |
| Leg extension / vastus lateralis | light | 1020.978000 | 4.198618 | 0.139953942 | 14.507 |
| Leg extension / vastus lateralis | standard | 2074.368000 | 8.530526 | 0.177719291 | 29.474 |
| Leg extension / vastus lateralis | high | 3448.096600 | 14.179778 | 0.214845120 | 48.993 |
| Barbell curl / biceps | light | 276.540075 | 6.946498 | 0.231549925 | 24.001 |
| Barbell curl / biceps | standard | 561.859200 | 14.113519 | 0.294031650 | 48.764 |
| Barbell curl / biceps | high | 933.944602 | 23.460050 | 0.355455308 | 81.057 |

Joint calibration intentionally keeps one representative joint/exercise pair constant
across the three exposure bands so the dose response remains inspectable. The median
candidate is exactly `0.312 JRU/hour`.

| Joint anchor | Band | Raw JRU | Candidate velocity | Predicted h |
|---|---:|---:|---:|---:|
| Bench press / glenohumeral | light | 7.371000 | 0.245700000 | 23.625 |
| Bench press / glenohumeral | standard | 14.976000 | 0.312000000 | 48.000 |
| Bench press / glenohumeral | high | 24.893700 | 0.377177273 | 79.788 |

### Calibration uncertainty

The one-parameter fit does not place every anchor inside its conceptual band. High-dose
predictions are often above 72 hours because effective reps, the near-failure multiplier,
and the cumulative-set penalty all rise together. The quadriceps anchor predicts shorter
times because the catalog's projected FCSA is large relative to its active-tension
vector. The joint high anchor predicts 79.8 hours.

These mismatches are deliberately visible. V1 keeps one global velocity and the exact
requested equations instead of introducing hidden class-specific fitting. The utility
makes a later recalibration or a future model-version change reproducible.

## Engine-data observations and diagnostics

Current production observations:

- 49 core exercises and 49 matching engine rows;
- every engine row currently has all four non-empty JSON object vectors;
- the three muscle vectors have identical key sets per exercise;
- 47 canonical muscle keys, matching `core.muscles.slug`;
- 11 observed joint slugs; there is no separate canonical joint table yet;
- ETU range 0.48–179.19, active tension 0.60–155.82, recovery modifier
  0.95–1.15, and joint load 0.06–0.90;
- all 47 projected FCSA values are positive, ranging from 4.50 to 243.17 cm².

Sparse absence of a muscle key means zero exposure in current engine semantics. If a
whole vector is missing, malformed, or has unmatched active/modifier keys in the future,
the evaluator returns the calculable partial result and a diagnostic rather than
inventing data. Supported diagnostics include:

- `MISSING_ETU_VECTOR`;
- `MISSING_ACTIVE_TENSION_VECTOR`;
- `MISSING_RECOVERY_MODIFIER_VECTOR`;
- `MISSING_JOINT_LOAD_VECTOR`;
- corresponding `MALFORMED_*` codes;
- `MALFORMED_RECOVERY_VECTOR_KEYS`;
- `MISSING_FCSA`;
- `RECOVERY_DIVERGENCE`.

## Verification

Deterministic tests cover:

- RIR0/RIR4 effective reps and ETU equations;
- DEFAULT-only resolution, FALLBACK exclusion, stable provenance IDs, and
  volume-axis/min-level gating;
- absolute ETU, FCSA normalization, and all three intent classes;
- base MRU, near-failure penalty, cumulative penalty, and 1.30 cap;
- MRU/JRU conversion, linear decay, rest days, overlap, and before/after snapshots;
- periodic carry-over, convergence, and intentional divergence;
- exact contribution-to-summary reconciliation;
- partial/malformed engine-data diagnostics;
- PlanDraft immutability and explicit model version;
- OpenAPI presence and a live persisted-draft endpoint scenario.

Final verification results:

- 34 backend tests passed;
- Ruff passed;
- strict mypy passed across 32 source files;
- OpenAPI includes the Analysis POST contract;
- calibration utility reproduced both frozen values exactly to the stored precision;
- all 13 self-cleaning live PlanCreator scenarios passed;
- rebuilt `agonez-atlas-api:local` and deployed `be-atlas-api-1` healthy on port 33287;
- deployed plan 6 analysis returned 7 timeline days, 47 muscles, 11 joints, and 2,073
  explainable contributions without changing lock version 55.

Plan 6 produces an explicit `RECOVERY_DIVERGENCE` diagnostic after 256 cycles for 20
muscles and 7 joints under the frozen V1 calibration. This is not hidden or clamped. It
is an important manual-review signal: either the plan is strongly overloaded under the
requested equations, or later calibration/model-version work should adjust the global
one-parameter recovery model.

## Intentionally deferred

- Analysis frontend/tab;
- focus-area and editable volume-profile policy;
- muscle-specific recovery velocities, architecture/fiber modifiers;
- systemic, cardiovascular, neural, connective-tissue, and tendon models;
- real execution/calendar data, actual loads/reps/RIR, and progression;
- PlanExecution, analysis persistence/cache, and automatic plan changes;
- a separately governed canonical joint catalog/capacity model.
