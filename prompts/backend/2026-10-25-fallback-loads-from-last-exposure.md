# Handoff: plan-target prescriptions inherit loads from the last exposure

- **From:** mobile-fe agent (on behalf of the product owner)
- **To:** backend agent (linode-vps, `be/`)
- **Date:** 2026-10-25
- **Status:** request — **assess feasibility and safety first** (§ Checks), report back, and
  implement only if the checks come out clean.
- **Builds on:** `prompts/mobile-fe/2026-10-25-readiness-must-imply-startable-done.md`

## TL;DR

The product owner wants one standard behaviour for starting a session whose prescription is
not (fully) analysed:

> The backend completes the missing exercises from the plan, and **their loads come from the
> athlete's last exposure** of the same exercise. Loads stay empty **only** for a first
> exposure.

Today every generated set gets `prescribed_load_kg = NULL`, even when the athlete did that
exercise last week. Mobile also needs to **show** the complete session on Home before the
start, which today is only possible after a write.

## What happens today

Verified on the phone today, plan run "Szostek 3days FBW…", session 459, Trening A1:

- Analysis existed for 2 of 6 exercises. Context: `readiness: missing`, 2/6 exercises.
- **Home** lists only the 2 analysed exercises. `GET .../prescription` returns the partial
  snapshot, so the athlete cannot see that four more exercises will follow.
- **Start:** `POST .../prescription/fallback`, then `POST /workouts` with
  `allow_missing_loads=true`. The frozen prescription had Bench Press and Deadlift with
  12 kg (analysis). Cable Row, EZ-Bar Triceps Extension, Barbell Curl and Calf Raise had
  `NULL` on every set.

The relevant code is in `mobile_execution/repository.py`:

- `_ensure_fallback_prescription` → the `plan_exercises` query (~L555–600) already resolves
  `previous_exercise_performance_id`: the latest finalized performance of the same
  run-scoped exercise track (`logical_key = 'slot:<ordinal>'`), with at least one performed
  set that has an explicit load, from an earlier microcycle.
- The set insert (~L810) writes `prescribed_load_kg` as a literal `NULL`.

So the history is already found. It just isn't used for loads.

## The standard flow mobile will follow

1. `GET /mobile/context`: a session that is not `ready` reads `missing` (unchanged).
2. **Home preview (new, read-only):** mobile asks for the *complete* prescription the
   session would get: analysed rows as they are, plus generated rows with inherited loads.
   **Nothing may be written.**
3. **Start:** `POST .../prescription/fallback` materialises exactly that (idempotent), then
   `POST /workouts` with the returned version. `allow_missing_loads=true` is only needed if
   any load is still `NULL`, which means a first exposure.

## Requirements

- **F1 · Inherit loads.** Each generated set takes its load from the exercise's last
  exposure:
  - the performed load of the set at the same ordinal;
  - if that exposure had fewer performed sets, the load of its last performed set;
  - skipped or not-performed sets never count.

  Please choose and document the rule for set roles (e.g. a ramp-up set inheriting from a
  working set). Mobile only needs the rule to be deterministic and written down.
- **F2 · `NULL` only without history.** A load stays `NULL` only when the exercise has no
  qualifying previous exposure (first exposure), or when the matched exposure has no
  usable load at all.
- **F3 · Only loads are inherited.** Rep ranges, RIR targets, set count and roles still
  come from the plan. No progression, no rounding to `load_step_kg`: repeat what was
  actually lifted.
- **F4 · Provenance stays visible.** Generated exercises keep `source = plan_fallback`.
  Please add an additive per-set field, e.g.
  `load_source: "analysis" | "last_exposure" | null`, so the app can label inherited loads
  ("from last session") differently from analysed ones.
- **F5 · Read-only preview.** A side-effect-free read that returns the complete would-be
  prescription for a not-ready session. Either a new `GET .../prescription/fallback`, or a
  query flag on the existing `GET .../prescription`; your call.
  - It must use the **same function** as the `POST`, so preview and materialisation cannot
    disagree.
  - Generated rows have no persisted ids yet. Mark the payload as a preview (e.g.
    `preview: true`, `prescription_version: null`) so the app never starts with it.
- **F6 · Re-preparation before start.** Until a session is started, repeating
  `POST .../fallback` may fill still-`NULL` loads of `plan_fallback` rows from history that
  appeared since. It must never touch `analysis` rows or a started/frozen prescription, and
  must keep prescription ids stable (as today).
- **F7 · Readiness unchanged.** A session with any `plan_fallback` row still reads
  `missing`. Mobile prepares before starting either way.
- **F8 · Docs.** Update `prompts/mobile-fe/mobile-api-contract.md`,
  `prompts/mobile-fe/api-mobile-backend.md` (fallback section: "generated loads remain
  NULL" no longer holds), both OpenAPI files, and `__docs__/execution/api-mobile-backend.md`.

## Checks before you proceed

Please answer each in your report. If C1 or C2 needs a decision you are unsure about, ask
the user rather than guessing.

- **C1 · Which exposure is "last"?** The current history query only looks at **earlier
  microcycles** (`prior_mc.ordinal < current`). In "Szostek 3days FBW…" Trening A1 runs
  **twice per 14-day microcycle**, so the actual last session of that exercise can be in
  the same microcycle and would be ignored. The product owner's intent is the most recent
  finalized exposure before this session, by when it was actually performed. Please confirm
  that this is safe to change, including for off-schedule (`next_track_exposure`)
  sessions, whose actual time differs from their planned slot.
- **C2 · Substituted last exposure.** The query only requires
  `actual_exercise_id IS NOT NULL`. If the athlete substituted the exercise last time,
  inheriting that other exercise's loads would be wrong. Please require the performed
  exercise to equal the slot's DEFAULT exercise, or skip such exposures and fall back to
  the one before. Say which you chose.
- **C3 · Deload/reload microcycles.** Plain inheritance would carry normal-week loads into
  a deload week. Mobile is fine with plain inheritance, but please confirm the domain rules
  don't require adjusting it, or tell the user if they do.
- **C4 · Desktop impact.** Generated rows with loads must not count as analysis. Please
  confirm that the desktop's analysis-only completeness, its "based on" logic and the
  promotion of a generated row to analysis behave as before.
- **C5 · Existing prepared sessions.** Sessions already prepared with `NULL` loads but not
  started: does F6 cover them on their next preparation? Is any migration needed? Started
  sessions must not change.
- **C6 · Cost.** Inheriting per-set loads must not add per-exercise queries (no N+1).
  `prescription_version` will change when loads get filled; the context ETag is body-based,
  so that's fine.

## Out of scope

- No automatic progression or load suggestions beyond "repeat last".
- No writes from the context, from `GET .../prescription`, or from the preview.
  Materialisation stays the explicit `POST`.
- No change to readiness semantics (F7) or to the start's validation.

## What mobile will do once you deploy

- Home's Today card lists all exercises from the preview. Inherited loads are marked "from
  last session", and exercises without history are marked as such.
- The start flow stays as is. Missing-load handling only applies to first exposures.
- The workout screen labels inherited prescriptions using `load_source`.

## Done when

- Tests cover: inheritance by ordinal; fewer sets last time; skipped/not-performed sets
  ignored; first exposure → `NULL`; substituted last exposure (per C2); two exposures in
  one microcycle (per C1); preview equals materialisation; preview writes nothing;
  re-preparation fills `NULL`s but never touches analysis rows or started sessions.
- Docs updated (F8). Deployed, and the user told.

## Please report back

1. C1–C6 verdicts and any decisions you need from the user.
2. The inheritance rule as implemented (F1), and the preview's shape (F5).
3. Changed files, test results, and deployment state.
