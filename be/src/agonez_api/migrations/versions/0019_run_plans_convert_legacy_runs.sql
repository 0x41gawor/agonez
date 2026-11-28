-- Run plans, conversion part: every legacy plan run gets its own run plan.
-- Design: docs/plan_modifications_during_plan_run/02-database-and-backend.md §1.2 and §4.
--
-- BEFORE DEPLOYING the first build that contains this migration:
--   1. Take a backup: ./db_backup.sh in /home/agonez (02 §7, step B2: the code may then be rolled
--      back to the commit before this migration, never further).
--   2. Run the pre-flight audit read-only and expect zero rows:
--        docker exec -i -e PGOPTIONS='-c default_transaction_read_only=on' <postgres container> \
--            psql -X -v ON_ERROR_STOP=1 -U <user> -d <database> < be/scripts/run_plans_preflight.sql
--      The same audit runs again below and aborts the migration on any finding.
--
-- What it does, in the runner's single transaction (any error leaves the database unchanged):
--   * Locks the plans and exec tables against writes (reads continue) for its duration.
--   * Pre-flight (02 §4.1): the statement of be/scripts/run_plans_preflight.sql, verbatim without
--     its ORDER BY. Any row raises an exception.
--   * For every run with run_plan_id IS NULL, by id (02 §4.2): a run plan (scope run, the library
--     plan's name, description, accent and cover image, source_plan_id = library plan); one
--     RELEASED revision per library revision the run uses (references F2, F3, F6, F12, F13; in
--     order of first use; the last one is the pre-flight's "latest used" revision), each filled
--     by plans.copy_revision_tree(…, false); every F1-F13 reference of the run remapped through
--     the returned id maps, which are kept in public.agonez_0019_reference_map; new lineage keys
--     for the run's tracks, written to the units and slots each track maps to in every applied
--     revision (bound id first, else the day:N / slot:N position); a DRAFT working copy of the
--     last applied revision, copied after the backfill so it inherits the lineage keys.
--     Runs that already own a run plan (created by the run-plan aware run creation) are skipped.
--   * Verification (02 §4.3) and the constraints of 02 §1.2.
--
-- Tracks keep their positional logical_key labels (day:N, slot:N), and the copies keep every
-- ordinal, so the code before the identity refactor (T3.1) reads converted runs as before.
--
-- RELEASED revisions: library revisions, including the RELEASED revision 25 of plan 6 left by
-- the demo seed, are only read; no library row is written. The RELEASED revisions created here
-- receive their lineage keys before the migration commits, i.e. before anything can see them;
-- after that they are immutable like every applied revision (01 D16).
--
-- Duration on the 2026-11-28 backup (7 runs, 8 used library revisions, 360 sessions) in the
-- disposable postgres:15 test container (fsync off): the runner needs 350-380 ms instead of about
-- 20 ms with nothing pending; the conversion block alone 310-320 ms. Expect somewhat more with
-- fsync, still far below the API's 10 s statement_timeout, which PostgreSQL 15 applies to each
-- statement of this file separately. The tables stay locked against writes for that long.

LOCK TABLE
    plans.workout_plans,
    plans.plan_images,
    plans.plan_revisions,
    plans.day_prescriptions,
    plans.workout_unit_prescriptions,
    plans.exercise_slots,
    plans.exercise_slot_target_muscles,
    plans.exercise_variants,
    plans.set_infra_prescriptions,
    exec.plan_runs,
    exec.microcycles,
    exec.workout_unit_tracks,
    exec.exercise_unit_tracks,
    exec.workout_sessions,
    exec.workout_unit_prescriptions,
    exec.exercise_unit_prescriptions,
    exec.set_prescriptions,
    exec.workout_unit_performances,
    exec.exercise_unit_performances,
    exec.plan_run_events
IN EXCLUSIVE MODE;

-- Pre-flight (02 §4.1). Between the markers: be/scripts/run_plans_preflight.sql verbatim, without
-- its final ORDER BY (a test compares the two).
DO $preflight$
DECLARE
    finding_count integer;
    finding_list text;
BEGIN
    SELECT count(*),
           string_agg(
               format(
                   'check %s %s: run %s, revision %s, %s %s, tracks %s',
                   preflight.check_no, preflight.check_name, preflight.plan_run_id,
                   coalesce(preflight.revision_id::text, '-'), preflight.entity_kind,
                   preflight.entity_ids, preflight.track_ids
               ),
               E'\n'
               ORDER BY preflight.check_no, preflight.plan_run_id, preflight.revision_id,
                        preflight.entity_kind, preflight.track_ids, preflight.entity_ids
           )
    INTO finding_count, finding_list
    FROM (
-- preflight:begin
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
-- preflight:end
    ) AS preflight;

    IF finding_count > 0 THEN
        RAISE EXCEPTION 'migration 0019: the pre-flight audit found % problem(s)', finding_count
            USING DETAIL = finding_list,
                  HINT = 'Nothing was changed. Run be/scripts/run_plans_preflight.sql and fix the '
                         'listed runs (02 §4.1) before deploying again.';
    END IF;
END;
$preflight$;

-- The id maps of the copies (02 §4.2), kept for verification and for a manual reverse remap.
-- No foreign keys, so it never blocks a delete. Drop it after one release cycle.
CREATE TABLE public.agonez_0019_reference_map (
    plan_run_id integer NOT NULL,
    entity text NOT NULL,
    library_id integer NOT NULL,
    run_plan_id integer NOT NULL,
    PRIMARY KEY (plan_run_id, entity, library_id),
    CONSTRAINT agonez_0019_reference_map_entity_known CHECK (entity IN (
        'workout_plan', 'plan_revision', 'day', 'workout_unit', 'exercise_slot',
        'exercise_variant', 'set_infra'
    ))
);

COMMENT ON TABLE public.agonez_0019_reference_map IS
    'Migration 0019: for every converted plan run, which library row each run-plan row was copied from. Plain integers, no foreign keys. Drop after one release cycle.';
COMMENT ON COLUMN public.agonez_0019_reference_map.plan_run_id IS
    'The converted plan run (exec.plan_runs.id).';
COMMENT ON COLUMN public.agonez_0019_reference_map.entity IS
    'Table of both ids: workout_plan (plans.workout_plans), plan_revision (plans.plan_revisions), day, workout_unit, exercise_slot, exercise_variant, set_infra (the plans.copy_revision_tree entities).';
COMMENT ON COLUMN public.agonez_0019_reference_map.library_id IS
    'Id of the library row the run referenced before 0019.';
COMMENT ON COLUMN public.agonez_0019_reference_map.run_plan_id IS
    'Id of its copy in the run''s run plan, which the run references since 0019 (an applied revision; the DRAFT working copy is not mapped).';

-- Conversion (02 §4.2), one run at a time.
DO $convert$
DECLARE
    legacy record;
    used record;
    source_plan record;
    owned_plan_id integer;
    applied_count integer;
    applied_revision_id integer;
    previous_applied_id integer;
    working_copy_id integer;
BEGIN
    FOR legacy IN
        SELECT pr.id, pr.initial_plan_revision_id, pr.starts_on
        FROM exec.plan_runs AS pr
        WHERE pr.run_plan_id IS NULL
        ORDER BY pr.id
    LOOP
        SELECT wp.id, wp.name, wp.description, wp.accent, wp.scope
        INTO source_plan
        FROM plans.plan_revisions AS rev
        JOIN plans.workout_plans AS wp ON wp.id = rev.plan_id
        WHERE rev.id = legacy.initial_plan_revision_id;

        IF source_plan.scope <> 'library' THEN
            RAISE EXCEPTION 'migration 0019: run % starts from plan %, which is not a library plan',
                legacy.id, source_plan.id;
        END IF;

        IF EXISTS (
            SELECT 1
            FROM exec.microcycles AS mc
            JOIN plans.plan_revisions AS rev ON rev.id = mc.plan_revision_id
            WHERE mc.plan_run_id = legacy.id AND rev.plan_id <> source_plan.id
        ) OR EXISTS (
            SELECT 1
            FROM exec.workout_sessions AS ws
            JOIN plans.day_prescriptions AS dp ON dp.id = ws.source_plan_day_id
            JOIN plans.plan_revisions AS rev ON rev.id = dp.revision_id
            WHERE ws.plan_run_id = legacy.id AND rev.plan_id <> source_plan.id
        ) THEN
            RAISE EXCEPTION 'migration 0019: run % uses revisions of more than one plan', legacy.id;
        END IF;

        -- The run plan (D14: identity fields and the cover are copied, not versioned).
        INSERT INTO plans.workout_plans (name, description, accent, scope, source_plan_id)
        VALUES (source_plan.name, source_plan.description, source_plan.accent, 'run',
                source_plan.id)
        RETURNING id INTO owned_plan_id;

        INSERT INTO plans.plan_images (plan_id, content_type, byte_size, checksum, data, updated_at)
        SELECT owned_plan_id, img.content_type, img.byte_size, img.checksum, img.data,
               img.updated_at
        FROM plans.plan_images AS img
        WHERE img.plan_id = source_plan.id;

        INSERT INTO public.agonez_0019_reference_map (plan_run_id, entity, library_id, run_plan_id)
        VALUES (legacy.id, 'workout_plan', source_plan.id, owned_plan_id);

        -- One applied revision per used library revision, in order of first use. The order is the
        -- reverse of the pre-flight's "latest used" order, so the last copy is the revision whose
        -- coverage check 4 verified.
        applied_count := 0;
        previous_applied_id := NULL;
        FOR used IN
            WITH revision_references AS (
                SELECT mc.plan_revision_id AS revision_id, mc.ordinal, mc.starts_on
                FROM exec.microcycles AS mc
                WHERE mc.plan_run_id = legacy.id
                UNION ALL
                SELECT dp.revision_id, mc.ordinal, mc.starts_on
                FROM exec.workout_sessions AS ws
                JOIN exec.microcycles AS mc ON mc.id = ws.microcycle_id
                JOIN plans.day_prescriptions AS dp ON dp.id = ws.source_plan_day_id
                WHERE ws.plan_run_id = legacy.id
                UNION ALL
                SELECT wup.source_plan_revision_id, mc.ordinal, mc.starts_on
                FROM exec.workout_unit_prescriptions AS wup
                JOIN exec.workout_sessions AS ws ON ws.id = wup.workout_session_id
                JOIN exec.microcycles AS mc ON mc.id = ws.microcycle_id
                WHERE ws.plan_run_id = legacy.id
                UNION ALL
                SELECT ref.revision_id, mc.ordinal, mc.starts_on
                FROM exec.plan_run_events AS ev
                CROSS JOIN LATERAL (
                    VALUES (ev.from_plan_revision_id), (ev.to_plan_revision_id)
                ) AS ref (revision_id)
                LEFT JOIN exec.microcycles AS mc ON mc.id = ev.microcycle_id
                WHERE ev.plan_run_id = legacy.id AND ref.revision_id IS NOT NULL
            )
            SELECT rr.revision_id, min(rr.ordinal) AS first_ordinal,
                   min(rr.starts_on) AS first_starts_on
            FROM revision_references AS rr
            JOIN plans.plan_revisions AS rev ON rev.id = rr.revision_id
            GROUP BY rr.revision_id, rev.revision_no
            ORDER BY min(rr.ordinal) ASC NULLS FIRST, rev.revision_no, rr.revision_id
        LOOP
            applied_count := applied_count + 1;
            INSERT INTO plans.plan_revisions (
                plan_id, revision_no, status, based_on_revision_id, released_at
            )
            VALUES (
                owned_plan_id,
                applied_count,
                'RELEASED',
                coalesce(previous_applied_id, used.revision_id),
                coalesce(used.first_starts_on, legacy.starts_on)::timestamp AT TIME ZONE 'UTC'
            )
            RETURNING id INTO applied_revision_id;

            INSERT INTO public.agonez_0019_reference_map (
                plan_run_id, entity, library_id, run_plan_id
            )
            VALUES (legacy.id, 'plan_revision', used.revision_id, applied_revision_id);

            INSERT INTO public.agonez_0019_reference_map (
                plan_run_id, entity, library_id, run_plan_id
            )
            SELECT legacy.id, copied.entity, copied.source_id, copied.target_id
            FROM plans.copy_revision_tree(used.revision_id, applied_revision_id, false) AS copied;

            previous_applied_id := applied_revision_id;
        END LOOP;

        IF applied_count = 0 THEN
            RAISE EXCEPTION 'migration 0019: run % references no plan revision', legacy.id;
        END IF;

        -- Remap every exec reference of the run (F1-F13 of the audit). A reference without a map
        -- entry keeps its library id and makes the verification below fail.
        UPDATE exec.plan_runs AS target
        SET initial_plan_revision_id = map.run_plan_id
        FROM public.agonez_0019_reference_map AS map
        WHERE target.id = legacy.id
          AND map.plan_run_id = legacy.id
          AND map.entity = 'plan_revision'
          AND map.library_id = target.initial_plan_revision_id;

        UPDATE exec.microcycles AS target
        SET plan_revision_id = map.run_plan_id
        FROM public.agonez_0019_reference_map AS map
        WHERE target.plan_run_id = legacy.id
          AND map.plan_run_id = legacy.id
          AND map.entity = 'plan_revision'
          AND map.library_id = target.plan_revision_id;

        UPDATE exec.workout_sessions AS target
        SET source_plan_day_id = coalesce((
                SELECT map.run_plan_id FROM public.agonez_0019_reference_map AS map
                WHERE map.plan_run_id = legacy.id AND map.entity = 'day'
                  AND map.library_id = target.source_plan_day_id
            ), target.source_plan_day_id),
            source_plan_workout_unit_id = coalesce((
                SELECT map.run_plan_id FROM public.agonez_0019_reference_map AS map
                WHERE map.plan_run_id = legacy.id AND map.entity = 'workout_unit'
                  AND map.library_id = target.source_plan_workout_unit_id
            ), target.source_plan_workout_unit_id),
            fallback_source_plan_workout_unit_id = coalesce((
                SELECT map.run_plan_id FROM public.agonez_0019_reference_map AS map
                WHERE map.plan_run_id = legacy.id AND map.entity = 'workout_unit'
                  AND map.library_id = target.fallback_source_plan_workout_unit_id
            ), target.fallback_source_plan_workout_unit_id)
        WHERE target.plan_run_id = legacy.id;

        UPDATE exec.workout_unit_prescriptions AS target
        SET source_plan_revision_id = coalesce((
                SELECT map.run_plan_id FROM public.agonez_0019_reference_map AS map
                WHERE map.plan_run_id = legacy.id AND map.entity = 'plan_revision'
                  AND map.library_id = target.source_plan_revision_id
            ), target.source_plan_revision_id),
            source_plan_workout_unit_id = coalesce((
                SELECT map.run_plan_id FROM public.agonez_0019_reference_map AS map
                WHERE map.plan_run_id = legacy.id AND map.entity = 'workout_unit'
                  AND map.library_id = target.source_plan_workout_unit_id
            ), target.source_plan_workout_unit_id)
        FROM exec.workout_sessions AS ws
        WHERE ws.id = target.workout_session_id AND ws.plan_run_id = legacy.id;

        UPDATE exec.exercise_unit_prescriptions AS target
        SET source_plan_exercise_slot_id = coalesce((
                SELECT map.run_plan_id FROM public.agonez_0019_reference_map AS map
                WHERE map.plan_run_id = legacy.id AND map.entity = 'exercise_slot'
                  AND map.library_id = target.source_plan_exercise_slot_id
            ), target.source_plan_exercise_slot_id),
            source_plan_exercise_variant_id = coalesce((
                SELECT map.run_plan_id FROM public.agonez_0019_reference_map AS map
                WHERE map.plan_run_id = legacy.id AND map.entity = 'exercise_variant'
                  AND map.library_id = target.source_plan_exercise_variant_id
            ), target.source_plan_exercise_variant_id)
        FROM exec.workout_unit_prescriptions AS wup
        JOIN exec.workout_sessions AS ws ON ws.id = wup.workout_session_id
        WHERE wup.id = target.workout_unit_prescription_id AND ws.plan_run_id = legacy.id;

        UPDATE exec.set_prescriptions AS target
        SET source_plan_set_infra_id = map.run_plan_id
        FROM exec.exercise_unit_prescriptions AS eup
        JOIN exec.workout_unit_prescriptions AS wup ON wup.id = eup.workout_unit_prescription_id
        JOIN exec.workout_sessions AS ws ON ws.id = wup.workout_session_id
        JOIN public.agonez_0019_reference_map AS map
          ON map.plan_run_id = ws.plan_run_id AND map.entity = 'set_infra'
        WHERE eup.id = target.exercise_unit_prescription_id
          AND ws.plan_run_id = legacy.id
          AND map.library_id = target.source_plan_set_infra_id;

        UPDATE exec.exercise_unit_performances AS target
        SET actual_plan_exercise_variant_id = map.run_plan_id
        FROM exec.workout_unit_performances AS wupf
        JOIN exec.workout_unit_prescriptions AS wup ON wup.id = wupf.workout_unit_prescription_id
        JOIN exec.workout_sessions AS ws ON ws.id = wup.workout_session_id
        JOIN public.agonez_0019_reference_map AS map
          ON map.plan_run_id = ws.plan_run_id AND map.entity = 'exercise_variant'
        WHERE wupf.id = target.workout_unit_performance_id
          AND ws.plan_run_id = legacy.id
          AND map.library_id = target.actual_plan_exercise_variant_id;

        UPDATE exec.plan_run_events AS target
        SET from_plan_revision_id = coalesce((
                SELECT map.run_plan_id FROM public.agonez_0019_reference_map AS map
                WHERE map.plan_run_id = legacy.id AND map.entity = 'plan_revision'
                  AND map.library_id = target.from_plan_revision_id
            ), target.from_plan_revision_id),
            to_plan_revision_id = coalesce((
                SELECT map.run_plan_id FROM public.agonez_0019_reference_map AS map
                WHERE map.plan_run_id = legacy.id AND map.entity = 'plan_revision'
                  AND map.library_id = target.to_plan_revision_id
            ), target.to_plan_revision_id)
        WHERE target.plan_run_id = legacy.id
          AND (target.from_plan_revision_id IS NOT NULL OR target.to_plan_revision_id IS NOT NULL);

        -- Lineage backfill (D5): a new key per track, written to the unit or slot the track maps
        -- to in every applied revision. The mapping is the pre-flight's, read on the copies: the
        -- bound row (sessions / exercise prescriptions) first, else the day:N / slot:N position,
        -- the slot under the workout track's unit. The pre-flight guarantees at most one row per
        -- track and revision and at most one track per row.
        UPDATE exec.workout_unit_tracks
        SET plan_lineage_key = gen_random_uuid()
        WHERE plan_run_id = legacy.id;

        UPDATE exec.exercise_unit_tracks
        SET plan_lineage_key = gen_random_uuid()
        WHERE plan_run_id = legacy.id;

        WITH run_units AS (
            SELECT wu.id AS unit_id, dp.revision_id, dp.ordinal AS day_ordinal
            FROM plans.workout_unit_prescriptions AS wu
            JOIN plans.day_prescriptions AS dp ON dp.id = wu.day_id
            JOIN plans.plan_revisions AS rev ON rev.id = dp.revision_id
            WHERE rev.plan_id = owned_plan_id
        ),
        run_slots AS (
            SELECT es.id AS slot_id, es.workout_unit_id AS unit_id, es.ordinal AS slot_ordinal,
                   ru.revision_id
            FROM plans.exercise_slots AS es
            JOIN run_units AS ru ON ru.unit_id = es.workout_unit_id
        ),
        workout_tracks AS (
            SELECT wt.id AS track_id, wt.plan_lineage_key,
                   substring(wt.logical_key FROM '^day:([0-9]{1,9})$')::integer AS day_ordinal
            FROM exec.workout_unit_tracks AS wt
            WHERE wt.plan_run_id = legacy.id
        ),
        exercise_tracks AS (
            SELECT et.id AS track_id, et.workout_unit_track_id, et.plan_lineage_key,
                   substring(et.logical_key FROM '^slot:([0-9]{1,9})$')::integer AS slot_ordinal
            FROM exec.exercise_unit_tracks AS et
            WHERE et.plan_run_id = legacy.id
        ),
        session_bindings AS (
            SELECT DISTINCT ws.workout_unit_track_id AS track_id, ru.revision_id, ru.unit_id
            FROM exec.workout_sessions AS ws
            JOIN run_units AS ru ON ru.unit_id = ws.source_plan_workout_unit_id
            WHERE ws.plan_run_id = legacy.id
        ),
        prescription_bindings AS (
            SELECT DISTINCT eup.exercise_unit_track_id AS track_id, rs.revision_id, rs.slot_id
            FROM exec.exercise_unit_prescriptions AS eup
            JOIN exercise_tracks AS et ON et.track_id = eup.exercise_unit_track_id
            JOIN run_slots AS rs ON rs.slot_id = eup.source_plan_exercise_slot_id
        ),
        workout_mappings AS (
            SELECT sb.track_id, sb.revision_id, sb.unit_id
            FROM session_bindings AS sb
            UNION ALL
            SELECT wt.track_id, ru.revision_id, ru.unit_id
            FROM workout_tracks AS wt
            JOIN run_units AS ru ON ru.day_ordinal = wt.day_ordinal
            WHERE NOT EXISTS (
                SELECT 1
                FROM session_bindings AS sb
                WHERE sb.track_id = wt.track_id AND sb.revision_id = ru.revision_id
            )
        ),
        exercise_mappings AS (
            SELECT pb.track_id, pb.revision_id, pb.slot_id
            FROM prescription_bindings AS pb
            UNION ALL
            SELECT et.track_id, wm.revision_id, rs.slot_id
            FROM exercise_tracks AS et
            JOIN workout_mappings AS wm ON wm.track_id = et.workout_unit_track_id
            JOIN run_slots AS rs
              ON rs.unit_id = wm.unit_id AND rs.slot_ordinal = et.slot_ordinal
            WHERE NOT EXISTS (
                SELECT 1
                FROM prescription_bindings AS pb
                WHERE pb.track_id = et.track_id AND pb.revision_id = wm.revision_id
            )
        ),
        -- A data-modifying WITH runs exactly once, whether or not the main statement reads it.
        keyed_units AS (
            UPDATE plans.workout_unit_prescriptions AS target
            SET lineage_key = wt.plan_lineage_key
            FROM workout_mappings AS wm
            JOIN workout_tracks AS wt ON wt.track_id = wm.track_id
            WHERE target.id = wm.unit_id
            RETURNING target.id
        )
        UPDATE plans.exercise_slots AS target
        SET lineage_key = et.plan_lineage_key
        FROM exercise_mappings AS em
        JOIN exercise_tracks AS et ON et.track_id = em.track_id
        WHERE target.id = em.slot_id;

        -- The working copy, copied after the backfill so that it inherits the lineage keys.
        INSERT INTO plans.plan_revisions (plan_id, revision_no, status, based_on_revision_id)
        VALUES (owned_plan_id, applied_count + 1, 'DRAFT', previous_applied_id)
        RETURNING id INTO working_copy_id;

        PERFORM 1 FROM plans.copy_revision_tree(previous_applied_id, working_copy_id, false);

        UPDATE exec.plan_runs SET run_plan_id = owned_plan_id WHERE id = legacy.id;
    END LOOP;
END;
$convert$;

-- Verification (02 §4.3 and I1), over every run, converted or not. Any failure aborts the
-- migration; nothing is changed.
DO $verify$
DECLARE
    problem text;
BEGIN
    WITH revision_plan AS (
        SELECT rev.id, rev.plan_id FROM plans.plan_revisions AS rev
    ),
    day_plan AS (
        SELECT dp.id, rev.plan_id
        FROM plans.day_prescriptions AS dp
        JOIN plans.plan_revisions AS rev ON rev.id = dp.revision_id
    ),
    unit_plan AS (
        SELECT wu.id, dp.plan_id
        FROM plans.workout_unit_prescriptions AS wu
        JOIN day_plan AS dp ON dp.id = wu.day_id
    ),
    slot_plan AS (
        SELECT es.id, up.plan_id
        FROM plans.exercise_slots AS es
        JOIN unit_plan AS up ON up.id = es.workout_unit_id
    ),
    variant_plan AS (
        SELECT ev.id, sp.plan_id
        FROM plans.exercise_variants AS ev
        JOIN slot_plan AS sp ON sp.id = ev.slot_id
    ),
    set_plan AS (
        SELECT si.id, vp.plan_id
        FROM plans.set_infra_prescriptions AS si
        JOIN variant_plan AS vp ON vp.id = si.exercise_variant_id
    ),
    -- (column, run, plan of the referenced row) for every F1-F13 reference.
    exec_references (reference, plan_run_id, plan_id) AS (
        SELECT 'F1 plan_runs.initial_plan_revision_id', pr.id, rp.plan_id
        FROM exec.plan_runs AS pr
        JOIN revision_plan AS rp ON rp.id = pr.initial_plan_revision_id
        UNION ALL
        SELECT 'F2 microcycles.plan_revision_id', mc.plan_run_id, rp.plan_id
        FROM exec.microcycles AS mc
        JOIN revision_plan AS rp ON rp.id = mc.plan_revision_id
        UNION ALL
        SELECT 'F3 workout_sessions.source_plan_day_id', ws.plan_run_id, dp.plan_id
        FROM exec.workout_sessions AS ws
        JOIN day_plan AS dp ON dp.id = ws.source_plan_day_id
        UNION ALL
        SELECT 'F4 workout_sessions.source_plan_workout_unit_id', ws.plan_run_id, up.plan_id
        FROM exec.workout_sessions AS ws
        JOIN unit_plan AS up ON up.id = ws.source_plan_workout_unit_id
        UNION ALL
        SELECT 'F5 workout_sessions.fallback_source_plan_workout_unit_id', ws.plan_run_id,
               up.plan_id
        FROM exec.workout_sessions AS ws
        JOIN unit_plan AS up ON up.id = ws.fallback_source_plan_workout_unit_id
        UNION ALL
        SELECT 'F6 workout_unit_prescriptions.source_plan_revision_id', ws.plan_run_id,
               rp.plan_id
        FROM exec.workout_unit_prescriptions AS wup
        JOIN exec.workout_sessions AS ws ON ws.id = wup.workout_session_id
        JOIN revision_plan AS rp ON rp.id = wup.source_plan_revision_id
        UNION ALL
        SELECT 'F7 workout_unit_prescriptions.source_plan_workout_unit_id', ws.plan_run_id,
               up.plan_id
        FROM exec.workout_unit_prescriptions AS wup
        JOIN exec.workout_sessions AS ws ON ws.id = wup.workout_session_id
        JOIN unit_plan AS up ON up.id = wup.source_plan_workout_unit_id
        UNION ALL
        SELECT 'F8 exercise_unit_prescriptions.source_plan_exercise_slot_id', ws.plan_run_id,
               sp.plan_id
        FROM exec.exercise_unit_prescriptions AS eup
        JOIN exec.workout_unit_prescriptions AS wup ON wup.id = eup.workout_unit_prescription_id
        JOIN exec.workout_sessions AS ws ON ws.id = wup.workout_session_id
        JOIN slot_plan AS sp ON sp.id = eup.source_plan_exercise_slot_id
        UNION ALL
        SELECT 'F9 exercise_unit_prescriptions.source_plan_exercise_variant_id', ws.plan_run_id,
               vp.plan_id
        FROM exec.exercise_unit_prescriptions AS eup
        JOIN exec.workout_unit_prescriptions AS wup ON wup.id = eup.workout_unit_prescription_id
        JOIN exec.workout_sessions AS ws ON ws.id = wup.workout_session_id
        JOIN variant_plan AS vp ON vp.id = eup.source_plan_exercise_variant_id
        UNION ALL
        SELECT 'F10 set_prescriptions.source_plan_set_infra_id', ws.plan_run_id, stp.plan_id
        FROM exec.set_prescriptions AS spr
        JOIN exec.exercise_unit_prescriptions AS eup ON eup.id = spr.exercise_unit_prescription_id
        JOIN exec.workout_unit_prescriptions AS wup ON wup.id = eup.workout_unit_prescription_id
        JOIN exec.workout_sessions AS ws ON ws.id = wup.workout_session_id
        JOIN set_plan AS stp ON stp.id = spr.source_plan_set_infra_id
        UNION ALL
        SELECT 'F11 exercise_unit_performances.actual_plan_exercise_variant_id', ws.plan_run_id,
               vp.plan_id
        FROM exec.exercise_unit_performances AS eupf
        JOIN exec.workout_unit_performances AS wupf
          ON wupf.id = eupf.workout_unit_performance_id
        JOIN exec.workout_unit_prescriptions AS wup ON wup.id = wupf.workout_unit_prescription_id
        JOIN exec.workout_sessions AS ws ON ws.id = wup.workout_session_id
        JOIN variant_plan AS vp ON vp.id = eupf.actual_plan_exercise_variant_id
        UNION ALL
        SELECT 'F12 plan_run_events.from_plan_revision_id', ev.plan_run_id, rp.plan_id
        FROM exec.plan_run_events AS ev
        JOIN revision_plan AS rp ON rp.id = ev.from_plan_revision_id
        UNION ALL
        SELECT 'F13 plan_run_events.to_plan_revision_id', ev.plan_run_id, rp.plan_id
        FROM exec.plan_run_events AS ev
        JOIN revision_plan AS rp ON rp.id = ev.to_plan_revision_id
    )
    SELECT string_agg(DISTINCT format('%s of run %s', ref.reference, ref.plan_run_id), ', ')
    INTO problem
    FROM exec_references AS ref
    JOIN exec.plan_runs AS pr ON pr.id = ref.plan_run_id
    WHERE pr.run_plan_id IS DISTINCT FROM ref.plan_id;

    IF problem IS NOT NULL THEN
        RAISE EXCEPTION 'migration 0019: references outside the run''s own run plan (I1): %',
            problem;
    END IF;

    SELECT string_agg(format('run %s', pr.id), ', ' ORDER BY pr.id)
    INTO problem
    FROM exec.plan_runs AS pr
    WHERE pr.run_plan_id IS NULL
       OR (SELECT count(*) FROM plans.plan_revisions AS rev
           WHERE rev.plan_id = pr.run_plan_id AND rev.status = 'DRAFT') <> 1
       OR NOT EXISTS (SELECT 1 FROM plans.plan_revisions AS rev
                      WHERE rev.plan_id = pr.run_plan_id AND rev.status = 'RELEASED');

    IF problem IS NOT NULL THEN
        RAISE EXCEPTION 'migration 0019: runs without a run plan of one DRAFT and at least one '
                        'RELEASED revision: %', problem;
    END IF;

    SELECT string_agg(DISTINCT format('run %s', ws.plan_run_id), ', ')
    INTO problem
    FROM exec.workout_sessions AS ws
    JOIN plans.day_prescriptions AS dp ON dp.id = ws.source_plan_day_id
    JOIN plans.plan_revisions AS rev ON rev.id = dp.revision_id
    WHERE rev.status <> 'RELEASED';

    IF problem IS NOT NULL THEN
        RAISE EXCEPTION 'migration 0019: sessions bound to a revision that is not applied: %',
            problem;
    END IF;

    SELECT string_agg(format('%s in revision %s', repeated.entity, repeated.revision_id), ', '
                      ORDER BY repeated.revision_id, repeated.entity)
    INTO problem
    FROM (
        SELECT DISTINCT keyed.entity, keyed.revision_id
        FROM (
            SELECT 'workout unit' AS entity, dp.revision_id, wu.lineage_key
            FROM plans.workout_unit_prescriptions AS wu
            JOIN plans.day_prescriptions AS dp ON dp.id = wu.day_id
            UNION ALL
            SELECT 'exercise slot', dp.revision_id, es.lineage_key
            FROM plans.exercise_slots AS es
            JOIN plans.workout_unit_prescriptions AS wu ON wu.id = es.workout_unit_id
            JOIN plans.day_prescriptions AS dp ON dp.id = wu.day_id
        ) AS keyed
        JOIN plans.plan_revisions AS rev ON rev.id = keyed.revision_id
        JOIN exec.plan_runs AS pr ON pr.run_plan_id = rev.plan_id
        GROUP BY keyed.entity, keyed.revision_id, keyed.lineage_key
        HAVING count(*) > 1
    ) AS repeated;

    IF problem IS NOT NULL THEN
        RAISE EXCEPTION 'migration 0019: a lineage key repeats within a run-plan revision: %',
            problem;
    END IF;
END;
$verify$;

-- Constraints (02 §1.2): every run owns a run plan and every track has a lineage key.
ALTER TABLE exec.plan_runs ALTER COLUMN run_plan_id SET NOT NULL;
ALTER TABLE exec.workout_unit_tracks
    ALTER COLUMN plan_lineage_key SET NOT NULL,
    ADD CONSTRAINT workout_unit_tracks_run_lineage_unique UNIQUE (plan_run_id, plan_lineage_key);
ALTER TABLE exec.exercise_unit_tracks
    ALTER COLUMN plan_lineage_key SET NOT NULL,
    ADD CONSTRAINT exercise_unit_tracks_workout_lineage_unique
        UNIQUE (workout_unit_track_id, plan_lineage_key);

COMMENT ON COLUMN exec.plan_runs.run_plan_id IS
    'The run plan (plans.workout_plans, scope run) this run executes and owns; one run per run plan. Runs created before run plans were converted by migration 0019.';
COMMENT ON COLUMN exec.workout_unit_tracks.plan_lineage_key IS
    'lineage_key of the run-plan workout units this track follows across revisions; unique per run. The identity of the track.';
COMMENT ON COLUMN exec.exercise_unit_tracks.plan_lineage_key IS
    'lineage_key of the run-plan exercise slots this track follows across revisions; unique within its workout track. The identity of the track.';
COMMENT ON COLUMN exec.workout_unit_tracks.logical_key IS
    'Label only. day:N for tracks created with the run, the lineage UUID text for tracks created by a run-plan Apply. Identity is plan_lineage_key.';
COMMENT ON COLUMN exec.exercise_unit_tracks.logical_key IS
    'Label only. slot:N for tracks created with the run, the lineage UUID text for tracks created by a run-plan Apply. Identity is plan_lineage_key.';
COMMENT ON COLUMN exec.microcycles.plan_revision_id IS
    'Run-plan revision in effect when the microcycle started. The governing revision of a session is the revision of its source_plan_day_id.';
