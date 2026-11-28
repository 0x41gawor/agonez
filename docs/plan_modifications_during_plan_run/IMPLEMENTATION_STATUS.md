# Implementation Status — Plan Modifications During a Plan Run

The **single source of truth for progress**. Every agent reads this file first and updates it as the
last step of its task. Humans pick the next task from "Next up" and paste the matching prompt from
[AGENT_PROMPTS.md](AGENT_PROMPTS.md).

Last updated: 2026-11-28 — T2.1 (migration 0019) passed review; rebased onto `master` `e79fc1d` with T2.2's run creation (fix round in review). Next: T2.3 stacked on T2.1 ∥ T5.1; then T6.2.

---

## Next up

| Order | Task | Can run in parallel with | Notes |
| --- | --- | --- | --- |
| 1 | **T2.1** fix-round review | T5.1 | `impl/T2.1-convert-legacy-runs`, rebased on `e79fc1d` ([handoff/T2.1.md](handoff/T2.1.md)): the migration passed review; the fix commit `test(be): run the 0019 tests on T2.2's run creation` removed the pre-T2.2 stand-in, builds T-MIG-11's run with T2.2's real creation and runs T2.2's legacy-run tests before 0019. Merges with T2.3 at #6 after the T6.2 rehearsal. |
| 2 | **T5.1** promotion backend | T2.1 development | Ready now (#5 merged). T-INT-PR-03, T-INT-PR-06 and T-DEL-03/04 use runs that own their plans (helpers `create_run`, `plan_snapshot` and the promoted-plan setup of `test_int_run_07_…` in `tests/integration/test_run_creation.py`). The Apply half of T-INT-PR-03 waits for T3.3 and is covered by E2E-05 (T6.1). Reuse `duplicate_plan` + `definition_fingerprint(…, include_progression_ids=False)`. Not on the merge path: merge when reviewed. |
| 3 | T2.3, then T6.2 | — | T2.3 stacks on the finished T2.1 branch; T6.2 rehearses 0019 on that branch (create its smoke run from an executable plan, not demo plan 6). Both gate #6. T2.3 uses T2.1's `before_migration(RUN_PLAN_CONVERSION)` marker and `apply_migrations(…, through=RUN_PLAN_CONVERSION)` (handoff/T2.1.md "For the next tasks"). |

Update this table whenever a task finishes.

### Follow-ups without a task yet

| Follow-up | When | Notes |
| --- | --- | --- |
| Drop `public.agonez_0019_reference_map` with a new migration | One release after #6 (0019 deployed) | Kept for verification and a manual reverse remap (`02` §4.2, handoff/T2.1.md). No task in `06` owns it yet; plain table, no FKs. |

---

## Merge order on master

Everything lands on `master`, one task at a time, in this order; **every commit on `master` must be
deployable** (details and reasons: `06-implementation-roadmap.md` → "Working on master"). The human
deploys with `./redeploy.sh` from `/home/agonez`; agents never deploy.

| # | Task(s) | Gate before merging | Milestone | Merged |
| --- | --- | --- | --- | --- |
| 1 | T0.1 | review | A | ✓ `dcda3c9` 2026-11-25 |
| 2 | T0.2 | review | A | ✓ `e99336e` 2026-11-25 |
| 3 | T1.1 | review | A | ✓ `e66f5b4` 2026-11-25 |
| 4 | T1.2 | review | A | ✓ `64ce51f` 2026-11-25 |
| 5 | T2.2 | review | B | ✓ `227d3ce` 2026-11-28 |
| 6 | T2.1 + T2.3 (stacked, merged together) | review + **T6.2**; take `db_backup.sh` before the first deploy containing 0019 | B | |
| 7 | T3.1 | review (mandatory) + T2.3 re-run | B | |
| 8 | T3.5, T3.2 | review | C | |
| 9 | T3.3 | review (mandatory) | C | |
| 10 | T3.4 | review (mandatory) | C | |
| — | T5.1 (any time after #5) | review | C | |
| 11 | T4.1 … T4.5, T5.2, T4.6 (UI hidden: `RUN_PLAN_UI_ENABLED = false`) | review | D | |
| 12 | Enable the UI (`RUN_PLAN_UI_ENABLED = true`) | **T6.1** + **RD-01** | D | |

---

## Task board

Status values: `todo` · `ready` (dependencies done) · `in progress` · `review` · `done` · `blocked`.

| Task | Title | Depends on | Status | Branch | Commit | Updated |
| --- | --- | --- | --- | --- | --- | --- |
| T0.1 | DB-backed integration test harness | — | done | `impl/T0.1-integration-harness` (deleted) | `dcda3c9` | 2026-11-25 |
| T0.2 | Characterisation tests + preflight | T0.1 | done | `impl/T0.2-characterisation-preflight` (deleted) | `e99336e` | 2026-11-25 |
| T1.1 | Migration 0018 + `plans.copy_revision_tree` | T0.1 | done | `impl/T1.1-run-plans-schema` (deleted) | `e66f5b4` | 2026-11-25 |
| T1.2 | Plans module: loader, copy, fingerprint, scope guards | T1.1 | done | `impl/T1.2-plans-module` (deleted) | `64ce51f` | 2026-11-25 |
| T2.1 | Migration 0019: convert legacy runs | T1.1, T0.2, T2.2 (merge), T6.2 (merge) | review | `impl/T2.1-convert-legacy-runs` | rebased on `master` `e79fc1d`; 2 commits (migration + fix round) | 2026-11-28 |
| T2.2 | Run creation/deletion with run plans | T1.2 | done | `impl/T2.2-run-creation` (deleted) | `227d3ce` | 2026-11-28 |
| T2.3 | Conversion golden comparison | T2.1 (stacked) | ready (stack on `impl/T2.1-…`) | | | 2026-11-28 |
| T3.1 | Identity and binding refactor (+ run header fields) | T2.1 + T2.3 merged | todo | | | |
| T3.2 | Run-plan state, revision read, discard | T3.1 merged | todo | | | |
| T3.3 | Apply: sessions, tracks, validation, concurrency | T3.1, T3.2 | todo | | | |
| T3.4 | Prescription rebase, impact, dry run | T3.3 | todo | | | |
| T3.5 | Exercise-identity analytics fixes | T3.1 | todo | | | |
| T4.1 | Frontend API client, types, routes, stubs, UI flag | contract `04` | todo | | | |
| T4.2 | Run Plan tab | T4.1 | todo | | | |
| T4.3 | PlanCreator run context | T4.1 | todo | | | |
| T4.4 | Apply dialog | T4.1 | todo | | | |
| T4.5 | Peripheral Execution updates | T4.2, T3.5 | todo | | | |
| T4.6 | Translations | T4.2–T4.5, T5.2 | todo | | | |
| T5.1 | Promotion backend (duplicate with body) | T1.2, T2.2 merged | ready | | | 2026-11-28 |
| T5.2 | Promote dialog | T5.1, T4.1, T4.2 | todo | | | |
| T6.2 | Migration 0019 rehearsal (gate for #6) | T0.2, T2.2 merged; T2.1 + T2.3 branch | todo | | | |
| T6.1 | Live lifecycle scenario (gate for #12) | T3.2–T3.5, T5.1 merged | todo | | | |

---

## Decisions log

Open questions from `README.md`. Decide before the task in the last column starts. If undecided at
that point, the agent applies the documented default and records it here.

| ID | Question (short) | Default | Decision | Date | Needed by |
| --- | --- | --- | --- | --- | --- |
| Q1 | Reject non-executable plans at run creation? | No (only Apply validates) | **Yes, reject**: 422 `plan_not_executable` with Apply's issue list (no day-count rule); library plans stay permissive. T2.2 builds `validate_executable`, T3.3 reuses it | 2026-11-25 | T2.2 |
| Q2 | Microcycle length changes out of scope for v1? | Yes | open | | T3.3, T4.3 |
| Q3 | Rebind recoverable missed sessions? | Yes | open | | T3.3 |
| Q4 | Analysis prescription with changed set structure: discard or carry loads by role? | Discard and report | open | | T3.4 |
| Q5 | Demo seed `0001_execution_demo.sql` after 0019 | Guard it so it refuses to run | **Default**: guard the seed so it refuses to run once 0019 is applied; plan 6's revision 25 stays | 2026-11-25 | T2.1 |

---

## Deviations from the design

Any intentional difference between the code and docs `00`–`07`. Small local adjustments are allowed
when recorded here (one row each, details in the task's handoff file); contract changes must also
update the affected document section.

| Date | Task | Doc § | Deviation | Reason | Docs updated? |
| --- | --- | --- | --- | --- | --- |
| 2026-11-25 | T0.1 | 06 T0.1 | `snapshot_tables` is async, has an optional `where` filter and prefixes the row count; the harness only accepts a database container started by `test_db.sh` | Async harness connection; run-filtered snapshots; never touch another database | Not needed (handoff/T0.1.md) |
| 2026-11-25 | T0.2 | 06 T0.2, T2.2, T3.1; 07 T-REG | All six characterisation tests are `fixed by T2.2`; T2.2 removes every marker, T3.1 none | They edit the library plan, so run isolation alone fixes R1–R5 as written (verified with simulated isolation) | No (handoff/T0.2.md) |
| 2026-11-25 | T0.2 | 02 §4.1 | The preflight audits only runs without `run_plan_id` | 0019 converts only those; new runs must not block a deploy | No (handoff/T0.2.md) |
| 2026-11-25 | T0.2 | 06 T0.2 | Preflight verified on the 2026-11-25 dump, not 2026-11-19 | The harness restores the newest dump | Not needed |
| 2026-11-25 | T1.2 | 07 T-API-PLANS-03, 04 §2 | Library plan with runs → **409** `PlanInUseError` ("Plan N is still used by a plan run"), not 204; T2.2 turns the test into 204 | Runs reference library rows until T2.2 (new runs) and 0019 (old runs); the task asked for a 4xx instead of 500 | No (handoff/T1.2.md) |
| 2026-11-25 | T1.2 | 02 §3.1, 07 T-IMM-03 | `load_revision_rows`/`copy_revision` are module-level functions; header adds `revision_status`; `PlanRevisionNotFoundError` (404); fingerprint uses the effective `load_step_kg` and catalog ids, has `include_progression_ids`; T-IMM-03 scans all of `src/agonez_api` and lists `delete_plan_image` and the identity update; duplicate names count library plans only | Execution needs the functions without a repository; a GET→PUT of the editor must not look like an unapplied change; T5.1 compares with fresh progression ids | No (handoff/T1.2.md) |
| 2026-11-28 | T2.2 | 02 §3.2, §3.3 | `RunPlanRepository.lock_library_source` (step 1 of §3.3) + `create_run_plan(connection, *, source: Row)` instead of `source_revision_id`; `not_executable(code, issues)` beside them; the repository is built by `ExecutionRepository`, not `app.py` | Read the source once under its `FOR SHARE` lock; one error builder for creation and Apply | No (handoff/T2.2.md) |
| 2026-11-28 | T2.2 | 03 §3, 04 §2 | Issue paths: plan-level `days`, workout `days.<d>.workout_unit`, slot and set issues at the slot path; error `message` summarises the first three issues; `plan_revision_not_library` has `details {plan_revision_id, plan_id}`; unknown revision stays 404 `plan_revision_not_found` | The New Run screen shows `message` as is; the documented path prefix is what the editor maps | No (handoff/T2.2.md) |
| 2026-11-28 | T2.2 | 06 T2.2 (tests) | `live_execution_api_scenarios.py` starts its throwaway run from an executable copy of the demo plan; T1.1's `test_existing_rows_and_todays_writers_get_the_defaults` now expects run creation to write `run_plan_id` and track keys | Demo plan 6 is not executable (Q1); the old test pinned pre-T2.2 creation | No (handoff/T2.2.md) |
| 2026-11-28 | T2.1 | 07 T-API-PLANS-03, 06 T2.2 tests | T2.2's legacy-run tests run on the pre-0019 database (`before_migration`): `test_api_plans_03_…` split into the API-created half (converted template) and `test_api_plans_03_a_legacy_run_still_refuses_the_delete_before_0019`; `test_deleting_a_legacy_run_keeps_its_library_plan` marked. (The pre-T2.2 test stand-in of the first T2.1 commit was removed at the rebase.) | A run without `run_plan_id` cannot exist after 0019 | Not needed (handoff/T2.1.md) |
| 2026-11-28 | T2.1 | 06 T1.1, 07 | `test_existing_rows_and_todays_writers_get_the_defaults` and `test_run_ownership_constraints` (T1.1) run on the pre-0019 database (`before_migration` marker) | They assert the state between 0018 and 0019, which 0019 ends by design | Not needed |
| 2026-11-28 | T2.1 | 06 T2.1, 07 T-MIG | Verified on the 2026-11-28 dump (newest, records 0018) and 2026-11-25, not 2026-11-19; same 7 legacy runs and acceptance facts, no id adjusted. "Before 0019" dumps are chosen dynamically: newest dump whose migrations table lacks 0019 | The harness restores the newest dump; a converted backup committed later must not break the tests | Not needed |
| 2026-11-28 | T2.1 | 02 §4.2, §4.3 | 0019 also locks the plans/exec tables (EXCLUSIVE); the reference map records `workout_plan` and `plan_revision` rows too (not the draft copy), PK + entity CHECK; `released_at` = midnight UTC of the first microcycle start; raises if a run's revisions span two plans; verification requires every F1–F13 reference of **every** run to lie in the run's own run plan | Conceptual SQL made concrete; fail safe on unexpected data | No (handoff/T2.1.md) |
| 2026-11-25 | T1.1 | 02 §2 | `copy_revision_tree` also rejects NULL arguments and missing revisions, locks the target revision, raises with SQLSTATEs 22004/P0002/55000; map entities are `day`, `workout_unit`, `exercise_slot`, `exercise_variant`, `set_infra` (target muscles unmapped); tests copy every non-empty template revision (only one is RELEASED) | Defensive, distinguishable errors; §2 SQL is conceptual; the dump has a single RELEASED revision | Not needed (handoff/T1.1.md) |

---

## Handoff notes

One file per finished task in [`handoff/`](handoff/) (`handoff/T0.1.md`, …), written by the agent from
[`handoff/TEMPLATE.md`](handoff/TEMPLATE.md). Separate files keep parallel branches free of merge
conflicts. Before starting, an agent reads the handoff files of every task its own task depends on.

Finished tasks:

- [T0.1](handoff/T0.1.md) — DB-backed integration test harness (merged 2026-11-25, `dcda3c9`).
- [T0.2](handoff/T0.2.md) — characterisation tests and 0019 preflight (merged 2026-11-25, `e99336e`;
  preflight returns zero rows on the 2026-11-25 dump).
- [T1.1](handoff/T1.1.md) — migration 0018 and `plans.copy_revision_tree` (merged 2026-11-25,
  `e66f5b4`; about 15–50 ms at start-up).
- [T1.2](handoff/T1.2.md) — plans module run-plan aware: `load_revision_rows`, `copy_revision`,
  `definition_fingerprint`, scope guards, artifact fields, T-IMM-03 allow-list (merged 2026-11-25,
  `64ce51f`).
- [T2.2](handoff/T2.2.md) — every new run owns a run plan (r1 RELEASED, r2 DRAFT);
  `validate_executable` and 422 `plan_not_executable`; deleting a run deletes its run plan; all six
  T0.2 tests pass (merged 2026-11-28, `227d3ce`).
- [T2.1](handoff/T2.1.md) — migration 0019 (legacy runs → run plans), seed guard (Q5),
  `before_migration` test marker (2026-11-28 on `impl/T2.1-convert-legacy-runs`, rebased on
  `e79fc1d`; migration reviewed, **not merged**; 0.35–0.43 s at start-up on the 2026-11-28 dump).

## Where things are recorded

Nothing lives only in a chat. Whoever learns something that changes what a later agent must do
writes it down here or in the design, in the same commit:

| What | Where |
| --- | --- |
| Progress, order, "start X only after Y" | "Next up", the task board and the merge-order table in this file; 06 if a task's dependencies change |
| A decision on an open question | Decisions log in this file (and the affected doc section) |
| Code that intentionally differs from the design | Deviations table in this file; the affected doc section if a contract changes |
| Instructions for one specific later task | `AGENT_PROMPTS.md` §4 task notes, or "Next up" notes |
| What a finished task built, how to use it, pitfalls | `handoff/<task>.md` |

## Merge rules

- One task = one short-lived branch `impl/<task>-<slug>` in its own worktree = one commit (or a few)
  = one review.
- After review (and the gate, if the merge-order table lists one): rebase the branch onto `master`, run
  the suites again, then fast-forward `master` in `/home/agonez` (`git merge --ff-only impl/…`, with a
  clean working tree there) and push. Then delete the task branch and its worktree.
- Merge strictly in the merge-order table's order; parallel work waits for its turn.
- A migration file is immutable once it is on `master` (it may be deployed at any moment); fix it with
  a new migration.
- Two parallel branches may both edit the task board above. Adjacent table rows conflict in git:
  resolve by keeping both rows' updates.
- Docs-only changes (this folder) are safe on `master` at any time: `redeploy.sh` builds only `be/` and
  `web-fe/`.

---

## Environment facts (verified 2026-11-22)

- **Production runs on this machine.** PostgreSQL container `agonez-db` (host port from `MINA`) and the
  API container `be-atlas-api-1`. `./redeploy.sh` builds from the working tree of `/home/agonez`, and
  the API applies pending migrations at start-up. Agents never deploy, never run migrations against
  production and never write to it.
- **Migrations are immutable once applied** (`migrations/runner.py` refuses changed checksums). Treat a
  migration as immutable as soon as it is on `master`.
- **Agents work in git worktrees, not in `/home/agonez`** (switching branches there changes what a deploy
  would build).
  - Backend in a worktree: `cd <worktree>/be && /home/agonez/be/.venv/bin/python -m pytest`. pytest's
    `pythonpath = ["src"]` puts the worktree code ahead of the editable install, which points at
    `/home/agonez/be/src`. Lint: `/home/agonez/be/.venv/bin/ruff check .`, types:
    `/home/agonez/be/.venv/bin/mypy src`.
  - Frontend in a worktree: run `npm ci` in `<worktree>/web-fe` first (`node_modules` is not shared).
- Baseline suites (2026-11-28, after T2.2, dump `agonez_db_backup_2026-11-28.sql`): backend 189
  passed, 50 skipped (the integration tests, without the URL); `pytest -m integration` 49 passed,
  1 skipped (T1.1's rollback test: the newest dump already records 0018), no xfails; web 166
  passed. `ruff` and `mypy src` are green.
- Library plan 6 (the demo plan "5x week, Push-Pull-Legs…", run 1 "Execution Demo"; revisions 6
  and RELEASED 25) has 5 DEFAULT variants without sets, so it is not executable: from T2.2 on, new
  runs cannot be started from it (run 1 keeps working). Every other library revision (plans 10, 14,
  15, 17, 18, 19, 20, 26) is executable (checked on the 2026-11-28 dump by the agent and in review).
- Since T2.2, each new run's header and the Run manager show the run plan's own code (a new
  `P0xx`, same name) until T3.1/T4.5; each run plan uses a plan id, so new My Plans codes skip
  numbers.
- Production runs migration 0018 (applied 2026-11-25 21:42 UTC, verified read-only). The newest
  committed dump, `agonez_db_backup_2026-11-28.sql`, records 0018 (so T1.1's rollback test skips
  on it) and still holds the 7 legacy runs.
- On the T2.1 branch (2026-11-28, rebased on `e79fc1d`): backend 189 passed, 67 skipped;
  `pytest -m integration` 66 passed, 1 skipped (67 passed on the 2026-11-25 dump).
- The demo seed `migrations/seeds/0001_execution_demo.sql` has not run on the current schema since
  0009 (`client_uuid`); since T2.1 it also refuses to run once 0019 is recorded.
- Integration tests: `eval "$(scripts/test_db.sh)"`, `pytest -m integration`, `scripts/test_db.sh stop`
  (from `be/`; details in `be/README.md`).
- `psql` is not installed on the host. Integration tests restore the newest `agonez_db_backup_*.sql`
  through `psql` inside a disposable `postgres:15` container (T0.1). The dump's owner role is
  `kartezjusz`; it already records migrations up to 0017.
- Docker is available to agents.
