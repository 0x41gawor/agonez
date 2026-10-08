# Agonez Execution — Desktop Product Design

You are designing the next major desktop module of **Agonez**, called **Execution**.

Your task is to design the user-facing desktop/web experience for following a workout plan over time, analysing training performance, and creating prescriptions for future workout exposures.

This is primarily a **product / UX / information-design task**.

The persistence/domain layer has already been designed and implemented.

Do **not** redesign the database.

Do **not** implement the production backend.

Your outputs from this task should be:

1. a high-fidelity interactive desktop UI design/prototype for the Execution module,
2. a clear information architecture and interaction model,
3. an `api-contract.md` describing the backend API the designed UI will require.

The resulting design artifact will later be given to a coding agent that will implement it inside the existing Agonez Vue.js application.

The `api-contract.md` will independently be given to another coding agent implementing the FastAPI backend.

---

# 1. First understand Agonez

Before designing anything, inspect all supplied materials.

Especially read:

* `dictionary.md`,
* Execution domain documentation,
* Execution ERDs,
* table catalogue,
* repeatable-unit identity documentation,
* domain invariants,
* mock dataset description,
* Execution read-model SQL,
* screenshots of the existing Agonez application,
* screenshot of the historical Post-Workout-Analysis spreadsheet.

Use `dictionary.md` as the source of truth for terminology.

Use the current Agonez screenshots as the primary reference for:

* visual language,
* typography,
* spacing,
* component style,
* density,
* navigation,
* colours,
* borders,
* tables,
* cards,
* charts,
* general application personality.

The spreadsheet screenshot is different:

> Treat the old Post-Workout-Analysis spreadsheet as a **functional reference**, not a visual reference.

We want to preserve what made that workflow useful while designing a proper application around it.

---

# 2. Product context

Agonez has three conceptual domains:

```text
Atlas
    knowledge about exercises / muscles / biomechanics

Plans
    definition of a workout program

Execution
    a concrete athlete actually following that program over time
```

The fundamental distinction is:

```text
plans = what the training program is

exec = what happens when a concrete athlete follows that plan
       over concrete calendar time
```

A workout plan is reusable.

A `plan_run` is one concrete attempt to execute it.

For example:

```text
Plan:
5x week Push/Pull/Legs upper-focus

Plan Run:
Autumn 2026 reduction
2026-09-01 → 2026-10-26
8 microcycles
```

The supplied mock dataset contains such a real eight-microcycle run.

Use it extensively.

---

# 3. Core mental model: prescription versus performance

This distinction is fundamental to the entire UX.

For every exposure we can have:

```text
Prescription
what the athlete SHOULD do

Performance
what the athlete ACTUALLY did
```

Example:

```text
Prescription:
Bench Press
Set 1: 72.5 kg × 7 @ RIR 1
Set 2: 72.5 kg × 7 @ RIR 1
Set 3: 70 kg × 7 @ RIR 1

Performance:
Set 1: 72.5 kg × 7 @ RIR 1
Set 2: 72.5 kg × 6 @ RIR 0
Set 3: 70 kg × 5 @ RIR 0
```

There may additionally be:

* prescription comments,
* performance comments,
* different exercise variants,
* skipped sets,
* additional sets,
* load divergence,
* RIR divergence.

The UI must make **prescribed versus performed** extremely easy to compare.

Do not visually blur the two concepts.

---

# 4. The most important workflow: Post-Workout-Analysis

The heart of the module is **Post-Workout-Analysis**.

Conceptually:

```text
previous prescription
        ↓
actual performance
        ↓
trainer/athlete analysis
        ↓
next prescription
```

The user studies what happened in previous exposures and decides what the athlete should perform next time.

Later Agonez may automate this decision using progression models.

For now a human creates the prescription.

This means the main Execution UX is **not merely a training-history dashboard**.

It is a decision-support workspace.

The screen must help answer:

> What happened previously?

> Is this exercise progressing?

> What was prescribed?

> What was actually achieved?

> Were there technique / equipment / recovery issues?

> What should I prescribe next?

---

# 5. Exercise-unit trace — the highest-priority view

The most important feature in the entire first Execution release is the **exercise-unit trace**.

The supplied Google Sheet screenshot shows the historical workflow.

An exercise, for example:

```text
Bench Press
```

was displayed across successive weeks with:

* load,
* individual sets,
* reps,
* RIR-like annotations,
* free-form notes.

That worked surprisingly well because the user could immediately see progression vertically through time.

The application must preserve this strength.

However the target system is richer.

For every exposure we can know:

* microcycle ordinal,
* actual calendar date,
* workout-unit,
* prescription,
* actual performance,
* prescribed load per set,
* performed load per set,
* reps,
* RIR,
* exercise variant,
* comments,
* divergence from prescription.

The new UI must support **load per set**.

Do not assume one load value per exercise.

---

# 6. Exercise trace must also support prescribing the next exposure

This is critical.

The exercise trace is not read-only.

From the same analytical context, the user should be able to prepare the next prescription.

A strong design would allow the user to inspect something conceptually like:

```text
MC4
Prescription → Performance

MC5
Prescription → Performance

MC6
Prescription → Performance

MC7
Prescription → Performance

MC8
NEXT PRESCRIPTION
[ editable ]
```

The actual interaction design is yours to solve.

Possible approaches include:

* chronological rows,
* columns,
* expandable exposures,
* history + focused detail panel,
* pinned next-prescription editor,
* contextual drawer,
* spreadsheet-like workspace,
* another solution.

Do not mechanically copy the spreadsheet.

Find the best product interaction.

The core criterion is:

> The user should have enough historical evidence visible while making the next prescription that the decision feels informed rather than blind.

---

# 7. Think carefully about information density

Agonez is an engineering-oriented training product.

Execution is data-heavy by nature.

Do **not** simplify the interface into giant consumer-fitness cards with almost no information.

At the same time, do not simply turn the application into a database admin panel.

Find a good balance.

The user should be able to scan many weeks of:

```text
load
sets
reps
RIR
prescription/performance differences
```

without requiring dozens of clicks.

Use progressive disclosure for secondary information such as long comments or detailed set metadata.

Desktop screen width should be used intelligently.

---

# 8. Workout-unit trace

Design a higher-level trace for a repeated workout-unit such as:

```text
Monday Push
```

The goal is to understand how this workout-unit evolves over successive microcycles.

Useful information can include:

* exposure dates,
* completion status,
* major exercise progression,
* comments,
* future progression metric,
* important exercise-slots,
* prescription/performance trends.

This view is primarily analytical.

Creating the next exercise prescriptions should remain centred around the exercise-level Post-Workout-Analysis workflow unless you discover a significantly better interaction.

---

# 9. Microcycle trace

Design the next abstraction level:

```text
Microcycle 1
Microcycle 2
Microcycle 3
...
```

The purpose is to understand the athlete's evolution over weeks/microcycles.

The supplied domain model contains information such as:

* ordinal,
* start/end dates,
* plan revision,
* classification,
* comments,
* attendance,
* sessions.

Microcycles may represent concepts such as:

```text
normal
deload
reload
```

A user may add observations such as:

> Bodyweight finally reached 82 kg. Strength is still good.

or:

> Plateau for two weeks. Check recovery.

The UX should make such macro observations useful rather than burying them.

---

# 10. Workout calendar

Design a calendar-oriented view of the plan run.

The user needs to understand how planned training maps onto real life.

Sessions have states such as:

```text
scheduled
in_progress
completed
cancelled
missed
```

A completed session may later also indicate:

```text
as_prescribed
fallback
```

The calendar should make patterns obvious:

* adherence,
* missed training,
* intentionally cancelled sessions,
* fallback usage,
* spacing between workouts,
* where the athlete currently is in the plan run.

Do not treat `missed` and `cancelled` as the same visual concept.

They mean different things.

---

# 11. Plan-run overview

Design an appropriate overview for one active `plan_run`.

Useful high-level information may include:

* plan-run name,
* source workout plan,
* current microcycle,
* start/end dates,
* progress through the run,
* session attendance,
* recent activity,
* upcoming workout,
* latest events,
* deload/reload periods,
* selected analytical summaries.

Avoid creating a generic dashboard full of arbitrary KPI cards.

Every prominent metric should answer an actual training question.

---

# 12. Plan-run events / history

Execution contains a lightweight event history.

Examples include:

* plan revision changed,
* exercise modified,
* personal record,
* deload started,
* reload started,
* vacation,
* training break,
* free-form observation.

This should feel somewhat like a chronological training journal/history.

Each event can have both:

```text
calendar position
2026-09-23

plan position
Microcycle 4
```

Determine where this event stream belongs in the overall information architecture.

It does not necessarily require a completely independent page.

---

# 13. All-loads analysis

Design an analytical chart where the user can compare load progression across many exercise traces.

The underlying data can expose values conceptually like:

```text
exercise
workout-unit
calendar date
microcycle
set
load
```

The use-case is to answer questions such as:

> Are exercises across the entire program progressing together?

> Is Monday Push increasing while Tuesday Pull is stagnating?

> Did performance broadly drop during a particular period?

The chart may contain many series.

Design appropriate controls for:

* selecting/deselecting exercises,
* filtering workout-units,
* hovering exact values,
* reducing visual noise,
* comparing selected traces,
* changing useful aggregation where appropriate.

Do not produce a permanently unreadable spaghetti chart.

---

# 14. Trace charts and MARKER.X

The domain includes a future progression KPI currently referred to as:

```text
MARKER.X
```

Its exact formula and final product name are **not yet defined**.

Do not invent the final formula.

Do not make product decisions that require a specific mathematical definition.

However, the product will eventually have one comparable progress indicator for:

* workout-unit trace,
* microcycle trace.

You may reserve/design an appropriate place for this type of metric or demonstrate it using clearly identified mock/demo values.

Treat it as a future analytical capability, not a finalized domain object.

The design must remain useful even without MARKER.X.

---

# 15. Plan revisions must be understandable when relevant

The underlying workout plan can change during a plan run.

The supplied mock dataset includes such a revision transition.

Historical execution remains tied to the correct historical revision.

Most users should not have to think about database revisions constantly.

However, when a change materially affects interpretation of the trace, the UI should make it possible to understand:

> something changed here.

For example an exercise may have changed or program volume may have been modified.

Find an unobtrusive way to represent such transitions.

---

# 16. Repeatable-unit identity

Execution contains stable run-scoped tracks for:

* workout-units,
* exercise-units.

This is what allows one logical Bench Press trace to survive a plan revision.

Read the attached repeatable-unit identity documentation carefully.

Do not expose internal track IDs to users.

The UX should simply behave as though the same logical exercise remains one coherent trace when that is appropriate.

If the track intentionally breaks because the exercise was genuinely replaced, represent that transition understandably.

---

# 17. Existing mock dataset

Use the supplied Execution mock data as the factual basis of the prototype.

The dataset represents:

```text
Plan:
5x week, Push-Pull-Legs, upper focus, volume redukcyjne

Run:
8 microcycles
2026-09-01 → 2026-10-26
```

It intentionally includes:

* completed sessions,
* future sessions,
* one in-progress workout,
* missed session,
* cancelled session,
* revision transition,
* deload,
* reload,
* substitutions,
* skipped/additional sets,
* comments,
* events,
* progression,
* non-linear progression.

Bench Press specifically has multiple exposures spanning two plan revisions while remaining one logical exercise trace.

Use these cases in the actual screens.

Do not fill the entire prototype with meaningless `Lorem ipsum`, generic `Exercise 1`, or perfectly linear progression.

The irregularities are important because they are what the product has to explain.

---

# 18. Information architecture

Determine the best information architecture for the desktop Execution module.

Do **not** assume that every domain concept deserves a separate tab.

For example:

```text
Overview
Calendar
Post-Workout-Analysis
Analytics
History
```

could be one solution.

But it is only an example.

You are expected to find a better structure if one exists.

The architecture should minimize navigation cost between:

```text
I notice a problem
→
I inspect the relevant trace
→
I understand previous performance
→
I prepare the next prescription
```

Post-Workout-Analysis should be especially efficient for the common workflow:

> trainer sits down once after a microcycle and reviews several exercise traces sequentially.

Consider how the user can move efficiently:

```text
Bench Press
→ Incline Press
→ Lateral Raise
→ ...
```

without repeatedly navigating through the entire application.

---

# 19. Prescription editing

Design the interaction for authoring the next prescription.

At minimum the user may need to edit, per set:

* load,
* comments.

At exercise level there may also be a prescription comment.

The user should be able to use the previous exposure as a starting point rather than recreating everything manually.

Explore efficient interactions such as:

* copy previous prescription,
* start from previous performance,
* adjust only changed values,
* keyboard-friendly editing,
* applying one load to several selected sets,
* explicit unsaved/draft state if useful.

However:

Do not invent backend capabilities unsupported by the attached domain model without identifying them explicitly in the API contract as required application behaviour.

The design should eventually be comfortable for a serious user managing many exercises every week.

---

# 20. Current scope boundaries

This design concerns the **desktop/web Execution module**.

Do not design the phone workout application in this task.

The future mobile application will:

```text
receive prescription
guide athlete through workout
record performance
sync performed workout back to server
```

That is a later project.

The desktop module can display `in_progress` state originating from such a client, but do not design the mobile workout flow.

Also do not redesign:

* Atlas,
* Plan Creator,
* authentication,
* full user/account management.

Integrate naturally with the existing product.

---

# 21. API contract deliverable

After the UX is designed, create:

```text
api-contract.md
```

This is an important deliverable.

The document will be handed directly to a FastAPI coding agent.

Do not expose database tables one-to-one as REST resources merely because they exist.

Design the API **from the UI use-cases**.

The database already provides six useful read-model families for:

* exercise trace,
* workout trace,
* microcycle trace,
* calendar,
* load time series,
* events.

Read `exec_read_models.sql`.

Use those capabilities as input, but define endpoints around product workflows.

The contract should cover at least the data needed for:

* plan-run list / selection if needed by the design,
* plan-run overview,
* exercise trace,
* next prescription editor,
* workout-unit trace,
* microcycle trace,
* calendar,
* all-loads analytics,
* event history.

Also define the required write operations.

Most importantly:

```text
create/update the next workout prescription
```

and any additional write operations that the final design genuinely requires, such as execution-level comments/events.

---

# 22. API contract format

For every endpoint specify enough information for independent backend and frontend implementation.

Include:

```text
HTTP method
path
purpose
path/query parameters
request body
response body
important enums
nullable/optional semantics
important domain errors
relevant pagination/filtering
```

Provide realistic example JSON.

Prefer UI-oriented DTOs over leaking the physical database structure.

For example, an exercise trace endpoint should be allowed to return one coherent structure representing:

```text
exercise identity
trace metadata
exposures[]
    microcycle
    date
    prescription
        sets[]
    performance
        sets[]
    comments
next_prescription
```

rather than forcing the Vue frontend to independently call and join six table-oriented endpoints.

Use backend aggregation where it improves product simplicity.

---

# 23. Respect domain invariants

Read `invariants.md`.

The UI and API contract must not permit invalid domain states.

Examples include lifecycle relationships between:

```text
session
prescription
performance
```

and rules around creating future prescriptions.

If a required action is forbidden because its preceding performance does not yet exist, design an appropriate disabled/blocked state rather than ignoring the invariant.

Where an invariant belongs to the server, document the relevant API error semantics.

---

# 24. Visual direction

Match the existing Agonez product rather than inventing an unrelated visual identity.

The desired feeling is:

```text
serious
technical
precise
athletic
science/engineering-oriented
premium but restrained
```

Avoid:

* playful gamified fitness-app aesthetics,
* excessive gradients,
* giant rounded cards everywhere,
* neon cyberpunk styling,
* bodybuilding-bro visual clichés,
* gratuitous trophy/fire/streak mechanics,
* enormous empty whitespace,
* dashboard KPI-card spam.

The design can be dense.

Think more:

> professional analytical training workstation

than:

> consumer calorie counter.

Preserve Agonez's existing visual identity from the supplied screenshots.

---

# 25. Interaction quality

Prioritize:

* rapid visual comparison,
* scanability,
* consistent chronology,
* visible dates,
* low navigation friction,
* useful hover states,
* tooltips where terminology needs explanation,
* keyboard-friendly data entry where reasonable,
* sensible sticky headers/columns for large histories,
* clear selected/focused states,
* good empty/loading/error states,
* distinction between historical immutable information and editable next prescription.

Do not overuse modal dialogs.

Post-Workout-Analysis is a primary workflow and deserves a real workspace.

---

# 26. Prototype requirements

Produce a polished desktop prototype/artifact demonstrating the main workflows with the supplied mock data.

At minimum demonstrate:

### Scenario A — inspect active plan run

User enters Execution and understands:

* which run is active,
* where they currently are,
* recent execution,
* upcoming work.
* user can start a nexr plan run (create it)

### Scenario B — Post-Workout-Analysis

User opens an exercise trace such as Bench Press.

They can understand its history across multiple microcycles and the plan-revision transition.

They compare prescribed versus performed sets.

They read comments.

They create/edit the next prescription.

### Scenario C — inspect a workout-unit

User examines progression of one repeated workout-unit over several microcycles.

### Scenario D — inspect the macro timeline

User understands:

* microcycles,
* deload/reload,
* missed/cancelled workouts,
* plan events.

### Scenario E — analyse load progression

User uses the all-loads analytical view to compare several exercise traces.

The prototype does not need every possible edge case, but the architecture should support them.

---

# 27. Design decisions document

Alongside the artifact, briefly document important decisions.

Especially explain:

* chosen information architecture,
* why Post-Workout-Analysis is structured the way it is,
* how prescription and performance are visually distinguished,
* how long traces remain scannable,
* how plan-revision transitions appear,
* how microcycle/calendar context is represented,
* how the design scales when a plan contains many workout-units and exercises,
* how the same architecture can later incorporate automated progression.

Do not write a generic UX essay.

Document the decisions necessary for implementation.

---

# 28. Important future direction

The first version is human-driven:

```text
human analyses performance
→ human writes next prescription
```

A later version should allow:

```text
progression model
→ automatic proposal
→ human reviews/accepts/overrides
```

Design the prescription workflow so this can later become:

```text
Suggested prescription
72.5 kg × 7 / 7 / 7

Reason:
Double Progression rule satisfied

[Accept] [Modify]
```

without requiring the entire interface to be redesigned.

Do not implement or invent the progression algorithm now.

Simply preserve a natural extension point.

---

# 29. Non-goals

Do not:

* redesign the `exec` database schema,
* expose raw database IDs unnecessarily,
* design the mobile workout app,
* implement production backend code,
* implement final production Vue code,
* define MARKER.X mathematically,
* design automated progression logic,
* redesign Atlas,
* redesign Plan Creator,
* create a generic BI dashboard detached from workout workflows.

---

# 30. Definition of done

The design is successful when a user can clearly answer:

> What was I supposed to do?

> What did I actually do?

> How has this exercise progressed over successive exposures?

> What happened on a specific real-world date?

> Did my workout-unit/program progress across microcycles?

> Where were workouts missed or cancelled?

> Did something important change in the program?

> Based on all of this, what should I prescribe next?

And the most important workflow should feel natural:

```text
inspect historical exposure
→ understand performance
→ reason about progression
→ write next prescription
→ move to next exercise trace
```

The design should make this substantially better than the original spreadsheet while preserving the spreadsheet's key strength:

> a large amount of progression history can be understood at a glance.
