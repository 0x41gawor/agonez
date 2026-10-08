# Agonez Execution — Vue.js Frontend Integration

We are now implementing the final frontend part of the new **Execution** module.

The database/domain model and FastAPI backend have already been implemented.

The UI/product design has also already been completed separately.

Your task is to integrate that design into the **existing Agonez Vue.js frontend repository** as a native new module/tab.

This is **not** a greenfield frontend task.

You must first understand the existing frontend architecture, design system, routing, i18n, API layer, component conventions and application shell, and then integrate Execution cleanly into that system.

---

# 1. Inputs

I am attaching the following artifacts.

## UI design reference

`execution-design-reference.html`

This is the visual and interaction reference produced by the design agent.

Treat it as the primary source of truth for:

* layout,
* information architecture,
* visual hierarchy,
* density,
* screen composition,
* interaction intent,
* important states.

It is **not production source code**.

Do not blindly convert its HTML/CSS into Vue.

---

## Design implementation handoff

`implementation-handoff.md`

This explains:

* component intent,
* layout rules,
* typography hierarchy,
* interaction details,
* responsive behaviour,
* charts,
* locale/i18n expectations,
* P0/P1/P2 implementation priorities.

Read it fully before coding.

---

## API contract

`api-contract.md`

This describes the UI-oriented Execution API expected by the design.

---

## Actual backend OpenAPI

`__docs__/api/openapi.yaml` (in the repo)

This is the machine-readable description of the currently implemented FastAPI backend.

Use this to verify:

* exact routes,
* request bodies,
* response shapes,
* enums,
* nullability,
* query parameters.

---

## Backend implementation notes

`__docs__/execution/api-backend.md` (in the repo)

This documents implementation decisions and any deviations from the original API contract.

Where there is disagreement between:

```text
api-contract.md
and
actual implemented backend
```

the **implemented backend + OpenAPI are authoritative for integration**.

Do not invent frontend workarounds around an API that already exposes the needed data correctly.

---

# 2. First task: understand the existing Vue.js application

Before modifying anything, inspect the frontend repository thoroughly.

At minimum identify:

1. application entry point,
2. router structure,
3. main application shell,
4. existing top-level tabs/modules,
5. navigation configuration,
6. layout components,
7. global CSS,
8. theme/design tokens,
9. typography setup,
10. font loading,
11. icon library,
12. chart library if one exists,
13. API client / HTTP abstraction,
14. error-handling conventions,
15. loading-state conventions,
16. state-management approach,
17. composables,
18. locale/i18n system,
19. existing locale files,
20. reusable table/card/badge/input/button components,
21. responsive/breakpoint conventions,
22. frontend testing setup.

Also inspect representative existing views from:

* Atlas,
* Plans,
* Home,

so that Execution integrates into the actual product language.

Do not create a parallel mini-framework inside Execution.

---

# 3. Integration goal

Add **Execution** as another first-class Agonez module/tab alongside the existing application modules.

Conceptually:

```text
Home
Atlas
Plans
Execution
...
```

Use the existing navigation architecture.

Do not hardcode a second navigation system just for Execution.

The exact placement and route naming should follow repository conventions.

Execution should feel like it has always belonged to Agonez.

---

# 4. Visual fidelity versus repository conventions

Use this rule:

```text
existing Agonez implementation infrastructure
+
Claude design intent
=
production Execution UI
```

The design HTML defines **what the UI should look and behave like**.

The existing Vue repository defines **how that UI should be implemented**.

For example:

* use existing Agonez fonts rather than copying prototype font declarations,
* use existing spacing/design tokens where equivalent,
* use existing buttons rather than rebuilding visually identical buttons,
* use existing badges/status components where suitable,
* use existing icons,
* use existing form controls,
* use existing charting infrastructure,
* use existing route/layout primitives,
* use existing locale infrastructure.

Do not sacrifice the core design merely to reuse an inappropriate component.

But do not duplicate infrastructure without need.

---

# 5. Implementation priorities

Follow the priority levels from `implementation-handoff.md`.

In particular, treat the following as **P0 product behaviour**:

* Execution information architecture,
* Post-Workout-Analysis workflow,
* exercise trace chronology,
* prescribed versus performed comparison,
* next-prescription editor,
* efficient movement between exercise traces,
* calendar session-state distinction,
* dense historical-data presentation,
* analytical chart interactions.

Minor differences in:

* exact shadows,
* token names,
* icon glyphs,
* radius values,

are much less important than preserving these workflows.

---

# 6. Routes and screen architecture

Implement the screen structure defined by the final design.

Use nested routes where that fits the existing router architecture.

The final design/API concept includes screens around:

* Overview,
* Analysis / Post-Workout-Analysis,
* Workout trace,
* Timeline / calendar,
* Loads,
* New plan run.

Do not assume these exact labels must become raw route names if the repository has different route naming conventions.

Keep route structure predictable and bookmarkable where appropriate.

A user should be able to refresh an Execution subpage and remain on the same logical screen.

Where selected entities matter, such as:

```text
plan_run
workout_trace
exercise_trace
```

prefer explicit route/query state over hidden ephemeral global state when reasonable.

---

# 7. Plan-run context

Most Execution screens operate inside one selected:

```text
plan_run
```

Implement a coherent run-context model.

The user should be able to:

* see the current run,
* switch runs,
* retain the selected run while navigating between Execution screens.

Do not make every child screen independently rediscover unrelated context.

Follow the design and API contract.

---

# 8. API integration

Integrate with the real FastAPI backend.

Do not use mock data in the final production path.

Mock/fallback data may be used only for isolated development/testing if the repository already uses such patterns.

Inspect the existing frontend API architecture first.

If the app already has:

* shared API client,
* request wrappers,
* typed DTO layer,
* generated OpenAPI client,
* composables/services,

reuse those conventions.

Do not introduce a second HTTP client architecture.

---

# 9. OpenAPI and typing

Use `api/openapi.yaml` to align frontend types with the real backend.

Prefer generated or explicit TypeScript types depending on existing repository conventions.

Avoid duplicated manually-maintained DTO definitions if the project already derives them from OpenAPI.

If generation is not currently used, create a coherent typed API layer following current patterns.

Important enum values must remain exact.

Do not stringly-type Execution state throughout the UI when a proper TypeScript union/enum can be used.

---

# 10. API contract reconciliation

Compare:

```text
api-contract.md
api/openapi.yaml
api-backend.md
```

before implementing UI calls.

Build a small internal map:

```text
screen/component
→ endpoint
→ DTO
```

Do not assume the original contract is perfectly identical to the final backend.

Where `api-backend.md` documents a deviation, implement against the backend.

If you find an **unexpected undocumented mismatch**, do not silently guess.

Resolve it in the smallest coherent way and document it in your final report.

Avoid changing backend code unless integration is genuinely impossible.

This task is primarily frontend implementation.

---

# 11. Execution overview

Implement the designed plan-run overview using the aggregated backend endpoint.

The overview should provide the intended high-level understanding of:

* active plan run,
* current position,
* current microcycle,
* upcoming/current workouts,
* analysis readiness,
* recent exposure,
* attendance,
* recent events.

Avoid turning the screen into generic KPI-card spam.

Follow the provided design closely.

---

# 12. Analysis / Post-Workout-Analysis

This is the most important screen.

Implement it with particular care.

The workflow should support:

```text
select workout
→
select exercise trace
→
inspect historical exposures
→
compare prescription vs performance
→
review comments/divergence
→
prepare next prescription
→
save
→
move to next exercise
```

The experience should be efficient for reviewing an entire workout or microcycle sequentially.

Do not require repeated navigation back to a general menu.

---

# 13. Analysis queue

Use the backend Analysis queue endpoint.

Implement the designed left rail / selector showing:

* workout traces,
* exercise traces,
* readiness,
* saved/unsaved state,
* blocked states,
* prescription completeness.

Client-only dirty/unsaved state should remain client-side where the API contract specifies that.

Do not persist UI-only state unnecessarily.

---

# 14. Exercise trace

The exercise trace must display historical exposures using the backend's aggregated trace payload.

Important data includes:

* microcycle,
* date,
* plan revision changes,
* prescription,
* performance,
* sets,
* loads,
* reps,
* RIR,
* exercise substitutions,
* skipped/additional sets,
* comments,
* divergences.

Preserve chronology and information density.

The interface should make it possible to understand several exposures at a glance.

Do not turn every set/exposure into a giant card requiring excessive vertical scrolling.

---

# 15. Prescription versus performance

Prescribed and performed values must remain visually distinct.

The user should be able to quickly detect:

* performed below prescribed load,
* performed above prescribed load,
* reps below/inside/top of range,
* RIR deeper/on-target/shallower,
* skipped sets,
* additional sets,
* substitutions.

Use the backend-derived divergence fields.

Do not duplicate domain comparison logic in Vue where the server already computes the semantics.

The frontend owns presentation.

The backend owns business interpretation.

---

# 16. Next-prescription editor

Implement the next-prescription editor according to the design.

The editor should consume:

* next state,
* target session,
* basis performance,
* target plan sets,
* defaults,
* existing saved prescription,
* future suggestion placeholder.

Support the relevant edit flow for:

* per-set load,
* per-set comment,
* exercise-level prescription comment.

Do not make plan-owned fields editable if the API does not allow them.

For example:

* rep ranges,
* target RIR,
* set count,

belong to the plan revision and should remain read-only in this workflow.

---

# 17. Editor defaults

Where the API exposes defaults such as:

```text
from_previous_prescription
from_previous_performance
from_seed_run
```

use them according to the final design.

Do not automatically persist default values merely because they are shown.

Respect the intended distinction between:

```text
suggested/default UI value
and
saved prescription
```

---

# 18. Save and concurrency behaviour

Implement the prescription write flow robustly.

Handle API errors such as:

* prescription blocked,
* session locked,
* stale basis,
* not next session,
* version conflict,
* invalid load,
* set count mismatch.

Do not show generic "Something went wrong" when the API provides actionable domain semantics.

For example:

### stale basis

The UI should:

* notify the user that a newer performance exists,
* refresh the trace,
* preserve locally typed values where practical.

### version conflict

Follow existing application conflict-handling conventions.

### blocked

Explain why the prescription cannot yet be created.

---

# 19. Save & next workflow

If present in the final design, implement efficient:

```text
Save
Save & next
Previous / next trace
```

navigation.

After saving, the next exercise should load without unnecessary full-page navigation.

Prefetch the next trace if this fits the existing frontend/data-fetching architecture and is supported by the design.

Do not overcomplicate prefetching if the project does not already use that approach.

---

# 20. Workout trace

Implement the matrix-oriented workout trace from the aggregated endpoint.

Conceptually:

```text
rows = microcycles/exposures
columns = exercise traces
```

Use the server-provided cell summaries.

Do not perform N API calls per matrix row/column.

Support the designed interaction for inspecting progression across the workout.

---

# 21. Timeline / microcycles

Implement the Timeline according to the design and backend API.

Represent:

* microcycle boundaries,
* classification,
* plan revision changes,
* session states,
* notes,
* events,
* attendance,
* volume.

Preserve distinctions between:

```text
normal
deload
reload
```

and between:

```text
missed
cancelled
```

Do not communicate status only using colour.

---

# 22. Calendar

Implement the designed calendar mode using the flattened session endpoint.

Support the relevant visual statuses:

* scheduled,
* in progress,
* completed,
* cancelled,
* missed.

Completion mode:

```text
as_prescribed
fallback
```

must remain a separate semantic dimension.

Do not collapse fallback into another session state.

---

# 23. Microcycle editing

Where the design exposes:

* notes,
* future deload/reload classification,

integrate with the relevant PATCH endpoint.

Respect API/domain restrictions.

If classification changes are rejected because the microcycle has already started, show an appropriate domain-level message.

---

# 24. Events / journal

Implement event history according to the final design.

Support the intended user actions for allowed user-managed events.

System-managed events must appear historical/read-only.

Do not expose edit/delete controls for system events only to let the backend reject them.

Use backend metadata such as:

* calendar date,
* microcycle ordinal,
* session,
* exercise trace,

to provide useful context.

---

# 25. Load analytics

Implement the Loads screen using the real load-series endpoint.

Support the final design controls for:

* metric,
* workout filter,
* exercise filter,
* series visibility,
* comparison,
* normalization/display scale where applicable,
* hover values.

Important:

```text
substitution
skipped exercise
missed session
cancelled session
```

are **gaps**, not zeroes.

Preserve that visually.

Do not interpolate misleading progression lines through semantically invalid values if the design specifies gaps.

---

# 26. Charts

First inspect whether the existing Vue project already has a charting library.

Reuse it if suitable.

Only introduce a new chart dependency if:

* no appropriate solution exists,
* the final design genuinely requires it.

If a new dependency is necessary:

* choose a focused, maintainable library,
* document why,
* avoid introducing a giant visualization framework for one chart.

Match chart interactions from the design:

* hover,
* selected series,
* muted series,
* filtering,
* exact tooltips.

---

# 27. MARKER.X

MARKER.X is not implemented.

Where the API returns:

```text
progress_marker: null
```

do not manufacture data.

The UI may show the reserved/design placeholder only if that was explicitly part of the final design.

Do not fake progression KPI values in production.

---

# 28. Revision transitions

The UI should represent revision transitions when they matter for interpretation.

Use the server-provided transition metadata.

Do not expose raw DB revision IDs as primary user-facing information.

A subtle marker such as:

```text
Revision 1 → 2
```

with contextual detail is sufficient if that matches the design.

---

# 29. Locales / i18n

Use the application's existing i18n/locales mechanism.

Do not hardcode new user-facing Execution strings inside Vue components.

Add appropriate translation keys following existing conventions.

Reuse terminology from:

`dictionary.md`

and the design handoff.

Cover at least:

* screen names,
* actions,
* status labels,
* completion mode,
* analysis states,
* error/domain messages,
* chart labels,
* prescription/performance terminology,
* empty states,
* tooltips.

Do not create a second localization subsystem.

---

# 30. Fonts and typography

Use the existing application's font setup.

Do not import prototype-only fonts.

Reproduce the hierarchy from `execution-design-reference.html` and `implementation-handoff.md` using the existing typography system.

Where exact prototype CSS conflicts with established Agonez typography tokens, preserve the visual intent using the native tokens.

---

# 31. CSS and styling

Do not paste the standalone HTML stylesheet wholesale.

Translate the design into the project's existing styling architecture.

Reuse:

* variables,
* tokens,
* utility classes,
* CSS modules/scoped styles,
* existing primitives,

according to current conventions.

Avoid creating large amounts of unrelated global CSS.

Execution-specific styling should remain appropriately scoped.

---

# 32. Components

Use the decomposition guidance from `implementation-handoff.md`, but adapt it to the repository.

Prefer reusable components for repeated concepts such as:

* session status,
* microcycle badge,
* prescription/performance sets,
* trace headers,
* event rows,
* execution status indicators.

Do not prematurely abstract one-off layout fragments into generic frameworks.

Find the appropriate granularity.

---

# 33. State management

Follow the existing frontend's state-management philosophy.

Do not introduce Pinia/Vuex/a new store solely for Execution if the app currently uses local/composable state effectively.

Likewise, if the app already relies heavily on a store, integrate with it.

Separate:

```text
server state
UI state
dirty form state
route state
```

cleanly.

Avoid keeping duplicate authoritative copies of API data.

---

# 34. Loading states

Implement appropriate loading states for major screens.

Use existing skeleton/spinner conventions.

The layout should remain stable during loading where possible.

Do not replace a dense analytical workspace with a giant centered spinner if existing product conventions support better skeletons.

---

# 35. Empty states

Implement meaningful empty states where relevant.

Examples may include:

* no plan run,
* no future session,
* no historical exposure yet,
* no saved prescription,
* no events,
* no comparable load data.

Use terminology appropriate to Execution.

Do not confuse:

```text
empty
blocked
loading
error
```

These are different states.

---

# 36. Error handling

Integrate Execution-specific API errors into the existing notification/error system.

Map stable backend error codes to useful UX messages.

Do not expose raw FastAPI errors or stack-like messages.

Important domain errors should produce contextual feedback near the relevant workflow when appropriate.

---

# 37. Accessibility

Preserve the accessibility guidance from the design handoff.

At minimum:

* keyboard focus must remain visible,
* editor inputs should be keyboard-friendly,
* icon-only actions need labels/tooltips,
* statuses must not rely on colour alone,
* interactive table rows need clear semantics,
* disabled controls should explain blocked state where needed.

---

# 38. Responsive behaviour

This module is desktop-first.

Follow the design handoff for:

* large desktop,
* standard laptop,
* minimum practical desktop width.

For data-heavy trace/matrix screens, horizontal scrolling is acceptable where the alternative would destroy readability.

Do not aggressively transform analytical tables into stacked mobile cards.

The future mobile workout app is a separate product.

---

# 39. New plan run

If included in the final design, implement the New Plan Run flow using:

```text
preview
→
create
```

Use the backend preview endpoint for live calculations such as:

* end date,
* session count,
* workout count,
* overlap warning.

Do not duplicate run projection calculations in the frontend.

---

# 40. Do not redesign other modules

Do not use this task as an opportunity to refactor or redesign:

* Atlas,
* Plans,
* Home,

unless a tiny shared change is necessary to integrate Execution.

Keep unrelated diffs minimal.

---

# 41. No backend reimplementation

The backend is already implemented.

Do not recreate domain rules in the frontend.

Especially do not duplicate logic for:

* next-prescription readiness,
* session lifecycle validity,
* divergence classification,
* attendance ratios,
* revision comparison,
* microcycle projection.

The backend returns these semantics.

Vue should present them.

---

# 42. Testing

Use the repository's existing frontend test stack.

Add useful tests around the most important behaviour.

At minimum cover where practical:

## Navigation

* Execution tab exists,
* route loads correctly,
* selected run persists appropriately during navigation.

## Analysis

* queue renders,
* exercise selection changes trace,
* prescribed/performed values render distinctly,
* blocked state renders,
* editor is disabled/locked appropriately.

## Prescription editor

* loads existing prescription,
* edits loads/comments,
* save request is correct,
* save success refreshes UI,
* Save & next advances correctly if implemented.

## Errors

* stale basis,
* version conflict,
* blocked prescription,
* session locked.

## Timeline/calendar

* session statuses render correctly,
* missed versus cancelled is distinguishable,
* deload/reload classification appears correctly.

## Load analytics

* gaps remain gaps,
* series filtering works.

Do not chase meaningless 100% coverage.

Prioritize critical workflows.

---

# 43. Validate against the real backend

If the project can be run locally with the Execution demo dataset, test the frontend against the real backend.

Use the seeded demo run.

The most important integration flow is:

```text
open Execution
↓
select demo plan run
↓
open Analysis
↓
select Push A
↓
open Bench Press
↓
inspect multiple historical exposures
↓
see prescription vs performance
↓
edit the next prescription
↓
save it
↓
move to the next exercise
↓
return and confirm saved state
```

Also verify:

```text
Overview
Workout trace
Timeline
Calendar
Events
Loads
```

against real API responses.

Do not consider the task complete based only on mocked component rendering.

---

# 44. Browser verification

Run the application and inspect the resulting UI.

Compare it side-by-side with:

`execution-design-reference.html`

Check especially:

* spacing,
* density,
* column widths,
* sticky behaviour,
* hierarchy,
* trace readability,
* prescription editor,
* chart sizing,
* status visibility,
* navigation.

Fix obvious visual regressions before finishing.

The standalone HTML is not production code, but it is the visual benchmark.

---

# 45. Code quality

Keep the implementation maintainable.

Avoid:

* one enormous Execution component,
* 1000-line templates,
* deeply duplicated DTO mapping,
* hardcoded styling scattered throughout templates,
* business logic embedded in rendering expressions,
* direct raw `fetch()` calls in random components if the project has an API layer.

Prefer clear component/composable/service boundaries consistent with the repository.

---

# 46. Documentation

Add a concise frontend Execution implementation document if the repository has a suitable docs structure.

Document:

* route architecture,
* primary components,
* API integration layer,
* important state ownership,
* chart implementation,
* locale key namespace,
* any deliberate deviations from the design handoff.

Do not duplicate the entire design handoff.

---

# 47. Final implementation audit

Before finishing, verify all designed screens/components against:

```text
execution-design-reference.html
implementation-handoff.md
api/openapi.yaml
api-backend.md
api-contract.md
```

Create a short checklist:

```text
implemented
implemented with justified adaptation
not implemented
```

There should be no accidental omissions.

For any omitted feature, explain why.

---

# 48. Final report

When implementation is complete, report:

1. frontend architecture discovered,
2. files added,
3. files modified,
4. new routes,
5. new top-level navigation entry,
6. major Vue components,
7. composables/services added,
8. API integration approach,
9. locale keys/files added,
10. chart solution used,
11. tests added,
12. test results,
13. build/lint/typecheck results,
14. real-backend integration result,
15. any deviations from Claude's design,
16. any deviations caused by backend/OpenAPI reality,
17. remaining issues, if any.

---

# Definition of done

The Execution frontend is complete when:

* Execution appears as a native Agonez module,
* it uses the existing application shell and navigation,
* existing fonts/styles/i18n/components are reused appropriately,
* the Claude design is reproduced faithfully,
* the standalone HTML was used as a visual reference rather than copied mechanically,
* real FastAPI endpoints are used,
* API DTOs are typed coherently,
* Overview works,
* Analysis queue works,
* exercise trace works across multiple plan revisions,
* prescription versus performance is clear,
* next prescription can be created/edited/saved,
* blocked/locked states are handled,
* Workout Trace works,
* Timeline works,
* Calendar works,
* Events work,
* Load Analytics works,
* session states remain semantically distinct,
* MARKER.X is not fabricated,
* localization uses the existing app infrastructure,
* important errors are handled meaningfully,
* frontend tests pass,
* build/typecheck/lint pass,
* existing unrelated application functionality remains intact,
* the UI has been visually checked against the design reference.

The primary acceptance test is:

> Can a user enter the new Execution tab, open the active demo run, go to Post-Workout-Analysis, inspect Bench Press history across plan revisions, clearly compare prescription against actual performance, create the next prescription, save it through the real API, advance to the next exercise trace, and later return to see the saved state — while the whole module visually and structurally feels like a native part of the existing Agonez Vue.js application?

If the answer is not cleanly **yes**, the frontend integration is not finished.
