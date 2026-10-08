# Execution frontend

The Execution module is a native Vue 3 feature under `/execution`. It uses the existing
application shell, Pinia instance, vue-i18n runtime, API client, Geist fonts, theme tokens,
buttons, panels, loading skeletons, and error treatment.

## Routes

```text
/execution
/execution/runs/new
/execution/runs/:runId
/execution/runs/:runId/analysis?trace=:exerciseTraceId
/execution/runs/:runId/analysis/workouts/:workoutTraceId
/execution/runs/:runId/timeline?axis=microcycles|weeks&session=:sessionId
/execution/runs/:runId/loads?metric=...&scale=kg&traces=...
```

The landing route selects the active run, then the next scheduled run, then the most
recent returned run. Trace, workout, calendar axis, selected session, load metric, scale,
and visible load series are bookmarkable.

## Architecture

- `src/api/execution-types.ts` mirrors the screen-shaped FastAPI DTOs.
- `src/api/execution.ts` is the only Execution HTTP boundary.
- `src/views/execution/ExecutionLayout.vue` owns the shared run list, overview payload,
  run header, and four tabs. It provides that state to child views.
- `src/stores/executionDrafts.ts` owns only unsaved prescription form state, keyed by
  exercise trace. Server data remains in each route view.
- `src/components/execution/` contains status marks, the queue, dense trace table,
  prescription editor, load strip, and SVG load chart.
- `src/styles/execution.css` is scoped by Execution-specific class names and maps visual
  intent onto the existing application tokens.
- `src/i18n/locales/en/execution.ts` owns the English namespace. Other locale packs use
  the application's existing English fallback merge until translated copy is supplied.

The Analysis route keeps queue/readiness state, the selected aggregated exercise trace,
and the active draft separate. Save sends the backend basis ID, plan-aligned set ordinals,
comments, and optimistic version. Stable backend errors are mapped to editor messages;
stale/version-conflict reloads preserve the draft. Blocking conflicts refresh the trace
and switch the editor to the server-owned locked state.

## Charts

No chart library existed in the application. The load strip and all-loads chart are small,
accessible SVG components. Each server `null` value closes the current SVG path, so
substitutions and skipped exposures remain real gaps. Points are keyboard-focusable and
expose exact values through SVG titles. MARKER.X remains visibly reserved and empty.

## Design and backend adaptations

- The prototype's standalone stylesheet, top navigation, fonts, and state switcher were
  not copied. Existing Agonez infrastructure is used.
- `current_plan.load_step_kg` is `null` in the implemented API. Step controls remain
  visible but disabled with an explanation; direct and bulk load entry work normally.
- Seed-run defaults are absent because the optional backend field was deliberately omitted.
- The overview's current-session DTO does not expose completion mode, so it does not infer
  “as prescribed.” The calendar and workout trace show completion mode where supplied.
- “Primary lifts” on Loads selects the first API-ordered trace per workout because v1 load
  series do not expose slot role. No progression values are fabricated.
- Revision comparison authoring links are intentionally informational because applying a
  revision transition is outside this release.
- User-created events can be expanded, edited, and deleted, while system events stay
  read-only. Event creation and session reclassification are live.

## Implementation audit

Implemented:

- native top-level navigation, run switcher, shared tabs, and no-run state;
- Overview, Analysis queue, exercise history, prescription/performance grammar, editor,
  Save, Save & next, J/K and save shortcuts, workout trace matrix;
- Timeline microcycle and calendar axes, session selection/actions, notes,
  deload/reload planning, journal composition/filtering/deletion;
- Loads metric/scale/series controls, unit filters, hover isolation, exact tooltips, gaps;
- preview-to-create New Plan Run flow;
- loading, empty, blocked, error, responsive, keyboard, and non-colour status treatments.

Implemented with justified adaptation:

- charts use focused SVG components instead of a dependency;
- load-step controls reflect the backend's null step value;
- the primary-load preset uses stable API ordering due to missing slot-role metadata;
- all untranslated locales use the repository's established English fallback mechanism.

Not implemented because the backend/design explicitly reserve them:

- MARKER.X values, automated progression suggestions, seed-run defaults;
- applying plan revision transitions, mobile start/finalize, or fallback authoring.
