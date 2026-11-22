# 00 — Current-State Audit

Audit date: 2026-11-22. Repository head: `f5b1960`. Schema head: migration `0017_day_icon_rest_variants.sql`.

Evidence labels:

- **VERIFIED (code)** — read directly in the current source or migrations.
- **VERIFIED (data)** — confirmed with read-only queries against the live `agonez-db` container
  (`default_transaction_read_only=on`; aggregate queries only).
- **VERIFIED (tests)** — confirmed by running the existing suites (backend `pytest`: 162 passed;
  web `vitest`: 166 passed).
- **INFERRED** — follows from verified facts but was not reproduced end to end.
- **ASSUMPTION** — not settled by the repository.

---

## 1. System shape (relevant slice)

| Layer | Location | Notes |
| --- | --- | --- |
| API | `be/src/agonez_api/app.py` | FastAPI; one `psycopg` async pool (`autocommit=True`, `dict_row`); repositories open explicit transactions. |
| Plans module | `be/src/agonez_api/modules/plans/` | `router.py` (`/api/plans`), `service.py`, `repository.py` (all SQL), `schemas.py`, `analysis/` (request-time analysis), `images.py`. |
| Desktop Execution | `be/src/agonez_api/modules/execution/` | `router.py` (`/api/v1/exec`), `service.py` (read models, 2180 lines), `repository.py` (writes + bulk bundle load), `domain.py` (`resolve_next`), `progression.py`. |
| Mobile Execution | `be/src/agonez_api/modules/mobile_execution/` | `/api/v1/mobile`; offline-first start/ops/finalize; fallback prescription materialisation. |
| Migrations | `be/src/agonez_api/migrations/versions/*.sql` + `runner.py` | Plain SQL files applied in filename order, one transaction each, checksum-locked. No Python migrations. |
| Web FE | `web-fe/src/` | Vue 3 + Pinia + vue-router + vue-i18n (11 locales). PlanCreator at `/plans/:planId`; Execution at `/execution/runs/:runId/*`. |
| Mobile FE | `mobile-fe/` (Flutter) | Consumes `/api/v1/mobile`. Out of scope except for compatibility. |

**VERIFIED (code):** there is no authentication or ownership anywhere. `app.py` describes the API as
"Authentication and ownership are intentionally deferred"; mobile `X-Agonez-Device-Id` is a write
lease, not an identity.

---

## 2. Plans domain

### 2.1 Tables (migration `0001` + later additions)

```
plans.workout_plans (id, name, description, accent, created_at, updated_at)
  └─ plans.plan_revisions (id, plan_id, revision_no, status DRAFT|RELEASED|ARCHIVED,
                           based_on_revision_id, lock_version, snapshot jsonb, released_at)
       └─ plans.day_prescriptions (id, revision_id, ordinal, weekday, name, description, icon)
            └─ plans.workout_unit_prescriptions (id, day_id UNIQUE, name, description,
                                                 warmup_notes, stretch_notes)        -- 0..1 per day
                 └─ plans.exercise_slots (id, workout_unit_id, ordinal, name, description, goal,
                                          role, volume_axis, loading_mode, loading_cycle)
                      ├─ plans.exercise_slot_target_muscles (slot_id, muscle_id)
                      └─ plans.exercise_variants (id, slot_id, ordinal, variant_type DEFAULT|FALLBACK,
                                                  exercise_id, progression_model_slug, progression_id,
                                                  load_step_kg, active_working_set_min/max)
                           └─ plans.set_infra_prescriptions (id, exercise_variant_id, ordinal,
                                 rep_min, rep_max, rep_range_semantics, rir, role, load_spec,
                                 min_volume_level, loading_mode, loading_cycle)
plans.plan_images (plan_id PK → workout_plans ON DELETE CASCADE, bytes)          -- 0016
```

- All child FKs inside `plans.*` are `ON DELETE CASCADE`. Ordinal uniques are
  `DEFERRABLE INITIALLY DEFERRED`; `workout_unit_prescriptions_day_unique` is also deferrable.
- `plan_revisions_one_draft_per_plan` — partial unique index: at most one `DRAFT` per plan.
- A "workout unit" is 1:1 with a day; a day without a workout unit is a rest day. "Adding a workout
  unit" in PlanCreator means giving a rest day a workout (`DayEditor.vue` `addWorkout`) or adding a
  day; "removing" means `workout_unit = null` (`DayEditor.vue:126`) or removing the day.
- `exercise_variants.progression_id` (0005) is the progression-loop identity; it is intentionally
  non-unique (several units may share a loop). It is variant-level, not slot-level.
- `min_volume_level`, `active_working_set_min/max`, slot/set `loading_cycle` exist in the plan model.
  **VERIFIED (code):** none of them is read by `modules/execution` or `modules/mobile_execution`
  (grep). They are consumed by plan analysis only.
- Plan identity fields `name`, `description`, `accent` and the cover image live on
  `workout_plans`/`plan_images`, i.e. **they are not revision-scoped**. Day `icon` is revision-scoped.

### 2.2 Revision lifecycle — what actually exists

**VERIFIED (code):**

- `PlanRepository.create_plan` (`plans/repository.py:56`), `import_plan` (`:78`) and
  `duplicate_plan` (`:237`) each create exactly one revision `revision_no = 1, status = 'DRAFT'`.
- There is **no code path that releases or archives a revision**. `RELEASED`/`ARCHIVED` appear only
  in `schemas.py` (`PlanRevisionStatus`) and as a read column. No endpoint creates revision 2.
- `plan_revisions.snapshot` is never written by application code (used only as a marker by the
  demo seed `migrations/seeds/0001_execution_demo.sql`).
- The single DRAFT is the plan. Every PlanCreator save mutates it in place.

**VERIFIED (data):** 10 revisions exist: 9 `DRAFT` + 1 `RELEASED` (revision 25 of plan 6, created by
the demo seed, `based_on_revision_id = 6`). Plan 6's DRAFT is revision **1**, i.e. the editable
draft is *older* than the released revision.

### 2.3 Draft save (`PUT /api/plans/{plan_id}/draft`)

`PlanRepository.save_draft` (`plans/repository.py:685-824`), one transaction:

1. `SET CONSTRAINTS ALL DEFERRED`; `SELECT … FROM plans.workout_plans … FOR UPDATE`; lock the DRAFT
   revision `FOR UPDATE`.
2. `_validate_draft_identity` (`:827`) — payload `id`, `revision_id`, `revision_no` must match.
3. Optimistic concurrency on `lock_version` → `PlanConflictError` → HTTP 409
   (`app.py` handler, body carries `submitted_lock_version`/`current_lock_version`).
4. `_validate_nested_ids` (`:838`) — every submitted nested id must already belong to this draft.
5. Updates `workout_plans` name/description/accent directly (not versioned).
6. Flips **all** existing variants to `FALLBACK`, then upserts days → workout unit → slots → target
   muscles → variants → sets (`_upsert_*`, `:959-1192`). Upserts may **reparent** rows (e.g. a slot
   moved to another workout keeps its id).
7. `_delete_omitted` (`:937-957`) — hard `DELETE` of every existing set/variant/slot/unit/day whose
   id was not submitted.
8. `lock_version = lock_version + 1`.

Frontend: explicit save only (button / Ctrl+S) — `web-fe/src/composables/usePlanDraft.ts`; no
autosave. Dirty tracking compares serialised `toPlanDraftUpdate` against a baseline.

### 2.4 Copy / duplicate / import / export

- `_copy_draft_tree` (`plans/repository.py:311-459`) copies a full `DraftRows` tree into a new
  revision with id remapping. It **regenerates `progression_id`s** but keeps sharing structure
  (`progression_ids.setdefault`). Used only by `duplicate_plan`, which also copies `plan_images`
  and sets `based_on_revision_id` to the source revision.
- `import_plan` builds a draft from the AI interchange JSON (`AGONEZ_PLAN_JSON_SPEC.md`).
- `export_draft` (`plans/analysis/service.py`) serialises the draft to the same JSON format.
- `_load_draft_rows` (`:1194-1317`) loads a tree **only by "the DRAFT of plan X"**; there is no loader
  by revision id in the plans module. (Execution has its own `_load_revision_tree`, see §3.)

### 2.5 Analysis

`POST /api/plans/{id}/draft/analysis` → `PlanAnalysisService.analyze_draft` →
`PlanRepository.get_analysis_source` (REPEATABLE READ, read-only) → always analyses the DRAFT of the
plan id. Frontend `usePlanAnalysis` passes the persisted `lock_version` and marks results stale on
mismatch. Keyed purely by `plan_id` — reusable for any plan row.

### 2.6 Deletion

`DELETE /api/plans/{id}` → `PlanRepository.delete_plan` (`:546`) — plain `DELETE FROM
plans.workout_plans`. **VERIFIED (code):** no handler for `psycopg.errors.ForeignKeyViolation` exists
in `app.py`, so deleting a plan any run was created from raises an FK violation from
`exec.plan_runs.initial_plan_revision_id` (RESTRICT) and surfaces as **HTTP 500**.

---

## 3. Execution domain

### 3.1 Tables (migration `0006` + 0007/0009/0010/0012/0013/0014/0015)

```
exec.plan_runs (initial_plan_revision_id → plans.plan_revisions RESTRICT, starts_on,
                microcycle_count, microcycle_duration_days  -- snapshot of day count,
                ends_on GENERATED, status scheduled|active|cancelled|completed)
  ├─ exec.microcycles (ordinal, starts_on, ends_on, plan_revision_id → plans.plan_revisions RESTRICT,
  │                    classification normal|deload|reload)
  ├─ exec.workout_unit_tracks (logical_key 'day:N', name, description)     UNIQUE(plan_run_id, logical_key)
  │    └─ exec.exercise_unit_tracks (logical_key 'slot:N', name, source_progression_id)
  │                                                       UNIQUE(workout_unit_track_id, logical_key)
  │         └─ exec.exercise_setup_notes (exercise_id, note_text, rev)          -- 0015
  ├─ exec.workout_sessions (microcycle_id, workout_unit_track_id,
  │       source_plan_day_id → plans.day_prescriptions RESTRICT,
  │       source_plan_workout_unit_id → plans.workout_unit_prescriptions RESTRICT,
  │       fallback_source_plan_workout_unit_id → plans.workout_unit_prescriptions RESTRICT,
  │       scheduled_date, status scheduled|in_progress|completed|cancelled|missed, start_mode, …)
  │    └─ exec.workout_unit_prescriptions (UNIQUE session; source_plan_revision_id RESTRICT,
  │         source_plan_workout_unit_id RESTRICT, name/description/warmup/stretch snapshots)
  │         ├─ exec.exercise_unit_prescriptions (exercise_unit_track_id, ordinal,
  │         │     source_plan_exercise_slot_id RESTRICT, source_plan_exercise_variant_id RESTRICT,
  │         │     source_progression_id, prescribed_exercise_id, slot/role/model/load-step snapshots,
  │         │     generation_source analysis|plan_fallback, previous_exercise_performance_id)
  │         │    └─ exec.set_prescriptions (ordinal, source_plan_set_infra_id RESTRICT,
  │         │          set_role_snapshot, rep_min, rep_max, target_rir, prescribed_load_kg, load_source)
  │         └─ exec.workout_unit_performances (draft|finalized, mobile lease/seq columns)
  │              └─ exec.exercise_unit_performances (execution_mode as_prescribed|substituted|skipped|
  │                    additional|not_performed, actual_exercise_id,
  │                    actual_plan_exercise_variant_id → plans.exercise_variants RESTRICT, performed_ordinal)
  │                   └─ exec.set_performances (prescribed_set_id nullable = additional set, …)
  └─ exec.plan_run_events (event_type incl. plan_revision_changed,
                           from/to_plan_revision_id → plans.plan_revisions RESTRICT, metadata jsonb)
```

Deferred constraint trigger `exec.enforce_session_performance_consistency` (0006) guarantees:
`completed ⇔ finalized performance`, `in_progress ⇔ draft performance`,
`scheduled|cancelled|missed ⇒ no performance`. Partial unique index
`workout_sessions_one_in_progress_per_run` (0009).

### 3.2 Run creation — `POST /api/v1/exec/plan-runs`

`ExecutionRepository.create_plan_run` (`execution/repository.py:258-435`), one transaction:

1. `_load_revision_tree(payload.plan_revision_id)` (`:138`) — any revision id is accepted, DRAFT
   included. `microcycle_duration_days = len(days)`.
2. Insert run with `initial_plan_revision_id = payload.plan_revision_id` (the **library** revision).
3. Insert `microcycle_count` microcycles, each `plan_revision_id = payload.plan_revision_id`.
4. One `workout_unit_track` per workout unit, `logical_key = f"day:{day_ordinal}"` (`:344`).
5. One `exercise_unit_track` per slot **that has a DEFAULT variant**, `logical_key =
   f"slot:{slot_ordinal}"` (`:368`), `source_progression_id = variant.progression_id`. Slots without
   a DEFAULT variant get no track.
6. Seed empty `exercise_setup_notes` per (track, every variant exercise of the slot).
7. Insert **all** sessions upfront: microcycles × workouts, `status = 'scheduled'`,
   `source_plan_day_id`/`source_plan_workout_unit_id` = library rows, date =
   `starts_on + (ordinal-1)·duration + day.ordinal` (`domain.day_for`).
8. Insert a `Run started` observation event.

No prescriptions are created at run creation. The source revision is **not frozen**: it stays DRAFT
and editable in My Plans. The frontend (`NewPlanRunView.vue`) shows a warning when a DRAFT revision is
chosen (`execution.newRun.draftWarning`) but allows it.

**VERIFIED (data):** 6 runs, all `active`; every `initial_plan_revision_id` is a `DRAFT`. Revisions
15 and 17 are each shared by two runs (runs 3 & 14; runs 2 & 11).

### 3.3 Prescription materialisation (snapshot timing)

Prescriptions are materialised **per session, lazily**, by two writers:

| Writer | Code | When | Source |
| --- | --- | --- | --- |
| Desktop Post-Workout-Analysis (PWA) | `ExecutionRepository.save_exercise_prescription` (`execution/repository.py:939-1279`) | User saves loads for the **next** target exposure of an exercise track (`resolve_next`); session must be `scheduled`/`missed`. | Live plan rows located by `track.logical_key` → `slot:N` ordinal inside `target.source_plan_workout_unit_id` (`:1012-1022`). `generation_source = 'analysis'`. Set ordinals must exactly equal current plan set count (`set_count_mismatch`). |
| Mobile fallback preparation | `MobileExecutionRepository._ensure_fallback_prescription` (`mobile_execution/repository.py:587-1017`) | `POST /api/v1/mobile/sessions/{id}/prescription/fallback` (and its `GET` preview) before start. | Live plan rows of `session.source_plan_workout_unit_id`; exercise track found by `track.logical_key = 'slot:' || slot.ordinal` (`:715`). Loads by progression agent (`progression.py`, `RepeatLastExposureAgent`). `generation_source = 'plan_fallback'`. |

Snapshot mutability **VERIFIED (code):**

- `plan_fallback` rows of a pending session are **re-synchronised to the live plan** on every
  preparation (stale fallback rows deleted, snapshots updated, set rows rebuilt if structure changed).
- `analysis` rows are **never** re-synchronised (`:823` `continue`).
- Workout-level prose snapshots are refreshed silently without bumping `updated_at` (`:660-700`).
- Once a session is `in_progress`, nothing re-reads the plan for its prescription — except the
  substitution alternatives list (`:481-499`) and `_substitute_exercise` (`:2207`), which read live
  `plans.exercise_variants` by `source_plan_exercise_slot_id`.

### 3.4 Start, performance, finalisation

- `start_workout` (`mobile_execution/repository.py:1403-1639`): takes
  `pg_advisory_xact_lock(674202114, plan_run_id)` (`:1435`) — a **per-run serialisation lock** —,
  checks startability (`startable_session_ids`, `:81`), `prescription_version` (hash of the
  prescription rows, `:2953`), and **completeness against the live plan**
  (`expected_plan_structure_sql`, `:43`: slot count and DEFAULT-variant set count of
  `source_plan_workout_unit_id`) → `prescription_incomplete` if they differ (`:1544`).
- Session overrides recorded **in performance rows only** (mobile ops): `substitute_exercise`
  (plan variant or Atlas), `skip_exercise`, `add_unplanned_exercise`, additional/skipped sets,
  `reorder_exercises` (`performed_ordinal`), comments, setup notes. Desktop overrides: PWA loads and
  comments on the next prescription; `PATCH …/sessions/{id}` status (`scheduled↔cancelled`,
  `→missed`).
- `finalize_workout` (`:2526`) finalises the performance and sets the session `completed`.
- `reconcile()` (`execution/repository.py:70`, mobile twin `:173`) lazily marks past `scheduled`
  sessions without performance as `missed` and scheduled runs as `active` on each read.

### 3.5 Reads: live plan vs snapshot

**VERIFIED (code):** `_load_bundle` (`execution/repository.py:441-680`) loads plan structures **live**
for every `microcycles.plan_revision_id` (`_load_plan_structures`, `:682`). The service then resolves
structure **positionally**:

- `_target_structure` (`execution/service.py:1302-1379`): with a target session, uses the
  microcycle's revision and the session's `source_day.ordinal`; without one, uses
  `bundle.microcycles[-1]` and parses `day:N` from the workout track. The slot is always found by
  `slot:N` ordinal. Missing slot ⇒ `not_found("exercise_trace_not_found")`.
- `_logical_ordinal` parsing occurs at 12 call sites in `execution/service.py` (`:347, :814, :899,
  :1198, :1321, :1330, :1538, :1713, :1754, :1804, :1947`) plus `execution/repository.py:1821` and
  the SQL join at `mobile_execution/repository.py:715`.
- `_exercise_revision_transitions` (`:1476`) and the timeline (`:1938`) assume **one revision per
  microcycle**.

What uses snapshots: executed prescriptions (`exec.*_prescriptions` snapshot columns), performances,
the views `exercise_unit_trace`, `performed_load_time_series`. What uses live plan rows: structure
lookups above, plan sets shown next to history in exercise traces, `_display_name`, mobile
completeness checks, fallback generation, substitution alternatives.

### 3.6 Existing (unused) revision-transition design

`exec.microcycles.plan_revision_id`, `plan_run_events.plan_revision_changed` (CHECK requiring distinct
from/to revisions) and `__docs__/execution/repeatable-unit-identity.md` describe an intended model:
immutable revisions with new child ids, stable run-scoped tracks, "apply a plan revision only to
future microcycles/sessions and append a revision-change event". **VERIFIED (code):** no application
code writes a second `microcycles.plan_revision_id` or a `plan_revision_changed` event.
**VERIFIED (data):** run 1 (the demo seed) uses revisions 6 (microcycles 1–3) and 25 (4–8); its
workout tracks map to two source workout units each; one `plan_revision_changed` event exists.

---

## 4. Cross-schema foreign-key inventory (`exec.*` → `plans.*`)

Every one of these is `ON DELETE RESTRICT` (no `ON UPDATE` action). Lifecycle of every referenced
row today: **mutable DRAFT rows of a library plan**, editable and deletable from My Plans.

| # | Referencing column | Referenced | Written by | Risk after a structural edit of the library plan |
| --- | --- | --- | --- | --- |
| F1 | `plan_runs.initial_plan_revision_id` | `plan_revisions` | run creation | Blocks deleting the library plan (HTTP 500). |
| F2 | `microcycles.plan_revision_id` | `plan_revisions` | run creation | Same; also drives live structure reads. |
| F3 | `workout_sessions.source_plan_day_id` | `day_prescriptions` | run creation | Removing a training day ⇒ save fails (500). Removing a rest day succeeds but silently breaks the run's day-count snapshot. Reordering a day silently changes `day_ordinal` seen by history. |
| F4 | `workout_sessions.source_plan_workout_unit_id` | `workout_unit_prescriptions` | run creation | Making a training day a rest day ⇒ save fails (500). Content edits change what *all* sessions (incl. completed) display. |
| F5 | `workout_sessions.fallback_source_plan_workout_unit_id` | `workout_unit_prescriptions` | nothing (hook) | — |
| F6 | `workout_unit_prescriptions.source_plan_revision_id` | `plan_revisions` | PWA, fallback | Blocks plan deletion. |
| F7 | `workout_unit_prescriptions.source_plan_workout_unit_id` | `workout_unit_prescriptions` | PWA, fallback | Removing the workout ⇒ save fails. |
| F8 | `exercise_unit_prescriptions.source_plan_exercise_slot_id` | `exercise_slots` | PWA, fallback | Removing a prescribed slot ⇒ save fails. |
| F9 | `exercise_unit_prescriptions.source_plan_exercise_variant_id` | `exercise_variants` | PWA, fallback | Removing/replacing-by-delete a prescribed variant ⇒ save fails. |
| F10 | `set_prescriptions.source_plan_set_infra_id` | `set_infra_prescriptions` | PWA, fallback | **Removing a set that was ever prescribed ⇒ save fails.** |
| F11 | `exercise_unit_performances.actual_plan_exercise_variant_id` | `exercise_variants` | mobile substitution | Removing a FALLBACK variant once used ⇒ save fails. |
| F12/F13 | `plan_run_events.from/to_plan_revision_id` | `plan_revisions` | (seed only) | Blocks plan deletion. |

Delete/update actions inside `plans.*` (**VERIFIED (data)**, `pg_constraint`, read-only):
`plan_revisions.plan_id → workout_plans` CASCADE; `plan_revisions.based_on_revision_id →
plan_revisions` **SET NULL** (0001); `plan_images.plan_id` CASCADE; the day → workout unit → slot →
variant → set chain CASCADE; `exercise_variants.progression_model_slug → core.progression_models(slug)`
**ON UPDATE CASCADE** (0003). No triggers exist on any `plans.*` table.

Other cross-schema references: `exec.*.prescribed_exercise_id`, `actual_exercise_id`,
`exercise_setup_notes.exercise_id` → `core.exercises` (RESTRICT) — unaffected by this feature.
Views `exec.workout_session_calendar`, `exec.microcycle_trace`, `exec.plan_run_event_history` join
`plans.plan_revisions`.

### 4.1 Ordinal-based identity

**VERIFIED (code):** Execution identity is positional. `workout_unit_tracks.logical_key = 'day:N'`
and `exercise_unit_tracks.logical_key = 'slot:N'` are assigned once at run creation and later
resolved against *whatever row currently has that ordinal*. Consequences:

- Reordering exercises in the library plan makes `slot:1` resolve to a different exercise. History is
  stored per track id (correct), but **future structure lookups and progression basis cross over to
  the exercise now occupying that position** — progression history is silently transferred between
  unrelated exercises.
- Reordering days makes `day:N` resolve to a different workout in `_target_structure(None)`
  (display names, plan sets) while sessions still point at the original unit by id.
- Inserting a slot shifts every later `slot:N`. Appending a slot creates a slot with no track:
  fallback preparation fails with `fallback_unavailable` (`:767`), and `start_workout` fails with
  `prescription_incomplete` because the expected slot count no longer matches. **All future sessions
  of that workout become unstartable on mobile.** (INFERRED from code; not reproduced.)
- Deleting a never-prescribed slot succeeds (no FK); afterwards `_queue_exercise` → `_display_name` →
  `_target_structure` raises `exercise_trace_not_found`, so `GET …/overview` and the analysis queue
  return **404 for the whole run**. (INFERRED from code; not reproduced.)
- Positional and logical identity are therefore **not interchangeable**; the slot ordinal is
  presentation order, not exercise-unit identity.

**VERIFIED (data):** today no drift exists — every workout track's sessions agree with `day:N`, no
exercise prescription points at a slot whose ordinal differs from its track key, no slot lacks a
track, and no track lacks a slot. 70 exercise tracks (runs 2, 3, 5, 11) were never prescribed (their identity
is recoverable only positionally).

---

## 5. Verification of the preliminary findings

| # | Hypothesis | Verdict | Corrections / missing detail |
| --- | --- | --- | --- |
| 1 | `plan_runs.initial_plan_revision_id` references `plans.plan_revisions` | **VERIFIED** | Also F2, F6, F12, F13 reference revisions; all RESTRICT. |
| 2 | Starting a run does not freeze/release the source revision | **VERIFIED** | Stronger: no code can release a revision at all. |
| 3 | Some runs reference revisions that remain DRAFT | **VERIFIED (data)** | *All* 6 runs do. Run 1 additionally references a RELEASED revision created by the demo seed; plan 6's editable DRAFT is the older revision. |
| 4 | Run creation produces microcycles, sessions, workout and exercise tracks | **VERIFIED** | Also setup notes and a `Run started` event. Exercise tracks only for slots with a DEFAULT variant. Sessions for **all** microcycles are created upfront. |
| 5 | Sessions reference plan entities via `source_plan_day_id`, `source_plan_workout_unit_id` | **VERIFIED** | Plus `fallback_source_plan_workout_unit_id` (unused hook). Sessions do not store a revision; it is implied by the source day and by the microcycle. |
| 6 | Tracks keyed by `day:N` / `slot:N` | **VERIFIED** | Keys are positional and resolved against live rows; migration `0015` also seeded setup notes positionally. |
| 7 | Prescriptions snapshotted at materialisation, not run creation | **VERIFIED** | Two writers (PWA, fallback). Fallback snapshots are re-synced to the live plan while pending; analysis snapshots are not. |
| 8 | Prescription entities | **VERIFIED** | `exec.workout_unit_prescriptions`, `exec.exercise_unit_prescriptions`, `exec.set_prescriptions`; plus `exercise_unit_performances.actual_plan_exercise_variant_id` (F11). |
| 9 | Structural deletion can fail because of RESTRICT | **VERIFIED** | Failure surfaces as HTTP 500 (no FK error handler). |
| 10 | Draft save deletes omitted entities, causing DB errors for active runs | **VERIFIED** | Removing any training day or workout unit of a plan with a run always fails (sessions reference every one of them). Removing never-prescribed slots *succeeds* and then breaks Execution reads (§4.1). Reparenting/reordering succeeds and silently changes history semantics. |

---

## 6. Verified risks and defects (current system)

| ID | Severity | Defect | Evidence |
| --- | --- | --- | --- |
| R1 | High | Editing a library plan mutates the definition of every run created from it, including completed sessions' displayed plan context; runs sharing a revision affect each other. | §3.2, §3.5, data: shared revisions 15, 17. |
| R2 | High | Structural deletes in PlanCreator fail with HTTP 500 for plans with runs; deleting such a plan fails with 500. | §2.3 step 7, §2.6, F1–F13. |
| R3 | High | Positional track identity silently re-targets progression and structure after reorder/insert. | §4.1. |
| R4 | High | Adding an exercise to a plan with an active run makes that workout unstartable on mobile. | §4.1 (`:715`, `:767`, `:1544`). |
| R5 | Medium | Deleting a never-prescribed slot makes the run overview 404. | §4.1 (`execution/service.py:1359-1363`). |
| R6 | Medium | A saved PWA (`analysis`) prescription whose set count no longer matches the plan blocks start (`prescription_incomplete`/`fallback_unavailable`). | `mobile_execution/repository.py:823`, `:1008`, `:1544`. |
| R7 | Low | Load series (`_load_series`, `service.py:2050`) and PWA defaults (`_next_prescription`, `:950`) assume one exercise per track; a plan-level exercise change would mix exercises in one series/default. Today it can only happen through library edits. | code. |
| R8 | Low | Microcycle-level revision assumption (`_exercise_revision_transitions`, timeline `revision_changed_here`) cannot express a mid-microcycle change. | code. |

---

## 7. Frontend architecture (web-fe)

| Concern | Files | Notes |
| --- | --- | --- |
| Routing | `src/router/index.ts` | `/plans` (list), `/plans/:planId` (PlanCreator), `/execution`, `/execution/runs/new`, `/execution/runs/:runId` with children overview/analysis/workout trace/timeline/loads. |
| My Plans | `src/views/PlanListView.vue` | `plansApi.list/duplicate/delete`; cards link to the editor. |
| PlanCreator shell | `src/views/PlanCreatorView.vue` (268 lines) | Toolbar (back → `/plans`, title, save state, Export JSON, Save), tabs PLAN / ANALYSIS / disabled "Modulation (later)", conflict banner, guidance coach. Takes only `planId`. |
| Editor state | `src/composables/usePlanDraft.ts`, `src/features/plans/editor.ts` | Load/save via `plansApi.draft/saveDraft`; `clientKey` per node; validation; 409 → conflict banner. |
| Editor components | `src/components/plans/PlanEditor.vue`, `DayEditor.vue`, `WorkoutUnitEditor.vue`, `ExerciseSlotEditor.vue`, `ExerciseVariantEditor.vue`, `SetPrescriptionEditor.vue`, `PlanCoverEditor.vue`, … | `PlanEditor` owns "Add day"; `DayEditor` emits duplicate/move/remove and toggles rest/workout. No read-only or locked mode exists. |
| Analysis | `src/components/plans/analysis/*`, `src/composables/usePlanAnalysis.ts` | Keyed by `planId` + `lock_version`. |
| Execution shell | `src/views/execution/ExecutionLayout.vue` | Run bar (name, "from Pxxx · plan", run selector, Manage, New run) + tabs Overview/Analysis/Timeline/Loads; provides `executionContextKey`. |
| Run creation | `src/views/execution/NewPlanRunView.vue` | Plan + revision selectors, DRAFT warning, preview. |
| API clients | `src/api/plans.ts`, `src/api/execution.ts`, `src/api/*-types.ts`, `src/api/client.ts` | `ApiError` carries status; exec error envelope parsed in client. |
| i18n | `src/i18n/locales/<11 locales>/{plans,execution,…}.ts` | `tests/i18n.test.ts` imports every locale's `plans`/`execution` bundles (parity check). |

PlanCreator is reusable for any plan row because every call is keyed by `planId`; the only
library-specific behaviour is navigation (`/plans` back link) and the absence of context.

---

## 8. Test coverage

| Area | Existing coverage | Gap |
| --- | --- | --- |
| Draft save | `tests/test_plan_repository.py` (fake connection: new ids, duplicate naming, copy remaps ids); `test_plan_schemas.py` | No DB-backed test of save with exec references, delete-omitted, reparenting. |
| Revisions | none | Nothing exercises RELEASED/ARCHIVED. |
| Run creation | `test_execution_service.py` (projection shape, validation) | No DB-backed creation test; no track/session/setup-note assertions. |
| Next-prescription resolver | `test_execution_domain.py` (pure) | Good unit coverage of `resolve_next`. |
| Materialisation | `test_mobile_execution.py::test_fallback_materialization_preserves_analysis_and_fills_missing_slots` (fake connection) | No DB-backed PWA/fallback tests; no plan-change scenarios. |
| Start/ops/finalize | `test_mobile_execution.py` (pure helpers, contract), `live_mobile_execution_api_scenarios.py` (destructive, disposable DB, manual) | Not in CI; no concurrency tests. |
| Structural editing vs execution | none | Entirely missing. |
| Migrations | `live_mobile_migration_checks.py` (manual catalogue checks) | No automated migration rehearsal on a backup. |
| Frontend | `tests/plan-editor.test.ts`, `use-plan-draft.test.ts`, `plan-creator-analysis-tab.test.ts`, `execution.test.ts`, … (166 tests) | No run-context tests (none exist yet). |

**Missing infrastructure that must precede lifecycle refactors:** a DB-backed pytest harness
(disposable PostgreSQL restored from the newest `agonez_db_backup_*.sql`, migrations applied,
per-test isolation) — see `06-implementation-roadmap.md` task T0.1.

---

## 9. Assumptions and unknowns

- **ASSUMPTION:** single-athlete usage per deployment; no concurrent multi-user editing beyond
  multiple tabs/devices of the same athlete.
- **ASSUMPTION:** the demo seed `migrations/seeds/0001_execution_demo.sql` and the destructive live
  scenario scripts are development aids, not production paths.
- **UNKNOWN:** whether mobile clients cache plan structure beyond the prescription payload (the
  Flutter app was not audited); the mobile API contract is unchanged by the design, so this does not
  block implementation.
