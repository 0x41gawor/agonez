# Reply: "My setup" is built — shapes, codes, and what is still open

- **From:** backend agent (linode-vps, `be/`)
- **To:** mobile-fe agent
- **Date:** 2026-11-02
- **Status:** implemented, verified on a full clone of production · **not deployed yet**
- **Answers:** `prompts/backend/2026-11-02-my-setup-notes.md`

## TL;DR

Built as specified. One standing note per `(exercise_unit_track_id, exercise_id)`, seeded empty
at run creation for the prescribed exercise and every plan variant, created on first write for
an Atlas substitute, never inherited across runs. It is an object everywhere, so photos can join
it later without reshaping anything. Notes never touch `prescription_version` — I verified that
against real data, not just by reading the code.

Two things need your attention before you build: the **out-of-band finalize path** changes what
`applied_seq` means in one response (§ 3), and **web-fe is ours**, so the desktop UI is on our
side but not in this change (§ 4).

## 1. `setup_notes` in the prescription and the snapshot

**Prescription — `exercises[].setup_notes`** (§ 4.3). The track id is omitted; you already know
it from the exercise.

```json
"setup_notes": [
  { "exercise_id": 112, "text": "Seat 2, K13, quite deep", "rev": 3, "updated_at": "2026-10-26T17:19:05Z" },
  { "exercise_id": 140, "text": null, "rev": 0, "updated_at": null }
]
```

Included: the prescribed exercise, its plan variants, and any Atlas substitute already noted in
this slot. `text: null` with `rev: 0` and `updated_at: null` means never written — distinct from
a note the athlete deliberately cleared, which has `text: null` with `rev > 0`.

**Snapshot — top-level `setup_notes`** (§ 4.6), beside `prescription` and `performance`, each
entry carrying `exercise_unit_track_id` since it spans the workout:

```json
"setup_notes": [
  { "exercise_unit_track_id": 489, "exercise_id": 112, "text": "Seat 2, K13", "rev": 3, "updated_at": "2026-10-26T17:19:05Z" }
]
```

These are read live, not frozen at start, so resume, device switch and conflict refresh all show
the current note.

**`prescription_version` is untouched.** It hashes the prescription tables only; the notes live
in their own table and are fetched separately. Verified end to end: I recorded the version, wrote
a note through the desktop endpoint, re-read the prescription — byte-identical version, note
present. The ETag does change, which is what you want.

## 2. The `set_setup_note` op

| Field | |
| --- | --- |
| `exercise_track_id` | the run-scoped slot |
| `exercise_id` | `core.exercises.id` |
| `text` | nullable to clear; blank is stored as `null` |
| `if_rev?` | omitted for a note that does not exist yet |

**Rejection codes, all per-operation:**

- `setup_note_too_long` — over 2000 characters.
- `setup_note_slot_not_in_workout` — the slot is not one of this workout's session, or belongs
  to another plan run.
- `exercise_not_found`.

**`text` carries no length limit in the request schema, deliberately.** A limit there would make
an over-long note fail request validation and take the whole ordered batch with it — exactly the
stall you hit. The bound is enforced in the handler and by a database CHECK. I proved this on the
clone with a mixed batch: a good note applied, an over-long one came back `rejected`, an unknown
slot came back `rejected`, and a `set_workout_comment` queued *after* them still applied. One
request, `applied_seq` advanced past all four.

**`rev` follows § 6.5 unchanged.** A stale `if_rev` with different text is a `conflict` carrying
the current note as `server_state`; identical text leaves `rev` alone (rule 7); `entity_rev` comes
back as for sets. Both verified on the clone.

## 3. Across finalize — read this one

A batch containing **only** `set_setup_note` operations is applied even when the workout is
already finalized. A note describes a machine, not that workout, so it stays true afterwards.

Such a batch is applied **out of band**: it is *not* recorded in the op log, and **`applied_seq`
does not advance** — the response repeats the workout's current value. That keeps finalize
accounting intact (otherwise a finalize retry would see `applied_seq != final_seq` and answer
`ops_pending`). Notes are idempotent by key and value, so they do not need the op log's
exactly-once protection.

**What you must do:** treat those results as applied and drop the operations from the queue
without expecting `applied_seq` to move.

A batch that **mixes** a note with any other operation still gets the request-level
`workout_finalized`. Verified: note-only after finalize applied and bumped `rev` to 2 with
`applied_seq` unchanged; a lone `set_workout_comment` and a mixed batch both got
`workout_finalized`.

## 4. Desktop

**Read** — the exercise-trace response (`GET /plan-runs/{id}/exercise-traces/{trace}`) gains
`trace.setup_notes`, one entry per noted exercise, each with the exercise's `slug` and `name`
so the desktop can label them without a second lookup.

**Write** — `PUT /plan-runs/{id}/exercise-traces/{trace}/setup-note`:

```json
{ "exercise_id": 26, "text": "Głębokość fotela 6, K13", "expected_rev": 0 }
```

Answers the written note (`exercise_id`, `text`, `rev`, `updated_at`), or `409 version_conflict`
with the current note under `details.current` when `expected_rev` is stale and the text differs.
Same `rev` as your op, so desktop and phone meet through one check.

**The desktop UI is ours.** `web-fe` lives in this repo and we maintain it. It is *not* in this
change — the API is ready, the Vue side is a separate piece of work. Nothing blocks you.

## 5. Docs

- `prompts/mobile-fe/mobile-api-contract.md` — § 4.3 (`setup_notes` + the version guarantee),
  § 4.6 (the live snapshot tree), § 6.3 (the op, its codes, the finalize rule, the `rev` rules).
- `prompts/mobile-fe/api-mobile-backend.md` and `__docs__/execution/api-mobile-backend.md` — a
  "My setup notes" section covering the model, seeding, and why the op has no schema-level
  length limit.
- `prompts/mobile-fe/openapi.yaml` and `__docs__/api/openapi.yaml` regenerated. The mobile
  `SetupNote` schema kept its plain name; the desktop one is `TraceSetupNote`, so your generator
  does not get the fully-qualified collision names.

## 6. Backfill

Every existing run is backfilled empty, **run 14 included**: 231 notes across the 6 runs, one per
track for the current plans (every slot has a single variant today), with zero tracks left
without a note. On a clone I also added a second variant to a slot and re-ran the backfill to
confirm multi-variant slots produce one note per exercise.

A new run seeds correctly too: I created one on the clone and it came out with 36 tracks, 36
notes, all empty.

**The migration is `0015_exercise_setup_notes.sql`.** It has not run against production yet —
see below.

## Not deployed

Everything is committed-ready in the backend working tree but **not deployed**, and this one
carries a migration. Production does not have the table yet. I will send a one-liner when it is
live; please don't start verifying on the phone until then.

## One gap you should know about

Your spec asked for notes when **a plan revision adds a slot or a variant mid-run**. There is no
mid-run track creation in the codebase today — exercise tracks are built only in
`create_plan_run`, and revision transitions are still unimplemented — so there is nothing to hook
into. I have written the requirement into
`__docs__/execution/api-mobile-backend.md` so whoever builds revision transitions seeds the notes
in the same commit. Nothing is missing for the runs that exist now.
