# 05 — Frontend UX Specification (web-fe)

Implementation-ready specification. There is no separate design phase: reuse the existing Execution
and PlanCreator visual language (`exec-*` classes, `panel`, `button`/`button primary`/`button ghost`,
`eyebrow`, `mono`, `exec-modal-backdrop`/`exec-modal panel` from `RunManagerDialog.vue`, the
`conflict-banner`/`plan-inline-error` blocks from `PlanCreatorView.vue`).

---

## 1. Navigation model

```text
/execution/runs/:runId                     ExecutionLayout (run bar + tabs)
   ├─ ''          Overview
   ├─ analysis    Analysis
   ├─ timeline    Timeline
   ├─ loads       Loads
   └─ plan        RUN PLAN  (new tab)  ──► "Edit run plan"
                                              │
/execution/runs/:runId/plan/edit           RunPlanEditorView  (top-level route, no Execution tabs)
                                              └─ PlanCreatorView with runContext
                                                   tabs: Plan | Analysis | Modulation (later)
                                                   "← Run plan" returns to /execution/runs/:runId/plan
```

- One level of nesting only: Execution tabs **or** PlanCreator tabs, never both.
- Breadcrumb in the editor eyebrow: `Run plan · <run name>`; the back arrow (existing `plan-back`)
  targets the Run Plan tab.
- Direct visits to `/plans/:planId` for a run plan redirect (`router.replace`) to
  `/execution/runs/<plan_run_id>/plan/edit` once the draft artifact reports `scope: 'run'`.

**Feature flag.** All run-plan UI ships to `master` hidden behind
`src/features/execution/run-plan-flag.ts` → `export const RUN_PLAN_UI_ENABLED = false` (added by T4.1;
flipped to `true` in one commit once T6.1 and RD-01 pass, `06` step #12). When `false`: the two routes
below are not registered, the Run plan tab is not rendered, and `PlanCreatorView` does not redirect
run plans. No other screen changes behaviour based on the flag.

Router changes (`src/router/index.ts`, only when `RUN_PLAN_UI_ENABLED`):

```ts
{ path: '/execution/runs/:runId(\\d+)/plan/edit', name: 'execution-run-plan-editor',
  component: () => import('@/views/execution/RunPlanEditorView.vue'), props: true },   // declare before the parent route
// child of '/execution/runs/:runId(\\d+)':
{ path: 'plan', name: 'execution-run-plan',
  component: () => import('@/views/execution/ExecutionRunPlanView.vue') },
```

---

## 2. Execution entry point

### 2.1 Tab

`ExecutionLayout.vue`: add a fifth tab **Run plan** after Loads. Show a small accent dot
(`.tab-dot`, `aria-label="Unapplied changes"`) when `overview.run.has_unapplied_changes`. Extend
`activeTab` with `'run-plan'` for route name `execution-run-plan`.

### 2.2 Run bar copy

Replace `execution.run.from` ("From P006 · plan") with:

- `Run plan: {name} · copied from {source}` when `run.source_plan` exists;
- `Run plan: {name} · source plan deleted` otherwise.

`{name}` = `run.plan.name` (the run plan), `{source}` = `run.source_plan.code · run.source_plan.name`.

---

## 3. Run Plan tab — `views/execution/ExecutionRunPlanView.vue` (new)

Data: `executionApi.runPlan(runId)` then `executionApi.runPlanRevision(runId,
state.current_revision.plan_revision_id)`. Uses `executionContextKey` (`reload` after changes) and
`useAtlasCatalogStore` for exercise names.

```text
┌───────────────────────────────────────────────────────────────────────────────────────────┐
│ RUN PLAN                                                                       r3 · applied │
│ PPL upper focus                                                         18 Nov 2026 19:02 │
│ This run has its own copy of the plan. Changing it never affects "P015 · PPL upper focus" │
│ in My Plans, and other runs are not affected.                                              │
│                                                                                            │
│ [ Edit run plan ]   [ Save as new plan… ]                                                  │
├───────────────────────────────────────────────────────────────────────────────────────────┤
│ ● You have saved changes that are not applied to this run yet.   [ Review & apply… ] [Discard] │   (only when has_unapplied_changes)
├───────────────────────────────────────────────────────────────────────────────────────────┤
│ CURRENT DEFINITION · 7 days · 5 workouts · 36 exercises · 112 sets                          │
│ D1 Mon  ▲ Push A        Bench press 3 × 6–8 @RIR2 · Incline DB press 3 × 8–10 @RIR2 · …    │
│ D2 Tue  ▼ Pull A        …                                                                  │
│ D3 Wed  ☾ Rest                                                                             │
│ …                                                                                          │
├───────────────────────────────────────────────────────────────────────────────────────────┤
│ MODIFICATION HISTORY                                                                       │
│ r3  18 Nov 19:02  "Pec deck removed from the gym"  21 sessions updated · 1 prescription    │
│                   discarded                                                     [ View ]   │
│ r2  02 Nov 08:15  —  21 sessions updated                                        [ View ]   │
│ r1  26 Oct        Copied from P015 · PPL upper focus when the run was created   [ View ]   │
└───────────────────────────────────────────────────────────────────────────────────────────┘
```

Components (new, under `src/components/execution/run-plan/`):

| Component | Responsibility | Reuses |
| --- | --- | --- |
| `RunPlanDefinition.vue` | Read-only day list of a `PlanRevisionArtifact`: day label (`D{n}`, weekday), `DayIconMark`, workout name, exercise chips with role colour and compact set summary (`3 × 6–8 @RIR2`, ramp-up sets prefixed `+1 ramp`). Rest days collapsed. | `DayIconMark.vue`, `roleLabel` + role palette from `features/plans/editor.ts`, catalog names. |
| `RunPlanHistory.vue` | History list from `state.history`; "View" opens `RunPlanRevisionDrawer`. | `executionDate` formatter. |
| `RunPlanRevisionDrawer.vue` | Side drawer (`exec-modal` styling) rendering `RunPlanDefinition` for a historical revision (`runPlanRevision`). | — |
| `RunPlanApplyDialog.vue` | Dry run + confirmation + apply (§5). | `exec-modal` markup/ESC handling from `RunManagerDialog.vue`. |
| `RunPlanPromoteDialog.vue` | Library promotion (§7). | same. |

States: skeleton (`ExecutionSkeleton`), error (`ErrorState` with retry), ended run (banner, §6).
Discard uses `window.confirm(t('execution.runPlan.discardConfirm', {revision}))` (same pattern as
`PlanCreatorView` reload confirm), then `discardRunPlan` with `draft.lock_version`; on 409 reload
state and show `plan-inline-error`.

---

## 4. PlanCreator in run context

### 4.1 Wrapper — `views/execution/RunPlanEditorView.vue` (new, ~80 lines)

- Props `runId: string`. Loads `RunPlanState`; shows `ExecutionSkeleton`/`ErrorState`.
- Renders `<PlanCreatorView :plan-id="String(state.run_plan.plan_id)" :run-context="ctx" />` where

```ts
export interface RunPlanEditorContext {
  runId: number
  runName: string
  state: Ref<RunPlanState>
  refresh: () => Promise<void>       // re-fetches RunPlanState
}
```

### 4.2 `views/PlanCreatorView.vue` (modified, additive)

New optional prop `runContext?: RunPlanEditorContext`. Without it, behaviour is byte-for-byte
today's. With it:

| Area | Library context (today) | Run context |
| --- | --- | --- |
| Back link | `/plans` | `{ name: 'execution-run-plan', params: { runId } }`, label "Run plan" |
| Eyebrow | `PlanCreator` | `Run plan · {runName}` |
| Ownership strip (new `RunPlanContextBanner.vue`, below toolbar, non-dismissable, subtle `panel` style) | — | "You are editing this run's own plan. Changes to days, workouts, exercises and sets reach the run only when you apply them; the name, description, colour and cover update as soon as you save. {source} in My Plans is not affected." Shows `r{current} applied · draft r{draft}`. |
| Identity section (`PlanEditor.vue` identity panel) | — | Caption under the panel heading: "Updates immediately — no Apply needed." (`plans.runContext.identityImmediate`), rendered when `lockDayStructure` is set. The cover upload in `PlanCoverEditor.vue` already writes immediately through `PUT /image`. |
| Save button | "Save plan" (Ctrl S) | "Save draft" (Ctrl S). Same `editor.save()`. |
| Status chip | Saving / Conflict / Failed / Unsaved / Saved / Current | Same, plus "Saved · not applied" when `!dirty && state.draft.has_unapplied_changes` (refresh state after each save). Saving only identity changes (name, description, accent) shows plain "Saved": they are already live and never count as unapplied. |
| Primary action | — | **Apply to run…** (`button primary`). Enabled when `modifiable` and (`dirty` or `has_unapplied_changes`). If `dirty`: run `savePlan()` first; abort on failure. Then open `RunPlanApplyDialog`. |
| Secondary actions | Export JSON | Export JSON, **Save as new plan…** (opens `RunPlanPromoteDialog`; requires `!dirty`, otherwise prompt to save first). |
| Structure | Add/duplicate/remove days | Day count locked (§4.3). |
| Tabs | Plan / Analysis / Modulation (disabled) | identical; Analysis analyses the working copy. |
| Leave guard | confirm if dirty | identical (`onBeforeRouteLeave`). Saved-but-unapplied changes do not block navigation; the Run Plan tab shows the banner. |
| After Apply | — | `await editor.reloadLatest()` (draft renumbered, lock bumped), `await runContext.refresh()`, inline success `plan-inline-success`: "Applied as revision r{n}. {k} upcoming sessions now follow it." with link "View run plan". |

### 4.3 Locked day structure

`PlanEditor.vue` gains prop `lockDayStructure?: boolean` (default `false`):

- Hide both "Add day" buttons (header and empty state).
- Pass `:structure-locked="lockDayStructure"` to `DayEditor.vue`, which hides **Duplicate** (⧉) and
  **Remove** (×). Move ↑/↓, "Add workout" on rest days and "Remove workout" (→ rest day) stay.
- Under the days heading show `plans.runContext.dayCountLocked`: "A running plan keeps its
  {count}-day microcycle. You can reorder days, turn rest days into training days and back, and edit
  everything inside a day."

### 4.4 Server validation issues

`run_plan_not_executable` issues use ordinal paths. New helper `features/plans/run-plan.ts →
mapServerIssues(draft: PlanEditorState, issues): PlanValidationIssue[]` converts
`days.<ordinal>.workout_unit.exercise_slots.<ordinal>` to the editor's `days.<clientKey>.slots.<clientKey>`
paths and assigns them to `editor.validationIssues`, so the existing field highlighting works; also
switch to the Plan tab and scroll to the first issue (reuse `reviewGuidance` scrolling).

---

## 5. Apply flow — `RunPlanApplyDialog.vue`

```text
Apply changes to this run?                                                     [×]
Revision r4 replaces r3 from today (Sun 22 Nov). Completed workouts keep exactly
what you did.

  ✓ 21 upcoming sessions follow the new plan
  ✓ 4 sessions move to their new day from next week
  + Added: Cable fly (Push B)
  − Removed: Pec deck (Push B) — its history stays in Analysis
  − Removed workout: Arms (Sat) — 5 upcoming sessions removed; your 1 cancellation stays in history
  ⏵ Pull A, in progress, finishes on r3

  ⚠ These saved prescriptions will be discarded:
     Pec deck · Fri 20 Nov · 40 / 40 / 35 kg — exercise replaced

  What changed? (optional, shown in the run history)
  [ Pec deck removed from the gym                                           ]

                                             [ Cancel ]   [ Apply r4 ]
```

Sequence:

1. Open → `applyRunPlan(runId, { draft_lock_version, expected_applied_revision_id, dry_run: true })`
   → render `impact`. Loading row while waiting.
2. Confirm → same request with `dry_run: false` and `note`.
3. Success → emit `applied(result)`; caller performs §4.2 "After Apply".

Error handling:

| Response | Dialog behaviour |
| --- | --- |
| `already_applied: true` | Treat as success. |
| 409 `draft_version_conflict` | Close dialog; set the editor conflict banner (existing `conflict-banner`, "Reload latest"). |
| 409 `run_plan_revision_conflict` | Message "This run's plan changed in another window." Button "Reload and review" → `runContext.refresh()` then repeat the dry run. |
| 409 `run_plan_not_modifiable` | Message + close; editor switches to ended-run mode (§6). |
| 422 `run_plan_unchanged` | Message "Nothing to apply"; close. |
| 422 `run_plan_not_executable` | Show the issue list; "Show in editor" closes and applies §4.4. |
| Network/500 | Inline error, keep dialog open; Apply retry is safe (idempotent replay). |

Copy rules: always say *from today* (v1 has no "apply from date" control, `01` §10); name the
in-progress workout if any; never say "history is rewritten" (it is not); say that cancellations are
kept; never say that *all* changes wait for Apply — name, description, colour and cover are already
live; list discarded prescriptions with their loads so nothing silent happens.

---

## 6. Ended runs

When `modifiable === false` (run `completed`/`cancelled`):

- Run Plan tab banner: "This run has ended. Its plan can no longer change what the run executes. You
  can still save it as a new plan." Unapplied-changes banner hidden; Apply/Discard hidden.
- Editor: Apply hidden; Save draft still allowed (to prepare a promotion); ownership strip says
  "Changes here are only useful for Save as new plan".

---

## 7. Library promotion — `RunPlanPromoteDialog.vue`

```text
Save as a new plan in My Plans
  Name  [ PPL upper focus — Autumn block              ]
  Source  (●) Current run definition (r3, what the run executes)
          ( ) Working copy with unapplied changes            ← shown only if has_unapplied_changes
  The new plan is independent: editing it never affects this run.
                                                  [ Cancel ]  [ Create plan ]
```

- Default name: `{run plan name} — {run name}` truncated to 200 chars.
- Request: `plansApi.duplicate(state.run_plan.plan_id, { name, source_revision_id })`;
  `source_revision_id` = `current_revision.plan_revision_id` for "Current run definition", omitted for
  "Working copy".
- Success: inline success with link to `/plans/{id}` ("Open in My Plans") and to
  `/execution/runs/new` ("Start a run from it").
- Entry points: Run Plan tab button, editor secondary action.

---

## 8. Other screens

| Screen | Change |
| --- | --- |
| `NewPlanRunView.vue` | Replace `execution.newRun.draftWarning` with info text `execution.newRun.copyNotice`: "The run gets its own copy of this plan. Later edits in My Plans won't change it; adjust the run from Execution → Run plan." Hide the revision selector when the plan has a single revision. On 422 `plan_not_executable`, list the issues (workout/exercise names from the paths) with a link to the plan in My Plans (Q1). |
| `PlanListView.vue` | No change (backend filters run plans). |
| Overview / Timeline | Microcycle revision tick already exists (`revision_changed_here`, `r{plan_revision_no}`); label the `plan_revision_changed` event "Run plan modified" and link it to the Run Plan tab. When un-cancelling a session returns 409 `session_workout_removed`, show `execution.runPlan.cannotUncancel` inline. |
| `LoadsChart.vue` / `LoadPerSetStrip.vue` | Break the line where `point.exercise_id` changes; tooltip shows the exercise name; legend shows the latest exercise. |
| `ExerciseTraceTable.vue`, `WorkoutTraceView.vue`, `AnalysisQueue.vue` | Chip "Removed from plan" when `retired`; retired exercises sorted after active ones; retired workouts absent from the queue. |

---

## 9. State management

No new Pinia store. Run-plan state is view-local (`ExecutionRunPlanView`, `RunPlanEditorView`) and
refreshed after Save, Apply, Discard. `ExecutionLayout.load()` is re-run after Apply/Discard to update
the tab dot and the run bar. Editor state stays in `usePlanDraft` (unchanged).

---

## 10. i18n

All new strings go to the 11 locales (`en, pl, fr, es, de, it, nl, sv, pt-BR, uk, tr`) in
`src/i18n/locales/<locale>/execution.ts` (`execution.runPlan.*`, `execution.tabs.runPlan`,
`execution.newRun.copyNotice`, `execution.run.runPlanFrom`, `execution.run.sourceDeleted`) and
`plans.ts` (`plans.runContext.*`). English source keys:

```ts
// execution.ts
tabs: { …, runPlan: 'Run plan' },
runPlan: {
  eyebrow: 'Run plan', applied: 'r{revision} · applied {date}',
  ownership: 'This run has its own copy of the plan. Changing it never affects "{source}" in My Plans, and other runs are not affected.',
  ownershipNoSource: 'This run has its own copy of the plan. The plan it was copied from has been deleted.',
  edit: 'Edit run plan', promote: 'Save as new plan…',
  unapplied: 'You have saved changes that are not applied to this run yet.',
  review: 'Review & apply…', discard: 'Discard', discardConfirm: 'Discard unapplied changes to days, workouts, exercises and sets and return the working copy to r{revision}? The name, description, colour and cover stay as they are.',
  cannotUncancel: "This workout is no longer in the run plan, so its cancellation can't be undone.",
  definition: 'Current definition', summary: '{days} days · {workouts} workouts · {exercises} exercises · {sets} sets',
  history: 'Modification history', copied: 'Copied from {source} when the run was created',
  historyImpact: '{sessions} sessions updated', historyDiscarded: '{count} prescription discarded | {count} prescriptions discarded',
  view: 'View', ended: 'This run has ended. Its plan can no longer change what the run executes. You can still save it as a new plan.',
  apply: {
    title: 'Apply changes to this run?', lead: 'Revision r{next} replaces r{current} from today ({date}). Completed workouts keep exactly what you did.',
    rebound: '{count} upcoming session follows the new plan | {count} upcoming sessions follow the new plan',
    redated: '{count} session moves to its new day from next week | {count} sessions move to their new day from next week',
    added: 'Added: {name} ({workout})', removed: 'Removed: {name} ({workout}) — its history stays in Analysis',
    removedWorkout: 'Removed workout: {workout} — {removed} upcoming sessions removed; {retained} cancelled or missed sessions stay in history',
    inProgress: '{workout}, in progress, finishes on r{revision}',
    discarded: 'These saved prescriptions will be discarded:',
    reasons: { exercise_changed: 'exercise replaced', set_structure_changed: 'sets changed', slot_removed: 'exercise removed', workout_removed: 'workout removed' },
    note: 'What changed? (optional, shown in the run history)', confirm: 'Apply r{next}',
    conflict: "This run's plan changed in another window.", reload: 'Reload and review', unchanged: 'Nothing to apply.',
    success: 'Applied as revision r{revision}. {count} upcoming sessions now follow it.',
  },
  promoteDialog: { title: 'Save as a new plan in My Plans', name: 'Name', source: 'Source',
    current: 'Current run definition (r{revision}, what the run executes)', draft: 'Working copy with unapplied changes',
    independent: 'The new plan is independent: editing it never affects this run.', create: 'Create plan',
    created: '"{name}" was added to My Plans.', open: 'Open in My Plans', startRun: 'Start a run from it' },
},
run: { …, runPlanFrom: 'Run plan: {plan} · copied from {source}', sourceDeleted: 'Run plan: {plan} · source plan deleted' },
newRun: { …, copyNotice: "The run gets its own copy of this plan. Later edits in My Plans won't change it; adjust the run from Execution → Run plan." },

// plans.ts
runContext: {
  eyebrow: 'Run plan · {run}', back: 'Run plan', saveDraft: 'Save draft', apply: 'Apply to run…',
  notApplied: 'Saved · not applied', revisions: 'r{current} applied · draft r{draft}',
  ownership: "You are editing this run's own plan. Changes to days, workouts, exercises and sets reach the run only when you apply them; the name, description, colour and cover update as soon as you save. {source} in My Plans is not affected.",
  identityImmediate: 'Updates immediately — no Apply needed.',
  endedOwnership: 'This run has ended. Changes here are only useful for Save as new plan.',
  dayCountLocked: 'A running plan keeps its {count}-day microcycle. You can reorder days, turn rest days into training days and back, and edit everything inside a day.',
  saveFirst: 'Save your changes first.',
},
```

---

## 11. Files

| New | Modified |
| --- | --- |
| `src/views/execution/ExecutionRunPlanView.vue` | `src/router/index.ts` |
| `src/views/execution/RunPlanEditorView.vue` | `src/views/execution/ExecutionLayout.vue` (tab, run bar) |
| `src/components/execution/run-plan/RunPlanDefinition.vue` | `src/views/PlanCreatorView.vue` (optional `runContext`) |
| `src/components/execution/run-plan/RunPlanHistory.vue` | `src/components/plans/PlanEditor.vue` (`lockDayStructure`) |
| `src/components/execution/run-plan/RunPlanRevisionDrawer.vue` | `src/components/plans/DayEditor.vue` (`structureLocked`) |
| `src/components/execution/run-plan/RunPlanApplyDialog.vue` | `src/views/execution/NewPlanRunView.vue` |
| `src/components/execution/run-plan/RunPlanPromoteDialog.vue` | `src/api/execution.ts`, `src/api/execution-types.ts`, `src/api/plans.ts`, `src/api/plan-types.ts` |
| `src/components/plans/RunPlanContextBanner.vue` | `src/components/execution/LoadsChart.vue`, `ExerciseTraceTable.vue`, `AnalysisQueue.vue`, `src/views/execution/WorkoutTraceView.vue` |
| `src/features/plans/run-plan.ts` (`mapServerIssues`, default promotion name) | `src/i18n/locales/*/execution.ts`, `src/i18n/locales/*/plans.ts` |
| `tests/run-plan-view.test.ts`, `tests/run-plan-editor.test.ts`, `tests/run-plan-apply-dialog.test.ts`, `tests/run-plan-promote.test.ts` | `tests/plan-editor.test.ts`, `tests/execution.test.ts`, `tests/i18n.test.ts` (if keys are enumerated) |
