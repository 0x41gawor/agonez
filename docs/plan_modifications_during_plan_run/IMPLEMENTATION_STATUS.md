# Implementation Status — Plan Modifications During a Plan Run

The **single source of truth for progress**. Every agent reads this file first and updates it as the
last step of its task. Humans pick the next task from "Next up" and paste the matching prompt from
[AGENT_PROMPTS.md](AGENT_PROMPTS.md).

Last updated: 2026-11-25 — T0.2 in review (preflight: zero rows). Next: review and merge T0.2 (#2),
then T1.1 (#3).

---

## Next up

| Order | Task | Can run in parallel with | Notes |
| --- | --- | --- | --- |
| 1 | Review **T0.2** (merge #2) · **T1.1** migration 0018 (merge #3) | each other | T0.2 is in review; merge it before T1.1. T1.1 reads [handoff/T0.1.md](handoff/T0.1.md) first. |
| 2 | T1.2 plans module | T2.1 *development* (merges later, after T2.2 and T6.2) | T2.1 needs Q5 decided (default applies otherwise). |
| 3 | T2.2 run creation with run plans | — | Needs Q1. Removes **all six** T0.2 xfail markers ([handoff/T0.2.md](handoff/T0.2.md)). |

Update this table whenever a task finishes.

---

## Merge order on master

Everything lands on `master`, one task at a time, in this order; **every commit on `master` must be
deployable** (details and reasons: `06-implementation-roadmap.md` → "Working on master"). The human
deploys with `./redeploy.sh` from `/home/agonez`; agents never deploy.

| # | Task(s) | Gate before merging | Milestone | Merged |
| --- | --- | --- | --- | --- |
| 1 | T0.1 | review | A | ✓ `dcda3c9` 2026-11-25 |
| 2 | T0.2 | review | A | |
| 3 | T1.1 | review | A | |
| 4 | T1.2 | review | A | |
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
| T0.2 | Characterisation tests + preflight | T0.1 | review | `impl/T0.2-characterisation-preflight` | branch head | 2026-11-25 |
| T1.1 | Migration 0018 + `plans.copy_revision_tree` | T0.1 | ready | | | 2026-11-25 |
| T1.2 | Plans module: loader, copy, fingerprint, scope guards | T1.1 | todo | | | |
| T2.1 | Migration 0019: convert legacy runs | T1.1, T0.2, T2.2 (merge), T6.2 (merge) | todo | | | |
| T2.2 | Run creation/deletion with run plans | T1.2 | todo | | | |
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
| T5.1 | Promotion backend (duplicate with body) | T1.2 | todo | | | |
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

---

## Handoff notes

One file per finished task in [`handoff/`](handoff/) (`handoff/T0.1.md`, …), written by the agent from
[`handoff/TEMPLATE.md`](handoff/TEMPLATE.md). Separate files keep parallel branches free of merge
conflicts. Before starting, an agent reads the handoff files of every task its own task depends on.

Finished tasks:

- [T0.1](handoff/T0.1.md) — DB-backed integration test harness (merged 2026-11-25, `dcda3c9`).
- [T0.2](handoff/T0.2.md) — characterisation tests and 0019 preflight (in review; preflight returns
  zero rows on the 2026-11-25 dump).

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
- Baseline suites (2026-11-25, with T0.2): backend 164 passed, 21 skipped (the integration tests,
  without the URL); `pytest -m integration` 15 passed, 6 xfailed; web 166 passed. `ruff` and
  `mypy src` are green (the
  `plans/schemas.py:97` type error that T0.1 reported was fixed on `master` right after the merge).
- Integration tests: `eval "$(scripts/test_db.sh)"`, `pytest -m integration`, `scripts/test_db.sh stop`
  (from `be/`; details in `be/README.md`).
- `psql` is not installed on the host. Integration tests restore the newest `agonez_db_backup_*.sql`
  through `psql` inside a disposable `postgres:15` container (T0.1). The dump's owner role is
  `kartezjusz`; it already records migrations up to 0017.
- Docker is available to agents.
