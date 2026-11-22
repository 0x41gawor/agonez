# 01 — Domain Model and Architecture

This document defines the target model for **Run Plans** and the persistent **Run Plan
Modification**. Every decision references the evidence in `00-current-state-audit.md` (cited as
"Audit §n").

---

## 1. Vocabulary

| Term | Meaning |
| --- | --- |
| **Library plan** | A reusable plan shown in My Plans. `plans.workout_plans.scope = 'library'`. Keeps today's single-DRAFT lifecycle. |
| **Run plan** | The plan definition owned by exactly one plan run. A `plans.workout_plans` row with `scope = 'run'`, referenced by `exec.plan_runs.run_plan_id`. |
| **Working copy** | The run plan's single `DRAFT` revision. Edited by PlanCreator through the existing `/api/plans/{id}/draft` endpoints. Never referenced by Execution. |
| **Applied revision** | An immutable `RELEASED` revision of the run plan. Revision 1 is the copy made at run creation; each Apply adds one. |
| **Current revision** | The applied revision with the highest `revision_no`. It is "the plan the run executes now". |
| **Run Plan Modification** | The one persistent change type: *Apply* the working copy to the run, producing a new applied revision and reconciling unexecuted sessions. |
| **Session Override** | Existing one-off, per-session changes (PWA loads/comments, mobile substitute/skip/add/reorder, status changes). Unchanged by this feature. |
| **Lineage key** | A UUID on `plans.workout_unit_prescriptions` and `plans.exercise_slots` that survives copying between revisions. Execution tracks are keyed by it. |
| **Bound revision** (of a session) | The revision owning the session's `source_plan_day_id`. |
| **Executed session** | A session with a performance artifact: `in_progress` or `completed` (DB-enforced by `exec.enforce_session_performance_consistency`). |
| **Unexecuted session** | `scheduled`, `missed` or `cancelled` — never has a performance artifact. |
| **Pending session** | An unexecuted session that can still be executed: `scheduled`; `cancelled` dated today or later (it can be un-cancelled); `missed` and still recoverable (after its track's latest executed occurrence). Only pending sessions are reconciled. Others are **settled** (`03` §1). |
| **Athlete cancellation** | A session the athlete set to `cancelled`. Apply never deletes it, re-dates it or changes its status; it may only rebind its content (`03` §5). |

---

## 2. Business invariants

| ID | Invariant | Enforcement |
| --- | --- | --- |
| I1 | A plan run executes only its own run plan. No `exec.*` row references a library plan's revisions or child rows. | Composite FK `plan_runs(run_plan_id, run_plan_scope='run')`; application binds only run-plan rows; migration test asserts zero cross references. |
| I2 | Editing a library plan never changes any run. Editing a run plan never changes its source library plan or any other run. | I1 + copy-on-create (D3). |
| I3 | Applied revisions are immutable (the revision row's status and its child rows). | **Application-level, by construction** — every plans write is scoped to the single DRAFT revision; Execution never writes `plans.*`; RESTRICT FKs additionally block deleting referenced rows. No DB trigger (D16). Guarded by T-IMM tests (`07`). |
| I4 | Executed sessions (in progress or completed) are never rebound, re-dated, or re-prescribed by a modification. | Reconciliation filters on "has performance"; tests. |
| I5 | Pending sessions whose workout still exists follow the current revision after Apply. | Reconciliation (D7). |
| I6 | Missed and cancelled sessions keep their status, date, microcycle and notes; adherence history is unchanged. An athlete cancellation is never deleted or re-dated, including when its workout is removed. | Reconciliation never changes the status or date of a missed/cancelled session and deletes only `scheduled` sessions of removed workouts (`03` §5.2). |
| I7 | Track identity follows lineage, never ordinal position. | D5. |
| I8 | Load/progression defaults never cross core exercise identity. | D9. |
| I9 | A modification is atomic: either the new revision and all execution reconciliation commit, or nothing changes. | Single transaction (D10). |
| I10 | The run plan's day count equals `plan_runs.microcycle_duration_days`. | Apply validation (D13) + UI lock. |

---

## 3. Ownership model

```text
                       copy (D3)                         Apply (D10)
 Library plan  ────────────────────►  Run plan  ─────────────────────────►  new applied revision
 scope=library                         scope=run                              (RELEASED, immutable)
 ┌───────────────┐                    ┌──────────────────────────────┐
 │ DRAFT r1      │                    │ r1 RELEASED  (copy at start) │◄── exec.plan_runs.initial_plan_revision_id
 │ (mutable)     │                    │ r2 RELEASED  (Apply #1)      │
 └───────────────┘                    │ r3 RELEASED  (Apply #2)  ◄───┼── current revision
        ▲                             │ r4 DRAFT     working copy    │◄── PlanCreator (run context)
        │ promote (D12)               └──────────────────────────────┘
        └──────────── new library plan (scope=library, fresh progression ids)
                                                │
                                                ▼  sessions bind to applied-revision rows only
                                      exec.workout_sessions / prescriptions / tracks
```

- `exec.plan_runs.run_plan_id` (UNIQUE) expresses ownership: one run owns one run plan. The plans
  module does not need to know about runs beyond `scope` (and a read-only join to show the owning
  run id in the draft artifact).
- Lineage (informational, never behavioural): `workout_plans.source_plan_id` (`ON DELETE SET NULL`)
  points from a run plan to the library plan it was copied from, and from a promoted library plan to
  the run plan it came from. Revision 1 of a run plan has `based_on_revision_id` = the library
  revision copied.
- Deleting a run deletes its run plan. Deleting a library plan never affects runs. Neither deletion
  can block on, or cascade into, an independently promoted plan: every lineage reference
  (`source_plan_id`, `plan_revisions.based_on_revision_id`) is `ON DELETE SET NULL` (verified,
  `02` §3.6).

---

## 4. Run plan lifecycle

```text
 run created ──► [r1 RELEASED + r2 DRAFT]  (draft == current)
                     │
         PUT draft   ▼                         Discard
   ┌──────────► draft != current ───────────────────────► draft := copy(current)
   │                 │
   │          Apply  ▼
   │       new RELEASED rN (copy of draft) ; draft.revision_no := N+1
   │       reconcile execution ; plan_revision_changed event
   └──────────────── draft == current
 run completed/cancelled ──► Apply refused (409 run_plan_not_modifiable);
                             draft editing and promotion still allowed
 run deleted ──► run plan deleted (cascade revisions/children)
```

- "Has unapplied changes" is computed, not stored: a structural fingerprint of the draft tree vs the
  current revision tree (ids excluded, lineage keys included). Editing and manually reverting yields
  "no changes".
- Only the revision-scoped **definition** (days, workouts, exercises, variants, sets, day icons) waits
  for Apply. The plan's identity metadata — name, description, accent, cover image — is plan-level and
  takes effect for the run plan immediately on save/upload, without Apply and without producing
  "unapplied changes" (D14).
- Draft `revision_no` always equals the number its next Apply will produce. Apply renumbers the draft
  and bumps its `lock_version`, so an editor holding a stale draft gets a normal 409 and reloads.

---

## 5. Modification semantics

One operation, **Apply**:

1. Snapshot the working copy as a new immutable applied revision.
2. Reconcile Execution against it at the moment of application ("now" = the Execution service clock
   `ExecutionService._today()`, the same clock `reconcile()` uses).
3. Record a `plan_revision_changed` event (from → to revision, optional athlete note, impact summary).

The change remains in effect until the next Apply. There are no effective-from/to dates, scheduled
revisions or periodisation rules. Calendar time belongs to Execution: whatever is unexecuted at the
moment of application follows the new definition. Example from the brief:

| Week | Action | Effect |
| --- | --- | --- |
| W1–W2 | — | Sessions bound to r1 (2 sets). |
| W3 (Wed) | Apply r2 (3 sets) | Mon/Tue W3 sessions already completed stay r1; Wed–Sun W3 and all later unexecuted sessions rebind to r2. |
| W5 (Mon) | Apply r3 (4 sets) | Everything unexecuted from Mon W5 rebinds to r3. |

---

## 6. Historical integrity rules

| Rule | Mechanism |
| --- | --- |
| H1 Completed sessions keep their prescriptions and performance. | Their prescription snapshots stay; their source FKs point at an immutable applied revision; I4. |
| H2 In-progress sessions do not change. | Same as H1; mobile substitution alternatives read the session's old (immutable) slot rows. |
| H3 Missed/cancelled sessions keep their meaning. | Status/date/microcycle untouched (I6). Settled sessions (non-recoverable missed, past cancelled) keep their binding. Recoverable missed sessions and athlete cancellations of a removed workout are retained with their old binding; they can no longer be started or un-cancelled. |
| H4 Future sessions follow the new definition. | Rebinding + prescription rebase/clear (D7, D8). |
| H5 Analytics distinguish history from the current definition. | History is read through each session's bound revision and prescription snapshots; "current" views read the current revision. |
| H6 Nothing is silently rewritten. | Every discarded user-entered prescription is listed in the Apply response and in the event metadata; dry run shows it beforehand. |

---

## 7. Architecture decisions

Each decision follows: repository today → business need → alternatives → decision → why → trade-offs.

### D1 — Run plan representation: reuse `plans.*` with a `scope`

- **Today:** plan definitions live only in relational `plans.*`; Execution, analysis, export and
  PlanCreator all consume that shape (Audit §2, §3.5).
- **Need:** an isolated, editable copy per run, editable with PlanCreator and analysable.
- **Alternatives:**
  - A. Same tables, `workout_plans.scope = 'library' | 'run'`. 
  - B. Exec-owned mirror tables (`exec.run_plan_days` …): duplicates the plans domain, breaks every
    PlanCreator/analysis/export endpoint, needs a second editor. 
  - C. JSON snapshot (`plan_revisions.snapshot`): Execution RESTRICT FKs and every read path need
    relational child rows. 
  - D. Pin runs to frozen library revisions and add library revisions on change: runs from the same
    plan would share revisions (violates I2), run edits would pollute the library history.
- **Decision:** A.
- **Why:** zero duplication; PlanCreator, analysis, export, image handling and the existing copy code
  work unchanged by plan id.
- **Trade-offs:** library queries must filter `scope = 'library'` (one place: `list_plans`); library-only
  operations (delete, import) need a scope guard.

### D2 — Ownership pointer on `exec.plan_runs`

- **Alternatives:** `plans.workout_plans.owner_plan_run_id → exec.plan_runs` (creates a
  plans→exec schema cycle and a creation-order problem with `initial_plan_revision_id NOT NULL`), or
  `exec.plan_runs.run_plan_id → plans.workout_plans`.
- **Decision:** `exec.plan_runs.run_plan_id integer UNIQUE` with composite FK
  `(run_plan_id, run_plan_scope) → plans.workout_plans(id, scope)` where `run_plan_scope` is a
  constant `'run'` column. The DB itself rejects a run pointing at a library plan.
- **Why:** keeps dependency direction exec → plans (as today), natural insert order, DB-enforced I1.

### D3 — Copying: one SQL function, used everywhere

- **Today:** `PlanRepository._copy_draft_tree` (Python, row-by-row, regenerates progression ids).
  The legacy-run migration must copy trees inside a SQL migration (the runner only executes `.sql`,
  Audit §1).
- **Decision:** introduce `plans.copy_revision_tree(source_revision_id, target_revision_id,
  regenerate_progression_ids boolean)` (PL/pgSQL, returns an id map). Use it in the migration and
  replace the body of `_copy_draft_tree` with a call. Lineage keys are always copied.
  `regenerate_progression_ids` is `false` for run-plan copies (same loops) and `true` for library
  duplicates/promotions (independent loops, today's behaviour).
- **Why:** a single copy implementation for run creation, Apply, Discard, promotion, duplicate and
  migration; set ordering and remapping are proven once.
- **Trade-offs:** a new column must be added to the function (via `CREATE OR REPLACE FUNCTION` in the
  same migration) — the same discipline `_copy_draft_tree` already needed (e.g. `icon` in 0016).

### D4 — Revisions: DRAFT working copy + immutable RELEASED applied revisions

- **Today:** `DRAFT/RELEASED` statuses and the one-draft index exist but release is unused
  (Audit §2.2). Exec references must never point at mutable rows (F1–F13).
- **Alternatives:** mutate one run revision in place (breaks RESTRICT FKs and history display —
  the exact defect R1/R2); a revision per save (PlanCreator saves often; reconciliation per save);
  an operation log/event-sourced plan (new subsystem).
- **Decision:** reuse statuses: one DRAFT working copy edited with the existing save path; Apply
  copies it into a new RELEASED revision. Current = max RELEASED `revision_no`. History = applied
  revisions + `plan_revision_changed` events. `ARCHIVED` stays unused.
- **Why:** the existing save path (including `_delete_omitted`) becomes safe because the draft is never
  referenced by Execution; no new versioning subsystem.

### D5 — Identity: lineage keys, not ordinals

- **Today:** `day:N` / `slot:N` positional keys (Audit §4.1); `progression_id` is variant-level and
  shareable, so it cannot identify a slot.
- **Decision:** add `lineage_key uuid NOT NULL DEFAULT gen_random_uuid()` to
  `plans.workout_unit_prescriptions` and `plans.exercise_slots`; add `plan_lineage_key uuid` to
  `exec.workout_unit_tracks` (unique per run) and `exec.exercise_unit_tracks` (unique per workout
  track). Clients never send lineage keys: draft upserts leave the column untouched for existing ids,
  new rows get the default, copies preserve it. All `_logical_ordinal` parsing is replaced by lineage
  lookups. `logical_key` becomes a legacy label (new tracks store the lineage UUID text in it to keep
  the existing unique constraints meaningful).
- **Why:** reorder/insert/remove cannot re-target identity; moving a slot within a workout keeps its
  track; deleting and re-adding is a *new* exercise unit.
- **Workout identity sits on the workout unit**, not the day: moving a workout to another day keeps
  its track; turning a rest day into a training day creates a new track.
- **Exercise track key = (workout track, slot lineage):** moving a slot to a *different* workout
  creates a new exercise unit there (no silent cross-workout transfer).

### D6 — Session binding is per session

- **Today:** structure is resolved through `microcycles.plan_revision_id` (one revision per
  microcycle). A mid-week modification makes Monday r1 and Thursday r2 inside one microcycle.
- **Decision:** the authoritative governing revision of a session is its bound revision
  (`source_plan_day_id → day.revision_id`). `microcycles.plan_revision_id` is kept and redefined as
  "revision in effect at microcycle start": Apply updates it only for microcycles with
  `starts_on > today`. Reads that need "the current definition" use the run's current revision
  explicitly.
- **Why:** no new column — sessions already carry the binding; the microcycle column keeps its NOT
  NULL FK and the views keep working.

### D7 — Reconciliation boundary

Detailed in `03-execution-reconciliation.md`. Summary:

- Executed sessions and settled sessions (non-recoverable missed, past cancelled): untouched.
- Pending sessions of a workout that still exists: rebound to the new revision.
  - Dates: `scheduled` sessions in future microcycles adopt new day positions; the current
    microcycle keeps existing dates (prevents retroactive "missed" sessions and same-day collisions;
    v1 limitation, §10). Cancelled sessions are never re-dated.
- Pending sessions of a removed workout: future `scheduled` ones deleted — projections, not history;
  athlete cancellations (any date) and recoverable missed sessions retained with their old binding,
  no longer startable or un-cancellable.
- Athlete cancellations of a surviving workout keep status and date; only their content is rebound,
  so un-cancelling one later executes the current definition.
- New workouts: sessions created for every microcycle date `>= today` (current microcycle only if the
  date is free).
- **Recoverable missed sessions are rebound** (decision, see open question Q3): a missed session has
  no executed content; if the athlete catches it up later it must execute the current definition
  (e.g. not the removed machine). Its status/date stay "missed" (I6). Non-recoverable missed sessions
  (`startable_session_ids` semantics) can never run again and keep their binding.

### D8 — Materialised prescriptions on rebound sessions

- `plan_fallback` rows: deleted; regenerated on demand by the existing fallback preparation.
- `analysis` rows (user-entered PWA loads): **rebased** in place when the slot lineage still exists,
  the DEFAULT exercise is unchanged and the set structure (count and role sequence) is unchanged —
  rep range/RIR snapshots refresh, loads and comments stay. Otherwise **discarded and reported**.
  `updated_at` is bumped so desktop and mobile optimistic checks detect the change.
- **Why:** pending analysis prescriptions are few (only the next target per track; 37 live rows), the
  rule is deterministic and testable, and it removes defect R6. Carrying loads by role rank is a
  possible later refinement (open question Q4).

### D9 — Replacement vs continuation of exercise identity

- **Rule:** an exercise *track* is the logical exercise unit of a workout (slot lineage). The *core
  exercise* is what is performed in it. Progression and load continuity require **both** the same
  track and the same core exercise.
  - Replacing the DEFAULT exercise of a slot (e.g. machine removed): same track (trace continuity,
    analytics show the switch), but progression restarts: no load defaults, basis or agent input are
    taken from the previous exercise. This matches today's mobile fallback query, which already
    requires `actual_exercise_id = variant.exercise_id` for the previous exposure.
  - Reordering within a workout: same track, same progression.
  - Removing a slot and adding another: a new track; the old track is retired.
- **Required fixes:** PWA defaults (`_next_prescription`) and load series (`_load_series`) must
  segment by core exercise (Audit R7).
- **Not built:** an explicit "continue progression from exercise X" mapping. It can be added later as
  metadata on Apply without schema changes to tracks.

### D10 — A distinct, atomic Apply operation

- **Why distinct:** the draft save is a frequent, partial editing action; Apply has execution side
  effects that must be explicit, atomic and serialised with workout starts. Keeping them separate is
  what makes `_delete_omitted` safe (D4).
- **Mechanics:** one transaction; per-run advisory lock `pg_advisory_xact_lock(674202114, run_id)`
  (already used by mobile start, Audit §3.4); optimistic checks on the draft `lock_version` and on the
  client's view of the current revision; idempotent replay (same draft already applied ⇒ 200
  `already_applied`); `dry_run=true` runs the identical transaction with forced rollback and returns
  the impact report (precedent: `preview_fallback_prescription`). Dry run is cheap because it is the
  same code path; the UI uses it for the confirmation dialog.

### D11 — Existing runs: eager conversion migration

- **Alternatives:** lazy conversion (dual read paths everywhere until each run is touched);
  new-runs-only (legacy runs keep R1–R5 forever and library plans stay undeletable);
  a Python one-off command (non-atomic with the schema change; requires a compatibility layer).
- **Decision:** a SQL migration converts every existing run in one transaction: create its run plan,
  copy **each** library revision the run uses (run 1 uses two) as applied revisions, create the
  working copy, remap all F2–F13 references via the copy id maps, and backfill lineage keys from track
  bindings (sessions/prescriptions by id first, positional fallback only for never-bound rows).
  Pre-flight audit queries must return zero anomalies; live data passes them today (Audit §4.1).
- **Why:** no dual-path code; library plans become independent immediately.

### D12 — Library promotion through the existing duplicate endpoint

- **Today:** `POST /api/plans/{id}/duplicate` copies the DRAFT into a new library plan (with image,
  fresh progression ids, `based_on_revision_id`).
- **Decision:** extend it with an optional body `{name?, source_revision_id?}`. On a run plan it
  produces a library plan from the working copy (default) or from a chosen applied revision
  (`source_revision_id` = current revision for "what the run executes now"). The new plan gets
  `scope='library'`, `source_plan_id = run plan id`, fresh progression ids, preserved lineage keys
  (harmless; they only matter inside one run's revision chain).
- **Why:** reuse, no new module; the new plan is fully independent and valid for new runs.

### D13 — Day count is fixed for a run plan (v1)

Microcycle dates, `microcycle_duration_days` and the generated `ends_on` all derive from the day
count. Changing it mid-run would re-date every future microcycle and the run end. v1 allows: reorder
days, turn rest days into training days and back, edit everything inside days. Adding/removing days
is disabled in run context and rejected by Apply (`day_count_changed`).

### D14 — Plan identity fields are not versioned

`name`, `description`, `accent` live on `plans.workout_plans` and the cover on `plans.plan_images`
(Audit §2.1); none of them has a revision. For a run plan:

- name/description/accent are written by `PUT /api/plans/{id}/draft` (`save_draft` updates
  `workout_plans` directly) and the cover by `PUT/DELETE /api/plans/{id}/image` — both take effect
  **immediately**, with no Apply;
- they are excluded from the definition fingerprint, so they never produce "unapplied changes", are
  not part of applied revisions, and Discard does not revert them;
- they never affect execution (the run bar and Run Plan tab simply show the current values).

Day `icon` is revision-scoped and follows Apply like any other definition change. UX copy must not
claim that "all changes" wait for Apply (`05` §4.2).

### D15 — Authorization

**Verified:** no authentication or ownership exists (Audit §1). The design enforces what can be
enforced server-side without identities:

- Scope guards: library list/delete/import reject run plans; run plans are deletable only with their
  run.
- Lifecycle guards: Apply only for `scheduled`/`active` runs; applied revisions immutable;
  run-plan id ↔ run consistency checked on every run-plan endpoint.
- Forward rule for when auth arrives: *access to a run plan = access to its owning run*; library
  plans and runs get an owner column. No frontend-only filtering is relied upon.

### D16 — Immutability of applied revisions is enforced by construction, not by triggers

- **Today:** no triggers exist on `plans.*` (verified in the live catalogue). Every UPDATE/DELETE of
  plan child rows is in `PlanRepository.save_draft` and its helpers (`plans/repository.py:758-1192`),
  scoped to the DRAFT located by `status = 'DRAFT'` and guarded by `_validate_nested_ids` (every
  submitted id must belong to that draft); `delete_plan` deletes whole plans. Execution and mobile code
  never write `plans.*`.
- **Alternatives:** BEFORE UPDATE/DELETE triggers on the six child tables rejecting rows of RELEASED
  revisions. Rejected: they must resolve the revision through up to five joins per row; they would
  block the legitimate `ON UPDATE CASCADE` from `core.progression_models.slug`
  (`exercise_variants.progression_model_slug`, migration 0003) and whole-table data migrations of the
  kind already shipped (0005, 0011); allowing whole-plan cascade deletes inside a delete trigger relies
  on fragile visibility rules.
- **Decision:** keep enforcement in the application, make the write surface explicit and tested:
  1. plans writes stay scoped to the DRAFT (unchanged code);
  2. new writers are limited to: `copy_revision_tree` (insert-only into an **empty** target revision —
     it raises otherwise), Discard (deletes children of the revision it has locked and verified as
     `DRAFT`), Apply (updates only the DRAFT revision row's `revision_no`/`lock_version`/
     `based_on_revision_id`), run deletion (whole run plan);
  3. a static allow-list test fails when any new `UPDATE plans.*`/`DELETE FROM plans.*` statement
     appears outside those functions (T-IMM-03);
  4. RESTRICT FKs keep blocking deletion of any row Execution references.
- **Actual guarantee:** no API operation can modify or delete a RELEASED revision or its child rows
  while its run exists. Not guaranteed: ad-hoc SQL, future code bypassing the allow-list, the
  catalogue slug cascade (a rename of a progression-model slug, an identity change rather than a plan
  change), and data migrations — any migration touching plan child rows must state how it treats
  RELEASED revisions (definition of done, `06`).
- **Tests:** T-IMM-01…04 (`07`).

---

## 8. Abstractions introduced (and why each is needed)

| Abstraction | Problem it solves | Could we avoid it? |
| --- | --- | --- |
| `workout_plans.scope` | Hide run plans from My Plans; guard library-only actions. | Only via a cross-schema anti-join in every plans query — more coupling. |
| `exec.plan_runs.run_plan_id` | Ownership; locate the run plan. | No: `initial_plan_revision_id` alone cannot express "the run's current plan". |
| `workout_plans.source_plan_id` | Show "copied from …" and promotion lineage. | Could derive from `based_on_revision_id`, but that dies with revision deletes and is revision-, not plan-, level. Cheap and nullable. |
| Lineage keys (2 plan columns, 2 exec columns) | Ordinal identity defects R3–R5. | No: progression ids are not slot identities; draft row ids change across revisions. |
| `plans.copy_revision_tree` | One copy implementation for runtime and migration. | Would require two implementations (Python + SQL). |
| Apply endpoint + reconciliation | Atomic, explicit execution side effects. | No. |

No new domain tables, state machines, scheduling or periodisation components are introduced (the
only new table is a temporary migration audit map outside the domain schemas, `02` §4.2).

---

## 9. Architecture diagram (runtime)

```text
 web-fe                                   be (FastAPI)                               PostgreSQL
 ───────                                  ────────────                               ──────────
 PlanCreatorView (run context)  ── GET/PUT /api/plans/{runPlanId}/draft ──► PlanService ──► plans.* (DRAFT)
                                ── POST .../draft/analysis|export ───────► PlanAnalysisService
 RunPlanView (Execution tab)    ── GET  /api/v1/exec/plan-runs/{id}/run-plan ──► RunPlanService ─┐
 Apply dialog                   ── POST /api/v1/exec/plan-runs/{id}/run-plan/apply (dry_run) ───┤
                                ── POST /api/v1/exec/plan-runs/{id}/run-plan/discard ───────────┤
 Promote dialog                 ── POST /api/plans/{runPlanId}/duplicate {name, source_revision_id}
                                                                         │                      │
                                                     plans.copy_revision_tree()   reconcile sessions/tracks/
                                                                                  prescriptions (exec.*)
 mobile-fe (unchanged API)      ── /api/v1/mobile/* ──► MobileExecutionRepository (lineage joins, bound revision)
```

`RunPlanService`/`RunPlanRepository` live in a new file pair under `modules/execution/`
(`run_plan.py`, `run_plan_repository.py`) to avoid edit conflicts with the large existing service and
repository files.

---

## 10. Intentional v1 limitations

| Limitation | Behaviour | Rationale | Workaround |
| --- | --- | --- | --- |
| Fixed microcycle duration | The run plan's day count is locked to `plan_runs.microcycle_duration_days`; PlanCreator hides add/duplicate/remove-day in run context and Apply rejects `day_count_changed` (D13). | Microcycle dates, `ends_on` (generated) and every session date derive from it. | Reorder days or toggle rest/training days; for a different cycle length, *Save as new plan* and start a new run. |
| Workout re-dating from the next microcycle | Moving a workout to another day re-dates pending `scheduled` sessions only in microcycles that start after today; the current microcycle keeps its dates; athlete cancellations are never re-dated (`03` §5.1). | Avoids creating instantly-missed sessions and same-day collisions inside the running week. | Train it on another day this week with the existing off-schedule start (`next_track_exposure`). |
| No scheduled future modifications | Apply always takes effect at the moment it runs; there are no effective-from/to dates or queued revisions (§5). | Execution owns calendar time; the brief excludes periodisation. | Keep edits in the working copy and press Apply on the day they should start. |
