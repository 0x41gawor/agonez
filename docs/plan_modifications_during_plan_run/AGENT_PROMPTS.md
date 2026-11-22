# Agent Prompts and Workflow

How to run the implementation with coding agents over several days without keeping state in your
head. State lives in [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) (board, decisions,
deviations) and [`handoff/`](handoff/) (one file per finished task).

## Workflow per task

```text
1. Pick the task      IMPLEMENTATION_STATUS.md → "Next up" (check its decisions are recorded).
2. Start an agent     new session in its own git WORKTREE; paste the Implementation prompt below.
3. Review             second session (or /code-review) with the Review prompt.
4. Fix                send findings back to the implementing session (same context).
5. Merge              merge the task branch into its integration branch (Releases table); push.
6. Gate               at the end of a release, run its gate task (T6.2 for B, T6.1 for C) and deploy
                      yourself from master with ./redeploy.sh.
```

Rules of thumb:

- **One task per session.** A fresh session per task keeps context small; everything it needs is in
  the docs and the handoff files.
- **Always a worktree.** `/home/agonez` is what `redeploy.sh` builds, and the API runs migrations at
  start-up. Never let an agent switch branches there.
- **Review is mandatory** for T2.1, T3.1, T3.3, T3.4 (data conversion, identity, Apply). It is
  recommended for everything else.
- Use your strongest model/effort for T2.1, T3.1, T3.3, T3.4. Mechanical tasks (T0.2, T4.6, T2.3) can
  use a cheaper setup.
- If a session is interrupted, start a new one with the Resume prompt; the branch and the status doc
  carry the state.

Base branch per task (fill `{BASE}`):

| Tasks | `{BASE}` |
| --- | --- |
| T0.1, T0.2, T1.1, T1.2, T5.1 (if shipped in A) | `master` |
| T2.1, T2.2, T2.3, T3.1, T6.2 | `release/run-plans-b` (create it from `master` when the first of these starts) |
| T3.2, T3.3, T3.4, T3.5, T5.1 (if shipped in C), T6.1 | `release/run-plans-c` (from `master` after release B is deployed) |
| T4.1–T4.6, T5.2 | `release/run-plans-d` (from `master`; rebase onto C when it lands) |

---

## 1. Implementation prompt (template)

Replace `{TASK}`, `{SLUG}` and `{BASE}`. Add the task-specific notes from §4 at the end.

```text
Implement task {TASK} of the "Plan modifications during plan run" feature in this repository.

READ FIRST, in this order:
1. docs/plan_modifications_during_plan_run/IMPLEMENTATION_STATUS.md — board, decisions (Q1–Q5),
   deviations, environment facts.
2. The handoff files in docs/plan_modifications_during_plan_run/handoff/ for every task {TASK}
   depends on.
3. docs/plan_modifications_during_plan_run/README.md.
4. docs/plan_modifications_during_plan_run/06-implementation-roadmap.md, section {TASK} — this is
   your specification: objective, files, expected changes, acceptance criteria, required tests.
5. Every document section that {TASK} references (01/02/03/04/05) and the test IDs it lists in
   07-test-matrix.md.
Then inspect the real code you will change before editing it.

BRANCH: work in your own git worktree on branch impl/{TASK}-{SLUG}, based on {BASE}. Before any
change, check that {BASE} is an ancestor of HEAD; if it is not and you have no changes yet, run
`git reset --hard {BASE}`. Never check out branches in /home/agonez itself.

SCOPE:
- Implement exactly {TASK}. Touch only the files the task lists, plus their tests. Do not start later
  tasks.
- The architecture is accepted. Do not redesign it. If the specification is wrong or impossible
  against the real code: make the smallest local adjustment and record it as a deviation, or, if no
  small adjustment exists, stop and explain the problem instead of inventing a different design.
- If an open decision (Q1–Q5) affects you and is still "open", apply its documented default and
  record that in the Decisions log.

SAFETY (non-negotiable):
- Production PostgreSQL (container `agonez-db`; the DSN built from NOME/AGANDSKODE/MINA) and the
  production API container run on this machine. Never write to them, never run migrations against
  them, never run ./redeploy.sh, never restore a backup into them. Integration tests use only
  AGONEZ_TEST_DATABASE_URL (a disposable container).
- Migrations that might already be deployed are immutable; fix them with a new migration file.
- Do not push. Do not modify unrelated code.

DEFINITION OF DONE:
- Every acceptance criterion and required test of {TASK} passes.
- Backend (from <worktree>/be): /home/agonez/be/.venv/bin/ruff check . ;
  /home/agonez/be/.venv/bin/mypy src ; /home/agonez/be/.venv/bin/python -m pytest
  (and `-m integration` once the T0.1 harness exists).
- Frontend (from <worktree>/web-fe, after `npm ci`): npm run lint ; npm run typecheck ; npm test.
- Report the exact commands and results. If anything fails, say so; do not claim success.

FINISH:
1. Write docs/plan_modifications_during_plan_run/handoff/{TASK}.md from handoff/TEMPLATE.md.
2. In IMPLEMENTATION_STATUS.md: update your task row (status `review`, branch, commit, date), the
   "Next up" table, the finished-tasks list, the Decisions log and the Deviations table if they apply.
   If you changed a contract, update the affected section of 02/03/04/05 too.
3. Commit code, tests, handoff file and status update together. Use a conventional message
   ("feat(be): …", "test(be): …", "feat(web-fe): …"); put "{TASK}" in the body.
4. Final reply: what was done, test results, deviations, open risks, suggested next task.
```

---

## 2. Review prompt (template)

Run in a separate session (read-only is enough), or use `/code-review` on the branch and add the
checklist below.

```text
Review branch impl/{TASK}-{SLUG} against {BASE} (git diff {BASE}...impl/{TASK}-{SLUG}) for task {TASK}
of the "Plan modifications during plan run" feature.

Specification: docs/plan_modifications_during_plan_run/06-implementation-roadmap.md section {TASK},
the document sections it references, and the test IDs it lists in 07-test-matrix.md. Context:
IMPLEMENTATION_STATUS.md and handoff/{TASK}.md.

Check, and report findings ranked by severity with file:line:
1. Each acceptance criterion: met / not met, with evidence.
2. Each required test exists and asserts the behaviour (not merely that code runs).
3. Scope: no changes outside the task's files without a recorded deviation; no later-task work.
4. Invariants in 01 §2 (I1–I10) and D16: no new UPDATE/DELETE on plans.* outside the allow-list;
   executed sessions and athlete cancellations untouched where relevant.
5. Migrations: commented columns/functions, no destructive data changes outside the specification,
   safe for the release they belong to.
6. Safety: nothing touches the production DB/containers; no deploy scripts run.
7. The handoff file and status doc are truthful and complete.
Run the Definition-of-done commands yourself and include the results. Do not fix anything; only
report.
```

---

## 3. Resume prompt

```text
Resume task {TASK} of the "Plan modifications during plan run" feature. It was started earlier on
branch impl/{TASK}-{SLUG} (base {BASE}). Read IMPLEMENTATION_STATUS.md, the roadmap section {TASK},
and `git log {BASE}..HEAD` plus `git status`/`git diff` on that branch to reconstruct the state.
Then continue with the Implementation prompt's rules (scope, safety, definition of done, finish).
Start by summarising what is already done and what remains.
```

---

## 4. Task-specific notes (append to the Implementation prompt)

| Task | Add to the prompt |
| --- | --- |
| T0.1 | Docker is available; `psql` is not installed on the host — restore the dump with `docker exec -i <container> psql`. Create the dump's owner role (`kartezjusz`) before restoring. The dump already records migrations up to 0017. Keep integration tests opt-in; the default `pytest` run must still show 162 passed. |
| T0.2 | Write target-behaviour tests marked `xfail(strict=True)` with the fixing task in `reason`. Preflight SQL must be read-only. |
| T1.1 | Migration 0018 must be additive and safe for the current runtime (release A). Test the copy function against real revisions from the restored backup. |
| T1.2 | Introduce the T-IMM-03 static allow-list test listing today's writers. No behaviour change for library plans except the delete-500 fix. |
| T2.1 | Highest-risk task. Run the conversion only against restored backups in disposable containers. The migration runs in the runner's single transaction: any preflight hit or error must abort it and leave the database unchanged. Follow Q5 for the demo seed. Mandatory review. |
| T2.2 | Must ship with T2.1 and T3.1 (release B). Follow Q1. |
| T2.3 | Capture the "before" read models on the same code version with 0018 only, then apply 0019; document the normaliser. |
| T3.1 | Large but mechanical; finish with the grep guard (T-INT-ID-08) green. Re-run T2.3 afterwards: only additive fields may differ. Mandatory review. |
| T3.3 | Follow Q2/Q3. Concurrency tests need two real connections and the advisory lock. Mandatory review. |
| T3.4 | Follow Q4. Dry run must leave every table hash unchanged. Mandatory review. |
| T4.x | Work against fixtures from T4.1 if the backend is not ready. Add every new i18n key to all 11 locales (English text copied) so the parity test stays green. |
| T6.2 | Prepare the scripted part (preflight, migration timing, T-MIG/golden runs, smoke scripts). Steps needing production access (a fresh `db_backup.sh` dump, the rollback drill decision) are done by the human; the agent writes a checklist report with the commands to run. |
| T6.1 | Runs only against a disposable deployment restored from a backup with release B applied. The script must refuse to run without `RUN_PLAN_ALLOW_DESTRUCTIVE_TEST=1`. |

---

## 5. Ready-to-paste: T0.1

```text
Implement task T0.1 of the "Plan modifications during plan run" feature in this repository.

READ FIRST, in this order:
1. docs/plan_modifications_during_plan_run/IMPLEMENTATION_STATUS.md — board, decisions,
   environment facts.
2. docs/plan_modifications_during_plan_run/README.md.
3. docs/plan_modifications_during_plan_run/06-implementation-roadmap.md, section T0.1 — your
   specification.
4. docs/plan_modifications_during_plan_run/07-test-matrix.md (intro and §2) for how later tasks will
   use the harness (snapshot_tables, builders, frozen clock).
Then inspect be/src/agonez_api/migrations/runner.py, core/config.py, core/database.py, app.py,
modules/execution/service.py (injectable `today`), and
be/tests/live_mobile_execution_api_scenarios.py (mobile start/ops/finalize payloads).

BRANCH: work in your own git worktree on branch impl/T0.1-integration-harness, based on master.
Before any change, check that master is an ancestor of HEAD; if not and you have no changes yet, run
`git reset --hard master`. Never check out branches in /home/agonez itself.

SCOPE: implement exactly T0.1: be/scripts/test_db.sh, be/tests/integration/{conftest.py,
builders.py,test_harness_smoke.py}, the `integration` pytest marker in be/pyproject.toml, and a
"Integration tests" section in be/README.md. No application code changes. The architecture is
accepted; record any small deviation instead of redesigning.

SAFETY (non-negotiable): production PostgreSQL (container `agonez-db`; DSN from NOME/AGANDSKODE/MINA)
and the production API container run on this machine. Never connect to them, never run migrations
against them, never run ./redeploy.sh. Use only a disposable postgres:15 container that your script
starts on 127.0.0.1 with a throwaway password. Do not push.

TASK NOTES: Docker is available; psql is NOT installed on the host — restore the newest
agonez_db_backup_*.sql from the repo root with `docker exec -i <container> psql -v ON_ERROR_STOP=1`.
Create the dump's owner role (kartezjusz, from its OWNER TO statements) before restoring. The dump
already records migrations up to 0017, so run_migrations() applies only newer ones. Settings has no
DSN field: build it from aliases (NOME, AGANDSKODE, MINA, DB_HOST, DB_NAME). A pool passed to
create_app() is not opened by its lifespan: open/close it in the fixture. Keep integration tests
opt-in (skipped without AGONEZ_TEST_DATABASE_URL); the default pytest run must still be 162 passed.

DEFINITION OF DONE (from <worktree>/be): /home/agonez/be/.venv/bin/ruff check . ;
/home/agonez/be/.venv/bin/mypy src ; /home/agonez/be/.venv/bin/python -m pytest ;
scripts/test_db.sh then AGONEZ_TEST_DATABASE_URL=… /home/agonez/be/.venv/bin/python -m pytest -m
integration. Report exact commands and results; stop the disposable container afterwards.

FINISH: write docs/plan_modifications_during_plan_run/handoff/T0.1.md from handoff/TEMPLATE.md;
update IMPLEMENTATION_STATUS.md (T0.1 row → review with branch/commit/date, "Next up", finished
tasks); commit everything together as "test(be): add DB-backed integration test harness" with
"T0.1" in the body. Final reply: summary, test results, deviations, next task.
```
