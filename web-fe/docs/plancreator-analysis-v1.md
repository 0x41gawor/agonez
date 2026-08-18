# PlanCreator ANALYSIS tab V1 implementation plan

Status: implemented and deployed locally (2026-08-18)

## Verified source contract

- Consume `POST /api/plans/{plan_id}/draft/analysis` with default resolution context
  `{global_volume_level: 0, focus_area: null, axis_overrides: {}}`.
- The deployed OpenAPI contract was inspected before defining TypeScript DTOs.
- Existing plan 6 currently returns 7 timeline days, 47 muscle summaries, 11 joint
  summaries, about 2,073 provenance records, and an inspectable
  `RECOVERY_DIVERGENCE` diagnostic.
- Backend result fields and model parameters remain authoritative. Vue performs only
  display transforms, sorting, filtering, grouping of returned provenance, and lookup
  construction; it does not implement evaluator equations.

## Architecture

```text
PlanCreatorView
  ├── usePlanDraft          editable local PLAN state
  └── usePlanAnalysis       persisted-draft derived state
        └── plansApi.analyzeDraft

PlanAnalysis
  ├── frozen Analysis snapshot + status overview
  ├── chronological MicrocycleTimeline
  ├── selected WorkoutAnalysis
  │     ├── one shared BodyViewer (recovery display only)
  │     ├── BEFORE / AFTER state
  │     └── returned workout stimulus
  ├── MuscleSummary + selected provenance inspector
  ├── JointSummary + selected provenance inspector
  ├── diagnostics
  └── collapsed model metadata
```

The PLAN editor remains mounted while tabs switch so unsaved editor state is never
discarded. ANALYSIS is fetched on first activation and reused until stale or manually
refreshed. A successful PLAN save invalidates the previous result. Dirty local PLAN
state and analyzed/current lock-version mismatch are both visible freshness states.

## Interaction and performance decisions

- The timeline is the primary selection control and preserves backend order, including
  selectable rest days.
- BEFORE/AFTER switches between already-returned snapshots without HTTP requests.
- The existing `BodyViewer` receives a display-only recovery vector capped into fixed
  0, 0–24, 24–48, 48–72, and 72+ hour intensity bands. Tooltip/inspector values retain
  the real uncapped backend hours.
- Muscle names reuse the existing Atlas catalog. Joint display names use one isolated
  deterministic frontend map because no backend joint catalog exists yet.
- Provenance is indexed in cached computed maps. Only the selected resource is grouped,
  and source/set rows are limited or disclosed on demand; thousands of records are not
  mounted at once.
- Muscle and joint summaries default to the strongest rows and offer explicit expansion.
- Absolute ETU and backend-provided ETU/FCSA are distinct display modes. Recovery anatomy
  is never affected by that switch.

## Verification completed

- Strict TypeScript and the Vite production build pass.
- ESLint passes with zero warnings.
- Vitest passes all 52 tests across 13 files. Analysis coverage includes first fetch,
  the default context, enabled/disabled tabs, stale/lock mismatch, save invalidation,
  timeline selection, BEFORE/AFTER, anatomy input, summaries, intent classes,
  provenance, diagnostics, HTTP errors, and bounded provenance DOM.
- The existing Docker frontend was rebuilt and is healthy on `MERSAA=33288` with its
  backend proxy targeting `MAMMOONE=33287`.
- The deployed proxy was checked against populated plan 6. It returned
  `plan-analysis-v1`, seven days (five workouts and two rest days), 47 muscles,
  11 joints, 2,073 contribution records, and an inspectable
  `RECOVERY_DIVERGENCE` diagnostic.

Out of scope: evaluator math, plan scoring/recommendations, editable modulation,
systemic fatigue, progression/execution, joint anatomy, or analysis persistence.
