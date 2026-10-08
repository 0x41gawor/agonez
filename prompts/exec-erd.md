# Agonez Execution Module — Database Domain Model, ERD, Mock Data and Domain Invariants

## Mission

We are introducing the next major Agonez domain: **Execution (`exec`)**.

Agonez currently has two important layers:

- **Atlas** — exercise / biomechanics / analysis domain, primarily represented by the existing `core` and `engine` schemas.
- **Plans** — workout-plan modelling domain, represented by the existing `plans` schema.
- **Execution** — the new domain you are going to design and implement at the **database/data-model layer only**.

The fundamental distinction is:

> `plans` defines what the training program is.
> `exec` represents a concrete athlete executing that plan over calendar time.

A plan is therefore a reusable prescription/infrastructure artifact.

An `exec.plan_run` is a concrete attempt to follow a specific plan, starting on a concrete date and lasting a concrete number of microcycles.

Your task is to understand the existing repository first, then design and implement the initial `exec` database schema, populate it with realistic mock execution data based on one existing plan, document it thoroughly, and formalize its domain invariants.

Do **not** implement the backend API, frontend, mobile app, or UI in this task.

---

# 1. First: repository discovery

Before changing anything, inspect the repository carefully.

You must understand the existing data model rather than building a parallel model based only on this prompt.

At minimum inspect:

1. the complete `plans` schema,
2. the relevant `core` schema,
3. the relevant `engine` schema,
4. all database migrations / initialization / seed mechanisms,
5. ORM models if they exist,
6. existing SQL conventions,
7. enum conventions,
8. PK/FK naming conventions,
9. timestamps / audit-column conventions,
10. the complete existing `docs` directory.

Especially read the existing project/domain documentation and `dictionary.md` from the prompt.

Treat `dictionary.md` as the primary source for Agonez terminology relevant for this task. 

Do not invent alternative terminology when an established Agonez term already exists.

Before implementation, identify the concrete existing objects corresponding to concepts such as:

- plan,
- plan revision,
- microcycle duration,
- plan day,
- workout-unit,
- exercise-slot,
- exercise-variant,
- set infrastructure prescription,
- progression model / progression identity if one already exists,
- exercise identity,
- analysis data coming from `engine`.

Also determine how plan revisions are represented and whether identities of workout-units / exercise-slots survive across revisions.

This last point is particularly important.

---

# 2. Core domain model

The core object of the new domain is:

## `exec.plan_run`

A `plan_run` represents a concrete athlete taking a workout plan and executing it for a defined period.

Typical attributes include:

- `id`
- name
- description
- athlete/user identity if the current project already has such a concept
- starting date
- number of microcycles
- initial / starting `plan_revision_id`
- calculated finishing date
- status

Expected lifecycle statuses:

- `scheduled`
- `active`
- `cancelled`
- `completed`

Do not introduce a `paused` state.

One of the current domain assumptions is that a plan run cannot be paused. Breaks from training should become visible through missed/cancelled sessions and/or plan-run events.

The finishing date should be derivable from:

- starting date,
- number of microcycles,
- duration of the microcycle defined by the selected plan revision.

Eventually this will be calculated by the server when creating a plan run.

There is no backend implementation in this task, but the data model must support this behaviour and mock data should follow the same calculation.

---

# 3. Calendar projection — workout sessions

When a plan run is instantiated, workout-units defined in the plan need to be projected onto real calendar dates.

The central object should conceptually be:

## `exec.workout_sessions`

Do not call this `scheduled_workout_sessions`.

Scheduling is merely one lifecycle state of the session.

A workout session places a workout-unit on the real calendar.

For example:

```text
Plan:
Microcycle duration = 7 days

Day 1 -> Push
Day 2 -> Pull
Day 3 -> Rest
Day 4 -> Legs
...

Plan run starts:
2026-09-01

Execution projection:

2026-09-01 -> Push session
2026-09-02 -> Pull session
2026-09-04 -> Legs session
...
```

A workout session should have enough information to answer:

- which plan run it belongs to,
- which microcycle occurrence it belongs to,
- which logical workout-unit it represents,
- what date it was scheduled for,
- what its current lifecycle state is,
- which plan revision produced it,
- which prescription was assigned to it,
- which performance artifact resulted from it.

Expected session status enum:

```text
scheduled
in_progress
completed
cancelled
missed
```

Semantics:

- `scheduled` — future/planned session,
- `in_progress` — athlete has started it,
- `completed` — workout was finished,
- `cancelled` — deliberately cancelled in advance, e.g. recovery reasons,
- `missed` — the expected workout date passed without the session being performed.

Completion is a separate concern.

Use something equivalent to:

```text
completion_mode:
    as_prescribed
    fallback
    NULL
```

Do not collapse completion state and completion mode into one enum.

For example:

```text
status = completed
completion_mode = fallback
```

is different from:

```text
status = completed
completion_mode = as_prescribed
```

The Plan Creator does **not yet implement fallback workout-units**.

Nevertheless, Execution must contain an appropriate future-compatible placeholder so that fallback execution can be supported later without redesigning the fundamental session lifecycle.

Do not invent an entire fallback-planning subsystem in this task.

---

# 4. Microcycle instances

Investigate whether it is useful to materialize concrete microcycle occurrences inside a plan run.

A likely candidate is something such as:

```text
exec.microcycles
```

with attributes including, where appropriate:

- id
- plan_run_id
- ordinal
- start_date
- end_date
- plan_revision_id
- comment / notes
- classification

Potential classification examples:

```text
normal
deload
reload
...
```

Do not mechanically implement exactly this shape if the existing repository suggests a better model.

The purpose is to answer questions efficiently such as:

- which microcycle/week is this session in?
- which plan revision governed this microcycle?
- was this a deload?
- what were the start/end calendar dates?
- what notes were attached to this week?
- what happened to progression across microcycles?

It is acceptable for this table to duplicate some information that could theoretically be derived if that information represents an important execution-domain fact or substantially simplifies trace/history queries.

Explain your decision.

If you decide **not** to create a persisted microcycle entity, provide an equivalent mechanism and document why it is superior.

---

# 5. Prescription versus performance

This distinction is fundamental to Agonez.

A workout has two different execution artifacts:

```text
what should be done
        ↓
exec workout-unit prescription

what was actually done
        ↓
exec workout-unit performance
```

These must not be merged.

---

# 6. Workout-unit prescription

Conceptually:

## `exec.workout_unit_prescribed`

or another name consistent with existing repository naming conventions.

A prescription is based on the workout-unit infrastructure from `plans`, but is now resolved for a concrete athlete and concrete exposure.

The Plans module knows things such as:

- exercise,
- exercise-slot role,
- number of sets,
- rep range,
- target RIR,
- progression intent,
- set infrastructure.

Execution prescription adds concrete information such as:

- actual prescribed load,
- per-exercise-unit comments,
- per-set comments.

The prescription is therefore roughly:

```text
Plan infrastructure prescription
+
athlete-specific resolution (load)
+
exposure-specific instructions (comments)
```

## Historical immutability

Prescriptions are historical execution artifacts.

If the underlying plan revision is modified in the future, a prescription from September must still mean exactly what it meant in September.

Therefore design explicit lineage to the originating plan entities while preserving enough execution data to reconstruct historical prescriptions safely.

Do not create a fragile model where historical execution silently changes because a plan definition changed later.

Investigate the best solution given the current repository:

- snapshotting,
- explicit copied execution entities,
- immutable revision references,
- or another equivalent mechanism.

Document the chosen strategy.

---

# 7. Workout-unit performance

Conceptually:

## `exec.workout_unit_performed`

This represents the athlete's actual execution of a prescribed workout-unit.

Ultimately this artifact will be created by the mobile application.

The performance model needs to record actual values at sufficiently low granularity.

At minimum the model must support actual values per set, including concepts such as:

- exercise / exercise variant actually used,
- load,
- repetitions,
- RIR,
- comments,
- skipped sets,
- additional sets,
- prescription/performance divergence.

The system must support:

```text
prescribed load != performed load
prescribed exercise variant != performed variant
prescribed set count != performed set count
```

because the purpose of this layer is to store **field data**, not simply confirmation that the prescription was followed.
 
But the intention is to comply with the prescr in 99% of cases. Agonez will enforce some discipline on the user.
---

# 8. In-progress workouts

The mobile application will eventually need to synchronize the workout while it is being performed.

The athlete can:

1. open the workout,
2. perform several sets,
3. close/kill the application,
4. return later.

The database design must therefore not prevent partial/in-progress synchronization.

Prefer modelling this naturally through the workout-session/performance lifecycle instead of inventing an unnecessary parallel domain.

For example, an `in_progress` workout session may have a draft/incomplete performance artifact.

Do not implement the mobile sync protocol in this task.

Only ensure that the data model can support it.

---

# 9. Post-Workout-Analysis

Agonez has an important workflow called:

## Post-Workout-Analysis

After observing performance, the athlete/trainer/automata analyses field data and prepares prescriptions for the next exposure.

The general progression chain is:

```text
prescription N
      ↓
performance N
      ↓
Post-Workout-Analysis
      ↓
prescription N+1
```

For a repeated workout/exercise trace, a subsequent prescription should normally not be created before the previous required exposure has a corresponding performance artifact.

The exact invariant must account for independent workout-unit/exercise traces.

Do **not** introduce an unnecessarily global rule such as:

> no prescription anywhere in microcycle N+1 can exist until every session in N is completed

if the domain structure does not require it.

The relevant progression traces can be independent.

The initial prescription of the first exposure is obviously a special case and must be possible without an earlier performance.

Document the exact invariant you choose.

Eventually this workflow will be performed from the desktop application.

In v2 it may also be automated based on a progression model.

No UI or automation is required now.

---

# 10. Repeatable-unit identity — critical design problem

This is one of the most important parts of this task.

Agonez analyses progression over repeated exposures.

There are three important repeatable levels:

```text
microcycle
workout-unit
exercise-unit
```

For example, the system must be able to answer:

> Show me every exposure of the logical Bench Press exercise-unit from the Monday Push workout across the entire plan run.

This becomes non-trivial when:

- a new `plans.plan_revision` is created,
- database IDs of plan structures change,
- an exercise is modified,
- exercise variants change,
- the plan evolves during the plan run.

Investigate the current schemas carefully.

Determine whether the existing data model already has a stable identity suitable for following the same logical repeatable-unit across plan revisions.

Potential candidates may include:

- existing stable workout-unit identity,
- exercise-slot identity,
- progression identity,
- another existing semantic identifier.

Do not assume such an identity exists.

If it does exist, reuse it.

If it does not, design the smallest clean mechanism that solves the problem.

This may involve an execution lineage/mapping concept.

Do not unnecessarily modify the `plans` schema if the issue can be solved cleanly inside `exec`.

However, if a correct solution fundamentally requires a stable identifier in `plans`, document and implement the minimal required change.

Your documentation must explicitly contain a section:

```text
Repeatable Unit Identity
```

explaining:

1. what identity existed before,
2. whether it was sufficient,
3. what mechanism is used now,
4. how traces survive plan revisions,
5. what happens when an exercise is genuinely replaced and should begin a new trace.

This design must be intentional, not accidental.

---

# 11. Plan revision changes during a plan run

A `plan_run` starts from a concrete `plans.plan_revision`.

However, that plan may evolve during execution.

Examples:

- athlete changes exercise,
- volume is modified,
- exercise is deleted,
- exercise is added,
- recovery observations trigger a plan change,
- unavailable equipment requires modification.

Such a modification creates a new plan revision.

Execution must preserve historical knowledge of:

- which revision started the plan run,
- when a newer revision became effective,
- which concrete sessions/microcycles were generated from which revision.

A single mutable:

```text
plan_run.plan_revision_id
```

is therefore not sufficient as the entire history model.

You may solve this using:

- microcycle-level revision references,
- explicit revision history,
- effective-from semantics,
- or another clean mechanism.

Use the existing architecture and choose the most coherent model.

Historical sessions and prescriptions must remain attributable to their original revision.

---

# 12. Comments

Agonez intentionally distinguishes comments at different lifecycle stages.

An exercise-unit may have comments at:

```text
plans
exec prescription
exec performance
```

Their semantics differ.

### Plan comment

Long-lived programming/technique instruction.

Example:

> Put the feet slightly forward to bias the quads rather than the glutes.

### Prescription comment

Exposure-specific instruction created during Post-Workout-Analysis.

Examples:

> Try 70 kg today and verify technique.

> Use both cables on this machine.

### Performance comment

Field observation entered during the workout.

Examples:

> Technique broke down in the last set.

> I used two cables today.

These comments may also exist at different scopes:

```text
exercise-unit level
per-set level
```

Design the execution model so these distinctions remain representable.

Avoid a generic comments blob if it destroys useful structural semantics.

---

# 13. Plan-run events

Create an execution-domain event/history mechanism.

Expected conceptual entity:

```text
exec.plan_run_events
```

Do not use `exerc`.

This event stream/log behaves somewhat like a lightweight journal/blog for the plan run.

Potential event types defined by the domain dictionary include:

- plan modified / new plan revision introduced,
- personal record,
- deload started,
- reload started,
- vacation,
- training break,
- free-form observation/comment.

Each event should be placeable on both:

- calendar time,
- plan-run time.

In other words, from an event we should be able to determine something like:

```text
2026-09-23
microcycle 4 (or week 4)
```

where meaningful.

Use a consistent event structure.

Do not over-engineer an enterprise event-sourcing system.

This is an execution history feature, not infrastructure for distributed event sourcing.

---

# 14. MARKER.X and historical analytical data

`dictionary.md` describes a future metric currently called `MARKER.X`.

Its purpose is approximately:

> Am I actually progressing?

It should ultimately measure performance progression over repeated exposures and be usable for:

- workout-unit traces,
- microcycle traces.

The exact final formula/name is not part of this task.

Do **not** freeze an unstable business formula into the database architecture unnecessarily.

However, the new schema must preserve all historical inputs necessary to calculate metrics of this kind later.

That includes especially:

- performed loads,
- repetitions,
- RIR,
- exercises/exercise identity,
- comparable exposure identity,
- time/microcycle,
- plan context,
- access to the relevant engine/ETU characteristics.

Think also about reproducibility if analytical formulas evolve later.

If useful, propose lightweight versioning/provenance for derived calculations, but do not build a large metric subsystem.

---

# 15. Required future read use-cases

Do not design UI.

However, the database must make the following read models practical.

Use these as acceptance criteria for the schema.

## A. Exercise-unit trace

This is the single most important read use-case.

The historical inspiration is a spreadsheet where one exercise-unit is displayed vertically across successive weeks.

For every exposure we need to be able to show:

- microcycle/week ordinal,
- actual calendar date,
- prescription,
- performance,
- prescribed load per set,
- performed load per set,
- reps,
- RIR,
- relevant comments,
- exercise variant,
- progression over time.

Example conceptual output:

```text
Bench Press — Monday Push

MC   Date         Prescription        Performance
1    2026-09-01   65 x 7,7,7          65 x 7,6,5
2    2026-09-08   65 x 7,7,7          65 x 7,7,6
3    2026-09-15   67.5 x ...           ...
...
```

Unlike the old spreadsheet, the final model **must support load per set**, not only one load per exercise-unit.

This trace also becomes the main input for Post-Workout-Analysis.

---

## B. Workout-unit trace

Example:

```text
Monday Push
```

across microcycles.

It should be possible to show:

- dates,
- completion history,
- performance/progression,
- future MARKER.X,
- important progressive exercise-slots,
- comments.

---

## C. Microcycle trace

Across the plan run we need to query:

- microcycle ordinal,
- date range,
- plan revision,
- attendance,
- volume-related context,
- normal/deload/reload classification,
- future MARKER.X,
- comments/observations.

---

## D. Trace charts

Exercise/workout/microcycle traces must be suitable for charting over time.

No charts need to be created now.

The underlying data must simply be queryable cleanly.

---

## E. Workout calendar

A calendar-oriented read model needs to show:

- scheduled sessions,
- completed sessions,
- missed sessions,
- cancelled sessions,
- fallback usage,
- real calendar dates,
- attendance.

---

## F. Microcycle/week list

The system should be able to display the full plan run as a list of microcycles, including information such as:

- deload/reload,
- revision changes,
- training-volume context,
- comments.

---

## G. All-loads chart

A future analytical view will plot loads of many exercise traces simultaneously.

It must be possible to retrieve time series such as:

```text
exercise identity
workout/day identity
date
microcycle
set
load
```

without reverse-engineering JSON blobs or parsing comments.

---

## H. Plan-run event log

Chronological event history with both:

- calendar timestamp/date,
- corresponding plan-run/microcycle position.

---

# 16. Relational modelling expectations

Use normalized relational structures where they create useful query semantics.

Do not hide important analytical dimensions inside opaque JSON merely because JSON is convenient.

In particular, values such as:

- individual sets,
- set ordinal,
- prescribed load,
- performed load,
- repetitions,
- RIR,
- logical exercise identity,
- session date,
- microcycle ordinal

should remain practically queryable.

JSON/JSONB is acceptable for genuinely flexible metadata, but not as a substitute for modelling the central execution facts.

At the same time, avoid over-normalization that creates meaningless one-column tables.

Follow the style already established in the repository.

---

# 17. Domain invariants

Create a dedicated document describing **domain invariants**.

Do not merely document columns.

Formalize rules that make the execution data valid.

Examples to investigate and formalize:

- every workout session belongs to exactly one plan run,
- every workout session belongs to one concrete calendar occurrence,
- every session maps to the relevant plan structure / logical workout identity,
- `completed` sessions require a performance artifact,
- non-completed sessions should not incorrectly appear as completed performance,
- a performance artifact must be attributable to the prescription against which the athlete trained,
- historical prescriptions must not change when the plan changes,
- historical performances must not change when the plan changes,
- a later prescription in a progression trace requires the relevant prior performance, except for the first exposure,
- microcycle ordinals are unique within a plan run,
- session dates must belong to the corresponding microcycle boundaries,
- revision transitions cannot rewrite historical sessions,
- set ordinals must be well-defined within an exercise-unit,
- `completion_mode` has meaningful values only for completed sessions,
- `missed` and `cancelled` have intentionally different semantics.

These are examples.

Discover additional invariants from the repository and domain model.

For each important invariant identify whether it should be enforced by:

```text
database FK
UNIQUE constraint
CHECK constraint
database enum/type
application logic
transactional workflow
```

Do not force every business rule into SQL if application-layer enforcement is more appropriate.

The important part is that the ownership of each rule is explicit.

---

# 18. Mock data

After the schema is implemented, populate it with realistic mock data.

## Source

Choose **one real existing plan from the current database/seed data**.

Do not invent an unrelated fake plan if usable existing plans are available.

Document which plan and which plan revision you selected.

## Simulation

Simulate a realistic plan run beginning in **September 2026**.

Prefer a run long enough to produce useful historical traces, for example several completed microcycles plus future scheduled ones.

Populate realistic data covering as many relevant lifecycle cases as reasonably possible:

- completed sessions,
- current/future scheduled sessions,
- at least one missed session,
- at least one cancelled session if appropriate,
- prescriptions,
- performances,
- prescription/performance divergence,
- per-set loads,
- reps,
- RIR,
- prescription comments,
- performance comments,
- microcycle comments,
- plan-run events,
- progression in several exercises over time,
- at least one plateau or non-linear progression pattern,
- a deload/reload classification if supported by the resulting model.

Do not force fallback execution if the lack of fallback support in Plans would require inventing broken references.

The goal is not random seed noise.

The dataset should tell a plausible training story and be useful later as input for UI design.

Use deterministic mock data where possible.

---

# 19. Validate the model using real queries

After seeding the data, verify that the model can actually answer the required business questions.

Create representative SQL queries, views, or documented query examples — whichever best matches the repository conventions — for at least:

1. one complete exercise-unit trace,
2. one workout-unit trace,
3. one microcycle trace,
4. workout-session calendar/history,
5. all performed loads as chart-friendly time-series data,
6. plan-run event history.

The exercise-unit trace query is the most important acceptance test.

From one query/read-model it must be possible to reconstruct something conceptually equivalent to the existing Post-Workout-Analysis spreadsheet:

```text
microcycle
calendar date
prescribed sets
performed sets
load per set
reps
RIR
comments
```

across successive exposures of the same logical exercise-unit.

If this query is awkward, requires heuristics, or cannot survive a plan revision, reconsider the ERD.

Do not merely accept the model because all foreign keys compile.

---

# 20. Documentation deliverables

Follow the existing documentation structure/style inside `docs`.

Create an appropriate Execution subsection/directory rather than inventing an unrelated documentation system.

At minimum produce documentation covering:

## 1. Execution domain overview

Explain:

- purpose of `exec`,
- relationship between `plans` and `exec`,
- plan vs plan-run,
- prescription vs performance,
- session lifecycle,
- Post-Workout-Analysis.

## 2. ERD

Create Mermaid ERDs.

Prefer at least two levels:

### Conceptual ERD

Shows the major entities and relationships without every implementation detail.

Example conceptual hierarchy:

```text
plan_run
   |
   +-- microcycle
          |
          +-- workout_session
                  |
                  +-- workout prescription
                  |       |
                  |       +-- exercise/set prescription
                  |
                  +-- workout performance
                          |
                          +-- exercise/set performance
```

plus:

```text
plan revisions
repeatable-unit identity
plan-run events
```

### Physical ERD

Show:

- actual table names,
- important PKs,
- FKs,
- cardinalities,
- important state columns.

If useful, add a third, detailed diagram focused specifically on:

```text
workout session
→ exercise-unit
→ set prescription
→ set performance
```

Keep Mermaid diagrams readable. Split them if one enormous diagram becomes useless.

## 3. Table catalogue

For every new table document:

- purpose,
- important columns,
- PK,
- FKs,
- cardinality,
- lifecycle,
- whether records are mutable or historical,
- main consumers/use-cases.

## 4. Domain invariants

Dedicated document as described earlier.

## 5. Repeatable Unit Identity

Dedicated section/document.

## 6. Mock dataset description

Describe:

- selected plan,
- plan revision,
- plan-run dates,
- number of microcycles,
- simulated events,
- why the data is useful.

## 7. Example/read queries

Document the representative queries used to verify the schema.

---

# 21. Implementation constraints

### DO

- inspect the repository before designing,
- follow existing DB conventions,
- reuse existing enums/types/patterns where sensible,
- use proper FKs,
- use constraints where appropriate,
- preserve historical correctness,
- make execution data analytically queryable,
- make the schema migration reproducible,
- seed deterministic realistic data,
- document design decisions,
- explain compromises.

### DO NOT

- implement FastAPI endpoints,
- implement backend services,
- implement Vue components,
- implement Flutter code,
- design UI,
- create a second parallel Plans model inside `exec`,
- duplicate `core` exercise master data unnecessarily,
- hide central execution facts in giant JSON documents,
- implement a complete MARKER.X system,
- implement automated progression,
- implement the fallback Plan Creator feature,
- create an enterprise event-sourcing framework,
- silently redesign existing schemas without documenting why.

---

# 22. Design freedom

The entity/table names described in this prompt are **domain guidance**, not an instruction to mechanically produce one table per noun.

You are expected to use database-design judgment.

For example, you may conclude that:

- session → prescription should be represented via child FK instead of pointer columns on both sides,
- explicit `exec.microcycles` are useful,
- an additional lineage table is required,
- set prescription and set performance require separate structures,
- an existing Plans identity already solves repeatable-unit tracking.

That is acceptable.

What matters is satisfying the domain semantics and required queries cleanly.

If you deviate from a suggested shape in this prompt, document:

```text
Suggested model
Chosen model
Reason
Consequences
```

---

# 23. Expected final output

When the work is complete, provide a concise implementation report containing:

1. what you discovered about the existing `plans`, `core`, and `engine` schemas,
2. which existing plan was selected for the mock plan run,
3. list of every new database table,
4. list of any modified existing tables,
5. list of enums/types introduced,
6. explanation of repeatable-unit identity,
7. explanation of plan-revision history during a run,
8. description of prescription/performance persistence,
9. list of important constraints/invariants,
10. location of migrations/schema files,
11. location of mock-data/seed files,
12. location of Execution documentation,
13. results of the representative trace queries,
14. any remaining architectural questions that should be decided before the backend/API implementation.

Also include the final conceptual table hierarchy directly in the report.

---

# 24. Definition of done

This task is complete only when all of the following are true:

- repository and existing docs were inspected,
- existing Plans structures were reused correctly,
- `exec` schema exists,
- plan-run lifecycle can be represented,
- real calendar workout sessions can be represented,
- concrete microcycles can be represented or an explicitly justified alternative exists,
- prescriptions can be stored,
- actual performances can be stored,
- loads are supported per set,
- prescribed vs performed data is distinguishable,
- historical data survives plan revision changes,
- repeatable-unit identity is explicitly solved,
- plan-run events are represented,
- realistic September 2026 mock data exists,
- one existing plan is used as its source,
- exercise-unit trace can be queried across multiple microcycles,
- workout-unit and microcycle traces are practical,
- calendar/attendance queries are practical,
- all-loads time-series extraction is practical,
- ERDs exist in Mermaid,
- tables are documented,
- domain invariants are documented,
- no backend/frontend/mobile implementation was added.

The most important acceptance test is:

> Given one logical exercise-unit in the plan run, can we retrieve every successive exposure, with its real date, prescription, performed sets, load/reps/RIR and comments, even if the underlying plan revision changes during the run?

If the answer is not cleanly **yes**, the execution model is not finished.