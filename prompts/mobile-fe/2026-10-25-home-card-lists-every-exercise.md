# Handoff: list every exercise on the Today card (flow to execute)

- **From:** backend agent (linode-vps, `be/`)
- **To:** mobile-fe agent (Flutter app)
- **Date:** 2026-10-25
- **Status:** backend **deployed and live** — build against it now
- **Builds on:** `prompts/mobile-fe/2026-10-25-fallback-loads-from-last-exposure-done.md`

## The ask

On the Today card, a session whose analysis is partial currently lists only the analysed
exercises. The product owner wants **every** exercise the plan prescribes listed, whether or
not analysis has produced its loads.

Screenshot today: *Trening A1 — "Post-Workout-Analysis covers 2 of 6 exercises"* lists Bench
Press and Deadlift only. It should list all six.

## Your assumption is correct

> *the mobile-app reads the context and by the missing flag knows that it has to
> `GET prescription/fallback`*

Yes. `readiness` is the switch. Nothing else needs to change in how you decide.

## The flow

```text
GET /api/v1/mobile/context
        │
        ├─ prescription.readiness == "ready"
        │     └─ GET  /sessions/{id}/prescription          ← unchanged, as today
        │           → list exercises, Start
        │
        └─ prescription.readiness == "missing"
              └─ GET  /sessions/{id}/prescription/fallback  ← NEW, read-only preview
                    → list ALL exercises on the card
                    │
                    │  athlete taps Start
                    ▼
                    POST /sessions/{id}/prescription/fallback   (materialises; same loads,
                    │                                            real ids, real version)
                    ▼
                    POST /workouts   with the returned prescription_version
                                     allow_missing_loads=true if any load is still null
```

The start half is **exactly what you do today**. The only new step is the read before it.

## The new call

`GET /api/v1/mobile/sessions/{session_id}/prescription/fallback`

Same payload shape as `GET .../prescription`, so your existing parser works, with:

| Field | Value on a preview |
| --- | --- |
| `preview` | `true` |
| `prescription_version` | `null` |
| `exercises[].exercise_prescription_id` | `null` on generated rows, real on analysed ones |
| `sets[].set_prescription_id` | same |
| `exercises[].source` | `analysis` or `plan_fallback` — per exercise |
| `sets[].load_source` | `analysis`, `last_exposure`, or `null` |

**Never start from a preview.** It has no version and the generated rows have no ids. Call
the `POST` first; it returns the identical loads with real ids and a version.

It writes nothing, so it is safe to call on every Home render. It is not cached — fetch it
when you load the card, not on a timer.

Errors: `404 session_not_found`, `409 session_not_startable` (session is not `scheduled` or
`missed`), `422 fallback_unavailable`.

## What to render

Live response for the session in your screenshot (Trening A1, session 507, run 13):

```
[analysis     ] Bench Press                       4 sets @ 12.0  load_source: analysis
[analysis     ] Deadlift                          4 sets @ 12.0  load_source: analysis
[plan_fallback] Close-Grip Seated Cable Row       4 sets @ null  load_source: null
[plan_fallback] Incline EZ-Bar Triceps Extension  3 sets @ null  load_source: null
[plan_fallback] Barbell Curl                      3 sets @ null  load_source: null
[plan_fallback] Standing Calf Raise               3 sets @ null  load_source: null
```

All six rows belong on the card, in `ordinal` order.

**The loads are `null` here and that is correct, not a bug.** Run 13 started today, and load
inheritance is scoped to the plan run, so the first exposure of each exercise in a new run
has no history to inherit from. The product owner has confirmed this is the intended
behaviour — do not treat a `null` load as an error or hide the exercise because of it.

In a run with history the same call returns inherited loads, e.g. session 31 of the demo
run gives Cable Lateral Raise at 19.0 kg with `load_source: "last_exposure"`.

Suggested labelling, your call on wording:

- `load_source: "analysis"` → show the load plainly.
- `load_source: "last_exposure"` → show the load, marked "from last session".
- `load_source: null` → show the set with no load; the athlete enters it in the gym.

The existing "covers 2 of 6 exercises" line still works — `expected_exercise_count` is
unchanged. You may want to reword it now that the other four are visible rather than absent.

## Try it

```bash
curl -s "https://agonez.com/api/v1/mobile/sessions/507/prescription/fallback" \
  -H "X-Agonez-Device-Id: 11111111-2222-3333-4444-555555555555"
```

Session 507 is the one in the screenshot. Session 31 shows inherited loads.

## Out of scope

- Cross-run load inheritance. A new plan run starts without loads by design.
- Any change to readiness, to the start, or to error handling. Your sync-engine work from
  the readiness handoff stands as is.
