# Progression agents — delegating progression to an automated coach

> **Read this before touching prescription loads, progression models, or the plan-backed
> fallback.** The narrow thing agents do *today* is not what they are for. Several steps in
> the design look redundant until you know the destination, and have been removed by
> accident before.

## What this is

A progression agent is an **automated coach**. The athlete delegates the management of
progression for an exercise to it, and from then on the agent decides what that exercise
should weigh at the next exposure — the same decision a coach makes when reviewing last
week's session, applied automatically, every time, according to the progression model the
plan prescribes.

Progression management is the recurring work of training: look at what was performed, decide
whether the athlete earned more weight, more reps, or a repeat, and write the next
prescription. Agonez already models *how* that decision should be made — every exercise
variant carries a `progression_model_slug` (double progression, single progression, 2-for-2,
…). Until now that model was documentation for a human: the athlete or coach read it and did
Post-Workout-Analysis by hand on desktop. An agent executes it.

This is a product capability, not an implementation detail. The athlete chooses, per
exercise, whether to steer progression themselves or hand it to the automata. Both must
remain possible, and a delegated decision must always be visible and overridable — which is
why every prescribed load records who decided it.

## What is built today, and what is not

**Built:** the agent contract, the registry that selects an agent per exercise, and one
agent — `RepeatLastExposureAgent`, which repeats the last exposure's loads without
progressing them.

**Where it runs today:** exactly one moment — plan-backed fallback preparation, when the
athlete starts a session whose Post-Workout-Analysis is incomplete. That is a **workaround**
for a real problem (analysis is saved one exercise at a time, and the athlete turns up at the
gym with half a prescription), and it is the narrowest useful deployment of the capability.
It is a beachhead, not the goal.

**Not built yet:**

- Model-aware agents. No agent reads the progression model yet; every model resolves to the
  default. A double-progression agent would check whether the ceiling of the rep range was
  reached on every working set and add `load_step_kg` when it was.
- Running after a workout is finalized, which is where an agent belongs as a coach: the
  athlete finishes, the agent reviews the performance and writes the next exposure's
  prescription without anyone opening desktop.
- Delegation as an explicit, per-exercise athlete choice, with the desktop surfacing what the
  agent decided and why, and letting a human override it.

Do not mistake the current entry point for the design. When you add the post-finalization
run, the agent contract below should not need to change — that is the point of it.

## The contract

Defined in `be/src/agonez_api/modules/execution/progression.py`.

```python
resolve_loads(ProgressionRequest(
    progression_model_slug=...,   # the model the athlete delegated to
    planned_sets=...,             # the plan's sets: ordinal, role, rep range, target RIR
    last_exposure=...,            # what was actually performed: loads, reps, RIR, per set
    load_step_kg=...,             # the exercise's load increment, if any
)) -> tuple[ResolvedLoad, ...]    # one decided load + its source per planned set
```

Three properties matter and must be preserved:

1. **An agent is a pure function.** No database, no clock, no randomness. The same input
   always yields the same decision. This is what lets a preview and a write produce
   identical answers, lets a decision be explained after the fact, and lets agents be
   unit-tested without a database.
2. **An agent decides loads and nothing else.** Rep ranges, RIR targets, set count and roles
   come from the plan. An agent that wants to change the rep range is asking for a different
   contract — come back and design it rather than widening this one quietly.
3. **An agent says where its answer came from.** `ResolvedLoad.source` is persisted to
   `exec.set_prescriptions.load_source`, so a machine decision is never mistaken for a human
   one.

`agent_for(progression_model_slug)` selects the agent; unknown and unset models fall back to
the default, so an exercise always gets an answer.

### Today's agent: `RepeatLastExposureAgent` (`load_source = 'last_exposure'`)

Repeats what was lifted. It does not progress, because repeating is the honest default when
no model-aware agent has been written yet. Matching is **role-aware**:

1. Only sets really **performed with an explicit load** at the matched exposure count.
   Skipped and not-performed sets never do.
2. Those sets are grouped by the role they were prescribed under. Sets the athlete added
   outside the plan have no role and are ignored.
3. A planned set that is the *k*-th of its role takes the load of the *k*-th usable set of
   that same role.
4. If that role has fewer usable sets, it repeats the last one — three working sets last
   week, four this week, the fourth repeats the third.
5. If that role has **no** usable set, the load stays `null`.

**Loads never cross a role boundary.** A ramp-up must not inherit a working-set weight, and
`null` is the honest answer for a first exposure or a role the athlete skipped entirely. The
agent never rounds to `load_step_kg`: rounding is a progression decision, and this agent
makes none.

## What an agent needs to know: the last exposure

An agent can only coach from evidence. The evidence is the athlete's last exposure of that
exercise, resolved by the `plan_exercises` query in `_ensure_fallback_prescription`
(`mobile_execution/repository.py`). An exposure qualifies when **all** of these hold:

| Condition | Why |
| --- | --- |
| Same run-scoped exercise track (`logical_key = 'slot:<ordinal>'`) | The track is the stable identity of "this slot across microcycles". |
| `workout_unit_performances.status = 'finalized'` | A draft workout is still being edited; its loads are not evidence yet. |
| `actual_exercise_id` equals the slot's **DEFAULT** variant exercise | If the athlete substituted last time, that other exercise's loads say nothing about this one. The search falls through to an earlier matching exposure. |
| At least one `performed` set with an explicit load | An exposure where everything was skipped teaches nothing. |
| Same plan run, and not this session | A run is a closed world; a session never inherits from itself. |

Ordered by **`workout_unit_performances.completed_at` descending** — the most recent exposure
*by when it was actually performed*. Deliberately **not** by microcycle ordinal: a workout
unit can recur several times inside one microcycle, and an off-schedule start performs a
session whose planned date differs from its real one. Ordering by ordinal would silently
ignore the athlete's most recent real training — the very evidence a coach would look at
first.

When model-aware agents arrive they will want more than the last exposure (a trend across
several). That is a change to how evidence is gathered, not to the agent contract:
`ProgressionRequest` gains a field, and agents that ignore it keep working.

## Where it runs today: fallback preparation

```text
Home (preview, read-only)                    Start (write)
──────────────────────────                   ─────────────
GET  /mobile/context                         POST /sessions/{id}/prescription/fallback
  readiness: ready | missing                   └─ _ensure_fallback_prescription   ← one function
       │                                          │
       ├─ ready   → start directly               ├─ resolve plan slots + DEFAULT variants
       │                                          ├─ resolve each exercise's LAST EXPOSURE
       └─ missing →                               ├─ ask the PROGRESSION AGENT for loads
          GET /sessions/{id}/prescription/        ├─ insert/refresh plan_fallback rows
              fallback   (preview: true)          └─ fill still-empty loads (re-preparation)
            └─ _ensure_fallback_prescription            │
               in a ROLLED-BACK transaction             ▼
               → same answer, nothing written      POST /mobile/workouts
```

**The preview and the write path run the same function.** `preview_fallback_prescription`
calls `_ensure_fallback_prescription` inside `connection.transaction(force_rollback=True)`
and returns what it built. That is why they cannot disagree: there is no second
implementation to drift. If you ever "optimise" the preview into its own query, you have
reintroduced the drift this design exists to prevent.

A preview is marked `preview: true`, has `prescription_version: null`, and the rows it would
generate carry `null` ids. **The app must never start from a preview** — it prepares with the
`POST` first, which returns real ids and a version.

## Who decided a load

Two kinds of deciders write `exec.set_prescriptions.prescribed_load_kg`, and
`load_source` records which:

| `load_source` | Decider |
| --- | --- |
| `analysis` | A human: Post-Workout-Analysis on desktop, one exercise at a time. |
| `last_exposure` | The default agent, repeating the previous exposure. |
| *(one value per future agent)* | A model-aware agent executing a delegated progression model. |
| `null` | Nothing decided — no load is prescribed. |

Keep these distinguishable. An athlete who delegated progression still has the right to see
what the automata chose and to overrule it, and that is impossible if a machine decision is
indistinguishable from their own.

## Adding a model-aware agent

1. Write the agent as a pure function of `ProgressionRequest` and register it under its
   `progression_model_slug` with `register_agent(...)`.
2. Add its value to the `exec.prescribed_load_source` enum in a migration, and return that
   value as `ResolvedLoad.source`.
3. Add the value to `PrescriptionSet.load_source` in `mobile_execution/schemas.py` and tell
   the mobile agent, so the app can label it.
4. Unit-test the agent on its own. It is pure; it needs no database.
5. Decide, deliberately and with the product owner, **when** it runs. If it should coach
   after every workout rather than only at fallback preparation, that is new wiring —
   design it, do not bolt it onto the fallback path because that is where the call already
   sits.

```python
class DoubleProgressionAgent:
    slug = "double_progression"

    def resolve(self, request: ProgressionRequest) -> tuple[ResolvedLoad, ...]:
        ...  # ceiling of the rep range reached on all working sets → load + load_step_kg
             #                                          otherwise → repeat the load

register_agent("double_progression", DoubleProgressionAgent())
```

Nothing else changes. The repository, the preview and the start already route through
`agent_for`.

## Rules that must not be broken

- **Only loads are decided by an agent.** Reps, RIR, set count and roles come from the plan.
- **Agents stay pure.** A database call or a clock inside an agent breaks the preview's
  equality with the write path and makes a decision unexplainable afterwards.
- **Generated rows are never analysis.** They keep
  `exercise_unit_prescriptions.generation_source = 'plan_fallback'`, so desktop's
  analysis-only completeness, its "based on" logic and the promotion of a generated row to
  `analysis` behave as before. A load decided by an agent does not mean the exercise was
  analysed by a human.
- **A session holding any `plan_fallback` row still reads `readiness: missing`** in
  `GET /mobile/context`. Readiness means "startable as the prescription stands"; the app
  prepares before starting either way.
- **A decided load is never silently revised.** Preparation skips exercises already marked
  `analysis`, and re-preparation only fills loads that are still empty. An agent does not
  overrule a human, and it does not overrule its own earlier answer behind the athlete's
  back.
- **Nothing is written outside the explicit `POST`.** The context, `GET .../prescription`
  and the preview are read-only.
- **A started or finalized session is frozen.** Preparation refuses anything that is not
  `scheduled` or `missed` with `session_not_startable`.
- **No N+1.** Every matched exposure is read in one statement, whatever the exercise count.

## Where the pieces live

| Concern | File |
| --- | --- |
| Agent contract, registry, default agent | `be/src/agonez_api/modules/execution/progression.py` |
| Last-exposure resolution, agent call, writes | `be/src/agonez_api/modules/mobile_execution/repository.py` (`_ensure_fallback_prescription`, `_resolve_fallback_loads`, `_fill_missing_fallback_loads`) |
| Preview (rolled-back materialization) | same file, `preview_fallback_prescription` |
| Load provenance column and enum | `be/src/agonez_api/migrations/versions/0014_prescription_load_provenance.sql` |
| Agent unit tests | `be/tests/test_progression_agents.py` |
| Flow tests | `be/tests/test_mobile_execution.py` |
