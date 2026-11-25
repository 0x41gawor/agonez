# 03 — Execution Reconciliation

How an Apply (`01` D7/D8/D10) changes Execution, and why nothing historical moves.

---

## 1. Definitions

| Term | Definition |
| --- | --- |
| `today` | `ExecutionService._today()` — the same injectable clock used by `reconcile()` (`execution/service.py:67`). |
| Current microcycle | The run's microcycle with `starts_on <= today <= ends_on` (none before the run starts or after it ends). |
| Executed session | `in_progress` or `completed` (has a performance artifact; DB-enforced). |
| **Pending session** | A session that can still be executed: `scheduled`; or `cancelled` with `scheduled_date >= today` (it can be un-cancelled, `execution/repository.py:1504-1526`); or `missed` **and recoverable**, i.e. ordered after its track's latest executed occurrence — exactly the missed occurrences `startable_session_ids` (`mobile_execution/repository.py:81`) can return. |
| **Settled session** | Unexecuted but terminal: non-recoverable `missed`, or `cancelled` with `scheduled_date < today`. |
| Surviving workout | A workout track whose `plan_lineage_key` exists in the new revision. |
| Retired workout / exercise | A track whose lineage is absent from the current revision (workout) or from its workout in the current revision (exercise). Computed, not stored. |
| Bound revision | Revision of the session's `source_plan_day_id`. |

Only **pending** sessions are ever touched. Executed and settled sessions keep their binding,
date, status and prescriptions.
A pending **cancelled** session is touched in one way only: its content is rebound when its workout
survives. Status and date never change, and it is never deleted (`01` I6).

---

## 2. Apply algorithm

```python
async def apply(run_id, req, today, dry_run):
    async with conn.transaction(force_rollback=dry_run):
        SET CONSTRAINTS ALL DEFERRED
        SELECT pg_advisory_xact_lock(674202114, run_id)
        run   = SELECT * FROM exec.plan_runs WHERE id = run_id FOR UPDATE      # 404 plan_run_not_found
        require run.status in ('scheduled', 'active')                           # 409 run_plan_not_modifiable
        plan  = SELECT * FROM plans.workout_plans WHERE id = run.run_plan_id FOR UPDATE
        draft = SELECT * FROM plans.plan_revisions
                WHERE plan_id = plan.id AND status = 'DRAFT' FOR UPDATE
        current = latest RELEASED revision of plan

        sessions = SELECT … FROM exec.workout_sessions WHERE plan_run_id = run_id
                   ORDER BY id FOR UPDATE                            # deterministic lock order
        # 0. normalise date-owned states inside this transaction (same SQL as reconcile())
        mark past 'scheduled' sessions without performance as 'missed'; scheduled run -> active

        # 1. optimistic checks — the revision check runs first: a successful Apply bumps the
        #    draft lock_version, so a replay must be recognised before the lock comparison
        draft_rows, current_rows = load_revision_rows(draft.id), load_revision_rows(current.id)
        if current.id != req.expected_applied_revision_id:
            if fingerprint(draft_rows) == fingerprint(current_rows):
                return state(already_applied=True)                   # idempotent replay, 200
            409 run_plan_revision_conflict
        if draft.lock_version != req.draft_lock_version:            409 draft_version_conflict
        if fingerprint(draft_rows) == fingerprint(current_rows):    422 run_plan_unchanged

        # 2. executability (§3)
        issues = validate_executable(draft_rows, run.microcycle_duration_days)
        if issues:                                                   422 run_plan_not_executable

        # 3. snapshot the working copy
        n = current.revision_no + 1          # == draft.revision_no by construction
        # UNIQUE(plan_id, revision_no) is not deferrable: move the draft out of the way first
        UPDATE plans.plan_revisions SET revision_no = n + 1, lock_version = lock_version + 1,
               updated_at = now() WHERE id = draft.id
        new = INSERT plan_revisions(plan.id, n, 'RELEASED', based_on=current.id, released_at=now())
        UPDATE plans.plan_revisions SET based_on_revision_id = new.id WHERE id = draft.id
        copy_revision_tree(draft.id -> new.id, regenerate_progression_ids=False)
        tree = load_revision_tree(new.id)    # with lineage keys

        # 4. execution
        impact = Impact()
        sessions = reload_sessions(run_id)                           # already locked above
        tracks   = reconcile_tracks(run, tree, impact)               # §4
        reconcile_sessions(run, tree, tracks, sessions, today, impact)  # §5, §6
        ensure_sessions_for_active_workouts(run, tree, tracks, today, impact)  # §5.3
        UPDATE exec.microcycles SET plan_revision_id = new.id, updated_at = clock_timestamp()
         WHERE plan_run_id = run_id AND starts_on > today
        INSERT exec.plan_run_events(plan_run_id, microcycle_id = event_microcycle(run, today),
               event_type='plan_revision_changed', occurred_at=clock_timestamp(),
               title='Run plan modified', details=req.note,
               from_plan_revision_id=current.id, to_plan_revision_id=new.id,
               metadata={'kind':'run_plan_applied','_source':'system','impact': impact.summary()})
        UPDATE exec.plan_runs SET updated_at = clock_timestamp() WHERE id = run_id
        return ApplyOutcome(new, impact, dry_run)
```

`event_microcycle`: the current microcycle; before the run starts, microcycle 1; after `ends_on`,
the last microcycle.
`plan_runs.updated_at` changes, so desktop clients holding a run `version` refresh.

---

## 3. Executability validation (Apply and run creation)

| Code | Rule | Why |
| --- | --- | --- |
| `day_count_changed` | `len(days) == run.microcycle_duration_days` (Apply only) | D13: microcycle dates derive from it. |
| `no_workouts` | At least one day has a workout unit. | A run without sessions is meaningless. |
| `workout_without_exercises` | Every workout unit has ≥ 1 slot. | Fallback preparation rejects empty workouts (`mobile_execution/repository.py:754`). |
| `slot_without_exercise` | Every slot has exactly one DEFAULT variant. | No track/prescription can be built otherwise (`:767`). |
| `exercise_without_sets` | Every DEFAULT variant has ≥ 1 set. | A zero-set exercise yields a vacuous prescription. |
| `duplicate_lineage` | Lineage keys unique per revision (defensive; 500-class bug if hit). | Identity must be unambiguous. |

Each issue carries `{code, path, day_ordinal, slot_ordinal, message}`; `path` uses the PlanCreator
convention (`days.<ordinal>.workout_unit.exercise_slots.<ordinal>`) so the editor can highlight it.
One pure function, `validate_executable(rows, *, expected_day_count=None)` in
`modules/plans/executability.py`, serves both callers (built by T2.2, reused by T3.3):

- **Apply** passes the run's `microcycle_duration_days`; any issue → 422 `run_plan_not_executable`.
- **Run creation** (Q1, decided 2026-11-25) passes no day count, so `day_count_changed` never fires;
  any issue → 422 `plan_not_executable` with the same `issues` list, and nothing is created.
- **Library plans stay permissive**: My Plans can still save unfinished plans.

---

## 4. Track identity reconciliation

```python
def reconcile_tracks(run, tree, impact):
    wt_by_lineage = {t.plan_lineage_key: t for t in workout_tracks(run)}
    for unit in tree.workout_units:
        wt = wt_by_lineage.get(unit.lineage_key)
        if wt is None:
            wt = INSERT exec.workout_unit_tracks(plan_run_id, plan_lineage_key=unit.lineage_key,
                                                 logical_key=str(unit.lineage_key),
                                                 name=unit.name, description=unit.description)
            impact.workouts_added.append(wt)
        elif (wt.name, wt.description) != (unit.name, unit.description):
            UPDATE wt SET name, description          # label of the logical workout
        et_by_lineage = {e.plan_lineage_key: e for e in exercise_tracks(wt)}
        for slot in unit.slots:
            default = slot.default_variant
            et = et_by_lineage.get(slot.lineage_key)
            if et is None:
                et = INSERT exec.exercise_unit_tracks(plan_run_id, workout_unit_track_id=wt.id,
                         plan_lineage_key=slot.lineage_key, logical_key=str(slot.lineage_key),
                         name=slot.name or default.exercise_name,
                         source_progression_id=default.progression_id)
                impact.exercises_added.append(et)
            elif et.name != (slot.name or default.exercise_name):
                UPDATE et SET name
            for exercise_id in distinct(v.exercise_id for v in slot.variants):
                INSERT exec.exercise_setup_notes(et.id, exercise_id) ON CONFLICT DO NOTHING
    impact.workouts_retired = [t for t in workout_tracks(run) if t.lineage not in tree]
    impact.exercises_retired = [...]   # exercise tracks whose lineage is absent under their workout
```

- Tracks are never deleted: history references them.
- A slot moved to another workout is a new exercise track there; the old one is retired (D5).
- Re-adding a removed workout or exercise in PlanCreator creates new rows ⇒ new lineage ⇒ new
  track. History is never re-attached implicitly.

---

## 5. Session reconciliation

### 5.1 Pending sessions of surviving workouts — rebind

```python
for s in sessions if is_pending(s, today):
    unit = tree.unit_by_lineage.get(s.track.plan_lineage_key)
    if unit is None:
        handle_removed(s); continue                                   # §5.2
    new_date = s.microcycle.starts_on + unit.day.ordinal
    if s.status == 'cancelled':
        date = s.scheduled_date                                       # athlete cancellation: never moved
    elif s.microcycle.starts_on > today:                              # future microcycle
        date = new_date if not occupied_by_executed(s.microcycle, new_date, other_than=s) \
               else s.scheduled_date                                  # report redate_skipped
    else:
        date = s.scheduled_date                                       # current/past microcycle
    UPDATE exec.workout_sessions SET source_plan_day_id = unit.day.id,
           source_plan_workout_unit_id = unit.id, scheduled_date = date,
           updated_at = clock_timestamp() WHERE id = s.id
    rebase_prescription(s, unit)                                      # §6
```

Why the current microcycle keeps its dates: moving a workout to an earlier weekday would otherwise
create an instantly-missed session; moving it to a later one can collide with another kept session
(the timeline shows one session per date, `execution/service.py:2008-2028`). Day-position changes
therefore take effect from the next microcycle; content changes take effect immediately (v1
limitation, `01` §10).

Why cancellations keep their date: a cancellation records the athlete's decision about a specific
day. Rebinding its content is harmless (it only matters if the athlete un-cancels it), moving it is
not. A retained cancellation may therefore share a date with a re-dated or newly created session;
the timeline must prefer the non-cancelled session on such a date (T3.5).

### 5.2 Pending sessions of removed workouts

| Pending session | Action | Rationale |
| --- | --- | --- |
| `scheduled` with `scheduled_date >= today` | **Delete** the session (prescriptions cascade). Report `sessions.removed`; every `analysis` prescription lost this way is listed in `analysis_discarded` with reason `workout_removed`. | A projection, not history. Converting it to `cancelled` would inject non-athlete cancellations into adherence once the dates pass (`domain.attendance_for`). |
| `cancelled` (athlete cancellation, `scheduled_date >= today`) | **Keep** status, date and old binding. It becomes settled: `cancelled → scheduled` is refused with 409 `session_workout_removed` because the session is not bound to the current revision (`02` §3.4). Report `sessions.retained`. | Preserves the athlete's explicit decision (I6); it counts as cancelled in adherence when its date passes, exactly as before the modification. |
| Recoverable `missed` (date in the past) | Keep its binding to the old revision. It becomes settled: not startable because it is not bound to the current revision. Report `sessions.retained`. | The miss is a historical fact; the workout no longer exists to catch up. |

### 5.3 Ensure sessions for active workouts

```python
for unit in tree.workout_units:
    wt = track_for(unit)
    for mc in run.microcycles:
        if session_exists(mc, wt):  continue                      # UNIQUE(microcycle_id, track)
        date = mc.starts_on + unit.day.ordinal
        if date < today: continue                                 # never fabricate past sessions
        if mc is current and date_occupied(mc, date): report deferred_to_next_microcycle; continue
        # date_occupied = a non-cancelled session of the run already has this date;
        # retained cancellations never block a new session
        INSERT exec.workout_sessions(plan_run_id, microcycle_id=mc.id, workout_unit_track_id=wt.id,
               source_plan_day_id=unit.day.id, source_plan_workout_unit_id=unit.id,
               scheduled_date=date, status='scheduled')
        report sessions_added
```

This covers new workouts and any surviving workout missing a future occurrence.

### 5.4 Microcycles, run, attendance

- `microcycles.plan_revision_id := new` only where `starts_on > today` (D6).
- `plan_runs.microcycle_count`, `microcycle_duration_days`, `ends_on`: unchanged (D13).
- Attendance (`domain.attendance_for`) counts sessions with `scheduled_date <= as_of`; removed and
  added sessions are future-dated, so past adherence is unchanged. Retained athlete cancellations
  count as cancelled when due, as they would have without the modification.

---

## 6. Prescription rebase rules (pending, rebound sessions)

```python
def rebase_prescription(s, unit):
    wp = workout_prescription(s)
    if wp is None: return
    for ep in exercise_prescriptions(wp):
        if ep.generation_source == 'plan_fallback':
            DELETE ep                                     # regenerated by prepare-fallback
            impact.fallback_cleared += 1; continue
        slot = unit.slot_by_lineage.get(ep.track.plan_lineage_key)
        reason = ('slot_removed'          if slot is None else
                  'exercise_changed'      if slot.default.exercise_id != ep.prescribed_exercise_id else
                  'set_structure_changed' if roles(slot.default.sets) != roles(ep.sets) else None)
        if reason:
            DELETE ep
            impact.analysis_discarded.append({session_id, scheduled_date, exercise_trace_id,
                                              name, reason, loads: [...]})
            continue
        # compatible: keep loads/comments, refresh plan-derived snapshots
        UPDATE ep SET ordinal = slot.ordinal + 1000000 ...      # two-phase: UNIQUE(wp, ordinal) is not deferrable
        UPDATE ep SET ordinal = slot.ordinal,
               source_plan_exercise_slot_id = slot.id, source_plan_exercise_variant_id = slot.default.id,
               source_progression_id = slot.default.progression_id,
               slot_name_snapshot, plan_description_snapshot, plan_goal_snapshot, slot_role_snapshot,
               progression_model_slug_snapshot, load_step_kg_snapshot,
               updated_at = clock_timestamp()
        for each set (matched by ordinal):
            UPDATE exec.set_prescriptions SET source_plan_set_infra_id = new.id,
                   rep_min, rep_max, target_rir                  # role unchanged by the check
        impact.analysis_rebased += 1
    if no exercise prescriptions remain: DELETE wp
    else: UPDATE wp SET source_plan_revision_id = new_revision, source_plan_workout_unit_id = unit.id,
                     name/description/warmup/stretch snapshots, updated_at = clock_timestamp()
```

`roles(sets)` is the ordered list of set roles; equal lists imply equal count. The bumped
`updated_at` values change mobile `prescription_version` (`mobile_execution/repository.py:2953`) and
desktop `expected_version`, so stale clients get the existing conflict responses.

After Apply, a rebased session may have analysis rows for some slots and none for others (e.g. a new
slot). The existing fallback preparation keeps analysis rows and fills the rest
(`test_fallback_materialization_preserves_analysis_and_fills_missing_slots`); its completeness check
now passes because analysis rows match the current structure — this removes defect R6.

---

## 7. Behaviour matrix — session state × modification type

Legend: **—** no effect · **Rebind** session follows the new revision · **FB** fallback prescription
cleared (regenerated on demand) · **A✓** analysis prescription rebased (loads kept) · **A✗** analysis
prescription discarded and reported.

| Session state ↓ / Modification → | Workout notes / names / warmup | Add exercise | Remove exercise | Replace exercise | Edit sets' reps/RIR, model, load step | Add / remove sets, change set roles | Reorder exercises | Add workout (rest→training) | Remove workout (training→rest) | Move workout to another day |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **completed** | — | — | — | — | — | — | — | — | — (retired track; history kept) | — |
| **in_progress** | — (keeps old revision; finishes as prescribed) | — | — | — | — | — | — | — | — (finishes; track retired afterwards) | — |
| **scheduled, current microcycle, date ≥ today** | Rebind, FB, A✓ | Rebind, FB, A✓ (new slot unprescribed) | Rebind, FB, A✗ for removed slot | Rebind, FB, A✗ (`exercise_changed`) | Rebind, FB, A✓ (reps/RIR refreshed) | Rebind, FB, A✗ (`set_structure_changed`) | Rebind, FB, A✓ (ordinal updated) | Session created if date ≥ today and free | Session deleted | Rebind; **date unchanged** |
| **scheduled, future microcycle** | Rebind, FB, A✓ | as above | as above | as above | as above | as above | as above | Session created | Session deleted | Rebind; **re-dated** to new day (unless the date holds an executed session) |
| **missed, recoverable** | Rebind, FB, A✓ | as above | as above | as above | as above | as above | as above | — (no past sessions fabricated) | Kept, old binding, no longer startable | Rebind; date unchanged |
| **missed, not recoverable** (settled) | — | — | — | — | — | — | — | — | — | — |
| **cancelled, date ≥ today** (athlete cancellation) | Rebind content; status and date kept | same | same | same | same | same | same | — | **Kept** (old binding, status, date); un-cancel refused (`session_workout_removed`) | Rebind content; **date never changed** |
| **cancelled, date < today** (settled) | — | — | — | — | — | — | — | — | — | — |

Plan identity edits (name, description, accent, cover) never pass through Apply (D14) and affect no
session. Day icon edits follow the "workout notes" column.

---

## 8. Worked example — mid-week modification

Run: 7-day microcycles starting Monday. Week 3 = microcycle 3 (Mon 15 … Sun 21). Push A (Mon),
Pull A (Tue), Legs (Thu), Push B (Sat). Today = Wed 17. Pull A on Tue was not performed (missed,
recoverable). The athlete applies r2: replace *Pec Deck* in Push B with *Cable Fly*, add a 4th set to
Squat in Legs, move Legs from Thu to Fri.

| Session | State | Outcome |
| --- | --- | --- |
| W3 Push A (Mon 15) | completed | — (bound to r1) |
| W3 Pull A (Tue 16) | missed, recoverable | Rebound to r2 (no content change); if caught up today it runs r2. |
| W3 Legs (Thu 18) | scheduled | Rebound to r2: 4 Squat sets; **stays Thu 18** (current microcycle); its saved analysis Squat prescription is discarded (`set_structure_changed`) and listed. |
| W3 Push B (Sat 20) | scheduled | Rebound; Pec Deck analysis prescription discarded (`exercise_changed`); same exercise track; Cable Fly has no load default (first exposure). |
| W4+ Legs | scheduled | Rebound and re-dated to Friday. |
| W4+ all others | scheduled | Rebound to r2. |
| Microcycles 4–8 | — | `plan_revision_id := r2`; microcycle 3 stays r1 (revision in effect when it started). |
| Event | — | `plan_revision_changed` r1→r2 in microcycle 3 with the impact summary. |

---

## 9. Progression-loop continuity

| Change | Exercise track | `progression_id` | Load basis / defaults |
| --- | --- | --- | --- |
| Edit sets, reps, RIR, role | same | preserved | continues; `RepeatLastExposureAgent` maps by role rank (`progression.py:98`), so growing from 3 to 4 working sets repeats the third load. |
| Reorder exercises | same (lineage) | preserved | continues (fixes R3). |
| Replace DEFAULT exercise | same | preserved unless the athlete changes it | **restarts**: mobile requires `actual_exercise_id = variant.exercise_id` (`mobile_execution/repository.py:716-740`); PWA defaults fixed to require the same exercise (`02` §3.5). |
| Change progression model | same | preserved | next prescription uses the new model's agent (today: default agent for all). |
| Remove + add exercise | new track | new (new variant row) | starts empty. |
| Move exercise to another workout | new track in the target workout | preserved on the moved variant row | starts empty in the new workout (no silent cross-workout transfer). |
| Shared loops (several variants share a `progression_id`) | per slot | preserved across copies | unchanged semantics (Execution uses `source_progression_id` as evidence only). |

"Latest exposure" (`_latest_exposure`, `execution/service.py:1556`) and history lookups are per track
and are unaffected. `resolve_next` (`domain.py:141`) keeps choosing the next target per track; only
the load defaults become exercise-aware.

---

## 10. Analytics: historical vs current

| Read | Source after this feature |
| --- | --- |
| Past exposures (traces, workout traces, exercise history) | Prescription/performance snapshots + the session's bound revision (immutable). |
| "Plan sets" shown next to the next target | Target session's bound revision = current revision. |
| Track labels, ordering, analysis queue, Run Plan view | Current revision; retired tracks flagged and listed after active ones. |
| Revision transitions | Consecutive exposures with different bound revisions. |
| Timeline day columns | Current revision; microcycles flagged where a `plan_revision_changed` event occurred. |
| Load series | Segmented by core exercise (D9). |
| Attendance | Unchanged formula. |
| PlanCreator Analysis tab | The working copy (design-time), as today. |

Timeline (required in T3.5): `_timeline_day` must prefer a non-cancelled session when a retained
cancellation shares a date with another session (one-line ordering change). Optional hardening:
expose all sessions of a date additively, and show past executed sessions with their prescription
`name_snapshot` instead of the current track label.

---

## 11. Errors, conflicts and recovery

| Situation | Response | Client recovery |
| --- | --- | --- |
| Run completed/cancelled | 409 `run_plan_not_modifiable` | Hide Apply; offer promotion. |
| Draft saved elsewhere since loaded | 409 `draft_version_conflict` `{current_lock_version}` | Reload working copy. |
| Another Apply happened | 409 `run_plan_revision_conflict` `{current_applied_revision_id}` | Reload state; re-run dry run. |
| Same draft already applied (retry) | 200 `already_applied: true` | Treat as success. |
| Nothing to apply | 422 `run_plan_unchanged` | Disable Apply. |
| Draft not executable | 422 `run_plan_not_executable` `{issues: [...]}` | Highlight paths in PlanCreator. |
| DB constraint/trigger failure | 500 (transaction rolled back, nothing changed) | Retry; report bug. |
| Un-cancel a cancellation of a removed workout (`PATCH …/sessions/{id}` → `scheduled`) | 409 `session_workout_removed` | Explain that the workout is no longer in the run plan. |
| Workout started on mobile during Apply | Serialised by advisory lock; whichever is first wins cleanly. | Mobile re-prepares on `prescription_changed`/`prescription_missing`. |

---

## 12. Post-Apply invariants (assert in integration tests)

1. Every pending session of a surviving workout is bound to the new revision.
2. No executed or settled session changed binding, date, status or prescription rows (compare
   before/after snapshots).
2a. No `cancelled` session was deleted, re-dated or changed status; the only sessions deleted are
   `scheduled` sessions of removed workouts dated today or later.
3. Every exercise prescription of a pending session references slots/variants/sets of the new
   revision, and its set roles equal the plan's.
4. Every workout unit and slot of the new revision maps to exactly one track; every track maps to at
   most one unit/slot.
5. At most one session per (microcycle, track); no new session has `scheduled_date < today`.
6. Microcycles with `starts_on > today` reference the new revision; others are unchanged.
7. Exactly one new `plan_revision_changed` event; the draft is renumbered to `new.revision_no + 1`
   and its `lock_version` increased by one.
8. With `dry_run=true`, a full-database row-count/hash comparison shows no change.
