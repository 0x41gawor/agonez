# Implementation Status — Plan Modifications During a Plan Run

The **single source of truth for progress**. Every agent reads this file first and updates it as the
last step of its task. Humans pick the next task from "Next up" and paste the matching prompt from
[AGENT_PROMPTS.md](AGENT_PROMPTS.md).

Last updated: 2026-11-22 — initial version (design complete, nothing implemented).

---

## Next up

| Order | Task | Can run in parallel with | Notes |
| --- | --- | --- | --- |
| 1 | **T0.1** DB-backed integration test harness | — | Ready. No open decision affects it. |
| 2 | T0.2 characterisation + preflight · T1.1 migration 0018 | each other | After T0.1 is merged. |
| 3 | T1.2 plans module · T2.1 migration 0019 | each other | T2.1 needs Q5 decided (default applies otherwise). |

Update this table whenever a task finishes.

---

## Releases

A release is deployed by the human only (`./redeploy.sh` from `/home/agonez` on `master`). Agents never
deploy. Gates: `06-implementation-roadmap.md` → "Release gates".

| Release | Tasks | Integration branch | Gate | Status |
| --- | --- | --- | --- | --- |
| A | T0.1, T0.2, T1.1, T1.2 (+ T5.1 optional) | `master` (each task merged after review) | unit + integration suites green | not started |
| B | T2.1, T2.2, T2.3, T3.1 | `release/run-plans-b` — merge to `master` only after T6.2 passes | T6.2 (RB-01…RB-08) | not started |
| C | T3.2, T3.3, T3.4, T3.5 (+ T5.1) | `release/run-plans-c`, from `master` after B is deployed | T6.1 (E2E-01…06) | not started |
| D | T4.1–T4.6, T5.2 | `release/run-plans-d` (development may start early against mocks) | RD-01 + frontend suites | not started |

Why release branches for B–D: `master` is what `redeploy.sh` builds. Merging T2.1 (migration 0019)
alone would make the next deploy convert production data without the code that needs it.

---

## Task board

Status values: `todo` · `ready` (dependencies done) · `in progress` · `review` · `done` · `blocked`.

| Task | Title | Depends on | Status | Branch | Commit | Updated |
| --- | --- | --- | --- | --- | --- | --- |
| T0.1 | DB-backed integration test harness | — | ready | | | 2026-11-22 |
| T0.2 | Characterisation tests + preflight | T0.1 | todo | | | |
| T1.1 | Migration 0018 + `plans.copy_revision_tree` | T0.1 | todo | | | |
| T1.2 | Plans module: loader, copy, fingerprint, scope guards | T1.1 | todo | | | |
| T2.1 | Migration 0019: convert legacy runs | T1.1, T0.2 | todo | | | |
| T2.2 | Run creation/deletion with run plans | T1.2 | todo | | | |
| T2.3 | Conversion golden comparison | T2.1, T2.2 | todo | | | |
| T3.1 | Identity and binding refactor | T2.1, T2.2 | todo | | | |
| T3.2 | Run-plan state, revision read, discard | T2.2 | todo | | | |
| T3.3 | Apply: sessions, tracks, validation, concurrency | T3.1, T3.2 | todo | | | |
| T3.4 | Prescription rebase, impact, dry run | T3.3 | todo | | | |
| T3.5 | Exercise-identity analytics fixes | T3.1 | todo | | | |
| T4.1 | Frontend API client, types, routes, stubs | contract `04` | todo | | | |
| T4.2 | Run Plan tab | T4.1 | todo | | | |
| T4.3 | PlanCreator run context | T4.1 | todo | | | |
| T4.4 | Apply dialog | T4.1 | todo | | | |
| T4.5 | Peripheral Execution updates | T4.2, T3.5 | todo | | | |
| T4.6 | Translations | T4.2–T4.5, T5.2 | todo | | | |
| T5.1 | Promotion backend (duplicate with body) | T1.2 | todo | | | |
| T5.2 | Promote dialog | T5.1, T4.1, T4.2 | todo | | | |
| T6.2 | Release-B migration rehearsal (gate) | T0.2, T2.1, T2.2, T2.3, T3.1 | todo | | | |
| T6.1 | Live lifecycle scenario (release-C gate) | T3.2–T3.5, T5.1, B deployed | todo | | | |

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
| | | | | | |

---

## Handoff notes

One file per finished task in [`handoff/`](handoff/) (`handoff/T0.1.md`, …), written by the agent from
[`handoff/TEMPLATE.md`](handoff/TEMPLATE.md). Separate files keep parallel branches free of merge
conflicts. Before starting, an agent reads the handoff files of every task its own task depends on.

Finished tasks:

_None yet._

## Merge rules

- One task = one branch `impl/<task>-<slug>` = one commit (or a few) = one review.
- After review, merge the task branch into its integration branch (Releases table). Release-A tasks
  merge into `master`.
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
- **Migrations are immutable once applied** (`migrations/runner.py` refuses changed checksums). After
  0018 is deployed, fixes need a new migration file.
- **Agents work in git worktrees, not in `/home/agonez`** (switching branches there changes what a deploy
  would build).
  - Backend in a worktree: `cd <worktree>/be && /home/agonez/be/.venv/bin/python -m pytest`. pytest's
    `pythonpath = ["src"]` puts the worktree code ahead of the editable install, which points at
    `/home/agonez/be/src`. Lint: `/home/agonez/be/.venv/bin/ruff check .`, types:
    `/home/agonez/be/.venv/bin/mypy src`.
  - Frontend in a worktree: run `npm ci` in `<worktree>/web-fe` first (`node_modules` is not shared).
- Baseline suites: backend 162 passed, web 166 passed.
- `psql` is not installed on the host. Integration tests restore the newest `agonez_db_backup_*.sql`
  through `psql` inside a disposable `postgres:15` container (T0.1). The dump's owner role is
  `kartezjusz`; it already records migrations up to 0017.
- Docker is available to agents.
