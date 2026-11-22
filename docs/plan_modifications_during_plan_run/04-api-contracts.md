# 04 — API Contracts

Two existing conventions are kept:

- **Plans API** (`/api/plans`, `modules/plans/router.py`): errors `{"detail": "..."}`; 404 not found,
  409 conflicts (lock version), 422 domain validation; optimistic concurrency via `lock_version` in the
  body.
- **Execution API** (`/api/v1/exec`, `modules/execution/router.py`): errors
  `{"error": {"code", "message", "details"}}` (`modules/execution/errors.py`, `app.py`), 422
  `request_validation` envelope for schema errors; optimistic concurrency via body fields.

Editing the working copy reuses the Plans API unchanged. Run-plan lifecycle operations live under
the Execution API because they have execution side effects. No new architectural style is introduced.

---

## 1. New Execution endpoints

### 1.1 `GET /api/v1/exec/plan-runs/{plan_run_id}/run-plan`

Run-plan state for the Run Plan tab and the editor's run context.

Response `200 RunPlanState`:

```json
{
  "plan_run_id": 14,
  "run_status": "active",
  "modifiable": true,
  "run_plan": {
    "plan_id": 41,
    "code": "P041",
    "name": "PPL upper focus",
    "accent": "teal",
    "image_url": "/api/plans/41/image?v=3f2a…"
  },
  "source_plan": { "plan_id": 15, "code": "P015", "name": "PPL upper focus" },
  "current_revision": {
    "plan_revision_id": 88,
    "revision_no": 3,
    "released_at": "2026-11-18T19:02:11Z",
    "summary": { "days": 7, "workouts": 5, "exercises": 36, "sets": 112 }
  },
  "draft": {
    "plan_revision_id": 89,
    "revision_no": 4,
    "lock_version": 7,
    "updated_at": "2026-11-21T08:40:00Z",
    "has_unapplied_changes": true
  },
  "history": [
    {
      "plan_revision_id": 88,
      "revision_no": 3,
      "released_at": "2026-11-18T19:02:11Z",
      "origin": "applied",
      "note": "Pec deck removed from the gym",
      "event_id": 512,
      "impact": {
        "sessions_rebound": 21, "sessions_added": 0, "sessions_removed": 0, "sessions_retained": 0,
        "exercises_added": 1, "exercises_retired": 1,
        "analysis_rebased": 3, "analysis_discarded": 1
      }
    },
    {
      "plan_revision_id": 70,
      "revision_no": 1,
      "released_at": "2026-10-26T07:00:00Z",
      "origin": "copied_from_library",
      "note": null,
      "event_id": null,
      "impact": null
    }
  ]
}
```

- `modifiable` = `run_status in {scheduled, active}`.
- `run_plan.name/accent/image_url` are the run plan's current identity values. They are plan-level,
  change immediately on `PUT …/draft` or `PUT/DELETE …/image`, and never make
  `has_unapplied_changes` true (`01` D14). `has_unapplied_changes` reflects the revision-scoped
  definition only.
- `source_plan` is `null` when the library plan was deleted (or for runs converted from a plan that
  no longer exists).
- `history` is newest first: every RELEASED revision, joined to its `plan_revision_changed` event
  (`metadata.impact` summary; `details` → `note`). Revision 1 has `origin: "copied_from_library"`.
- Errors: `404 plan_run_not_found`.

### 1.2 `GET /api/v1/exec/plan-runs/{plan_run_id}/run-plan/revisions/{plan_revision_id}`

Read-only definition of one applied revision (overview rendering and history inspection). Also
accepts the draft's id (returns the working copy read-only).

Response `200 PlanRevisionArtifact` — the existing `PlanDraftArtifact` shape (same
`days → workout_unit → exercise_slots → variants → sets` tree, `modules/plans/schemas.py:421`) plus:

```json
{ "status": "RELEASED", "released_at": "2026-11-18T19:02:11Z", "...": "PlanDraftArtifact fields" }
```

`lock_version` is informational for RELEASED revisions. Lineage keys are not exposed.

Errors: `404 plan_run_not_found`; `404 plan_revision_not_found` when the revision does not belong to
this run's run plan (never reveals other plans).

### 1.3 `POST /api/v1/exec/plan-runs/{plan_run_id}/run-plan/apply`

Request `RunPlanApply`:

```json
{
  "draft_lock_version": 7,
  "expected_applied_revision_id": 88,
  "note": "Pec deck removed from the gym",
  "dry_run": false
}
```

| Field | Type | Rules |
| --- | --- | --- |
| `draft_lock_version` | int ≥ 1 | Must equal the working copy's current `lock_version`. |
| `expected_applied_revision_id` | int ≥ 1 | The `current_revision.plan_revision_id` the client last saw. |
| `note` | string \| null | ≤ 500 chars; stored as the event's `details`. |
| `dry_run` | bool, default `false` | Same transaction, forced rollback. |

Response `200 RunPlanApplyResult`:

```json
{
  "dry_run": false,
  "already_applied": false,
  "previous_revision": { "plan_revision_id": 88, "revision_no": 3 },
  "applied_revision": { "plan_revision_id": 95, "revision_no": 4, "released_at": "2026-11-22T10:15:03Z" },
  "effective_on": "2026-11-22",
  "impact": {
    "sessions": {
      "rebound": 21, "redated": 4, "added": 0, "removed": 0, "retained": 0,
      "redate_skipped": 0, "deferred_to_next_microcycle": 0, "untouched_executed": 9
    },
    "workouts": {
      "added":   [],
      "retired": []
    },
    "exercises": {
      "added":   [{ "exercise_trace_id": 301, "workout_trace_id": 44, "workout_name": "Push B", "name": "Cable fly" }],
      "retired": [{ "exercise_trace_id": 233, "workout_trace_id": 44, "workout_name": "Push B", "name": "Pec deck" }]
    },
    "prescriptions": {
      "fallback_cleared": 1,
      "analysis_rebased": 3,
      "analysis_discarded": [
        {
          "session_id": 1201,
          "scheduled_date": "2026-11-20",
          "exercise_trace_id": 233,
          "name": "Pec deck",
          "reason": "exercise_changed",
          "loads_kg": [40.0, 40.0, 35.0]
        }
      ]
    },
    "in_progress_session": null
  },
  "state": { "...": "RunPlanState after the operation" }
}
```

- `dry_run: true` → `applied_revision.plan_revision_id` and newly created `exercise_trace_id`/
  `workout_trace_id` values are `null` (rolled back); `state` is the unchanged pre-apply state.
- `already_applied: true` → idempotent replay (§3); `impact` is `null`.
- `reason` ∈ `slot_removed | exercise_changed | set_structure_changed | workout_removed`.
- `sessions.removed` counts only deleted `scheduled` sessions of removed workouts (dated today or
  later). `sessions.retained` counts athlete cancellations and recoverable missed sessions of removed
  workouts that are kept with their old binding. Cancelled sessions are never removed or re-dated.
- `in_progress_session` (when present): `{ "session_id", "workout_name", "keeps_revision_no" }` — tells
  the user the running workout finishes on the old definition.

Errors:

| Status | `code` | `details` |
| --- | --- | --- |
| 404 | `plan_run_not_found` | — |
| 409 | `run_plan_not_modifiable` | `{ "run_status": "completed" }` |
| 409 | `draft_version_conflict` | `{ "current_lock_version": 9 }` |
| 409 | `run_plan_revision_conflict` | `{ "current_applied_revision_id": 95, "current_revision_no": 4 }` |
| 422 | `run_plan_unchanged` | — |
| 422 | `run_plan_not_executable` | `{ "issues": [ { "code": "slot_without_exercise", "path": "days.2.workout_unit.exercise_slots.1", "day_ordinal": 2, "slot_ordinal": 1, "message": "…" } ] }` |
| 422 | `request_validation` | standard envelope |

Issue codes: `day_count_changed` (details also carry `expected_days`, `actual_days`), `no_workouts`,
`workout_without_exercises`, `slot_without_exercise`, `exercise_without_sets`, `duplicate_lineage`.

### 1.4 `POST /api/v1/exec/plan-runs/{plan_run_id}/run-plan/discard`

Resets the working copy to the current applied revision.

Request: `{ "draft_lock_version": 7 }` → `200 RunPlanState` (new draft `lock_version`; draft row ids
change, so the editor must reload).

Errors: `404 plan_run_not_found`, `409 run_plan_not_modifiable`, `409 draft_version_conflict`,
`422 run_plan_unchanged` (nothing to discard).

---

## 2. Changed existing endpoints

| Endpoint | Change | Compatibility |
| --- | --- | --- |
| `POST /api/v1/exec/plan-runs` | `plan_revision_id` must belong to a **library** plan (`422 plan_revision_not_library`). The run receives its own copy (revision 1 applied + working copy). Response unchanged in shape (overview). | Additive behaviour; same request. |
| `GET /api/v1/exec/plan-runs/preview` | Unchanged (reads the library revision). | — |
| `GET /api/v1/exec/plan-runs`, `…/{id}/overview` (run header) | `run.plan` = the **run plan** `{plan_id, code, name}` (same text as before until renamed). New: `run.source_plan: {plan_id, code, name} \| null`, `run.current_revision: {plan_revision_id, revision_no}`, `run.has_unapplied_changes: bool`. `initial_revision` now points at run-plan revision 1. | Additive except `plan_id`/`code` now identify the run plan. Web FE updated in T4.5. |
| `DELETE /api/v1/exec/plan-runs/{id}` | Also deletes the run plan. Plans promoted from it survive (`source_plan_id` → NULL). | Same contract. |
| `PATCH /api/v1/exec/plan-runs/{id}/sessions/{session_id}` (`status: scheduled` on a cancelled session) | New 409 `session_workout_removed` when the session's workout is no longer in the current run-plan revision. | New error on an existing endpoint. |
| `GET …/microcycles` (timeline, `ExecutionService._timeline`) | When a retained cancellation shares a date with another session, `days[].session` is the non-cancelled one. | Same shape. |
| Traces (`…/workout-traces`, `…/exercise-traces/{id}`, `…/analysis/queue`) | `day_ordinal`/`slot_ordinal` = position in the current revision; new `retired: bool` on workout and exercise traces; retired tracks excluded from the analysis queue. | Additive. |
| `GET …/load-series` | Each point gains `exercise_id`, `exercise_name`; `first_value`/`latest_value`/`delta_pct` computed over the latest exercise segment. | Additive. |
| `GET /api/plans` | Lists `scope = 'library'` only. `PlanSummary` gains `scope`, `source_plan_id`. | Additive. |
| `GET /api/plans/{id}`, `GET /api/plans/{id}/draft`, `PUT …/draft` response | Gain `scope: "library" \| "run"`, `source_plan_id`, `plan_run_id` (draft/detail only). `PUT` accepts and ignores them. | Additive. |
| `DELETE /api/plans/{id}` | Run plan → `409 {"detail": "Run plans are deleted together with their plan run"}`. Library plans with runs are now deletable (no more 500). | Behaviour fix. |
| `POST /api/plans/{id}/duplicate` | Optional body (§4). | Empty/absent body keeps today's behaviour. |
| `GET/POST /api/v1/mobile/sessions/{id}/prescription/fallback` | `fallback_unavailable` gains `details.reason = "session_not_current"` for sessions bound to a non-current revision (retired workouts). | Additive. |

All other mobile endpoints are unchanged in shape.

---

## 3. Revision identifiers and concurrency

| Identifier | Meaning | Used for |
| --- | --- | --- |
| `run_plan.plan_id` | The run plan row; use with every `/api/plans/{id}/draft*` call. | Editor loading/saving/analysis/export/promotion. |
| `draft.plan_revision_id` / `draft.revision_no` | Working copy identity; `revision_no` is the number the next Apply produces. | `PlanDraftUpdate.revision_id/revision_no`. |
| `draft.lock_version` | Optimistic version of the working copy (existing). | `PUT draft`, Apply, Discard. |
| `current_revision.plan_revision_id` | What the run executes now. | Apply's `expected_applied_revision_id`. |

Rules:

1. Every successful Apply renumbers the draft (`revision_no + 1`) and bumps its `lock_version`.
   Clients reload the working copy after Apply (a stale editor gets the existing plans 409 on save).
2. Replay safety: if `expected_applied_revision_id` is stale **and** the draft definition already equals
   the current revision, Apply returns `200 already_applied: true` instead of 409.
3. Apply and mobile workout start are serialised server-side; no client coordination is needed.
4. Save-then-apply from the editor is two calls: `PUT /api/plans/{id}/draft` (returns the new
   `lock_version`) then Apply with that version.
5. Identity metadata is not revision-scoped: the `name`, `description`, `accent` sent with
   `PUT /api/plans/{runPlanId}/draft`, and cover changes through `/image`, take effect for the run plan
   at once. Apply and Discard neither include nor revert them.

---

## 4. Library promotion — `POST /api/plans/{plan_id}/duplicate`

Request (all fields optional):

```json
{ "name": "PPL upper focus — after cycle 1", "source_revision_id": 88 }
```

| Field | Rules |
| --- | --- |
| `name` | 1–200 chars, not blank. Default: today's `"<name> copy"` rule (`_duplicate_plan_name`). |
| `source_revision_id` | A revision of `plan_id` (DRAFT or RELEASED). Default: the DRAFT. |

Response `201 PlanDraftArtifact` of the **new library plan**:

```json
{
  "id": 57, "revision_id": 120, "revision_no": 1, "lock_version": 1,
  "name": "PPL upper focus — after cycle 1",
  "scope": "library", "source_plan_id": 41, "plan_run_id": null,
  "description": "…", "accent": "teal", "image_url": "/api/plans/57/image?v=…",
  "days": [ "…" ]
}
```

Semantics: new `scope='library'` plan, copied tree with **fresh progression ids**, cover image
copied, `based_on_revision_id = source revision`, `source_plan_id = plan_id`. Independent of the run
and immediately usable in `POST /api/v1/exec/plan-runs`.

Errors: `404 {"detail": "Plan 41 was not found"}`; `422 {"detail": "source_revision_id 99 does not
belong to plan 41"}`; FastAPI default 422 for body validation.

Run Plan UI usage: "Save current run definition as new plan" → `source_revision_id =
current_revision.plan_revision_id`; "Save working copy as new plan" → omit it.

---

## 5. Pydantic models (backend)

```python
# modules/execution/schemas.py (or run_plan_schemas.py)
class RunPlanApply(APIModel):
    draft_lock_version: int = Field(ge=1)
    expected_applied_revision_id: int = Field(ge=1)
    note: str | None = Field(default=None, max_length=500)
    dry_run: bool = False

class RunPlanDiscard(APIModel):
    draft_lock_version: int = Field(ge=1)

class RunPlanState(APIModel): ...          # §1.1
class RunPlanApplyResult(APIModel): ...    # §1.3

# modules/plans/schemas.py
class PlanScope(str, Enum): LIBRARY = "library"; RUN = "run"
class PlanDuplicateRequest(APIModel):
    name: str | None = Field(default=None, min_length=1, max_length=200)
    source_revision_id: int | None = Field(default=None, ge=1)
class PlanRevisionArtifact(PlanDraftArtifact):
    status: PlanRevisionStatus
    released_at: datetime | None
```

Add the new routes to `ERROR_RESPONSES` documentation and regenerate `__docs__/api/openapi.yaml`;
`tests/test_openapi.py` must be updated.

---

## 6. Frontend types (`web-fe/src/api/execution-types.ts`, `plan-types.ts`)

```ts
export type PlanScope = 'library' | 'run'

export interface RunPlanRevisionRef { plan_revision_id: number; revision_no: number; released_at?: string }

export interface RunPlanState {
  plan_run_id: number
  run_status: PlanRunStatus
  modifiable: boolean
  run_plan: { plan_id: number; code: string; name: string; accent: PlanAccent | null; image_url: string | null }
  source_plan: { plan_id: number; code: string; name: string } | null
  current_revision: RunPlanRevisionRef & { summary: { days: number; workouts: number; exercises: number; sets: number } }
  draft: { plan_revision_id: number; revision_no: number; lock_version: number; updated_at: string; has_unapplied_changes: boolean }
  history: Array<RunPlanRevisionRef & {
    origin: 'copied_from_library' | 'applied'
    note: string | null
    event_id: number | null
    impact: Record<string, number> | null
  }>
}

export interface RunPlanApplyRequest {
  draft_lock_version: number
  expected_applied_revision_id: number
  note?: string | null
  dry_run?: boolean
}

export interface RunPlanApplyResult {
  dry_run: boolean
  already_applied: boolean
  previous_revision: RunPlanRevisionRef
  applied_revision: { plan_revision_id: number | null; revision_no: number; released_at: string | null } | null
  effective_on: string
  impact: RunPlanImpact | null
  state: RunPlanState
}
// RunPlanImpact mirrors §1.3.

// plan-types.ts additions
// PlanDraftArtifact & PlanSummary: scope: PlanScope; source_plan_id: number | null
// PlanDraftArtifact & PlanDetail:   plan_run_id: number | null
export interface PlanDuplicateRequest { name?: string; source_revision_id?: number }
```

Client methods: `executionApi.runPlan(runId)`, `executionApi.runPlanRevision(runId, revisionId)`,
`executionApi.applyRunPlan(runId, body)`, `executionApi.discardRunPlan(runId, body)`;
`plansApi.duplicate(planId, body?)` gains the optional body.
