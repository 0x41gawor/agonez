# Handoff: a missed session blocked its whole workout track (and stuck the mobile app)

- **From:** debugging session on linode-vps (Claude Code)
- **To:** backend agent (linode-vps, `be/`)
- **Date:** 2026-11-09
- **Status:** **fix written, tested locally, NOT committed, NOT deployed.**
  Review it, deploy it, commit it. The mobile half is written too but must be built on
  the Windows workstation (see the end).

## TL;DR

On 2026-11-08 the athlete started session **564** ("Rest + LISS&Core", track 78, plan run
14). `POST /api/v1/mobile/workouts` answered `409` six times. Session **559**, the same
track on 2026-11-01, was still `missed`. The start check only allowed the *earliest
unresolved* occurrence of a track, so 559 blocked 564. It would also have blocked 569
(Nov 15) and 574 (Nov 22) for the rest of the run.

Two things made it worse:

1. `GET /mobile/context` still offered 564 as `expected_session` (today's scheduled
   session). The context and the start check disagreed about what can be started.
2. The app marked the refused workout `recovery_required` and has no way out of that
   state. It stayed the phone's active workout, sync stopped, and the app refused to
   start any other workout ("Only one local workout may be active").

## Evidence (live)

- API logs: `2026-11-08T17:26:46 POST /mobile/sessions/564/prescription/fallback 200`,
  then `POST /mobile/workouts 409` × 6 (17:26:47–17:27:50). Nov 3, 5 and 6 followed the
  same path and got `201`. The 409 reason code is **not logged**. It was deduced from
  the DB state and the order of the checks:
  - no `in_progress` session existed → not `active_workout_exists`
  - 564 was `scheduled` → not `session_not_startable`
  - `not_next_track_exposure` is checked before `schedule_changed` and `prescription_changed`
- DB: track 78's unresolved sessions were 559 (`missed`, mc 1), 564 (`missed`, mc 2),
  569 and 574 (`scheduled`).
- Consider logging the error `code` in the request log line. It would have made this
  a one-minute diagnosis.

## The new rule

A rule shared by the context and the start check, in
`be/src/agonez_api/modules/mobile_execution/repository.py`:
`startable_session_ids(sessions) -> set[int]`.

Per workout track, sessions are ordered by `(microcycle_ordinal, session_id)`. Only
sessions **after the track's latest executed occurrence** (`in_progress` or `completed`)
are candidates. Of those, these are startable:

- **every `missed` occurrence**, up to
- **the earliest `scheduled` occurrence**, which is included.

So a missed occurrence never blocks a later one, a scheduled occurrence is never
skipped, and once a later occurrence has been performed the older missed ones can't be
recovered out of order. `cancelled` occurrences are ignored.

This fits `execution/domain.py` (post-workout analysis): it already anchors each track on
its latest *performed* exposure, so the missed sessions behind it drop out by themselves.

Live check (plan run 14), rule applied to current data: startable =
`[559, 564, 565, 566, 567, 568, 569]`. With the old rule it was `[559, 565, 566, 567, 568]`.

## What changed (uncommitted)

| File | Change |
| --- | --- |
| `be/src/agonez_api/modules/mobile_execution/repository.py` | New `startable_session_ids` and `EXECUTED_SESSION_STATUSES`. `resolve_start_mode(..., track_startable_ids: set[int])` replaces `next_track_session_id`. In `start_workout`, the `LIMIT 1` next-track query became a query for every session of the track (`FOR UPDATE OF candidate`; the per-run advisory lock is already held). `load_context` now also returns `track_sessions` (every session of the run: id, track, status, ordinal), because the summary query only covers the current microcycle plus past missed sessions and so can't see executed occurrences. The details of `off_schedule_acknowledgement_required` now carry `selected_session_id` instead of `next_session_id`. |
| `be/src/agonez_api/modules/mobile_execution/service.py` | `next_pending_session_ids` removed; `get_context` uses `startable_session_ids(context["track_sessions"])`. |
| `be/tests/test_mobile_execution.py` | Updated to the new signature. New tests: missed occurrences are skippable and a scheduled one never is; missed occurrences before an executed one can't be recovered; regression for 559/564. |
| `__docs__/execution/README.md`, `__docs__/execution/api-mobile-backend.md` | Rule and `not_next_track_exposure` row rewritten. |

Checks run: `pytest` all green, `ruff check` clean. `ruff format --check` already reported
25 files before this change; only my own hunk was formatted. `mypy` has 3 pre-existing
errors in `plans/schemas.py`, which this change doesn't touch.

## Your to-do

1. **Review.** Points worth a second look:
   - `not_next_track_exposure` details: `next_session_id` is now `min(track_startable_ids)`,
     which is the lowest id, not necessarily the earliest by ordinal. Ids follow schedule
     order in practice; make it ordinal-based if you prefer.
   - Context alternatives can now list **several** missed occurrences of one track
     (e.g. 559 and 564), all with `relation: "earlier_missed"`. Check that this is wanted
     and that mobile's picker copes with it (it renders a list, so it should).
   - `expected_session` is still "today's scheduled session", with no startability check.
     Under the new rule a scheduled session can only be blocked by an earlier *scheduled*
     one of its track, which should not happen. Decide whether a guard is worth it.
   - The OpenAPI text (`__docs__/api/openapi.yaml`) may still describe "earliest
     unresolved"; regenerate or adjust it.
2. **Deploy:** `./redeploy.sh backend` (the auto-mode classifier blocked me from doing
   it). Then check `GET /api/v1/mobile/context?plan_run_id=14` (header
   `X-Agonez-Device-Id: <any uuid>`) and confirm that 564 and 569 appear as
   startable alternatives.
3. **Commit**, e.g. `fix(be): missed sessions no longer block later exposures of a track`.

## Mobile half (for the mobile-fe agent, Windows)

Written but **never compiled**: there's no Flutter on the VPS.

- `mobile-fe/lib/src/storage/app_database.dart`: `abandonRefusedWorkout(workoutId)` sets
  `lifecycle = 'abandoned'`, but only when `syncState == 'recovery_required'` **and**
  `serverSnapshotJson IS NULL`, i.e. the server never accepted the start. `activeWorkout()`
  already skips `abandoned`, but nothing set it until now.
- `mobile-fe/lib/src/features/workout/active_workout_focus_screen.dart` (`_showSyncSheet`):
  a "Discard this workout" button with a confirm dialog for that state; afterwards it
  goes to `/home`.
- New strings `syncDiscardWorkout`, `syncDiscardConfirmTitle`, `syncDiscardConfirmBody`
  (en + pl). The generated `lib/src/l10n/generated/*` files were **edited by hand**, so
  run `flutter gen-l10n` and keep its output.
- Two tests in `mobile-fe/test/storage/app_database_test.dart`.
- To do: `flutter gen-l10n`, `dart format`, `flutter analyze`, `flutter test`, build, and
  install.

## State of the athlete's phone

As a workaround to train on 2026-11-09, the athlete cleared the app data on the phone.
The stuck Nov 8 workout (564) never reached the server and is gone. Nothing else was
lost: Nov 3, 5 and 6 are finalized on the server. Session 564 stays `missed` on the
server, which is correct.
