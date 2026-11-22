# 06 — Implementation Roadmap

Small, testable tasks for independent coding agents. Read `README.md`, then the documents each task
names. Decisions are referenced as D1–D16 (`01`), tests as T-IDs (`07`).

## Working on master

All work lands on `master`, in the order below. **Every commit on `master` must be deployable**:
`./redeploy.sh` builds `master` and the API applies pending migrations at start-up, and you may deploy
at any time (also for unrelated fixes). Agents still develop in their own git worktree on a
short-lived task branch; after review (and the gate, where one is listed) the branch is rebased onto
`master` and fast-forwarded into it. There are no long-lived release branches.

Canonical merge order:

| # | Task(s) | Why `master` stays deployable | Gate before merging |
| --- | --- | --- | --- |
| 1 | T0.1 | Tests and scripts only. | — |
| 2 | T0.2 | Tests and read-only SQL only. | — |
| 3 | T1.1 | Migration 0018 is additive; the current runtime ignores it. | — |
| 4 | T1.2 | Additive fields; library behaviour unchanged except the delete-500 fix. | — |
| 5 | T2.2 | New runs copy their plan; their tracks keep positional labels, so the current read code works on them. | — |
| 6 | T2.1 + T2.3 (stacked branches, merged together) | 0019 converts only runs without a run plan, keeps positional labels and ordinals: the current read code works on converted runs; T2.2 already sets `run_plan_id`, so NOT NULL holds. | **T6.2** passes on the stacked branch. Take `db_backup.sh` right before the first deploy that contains 0019. |
| 7 | T3.1 | Every track now has a lineage key. | Re-run T2.3: only additive fields differ. |
| 8 | T3.5, T3.2 (any order) | Additive analytics fields; new endpoints that no client calls. | — |
| 9 | T3.3 | Apply service and the un-cancel guard (which only triggers after an Apply); the Apply route is not registered yet. | — |
| 10 | T3.4 | Registers the Apply route; no client calls it while the UI is hidden. | — |
| — | T5.1 | Additive; may merge any time after #4. | — |
| 11 | T4.1 … T4.5, T5.2, T4.6 | All run-plan UI is behind `RUN_PLAN_UI_ENABLED = false` (added by T4.1). | — |
| 12 | Enable the UI (one-line commit: `RUN_PLAN_UI_ENABLED = true`) | — | **T6.1** and **RD-01** pass. |

Milestones (names used in the other documents): **A** = #1–4, **B** = #5–7, **C** = #8–10 + T5.1
(backend complete, dormant), **D** = #11–12 (UI).

Develop in parallel, merge in order: a task may be developed before its predecessors are merged (on a
branch stacked on theirs, or against mocks), but it is fast-forwarded into `master` only in the order
above. The second of two parallel branches rebases onto `master` before merging.

### Gates

Each gate uses only functionality that is already on `master` or on the branch being gated.

| Gate | When | Checks | Must not use |
| --- | --- | --- | --- |
| **T6.2** | Before T2.1 + T2.3 merge (#6) | RB-01…RB-08 (`07` §6b) | Apply, Discard, run-plan endpoints, promotion, frontend |
| **T6.1** | Before the UI is enabled (#12) | E2E-01…06 (`07` §5) over HTTP against a deployment of current `master` | Frontend |
| **RD-01** | Before the UI is enabled (#12) | Manual walkthrough of `05` with `RUN_PLAN_UI_ENABLED = true` in a local build | — |

## Dependencies and parallel lanes

```text
T0.1 ─┬─ T0.2 ─────────────────────────┐
      └─ T1.1 ─┬─ T1.2 ─ T2.2 ─ T2.1 ─ T2.3 ─► [T6.2] ─► merge #6 ─ T3.1 ─┬─ T3.5
               │                                                         ├─ T3.2 ─ T3.3 ─ T3.4 ─┐
               └─ T5.1 (any time after T1.2) ────────────────────────────┘                       │
docs (04) ─ T4.1 ─┬─ T4.2 ─┬─ T4.5 ─ T4.6                                                         │
                  ├─ T4.3 ─┤                                                                       │
                  └─ T4.4 ─┴─ T5.2 ─────────────────────────────► [T6.1 + RD-01] ─► enable UI ◄────┘
```

Parallel-safe pairs (no shared files): T0.2 ∥ T1.1 · T1.2 ∥ T2.1 development (SQL only; merges after
T2.2) · T3.2 ∥ T3.5 · T5.1 ∥ Phase 3 · all of Phase 4 ∥ Phase 3 (against contract `04`, mocked API) ·
T4.2 ∥ T4.3 ∥ T4.4 (T4.1 owns `router/index.ts`, the API client and the UI flag). Not parallel:
T3.1 → T3.5 (both edit `execution/service.py`), T3.3 → T3.4 (same new files).

Frontend i18n rule: every UI task adds its keys to **all 11 locales** (English text copied into
non-English files) so `tests/i18n.test.ts` stays green; T4.6 translates.

---

## Phase 0 — Safety net

### T0.1 — DB-backed integration test harness

- **Objective:** run repository/service code against a real disposable PostgreSQL with the production
  schema, so lifecycle refactors are verified end to end.
- **Dependencies:** none.
- **Modules/files:** new `be/tests/integration/conftest.py`, `be/tests/integration/builders.py`,
  `be/tests/integration/test_harness_smoke.py`, `be/scripts/test_db.sh`, `be/pyproject.toml`
  (pytest marker `integration`), `be/README.md` (how to run).
- **Exact expected changes:**
  - `test_db.sh`: start `postgres:15` (named, e.g. `agonez-it-db`) on `127.0.0.1:<random port>` with a
    throwaway password; print `AGONEZ_TEST_DATABASE_URL` and `AGONEZ_TEST_DB_CONTAINER`.
  - `conftest.py`: skip the `integration` marker unless `AGONEZ_TEST_DATABASE_URL` is set. Session
    fixture builds template DB `agonez_it_template` once: create the dump's owner role (the name in its
    `OWNER TO …` statements — today `kartezjusz`, 78 statements), then restore the newest
    `agonez_db_backup_*.sql` from the repository root (override with `AGONEZ_TEST_DB_DUMP`) with
    `docker exec -i $AGONEZ_TEST_DB_CONTAINER psql -v ON_ERROR_STOP=1 -d agonez_it_template < dump`.
    **`psql` is not installed on the host** and the dump is plain SQL with 33 `COPY … FROM stdin`
    blocks, so it must be replayed by `psql` inside the container (or a host with
    `postgresql-client`). The dump already contains `public.agonez_schema_migrations` at `0017`, so
    `run_migrations()` (`migrations/runner.py`) afterwards applies only newer migrations. Per-test (or per-module) database
    `CREATE DATABASE agonez_it_<hex> TEMPLATE agonez_it_template`; yield `Settings`, a pool from
    `create_database_pool`, `create_app(settings=…, pool=…)` with an `httpx.AsyncClient`
    (ASGI transport), and repositories/services; drop the DB afterwards. `Settings` has no DSN field:
    build it from the URL parts through its aliases (`NOME`, `AGANDSKODE`, `MINA`, `DB_HOST`,
    `DB_NAME`, `core/config.py`). A pool passed to `create_app` is not opened by its lifespan, so the
    fixture opens and closes it (`open_database_pool`, `core/database.py`).
  - `ExecutionService` constructed with a frozen `today` callable (it already accepts one,
    `execution/service.py:60-67`).
  - `builders.py`: `make_library_plan(client, spec)` (POST `/api/plans` + PUT draft from a compact
    spec: days, workouts, slots, exercise slugs taken from `core.exercises`, sets),
    `make_run(client, revision_id, starts_on, count)`, `finalize_session(...)` via mobile API
    (start + ops + finalize), `snapshot_tables(conn, tables) -> dict[str, str]` (per-table hash of
    ordered rows) for "nothing changed" assertions.
- **API/schema dependencies:** none (current schema).
- **Acceptance criteria:** `pytest -m integration` creates a plan, a run, finalises one mobile workout
  and reads the overview with HTTP 200 on a fresh template clone; without the env var the integration
  tests are skipped and the default `pytest` run is unchanged (162 passing).
- **Required tests:** `test_harness_smoke.py` (above).
- **Potential regressions:** none in app code; CI time if enabled by default (keep opt-in).
- **Deliverables:** harness files, README section, one green smoke test.
- **Suggested agent:** backend test-infrastructure agent.

### T0.2 — Characterisation tests and pre-flight audit

- **Objective:** pin today's defects as executable specifications and provide the 0019 pre-flight.
- **Dependencies:** T0.1.
- **Modules/files:** new `be/tests/integration/test_lifecycle_characterization.py`,
  `be/scripts/run_plans_preflight.sql`, `be/tests/integration/test_preflight.py`.
- **Exact expected changes:** tests written as **target behaviour** marked
  `@pytest.mark.xfail(strict=True, reason="fixed by T2.2/T3.1")`:
  - editing a library plan after run creation does not change the run's overview/plan sets (R1);
  - removing a training day from a library plan that has a run returns 2xx (R2);
  - deleting a library plan that has runs returns 204 (R2);
  - reordering slots in the library plan does not change any run track's exercise (R3);
  - adding a slot to the library plan keeps the run's next session startable (R4);
  - deleting a never-prescribed slot does not make `GET …/overview` 404 (R5).
  `run_plans_preflight.sql` implements the five checks of `02` §4.1; `test_preflight.py` asserts zero
  rows on the restored backup.
- **API/schema dependencies:** none.
- **Acceptance criteria:** all characterisation tests xfail today; preflight returns zero rows on the
  2026-11-19 backup.
- **Required tests:** as listed (T-REG-01…06 in `07`).
- **Potential regressions:** none.
- **Deliverables:** test module, preflight SQL, test.
- **Suggested agent:** backend test agent.

---

## Phase 1 — Backend foundation

### T1.1 — Migration 0018: schema and `plans.copy_revision_tree`

- **Objective:** add scope, lineage, ownership columns and the single copy implementation without
  changing runtime behaviour.
- **Dependencies:** T0.1.
- **Modules/files:** new `be/src/agonez_api/migrations/versions/0018_run_plans_schema.sql`; new
  `be/tests/integration/test_copy_revision_tree.py`.
- **Exact expected changes:** exactly `02` §1.1 and §2: enum `plans.plan_scope`;
  `workout_plans.scope/source_plan_id` + `UNIQUE(id, scope)` + partial index; `lineage_key` on
  `workout_unit_prescriptions` and `exercise_slots`; `plan_runs.run_plan_id` (nullable),
  `run_plan_scope` + CHECK + UNIQUE + composite FK; nullable `plan_lineage_key` on both track
  tables; `plans.copy_revision_tree(int, int, boolean)` returning `(entity, source_id, target_id)`.
  Comments on every new column.
- **API/schema dependencies:** none.
- **Acceptance criteria:** migration applies on the template; existing unit and integration tests
  pass unchanged; the function copies a real revision completely.
- **Required tests:** T-UNIT-COPY-01…06 (`07` §1): row counts per entity equal; parent remapping;
  lineage keys equal; progression ids equal when `false`, fresh but sharing-preserving when `true`;
  `load_step_kg` raw (NULL stays NULL); icon/loading cycles/target muscles copied; non-empty target
  raises.
- **Potential regressions:** table rewrite time for `ADD COLUMN … DEFAULT gen_random_uuid()` (small
  tables; acceptable); `UNIQUE(id, scope)` is redundant with PK but required for the composite FK.
- **Deliverables:** migration file, tests.
- **Suggested agent:** backend database agent.

### T1.2 — Plans module: revision loader, copy via function, fingerprint, scope guards

- **Objective:** make the plans module run-plan aware with no behavioural change for library plans
  except fixing the delete-500.
- **Dependencies:** T1.1.
- **Modules/files:** `modules/plans/repository.py`, `service.py`, `schemas.py`, `exceptions.py`,
  `router.py` (no new routes), `app.py` (409 handler for `PlanScopeError`), new
  `modules/plans/fingerprint.py`; tests `tests/test_plan_fingerprint.py`,
  `tests/integration/test_plan_scope.py`; update `tests/test_plan_repository.py` (copy test moves to
  integration), `tests/test_openapi.py`.
- **Exact expected changes:** `02` §3.1 rows "Revision loader", "Copy", "Fingerprint", "Scope
  guards", "Artifact fields". Concretely:
  - `load_revision_rows(connection, revision_id)` public; `_load_draft_rows` delegates to it; header
    adds `scope`, `source_plan_id`, `plan_run_id` (LEFT JOIN `exec.plan_runs` on `run_plan_id`).
  - `copy_revision(...)` wraps the SQL function; `duplicate_plan` uses it with
    `regenerate_progression_ids=True`; delete the Python remapping body of `_copy_draft_tree`.
  - `definition_fingerprint(DraftRows) -> str` (see `02` §3.1).
  - `list_plans` filters `scope='library'`; `delete_plan` raises `PlanScopeError` for run plans;
    `create_plan`/`import_plan` explicit `scope='library'`.
  - `PlanDraftArtifact`, `PlanSummary`, `PlanDetail` gain the fields of `04` §2; `PlanDraftUpdate`
    accepts and ignores `scope`, `source_plan_id`, `plan_run_id`.
- **API/schema dependencies:** 0018.
- **Acceptance criteria:** library flows behave as before (existing tests green); a manually inserted
  run-scope plan is not listed and cannot be deleted through `/api/plans`; GET→PUT draft round trip
  with the new fields succeeds; fingerprint is id-insensitive and lineage-sensitive.
- **Required tests:** T-UNIT-FP-01…05, T-API-PLANS-01…05, T-IMM-03 (introduce the static write
  allow-list with today's writers; later tasks extend it) (`07`).
- **Potential regressions:** `duplicate_plan` semantics (progression-id sharing) — covered by
  T-UNIT-COPY-05; OpenAPI snapshot.
- **Deliverables:** code + tests.
- **Suggested agent:** backend plans agent.

---

## Phase 2 — Migration / compatibility

### T2.1 — Migration 0019: convert legacy runs

- **Objective:** give every run without a run plan (`run_plan_id IS NULL`) its own run plan, remap all
  `exec` references, backfill lineage, tighten constraints.
- **Dependencies:** T1.1 (function, columns); T0.2 (preflight); T2.2 merged (it sets `run_plan_id` for
  new runs, so the NOT NULL constraint holds). SQL can be developed earlier; it merges at step #6
  together with T2.3, after the T6.2 gate.
- **Modules/files:** new `migrations/versions/0019_run_plans_convert_legacy_runs.sql`; new
  `be/tests/integration/test_migration_0019.py`.
- **Exact expected changes:** `02` §1.2 and §4 (preflight `RAISE`, per-run algorithm,
  `public.agonez_0019_reference_map`, constraints and comments). Written as a single PL/pgSQL
  `DO $$ … $$` block plus DDL; no Python.
- **API/schema dependencies:** 0018.
- **Acceptance criteria (on the restored 2026-11-19 backup):** all `02` §4.3 verification queries pass;
  run 1 has applied revisions r1 (copy of library rev 6) and r2 (copy of rev 25) and a draft r3; runs 3
  and 14 (and 2 and 11) own distinct run plans; library plan fingerprints unchanged; session and
  prescription counts unchanged; `DELETE FROM plans.workout_plans WHERE id = 15` succeeds inside a
  rolled-back test transaction; a run created by T2.2 code before the migration is left unchanged;
  legacy tracks keep their positional `logical_key` labels.
- **Required tests:** T-MIG-01…09, T-MIG-11 (`07` §6).
- **Potential regressions:** migration duration (≈ 6 runs, hundreds of rows — seconds); a preflight
  failure blocks deploy (intended); seed script incompatibility (Q5). The pre-T3.1 read code must keep
  working on converted runs (checked by T2.3).
- **Deliverables:** migration, tests, a short "run before deploy" note in the migration header
  comment (take `db_backup.sh`).
- **Suggested agent:** backend database agent.

### T2.2 — Run creation and deletion with run plans

- **Objective:** new runs copy their plan; deleting a run deletes its run plan. Must be deployable on
  0018 alone, with the current (positional) read code.
- **Dependencies:** T1.2.
- **Modules/files:** `modules/execution/repository.py` (`create_plan_run`, `delete_plan_run`), new
  `modules/execution/run_plan_repository.py` (`create_run_plan`); tests
  `tests/integration/test_run_creation.py`, `tests/test_execution_service.py`.
- **Exact expected changes:** `02` §3.3 and §3.6. Tracks get `plan_lineage_key` **and keep the
  positional `day:N`/`slot:N` labels**. `delete_plan_run` deletes the run plan when `run_plan_id` is
  set (legacy runs have none until 0019). No run-header or mobile-context changes (they move to T3.1);
  the header keeps reading the plan via `initial_plan_revision_id`, which now points at the run plan, so
  `run.plan.code` shows the run plan's code until T3.1/T4.5.
- **API/schema dependencies:** 0018; T1.2 copy + fingerprint.
- **Acceptance criteria:** after creation: run plan `scope='run'`, r1 RELEASED and r2 DRAFT with
  fingerprints equal to the library draft; tracks carry the copied lineage keys; sessions bound to r1;
  setup notes seeded as before; editing/deleting the library plan afterwards changes nothing in the run;
  two runs from one library plan are independent; deleting a run removes its run plan and leaves the
  library plan; creating from a run-plan revision → 422 `plan_revision_not_library`; overview,
  analysis queue, timeline, mobile context and fallback/start work for a new run with the unchanged
  read code. T0.2 tests for R1/R2 now XPASS → remove their xfail markers.
- **Required tests:** T-INT-RUN-01…08, T-DEL-01, T-DEL-02, T-IMM-04 (`07`); extend the T-IMM-03
  allow-list with the run-plan delete in `delete_plan_run`.
- **Potential regressions:** preview vs creation counts; mobile context plan name; `RunManagerDialog`
  delete flow (still single call).
- **Deliverables:** code + tests.
- **Suggested agent:** backend execution agent.

### T2.3 — Conversion rehearsal and golden comparison

- **Objective:** prove the conversion does not change any Execution read model.
- **Dependencies:** T2.1 (developed on a branch stacked on T2.1; both merge together at step #6);
  T0.1.
- **Modules/files:** new `be/tests/integration/test_migration_golden.py`, helper
  `be/tests/integration/golden.py` (id-insensitive JSON normaliser).
- **Exact expected changes:** for every run on the restored backup, capture `overview`,
  `analysis/queue`, `timeline`, `workout-traces` (+ each trace), `load-series`, mobile `context` and
  each pending session's `prescription` **before** 0019 and **after** 0019 using the same code version
  (current `master`, i.e. including T2.2);
  compare after removing database ids and fields added by this feature. Re-run after T3.1: expected
  differences are limited to the additive fields of `04` §2.
- **API/schema dependencies:** 0019.
- **Acceptance criteria:** zero unexpected diffs.
- **Required tests:** T-MIG-10.
- **Potential regressions:** none (test-only).
- **Deliverables:** test + normaliser.
- **Suggested agent:** backend test agent.

---

## Phase 3 — Execution reconciliation

### T3.1 — Identity and binding refactor

- **Objective:** remove positional identity and microcycle-level binding from every read and write
  path.
- **Dependencies:** T2.2 (new runs with lineage), T2.1 (legacy data).
- **Modules/files:** `modules/execution/repository.py` (`_load_bundle`, `_load_plan_structures`,
  `save_exercise_prescription`, `_logical_ordinal` removal), `modules/execution/service.py`
  (`_target_structure`, `_display_name`, `_analysis_queue`, `_queue_exercise`, `_next_prescription`
  target lookup, `_exercise_trace`, `_workout_trace`, `list_workout_traces`, `_timeline`,
  `_load_series` labels, `_logical_ordinal` removal), `modules/execution/schemas.py` (`retired`
  flags), `modules/mobile_execution/repository.py` (`_ensure_fallback_prescription` binding check and
  lineage join, startability filters in `load_context`/`start_workout`); tests
  `tests/integration/test_identity.py`, updates to `tests/test_execution_service.py`,
  `tests/test_mobile_execution.py`.
- **Exact expected changes:** run header and mobile context fields moved here from T2.2 (`04` §2:
  `run.plan` = run plan, `run.source_plan`, `run.current_revision`, `run.has_unapplied_changes`; files
  `execution/repository.py` `list_plan_runs`/`_load_bundle` run query, `service.py` `_run_header`,
  `schemas.py`, `mobile_execution/repository.py` `list_plan_runs`/`load_context`); `02` §3.4 table, row
  by row. Grep acceptance: no `_logical_ordinal`
  and no `'slot:' ||` / `'day:'` parsing remain in `modules/`.
- **API/schema dependencies:** 0019 constraints.
- **Acceptance criteria:** existing tests green (fixtures updated for lineage); a track whose slot is
  absent from the current revision is reported `retired: true` and the overview returns 200;
  reordering slots in a (synthetic) second revision keeps each track on its exercise; mobile fallback
  refuses sessions not bound to the current revision with `reason: session_not_current`; T0.2 R3/R5
  tests XPASS (remove markers); T2.3 golden diff shows only additive fields.
- **Required tests:** T-INT-ID-01…08.
- **Potential regressions:** ordering of workouts/exercises in Analysis and Timeline (now by current
  position); demo run 1 transitions display.
- **Deliverables:** code + tests.
- **Suggested agent:** backend execution agent (one agent; large but mechanical).

### T3.2 — Run-plan state, revision read and discard

- **Objective:** expose run-plan state and history; allow discarding unapplied changes.
- **Dependencies:** T2.2 (code); merges after T3.1 (step #8). Can be developed in parallel with T3.1
  and T3.5.
- **Modules/files:** new `modules/execution/run_plan.py` (service), `run_plan_repository.py`
  (state, revision artifact via `PlanRepository.load_revision_rows` + `PlanService.assemble_draft`,
  discard), `modules/execution/run_plan_schemas.py`; `modules/execution/router.py` (3 routes);
  `app.py` wiring; tests `tests/integration/test_run_plan_state.py`, `tests/test_openapi.py`.
- **Exact expected changes:** `04` §1.1, §1.2, §1.4. Discard: lock order advisory → run → plan →
  draft; delete draft children (`DELETE FROM plans.day_prescriptions WHERE revision_id = draft`),
  `copy_revision_tree(current → draft, false)`, bump `lock_version`.
- **API/schema dependencies:** T1.2 fingerprint, loader.
- **Acceptance criteria:** fresh run → `has_unapplied_changes=false`; after a draft PUT changing a rep
  range → `true`; after reverting → `false`; history lists r1 with `copied_from_library`; foreign
  revision id → 404; discard restores fingerprint equality and bumps lock; discard with stale lock →
  409; on a completed run → 409.
- **Required tests:** T-API-RP-01…08, T-API-PLANS-06; extend the T-IMM-03 allow-list with Discard (which must verify
  `status = 'DRAFT'` before deleting).
- **Potential regressions:** none (new endpoints).
- **Deliverables:** endpoints + tests + OpenAPI.
- **Suggested agent:** backend execution agent #2.

### T3.3 — Apply: snapshot, validation, concurrency, session and track reconciliation

- **Objective:** implement Apply per `03` §2–§5 (without prescription rebase, which is T3.4; both ship
  together).
- **Dependencies:** T3.1, T3.2.
- **Modules/files:** `modules/execution/run_plan.py`, `run_plan_repository.py`,
  `run_plan_schemas.py` (the Apply **route** is registered by T3.4, so `master` never exposes a partial
  Apply; T3.3 tests call the service); tests `tests/integration/test_apply_sessions.py`,
  `tests/integration/test_apply_concurrency.py`, `tests/test_run_plan_validation.py` (pure
  `validate_executable`).
- **Exact expected changes:** cancellation rules of `03` §5.1–§5.3 (never delete, re-date or change
  the status of a `cancelled` session); un-cancel guard in `execution/repository.py:update_session_status`
  (`02` §3.4, 409 `session_workout_removed`); pseudocode `03` §2 (steps 0–4 except `rebase_prescription`, which is a
  stub raising `NotImplementedError` when a pending session has prescriptions — T3.3 tests use runs
  without saved prescriptions; T3.4 replaces it), `03` §3 validation, §4 tracks, §5
  sessions, microcycle update, event, draft renumbering; error codes `04` §1.3.
- **API/schema dependencies:** T3.2 schemas.
- **Acceptance criteria:** behaviour-matrix rows for sessions without prescriptions (`03` §7) hold;
  post-apply invariants 1, 2, 4, 5, 6, 7 (`03` §12); idempotent replay returns `already_applied`;
  two concurrent Applies → exactly one new revision; Apply and mobile start interleaved → consistent
  outcome either way.
- **Required tests:** T-INT-AP-01…17, T-CONC-01…05, T-API-AP-01, T-API-AP-02; extend the T-IMM-03 allow-list with Apply's draft
  renumbering.
- **Potential regressions:** advisory-lock contention with mobile start (short transactions);
  timeline display for re-dated sessions.
- **Deliverables:** code + tests.
- **Suggested agent:** backend execution agent (senior).

### T3.4 — Prescription rebase/discard, impact report, dry run

- **Objective:** complete Apply with prescription handling, the impact report and dry run.
- **Dependencies:** T3.3.
- **Modules/files:** same as T3.3, plus the Apply route in `execution/router.py`; tests
  `tests/integration/test_apply_prescriptions.py`,
  `tests/integration/test_apply_mobile_compat.py`.
- **Exact expected changes:** `03` §6 algorithm (two-phase ordinal update), impact structure
  `04` §1.3, `dry_run` via `connection.transaction(force_rollback=True)`; event metadata impact
  summary.
- **API/schema dependencies:** none new.
- **Acceptance criteria:** invariants 3 and 8; matrix prescription cells; after Apply, mobile
  `prepare fallback` + `start` succeed for a session with a rebased analysis prescription and a newly
  added slot (fixes R6, T0.2 R4 XPASS); dry-run impact equals real impact; desktop PWA save with a
  pre-Apply `expected_version` returns `version_conflict`.
- **Required tests:** T-INT-RX-01…10, T-MOB-01…05, T-IMM-01, T-IMM-02.
- **Potential regressions:** mobile `prescription_version` changes for pending sessions after every
  Apply (intended).
- **Deliverables:** code + tests.
- **Suggested agent:** same agent as T3.3.

### T3.5 — Exercise-identity analytics fixes

- **Objective:** make defaults and analytics respect core-exercise identity and per-session revisions.
- **Dependencies:** T3.1 (same file; run after it).
- **Modules/files:** `modules/execution/service.py` (`_next_prescription` defaults, `_load_series`,
  `_exercise_revision_transitions`, `_timeline` columns and `revision_changed_here`), `schemas.py`
  (load-series point fields); tests `tests/integration/test_analytics_identity.py`,
  `tests/test_execution_service.py`.
- **Exact expected changes:** `02` §3.5; `03` §10, including the required timeline rule: when a
  retained cancellation shares a date with another session, `_timeline_day` returns the non-cancelled
  one.
- **API/schema dependencies:** none.
- **Acceptance criteria:** after replacing an exercise, the next-prescription defaults are `null`;
  the load series exposes `exercise_id` per point and `delta_pct` over the latest exercise only;
  revision transitions appear at the first exposure on the new revision even mid-microcycle; timeline
  columns reflect the current revision.
- **Required tests:** T-INT-AN-01…07.
- **Potential regressions:** Loads tab deltas for runs with Atlas substitutions (substituted points
  already have `value = null`; verify unchanged).
- **Deliverables:** code + tests.
- **Suggested agent:** backend execution agent.

---

## Phase 4 — Frontend integration

### T4.1 — API client, types, routes and stubs

- **Objective:** typed client for `04`, router entries, empty view stubs and the UI flag so UI tasks
  can run in parallel and land on `master` while hidden.
- **Dependencies:** `04` (contract only).
- **Modules/files:** `web-fe/src/api/execution.ts`, `execution-types.ts`, `plans.ts`, `plan-types.ts`,
  `src/router/index.ts`, stub `src/views/execution/ExecutionRunPlanView.vue`,
  `src/views/execution/RunPlanEditorView.vue`; `tests/api-client.test.ts`,
  `tests/fixtures/run-plan.ts` (fixtures for state, revision artifact, apply results incl. errors).
- **Exact expected changes:** `04` §6 types and client methods; `05` §1 routes; new
  `src/features/execution/run-plan-flag.ts` exporting `RUN_PLAN_UI_ENABLED = false` — the run-plan
  routes, the Run plan tab and the `/plans/:id` redirect are registered/rendered only when it is
  `true` (`05` §1).
- **Acceptance criteria:** typecheck/lint/tests green; fixtures cover every `04` example; with the flag
  `false` the app behaves exactly as before (no tab, no routes); tests cover both flag values.
- **Required tests:** T-FE-API-01…03, T-FE-FLAG-01.
- **Potential regressions:** route ranking between `/execution/runs/:runId/plan/edit` and the parent
  route (test navigation).
- **Deliverables:** code, fixtures, tests.
- **Suggested agent:** frontend agent.

### T4.2 — Run Plan tab

- **Dependencies:** T4.1.
- **Objective/expected changes:** `05` §2.1 (tab + dot in `ExecutionLayout.vue`), §3 (view,
  `RunPlanDefinition`, `RunPlanHistory`, `RunPlanRevisionDrawer`, discard), §6 (ended runs).
- **Modules/files:** files listed in `05` §11 for these components.
- **Acceptance criteria:** renders fixtures for fresh/unapplied/ended states; discard calls the API
  with the lock version and reloads; history "View" opens the drawer.
- **Required tests:** T-FE-RP-01…07 (`tests/run-plan-view.test.ts`).
- **Potential regressions:** Execution tab highlighting (`activeTab`).
- **Deliverables:** components + tests.
- **Suggested agent:** frontend agent A.

### T4.3 — PlanCreator run context

- **Dependencies:** T4.1.
- **Objective/expected changes:** `05` §4 (wrapper view, `runContext` prop, `RunPlanContextBanner`
  with the wording that separates applied definition changes from immediately-saved identity
  metadata, identity-panel caption,
  `lockDayStructure`/`structureLocked`, status chip, Save draft, Apply button wiring to the dialog
  component interface, `mapServerIssues`, redirect from `/plans/:id` for run plans), §6 editor part.
- **Modules/files:** `PlanCreatorView.vue`, `PlanEditor.vue`, `DayEditor.vue`, new
  `RunPlanEditorView.vue` (replace stub), `RunPlanContextBanner.vue`, `features/plans/run-plan.ts`.
- **Acceptance criteria:** with no `runContext`, all existing PlanCreator tests pass unchanged; in run
  context add/duplicate/remove-day controls are absent, rest↔workout toggle works, Ctrl+S saves the
  draft, Apply saves first when dirty, server issues highlight fields.
- **Required tests:** T-FE-ED-01…09 (`tests/run-plan-editor.test.ts`, `tests/plan-editor.test.ts`).
- **Potential regressions:** library PlanCreator behaviour (guarded by existing tests).
- **Deliverables:** code + tests.
- **Suggested agent:** frontend agent B.

### T4.4 — Apply dialog

- **Dependencies:** T4.1.
- **Objective/expected changes:** `05` §5 (dry run, impact rendering including removed workouts with
  removed vs retained session counts, note, all error branches).
- **Modules/files:** `RunPlanApplyDialog.vue`, `tests/run-plan-apply-dialog.test.ts`.
- **Acceptance criteria:** each `04` §1.3 response fixture renders the specified behaviour; confirm sends
  `dry_run:false` with the same versions and the note.
- **Required tests:** T-FE-AP-01…08.
- **Deliverables:** component + tests.
- **Suggested agent:** frontend agent C.

### T4.5 — Peripheral Execution updates

- **Dependencies:** T4.2 (tab exists), T3.5 contract (load-series fields).
- **Objective/expected changes:** `05` §2.2 run bar, §8 table (NewPlanRunView notice and revision
  selector, retired chips, load chart breaks, event label/link, `session_workout_removed` message on
  un-cancel).
- **Modules/files:** `ExecutionLayout.vue`, `NewPlanRunView.vue`, `LoadsChart.vue`,
  `ExerciseTraceTable.vue`, `AnalysisQueue.vue`, `WorkoutTraceView.vue`,
  `ExecutionTimelineView.vue`; `tests/execution.test.ts`.
- **Acceptance criteria:** run bar shows run/source plan; chart breaks between exercises; retired chips
  visible.
- **Required tests:** T-FE-EX-01…06.
- **Deliverables:** code + tests.
- **Suggested agent:** frontend agent A.

### T4.6 — Translations

- **Dependencies:** T4.2–T4.5, T5.2 strings final.
- **Objective:** translate all new keys in the 10 non-English locales.
- **Modules/files:** `src/i18n/locales/{pl,fr,es,de,it,nl,sv,pt-BR,uk,tr}/{execution,plans}.ts`.
- **Acceptance criteria:** `tests/i18n.test.ts` green; no English text left in non-English files for the
  new keys; pluralisation forms correct (pl, uk need three forms).
- **Required tests:** existing i18n parity tests.
- **Suggested agent:** localisation agent.

---

## Phase 5 — Library promotion

### T5.1 — Backend: duplicate with name and source revision

- **Objective:** promotion via `POST /api/plans/{id}/duplicate` (`04` §4).
- **Dependencies:** T1.2.
- **Modules/files:** `modules/plans/router.py`, `service.py`, `repository.py`, `schemas.py`
  (`PlanDuplicateRequest`); tests `tests/integration/test_promotion.py`, `tests/test_plan_schemas.py`,
  `tests/test_openapi.py`.
- **Exact expected changes:** optional body; source revision default DRAFT; validation that it belongs to
  the plan; result `scope='library'`, `source_plan_id`, fresh progression ids, image copied.
- **Acceptance criteria:** promoting a run plan's current applied revision yields a library plan whose
  fingerprint (ignoring progression ids) equals that revision; a run created from it is independent
  of the original run; empty body behaves exactly as today.
- **Required tests:** T-INT-PR-01…06, T-DEL-03, T-DEL-04.
- **Potential regressions:** `PlanListView` duplicate (sends `{}`) — covered.
- **Deliverables:** code + tests.
- **Suggested agent:** backend plans agent.

### T5.2 — Frontend: promote dialog

- **Dependencies:** T5.1 (contract), T4.1, T4.2.
- **Objective/expected changes:** `05` §7; entry points in the Run Plan tab and the editor.
- **Modules/files:** `RunPlanPromoteDialog.vue`, `ExecutionRunPlanView.vue`, `PlanCreatorView.vue`
  (button only), `tests/run-plan-promote.test.ts`.
- **Acceptance criteria:** source choice shown only with unapplied changes; correct
  `source_revision_id`; success links.
- **Required tests:** T-FE-PR-01…04.
- **Suggested agent:** frontend agent C.

---

## Phase 6 — End-to-end validation

### T6.1 — Live lifecycle scenario (gate before enabling the UI)

- **Objective:** destructive acceptance script on a disposable deployment covering the whole feature.
- **Dependencies:** T3.2, T3.3, T3.4, T3.5, T5.1 on `master`. Gates step #12 (UI enable) only; it is not
  a prerequisite of any earlier merge.
- **Modules/files:** new `be/tests/live_run_plan_scenarios.py` (same style and safety guard as
  `live_mobile_execution_api_scenarios.py`: requires `RUN_PLAN_ALLOW_DESTRUCTIVE_TEST=1`).
- **Exact expected changes:** scenario E2E-01 … E2E-06 of `07` §5, via HTTP only.
- **Acceptance criteria:** script passes against a disposable deployment of current `master` restored
  from a recent backup.
- **Suggested agent:** QA agent.

### T6.2 — Migration 0019 rehearsal (gate before merging T2.1 + T2.3)

- **Objective:** de-risk the legacy-run conversion using only what is on `master` plus the T2.1 + T2.3
  branch.
- **Dependencies:** T0.2 (preflight) and T2.2 on `master`; the stacked T2.1 + T2.3 branch. **No
  dependency on T3.1, Phase 3, promotion, frontend or T6.1.**
- **Exact expected changes:** checklist RB-01…RB-08 (`07` §6b) executed against a scratch container
  restored from a fresh `db_backup.sh` dump and recorded in `handoff/T6.2.md`: preflight, migrations
  0018/0019 with timings, T-MIG and golden tests, run creation/isolation smoke, existing mobile live
  scenario on converted runs, desktop read smoke, rollback drill (`02` §7).
- **Acceptance criteria:** RB-01…RB-08 pass, no unexpected diffs, timings recorded.
- **Suggested agent:** release/devops agent.

---

## Definition of done (every task)

- `ruff`, `mypy` (as configured in `be/pyproject.toml`), `pytest` (unit) and `pytest -m integration`
  green for backend tasks; `npm run lint`, `npm run typecheck`, `npm test` green for frontend tasks.
- New SQL has comments on new columns and functions (repository convention).
- `master` stays deployable after the commit (merge order and reasons: "Working on master").
- No change to unrelated modules; no broad refactors.
- Any new `UPDATE plans.*` / `DELETE FROM plans.*` statement is added to the T-IMM-03 allow-list with
  a justification that it cannot touch a RELEASED revision (`01` D16).
- Any data migration touching plan child rows states explicitly how it treats RELEASED revisions.
- `__docs__/` updates are out of scope unless the task says so; update `04` here if a contract changes.
