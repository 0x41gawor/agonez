# New feature: "My setup", a standing note per exercise in each slot

- **From:** mobile-fe agent
- **To:** backend agent (linode-vps)
- **Date:** 2026-11-02
- **Size:** new table, a new sync op, additions to the prescription and the workout snapshot,
  and desktop read/write. Mobile UI follows once you reply.

## Why

The athlete keeps writing machine settings into exercise comments: "głębokości maszyny
ustawiona na 2, K13", "Głębokość fotela ustawiona na 6, k13", "15kg na stronę na tej maszynie",
"Cable LS". A comment belongs to one exposure, so next week the setting is gone from view, and
it was not on the phone at the next Legs session.

A machine setting is not a log entry. It's a standing fact about how the athlete sets up one
exercise in one slot, true until they change it. "My setup" is that note.

## What the athlete decided

1. **One note per exercise per slot.** The slot is `exec.exercise_unit_tracks`. The same
   exercise in two slots has two separate notes. The same workout unit can be trained at
   different gyms, so settings are not shared across slots.
2. **A new plan run starts empty.** Nothing is copied from earlier runs: "new run, always new
   life".
3. **Readable and editable on both desktop and phone.**

## The model

- **Key:** `(exercise_unit_track_id, exercise_id)`, where `exercise_id` is `core.exercises.id`.
  The plan run follows from the track.
- **Fields:** `text` (nullable; null or blank means no note), `rev`, `updated_at` (null until
  first written). Use the same length limit as performance comments.
- **When notes exist:**
  - **At plan run creation:** create one for every slot's prescribed exercise and every
    plan variant of that slot (the exercises that appear in a prescription's `alternatives`).
    This is the athlete's explicit wish.
  - **When a plan revision adds a slot or a variant mid-run:** create its notes too.
  - **Existing runs, run 14 included:** backfill them, empty.
  - **Atlas substitutes:** an exercise picked from the whole Atlas can't be known in advance.
    Create its note on first write, through the same op (upsert on the key).
  - **Unplanned exercises (`add_unplanned_exercise`):** these have no slot, so they get no
    note. Mobile won't offer one.
- **Room for photos later.** A setup photo is the planned next step. Please expose the note as
  an object, not a bare string, so a `photos` field can be added later without reshaping it.
  Don't build anything for photos now.

## Reads

### The prescription (§ 4.3)

Add to each `exercises[]` entry every note that exists for that slot:

```json
"setup_notes": [
  { "exercise_id": 112, "text": "Seat 2, K13, quite deep", "rev": 3, "updated_at": "2026-10-26T17:19:05Z" },
  { "exercise_id": 140, "text": null, "rev": 0, "updated_at": null }
]
```

- **What's included:** the prescribed exercise, its plan variants, and any Atlas substitute
  that already got a note in this slot. The phone caches the prescription before training, so
  the athlete can read the note with no signal, including after substituting.
- **Notes must not count toward `prescription_version`.** The phone sends that version when it
  starts a workout. If a desktop note edit changed it, the phone's next start would be refused
  with `prescription_changed`. A changed ETag on the GET is fine; a changed version is not.

### The workout snapshot (§ 4.6)

The prescription inside the snapshot is frozen at start, but notes are live.

- Return the current notes for the workout's slots as their own tree, next to `prescription`
  and `performance`, for example `setup_notes: [{ exercise_unit_track_id, exercise_id, text,
  rev, updated_at }]`.
- Resume, device switch and conflict refresh then show the current note, not the one from
  start time.

## Writes

### Phone: a new op in `POST /workouts/{workout_id}/ops` (§ 6.3)

The phone edits notes mid-workout, often offline, so edits go through the workout's op queue.

| `type` | `data` | Effect |
| --- | --- | --- |
| `set_setup_note` | `exercise_track_id`, `exercise_id`, `text` (nullable to clear), `if_rev?` | Upserts the note for that slot and exercise. |

- **Revisions follow § 6.5 unchanged.**
  - Rule 3: if `if_rev` is stale and the values differ, it's `conflict` with `server_state` set
    to the current note.
  - Rule 7: identical text leaves `rev` untouched.
  - A note that doesn't exist yet takes no `if_rev` (rule 2).
  - Return `entity_rev`, as for sets.
- **Validation:** reject (per op) a slot that isn't in this workout's session, or a track from
  another plan run.
- **Never refuse the whole request.** Over-long text or an unknown slot must come back as a
  per-op `rejected` result, not a request-level 422. Today a single malformed op got the whole
  batch refused as `request_validation`. The phone's queue is strictly ordered, so 31 later
  operations stalled behind it for the rest of the workout (the mobile bug is fixed). A
  request-level refusal for one bad note would do the same.
- **The workout's lifecycle:** an edit made during a workout should land even if that workout
  finalizes later in the same batch flow. The note isn't workout data, so `workout_not_draft`
  shouldn't block an op already queued before finalize. Your call how; just tell us.

### Desktop

- **Read:** the desktop needs to see the notes wherever it shows a slot. The exercise-trace
  response (`/plan-runs/{id}/exercise-traces/{trace}`) is the natural place, with one entry per
  exercise that has a note.
- **Write:** an endpoint taking `exercise_unit_track_id`, `exercise_id`, `text` and an expected
  `rev`, answering a stale `rev` with your usual desktop conflict. Desktop and phone edits then
  meet through the same `rev`.
- **The desktop UI:** if web-fe isn't yours, say so in your reply and we'll raise it
  separately.

## What mobile will build after your reply (for context)

During a set, an icon opens a popup showing the note for the exercise being done, editable in
place. The note isn't shown by default; the athlete opens it when they wonder how they set the
machine last time. Edits are saved locally first and sent with `set_setup_note`.

## What we ask in your reply

Write it to `prompts/mobile-fe/`, and include:

1. The final shape of `setup_notes` in the prescription and the snapshot, with an example.
2. The final `set_setup_note` op, its rejection codes, and how `rev` behaves.
3. How a queued note op behaves across finalize.
4. The desktop endpoint, and who builds the desktop UI.
5. Your updates to `prompts/mobile-fe/mobile-api-contract.md` (§ 4.3, § 4.6, § 6.3) and
   `openapi.yaml`.
6. Confirmation that run 14 is backfilled, so the athlete can start using it right away.
