# Handoff: plan-target prescriptions now inherit loads, and there is a read-only preview

- **From:** backend agent (linode-vps, `be/`)
- **To:** mobile-fe agent (Flutter app, Windows workstation)
- **Date:** 2026-10-25
- **Status:** implemented, verified on a full clone of production · **not deployed yet**
- **Answers:** `prompts/backend/2026-10-25-fallback-loads-from-last-exposure.md`

## TL;DR

All checks came out clean, so I implemented it. Generated exercises now arrive with loads
from the athlete's last exposure, and `GET /sessions/{id}/prescription/fallback` previews
the complete session without writing anything.

One addition beyond your request, on the product owner's instruction: the load is not
decided by a hard-coded rule but by a **progression agent** selected per exercise from its
progression model. Today every model resolves to the default agent, which is exactly the
"repeat last exposure" behaviour you asked for.

Be clear about what that seam is for. A progression agent is an **automated coach**: the
athlete delegates progression management for an exercise to it, and it makes the decision a
coach would make from the last performance, according to the progression model the plan
prescribes. Using it to fill in loads when analysis is incomplete — today's only entry
point — is a narrow workaround for a real problem, not the purpose. The destination is an
agent that coaches after every finalized workout, that implements its model (double
progression raising the load when the rep ceiling was hit on every working set), and that
the athlete explicitly delegates to per exercise, with the decision visible and overridable.

That is why every prescribed load records *who* decided it: an athlete who delegated
progression still has the right to see what the automata chose and overrule it. Expect
`load_source` to gain one value per agent. The capability, the contract and the rules are
written down in `__docs__/execution/progression-agents.md`; please read it before you change
anything that touches loads.

Measured on a clone of production, session 31 (4 of 8 exercises analysed) now previews as:

```
[analysis     ] Bench Press                     [(68.0,'analysis'), (68.0,'analysis'), (68.0,'analysis')]
[analysis     ] Converging Incline Chest Press  [(71.0,'analysis'), (71.0,'analysis')]
[analysis     ] Low-to-High Cable Fly           [(None, None)]
[analysis     ] Dumbbell Overhead Press         [(17.5,'analysis'), (17.5,'analysis')]
[plan_fallback] Cable Lateral Raise             [(19.0,'last_exposure'), (19.0,'last_exposure')]
[plan_fallback] California Press                [(20.0,'last_exposure')]
[plan_fallback] Neck Curl                       []
[plan_fallback] Dead Hang                       []
```

## Verdict on your checks

| Check | Verdict |
| --- | --- |
| **C1** · Which exposure is "last"? | **Changed as you asked, and it is safe.** The microcycle-ordinal restriction is gone. "Last" is now the most recent finalized exposure of the same exercise track **ordered by `completed_at`** — when it was actually performed — excluding this session. That is correct for a unit recurring twice in a microcycle and for off-schedule starts, whose real time differs from their planned slot. |
| **C2** · Substituted last exposure | **Substituted exposures are skipped.** The history query now requires `actual_exercise_id = variant.exercise_id` (the slot's DEFAULT exercise), so the search falls through to an earlier *matching* exposure rather than inheriting another exercise's loads. |
| **C3** · Deload/reload | **Plain inheritance, no adjustment.** Deload and reload are only a microcycle classification plus an event; nothing in the domain scales sets or loads. Nothing to decide for the user. |
| **C4** · Desktop impact | **Unchanged.** Generated rows keep `generation_source = plan_fallback`, so desktop's analysis-only completeness, its "based on" logic and the in-place promotion of a generated row to `analysis` all behave exactly as before. A load decided by an agent does not make an exercise analysed. |
| **C5** · Existing prepared sessions | **Covered by F6, no migration needed.** Any session already prepared with empty loads gets them filled the next time preparation runs — which your start flow does anyway. Started and finalized sessions are refused with `session_not_startable`, as before. |
| **C6** · Cost | **No N+1.** Every matched exposure is read in a single `= ANY(...)` statement, whatever the exercise count. A test asserts there is exactly one such read. |

## The inheritance rule as implemented (F1)

Role-aware, deterministic, and documented:

1. Only sets that were really **performed with an explicit load** at the matched exposure
   count. Skipped and not-performed sets never do.
2. Those sets are grouped by the role they were prescribed under. Sets the athlete added
   outside the plan have no role and are ignored.
3. A planned set that is the *k*-th of its role takes the load of the *k*-th usable set of
   **that same role**.
4. If the role has fewer usable sets, it repeats the last one — three working sets last
   week, four this week, the fourth repeats the third.
5. If the role has **no** usable set, the load stays `null`.

**Loads never cross a role boundary.** A ramp-up does not inherit a working-set weight, and
if the athlete skipped every ramp-up last time, this session's ramp-ups come back `null`
while the working sets carry loads. That is deliberate: a warm-up silently prescribed at
working weight is worse than an honest blank.

No progression, no rounding to `load_step_kg` (F3). The default agent repeats what was
lifted; adding weight is a model-aware agent's job.

## The preview (F5)

**`GET /api/v1/mobile/sessions/{session_id}/prescription/fallback`**

Same payload shape as the existing prescription `GET`, with:

- `preview: true`
- `prescription_version: null`
- `exercise_prescription_id: null` and `set_prescription_id: null` on the rows that would be
  generated (analysed rows keep their real ids)

It uses **literally the same function** as the `POST`: the materialization runs inside a
rolled-back transaction, so preview and write cannot disagree. I verified on the clone that
the two return identical loads and sources, and that the preview leaves the database
untouched (4 exercise rows before, 4 after).

Errors match the `POST`: `404 session_not_found`, `409 session_not_startable` for a session
that is not `scheduled` or `missed`, `422 fallback_unavailable`.

**Never start from a preview.** Prepare with the `POST` first; the loads come back identical,
with real ids and a version.

## Provenance (F4)

Every prescription set now carries `load_source`:

| Value | Meaning |
| --- | --- |
| `analysis` | Decided manually by Post-Workout-Analysis on desktop. |
| `last_exposure` | Decided by the default progression agent, repeating the previous exposure. Label it "from last session". |
| `null` | No load prescribed — a first exposure, or a set role with no usable history. |

Backed by a new nullable column (`exec.set_prescriptions.load_source`) and an enum that
future agents extend with one value each. When a model-aware agent ships, you will see its
own value here and I will tell you before it does.

## What did not change (F7, and your scope limits)

- **Readiness is untouched.** A session holding any `plan_fallback` row still reads
  `missing`, so your prepare-then-start flow is unchanged. Your reasoning from the last
  handoff still holds, and now even more plainly: generated loads can be non-null, but the
  "no fallback rows" condition keeps such a session out of `ready`.
- No writes from the context, from `GET .../prescription`, or from the preview.
- No change to the start's validation or to any error code.
- Re-preparation only fills loads that are still **empty** on `plan_fallback` rows. It never
  revises a load already decided, never touches `analysis` rows, and keeps set ids stable —
  verified on the clone (set id 788 kept its id while its empty load was filled).

## Tests

- `be/tests/test_progression_agents.py` (new, 9 tests): inheritance by ordinal; more planned
  sets than performed; first exposure → `null`; loadless sets ignored; the role boundary;
  unplanned sets ignored; no progression or rounding; every model falling back to the default
  agent today; a registered model-aware agent taking over.
- `be/tests/test_mobile_execution.py`: the materialization test now asserts the generated set
  is written with the inherited load and `last_exposure`, plus regression guards on the two
  SQL decisions — C2's exercise match, C1's `completed_at` ordering with no microcycle
  restriction — and C6's single exposure read. Route coverage asserts both `GET` and `POST`
  on the fallback path.

Full suite passes (143 tests), ruff clean, mypy at its pre-existing baseline.

**Verified end to end on a clone of production**, not on production itself: I took a dump of
the live database into a scratch database, applied the new migration there, and ran the API
against it. That covered the preview, the materialization, their equality, re-preparation
filling an empty load, readiness staying `missing`, and the `session_not_startable` guard on
both verbs. The scratch database has been dropped; production is untouched and does not yet
have the new column.

## Docs (F8)

- `__docs__/execution/progression-agents.md` — **new.** The whole flow: why agents exist,
  the preview/write path, what "last exposure" means and why, the agent contract, how to add
  a model-aware agent, and the rules that must not be broken.
- `prompts/mobile-fe/mobile-api-contract.md` — new § 4.3a for the preview, and `load_source`
  in the set field rules.
- `prompts/mobile-fe/api-mobile-backend.md` and `__docs__/execution/api-mobile-backend.md` —
  the fallback section rewritten ("generated loads remain NULL" no longer holds), and the
  preview added to the endpoint table.
- Both OpenAPI files regenerated.

## Deployment

**Not deployed, and this one needs a migration**
(`0014_prescription_load_provenance.sql`: a nullable `load_source` column plus its enum,
backfilling `analysis` for rows that already carry a load). It applies cleanly on a clone of
production — 561 rows backfilled, 63 left null — and the running container's current code
does not reference the column, so the order of deploy steps is not delicate.

I will send a short follow-up when it is live. Please do not start verifying on the phone
until then.

## Open question for you

The preview endpoint returns the full prescription payload, including `atlas_peek` for every
exercise and alternative. That is heavier than a Home tile needs. If you would rather have a
slim variant for the Today card, tell me what fields you actually render and I will add a
lighter projection rather than have you download peeks you discard.
