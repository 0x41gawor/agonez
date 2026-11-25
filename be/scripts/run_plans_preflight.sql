-- Pre-flight audit for migration 0019 (convert legacy runs to run plans).
--
-- Read-only: a single SELECT. It must return ZERO rows before 0019 is deployed. Every row is
-- a legacy run whose positional identity cannot be converted safely. Do not change a check to
-- make it pass; report the rows.
--
-- Design: docs/plan_modifications_during_plan_run/02-database-and-backend.md, sections 4.1
-- (the checks) and 4.2 (the mapping they protect). Works on the schema before and after 0018.
--
-- Run it with psql in a read-only session:
--
--   docker exec -i -e PGOPTIONS='-c default_transaction_read_only=on' <postgres container> \
--       psql -X -v ON_ERROR_STOP=1 -U <user> -d <database> < be/scripts/run_plans_preflight.sql
--
-- Columns: check_no and check_name; the run; the plan revision concerned (NULL when check 2
-- finds a malformed key); entity_kind, 'workout_unit' or 'exercise_slot', which says which
-- track table track_ids belong to and which plan table entity_ids belong to.
--
--   1  a workout track's sessions bind two different units of one revision
--   2  a workout track's sessions disagree with its day:N key
--   3  an exercise track's prescriptions point at two different slots of one revision
--   4  a unit or slot of the run's latest used revision has no track
--   5  two tracks map to the same unit or slot of one revision

WITH
-- Only runs that 0019 converts. Going through jsonb keeps the query valid before 0018 adds
-- run_plan_id: a missing column reads as NULL.
legacy_runs AS (
    SELECT run.id AS plan_run_id
    FROM exec.plan_runs AS run
    WHERE to_jsonb(run) ->> 'run_plan_id' IS NULL
),
plan_units AS (
    SELECT unit.id AS unit_id, day.revision_id, day.ordinal AS day_ordinal
    FROM plans.workout_unit_prescriptions AS unit
    JOIN plans.day_prescriptions AS day ON day.id = unit.day_id
),
plan_slots AS (
    SELECT slot.id AS slot_id, slot.workout_unit_id AS unit_id,
           slot.ordinal AS slot_ordinal, unit.revision_id
    FROM plans.exercise_slots AS slot
    JOIN plan_units AS unit ON unit.unit_id = slot.workout_unit_id
),
-- The revisions each run uses (references F2, F3, F6, F12 and F13 of the audit).
revision_references AS (
    SELECT microcycle.plan_run_id, microcycle.plan_revision_id AS revision_id,
           microcycle.ordinal AS microcycle_ordinal
    FROM exec.microcycles AS microcycle
    UNION ALL
    SELECT session.plan_run_id, day.revision_id, microcycle.ordinal
    FROM exec.workout_sessions AS session
    JOIN exec.microcycles AS microcycle ON microcycle.id = session.microcycle_id
    JOIN plans.day_prescriptions AS day ON day.id = session.source_plan_day_id
    UNION ALL
    SELECT session.plan_run_id, prescription.source_plan_revision_id, microcycle.ordinal
    FROM exec.workout_unit_prescriptions AS prescription
    JOIN exec.workout_sessions AS session ON session.id = prescription.workout_session_id
    JOIN exec.microcycles AS microcycle ON microcycle.id = session.microcycle_id
    UNION ALL
    SELECT event.plan_run_id, referenced.revision_id, microcycle.ordinal
    FROM exec.plan_run_events AS event
    CROSS JOIN LATERAL (
        VALUES (event.from_plan_revision_id), (event.to_plan_revision_id)
    ) AS referenced (revision_id)
    LEFT JOIN exec.microcycles AS microcycle ON microcycle.id = event.microcycle_id
    WHERE referenced.revision_id IS NOT NULL
),
run_revisions AS (
    SELECT plan_run_id, revision_id, min(microcycle_ordinal) AS first_ordinal
    FROM revision_references
    JOIN legacy_runs USING (plan_run_id)
    GROUP BY plan_run_id, revision_id
),
-- "Latest used": the revision whose first use is the latest microcycle.
latest_revisions AS (
    SELECT DISTINCT ON (used.plan_run_id) used.plan_run_id, used.revision_id
    FROM run_revisions AS used
    JOIN plans.plan_revisions AS revision ON revision.id = used.revision_id
    ORDER BY used.plan_run_id, used.first_ordinal DESC NULLS LAST,
             revision.revision_no DESC, used.revision_id DESC
),
workout_tracks AS (
    SELECT track.id AS track_id, track.plan_run_id, track.logical_key,
           substring(track.logical_key FROM '^day:([0-9]{1,9})$')::integer AS day_ordinal
    FROM exec.workout_unit_tracks AS track
    JOIN legacy_runs USING (plan_run_id)
),
exercise_tracks AS (
    SELECT track.id AS track_id, track.plan_run_id, track.workout_unit_track_id,
           substring(track.logical_key FROM '^slot:([0-9]{1,9})$')::integer AS slot_ordinal
    FROM exec.exercise_unit_tracks AS track
    JOIN legacy_runs USING (plan_run_id)
),
session_bindings AS (
    SELECT track.plan_run_id, track.track_id, track.logical_key,
           track.day_ordinal AS key_ordinal, session.id AS session_id,
           unit.unit_id, unit.revision_id, unit.day_ordinal AS unit_day_ordinal,
           source_day.revision_id AS source_day_revision_id,
           source_day.ordinal AS source_day_ordinal
    FROM workout_tracks AS track
    JOIN exec.workout_sessions AS session ON session.workout_unit_track_id = track.track_id
    JOIN plan_units AS unit ON unit.unit_id = session.source_plan_workout_unit_id
    JOIN plans.day_prescriptions AS source_day ON source_day.id = session.source_plan_day_id
),
prescription_bindings AS (
    SELECT track.plan_run_id, track.track_id, slot.slot_id, slot.revision_id
    FROM exercise_tracks AS track
    JOIN exec.exercise_unit_prescriptions AS prescription
      ON prescription.exercise_unit_track_id = track.track_id
    JOIN plan_slots AS slot ON slot.slot_id = prescription.source_plan_exercise_slot_id
),
-- How 0019 maps a track in each used revision: by bound id, otherwise by position.
workout_mappings AS (
    SELECT DISTINCT plan_run_id, track_id, revision_id, unit_id
    FROM session_bindings
    UNION ALL
    SELECT track.plan_run_id, track.track_id, used.revision_id, unit.unit_id
    FROM run_revisions AS used
    JOIN workout_tracks AS track ON track.plan_run_id = used.plan_run_id
    JOIN plan_units AS unit
      ON unit.revision_id = used.revision_id AND unit.day_ordinal = track.day_ordinal
    WHERE NOT EXISTS (
        SELECT 1
        FROM session_bindings AS bound
        WHERE bound.track_id = track.track_id AND bound.revision_id = used.revision_id
    )
),
exercise_mappings AS (
    SELECT DISTINCT plan_run_id, track_id, revision_id, slot_id
    FROM prescription_bindings
    UNION ALL
    SELECT track.plan_run_id, track.track_id, workout.revision_id, slot.slot_id
    FROM exercise_tracks AS track
    JOIN workout_mappings AS workout ON workout.track_id = track.workout_unit_track_id
    JOIN plan_slots AS slot
      ON slot.unit_id = workout.unit_id AND slot.slot_ordinal = track.slot_ordinal
    WHERE NOT EXISTS (
        SELECT 1
        FROM prescription_bindings AS bound
        WHERE bound.track_id = track.track_id AND bound.revision_id = workout.revision_id
    )
),
findings (check_no, check_name, plan_run_id, revision_id, entity_kind, track_ids, entity_ids)
AS (
    SELECT 1, 'workout_track_bound_to_two_units', plan_run_id, revision_id, 'workout_unit',
           ARRAY[track_id], array_agg(DISTINCT unit_id ORDER BY unit_id)
    FROM session_bindings
    GROUP BY plan_run_id, track_id, revision_id
    HAVING count(DISTINCT unit_id) > 1

    UNION ALL

    -- IS DISTINCT FROM also reports a key that is not day:N at all.
    SELECT 2, 'workout_session_disagrees_with_day_key', plan_run_id,
           CASE WHEN key_ordinal IS NOT NULL THEN revision_id END, 'workout_unit',
           ARRAY[track_id], array_agg(DISTINCT unit_id ORDER BY unit_id)
    FROM session_bindings
    WHERE key_ordinal IS DISTINCT FROM unit_day_ordinal
       OR key_ordinal IS DISTINCT FROM source_day_ordinal
       OR revision_id <> source_day_revision_id
    GROUP BY plan_run_id, track_id,
             CASE WHEN key_ordinal IS NOT NULL THEN revision_id END

    UNION ALL

    SELECT 3, 'exercise_track_prescribed_from_two_slots', plan_run_id, revision_id,
           'exercise_slot', ARRAY[track_id], array_agg(DISTINCT slot_id ORDER BY slot_id)
    FROM prescription_bindings
    GROUP BY plan_run_id, track_id, revision_id
    HAVING count(DISTINCT slot_id) > 1

    UNION ALL

    SELECT 4, 'latest_revision_unit_without_track', latest.plan_run_id, latest.revision_id,
           'workout_unit', ARRAY[]::integer[], ARRAY[unit.unit_id]
    FROM latest_revisions AS latest
    JOIN plan_units AS unit ON unit.revision_id = latest.revision_id
    WHERE NOT EXISTS (
        SELECT 1
        FROM workout_mappings AS mapping
        WHERE mapping.plan_run_id = latest.plan_run_id AND mapping.unit_id = unit.unit_id
    )

    UNION ALL

    SELECT 4, 'latest_revision_slot_without_track', latest.plan_run_id, latest.revision_id,
           'exercise_slot', ARRAY[]::integer[], ARRAY[slot.slot_id]
    FROM latest_revisions AS latest
    JOIN plan_slots AS slot ON slot.revision_id = latest.revision_id
    WHERE NOT EXISTS (
        SELECT 1
        FROM exercise_mappings AS mapping
        WHERE mapping.plan_run_id = latest.plan_run_id AND mapping.slot_id = slot.slot_id
    )

    UNION ALL

    SELECT 5, 'workout_unit_claimed_by_two_tracks', plan_run_id, revision_id, 'workout_unit',
           array_agg(DISTINCT track_id ORDER BY track_id), ARRAY[unit_id]
    FROM workout_mappings
    GROUP BY plan_run_id, revision_id, unit_id
    HAVING count(DISTINCT track_id) > 1

    UNION ALL

    SELECT 5, 'exercise_slot_claimed_by_two_tracks', plan_run_id, revision_id, 'exercise_slot',
           array_agg(DISTINCT track_id ORDER BY track_id), ARRAY[slot_id]
    FROM exercise_mappings
    GROUP BY plan_run_id, revision_id, slot_id
    HAVING count(DISTINCT track_id) > 1
)
SELECT check_no, check_name, plan_run_id, revision_id, entity_kind, track_ids, entity_ids
FROM findings
ORDER BY check_no, plan_run_id, revision_id, entity_kind, track_ids, entity_ids;
