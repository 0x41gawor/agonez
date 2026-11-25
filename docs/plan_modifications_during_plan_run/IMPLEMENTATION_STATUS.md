# Implementation Status — Plan Modifications During a Plan Run

The **single source of truth for progress**. Every agent reads this file first and updates it as the
last step of its task. Humans pick the next task from "Next up" and paste the matching prompt from
[AGENT_PROMPTS.md](AGENT_PROMPTS.md).

Last updated: 2026-11-25 — T1.2 merged (#4): milestone A complete. Next: T2.2 (needs Q1) ∥ T5.1 ∥ T2.1 development (needs Q5).

---

## Next up

| Order | Task | Can run in parallel with | Notes |
| --- | --- | --- | --- |
| 1 | **T2.2** run creation with run plans | T2.1 *development* (merges later, after T2.2 and T6.2) · T5.1 | Needs Q1. Removes **all six** T0.2 xfail markers ([handoff/T0.2.md](handoff/T0.2.md)); turns T1.2's interim 409 test into 204 and extends the T-IMM-03 allow-list ([handoff/T1.2.md](handoff/T1.2.md)). |
| 2 | **T5.1** promotion backend | T2.2, Phase 3 | May merge any time after #4. Reuse `duplicate_plan` + `definition_fingerprint(…, include_progression_ids=False)`. |

Update this table whenever a task finishes.

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
| 5 | T2.2 | review | B | |
| 6 | T2.1 + T2.3 (stacked, merged together) | review + **T6.2**; take `db_backup.sh` before the first deploy containing 0019 | B | |
| 7 | T3.1 | review (mandatory) + T2.3 re-run | B | |
| 8 | T3.5, T3.2 | review | C | |
| 9 | T3.3 | review (mandatory) | C | |
| 10 | T3.4 | review (mandatory) | C | |
| — | T5.1 (any time after #4) | review | C | |
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
| T2.1 | Migration 0019: convert legacy runs | T1.1, T0.2, T2.2 (merge), T6.2 (merge) | todo | | | |
| T2.2 | Run creation/deletion with run plans | T1.2 | ready | | | 2026-11-25 |
| T2.3 | Conversion golden comparison | T2.1 (stacked) | todo | | | |
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
| T5.1 | Promotion backend (duplicate with body) | T1.2 | ready | | | 2026-11-25 |
| T5.2 | Promote dialog | T5.1, T4.1, T4.2 | todo | | | |
| T6.2 | Migration 0019 rehearsal (gate for #6) | T0.2, T2.2 merged; T2.1 + T2.3 branch | todo | | | |
| T6.1 | Live lifecycle scenario (gate for #12) | T3.2–T3.5, T5.1 merged | todo | | | |

---

## Decisions log

Open questions from `README.md`. Decide before the task in the last column starts. If undecided at
that point, the agent applies the documented default and records it here.

| ID | Question (short) | Default | Decision | Date | Needed by |
| --- | --- | --- | --- | --- | --- |
| Q1 | Reject non-executable plans at run creation? | No (only Apply validates) | open | | T2.2 |
| Q2 | Microcycle length changes out of scope for v1? | Yes | open | | T3.3, T4.3 |
| Q3 | Rebind recoverable missed sessions? | Yes | open | | T3.3 |
| Q4 | Analysis prescription with changed set structure: discard or carry loads by role? | Discard and report | open | | T3.4 |
| Q5 | Demo seed `0001_execution_demo.sql` after 0019 | Guard it so it refuses to run | open | | T2.1 |

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
- Baseline suites (2026-11-25, after T1.2): backend 174 passed, 37 skipped (the integration tests,
  without the URL); `pytest -m integration` 31 passed, 6 xfailed (the T0.2 tests); web 166 passed.
  `ruff` and `mypy src` are green.
- Production runs migration 0018 (applied 2026-11-25 21:42 UTC, verified read-only).
- Integration tests: `eval "$(scripts/test_db.sh)"`, `pytest -m integration`, `scripts/test_db.sh stop`
  (from `be/`; details in `be/README.md`).
- `psql` is not installed on the host. Integration tests restore the newest `agonez_db_backup_*.sql`
  through `psql` inside a disposable `postgres:15` container (T0.1). The dump's owner role is
  `kartezjusz`; it already records migrations up to 0017.
- Docker is available to agents.
