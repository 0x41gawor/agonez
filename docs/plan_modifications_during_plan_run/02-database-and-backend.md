# 02 — Database and Backend Design

Implementation-oriented design for decisions D1–D16 (`01-domain-and-architecture.md`). SQL below is
conceptual: names and shapes are final; exact statements belong to the implementing task.

---

## 1. Schema changes

### 1.1 Migration `0018_run_plans_schema.sql` (backward compatible)

Safe to deploy before any runtime change: every new column has a default or is nullable, and old code
ignores it.

```sql
-- D1: scope of a plan row
CREATE TYPE plans.plan_scope AS ENUM ('library', 'run');

ALTER TABLE plans.workout_plans
    ADD COLUMN scope plans.plan_scope NOT NULL DEFAULT 'library',
    ADD COLUMN source_plan_id integer
        REFERENCES plans.workout_plans(id) ON DELETE SET NULL,
    ADD CONSTRAINT workout_plans_id_scope_unique UNIQUE (id, scope);   -- target of D2 composite FK

CREATE INDEX workout_plans_library_by_updated
    ON plans.workout_plans (updated_at DESC, id DESC) WHERE scope = 'library';

COMMENT ON COLUMN plans.workout_plans.scope IS
    'library: reusable plan listed in My Plans. run: plan owned by exactly one exec.plan_runs row (run_plan_id).';
COMMENT ON COLUMN plans.workout_plans.source_plan_id IS
    'Informational lineage: library plan a run plan was copied from, or run plan a library plan was promoted from.';

-- D5: lineage keys (existing rows receive fresh UUIDs; legacy runs are re-keyed by 0019)
ALTER TABLE plans.workout_unit_prescriptions
    ADD COLUMN lineage_key uuid NOT NULL DEFAULT gen_random_uuid();
ALTER TABLE plans.exercise_slots
    ADD COLUMN lineage_key uuid NOT NULL DEFAULT gen_random_uuid();

COMMENT ON COLUMN plans.workout_unit_prescriptions.lineage_key IS
    'Identity of the logical workout across revision copies. Preserved by plans.copy_revision_tree; never sent by clients.';
COMMENT ON COLUMN plans.exercise_slots.lineage_key IS
    'Identity of the logical exercise unit across revision copies. Preserved by plans.copy_revision_tree; never sent by clients.';

-- D2: ownership
ALTER TABLE exec.plan_runs
    ADD COLUMN run_plan_id integer,
    ADD COLUMN run_plan_scope plans.plan_scope NOT NULL DEFAULT 'run',
    ADD CONSTRAINT plan_runs_run_plan_scope_is_run CHECK (run_plan_scope = 'run'),
    ADD CONSTRAINT plan_runs_run_plan_unique UNIQUE (run_plan_id),
    ADD CONSTRAINT plan_runs_run_plan_fk
        FOREIGN KEY (run_plan_id, run_plan_scope)
        REFERENCES plans.workout_plans(id, scope) ON DELETE RESTRICT;

-- D5: track identity
ALTER TABLE exec.workout_unit_tracks  ADD COLUMN plan_lineage_key uuid;
ALTER TABLE exec.exercise_unit_tracks ADD COLUMN plan_lineage_key uuid;

-- D3: the single copy implementation (see §2)
CREATE FUNCTION plans.copy_revision_tree(...) ...;
```

### 1.2 Migration `0019_run_plans_convert_legacy_runs.sql` (lands on `master` after T2.2 and only after the T6.2 rehearsal)

Converts every run with `run_plan_id IS NULL` (§4) — runs created after T2.2 is deployed already own
a run plan and lineage-keyed tracks and are skipped — then tightens constraints:

```sql
ALTER TABLE exec.plan_runs ALTER COLUMN run_plan_id SET NOT NULL;
ALTER TABLE exec.workout_unit_tracks
    ALTER COLUMN plan_lineage_key SET NOT NULL,
    ADD CONSTRAINT workout_unit_tracks_run_lineage_unique UNIQUE (plan_run_id, plan_lineage_key);
ALTER TABLE exec.exercise_unit_tracks
    ALTER COLUMN plan_lineage_key SET NOT NULL,
    ADD CONSTRAINT exercise_unit_tracks_workout_lineage_unique
        UNIQUE (workout_unit_track_id, plan_lineage_key);

COMMENT ON COLUMN exec.workout_unit_tracks.logical_key IS
    'Label only. day:N for tracks created with the run, the lineage UUID text for tracks created by a run-plan Apply. Identity is plan_lineage_key.';
COMMENT ON COLUMN exec.exercise_unit_tracks.logical_key IS
    'Label only. slot:N for tracks created with the run, the lineage UUID text for tracks created by a run-plan Apply. Identity is plan_lineage_key.';
COMMENT ON COLUMN exec.microcycles.plan_revision_id IS
    'Run-plan revision in effect when the microcycle started. The governing revision of a session is the revision of its source_plan_day_id.';
```

Why `logical_key` is kept: its unique constraints and the views `exec.workout_session_calendar`,
`exec.exercise_unit_trace`, `exec.workout_unit_trace`, `exec.performed_load_time_series` expose it.
Tracks created at run creation keep the positional label (so the pre-refactor read code keeps
working while the release is rolled out commit by commit, `06` "Working on master"); tracks created
by Apply store `plan_lineage_key::text` so the label stays unique even when a removed workout's
position is reused.

### 1.3 Existing schema reused unchanged

| Element | Reused for |
| --- | --- |
| `plans.plan_revisions.status` DRAFT/RELEASED, `plan_revisions_one_draft_per_plan`, `lock_version`, `based_on_revision_id`, `released_at` | Working copy / applied revisions (D4). |
| `exec.plan_runs.initial_plan_revision_id` | Run-plan revision 1. |
| `exec.microcycles.plan_revision_id` | Revision in effect at microcycle start (D6). |
| `exec.plan_run_events` `plan_revision_changed` + from/to FKs + `metadata` | Modification history and impact audit. |
| Session/prescription source FKs (F3–F11) | Bind to applied-revision rows; RESTRICT now protects immutable rows (correct). |
| `exec.enforce_session_performance_consistency` | Defines executed vs unexecuted. |
| `pg_advisory_xact_lock(674202114, plan_run_id)` | Serialise Apply with mobile start. |
| `PlanRepository.save_draft` and every `/api/plans/{id}/draft*` endpoint | Editing the working copy. |

### 1.4 Immutability of RELEASED revisions (D16)

No trigger is added. The guarantee is application-level and is made explicit by a closed write
surface:

| Writer | Writes | Why it cannot touch a RELEASED revision |
| --- | --- | --- |
| `PlanRepository.save_draft` + `_upsert_*`, `_replace_target_muscles`, `_delete_omitted` (existing) | `workout_plans` identity fields; child rows of the DRAFT | Revision located by `status = 'DRAFT'` `FOR UPDATE`; `_validate_nested_ids` rejects any id not in that draft (422). |
| `PlanRepository.delete_plan` (existing) | whole plan | Library scope only (run plans → 409); a run plan is deleted only by run deletion. |
| `plans.copy_revision_tree` (new) | inserts into the target revision | Raises unless the target revision has no days, so it only populates a freshly created revision. |
| Discard (new) | deletes children of the draft, then copies | Locks the revision and verifies `status = 'DRAFT'` before `DELETE FROM plans.day_prescriptions WHERE revision_id = …`. |
| Apply (new) | `plan_revisions` row of the DRAFT (`revision_no`, `lock_version`, `based_on_revision_id`); inserts the new RELEASED revision | Never updates a RELEASED row; never changes `status` of an existing revision. |
| `delete_plan_run` (changed) | whole run plan | Deletes all revisions together with the run. |

Known non-application writers (documented exceptions, not prevented):
`exercise_variants_progression_model_fk … ON UPDATE CASCADE` from `core.progression_models(slug)`
rewrites `progression_model_slug` in every revision when a catalogue slug is renamed (verified in the
live catalogue); data migrations such as 0005 and 0011 updated all plan rows. Future data migrations
must state how they treat RELEASED revisions.

Considered and rejected: BEFORE UPDATE/DELETE triggers on the six child tables or on
`plan_revisions.status` (cost, conflict with the slug cascade and data migrations, fragile cascade
handling — `01` D16). Also not needed: relaxing `exec` → `plans` RESTRICT to NO ACTION, because
`delete_plan_run` already deletes in dependency order (§3.6).

Required tests: T-IMM-01…04 (`07` §2) — including a static allow-list test over `modules/` for
`UPDATE plans.` / `DELETE FROM plans.` statements.

---

## 2. Plan copying — `plans.copy_revision_tree`

Every child table has a natural key unique within its parent (`(revision_id, ordinal)`, `day_id`,
`(workout_unit_id, ordinal)`, `(slot_id, ordinal)`, `(exercise_variant_id, ordinal)`,
`(slot_id, muscle_id)`), so the copy is set-based and remaps ids by joining on that key.

```sql
CREATE FUNCTION plans.copy_revision_tree(
    p_source_revision_id integer,
    p_target_revision_id integer,
    p_regenerate_progression_ids boolean
) RETURNS TABLE (entity text, source_id integer, target_id integer)
LANGUAGE plpgsql AS $$
BEGIN
    -- target must be empty (defensive)
    IF EXISTS (SELECT 1 FROM plans.day_prescriptions WHERE revision_id = p_target_revision_id) THEN
        RAISE EXCEPTION 'target revision % is not empty', p_target_revision_id;
    END IF;

    RETURN QUERY
    WITH src_days AS (
        SELECT * FROM plans.day_prescriptions WHERE revision_id = p_source_revision_id
    ), ins_days AS (
        INSERT INTO plans.day_prescriptions (revision_id, ordinal, weekday, name, description, icon)
        SELECT p_target_revision_id, ordinal, weekday, name, description, icon FROM src_days
        RETURNING id, ordinal
    )
    SELECT 'day', s.id, i.id FROM src_days s JOIN ins_days i USING (ordinal);
    -- …same pattern for:
    --   workout_unit_prescriptions  (join: mapped day_id)        copies lineage_key
    --   exercise_slots              (join: mapped unit, ordinal) copies lineage_key, loading_*
    --   exercise_slot_target_muscles (join: mapped slot)
    --   exercise_variants           (join: mapped slot, ordinal)
    --        progression_id := CASE WHEN p_regenerate_progression_ids
    --                               THEN map(progression_id)   -- one new uuid per distinct old id
    --                               ELSE progression_id END
    --        load_step_kg copied raw (NOT the COALESCEd default)
    --   set_infra_prescriptions     (join: mapped variant, ordinal)
END;
$$;
```

Rules:

- Lineage keys are **always** copied.
- `regenerate_progression_ids`: `false` for library→run, draft→applied, applied→draft (Discard);
  `true` for library duplicate and run→library promotion (today's `_copy_draft_tree` behaviour,
  including preserved sharing between variants).
- Callers create the target revision row first and own the transaction.
- `PlanRepository._copy_draft_tree` is replaced by `SELECT * FROM plans.copy_revision_tree(...)`;
  the Python remapping loop is deleted. The returned map is used by the migration (§4) and by tests.

---

## 3. Backend changes

### 3.1 Plans module (`modules/plans/`)

| Change | Where | Detail |
| --- | --- | --- |
| Revision loader | `repository.py` | Split `_load_draft_rows(plan_id)` into `_find_draft_revision(plan_id)` + `load_revision_rows(connection, revision_id) -> DraftRows` (public; execution reuses it). Header query also returns `p.scope`, `p.source_plan_id` and `run.id AS plan_run_id` via `LEFT JOIN exec.plan_runs AS run ON run.run_plan_id = p.id` (read-only display join). |
| Copy | `repository.py` | `copy_revision(connection, source_revision_id, target_revision_id, *, regenerate_progression_ids)` → calls the SQL function, returns the map. `duplicate_plan` uses it. |
| Fingerprint | new `modules/plans/fingerprint.py` | `definition_fingerprint(rows: DraftRows) -> str`: sha256 of canonical JSON of the revision-scoped tree, ordered by ordinals, **excluding** row ids, revision ids, lock versions and plan-level identity fields; **including** lineage keys. Pure function; unit-tested. |
| Scope guards | `repository.py`, `service.py`, `exceptions.py`, `app.py` | `list_plans` filters `scope = 'library'`. `delete_plan` on a run plan raises `PlanScopeError` → HTTP 409 `{"detail": "Run plans are deleted together with their plan run"}`. `import_plan`/`create_plan` always create `library`. |
| Artifact fields | `schemas.py`, `service.assemble_draft` | `PlanDraftArtifact`, `PlanSummary`, `PlanDetail` gain `scope: "library" \| "run"`, `source_plan_id: int \| null`; `PlanDraftArtifact` and `PlanDetail` gain `plan_run_id: int \| null`. Additive. `PlanDraftUpdate` accepts and ignores these three fields (GET→PUT round trip, same pattern as `image_url`). |
| Duplicate / promotion | `router.py`, `service.py`, `repository.py`, `schemas.py` | `POST /api/plans/{id}/duplicate` accepts optional body `PlanDuplicateRequest {name?: str (1..200, non-blank), source_revision_id?: int}`. Source revision defaults to the DRAFT; when given it must belong to the plan (else 422). Result: `scope='library'`, `source_plan_id = id`, `based_on_revision_id = source revision`, image copied, `regenerate_progression_ids = true`. Name defaults to the existing `_duplicate_plan_name` rule. |
| Save draft | unchanged | Works for run plans. `_delete_omitted` is safe because no `exec` row references a DRAFT (I1/D4). The identity fields it writes (`name`, `description`, `accent` on `workout_plans`) take effect for the run plan immediately; they are not revision-scoped (D14). |

### 3.2 New run-plan service (`modules/execution/run_plan.py`, `modules/execution/run_plan_repository.py`)

New files avoid conflicts with `execution/service.py` (2180 lines) and `execution/repository.py`.

```python
class RunPlanRepository:
    async def create_run_plan(self, connection, *, source_revision_id: int) -> CreatedRunPlan
        # used inside ExecutionRepository.create_plan_run's transaction
    async def get_state(self, plan_run_id: int) -> RunPlanStateRows
    async def apply(self, plan_run_id: int, payload: RunPlanApply, *, as_of: date) -> ApplyOutcome
    async def discard(self, plan_run_id: int, payload: RunPlanDiscard) -> RunPlanStateRows

class RunPlanService:   # wired in app.py like ExecutionService, same injectable `today`
    async def get_state(...); async def apply(...); async def discard(...)
```

Routes are added to `execution/router.py` (three small handlers; see `04-api-contracts.md`).

### 3.3 Run creation (`ExecutionRepository.create_plan_run`, `execution/repository.py:258`)

Inside the existing transaction, before inserting the run:

1. Load the source revision; require its plan `scope = 'library'` → else 422
   `plan_revision_not_library`. Lock the source plan `FOR SHARE` (as `duplicate_plan` does) for a
   consistent snapshot.
2. `RunPlanRepository.create_run_plan`:
   - `INSERT workout_plans (scope='run', name, description, accent, source_plan_id = source plan)`;
     copy `plan_images` row.
   - `r1`: `INSERT plan_revisions (revision_no=1, status='RELEASED', based_on_revision_id=source
     revision, released_at=now())`; `copy_revision_tree(source → r1, false)`.
   - `r2`: `INSERT plan_revisions (revision_no=2, status='DRAFT', based_on_revision_id=r1)`;
     `copy_revision_tree(r1 → r2, false)`.
3. `_load_revision_tree(r1)` and continue with today's algorithm, except:
   - `initial_plan_revision_id = r1`, `run_plan_id = run plan`, microcycles `plan_revision_id = r1`.
   - Workout track: `plan_lineage_key = unit.lineage_key`, `logical_key = f"day:{day_ordinal}"`
     (unchanged label).
   - Exercise track: `plan_lineage_key = slot.lineage_key`, `logical_key = f"slot:{slot_ordinal}"`
     (unchanged label).
   - The run header and mobile context keep reading the plan through `initial_plan_revision_id`
     (which is now the run plan's r1); the new header fields arrive with T3.1.
   - Sessions bind to r1 rows (as today, just different ids).
4. `PlanRunCreate.plan_revision_id` keeps its name and meaning ("library revision to copy").
   `preview_plan_run` is unchanged.

### 3.4 Identity and binding refactor (Execution + Mobile reads)

| Location | Today | Target |
| --- | --- | --- |
| `execution/repository.py:_load_bundle` sessions query (`:485-509`) | `mc.plan_revision_id` | `source_day.revision_id AS plan_revision_id`, plus `revision.revision_no` of that revision. Run query adds `run_plan_id`, current revision id/no, source plan name. |
| `_load_plan_structures` input (`:642`) | microcycle revisions | distinct session-bound revisions ∪ microcycle revisions ∪ current revision. Load `lineage_key` on workouts and slots. |
| `execution/service.py:_target_structure` (`:1302`) | `day:N` / `slot:N` parsing; `microcycles[-1]` | Workout = row with `lineage_key = workout_track.plan_lineage_key` in the target's bound revision (or the **current revision** when no target); slot = row with `lineage_key = exercise_track.plan_lineage_key` under that workout. Return `None` (not raise) when absent; callers treat the track as **retired**. |
| `_display_name`, `_queue_exercise`, `_analysis_queue`, `_workout_trace`, `list_workout_traces`, `_timeline`, `_load_series` | `_logical_ordinal(...)` for ordering/labels | `day_ordinal`/`slot_ordinal` come from the current revision; retired tracks use their last bound revision; final fallback = track id order. Retired tracks are excluded from the analysis queue and flagged `retired: true` in traces. |
| `execution/repository.py:save_exercise_prescription` (`:1012-1022`) | slot by `slot:N` | slot by lineage under `target.source_plan_workout_unit_id`. |
| `mobile_execution/repository.py:_ensure_fallback_prescription` (`:617`, `:715`) | `source_revision != mc.plan_revision_id` ⇒ unavailable; `'slot:' || ordinal` join | Require session bound to the run's **current revision** (else `fallback_unavailable` with reason `session_not_current`); join `track.plan_lineage_key = slot.lineage_key`. |
| `mobile_execution` startability (`startable_session_ids`, context, start) | all sessions of a track | Only sessions bound to the current revision are candidates (sessions of retired workouts are historical). |
| `execution/repository.py:update_session_status` (`:1479`) | `cancelled → scheduled` allowed when date ≥ today | Additionally require the session to be bound to the run's current revision; otherwise 409 `session_workout_removed` (an athlete cancellation of a removed workout stays a cancellation). |
| `_exercise_revision_transitions` (`:1476`) | per consecutive microcycle | per consecutive *exposure* of the track whose bound revisions differ. |
| Timeline `day_columns` (`:1938`) | governing microcycle revision + `day:N` | current revision days; workout per day via lineage. `revision_changed_here` = microcycle contains a `plan_revision_changed` event. |

### 3.5 Exercise-identity fixes (D9)

- `_next_prescription` (`execution/service.py:950`): `defaults.from_previous_prescription` and
  `from_previous_performance` are `null` per set when the basis prescription's
  `prescribed_exercise_id` (or the basis performance's `actual_exercise_id`) differs from the target
  variant's `exercise_id`.
- `_load_series` (`:2050`): each point carries `exercise_id`/`exercise_name`; `first_value`,
  `latest_value` and `delta_pct` are computed over the trailing run of points with the latest point's
  exercise; the frontend draws a break where the exercise changes.
- Mobile fallback already requires `actual_exercise_id = variant.exercise_id` (no change).

### 3.6 Deletion behaviour

**Verified FK delete actions** (live catalogue, read-only, 2026-11-22; definitions in 0001/0016):

| FK | ON DELETE |
| --- | --- |
| `plan_revisions.plan_id → workout_plans` | CASCADE |
| `plan_revisions.based_on_revision_id → plan_revisions` | **SET NULL** |
| `plan_images.plan_id → workout_plans` | CASCADE |
| `day_prescriptions.revision_id → plan_revisions` and the child chain below it | CASCADE |
| every `exec.* → plans.*` FK (F1–F13) | RESTRICT |
| new `workout_plans.source_plan_id → workout_plans` (0018) | **SET NULL** |
| new `plan_runs (run_plan_id, run_plan_scope) → workout_plans (id, scope)` (0018) | RESTRICT |

No triggers exist on `plans.*`. `public.agonez_0019_reference_map` has plain integer columns and
**no FKs**, so it never blocks a delete.

Lineage chain created by this feature: library plan **L** → (copy) run plan **P** → (promote) library
plan **Q**. Links: `P.source_plan_id = L`, `P.r1.based_on_revision_id = L.draft`,
`Q.source_plan_id = P`, `Q.r1.based_on_revision_id = P.<source revision>`. Copies never reference
source child rows.

| Action | Behaviour |
| --- | --- |
| Delete library plan **L** | Cascades only L's own revisions/children/image. `P.source_plan_id` and `P.r1.based_on_revision_id` become NULL; the run is untouched (no `exec` reference to L after 0019). Succeeds even when runs were created from L. |
| Delete run (`ExecutionRepository.delete_plan_run`, `:897`) | Existing order (sessions, then run — cascading microcycles, tracks, events) followed by `DELETE FROM plans.workout_plans WHERE id = :run_plan_id AND scope = 'run'` in the same transaction. All `exec` references are gone by then, so RESTRICT FKs are satisfied. `Q.source_plan_id` and `Q.r1.based_on_revision_id` become NULL; **Q survives intact**. |
| Delete promoted plan **Q** | Ordinary library delete; P and its run are unaffected (nothing references Q). |
| Delete run plan **P** via `/api/plans/{id}` | 409 (`PlanScopeError`); the composite RESTRICT FK would also refuse it while the run exists. |
| Structural delete inside the working copy | Always succeeds (draft rows are unreferenced). |
| Applied revisions | Never deleted individually; only with their run. |

### 3.7 Authorization and guards (D15)

| Operation | Server-side rule |
| --- | --- |
| Read run-plan state / applied revision | Run must exist; revision must belong to `run.run_plan_id` (404 `plan_revision_not_found` otherwise — never leak other plans' revisions through a run URL). |
| Edit working copy (`PUT /api/plans/{runPlanId}/draft`) | Allowed for any run status (harmless until applied; supports edit-then-promote after a run ended). |
| Apply / Discard | Run status `scheduled` or `active` (409 `run_plan_not_modifiable`). Draft must belong to `run.run_plan_id`. |
| Promote | Allowed in any run status. |
| Library list/delete/import | Library scope only. |

There are no identities to authorise; when authentication arrives, run plans inherit the owning
run's access rule (no extra column).

---

## 4. Legacy run conversion (migration 0019)

### 4.1 Pre-flight audit (read-only; must return zero rows)

Ship as `be/scripts/run_plans_preflight.sql` and embed the same checks at the start of 0019 with
`RAISE EXCEPTION` on any hit:

1. A workout track whose sessions bind to two different workout units **of the same revision**.
2. A workout track's sessions disagree with its `day:N` key in a revision (positional fallback would
   be wrong).
3. An exercise track whose prescriptions point at two different slots of the same revision.
4. A unit/slot of a run's latest used revision that no track maps to (would need new tracks/sessions;
   handle by a follow-up Apply instead of in SQL).
5. Two tracks mapping to the same unit/slot within one revision.

The checks cover only runs with `run_plan_id IS NULL` (the set 0019 converts), so runs created by
T2.2 never block a deploy. Live data (2026-11-22) passes all five (Audit §4.1); so does the
2026-11-25 dump (T0.2).

### 4.2 Algorithm (per run with `run_plan_id IS NULL`, ordered by `id`)

```text
for run R:
  P := INSERT workout_plans(scope='run', name/description/accent of the library plan,
                            source_plan_id = library plan id);  copy plan_images
  S[] := distinct library revisions referenced by R through F2, F3 (via day), F6, F12, F13,
         ordered by the first microcycle ordinal that uses them      -- run 1: [6, 25]
  for i, S_i in S:
      A_i := INSERT plan_revisions(P, revision_no=i+1, 'RELEASED',
                                   based_on = (i=0 ? S_0 : A_{i-1}),
                                   released_at = first microcycle start using S_i)
      map_i := copy_revision_tree(S_i → A_i, regenerate=false)
      record map_i in public.agonez_0019_reference_map(plan_run_id, entity, library_id, run_plan_id)
  remap references of R using the maps (all filtered by plan_run_id):
      plan_runs.initial_plan_revision_id, microcycles.plan_revision_id,
      workout_sessions.source_plan_day_id / source_plan_workout_unit_id / fallback_source_…,
      workout_unit_prescriptions.source_plan_revision_id / source_plan_workout_unit_id,
      exercise_unit_prescriptions.source_plan_exercise_slot_id / source_plan_exercise_variant_id,
      set_prescriptions.source_plan_set_infra_id,
      exercise_unit_performances.actual_plan_exercise_variant_id,
      plan_run_events.from_plan_revision_id / to_plan_revision_id
  lineage backfill:
      for each workout track T of R: L_T := gen_random_uuid(); T.plan_lineage_key := L_T
          for each A_i: unit := the unit of A_i bound by T's sessions (by id)
                                 else the unit at day ordinal parsed from T.logical_key
                         unit.lineage_key := L_T
      for each exercise track E of R: L_E := gen_random_uuid(); E.plan_lineage_key := L_E
          for each A_i: slot := the slot of A_i referenced by E's prescriptions (by id)
                                 else slot at ordinal parsed from E.logical_key under T's unit in A_i
                         slot.lineage_key := L_E
  D := INSERT plan_revisions(P, revision_no=len(S)+1, 'DRAFT', based_on=A_last)
  copy_revision_tree(A_last → D, false)              -- after backfill, so lineage is inherited
  plan_runs.run_plan_id := P
then: tighten constraints (§1.2)
```

Notes:

- Copies reflect each library revision's **current** content — exactly what Execution reads today, so
  no displayed history changes at conversion time. Executed facts live in prescription/performance
  snapshots and are untouched.
- Runs sharing a library revision (3 & 14, 2 & 11) get independent copies.
- Library plans and their revisions are not modified (their rows simply stop being referenced). Plan
  6's seed-created RELEASED revision 25 stays in the library plan's revision list; it is harmless and
  may be cleaned up manually.
- `public.agonez_0019_reference_map` (outside the domain schemas, plain integer columns, **no FKs**)
  keeps the id maps for verification
  and for a manual reverse remap; drop it after one release cycle.

### 4.3 Post-conversion verification (automated by T2.1's T-MIG tests and T2.3's golden comparison)

- No `exec` column of F1–F13 references a row whose plan has `scope = 'library'`.
- Every run has `run_plan_id`; every run plan has exactly one DRAFT and ≥ 1 RELEASED revision.
- Every session's source day belongs to a RELEASED revision of its run plan.
- Every track has `plan_lineage_key`; each lineage key appears at most once per revision.
- For every run, `GET /overview`, `/analysis/queue`, `/timeline`, `/load-series` return the same
  payload as before conversion, ignoring ids and the new additive fields (golden comparison on a
  restored backup).

---

## 5. Concurrency and transaction boundaries

| Operation | Transaction | Locks (in this order) | Optimistic checks |
| --- | --- | --- | --- |
| Save working copy (existing) | 1 tx | `workout_plans` row → DRAFT revision row | `lock_version` |
| Apply | 1 tx, `SET CONSTRAINTS ALL DEFERRED` | advisory `(674202114, run_id)` → `plan_runs` row → `workout_plans` (run plan) → DRAFT revision → `workout_sessions` of the run `ORDER BY id` | draft `lock_version`; `expected_applied_revision_id` |
| Discard | 1 tx | advisory → `plan_runs` → `workout_plans` → DRAFT | draft `lock_version` |
| Mobile start (existing) | 1 tx | advisory → session(s) | `prescription_version` |
| PWA save (existing) | 1 tx | session row | basis + `expected_version` |
| Finalize / ops (existing) | 1 tx | performance, session | lease/seq |

- The shared lock prefix (advisory → run → plan → draft → sessions) prevents deadlocks; no existing
  path locks `exec` rows before `plans` rows.
- Apply vs start: serialised by the advisory lock. If start wins, the session is executed and
  untouched. If Apply wins, start sees a changed or missing prescription and returns the existing
  `prescription_changed`/`prescription_missing` errors; the app re-prepares (behaviour already
  handled since `ae1f273`).
- Apply vs PWA save: PWA waits on the session lock; afterwards its `expected_version`/basis no longer
  match → existing `version_conflict`/`stale_basis`.
- Apply vs `reconcile()` (marks missed): waits on session row locks; no conflict in outcome because
  Apply never changes statuses.
- Apply vs draft save from another tab: the draft row lock serialises them; the loser gets 409.

**Idempotency:** a replayed Apply whose `expected_applied_revision_id` is stale but whose draft
fingerprint equals the current revision's returns 200 with `already_applied: true` and the current
state (no new revision).

**Atomicity/rollback:** every failure (validation, conflict, constraint, trigger) aborts the whole
transaction; nothing partial is visible. `dry_run=true` uses `connection.transaction(force_rollback=True)`.

---

## 6. Compatibility with existing runs and clients

- Legacy runs are converted eagerly (§4); there is no compatibility layer afterwards.
- Desktop API: all changes are additive (`run.source_plan`, `run.current_revision`, `retired`,
  per-point `exercise_id`), except that `day_ordinal`/`slot_ordinal` now report **current** positions
  instead of creation-time positions (identical until a modification is applied).
  New error on an existing endpoint: un-cancelling a cancellation whose workout was removed returns
  409 `session_workout_removed`.
- Mobile API: unchanged shapes. Behavioural changes only after an Apply: prescriptions of pending
  sessions may change or disappear (existing error paths), sessions of removed workouts stop being
  startable, new workouts appear.
- `migrations/seeds/0001_execution_demo.sql` binds a run directly to library revisions and must not be
  run after 0019 (add a guard or retire it — open question Q5). `live_*_scenarios.py` scripts that
  look up the demo run by name still work on a converted backup.

---

## 7. Rollback considerations

Work lands on `master` in an order where every commit is deployable (`06` "Working on master").
Rollback means redeploying an earlier `master` commit; the table says how far back that is safe.

| Step on `master` | Contents | Safe code rollback |
| --- | --- | --- |
| A | 0018, plans refactor (T1.1, T1.2) | Any earlier commit: 0018 is additive; old code ignores the columns; lineage defaults are harmless. |
| B1 | T2.2 run creation with run plans | Any earlier commit: runs created by T2.2 are ordinary runs to the old code (positional labels, ordinals preserved). |
| B2 | T2.1 migration 0019 | Back to B1 at most: earlier `create_plan_run` violates `run_plan_id NOT NULL`. Take `db_backup.sh` right before the first deploy that contains 0019; T6.2 rehearses it. Converted runs stay readable by B1 code (positional labels, `microcycles.plan_revision_id` remapped). |
| B3 | T3.1 identity refactor | Back to B2, as long as no Apply has run (Apply is only reachable after C). |
| C | T3.2–T3.5 (endpoints dormant until the UI flag is on) | Back to B3 at most once an Apply has created tracks with UUID labels, which pre-T3.1 code cannot parse. |
| D | Frontend behind `RUN_PLAN_UI_ENABLED` | Flip the constant back to `false`. |
