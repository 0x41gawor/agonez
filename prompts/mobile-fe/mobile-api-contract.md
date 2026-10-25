# Agonez Mobile — API contract (workout execution + Atlas companion)

Status: proposal for the backend agent · v1 · October 2026
Audience: backend coding agent (FastAPI + PostgreSQL, `exec` schema), Flutter coding agent (client side of the same contract)
Companion documents: `mobile-implementation-handoff.md` (UI/interaction), `mobile-design-reference.html` (interactive reference), Execution domain overview, `invariants.md`, `dictionary.md`.

This contract is derived from the mobile workflows, not from table shapes. It reuses the existing
`exec` model (plan run → microcycle → workout session → prescription / performance trees) and adds
the smallest backend surface that lets a phone run a workout **offline-first**, **resumably** and
**idempotently**.

---

## 0. Summary of decisions

| Topic | Decision |
| --- | --- |
| Granularity | **Hybrid.** Aggregated reads (`/context`, `/workouts/{id}`) + one **ordered, idempotent operation log** endpoint for all draft writes (`POST /workouts/{id}/ops`). No endpoint per button. |
| Op semantics | Ops are **entity-state upserts** (the op carries the full current state of one set / one exercise performance), applied in client sequence order. Re-applying an op is harmless. The client may coalesce pending ops for the same entity. |
| Identity | Prescription entities use **existing server integer ids**. Performance entities (workout, exercise performance, set performance) use **client-generated UUIDs**, so a phone can create them offline and retries never duplicate. |
| Ordering | Per-workout monotonic `seq` within a device **lease epoch**. Server stores `applied_seq`; duplicates are acknowledged, gaps are rejected with the expected `seq`. |
| Single active workout | One `in_progress` session per plan run (per athlete once identity exists). Start returns `409 active_workout_exists` with the id to resume. |
| Multi-device | A device must hold the workout's **lease** to write. Another device can `claim` it explicitly ("Resume here"); the old device's ops are then rejected as `superseded`. |
| Conflicts | Entity `rev` + optional `if_rev` per op. A stale op is *consumed* with result `conflict` (not applied); the client asks the athlete. Everything else in the batch still applies. |
| Prescription | Frozen at start (`prescription_version`). Start with a stale version → `409 prescription_changed` + fresh payload. Never changes mid-workout. |
| Rest timer | **Client-only.** No timer endpoints. `performed_at` timestamps on sets make rest intervals reconstructible later. |
| Finalize | Separate idempotent endpoint carrying `final_seq`. Unrecorded prescribed sets become `not_performed`. Session → `completed`, performance → `finalized`, in one transaction (invariants §Transaction boundaries #3). |
| Off-schedule start | Explicit `next_track_exposure` acknowledgement. Backend permits only the earliest unresolved occurrence of the selected workout track and preserves its planned microcycle/date. |
| `heart_rate_bpm` | Accepted in the set DTO now (nullable). Stored when the column exists; until then echoed in `unsupported_fields`, never an error. |
| Atlas | Reuse the existing Atlas exercise/muscle reads for the full article. Add a compact **peek** read and a compact **search** read; embed peek data in the workout payload for offline use. |
| Auth | Not invented. Identity is deferred in the current backend; mobile scopes by `plan_run_id` and sends an `X-Agonez-Device-Id`. See §11. |

---

## 1. Conventions

- Base path: `/api/v1/mobile`. Existing desktop Execution API stays under `/api/v1/exec`; nothing here changes it.
- JSON, `snake_case`, UTF-8. Times are RFC 3339 with offset (`timestamptz`). Dates are `YYYY-MM-DD` in the plan run's calendar.
- Loads are kilograms, decimal with up to 2 fractional digits (`67.5`, `8.75`). Clients must not send floats with more precision.
- `rir`: integer `0..10`. The UI's "5+" button sends `5`; it means *five or more*, exactly as the desktop treats RIR ≥ 5.
- `repetitions`: integer `0..100`.
- Headers sent by the mobile client on every request:
  - `X-Agonez-Device-Id: <uuid>` — stable per installation; used for leases and diagnostics.
  - `X-Agonez-Client: agonez-mobile/<semver> (<platform>)`.
  - `Accept-Language: <locale>` — content-locale negotiation already used by Atlas (en, pl, fr, es, de, it, nl, sv, pt-BR, uk, tr).
- Error envelope (all non-2xx):

```json
{ "error": { "code": "active_workout_exists", "message": "Human-readable, English, for logs", "details": { "workout_id": "6f4c…" } } }
```

  The client localizes by `code`; `message` is never shown to the athlete.
- `ETag`/`If-None-Match` are supported on the two big reads (`/context`, `/workouts/{id}`) so a resumed app can revalidate cheaply.

---

## 2. Resource model (mobile view)

```text
MobileContext ─────────────── what should the athlete do now?
 ├─ plan_run (selected)
 ├─ today (date, microcycle position)
 ├─ expected_session  ──► SessionSummary (+ prescription readiness)
 ├─ alternatives[]    ──► SessionSummary (earlier missed + current-microcycle sessions)
 └─ active_workout?   ──► ActiveWorkoutSummary

Workout (one per started session; client UUID)
 ├─ prescription (frozen, read-only)         ← exec.*_prescriptions
 │   └─ exercises[] → sets[]
 ├─ performance (draft → finalized)          ← exec.*_performances
 │   └─ exercises[] (client UUIDs) → sets[] (client UUIDs)
 └─ sync (lease, applied_seq, revision)
```

Mapping to the existing `exec` schema:

| Mobile concept | `exec` object | Notes |
| --- | --- | --- |
| Workout | `workout_sessions` (status `in_progress` → `completed`) + its `workout_unit_performances` row (`draft` → `finalized`) | Created by *start* in one transaction (invariants #2). |
| `workout_id` (UUID) | new column `workout_unit_performances.client_uuid` (unique) | Server integer PK stays internal. |
| Prescribed exercise | `exercise_unit_prescriptions` | Read-only for mobile. |
| Prescribed set | `set_prescriptions` (incl. `prescribed_load_kg`) | Read-only. |
| Exercise performance | `exercise_unit_performances` + `client_uuid` | `exercise_execution_mode`, actual exercise FK, exercise-level comment. |
| Set performance | `set_performances` + `client_uuid` | `prescribed_set_id` NULL ⇒ additional set; skipped ⇒ explicit status, no numbers (existing CHECK). |
| Op log | new table `exec.mobile_sync_ops` | Audit + idempotency only. Facts stay relational (invariant: "Core execution facts are not hidden in JSON"). |

---

## 3. Endpoints at a glance

| # | Method & path | Purpose | Screens |
| --- | --- | --- | --- |
| 1 | `GET /context` | Everything Home needs in one call | Home, cold start, resume |
| 2 | `GET /plan-runs` | Compact list for the plan-run selector | Run context sheet |
| 3 | `GET /sessions/{session_id}/prescription` | Full prescription payload before start (also for previewing alternatives) | Home, picker |
| 4 | `POST /workouts` | Start a workout (idempotent by client UUID) | Start |
| 5 | `GET /workouts/active` | Discover an active workout for this plan run | Cold start, Home |
| 6 | `GET /workouts/{workout_id}` | Full snapshot: frozen prescription + current draft + sync state | Resume, recovery, conflict refresh |
| 7 | `POST /workouts/{workout_id}/claim` | Take the write lease on this device ("Resume here") | Active elsewhere |
| 8 | `POST /workouts/{workout_id}/ops` | Ordered, idempotent batch of draft operations | Every recording action |
| 9 | `POST /workouts/{workout_id}/finalize` | Finish and finalize | Finish |
| 10 | `GET /atlas/exercises/{exercise_id}/peek` | Compact Atlas quick-view data | Quick peek |
| 11 | `GET /atlas/exercises?q=&plan_run_id=` | Compact search for substitution / unplanned exercise | Picker |
| — | *existing* Atlas exercise / muscle detail reads | Full Atlas article | Atlas workspace |

Explicitly **not** provided: timer endpoints, per-button endpoints (`/skip-set`, `/add-set`, …), analytics, progression.

---

## 4. Reads

### 4.1 `GET /context`

Query: `plan_run_id` (optional), `date` (optional, defaults to server "today" in the run's calendar; the client sends its local date to avoid midnight/timezone surprises).

Plan-run selection in v1 is **client-local**: the phone remembers the chosen `plan_run_id`. If it is omitted the server picks the single `active` run; if several are active it returns `selection_required`.

`200`:

```json
{
  "generated_at": "2026-10-09T15:58:02+02:00",
  "context_version": "ctx-7f19c2",
  "plan_run": {
    "id": 3,
    "name": "Autumn Cut 2026",
    "status": "active",
    "plan_name": "PPL Upper Focus",
    "starts_on": "2026-08-25",
    "ends_on": "2026-10-19",
    "microcycle_count": 8,
    "microcycle_duration_days": 7
  },
  "selection_required": false,
  "today": {
    "date": "2026-10-09",
    "microcycle": { "id": 51, "ordinal": 7, "day_ordinal": 4, "classification": "normal" }
  },
  "microcycle_days": [
    { "date": "2026-10-06", "day_ordinal": 1, "session_id": 412, "workout_unit_name": "Pull A", "status": "completed" },
    { "date": "2026-10-07", "day_ordinal": 2, "session_id": 413, "workout_unit_name": "Legs", "status": "completed" },
    { "date": "2026-10-08", "day_ordinal": 3, "session_id": null, "workout_unit_name": null, "status": "rest_day" },
    { "date": "2026-10-09", "day_ordinal": 4, "session_id": 414, "workout_unit_name": "Push A", "status": "scheduled" }
  ],
  "expected_session": {
    "session_id": 414,
    "workout_unit_name": "Push A",
    "workout_track_id": 7,
    "scheduled_on": "2026-10-09",
    "status": "scheduled",
    "prescription": {
      "readiness": "ready",
      "prescription_version": "rx-414-3",
      "updated_at": "2026-10-08T21:12:00+02:00",
      "exercise_count": 6,
      "set_count": 16,
      "expected_exercise_count": 6,
      "expected_set_count": 16,
      "estimated_duration_min": 70
    }
  },
  "alternatives": [
    { "session_id": 415, "workout_unit_name": "Push B", "scheduled_on": "2026-10-10", "status": "scheduled",
      "relation": "later_in_microcycle", "prescription": { "readiness": "ready", "prescription_version": "rx-415-2" } },
    { "session_id": 416, "workout_unit_name": "Pull B", "scheduled_on": "2026-10-11", "status": "scheduled",
      "relation": "later_in_microcycle", "prescription": { "readiness": "missing" } }
  ],
  "fallbacks": [],
  "active_workout": null,
  "recent": [
    { "session_id": 413, "workout_unit_name": "Legs", "completed_at": "2026-10-07T19:02:00+02:00", "performed_sets": 14, "prescribed_sets": 14, "skipped_sets": 0 }
  ]
}
```

Field rules:

- `prescription.readiness`: `ready` | `missing` | `not_applicable` (rest day).
  `ready` means **startable as is**: the prescription covers the session's complete plan
  structure (one exercise per plan slot, and every set of each slot's DEFAULT variant), every
  load is resolved, and no row came from a plan fallback. Starting a `ready` session with its
  current `prescription_version` and `allow_missing_loads=false` is never refused with
  `prescription_incomplete` or `prescription_missing`.
  `missing` covers everything else — no prescription, a partially analysed one (Post-Workout-Analysis
  saves exercise by exercise, so "5 of 7 slots analysed" is ordinary), unresolved loads, or a
  prescription already holding plan-fallback rows. Prepare it with `POST .../prescription/fallback`
  and start with `allow_missing_loads=true`.
  `expected_exercise_count` and `expected_set_count` report the plan structure the counts are
  measured against. The same rule applies to `expected_session` and every entry in `alternatives`.
- `expected_session` is `null` on a rest day or when no session is scheduled; the UI then shows "Rest day" and offers alternatives.
- `alternatives` lists only the earliest unresolved occurrence of each stable workout track:
  earlier `missed` sessions from the run plus other `scheduled` or `missed` sessions in the
  **current microcycle**. Earlier missed candidates remain available after the calendar's final
  microcycle. `relation` ∈ `earlier_missed` | `later_in_microcycle`. Final start validation
  remains authoritative in `POST /workouts` (§5.1).
- `fallbacks` is reserved for future fallback workout-units (`fallback_source_plan_workout_unit_id` hook). Always `[]` in v1.
- `active_workout`, when present, has the shape of §4.5 `ActiveWorkoutSummary`. The Home screen must show *Resume* instead of *Start* whenever it is non-null.
- `recent` is at most 3 rows. No trends, no MARKER.X — deep analysis stays on desktop.

Errors: `404 plan_run_not_found`, `200` with `plan_run: null` + `selection_required: false` when there is no active run (Home shows the *No active plan run* state; this is not an error).

### 4.2 `GET /plan-runs`

Compact list: `[{ id, name, status, starts_on, ends_on, microcycle_count, current_microcycle_ordinal }]`, active first. Used by the plan-run selector. Read-only; switching is client-local and **disabled while a workout is active**.

### 4.3 `GET /sessions/{session_id}/prescription`

Returns the coherent prescription payload needed to execute without further reads. The same object is embedded in the workout snapshot (§4.6), frozen at start.

```json
{
  "session_id": 414,
  "prescription_id": 9021,
  "prescription_version": "rx-414-3",
  "workout_unit_name": "Push A",
  "workout_track_id": 7,
  "microcycle": { "ordinal": 7, "classification": "normal" },
  "plan_comment": null,
  "prescription_comment": null,
  "exercises": [
    {
      "exercise_prescription_id": 55101,
      "ordinal": 1,
      "exercise_track_id": 31,
      "slot": { "goal": "Primary chest press", "role": "primary_progressive" },
      "exercise": { "id": 112, "slug": "flat_bench_barbell_press", "name": "Bench Press", "full_name": "Flat Bench Barbell Press" },
      "variant_label": "Flat bench, 1 s pause",
      "plan_comment": "Pause 1 s at the bottom. When you know the next rep will fail, finish the set with halves.",
      "prescription_comment": "Hold 67.5 on sets 1–2. Set 3 at 65 until elbows stay tucked.",
      "load_step_kg": 2.5,
      "default_rest_s": 180,
      "sets": [
        { "set_prescription_id": 880301, "ordinal": 1, "role": "working", "prescribed_load_kg": 67.5, "rep_min": 5, "rep_max": 7, "target_rir": 1, "comment": null },
        { "set_prescription_id": 880302, "ordinal": 2, "role": "working", "prescribed_load_kg": 67.5, "rep_min": 5, "rep_max": 7, "target_rir": 1, "comment": null },
        { "set_prescription_id": 880303, "ordinal": 3, "role": "working", "prescribed_load_kg": 65.0, "rep_min": 5, "rep_max": 7, "target_rir": 1, "comment": "Tuck elbows; stop the set if they flare." }
      ],
      "alternatives": [
        { "exercise": { "id": 140, "slug": "incline_dumbbell_press", "name": "Incline Dumbbell Press" }, "source": "plan_variant", "variant_ordinal": 2 }
      ],
      "history": {
        "previous_exposure": {
          "microcycle_ordinal": 6,
          "performed_on": "2026-10-02",
          "exercise": { "id": 112, "name": "Bench Press" },
          "sets": [
            { "ordinal": 1, "status": "performed", "load_kg": 67.5, "repetitions": 7, "rir": 1 },
            { "ordinal": 2, "status": "performed", "load_kg": 67.5, "repetitions": 6, "rir": 0 },
            { "ordinal": 3, "status": "performed", "load_kg": 67.5, "repetitions": 5, "rir": 0 }
          ]
        }
      },
      "atlas_peek": { "$ref": "§7.1 AtlasPeek, embedded for offline use" }
    }
  ]
}
```

Rules:

- `exercise.id` is `core.exercises.id`; `slug` is the stable cross-schema key (Atlas route, `engine.exercises` join). Both are always present so the client can open Atlas without another lookup.
- `slot.role` mirrors the set/slot role vocabulary already used by the desktop (`primary_progressive`, `secondary_compound`, `isolation`, …). The client only displays it.
- `load_step_kg` comes from the exercise variant's progression metadata; fall back to `2.5`.
- `default_rest_s` is a **hint** for the client timer (from plan metadata if present, else by role: compounds 180, isolation 90). Not persisted per workout.
- `alternatives` = the slot's other `exercise_variants` (`source: "plan_variant"`). They are sanctioned replacements but choosing one is still a *substitution* in the performance data.
- `history.previous_exposure` = the prior finalized `exercise_unit_performance` of the same `exercise_track` (exactly the link Post-Workout-Analysis uses, `previous_exercise_performance_id`). `null` for a first exposure. Only the last exposure is sent — mobile shows small context, not history.
- `atlas_peek` is embedded for every prescribed exercise **and** every `alternatives[].exercise` (see §7.1), so Quick Peek works offline.
- Nothing here exposes revision/day/slot integer FKs beyond what the client needs to address writes.

- `sets[].load_source` says who decided `prescribed_load_kg`: `analysis` for a manual Post-Workout-Analysis save, `last_exposure` for the default progression agent repeating the athlete's previous exposure, `null` when no load is prescribed. Label an inherited load as coming from the last session; a `null` load means a first exposure for that set role.

Errors: `404 session_not_found`, `409 prescription_missing` (readiness `missing`; body carries the plan targets so the athlete can still *Start with plan targets* — see §5.1 `allow_missing_loads`).

### 4.3a `GET /sessions/{session_id}/prescription/fallback` — preview (read-only)

Returns the **complete** snapshot the session would get: analysed exercises as they stand, plus the exercises the plan prescribes that analysis has not covered, with their loads already decided from the athlete's last exposure. Use it to render the whole session on Home before the athlete starts.

It writes nothing. The payload is marked `preview: true` with `prescription_version: null`, and rows that would be generated carry `exercise_prescription_id: null` and `set_prescription_id: null` — **never start from a preview**. Call `POST .../prescription/fallback` to materialise it; the loads come back identical, with real ids and a version.

Loads are decided by the progression agent registered for each exercise's progression model. Today that is always "repeat the last exposure": the matching set of the last finalized exposure of the same exercise, matched within its set role, never progressed or rounded. A load is `null` only for a first exposure, or a set role with no usable history. A substituted exposure is skipped — the loads of a different exercise are never inherited.

Errors as for `4.3`, plus `409 session_not_startable` for a session that is not `scheduled` or `missed`, and `422 fallback_unavailable` when the plan cannot be mapped to executable tracks.

### 4.4 `GET /workouts/active`

Query: `plan_run_id`. `200` → `ActiveWorkoutSummary`; `404 no_active_workout` when none. Called on every cold start **before** rendering Home; the response is also part of `/context`.

### 4.5 `ActiveWorkoutSummary`

```json
{
  "workout_id": "6f4c3c1e-9b0d-4b55-8a3e-0d6d2f4b7a10",
  "session_id": 414,
  "workout_unit_name": "Push A",
  "started_at": "2026-10-09T17:29:11+02:00",
  "start_context": {
    "scheduled_on": "2026-10-09",
    "microcycle_ordinal": 6,
    "mode": "on_schedule",
    "selected_from": null,
    "expected_session_id": null
  },
  "lease": { "device_id": "a1c5…", "epoch": 1, "is_this_device": true },
  "applied_seq": 27,
  "revision": 31,
  "position_hint": { "exercise_performance_id": "…", "set_ordinal": 2 },
  "counts": { "prescribed_sets": 16, "performed_sets": 10, "skipped_sets": 0 }
}
```

`position_hint` is the last position the writing device reported (op `set_cursor`, §6.3). The phone that owns the local draft trusts its own state; another device uses the hint.

### 4.6 `GET /workouts/{workout_id}`

The full snapshot used for resume after reinstall, device switch, conflict refresh, or local-store corruption.

```json
{
  "workout_id": "6f4c3c1e-…",
  "session_id": 414,
  "status": "in_progress",
  "started_at": "2026-10-09T17:29:11+02:00",
  "finished_at": null,
  "start_context": {
    "scheduled_on": "2026-10-09",
    "microcycle_ordinal": 6,
    "mode": "on_schedule",
    "selected_from": null,
    "expected_session_id": null
  },
  "lease": { "device_id": "a1c5…", "epoch": 1, "is_this_device": true },
  "applied_seq": 27,
  "revision": 31,
  "prescription": { "…": "frozen copy of §4.3" },
  "performance": {
    "comment": null,
    "exercises": [
      {
        "exercise_performance_id": "0b8e…",
        "exercise_prescription_id": 55101,
        "performed_ordinal": 1,
        "mode": "as_prescribed",
        "actual_exercise": { "id": 112, "slug": "flat_bench_barbell_press", "name": "Bench Press" },
        "comment": "Seat level 14 felt right.",
        "rev": 4,
        "sets": [
          { "set_performance_id": "c1d2…", "prescribed_set_id": 880301, "ordinal": 1, "status": "performed",
            "load_kg": 67.5, "repetitions": 7, "rir": 1, "comment": null, "heart_rate_bpm": null,
            "performed_at": "2026-10-09T17:33:40+02:00", "rev": 1 }
        ]
      }
    ]
  }
}
```

The snapshot always contains the prescription and the performance as **separate trees** — the client must never merge actual values into prescription fields.

---

## 5. Lifecycle writes

### 5.1 `POST /workouts` — start

```json
{
  "workout_id": "6f4c3c1e-9b0d-4b55-8a3e-0d6d2f4b7a10",
  "session_id": 414,
  "prescription_version": "rx-414-3",
  "started_at": "2026-10-09T17:29:11+02:00",
  "allow_missing_loads": false,
  "off_schedule": null
}
```

- `workout_id` is generated by the client **before** the request (UUIDv4) and persisted locally first. The call is idempotent on `workout_id`: a retry returns `200` with the same snapshot; the first success returns `201`.
- `started_at` is the device time the athlete tapped *Start* (the workout may have been started offline). The server stores it and also records `received_at`.
- Server transaction (invariants §Transaction boundaries #2): session `scheduled | missed → in_progress`, create `workout_unit_performances` (draft, `client_uuid = workout_id`), grant lease `{device_id, epoch: 1}`, `applied_seq = 0`.
- Response `201`: the §4.6 snapshot.

Errors:

| Status / code | When | Client behaviour |
| --- | --- | --- |
| `409 active_workout_exists` (`details.workout_id`) | Another workout is `in_progress` in this plan run | Show *Workout already active* → *Resume it* (claim if other device). Never auto-start a second. |
| `409 prescription_changed` (`details.prescription`) | `prescription_version` is stale | Show the *Prescription changed* banner with the diff, ask the athlete to start again on the new version. |
| `409 session_not_startable` (`details.status`) | Session is `completed`, `cancelled`, or already `in_progress` with another `workout_id` | Refresh context. A `missed` session remains pending and can start through `next_track_exposure`. |
| `422 prescription_missing` | No resolved loads and `allow_missing_loads=false` | Offer *Start with plan targets*; resend with `allow_missing_loads=true`. Load fields of the frozen prescription are then `null`. |
| `422 off_schedule_acknowledgement_required` | `session_id` is not `expected_session` | Show the confirmation and resend with the explicit acknowledgement. |
| `422 off_schedule_not_applicable` | An acknowledgement was sent for the expected session | Refresh context and start normally. |
| `409 not_next_track_exposure` | An earlier unresolved occurrence of this workout track exists | Refresh context and offer `details.next_session_id`; the athlete may execute it or cancel it outside the workout flow. |
| `409 schedule_changed` | The acknowledged `expected_session_id` is stale | Refresh context and ask for confirmation again. |

**Off-schedule starts.** The picker lets an athlete deliberately execute the next unresolved exposure of another workout type, or recover a missed exposure:

```json
"off_schedule": {
  "mode": "next_track_exposure",
  "acknowledged": true,
  "selected_from": "picker",
  "expected_session_id": 414
}
```

`expected_session_id` is nullable on a rest day. The backend validates it against current state,
then starts only the earliest `scheduled` or `missed` occurrence of the selected workout track by
microcycle ordinal. A different workout track is independent. The session remains attached to its
planned microcycle/date; actual `started_at` and `finished_at` are execution metadata.

**Offline start.** If `POST /workouts` cannot be reached, the client still starts locally with its `workout_id` and enqueues the start request as the first queued item; ops queue behind it. If the delayed start later fails with `409 active_workout_exists` or `prescription_changed`, the client keeps the local draft and asks the athlete (see handoff §Sync states); data is never dropped silently.

### 5.2 `POST /workouts/{workout_id}/claim`

Body: `{ "device_id": "<this device>", "observed_applied_seq": 27 }`.

Moves the write lease to this device and increments `epoch`. Returns the §4.6 snapshot. The client must then *replace* its local draft with the snapshot (it had none, or a stale one) and continue numbering ops from `seq = 1` in the new epoch.

`409 workout_finalized` if it was finished meanwhile. The UI wording is "A workout is already in progress — started 18:04 on another device · *Resume it here*". Claiming is an explicit tap, never automatic.

### 5.3 `POST /workouts/{workout_id}/finalize`

```json
{
  "lease_epoch": 1,
  "final_seq": 41,
  "finished_at": "2026-10-09T18:37:02+02:00",
  "unrecorded": "mark_not_performed",
  "acknowledged_incomplete": true
}
```

- Requires `applied_seq == final_seq` (the client flushes ops first; if they are still queued it sends finalize *after* them in the same queue). Otherwise `409 ops_pending` with `details.applied_seq`.
- `acknowledged_incomplete` must be `true` when any prescribed set is still unrecorded (the UI's *Hold to finish*). Otherwise `409 incomplete_not_acknowledged` — a guard against accidental finishes from buggy clients.
- Transaction (invariants #3): every prescribed set without a set performance gets a `not_performed` row (no numeric values); exercise performances with no performed set and mode `as_prescribed` become mode `not_performed`; performance `draft → finalized`; session `in_progress → completed` with `completed_at = finished_at` and `completion_mode` derived (see §10 open question 3).
- Idempotent: a repeated finalize with the same `final_seq` returns `200` with the same summary.
- Response:

```json
{
  "workout_id": "6f4c…", "status": "completed", "finished_at": "2026-10-09T18:37:02+02:00",
  "summary": { "prescribed_sets": 16, "performed_sets": 11, "skipped_sets": 0, "not_performed_sets": 5,
               "additional_sets": 0, "substitutions": 1, "skipped_exercises": 0, "added_exercises": 0, "reordered": false }
}
```

There is **no cancel/delete** endpoint. "Back" never cancels. An accidentally started workout is finished with nothing recorded (all `not_performed`), which is the honest record. (Open question 5 discusses an optional *discard empty workout* window.)

---

## 6. Draft synchronization — `POST /workouts/{workout_id}/ops`

### 6.1 Why an ordered op log of entity upserts

| Option | Offline client | Retries | Resume | Consistency | Verdict |
| --- | --- | --- | --- | --- | --- |
| Fine-grained REST (`PUT /sets/{id}`, `PATCH /exercises/{id}`, `POST /skip`…) | Needs a queue of heterogeneous HTTP calls, each with its own retry/ordering rules | Per call; ordering across calls is the client's problem | OK | Cross-entity ordering (reorder after add) is fragile | ✗ |
| Whole-draft state sync (`PUT /workouts/{id}/draft`) | Trivial | Idempotent | Trivial | Last-writer-wins for the whole tree; loses intent (was it skipped or never touched?); large payload on gym Wi-Fi; desktop edits clobbered | ✗ |
| **Ordered op log, each op = full state of one entity** | One FIFO queue, one endpoint | Idempotent by `(epoch, seq)` + `op_id`; ops are upserts | Snapshot + `applied_seq` | Total order per workout; per-entity `rev` for conflicts; intent is explicit (`skip_exercise`, `substitute_exercise`) | **✓** |

The chosen hybrid keeps reads aggregated and writes small, ordered and replayable. Because each op carries the complete state of the entity it touches, the client may **coalesce** queued ops for the same entity (e.g. three edits to set 2 while offline → only the last `upsert_set` is sent) as long as it never reorders ops across entities.

### 6.2 Request / response

```http
POST /api/v1/mobile/workouts/6f4c…/ops
X-Agonez-Device-Id: a1c5…
```

```json
{
  "lease_epoch": 1,
  "base_seq": 26,
  "ops": [
    { "op_id": "e2b7…", "seq": 27, "at": "2026-10-09T17:58:40+02:00", "type": "upsert_set",
      "data": { "set_performance_id": "c3a9…", "exercise_performance_id": "0b8e…", "prescribed_set_id": 880302,
                "ordinal": 2, "status": "performed", "load_kg": 65.0, "repetitions": 6, "rir": 0,
                "comment": "Reduced load after previous set", "heart_rate_bpm": null, "performed_at": "2026-10-09T17:58:38+02:00" } },
    { "op_id": "f019…", "seq": 28, "at": "2026-10-09T17:59:02+02:00", "type": "set_cursor",
      "data": { "exercise_performance_id": "0b8e…", "set_ordinal": 3 } }
  ]
}
```

- `base_seq` = the last seq the client believes the server applied. Ops must be contiguous from `base_seq + 1`.
- Max 200 ops per request; the client chunks larger backlogs.
- The server applies ops **in seq order inside one transaction per request**, then commits. Each op is recorded in `exec.mobile_sync_ops (workout_perf_id, epoch, seq, op_id, type, payload, result, applied_at)`.

`200`:

```json
{
  "applied_seq": 28,
  "revision": 33,
  "results": [
    { "seq": 27, "op_id": "e2b7…", "status": "applied", "entity_rev": 2 },
    { "seq": 28, "op_id": "f019…", "status": "applied" }
  ],
  "unsupported_fields": ["heart_rate_bpm"],
  "server_time": "2026-10-09T17:59:03+02:00"
}
```

Per-op `status`: `applied` | `duplicate` (seq/op_id already applied — acknowledged, no change) | `conflict` (not applied, see §6.5) | `rejected` (validation error with `error.code`; the op is consumed so the queue can continue, the client surfaces it).

Request-level errors:

| Status / code | Meaning | Client action |
| --- | --- | --- |
| `409 seq_gap` (`details.expected_seq`) | First op's seq > `applied_seq + 1` | Resend from `expected_seq` (local queue is the source). |
| `409 seq_mismatch` | Same `(epoch, seq)` already applied with a different `op_id` | Client bug or two writers; fetch snapshot, rebuild. |
| `409 superseded` (`details.epoch`, `details.device_id`) | Lease moved to another device | Stop writing; show "Continued on another device"; offer *Resume here* (claim). Unsent local ops are kept for export/inspection, not silently dropped. |
| `409 workout_finalized` | Workout already completed | Fetch snapshot; mark local draft read-only. |
| `404 workout_not_found` | Start never reached the server | Send the queued start first (§5.1 offline start). |
| `5xx`, timeouts | Transient | Exponential backoff (1 s → 60 s cap, jitter); same batch, same seqs. |

### 6.3 Operation catalogue

All `data` objects name the entity they change by a client UUID. Unknown `exercise_performance_id` referenced together with an `exercise_prescription_id` creates the exercise performance implicitly with mode `as_prescribed` and `performed_ordinal` = prescription ordinal (so the common path needs no "create exercise" op).

| `type` | `data` | Effect in `exec` | UI trigger | Friction (UI) |
| --- | --- | --- | --- | --- |
| `upsert_set` | `set_performance_id`, `exercise_performance_id`, `prescribed_set_id` (nullable), `ordinal`, `status: "performed"`, `load_kg`, `repetitions`, `rir`, `comment?`, `heart_rate_bpm?`, `performed_at`, `if_rev?` | Insert/update one `set_performances` row. `prescribed_set_id: null` ⇒ **additional set**. | Confirm set · edit a recorded set · set note | none |
| `skip_set` | `set_performance_id`, `exercise_performance_id`, `prescribed_set_id`, `ordinal`, `comment?`, `if_rev?` | Row with status `skipped`, all numeric fields NULL (existing CHECK). | Skip set | hold 0.6 s |
| `clear_set` | `set_performance_id`, `if_rev?` | Delete the draft row (prescribed set becomes unrecorded again). Allowed only while `draft`. | Undo (6 s snackbar) · reopen | none |
| `add_set` | — | *Not a separate op:* an additional set is `upsert_set` with `prescribed_set_id: null` and a new ordinal. The UI still applies friction before allowing it. | Add extra set | hold 0.6 s |
| `set_exercise_comment` | `exercise_performance_id`, `exercise_prescription_id?`, `comment` (nullable to clear), `if_rev?` | Exercise-level **performance** comment (never the plan/prescription comment). | Exercise note | none |
| `skip_exercise` | `exercise_performance_id`, `exercise_prescription_id`, `comment?` | Mode `skipped`; any unrecorded prescribed sets get `skipped` rows; already performed sets stay. | Skip exercise | hold 1.2 s |
| `substitute_exercise` | `exercise_performance_id`, `exercise_prescription_id`, `actual_exercise_id`, `source: "plan_variant" \| "atlas"`, `variant_ordinal?` | Mode `substituted`, actual exercise FK set; prescribed exercise unchanged. Rejected `422 substitution_after_sets` if a performed set already exists. | Substitute exercise | picker + hold 1.2 s |
| `add_unplanned_exercise` | `exercise_performance_id`, `actual_exercise_id`, `performed_ordinal` | New exercise performance with mode `added`, no prescription FK. Its sets are `upsert_set` with `prescribed_set_id: null`. | Add unplanned exercise | picker + hold 1.4 s |
| `reorder_exercises` | `order: [exercise_performance_id, …]` (complete list of the workout's exercise performances, including not-yet-started prescribed ones) | Writes `performed_ordinal` for each. Prescription ordinals unchanged; "order changed" = any `performed_ordinal ≠ prescription ordinal`. Idempotent (full order). | Do next (outline) | hold 1.0 s |
| `set_cursor` | `exercise_performance_id`, `set_ordinal`, `phase: "set" \| "exercise_complete"` | Updates `position_hint` only. No domain effect. Coalescible. | Advancing / starting next exercise | none |
| `set_workout_comment` | `comment` | Workout-level performance comment (optional, reserved; v1 UI does not expose it). | — | — |

Validation (`rejected` with codes): `load_out_of_range` (0–1000 kg), `reps_out_of_range`, `rir_out_of_range`, `ordinal_conflict` (two set performances with the same ordinal in one exercise performance), `unknown_prescription_ref`, `prescription_ref_mismatch` (set prescription not under that exercise prescription), `exercise_not_found`, `substitution_after_sets`, `workout_not_draft`.

Explicitly **not** validated as errors: load ≠ prescribed, reps outside the target band, RIR ≠ target. These are normal field data.

### 6.4 Client-side identifiers

| Entity | Id | Generated |
| --- | --- | --- |
| Workout | `workout_id` UUIDv4 | at *Start* tap, persisted before any network call |
| Prescribed exercise performance | `exercise_performance_id` = UUIDv5(`workout_id`, `"ex:" + exercise_prescription_id`) | deterministic → re-derivable after local-store loss |
| Prescribed set performance | `set_performance_id` = UUIDv5(`workout_id`, `"set:" + set_prescription_id`) | deterministic |
| Additional set / unplanned exercise | UUIDv4 | at the confirm/hold moment |
| Op | `op_id` UUIDv4 + `(epoch, seq)` | when enqueued |

Deterministic ids for prescribed rows mean a retried skip and a later upsert address the same row, and a reinstalled client that pulls the snapshot computes identical ids.

### 6.5 Conflicts

Writers other than the lease holder are rare (desktop corrections during a workout). Rules:

1. Every exercise and set performance has `rev` (increments on each change).
2. An op may carry `if_rev`. The client sets it to the `rev` it last saw for that entity (from snapshot or a previous `entity_rev` result); for a brand-new entity it omits it.
3. If `if_rev` is present and differs from the server's `rev` **and** the stored values differ from the op's values, the op is consumed with `status: "conflict"` and `server_state` (the current entity). Identical values → `applied` (no false conflicts).
4. The client keeps working; the sync pill turns *Conflict*; the sheet shows *This phone* vs *Server* and offers **Keep this phone's value** (re-send `upsert_set` with `if_rev` = server rev) or **Use server value** (adopt locally, no op).
5. Desktop writes to an `in_progress` draft should go through the same rev check (backend concern; the desktop API returns its own conflict).

### 6.6 Delivery guarantees the client relies on

- At-least-once delivery, exactly-once effect (by `(workout, epoch, seq)` + `op_id`).
- Total order per workout per epoch.
- A `200` means the ops are committed; the client may then drop them from the queue.
- The snapshot's `applied_seq` + local queue = complete state; nothing else needs to be persisted server-side for resume.

---

## 7. Atlas for mobile

### 7.1 `GET /atlas/exercises/{exercise_id}/peek` → `AtlasPeek`

Compact data for the Quick Peek sheet; also embedded in the prescription payload for offline use.

```json
{
  "exercise": { "id": 112, "slug": "flat_bench_barbell_press", "name": "Bench Press", "full_name": "Flat Bench Barbell Press" },
  "tags": ["Upper body", "Chest", "Heavy Compound", "Free Weight", "Bilateral"],
  "technique_tldr": {
    "setup": "…", "execution": "…", "focus": "…", "stop_when": "…"
  },
  "muscles_top": [
    { "muscle_id": 31, "slug": "pectoralis_major_sternocostal", "name": "Musculus pectoralis major, pars sternocostalis", "etu_cm2": 142.6, "capacity_share": 0.81 }
  ],
  "body_map": {
    "asset": "human.svg",
    "asset_version": "v2",
    "regions": [ { "region_id": "pec_major_sternal_l", "intensity": 0.81 }, { "region_id": "pec_major_sternal_r", "intensity": 0.81 } ]
  },
  "content_locale": "en",
  "atlas_version": "0.1"
}
```

- `muscles_top`: at most 5, ordered by ETU; same numbers as the desktop "Muscle ETU exposure" table.
- `body_map.regions` uses the region ids already present in `human.svg`, so the client can colour the same SVG the desktop uses (no raster per exercise). Intensity `0..1` = normalized ETU, as the desktop legend "0 → max".
- `technique_tldr` = the four TL;DR items of the desktop *Technique* section (Setup, Execution, Focus, Stop when). Missing items are `null`.
- Localized via `Accept-Language` with the existing content-locale negotiation; `content_locale` says which locale was served.

### 7.2 `GET /atlas/exercises?q=&limit=&plan_run_id=`

Compact search for the substitution and *add unplanned* pickers.

```json
{ "items": [
  { "id": 141, "slug": "smith_incline_bench_press", "name": "Smith Machine Incline Press", "full_name": "Smith Machine Incline Bench Press",
    "mechanics_tier": "Heavy Compound", "target_category": "Chest",
    "last_performed_in_run": { "microcycle_ordinal": 2, "sets": [ { "load_kg": 50, "repetitions": 10, "rir": 2 } ] } }
] }
```

`last_performed_in_run` (only with `plan_run_id`) lets the client prefill load after a substitution ("Last Smith Machine Incline Press in this run (MC2): 50×10 / 50×9 / 50×8"). Search is name/alias/slug, locale-aware, max 30 results.

### 7.3 Full article

The full Atlas workspace uses the **existing** Atlas exercise and muscle detail reads that the Vue app already calls (by slug or id). They are reused unchanged; mobile only needs:

- stable addressing by `core.exercises.id` **or** `slug` (both are in every mobile DTO);
- the same `Accept-Language` negotiation;
- `ETag` support so open Atlas tabs can be revalidated cheaply.

Gaps to check in the existing reads (not invented here): whether the detail response already includes the TL;DR technique block and `human.svg` region intensities in one call; if not, the peek endpoint is the place to aggregate them rather than changing the desktop read.

---

## 8. Client-only vs server-synchronized

| Data | Where | Why |
| --- | --- | --- |
| Rest timer (`rest_ends_at`, duration, adjustments) | **Client only** (local store, timestamp-based) | Survives kill/restart from the timestamp; no analytic value beyond what `performed_at` gives. |
| Draft entry values not yet confirmed (load stepper position, selected reps/RIR) | Client only | Not a fact until *Confirm set*. Restored locally after restart. |
| Current position (exercise / set / phase) | Client authoritative; mirrored by `set_cursor` | Needed for another device's resume hint only. |
| Open Atlas workspaces and scroll positions | Client only | UI state. |
| Selected plan run | Client only (v1) | No athlete identity yet. |
| Started/finished timestamps, set `performed_at` | **Server** | Facts; enable rest/duration reconstruction and ordering. |
| Every set performance, skip, extra set, substitution, unplanned exercise, reorder, comments | **Server** via ops | Field data for Post-Workout-Analysis. |
| Heart rate per set | Server (when column exists) | Future field data. |

---

## 9. Required backend additions (minimal)

1. `client_uuid uuid UNIQUE` on `exec.workout_unit_performances`, `exec.exercise_unit_performances`, `exec.set_performances`.
2. On `workout_unit_performances`: `lease_device_id text`, `lease_epoch int NOT NULL DEFAULT 1`, `applied_seq int NOT NULL DEFAULT 0`, `revision int NOT NULL DEFAULT 0`, `position_hint` (two nullable columns, not JSON).
3. `rev int NOT NULL DEFAULT 0` on exercise and set performances.
4. `performed_ordinal int` on `exercise_unit_performances` (actual order; prescription ordinal stays on the prescription).
5. `performed_at timestamptz` on `set_performances` (+ server `received_at`).
6. `heart_rate_bpm smallint NULL CHECK (heart_rate_bpm BETWEEN 25 AND 250)` on `set_performances` — may land later; the API tolerates its absence.
7. Set status value for "left unrecorded at finish" (`not_performed`) if the existing `performed_set_status` enum lacks it; exercise execution mode `not_performed` likewise (see §10).
8. Table `exec.mobile_sync_ops` (append-only; PK `(workout_unit_performance_id, lease_epoch, seq)`, unique `op_id`).
9. Partial unique index guaranteeing one `in_progress` session per plan run.
10. On `workout_sessions`: `start_mode`, `off_schedule_selected_from`, and nullable
    `off_schedule_expected_session_id` for durable start-selection audit context.

All other facts already have relational homes (invariants table).

---

## 10. Open questions for the product owner / backend

1. **Additional/extraneous exposure semantics** — `next_track_exposure` is implemented for an existing planned occurrence. Creating an extra occurrence outside the plan remains undefined.
2. **`not_performed` vs `skipped`** — this contract distinguishes *deliberately skipped* (athlete acknowledged) from *not reached before finishing* (`not_performed`). Confirm the enum values to add or map.
3. **`completion_mode` mapping at finalize** — which existing value represents "completed with deviations / incomplete"? Proposed rule: `as_planned` only when every prescribed set is performed and no structural op occurred.
4. **Substitution after sets** — v1 rejects it (one actual exercise per exercise performance). If mid-exercise machine swaps are common, model them as *skip remaining sets + add unplanned exercise* (current UI guidance) or extend the model.
5. **Discard an empty workout** — optional future endpoint allowing a start to be undone within N minutes when zero ops exist. Not in v1; the honest default is finishing with all `not_performed`.
6. **Athlete identity** — single active workout is currently enforced per plan run; becomes per athlete when auth lands. Leases already carry device ids.
7. **Desktop edits during `in_progress`** — should desktop be read-only for drafts? Simplest: yes, with an explicit "take over" on desktop mirroring `claim`.

---

## 11. Authentication dependency

The current backend intentionally defers user/athlete identity. This contract therefore:

- scopes all reads/writes by `plan_run_id` / `session_id` / `workout_id`;
- uses `X-Agonez-Device-Id` only for leases and diagnostics, **not** as authentication;
- must be placed behind whatever auth the desktop API adopts. When athlete identity exists, `/context` becomes per-athlete, plan-run selection may move server-side, and the single-active-workout constraint moves from plan run to athlete.

---

## 12. Sequence sketches

**Normal set (online)**

```text
tap Confirm ─► local store: set row + op#27 queued ─► UI: rest timer, "Saving…"
            ─► POST /ops {27}  ─► 200 applied_seq=27 ─► UI: "Saved"
```

**Offline, then killed, then reopened**

```text
ops #28–#31 queued (Offline · 4)  ─► app killed
reopen ─► local store has workout + queue ─► Home shows "Workout in progress · Resume"
       ─► (network back) POST /ops base_seq=27 {28..31} ─► 200 applied_seq=31
```

**Lost local store (reinstall)**

```text
GET /context ─► active_workout{workout_id, lease.is_this_device=false}
tap Resume here ─► POST /claim ─► snapshot (epoch 2) ─► continue with seq 1 (epoch 2)
```

**Finish**

```text
Finish (hold if incomplete) ─► finalize queued behind ops
─► POST /finalize {final_seq} ─► 200 completed ─► "Push A recorded · Synced"
   (offline: "Saved on this phone · finalised when you're back online")
```
