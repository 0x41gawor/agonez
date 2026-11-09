# Handoff: missed sessions no longer block a track — and your half needs a build

- **From:** backend agent (linode-vps, `be/`)
- **To:** mobile-fe agent (Windows workstation)
- **Date:** 2026-11-09
- **Status:** backend **deployed and verified on production**. The Flutter half is written but
  **never compiled** — that part is yours.
- **Answers:** `prompts/backend/2026-11-09-missed-exposure-blocks-track.md`

## TL;DR

The 409 loop that stranded the athlete's Nov 8 workout is fixed on the server. A missed occurrence
of a workout track no longer blocks later occurrences of that track.

Two things for you:

1. **The Dart half of that fix is sitting uncompiled in the repo** (a "Discard this workout"
   escape hatch). There is no Flutter on the VPS, so it has never been run through
   `gen-l10n`, `analyze` or `test`. See § 4 — this is the actual work.
2. **One workout track can now offer several `earlier_missed` candidates at once.** I checked your
   picker and it already copes (§ 3). Worth one look, not a rewrite.

Nothing in the wire shapes you parse has changed. No new endpoint, no new field you must read.

## 1. What was wrong

On Nov 8 you started session **564** ("Rest + LISS&Core", track 78, run 14) and
`POST /mobile/workouts` answered `409` six times. Session **559** — the same track, Nov 1 — was
still `missed`, and the start check only allowed the *earliest unresolved* occurrence of a track.
So 559 blocked 564, and would have gone on to block 569 (Nov 15) and 574 (Nov 22).

Worse, `/mobile/context` still offered 564 as `expected_session`, so the context and the start
check disagreed about what could be started. The server was telling you to start something it
would then refuse.

## 2. The new rule (live now)

Per workout track, occurrences are ordered by microcycle. Only occurrences **after the track's
latest executed (`in_progress` or `completed`) one** are candidates. Among those:

- **every `missed` occurrence** is startable, up to and including
- **the earliest `scheduled` occurrence**.

So a missed occurrence never blocks a later one, a `scheduled` occurrence is never skipped, and
once a later occurrence has been performed the older missed ones can no longer be recovered out of
order. `cancelled` occurrences are ignored.

**Verified against live run 14.** Track 78 is `559 missed · 564 missed · 569 scheduled ·
574 scheduled`, and the deployed context now returns:

```
559  mc1  missed     earlier_missed
564  mc2  missed     earlier_missed       <- was refused with 409
566  mc3  scheduled  later_in_microcycle
567  mc3  scheduled  later_in_microcycle
568  mc3  scheduled  later_in_microcycle
569  mc3  scheduled  later_in_microcycle  <- was blocked behind 559
```

574 is correctly absent: it is a `scheduled` occurrence sitting behind an earlier `scheduled` one.
Before the fix, track 78 offered only 559.

## 3. What changes for you on the wire

**Nothing you must parse.** `alternatives` has the same shape and the same `relation` values.
The one behavioural difference:

**A single track may now contribute several `earlier_missed` entries** — e.g. 559 *and* 564, both
"Rest + LISS&Core", differing only by `scheduled_on`.

I read `lib/src/features/home/workout_unit_picker.dart` before writing this. `pickerUnits()` builds
one `PickerUnit` per alternative with no dedup by track, sorts by date, and labels earlier-missed
rows with `pickerMissedOn(date)`. So the two occurrences render as two distinct dated rows already.
**No change needed** — just confirm it reads sensibly on a real device, since the athlete will now
see two identically-named rows where there was one.

Please keep keying rows by `session_id` and showing the date. Do not collapse them by
workout-unit name.

**Error details, for completeness:** `not_next_track_exposure`'s message text changed, its
`details.next_session_id` is now the lowest startable id for the track, and
`off_schedule_acknowledgement_required` now carries `selected_session_id` instead of
`next_session_id`. I grepped your tree: production code reads only `details['expected_seq']`
(`workout_sync_engine.dart:263`), so none of this reaches you. `next_session_id` appears only as
fixture data in `test/features/home/workout_unit_picker_test.dart`, which still passes.

## 4. Your job: the Flutter half (never compiled)

This is the escape hatch for the state that forced the athlete to wipe app data. It is written and
committed-ready in the repo, but **no Flutter toolchain exists on the VPS**, so it has not been
formatted, analyzed, tested or built even once. Treat it as a draft to verify, not finished work.

| File | What it does |
| --- | --- |
| `lib/src/storage/app_database.dart` | New `abandonRefusedWorkout(workoutId)`. Sets `lifecycle = 'abandoned'`, but **only** when `syncState == 'recovery_required'` **and** `serverSnapshotJson IS NULL` — i.e. the server never accepted the start, so nothing can be lost. `activeWorkout()` already skips `abandoned`; nothing ever set it until now. Returns whether a row qualified. |
| `lib/src/features/workout/active_workout_focus_screen.dart` | In `_showSyncSheet`, a "Discard this workout" outlined button (key `sync-discard-refused-workout`) for exactly that state, behind a confirm dialog, then `router.go('/home')`. |
| `lib/src/l10n/app_en.arb`, `app_pl.arb` | New `syncDiscardWorkout`, `syncDiscardConfirmTitle`, `syncDiscardConfirmBody`. |
| `lib/src/l10n/generated/*` | **Hand-edited.** Run `flutter gen-l10n` and keep its output over these. I verified all three keys are present in both locales and in all three generated files, so the regen should be clean rather than a repair job. |
| `test/storage/app_database_test.dart` | Two tests for the guard (qualifying row is abandoned; non-qualifying row is not). |

To do: `flutter gen-l10n`, `dart format`, `flutter analyze`, `flutter test`, then build and install.

## 5. One design point worth your judgment

The root cause of the stuck phone was not only the backend rule. `workout_sync_engine.dart:300-319`
maps every server refusal of the *start* — `not_next_track_exposure`, `prescription_changed`,
`schedule_changed`, `session_not_startable` and others — to `recovery_required`, which keeps the
workout active and stops sync, with no exit.

The discard button is a manual way out. But a start the server **refused outright** never created
anything server-side, so arguably it should not become the active workout at all, or should land in
a state of its own rather than in the one meant for a workout that exists on the server and needs
reconciling. The backend fix makes `not_next_track_exposure` rare; the other codes can still strand
a start the same way.

Your call, your layer — I am flagging it, not asking for it.

## 6. Contract docs updated

`prompts/mobile-fe/mobile-api-contract.md` described the **old** rule in three places and would
have had you building against it. Rewritten:

- § 0 "Off-schedule start" row — the new per-track rule.
- § 4.1 `GET /context`, the `alternatives` bullet — the new rule, plus the explicit warning that
  one track can contribute several `earlier_missed` entries and that rows must be keyed by
  `session_id`.
- § 5.1 `POST /workouts` error table — the new `not_next_track_exposure` meaning and client action.

Also `__docs__/execution/api-mobile-backend.md` and `__docs__/execution/README.md` on our side.
The OpenAPI files do not enumerate this error code, so there is nothing to regenerate; your
generated client is unaffected.

## 7. State of the athlete's phone

To train on Nov 9 the athlete cleared the app data. The stuck Nov 8 workout (564) never reached the
server and is gone; nothing was lost, since Nov 3, 5 and 6 are finalized server-side. 564 remains
`missed` on the server, which is correct — and under the new rule it is now startable, so it can
still be recovered.

## 8. What I verified, and what I did not

**Verified:** 152 backend tests pass; `ruff` clean; `mypy` unchanged (3 pre-existing errors in
`plans/schemas.py`, confirmed by stashing); deployed with `./redeploy.sh backend`; the live context
for run 14 returns the startable set above; your picker's handling of repeated tracks, by reading
the code.

**Not verified:** every line of Dart in § 4 — never compiled. And I did not re-run a live
`POST /mobile/workouts` for 564, so the *start* path carries the new rule only on the strength of
the shared `startable_session_ids()` function and its unit tests, including a regression test for
the 559/564 case. If 564 refuses again, say so immediately and I will chase it.
