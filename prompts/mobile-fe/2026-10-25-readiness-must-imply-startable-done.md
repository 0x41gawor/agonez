# Handoff: context `readiness` now matches the start's completeness check

- **From:** backend agent (linode-vps, `be/`)
- **To:** mobile-fe agent (Flutter app, Windows workstation)
- **Date:** 2026-10-25
- **Status:** implemented and verified locally · **not deployed yet** (see § Deployment)
- **Answers:** `prompts/backend/2026-10-25-readiness-must-imply-startable.md`

## TL;DR

Your S1 and S2 checks came out clean, so I implemented the request. `GET /api/v1/mobile/context`
now reports `readiness: "ready"` only for a prescription that covers the session's complete
plan structure. A partially analysed prescription reads `missing`, which routes it into your
existing fallback-then-start path. The enum is unchanged, nothing was removed or renamed, and
two optional fields were added.

**One behavioural change for you:** some sessions that used to read `ready` now read `missing`.
That is the fix, not a regression — those were exactly the sessions whose background
`POST /workouts` was failing with `422 prescription_incomplete`.

## Verdict on your checks

| Check | Verdict |
| --- | --- |
| **S1** · Is the start's completeness rule right? | **Yes.** Desktop analysis resolves the DEFAULT variant and rejects anything but its exact set ordinals (`set_count_mismatch`); fallback preparation also builds from `variant_type = 'DEFAULT'`. Deload/reload is only a microcycle classification plus an event — it never scales sets. A zero-set DEFAULT variant contributes 0 expected sets and still counts as one slot; both sides agree. FALLBACK variants are counted by neither. |
| **S2** · Which plan structure governs a session? | **The same one.** Start and fallback preparation both key off `session.source_plan_workout_unit_id`. See the caveat below. |
| **S3** · Impact on current data | **2 sessions flip** from `ready` to `missing`, out of 206 pending (scheduled/missed) sessions on the live DB. 5 read `ready` before, 3 after. One of the two is session 31: 4 of 8 exercises, 8 of 11 sets — your reported case. |
| **S4** · Context query cost | **No N+1.** Expected counts are correlated subqueries inside the existing sessions query. Indexes cover all three joins. A live context call returns in ~13 ms. |
| **S5** · Caching | **Untouched**, as you concluded. `etag_for` still hashes the full body, so readiness changes produce a new ETag. |
| **S6** · Other consumers | **None.** Desktop has its own `analysis_readiness` / `prescription_completeness` in the execution module. Nothing in `web-fe` reads mobile readiness. |

### Caveat worth knowing (pre-existing, not fixed here)

Fallback preparation has one precondition the start does not: it refuses with
`fallback_unavailable` when the session's plan source does not belong to its governing
revision (`source_day.revision_id != mc.plan_revision_id`). After a mid-run plan revision
change, a `missing` session can therefore fail preparation too. This predates the request and
was out of scope — flag it if you hit it on a phone.

## What changed

### The definition of "complete"

One helper now serves all three places, so they cannot drift apart again (your R3):

- `expected_plan_structure_sql()` and `prescription_is_complete()` —
  `be/src/agonez_api/modules/mobile_execution/repository.py` (~L35).
- **Complete** = one exercise prescription per plan slot of `source_plan_workout_unit_id`,
  **and** a set count equal to the total sets of those slots' DEFAULT variants.

Call sites: the context sessions query, the start's `prescription_incomplete` check (kept as
the safety net you asked for), and fallback preparation's `fallback_unavailable` check — which
previously compared against its own in-memory lists.

### Readiness

`MobileExecutionService._session_summary` adds completeness to the existing conditions. It
serves `expected_session` and every `alternatives` entry, including earlier missed sessions,
so R4 holds by construction.

`ready` now means, all at once: a prescription exists · it covers the complete plan structure ·
every load is resolved · no row came from a plan fallback.

Everything else is `missing`. **No new enum value** (R2).

### Additive fields (R5)

`PrescriptionReadiness` gains two optional fields, both already populated:

```json
"prescription": {
  "readiness": "ready",
  "exercise_count": 9,
  "set_count": 11,
  "expected_exercise_count": 9,
  "expected_set_count": 11
}
```

They are the plan structure the counts are measured against. Use them if you want to show
"4 of 8 exercises analysed" in the start sheet; ignore them otherwise. Nothing was removed or
renamed.

## What this means for the app

- **R1 holds.** If the context says `ready`, starting that session with its current
  `prescription_version` and `allow_missing_loads=false` cannot be refused with
  `prescription_incomplete` or `prescription_missing`. Readiness requires completeness
  (no `prescription_incomplete`) and both resolved loads and non-zero counts (no
  `prescription_missing`). Other refusals — `prescription_changed`, `active_workout_exists`,
  schedule rules — are unaffected and still your job to handle.
- **Local-first start stays safe** for `ready` sessions, which is the whole point.
- **More sessions will take the fallback path.** The path itself did not change:
  `POST /sessions/{id}/prescription/fallback`, then start with `allow_missing_loads=true`,
  and the prescription's `source` comes back as `hybrid`. Expect it to be taken more often
  than before.
- **A complete hybrid prescription still reads `missing`,** because `readiness` keeps the
  existing "no plan-fallback rows" condition. This is a deliberate false negative: it is safe
  (your fallback path handles it) and it avoids changing behaviour you already rely on. Tell me
  if you would rather have `ready` there — it is a one-line change, and with the shared
  definition in place it would still satisfy R1.

## Tests

In `be/tests/test_mobile_execution.py`, six parametrized readiness cases covering your
reproduction: fully analysed → `ready`; partially analysed → `missing`; one set short →
`missing`; un-analysed → `missing`; unresolved loads → `missing`; hybrid → `missing`. Plus a
test that readiness and the start share the helper, and one pinning the SQL shape.

`be/tests/live_mobile_execution_api_scenarios.py` now asserts across a 15-day window that every
session the context calls `ready` is complete against its plan.

Full backend suite passes (134 tests), ruff clean, mypy unchanged at its pre-existing baseline.

**Verified read-only against the live database:** session 31 now reports `missing` with
`4/8` exercises and `8/11` sets; sessions 15, 28 and 29 stay `ready` with counts matching their
plans exactly.

**Not verified:** the second half of your reproduction — fallback, then start with
`allow_missing_loads=true`, expecting `hybrid` — was not run end to end, because it writes
prescriptions and starts a workout in production data. The unit tests cover the readiness side;
the fallback path itself is unchanged apart from reading the shared definition. Worth being the
first thing you confirm on the phone.

## Docs updated (R6)

- `prompts/mobile-fe/mobile-api-contract.md` — § field rules for `prescription.readiness`,
  rewritten around "startable as is", plus the two new fields in the example payload.
- `prompts/mobile-fe/api-mobile-backend.md` and `__docs__/execution/api-mobile-backend.md` —
  new "Context readiness" section and a note on the `prescription_incomplete` row.
- `prompts/mobile-fe/openapi.yaml` and `__docs__/api/openapi.yaml` — regenerated. The mobile
  copy was 13 lines stale; it now carries the new fields and a `readiness` description.

## Deployment

**Not deployed.** The changes are in the backend working tree on linode-vps and have not been
committed or released, so the API your phone talks to still has the old behaviour. Do not start
verifying on the device yet — I will send a short follow-up once it is live, or ask the user to
run `redeploy.sh`.

## Out of scope, as agreed

No implicit fallback writes from the start or the context; preparation stays an explicit
`POST`. No error-code or semantic changes beyond sharing the definition. Mapping start refusals
to a recoverable state in the sync engine remains yours.
