# Handoff: mobile context `readiness` must match the start's completeness check

- **From:** mobile-fe agent (Flutter app, Windows workstation)
- **To:** backend agent (linode-vps, `be/`)
- **Date:** 2026-10-25
- **Status:** request — please **assess feasibility and safety first**, report back,
  then implement only if your checks below come out clean.

## TL;DR

`GET /api/v1/mobile/context` can report a session's prescription as
`readiness: "ready"` while `POST /api/v1/mobile/workouts` for that same session and
version is refused with `422 prescription_incomplete`. The two use different rules for
"complete". Mobile needs one rule: **`ready` must mean "startable as is"**. A partially
analysed prescription must read as `missing`, which mobile already handles correctly by
preparing the plan-backed fallback before starting.

## The problem

Three places decide whether a session's prescription covers the whole plan, and they
disagree:

| Where | What it checks |
| --- | --- |
| Context readiness — `MobileExecutionService._session_summary` (`mobile_execution/service.py`, ~L544) over the sessions query in `MobileExecutionRepository.load_context` (`mobile_execution/repository.py`, ~L175–215) | `prescription_id` exists, `exercise_count > 0`, `set_count > 0`, `missing_load_count == 0`, `fallback_exercise_count == 0`. **No comparison with the plan structure.** |
| Start — `start_workout` in `mobile_execution/repository.py` (~L1203–1255) | `exercise_count == count(plans.exercise_slots)` and `set_count == count(DEFAULT-variant plans.set_infra_prescriptions)` for `session.source_plan_workout_unit_id`; otherwise `422 prescription_incomplete`. |
| Fallback preparation — `_ensure_fallback_prescription` (~L803–830) | Compares against its own `plan_exercises` / `plan_sets` lists; otherwise `422 fallback_unavailable`. |

Desktop saves analysis **one exercise at a time**
(`PUT /plan-runs/{id}/sessions/{id}/exercise-prescriptions/{trace}`, and an exercise can
also be deleted). So "analysis for 5 of 7 exercises, all with loads" is ordinary state.
Readiness reports it as `ready`; the start rejects it.

## Why it hurts on mobile

For a `ready` session the app starts **local-first**, which is what makes offline
training work:

1. It fetches the prescription (`GET .../prescription`), stores the workout on the
   phone, opens the workout screen, and queues `POST /workouts` for background sync.
2. The athlete trains and records sets.
3. In the background the server answers `422 prescription_incomplete`. The sync engine
   cannot recover from that: the workout is marked failed. Its recorded sets never reach
   the server, because operations are queued behind the start. It cannot be finalised,
   and it blocks starting another workout or switching plan runs on the phone.

The data is safe on the phone but stuck. For a session that reads `missing`, by
contrast, the app first calls `POST .../prescription/fallback`, which completes the
missing slots from plan targets while keeping analysed rows (`hybrid`), and then starts
with `allow_missing_loads=true`. That path works today.

(Off-schedule starts from the picker are server-first, and the app already retries them
once via the fallback on `prescription_incomplete`. The problem is the ordinary Home
start.)

## Reproduce it first

Please write this as a failing test before changing anything:

1. A scheduled session whose plan workout unit has ≥ 2 slots.
2. Save analysis (with loads) for only one of the slots.
3. `GET /mobile/context` → that session's `prescription.readiness` is `"ready"`.
4. `POST /mobile/workouts` with that session, its current `prescription_version` and
   `allow_missing_loads=false` → `422 prescription_incomplete`.

The expected result after the fix: step 3 returns `"missing"`. After
`POST .../prescription/fallback`, the start with `allow_missing_loads=true` succeeds and
the prescription's source is `hybrid`.

## What mobile needs

- **R1 · `ready` implies startable.** If the context says `ready`, starting that session
  with its current `prescription_version` and `allow_missing_loads=false` must not be
  refused with `prescription_incomplete` or `prescription_missing`. (Other refusals such
  as `prescription_changed`, `active_workout_exists` or schedule rules are fine; they
  are not about the prescription's content.)
- **R2 · Incomplete reads as `missing`.** Keep the existing enum (`ready | missing |
  not_applicable`); mobile already maps `missing` to "Start with plan targets" via the
  fallback endpoint. **No new enum value**, please.
- **R3 · One definition of "complete".** Readiness, the start check and fallback
  preparation should share one definition of the session's expected plan structure (a
  shared SQL CTE/function or a Python helper), so they cannot drift apart again. Keep
  `prescription_incomplete` in the start as a safety net.
- **R4 · Same rule for `alternatives`.** Every `SessionSummary` in the context
  (`expected_session` and `alternatives`, including earlier missed sessions) uses the
  same readiness rule.
- **R5 · Additive only.** No field removals or renames. Optional additive fields such as
  `expected_exercise_count` / `expected_set_count` in `PrescriptionReadiness` are welcome
  but not required; mobile ignores unknown fields.
- **R6 · Docs.** Update the readiness definition in `prompts/mobile-fe/mobile-api-contract.md`
  (§ field rules for `prescription.readiness`), `prompts/mobile-fe/api-mobile-backend.md`,
  and the OpenAPI description.

## Check before you proceed (feasibility and safety)

Please answer these in your report. If S1 or S2 turns up a problem, **stop and report
instead of implementing**.

- **S1 · Is the start's completeness rule itself right?** As far as I can tell, analysis
  saves enforce set ordinals that exactly match the target slot's DEFAULT variant
  (`set_count_mismatch` in `execution/repository.py`, ~L905–925), so exact set-count
  equality looks consistent. Please confirm against the domain rules for deload/reload
  microcycles, zero-set exercises, variant alternatives and plan revision changes. If any
  of them legitimately produces a different count, readiness must follow the corrected
  rule, not the current one.
- **S2 · Which plan structure governs a session?** The start uses
  `session.source_plan_workout_unit_id`; fallback preparation checks the session's
  governing plan revision. Confirm that they always describe the same structure, or pick
  the right one for all three.
- **S3 · Impact on current data (read-only).** How many existing scheduled or missed
  sessions would flip from `ready` to `missing`? A read-only query on the live DB is
  enough. Please include the number in your report.
- **S4 · Context query cost.** Compute expected counts for all listed sessions in the
  same query (join or CTE), not per session (no N+1).
- **S5 · Caching.** I checked this already: the context ETag is a hash of the full
  response body (`etag_for` in `mobile_execution/service.py`). A readiness change
  therefore changes the ETag, and phones will not get a stale `304`. No action needed
  unless you change `etag_for`.
- **S6 · Other consumers.** Confirm nothing else (desktop) relies on mobile readiness;
  desktop has its own analysis-only completeness.

## Out of scope

- Do not make the start or the context *write* a fallback implicitly; preparation stays
  an explicit `POST`.
- Do not change error codes or the `prescription_incomplete` / `fallback_unavailable`
  semantics beyond sharing the definition.
- Mobile will separately map start refusals (`prescription_incomplete`, the
  off-schedule codes) in its sync engine to a recoverable state. You don't need to do
  anything for that.

## Done when

- The reproduction test passes: `missing` → fallback → start succeeds as `hybrid`.
- Existing tests pass, plus tests for a fully analysed session (`ready` → plain start
  OK) and an un-analysed session (`missing`).
- Docs updated (R6).
- Deployed. Tell the user so the mobile side can verify on the phone.

## Please report back

1. Your verdict on S1–S6 (and the S3 number).
2. What you changed (files) and how "complete" is now defined.
3. Test results and the deployment state.
