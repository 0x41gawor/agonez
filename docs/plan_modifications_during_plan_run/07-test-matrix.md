# 07 — Test Matrix

Test IDs are referenced by tasks in `06`. Layers:

- **Unit** — pure Python / Vue tests, run by default (`pytest`, `vitest`).
- **Integration** — `pytest -m integration` against a disposable PostgreSQL cloned from the restored
  backup (harness T0.1). Repositories and the ASGI app run for real.
- **Live** — destructive HTTP scripts against a disposable deployment (T6.1).

Common assertion helper: `snapshot_tables()` (T0.1) hashes ordered rows of the named tables so
"nothing changed" can be asserted precisely.

---

## 1. Unit tests (backend)

| ID | Subject | Assertion |
| --- | --- | --- |
| T-UNIT-COPY-01 | `copy_revision_tree` (integration-backed, owned by T1.1) | Per-entity row counts of target equal source (days, units, slots, targets, variants, sets). |
| T-UNIT-COPY-02 | same | Every copied child references copied parents only (no source ids leak). |
| T-UNIT-COPY-03 | same | `lineage_key` equal for units and slots. |
| T-UNIT-COPY-04 | same, `regenerate=false` | `progression_id` equal per variant. |
| T-UNIT-COPY-05 | same, `regenerate=true` | All ids new; variants that shared an id still share one; distinct ids stay distinct. |
| T-UNIT-COPY-06 | same | Raw `load_step_kg` NULL stays NULL; `icon`, `loading_mode/cycle`, `load_spec`, `min_volume_level`, `active_working_set_*` copied; non-empty target raises. |
| T-UNIT-FP-01 | `definition_fingerprint` | Same tree with different row ids ⇒ equal. |
| T-UNIT-FP-02 | same | Changing one set's `rep_max` ⇒ different. |
| T-UNIT-FP-03 | same | Changing a slot lineage key ⇒ different (delete + re-add is a change). |
| T-UNIT-FP-04 | same | Plan name/description/accent ignored. |
| T-UNIT-FP-05 | same | Reordering exercises (ordinal swap) ⇒ different. |
| T-UNIT-VAL-01…06 | `validate_executable` | One test per issue code (`03` §3), each with correct `path`, `day_ordinal`, `slot_ordinal`. |
| T-UNIT-PRX-01 | rebase decision function | Returns `None`/`slot_removed`/`exercise_changed`/`set_structure_changed` for the four cases; equal role lists of different rep ranges ⇒ compatible. |
| T-UNIT-DEF-01 | `_next_prescription` defaults | Basis exercise ≠ target exercise ⇒ both default arrays all `null`. |
| T-UNIT-LS-01 | `_load_series` | Points carry `exercise_id`; `delta_pct` uses the trailing segment of the latest exercise. |

## 2. Database integration tests

| ID | Scenario | Expected |
| --- | --- | --- |
| T-REG-01…06 | Characterisation of R1–R5 (T0.2) | xfail today; all pass after T2.2 (they edit the library plan). Lineage identity inside a run plan is covered by T-INT-ID. |
| T-PRE-01 | Preflight on restored backup | Zero rows for all five checks. |
| T-INT-RUN-01 | Create run | Run plan `scope='run'`, `source_plan_id` = library; r1 RELEASED, r2 DRAFT; both fingerprints equal to library draft. |
| T-INT-RUN-02 | Create run | Each workout/exercise track `plan_lineage_key` equals the r1 unit/slot lineage; one track per unit/slot with DEFAULT variant. |
| T-INT-RUN-03 | Create run | All sessions bound to r1 rows; microcycles reference r1; counts equal preview. |
| T-INT-RUN-04 | **Source isolation** | After creation, PUT library draft (rename exercise, change sets, delete a day): run plan fingerprints, run overview and next-prescription plan sets unchanged; the library save succeeds (no FK error). |
| T-INT-RUN-05 | **Source isolation (reverse)** | PUT run-plan draft + Apply: library draft fingerprint and `updated_at` unchanged. |
| T-INT-RUN-06 | **Run-to-run isolation** | Two runs from one library plan; modify + apply run A: run B fingerprints, sessions and prescriptions unchanged (`snapshot_tables` filtered by run B). |
| T-INT-RUN-07 | Delete run | Run plan, its revisions and children gone; library plan intact; promoted plans keep `source_plan_id = NULL`. |
| T-INT-RUN-08 | Create from run-plan revision | 422 `plan_revision_not_library`. |
| T-INT-ID-01 | Reordered slots (synthetic second revision) | Each exercise track resolves to the same exercise. |
| T-INT-ID-02 | Inserted slot at position 0 | Existing tracks keep their exercises; the new slot maps to no existing track. |
| T-INT-ID-03 | Track absent from current revision | Overview 200; trace `retired: true`; excluded from analysis queue. |
| T-INT-ID-04 | Session bound to old revision | Mobile fallback → 422 `fallback_unavailable` `reason=session_not_current`; not startable. |
| T-INT-ID-05 | PWA save | Slot found by lineage; prescription references the target revision's rows. |
| T-INT-ID-06 | Converted run 1 | Exercise transitions computed per exposure; no exceptions. |
| T-INT-ID-07 | Ordinals in payloads | `day_ordinal`/`slot_ordinal` reflect current revision positions. |
| T-INT-ID-08 | Grep guard | No `_logical_ordinal`, `'slot:' ||`, `'day:' ||` in `modules/` (static test). |
| T-INT-AP-01 | Apply content edit | Pending sessions rebound; executed/settled untouched (`snapshot_tables` on their rows). |
| T-INT-AP-02 | **Add sets** (2→3 working sets) | Pending sessions' plan sets = 3; completed sessions' `set_prescriptions` unchanged. |
| T-INT-AP-03 | **Remove sets** (3→2) | Same, reversed; old revision rows still exist (RESTRICT respected). |
| T-INT-AP-04 | **Exercise replacement** | Same exercise track; new DEFAULT exercise in pending prescriptions; setup note row created for the new exercise. |
| T-INT-AP-05 | Add exercise | New exercise track; setup notes seeded; pending sessions include it after fallback prepare. |
| T-INT-AP-06 | Remove exercise | Track retired; history (traces) still returns its past exposures. |
| T-INT-AP-07 | Reorder exercises | Tracks unchanged; pending prescription ordinals follow the new order. |
| T-INT-AP-08 | Add workout (rest→training) | New workout track; sessions for every microcycle date ≥ today; none in the past. |
| T-INT-AP-09 | Remove workout | Future `scheduled` sessions deleted; future athlete cancellations and past recoverable missed sessions kept with status, date and old binding (`sessions.retained`); completed kept. |
| T-INT-AP-10 | Move workout to another day (**v1 limitation: re-dating from the next microcycle**) | Future-microcycle `scheduled` sessions re-dated; current-microcycle dates unchanged; `cancelled` sessions never re-dated. |
| T-INT-AP-11 | **Mid-week apply** (`03` §8 example with frozen clock) | Exact outcome table of `03` §8. |
| T-INT-AP-12 | Microcycle revision update | Only microcycles with `starts_on > today` point to the new revision. |
| T-INT-AP-13 | Event and renumbering | One `plan_revision_changed` event with from/to and impact; draft `revision_no` = new + 1; draft `lock_version` + 1. |
| T-INT-AP-14 | Validation | Each `run_plan_not_executable` code returned through the API with paths. |
| T-INT-AP-15 | Unchanged / not modifiable | 422 `run_plan_unchanged`; completed run → 409 `run_plan_not_modifiable`. |
| T-INT-AP-16 | Settled sessions | Non-recoverable missed and past cancelled sessions keep binding and date. |
| T-INT-AP-17 | **Athlete cancellations** | (a) Future cancelled session of a surviving, moved and edited workout: status and date unchanged, content rebound; un-cancelling it yields a `scheduled` session that executes the current revision. (b) Future cancelled session of a removed workout: kept with old binding; `PATCH …/sessions/{id}` → `scheduled` returns 409 `session_workout_removed`. (c) Attendance after the date passes counts it as cancelled, as without the modification. |
| T-INT-RX-01 | Fallback rows on pending session | Deleted by Apply; regenerated by prepare with the new structure. |
| T-INT-RX-02 | Analysis rebase compatible (rep range change) | Loads/comments kept; rep/RIR snapshots updated; source ids point to new revision; `updated_at` bumped. |
| T-INT-RX-03 | Analysis + exercise replaced | Discarded; listed with reason `exercise_changed` and loads. |
| T-INT-RX-04 | Analysis + set count changed | Discarded `set_structure_changed`. |
| T-INT-RX-05 | Analysis + slot removed | Discarded `slot_removed`. |
| T-INT-RX-06 | Workout removed with saved analysis (future) | Session deleted; reported `workout_removed`. |
| T-INT-RX-07 | Workout prescription emptied | Deleted; no orphan `workout_unit_prescriptions`. |
| T-INT-RX-08 | Reorder with rebased rows | Two-phase ordinal update succeeds (no unique violation). |
| T-INT-RX-09 | Dry run | Same impact as real Apply; `snapshot_tables` of `plans.*` and `exec.*` unchanged. |
| T-INT-RX-10 | **Completed workout preservation** | Hash of the completed session's prescription and performance rows identical before/after three successive Applies. |
| T-INT-AN-01 | Replaced exercise defaults | `GET …/next` defaults `null`. |
| T-INT-AN-02 | Load series after replacement | Two segments; delta over the new exercise only. |
| T-INT-AN-03 | **Historical analytics** | Exercise trace of a past exposure shows its own revision's plan sets (old), while `next` shows the current ones. |
| T-INT-AN-04 | Timeline | Day columns from the current revision; `revision_changed_here` on the microcycle containing the Apply event. |
| T-INT-AN-05 | Attendance | Past `attendance` numbers identical before/after Apply. |
| T-INT-AN-06 | Substituted points | Load-series values for Atlas substitutions still `null` (no regression). |
| T-INT-AN-07 | Timeline date shared by a retained cancellation and another session | `days[].session` is the non-cancelled session. |
| T-INT-PR-01 | **Save Run Plan to My Plans** (applied revision) | New plan `scope='library'`, listed in `/api/plans`, fingerprint equals the revision (ignoring progression ids), progression ids fresh, image copied, `source_plan_id` = run plan. |
| T-INT-PR-02 | Promote working copy | Same with the draft as source. |
| T-INT-PR-03 | **Create another run from the promoted plan** | Succeeds; the new run's run plan is independent of both the promoted plan and the original run (modify + apply each; no cross effects). |
| T-INT-PR-04 | Foreign `source_revision_id` | 422. |
| T-INT-PR-05 | Empty body | Identical to today's duplicate behaviour (name "X copy"). |
| T-INT-PR-06 | Delete original run after promotion | Promoted plan intact; `source_plan_id` becomes NULL. |

### 2b. Immutability of applied revisions (D16)

| ID | Scenario | Expected |
| --- | --- | --- |
| T-IMM-01 | PUT `/api/plans/{runPlanId}/draft` carrying ids of rows that belong to a RELEASED revision (day, unit, slot, variant, set) | 422 `… does not belong to this draft`; `snapshot_tables` of the RELEASED revision unchanged. |
| T-IMM-02 | Lifecycle sweep: several saves, Applies, a Discard, a promotion, library edits and a library delete | Fingerprint and row hash of every RELEASED revision, captured right after its Apply, are unchanged at the end; no RELEASED revision changed `status`. |
| T-IMM-03 | **Static write allow-list** over `be/src/agonez_api/modules/**/*.py` | Every `UPDATE plans.<table>` / `DELETE FROM plans.<table>` (including the f-string in `_delete_omitted`) occurs only in allow-listed functions: `save_draft` helpers, `delete_plan`, Discard, Apply draft renumbering, `delete_plan_run`. A new occurrence fails the test. |
| T-IMM-04 | Delete a RELEASED child row that Execution references (raw SQL in a rolled-back transaction) | ForeignKeyViolation (RESTRICT). |

### 2c. Deletion and lineage (verified FK actions, `02` §3.6)

| ID | Scenario | Expected |
| --- | --- | --- |
| T-DEL-01 | Delete library plan L after a run was created from it | 204; run plan `source_plan_id` and r1 `based_on_revision_id` are NULL; run overview, sessions and run plan fingerprints unchanged. |
| T-DEL-02 | Delete the run | Run plan, its revisions, children and image gone; library plan untouched. |
| T-DEL-03 | Promote run plan P to Q, then delete the run | Q intact (fingerprint, image, listed in My Plans); `Q.source_plan_id` and `Q.r1.based_on_revision_id` NULL; Q usable for a new run. |
| T-DEL-04 | Delete Q, and separately delete L, after promotion | Each deletion succeeds; P and its run unaffected. |

## 3. API integration tests

| ID | Endpoint | Expected |
| --- | --- | --- |
| T-API-PLANS-01 | `GET /api/plans` | Excludes run plans. |
| T-API-PLANS-02 | `DELETE /api/plans/{runPlanId}` | 409 with detail. |
| T-API-PLANS-03 | `DELETE /api/plans/{libraryId}` with runs | 204 (was 500). |
| T-API-PLANS-04 | GET→PUT draft of a run plan | Round trip with `scope/source_plan_id/plan_run_id` accepted. |
| T-API-PLANS-05 | `POST /api/plans/{runPlanId}/draft/analysis`, `/export` | 200 (reuse proven). |
| T-API-RP-01 | `GET …/run-plan` fresh run | `has_unapplied_changes=false`, history = [r1 copied]. |
| T-API-RP-02 | after draft PUT | `true`. |
| T-API-RP-03 | after manual revert | `false`. |
| T-API-RP-04 | `GET …/run-plan/revisions/{id}` | 200 for own revisions incl. draft; 404 for other plans' revisions. |
| T-API-RP-05 | Discard | Fingerprint equality; lock bumped; draft ids changed. |
| T-API-RP-06 | Discard stale lock | 409 `draft_version_conflict`. |
| T-API-RP-07 | Discard ended run | 409 `run_plan_not_modifiable`. |
| T-API-RP-08 | OpenAPI | New routes, schemas and error responses present (`tests/test_openapi.py`). |
| T-API-AP-01 | Apply error envelope | Every `04` §1.3 code returns the exec envelope with documented details. |
| T-API-AP-02 | **v1 limitation: no scheduled modifications** — Apply body with an extra field such as `effective_from` | 422 `request_validation` (`extra=forbid`); no revision created. |
| T-API-PLANS-06 | Identity metadata on a run plan: PUT draft changing only `name`/`accent`, and PUT `/image` | Run plan and run bar show the new values immediately; `has_unapplied_changes` stays `false`; Discard does not revert them. |

## 4. Concurrency and failure tests

| ID | Scenario | Expected |
| --- | --- | --- |
| T-CONC-01 | **Two Applies in parallel** (same versions) | One new revision; the other gets `already_applied` (same draft) — never two revisions. |
| T-CONC-02 | Apply while a draft save commits | Apply 409 `draft_version_conflict` or runs after the save with the new lock; never applies a half-saved draft. |
| T-CONC-03 | Apply vs mobile start on the same pending session | Either: start first ⇒ session untouched by Apply; or Apply first ⇒ start returns `prescription_changed`/`prescription_missing`; re-prepare + start succeeds. |
| T-CONC-04 | Apply vs PWA save | PWA gets `version_conflict`/`stale_basis` after Apply. |
| T-CONC-05 | Stale client Apply | `run_plan_revision_conflict` with current revision details. |
| T-FAIL-01 | **Failed transaction rollback** — inject failure after the revision copy (e.g. monkeypatch the reconciliation step to raise) | No new revision, draft unchanged (revision_no, lock), sessions/prescriptions/events unchanged (`snapshot_tables`). |
| T-FAIL-02 | Constraint violation inside reconciliation (forced duplicate session) | Same as T-FAIL-01; HTTP 500; retry succeeds once the cause is removed. |
| T-FAIL-03 | Run creation failure after run-plan copy | No orphan run plan rows (single transaction). |
| T-FAIL-04 | Migration 0019 preflight hit (seeded anomaly) | Migration aborts; database identical to pre-migration state. |

## 4b. Mobile compatibility (integration, through `/api/v1/mobile`)

| ID | Scenario | Expected |
| --- | --- | --- |
| T-MOB-01 | `GET /api/v1/mobile/context` after Apply | Rebound pending sessions listed; readiness computed against the new structure; `prescription_version` changed for sessions whose prescriptions were rebased or cleared. |
| T-MOB-02 | Prepare fallback + start on a session with a rebased analysis prescription and a newly added slot | Complete prescription (analysis rows kept, new slot filled); start succeeds (regression for R6/R4). |
| T-MOB-03 | Workout in progress during Apply | Set ops, plan-variant substitution (alternatives list unchanged — old revision variants) and finalize succeed; the session completes on the old revision. |
| T-MOB-04 | Past recoverable missed session of a removed workout | Not startable (`start` → conflict); fallback prepare → 422 `fallback_unavailable` `reason=session_not_current`. |
| T-MOB-05 | Session of a newly added workout | Appears in context on its date; prepare + start + finalize succeed; setup notes available for its exercises. |

## 5. End-to-end scenarios (live script, T6.1)

| ID | Scenario |
| --- | --- |
| E2E-01 | Create library plan → start run → mobile: complete session 1 (prepare, start, ops, finalize). |
| E2E-02 | Edit run plan (replace an exercise, add a set, add a workout on a rest day, remove another workout, move a workout) → dry run → Apply with note → verify impact counts and that session 1's prescription/performance hash is unchanged. |
| E2E-03 | Mobile: next session prepares and starts with the new structure; replaced exercise has no load default; finalize. |
| E2E-04 | Library plan edited and then deleted → run unaffected; delete succeeds. |
| E2E-05 | Promote current run definition → create a second run from it → apply a change to the second run → first run unaffected. |
| E2E-06 | Delete the first run → its run plan removed; promoted plan remains. |

## 6. Migration tests (restored backup, T2.1/T2.3)

| ID | Assertion |
| --- | --- |
| T-MIG-01 | Every run has `run_plan_id`; every run plan has 1 DRAFT and ≥ 1 RELEASED. |
| T-MIG-02 | No F1–F13 column references a library-scope plan. |
| T-MIG-03 | Every session's source day belongs to a RELEASED revision of its run plan. |
| T-MIG-04 | Run 1: applied r1 copy of library rev 6, r2 copy of rev 25, draft r3; microcycles 1–3 → r1, 4–8 → r2; event from/to remapped. |
| T-MIG-05 | Runs sharing library revisions (3/14, 2/11) own distinct run plans. |
| T-MIG-06 | Every track has `plan_lineage_key`; lineage unique per revision; tracks map to their bound units/slots. |
| T-MIG-07 | Library plan fingerprints and `updated_at` unchanged; library plan 15 deletable afterwards. |
| T-MIG-08 | Row counts of sessions, prescriptions, performances, setup notes, events unchanged. |
| T-MIG-09 | `public.agonez_0019_reference_map` covers every remapped id. |
| T-MIG-11 | A run created by T2.2 code before 0019 is skipped by the conversion (row hashes unchanged); legacy tracks keep positional `logical_key` labels; pre-T3.1 read code returns 200 for every converted run. |
| T-MIG-10 | **Existing plan_run compatibility** — golden comparison (`06` T2.3): identical read models before/after conversion; after T3.1 only additive fields differ. |

## 6b. Release rehearsal checklists

Migration 0019 rehearsal (T6.2, gate before T2.1 + T2.3 merge into `master`) — uses only `master`
(including T2.2) plus the T2.1 + T2.3 branch; no T3.1, Apply, Discard, run-plan endpoints, promotion or
frontend:

| ID | Check |
| --- | --- |
| RB-01 | Fresh `db_backup.sh` dump restored into a scratch PostgreSQL 15 container. |
| RB-02 | `be/scripts/run_plans_preflight.sql` returns zero rows. |
| RB-03 | Migrations 0018 and 0019 apply; durations recorded. |
| RB-04 | T-MIG-01…10 (including the golden comparison) pass on the scratch database. |
| RB-05 | Run-creation smoke through the API: create a run from a library plan; edit and then delete that library plan; the run is unaffected (T-INT-RUN-04, T-DEL-01 checks). |
| RB-06 | `live_mobile_execution_api_scenarios.py` passes against the scratch API on converted runs. |
| RB-07 | Desktop read smoke: overview, analysis queue, timeline, load series return 200 for every converted run. |
| RB-08 | Rollback drill per `02` §7 (step B2: redeploy the pre-0019 `master` commit against the converted scratch database) executed and timed. |

Before enabling the UI (step #12 in `06`):

- T6.1: E2E-01…06 (§5) over HTTP against a disposable deployment of current `master`.
- RD-01: manual walkthrough of `05` §2–§7 (tab, editor run context, apply dialog, discard, promotion,
  ended run) in a local build with `RUN_PLAN_UI_ENABLED = true` against current `master`, plus the
  frontend suites.

## 7. Frontend tests (vitest)

| ID | Component | Assertion |
| --- | --- | --- |
| T-FE-API-01…03 | API client | URLs, bodies (`dry_run`, versions, note), error parsing of exec envelope. |
| T-FE-FLAG-01 | UI flag | With `RUN_PLAN_UI_ENABLED = false`: no Run plan tab, no run-plan routes, no `/plans/:id` redirect; with `true`: all present. |
| T-FE-RP-01 | Run Plan tab | Fresh state: no unapplied banner; ownership copy names the source plan. |
| T-FE-RP-02 | | Unapplied state: banner with Review & apply / Discard. |
| T-FE-RP-03 | | Source deleted copy. |
| T-FE-RP-04 | | Ended run: Apply/Discard hidden, ended banner. |
| T-FE-RP-05 | | Definition renders days, rest days, set summaries from a revision fixture. |
| T-FE-RP-06 | | Discard confirm → API call with lock → reload. |
| T-FE-RP-07 | | Tab dot shown when `has_unapplied_changes`. |
| T-FE-ED-01 | PlanCreator library context | Existing tests unchanged (no `runContext`). |
| T-FE-ED-02 | run context | Back link and eyebrow point to the run. |
| T-FE-ED-03 | | No add/duplicate/remove-day controls; rest↔workout toggle present; locked-days note shown. |
| T-FE-ED-04 | | Save button label "Save draft"; Ctrl+S saves. |
| T-FE-ED-05 | | Status "Saved · not applied" when clean and unapplied; an identity-only save (name, accent) shows plain "Saved"; banner and identity caption say name/description/colour/cover update immediately. |
| T-FE-ED-06 | | Apply when dirty saves first, then opens dialog; save failure aborts. |
| T-FE-ED-07 | | `mapServerIssues` maps ordinal paths to clientKey paths; fields highlighted. |
| T-FE-ED-08 | | After apply: draft reloaded, state refreshed, success message. |
| T-FE-ED-09 | | `/plans/:id` with `scope: 'run'` redirects to the run editor. |
| T-FE-AP-01…08 | Apply dialog | Dry-run rendering (rebound/redated/added/removed/in-progress/discarded list, removed workouts with removed vs retained counts); confirm payload; `already_applied`; each 409/422 branch per `05` §5. |
| T-FE-EX-01…06 | Peripheral | Run bar copy; NewPlanRun notice; retired chips; load chart break at exercise change; event label link; `session_workout_removed` message when un-cancelling. |
| T-FE-PR-01…04 | Promote dialog | Default name; source choice visibility; `source_revision_id` mapping; success links. |

## 8. Regression suite (must stay green throughout)

- Existing backend unit tests (162) and web tests (166).
- `test_execution_domain.py` (`resolve_next`) — unchanged semantics.
- `test_mobile_execution.py` startability, completeness and prescription-version tests (fixtures
  updated for lineage only).
- `live_mobile_execution_api_scenarios.py` against a converted backup (T6.2).
- Library PlanCreator flows: create, import, duplicate, save, analysis, export, cover image.

## 9. Coverage of the required areas

| # | Required area | Tests |
| --- | --- | --- |
| 1 | Source plan isolation | T-INT-RUN-04, T-INT-RUN-05, T-REG-01, E2E-04 |
| 2 | Run-to-run isolation | T-INT-RUN-06, T-MIG-05, E2E-05 |
| 3 | Structural modifications | T-INT-AP-04…10, T-INT-ID-01…03 |
| 4 | Adding/removing sets | T-INT-AP-02, T-INT-AP-03, T-INT-RX-04 |
| 5 | Exercise replacement | T-INT-AP-04, T-INT-RX-03, T-INT-AN-01/02, T-UNIT-DEF-01 |
| 6 | Completed workout preservation | T-INT-RX-10, T-INT-AP-01, E2E-02 |
| 7 | In-progress session protection | T-CONC-03, T-INT-AP-01 (in-progress fixture), matrix row tests in T-INT-AP-11 |
| 8 | Existing future prescriptions | T-INT-RX-01…08 |
| 9 | Progression-loop continuity | T-INT-ID-01/02, T-INT-AP-02/07, T-UNIT-COPY-04/05, T-INT-AN-01 |
| 10 | Historical analytics | T-INT-AN-03…05, T-MIG-10 |
| 11 | Concurrent modifications | T-CONC-01…05 |
| 12 | Saving a Run Plan to My Plans | T-INT-PR-01/02, T-FE-PR-01…04 |
| 13 | Creating another run from the promoted plan | T-INT-PR-03, E2E-05 |
| 14 | Existing plan_run compatibility | T-MIG-01…10, T-PRE-01 |
| 15 | Failed transactions and rollback | T-FAIL-01…04, T-INT-RX-09 |
| 16 | RELEASED revision immutability | T-IMM-01…04 |
| 17 | Deletion of source plan / originating run vs promoted plans | T-DEL-01…04 |
| 18 | Athlete cancellations preserved | T-INT-AP-09, T-INT-AP-17, T-INT-AN-07 |
| 19 | Identity metadata not revision-scoped | T-API-PLANS-06, T-UNIT-FP-04, T-FE-ED-05 |
| 20 | v1 limitations (fixed duration, re-dating from next microcycle, no scheduled modifications) | T-INT-AP-14 (`day_count_changed`), T-FE-ED-03, T-INT-AP-10, T-API-AP-02 |
