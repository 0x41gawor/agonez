# Plan Modifications During a Plan Run

Architecture and implementation handoff for letting an athlete change the training definition of an
**active plan run** without starting a new run, while keeping training history intact.

Status: design complete, nothing implemented. Audit baseline: commit `f5b1960`, schema `0017`,
live data checked read-only on 2026-11-22.

## The feature in one paragraph

Every plan run gets its own copy of the chosen plan, the **run plan**. The athlete edits it in the
existing PlanCreator, opened from a new **Run plan** tab in Execution. Saved changes to the definition
(days, workouts, exercises, sets) stay in a working copy until the athlete presses **Apply to run**;
the plan's name, description, colour and cover are not versioned and update as soon as they are
saved. Apply freezes the working copy as a new immutable
revision. From that moment every workout that has not been executed follows the new revision.
Completed and in-progress workouts, and missed or cancelled history, stay exactly as they were. The
run plan can be saved back to My Plans as a new, independent plan. My Plans never shows run plans,
and editing a library plan never affects a run.

## Main architectural decision

**Run plans are ordinary `plans.workout_plans` rows with `scope = 'run'`, owned by
`exec.plan_runs.run_plan_id`. They reuse the existing revision statuses: one `DRAFT` working copy plus
immutable `RELEASED` applied revisions.**

Execution keeps its existing structure: upfront sessions, lazy prescription snapshots, tracks. Three
things change:

1. Sessions bind only to immutable applied-revision rows (never to mutable drafts).
2. Track identity moves from positional keys (`day:N`/`slot:N`) to **lineage keys**: UUIDs on workout
   units and exercise slots that survive revision copies.
3. A single atomic **Apply** operation rebinds pending sessions and handles their already-saved
   prescriptions.

No new domain tables, no versioning subsystem, no periodisation, no second editor.

Why: today runs point straight at the mutable library draft. Library edits leak into runs, runs from
one plan share rows, structural deletes fail with HTTP 500, and positional track keys silently
re-target progression after a reorder. The original Execution schema already planned for revision
transitions (`microcycles.plan_revision_id`, `plan_revision_changed` events) but never got a write
path. This design completes that model with the smallest set of changes.

## Reading order

| # | Document | Read when |
| --- | --- | --- |
| 1 | [00-current-state-audit.md](00-current-state-audit.md) | You need the evidence: tables, FKs, code paths, verified defects (R1–R8). |
| 2 | [01-domain-and-architecture.md](01-domain-and-architecture.md) | Always. Vocabulary, invariants I1–I10, decisions D1–D16, v1 limitations (§10). |
| 3 | [02-database-and-backend.md](02-database-and-backend.md) | Backend/database tasks: migrations 0018/0019, copy function, module changes, locking, rollback. |
| 4 | [03-execution-reconciliation.md](03-execution-reconciliation.md) | Apply/identity tasks: algorithm, behaviour matrix, prescription rules, invariants. |
| 5 | [04-api-contracts.md](04-api-contracts.md) | Any API or frontend task. |
| 6 | [05-frontend-ux.md](05-frontend-ux.md) | Frontend tasks. |
| 7 | [06-implementation-roadmap.md](06-implementation-roadmap.md) | Picking up a task. |
| 8 | [07-test-matrix.md](07-test-matrix.md) | Writing tests; test IDs referenced by tasks. |
| — | [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) | **Before and after every task**: board, decisions Q1–Q5, deviations, environment facts. |
| — | [AGENT_PROMPTS.md](AGENT_PROMPTS.md) | Starting, reviewing or resuming an agent session; ready-to-paste T0.1 prompt. |
| — | [handoff/](handoff/) | One handoff note per finished task. |

## Implementation phases

| Phase | Outcome | Tasks |
| --- | --- | --- |
| 0 Safety net | DB-backed integration harness; current defects pinned as xfail specs; migration preflight. | T0.1, T0.2 |
| 1 Backend foundation | Schema (scope, lineage, ownership) + `plans.copy_revision_tree`; plans module run-aware; library delete-500 fixed. | T1.1, T1.2 |
| 2 Migration / compatibility | Every existing run converted to its own run plan; new runs copy their plan; golden comparison proves no read-model change. | T2.1, T2.2, T2.3 |
| 3 Execution reconciliation | Lineage identity everywhere; run-plan state/discard; Apply with rebinding, prescription rebase, dry run; exercise-aware analytics. | T3.1 – T3.5 |
| 4 Frontend integration | Run plan tab, PlanCreator run context, apply dialog, peripheral updates, translations. | T4.1 – T4.6 |
| 5 Library promotion | "Save as new plan" via the existing duplicate endpoint. | T5.1, T5.2 |
| 6 End-to-end validation | Gates: migration rehearsal before 0019 merges; live lifecycle script before the UI is enabled. | T6.2, T6.1 |

Everything lands on `master` in a fixed order in which **every commit is deployable** (`06`
"Working on master"): run creation copies plans before migration 0019 converts the old runs, the
identity refactor follows the conversion, the Apply backend lands dormant, and the UI lands behind
`RUN_PLAN_UI_ENABLED = false` until the end. Gates: the migration rehearsal T6.2 before 0019 merges;
the live lifecycle script T6.1 and a manual walkthrough before the UI is enabled.

## Intentional v1 limitations

- **Fixed microcycle duration** — the run plan's day count cannot change; for another cycle length,
  save the run plan as a new plan and start a new run.
- **Workout re-dating from the next microcycle** — moving a workout to another day re-dates its
  sessions only from the next microcycle; this week's dates stay, and athlete cancellations are never
  moved.
- **No scheduled future modifications** — Apply always takes effect immediately; there are no
  effective-from dates.

Details and workarounds: `01` §10.

## Dependencies

- PostgreSQL 15 (`gen_random_uuid()` is built in).
- A disposable PostgreSQL to run integration tests (Docker, `be/scripts/test_db.sh` from T0.1) and the
  newest `agonez_db_backup_*.sql` in the repository root.
- No new Python or npm packages.
- Mobile app: no API shape changes; behaviour after an Apply relies on its existing handling of
  `prescription_changed` / `prescription_missing` on start (since commit `ae1f273`).

## Open decisions (affect implementation)

| ID | Question | Current default in the design | Affects |
| --- | --- | --- | --- |
| Q1 | Should run **creation** reject non-executable plans (empty workouts, slots without an exercise, exercises without sets), as Apply does? | Keep today's permissive creation. Only Apply validates. | T2.2 |
| Q2 | Changing the number of days (microcycle length) of a running plan. | Out of scope for v1. The day count is locked in run context and Apply rejects changes. | T3.3, T4.3 |
| Q3 | A *recoverable* missed session (one that can still be caught up) is rebound to the new revision, so catching it up runs the current definition. | Rebind. Status, date and adherence stay unchanged. | T3.3 |
| Q4 | A saved desktop prescription whose set structure changed: discard and report, or carry loads over by set role? | Discard and report, with the dry run showing it beforehand. | T3.4 |
| Q5 | The demo seed `migrations/seeds/0001_execution_demo.sql` binds a run directly to library revisions, and it left a RELEASED revision 25 in library plan 6. | Guard the seed so it refuses to run after 0019. Leave revision 25 in place (harmless). | T2.1 |

## Recommended next action

Assign **T0.1, the DB-backed integration test harness** (`06-implementation-roadmap.md`), using the
ready-to-paste prompt in [AGENT_PROMPTS.md](AGENT_PROMPTS.md) §5, and track progress in
[IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md). Every later
task depends on verifying lifecycle behaviour against a real schema with real constraints, and none
exists today. T0.2 (characterisation tests and preflight) and T1.1 (migration 0018) can start as soon
as it lands, in parallel.
