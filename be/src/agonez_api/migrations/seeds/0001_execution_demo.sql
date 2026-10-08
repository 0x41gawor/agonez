BEGIN;

DO $$
DECLARE
    source_plan_name constant text :=
        '5x week, Push-Pull-Legs, upper focus, volume redukcyjne';
    seed_key constant text := 'exec_demo_september_2026_v1';
    run_name constant text := 'Execution Demo — PPL Upper Focus 2026';
    source_plan_id integer;
    source_revision_id integer;
    evolved_revision_id integer;
    evolved_revision_no integer;
    run_id integer;
    microcycle_id integer;
    workout_track_id integer;
    exercise_track_id integer;
    session_id integer;
    workout_prescription_id integer;
    exercise_prescription_id integer;
    set_prescription_id integer;
    workout_performance_id integer;
    exercise_performance_id integer;
    previous_exercise_performance_id integer;
    actual_exercise_id integer;
    actual_variant_id integer;
    microcycle_ordinal integer;
    source_day record;
    source_workout record;
    source_slot record;
    source_target record;
    source_variant record;
    source_set record;
    copied_day_id integer;
    copied_workout_id integer;
    copied_slot_id integer;
    copied_variant_id integer;
    session_row record;
    exercise_row record;
    prescribed_set_row record;
    session_status exec.workout_session_status;
    performance_status exec.performance_status;
    exercise_mode exec.exercise_execution_mode;
    prescribed_load numeric(8,3);
    performed_load numeric(8,3);
    performed_repetitions smallint;
    performed_rir smallint;
    exercise_comment text;
    set_comment text;
    session_started_at timestamptz;
    session_completed_at timestamptz;
    exercise_slug text;
    etu_snapshot jsonb;
    copied_day_count integer;
BEGIN
    SELECT plan.id, revision.id
    INTO source_plan_id, source_revision_id
    FROM plans.workout_plans AS plan
    JOIN plans.plan_revisions AS revision ON revision.plan_id = plan.id
    WHERE plan.name = source_plan_name
      AND revision.revision_no = 1;

    IF source_revision_id IS NULL THEN
        RAISE EXCEPTION
            'Execution demo requires plan % revision 1',
            source_plan_name;
    END IF;

    SELECT count(*)
    INTO copied_day_count
    FROM plans.day_prescriptions
    WHERE revision_id = source_revision_id;

    IF copied_day_count = 0 THEN
        RAISE EXCEPTION 'Execution demo source revision % has no days', source_revision_id;
    END IF;

    DELETE FROM exec.plan_runs
    WHERE name = run_name
      AND initial_plan_revision_id = source_revision_id;

    SELECT revision.id, revision.revision_no
    INTO evolved_revision_id, evolved_revision_no
    FROM plans.plan_revisions AS revision
    WHERE revision.plan_id = source_plan_id
      AND revision.snapshot ->> 'seed_key' = seed_key;

    IF evolved_revision_id IS NULL THEN
        SELECT COALESCE(max(revision_no), 0) + 1
        INTO evolved_revision_no
        FROM plans.plan_revisions
        WHERE plan_id = source_plan_id;

        INSERT INTO plans.plan_revisions (
            plan_id,
            revision_no,
            status,
            based_on_revision_id,
            lock_version,
            snapshot,
            released_at
        )
        VALUES (
            source_plan_id,
            evolved_revision_no,
            'RELEASED',
            source_revision_id,
            1,
            jsonb_build_object(
                'seed_key', seed_key,
                'purpose', 'Execution demo revision transition'
            ),
            '2026-09-21 18:00:00+00'
        )
        RETURNING id INTO evolved_revision_id;
    ELSE
        DELETE FROM plans.day_prescriptions
        WHERE revision_id = evolved_revision_id;

        UPDATE plans.plan_revisions
        SET
            based_on_revision_id = source_revision_id,
            status = 'RELEASED',
            snapshot = jsonb_build_object(
                'seed_key', seed_key,
                'purpose', 'Execution demo revision transition'
            ),
            released_at = '2026-09-21 18:00:00+00',
            updated_at = now()
        WHERE id = evolved_revision_id;
    END IF;

    FOR source_day IN
        SELECT *
        FROM plans.day_prescriptions
        WHERE revision_id = source_revision_id
        ORDER BY ordinal
    LOOP
        INSERT INTO plans.day_prescriptions (
            revision_id,
            ordinal,
            name,
            description,
            weekday
        )
        VALUES (
            evolved_revision_id,
            source_day.ordinal,
            source_day.name,
            source_day.description,
            source_day.weekday
        )
        RETURNING id INTO copied_day_id;

        FOR source_workout IN
            SELECT *
            FROM plans.workout_unit_prescriptions
            WHERE day_id = source_day.id
        LOOP
            INSERT INTO plans.workout_unit_prescriptions (
                day_id,
                name,
                description,
                warmup_notes,
                stretch_notes
            )
            VALUES (
                copied_day_id,
                source_workout.name,
                source_workout.description,
                source_workout.warmup_notes,
                source_workout.stretch_notes
            )
            RETURNING id INTO copied_workout_id;

            FOR source_slot IN
                SELECT *
                FROM plans.exercise_slots
                WHERE workout_unit_id = source_workout.id
                ORDER BY ordinal
            LOOP
                INSERT INTO plans.exercise_slots (
                    workout_unit_id,
                    ordinal,
                    name,
                    description,
                    goal,
                    role,
                    volume_axis,
                    loading_mode,
                    loading_cycle
                )
                VALUES (
                    copied_workout_id,
                    source_slot.ordinal,
                    source_slot.name,
                    source_slot.description,
                    source_slot.goal,
                    source_slot.role,
                    source_slot.volume_axis,
                    source_slot.loading_mode,
                    source_slot.loading_cycle
                )
                RETURNING id INTO copied_slot_id;

                FOR source_target IN
                    SELECT *
                    FROM plans.exercise_slot_target_muscles
                    WHERE slot_id = source_slot.id
                LOOP
                    INSERT INTO plans.exercise_slot_target_muscles (slot_id, muscle_id)
                    VALUES (copied_slot_id, source_target.muscle_id);
                END LOOP;

                FOR source_variant IN
                    SELECT *
                    FROM plans.exercise_variants
                    WHERE slot_id = source_slot.id
                    ORDER BY ordinal
                LOOP
                    INSERT INTO plans.exercise_variants (
                        slot_id,
                        ordinal,
                        variant_type,
                        exercise_id,
                        progression_model_slug,
                        progression_id,
                        active_working_set_min,
                        active_working_set_max
                    )
                    VALUES (
                        copied_slot_id,
                        source_variant.ordinal,
                        source_variant.variant_type,
                        source_variant.exercise_id,
                        source_variant.progression_model_slug,
                        source_variant.progression_id,
                        source_variant.active_working_set_min,
                        source_variant.active_working_set_max
                    )
                    RETURNING id INTO copied_variant_id;

                    FOR source_set IN
                        SELECT *
                        FROM plans.set_infra_prescriptions
                        WHERE exercise_variant_id = source_variant.id
                        ORDER BY ordinal
                    LOOP
                        INSERT INTO plans.set_infra_prescriptions (
                            exercise_variant_id,
                            ordinal,
                            rep_min,
                            rep_max,
                            min_volume_level,
                            loading_mode,
                            loading_cycle,
                            role,
                            load_spec,
                            rep_range_semantics,
                            rir
                        )
                        VALUES (
                            copied_variant_id,
                            source_set.ordinal,
                            source_set.rep_min,
                            source_set.rep_max,
                            source_set.min_volume_level,
                            source_set.loading_mode,
                            source_set.loading_cycle,
                            source_set.role,
                            source_set.load_spec,
                            source_set.rep_range_semantics,
                            source_set.rir
                        );
                    END LOOP;
                END LOOP;
            END LOOP;
        END LOOP;
    END LOOP;

    UPDATE plans.exercise_slots AS slot
    SET description = concat_ws(
        E'\n',
        NULLIF(slot.description, ''),
        'Execution demo revision: preserve the trace and use a controlled reload after deload.'
    )
    FROM plans.exercise_variants AS variant
    JOIN core.exercises AS exercise ON exercise.id = variant.exercise_id
    WHERE variant.slot_id = slot.id
      AND variant.variant_type = 'DEFAULT'
      AND exercise.slug = 'barbell_bench_press'
      AND slot.workout_unit_id IN (
          SELECT workout.id
          FROM plans.workout_unit_prescriptions AS workout
          JOIN plans.day_prescriptions AS day ON day.id = workout.day_id
          WHERE day.revision_id = evolved_revision_id
      );

    INSERT INTO exec.plan_runs (
        name,
        description,
        initial_plan_revision_id,
        starts_on,
        microcycle_count,
        microcycle_duration_days,
        status
    )
    VALUES (
        run_name,
        'Deterministic September 2026 execution story for the existing five-day PPL plan.',
        source_revision_id,
        DATE '2026-09-01',
        8,
        copied_day_count,
        'active'
    )
    RETURNING id INTO run_id;

    FOR microcycle_ordinal IN 1..8 LOOP
        INSERT INTO exec.microcycles (
            plan_run_id,
            ordinal,
            starts_on,
            ends_on,
            plan_revision_id,
            classification,
            notes
        )
        VALUES (
            run_id,
            microcycle_ordinal,
            DATE '2026-09-01' + ((microcycle_ordinal - 1) * copied_day_count),
            DATE '2026-09-01' + (microcycle_ordinal * copied_day_count - 1),
            CASE
                WHEN microcycle_ordinal <= 3 THEN source_revision_id
                ELSE evolved_revision_id
            END,
            CASE
                WHEN microcycle_ordinal = 4 THEN 'deload'::exec.microcycle_classification
                WHEN microcycle_ordinal = 5 THEN 'reload'::exec.microcycle_classification
                ELSE 'normal'::exec.microcycle_classification
            END,
            CASE
                WHEN microcycle_ordinal = 3 THEN
                    'Fatigue accumulated; one Pull B session was missed during a short training break.'
                WHEN microcycle_ordinal = 4 THEN
                    'Deload and the first microcycle governed by the evolved plan revision.'
                WHEN microcycle_ordinal = 5 THEN
                    'Reload: return toward pre-deload loads without forcing linear progression.'
                WHEN microcycle_ordinal = 6 THEN
                    'Current microcycle on 2026-10-07; one workout is actively syncing.'
                ELSE NULL
            END
        );
    END LOOP;

    FOR source_workout IN
        SELECT
            workout.id,
            workout.name,
            workout.description,
            day.ordinal AS day_ordinal
        FROM plans.workout_unit_prescriptions AS workout
        JOIN plans.day_prescriptions AS day ON day.id = workout.day_id
        WHERE day.revision_id = source_revision_id
        ORDER BY day.ordinal
    LOOP
        INSERT INTO exec.workout_unit_tracks (
            plan_run_id,
            logical_key,
            name,
            description
        )
        VALUES (
            run_id,
            format('day:%s', source_workout.day_ordinal),
            source_workout.name,
            source_workout.description
        )
        RETURNING id INTO workout_track_id;

        FOR source_slot IN
            SELECT
                slot.ordinal,
                COALESCE(NULLIF(slot.name, ''), exercise.name) AS name,
                variant.progression_id
            FROM plans.exercise_slots AS slot
            JOIN plans.exercise_variants AS variant
                ON variant.slot_id = slot.id
                AND variant.variant_type = 'DEFAULT'
            JOIN core.exercises AS exercise ON exercise.id = variant.exercise_id
            WHERE slot.workout_unit_id = source_workout.id
            ORDER BY slot.ordinal
        LOOP
            INSERT INTO exec.exercise_unit_tracks (
                plan_run_id,
                workout_unit_track_id,
                logical_key,
                name,
                source_progression_id
            )
            VALUES (
                run_id,
                workout_track_id,
                format('slot:%s', source_slot.ordinal),
                source_slot.name,
                source_slot.progression_id
            );
        END LOOP;
    END LOOP;

    FOR microcycle_ordinal IN 1..8 LOOP
        SELECT id
        INTO microcycle_id
        FROM exec.microcycles
        WHERE plan_run_id = run_id
          AND ordinal = microcycle_ordinal;

        FOR source_workout IN
            SELECT
                workout.id,
                workout.name,
                day.id AS day_id,
                day.ordinal AS day_ordinal
            FROM plans.workout_unit_prescriptions AS workout
            JOIN plans.day_prescriptions AS day ON day.id = workout.day_id
            WHERE day.revision_id = CASE
                WHEN microcycle_ordinal <= 3 THEN source_revision_id
                ELSE evolved_revision_id
            END
            ORDER BY day.ordinal
        LOOP
            SELECT id
            INTO workout_track_id
            FROM exec.workout_unit_tracks
            WHERE plan_run_id = run_id
              AND logical_key = format('day:%s', source_workout.day_ordinal);

            session_status := CASE
                WHEN microcycle_ordinal <= 5 THEN 'completed'::exec.workout_session_status
                WHEN microcycle_ordinal = 6 AND source_workout.day_ordinal = 0
                    THEN 'completed'::exec.workout_session_status
                WHEN microcycle_ordinal = 6 AND source_workout.day_ordinal = 1
                    THEN 'in_progress'::exec.workout_session_status
                ELSE 'scheduled'::exec.workout_session_status
            END;

            IF microcycle_ordinal = 3 AND source_workout.day_ordinal = 4 THEN
                session_status := 'missed';
            ELSIF microcycle_ordinal = 4 AND source_workout.day_ordinal = 2 THEN
                session_status := 'cancelled';
            END IF;

            session_started_at := CASE
                WHEN session_status IN ('completed', 'in_progress') THEN
                    (
                        DATE '2026-09-01'
                        + ((microcycle_ordinal - 1) * copied_day_count)
                        + source_workout.day_ordinal
                    )::timestamp + TIME '17:30'
                ELSE NULL
            END;
            session_completed_at := CASE
                WHEN session_status = 'completed' THEN session_started_at + INTERVAL '90 minutes'
                ELSE NULL
            END;

            INSERT INTO exec.workout_sessions (
                plan_run_id,
                microcycle_id,
                workout_unit_track_id,
                source_plan_day_id,
                source_plan_workout_unit_id,
                scheduled_date,
                status,
                completion_mode,
                started_at,
                completed_at,
                notes
            )
            VALUES (
                run_id,
                microcycle_id,
                workout_track_id,
                source_workout.day_id,
                source_workout.id,
                DATE '2026-09-01'
                    + ((microcycle_ordinal - 1) * copied_day_count)
                    + source_workout.day_ordinal,
                session_status,
                CASE
                    WHEN session_status = 'completed' THEN 'as_prescribed'::exec.completion_mode
                    ELSE NULL
                END,
                session_started_at,
                session_completed_at,
                CASE
                    WHEN session_status = 'missed' THEN 'Short training break; not performed.'
                    WHEN session_status = 'cancelled' THEN 'Cancelled in advance to protect recovery during deload.'
                    WHEN session_status = 'in_progress' THEN 'Partial mobile-sync example.'
                    ELSE NULL
                END
            )
            RETURNING id INTO session_id;
        END LOOP;
    END LOOP;

    FOR session_row IN
        SELECT
            session.*,
            microcycle.ordinal AS microcycle_ordinal,
            microcycle.plan_revision_id,
            workout.name AS source_workout_name,
            workout.description AS source_workout_description,
            workout.warmup_notes,
            workout.stretch_notes
        FROM exec.workout_sessions AS session
        JOIN exec.microcycles AS microcycle ON microcycle.id = session.microcycle_id
        JOIN plans.workout_unit_prescriptions AS workout
            ON workout.id = session.source_plan_workout_unit_id
        WHERE session.plan_run_id = run_id
          AND microcycle.ordinal <= 6
        ORDER BY session.scheduled_date, session.id
    LOOP
        INSERT INTO exec.workout_unit_prescriptions (
            workout_session_id,
            source_plan_revision_id,
            source_plan_workout_unit_id,
            name_snapshot,
            description_snapshot,
            warmup_notes_snapshot,
            stretch_notes_snapshot,
            prescription_comment,
            prescribed_at
        )
        VALUES (
            session_row.id,
            session_row.plan_revision_id,
            session_row.source_plan_workout_unit_id,
            session_row.source_workout_name,
            session_row.source_workout_description,
            session_row.warmup_notes,
            session_row.stretch_notes,
            CASE
                WHEN session_row.microcycle_ordinal = 4 THEN
                    'Deload exposure: keep technique repeatable and leave extra reserve.'
                WHEN session_row.microcycle_ordinal = 5 THEN
                    'Reload exposure: rebuild from the deload instead of chasing a weekly PR.'
                ELSE NULL
            END,
            session_row.scheduled_date::timestamp - INTERVAL '12 hours'
        )
        RETURNING id INTO workout_prescription_id;

        FOR exercise_row IN
            SELECT
                slot.id AS slot_id,
                slot.ordinal AS slot_ordinal,
                slot.name AS slot_name,
                slot.description AS slot_description,
                slot.goal AS slot_goal,
                slot.role AS slot_role,
                variant.id AS variant_id,
                variant.progression_id,
                variant.progression_model_slug,
                exercise.id AS exercise_id,
                exercise.slug AS exercise_slug,
                exercise.name AS exercise_name
            FROM plans.exercise_slots AS slot
            JOIN plans.exercise_variants AS variant
                ON variant.slot_id = slot.id
                AND variant.variant_type = 'DEFAULT'
            JOIN core.exercises AS exercise ON exercise.id = variant.exercise_id
            WHERE slot.workout_unit_id = session_row.source_plan_workout_unit_id
            ORDER BY slot.ordinal
        LOOP
            SELECT id
            INTO exercise_track_id
            FROM exec.exercise_unit_tracks
            WHERE workout_unit_track_id = session_row.workout_unit_track_id
              AND logical_key = format('slot:%s', exercise_row.slot_ordinal);

            SELECT performance.id
            INTO previous_exercise_performance_id
            FROM exec.exercise_unit_performances AS performance
            JOIN exec.workout_unit_performances AS workout_performance
                ON workout_performance.id = performance.workout_unit_performance_id
            JOIN exec.workout_unit_prescriptions AS prior_prescription
                ON prior_prescription.id = workout_performance.workout_unit_prescription_id
            JOIN exec.workout_sessions AS prior_session
                ON prior_session.id = prior_prescription.workout_session_id
            WHERE performance.exercise_unit_track_id = exercise_track_id
              AND workout_performance.status = 'finalized'
              AND prior_session.scheduled_date < session_row.scheduled_date
            ORDER BY prior_session.scheduled_date DESC, performance.id DESC
            LIMIT 1;

            exercise_comment := CASE
                WHEN exercise_row.exercise_slug = 'barbell_bench_press'
                    AND session_row.microcycle_ordinal = 1
                    THEN 'Start at 65 kg; keep the first set at RIR 1.'
                WHEN exercise_row.exercise_slug = 'barbell_bench_press'
                    AND session_row.microcycle_ordinal = 4
                    THEN 'Deload to 60 kg and prioritize a smooth bar path.'
                WHEN exercise_row.exercise_slug = 'barbell_bench_press'
                    AND session_row.microcycle_ordinal = 6
                    THEN 'Try 67.5 kg; stop the set if technique changes.'
                WHEN exercise_row.exercise_slug = 'plate_loaded_converging_incline_chest_press'
                    AND session_row.microcycle_ordinal = 6
                    THEN 'Try 70 kg and verify the seat position.'
                ELSE NULL
            END;

            INSERT INTO exec.exercise_unit_prescriptions (
                workout_unit_prescription_id,
                exercise_unit_track_id,
                ordinal,
                source_plan_exercise_slot_id,
                source_plan_exercise_variant_id,
                source_progression_id,
                prescribed_exercise_id,
                slot_name_snapshot,
                plan_description_snapshot,
                plan_goal_snapshot,
                slot_role_snapshot,
                progression_model_slug_snapshot,
                prescription_comment,
                previous_exercise_performance_id
            )
            VALUES (
                workout_prescription_id,
                exercise_track_id,
                exercise_row.slot_ordinal,
                exercise_row.slot_id,
                exercise_row.variant_id,
                exercise_row.progression_id,
                exercise_row.exercise_id,
                exercise_row.slot_name,
                exercise_row.slot_description,
                exercise_row.slot_goal,
                exercise_row.slot_role,
                exercise_row.progression_model_slug,
                exercise_comment,
                previous_exercise_performance_id
            )
            RETURNING id INTO exercise_prescription_id;

            FOR source_set IN
                SELECT *
                FROM plans.set_infra_prescriptions
                WHERE exercise_variant_id = exercise_row.variant_id
                ORDER BY ordinal
            LOOP
                prescribed_load := CASE exercise_row.exercise_slug
                    WHEN 'barbell_bench_press' THEN
                        (ARRAY[65, 65, 67.5, 60, 65, 67.5]::numeric[])
                            [session_row.microcycle_ordinal]
                    WHEN 'plate_loaded_converging_incline_chest_press' THEN
                        (ARRAY[65, 70, 70, 55, 65, 70]::numeric[])
                            [session_row.microcycle_ordinal]
                    ELSE
                        round(
                            (
                                10::numeric
                                + exercise_row.exercise_id::numeric * 1.25
                                + (session_row.microcycle_ordinal - 1)::numeric * 0.5
                            )
                            * CASE
                                WHEN session_row.microcycle_ordinal = 4 THEN 0.85
                                ELSE 1
                            END
                            * 2
                        ) / 2
                END;

                set_comment := CASE
                    WHEN exercise_row.exercise_slug = 'barbell_bench_press'
                        AND source_set.ordinal = 0
                        AND session_row.microcycle_ordinal = 6
                        THEN 'Use the normal one-second pause at the bottom.'
                    ELSE NULL
                END;

                INSERT INTO exec.set_prescriptions (
                    exercise_unit_prescription_id,
                    ordinal,
                    source_plan_set_infra_id,
                    set_role_snapshot,
                    rep_min,
                    rep_max,
                    target_rir,
                    prescribed_load_kg,
                    prescription_comment
                )
                VALUES (
                    exercise_prescription_id,
                    source_set.ordinal,
                    source_set.id,
                    source_set.role,
                    source_set.rep_min,
                    source_set.rep_max,
                    source_set.rir,
                    prescribed_load,
                    set_comment
                );
            END LOOP;
        END LOOP;

        IF session_row.status NOT IN ('completed', 'in_progress') THEN
            CONTINUE;
        END IF;

        performance_status := CASE
            WHEN session_row.status = 'completed' THEN 'finalized'::exec.performance_status
            ELSE 'draft'::exec.performance_status
        END;

        INSERT INTO exec.workout_unit_performances (
            workout_unit_prescription_id,
            status,
            started_at,
            completed_at,
            performance_comment
        )
        VALUES (
            workout_prescription_id,
            performance_status,
            session_row.started_at,
            session_row.completed_at,
            CASE
                WHEN session_row.status = 'in_progress' THEN
                    'Draft performance synchronized after the first exercises.'
                WHEN session_row.microcycle_ordinal = 4 THEN
                    'Deload felt easy; recovery improved.'
                ELSE NULL
            END
        )
        RETURNING id INTO workout_performance_id;

        FOR exercise_row IN
            SELECT
                prescription.*,
                exercise.slug AS exercise_slug,
                exercise.name AS exercise_name
            FROM exec.exercise_unit_prescriptions AS prescription
            JOIN core.exercises AS exercise
                ON exercise.id = prescription.prescribed_exercise_id
            WHERE prescription.workout_unit_prescription_id = workout_prescription_id
              AND (
                  session_row.status = 'completed'
                  OR prescription.ordinal <= 1
              )
            ORDER BY prescription.ordinal
        LOOP
            exercise_mode := 'as_prescribed';
            actual_exercise_id := exercise_row.prescribed_exercise_id;
            actual_variant_id := exercise_row.source_plan_exercise_variant_id;

            IF session_row.microcycle_ordinal = 2
                AND session_row.source_workout_name = 'Push A'
                AND exercise_row.exercise_slug = 'plate_loaded_converging_incline_chest_press'
            THEN
                exercise_mode := 'substituted';
                SELECT id
                INTO actual_exercise_id
                FROM core.exercises
                WHERE slug = 'smith_machine_incline_bench_press';
                actual_variant_id := NULL;
            ELSIF session_row.microcycle_ordinal = 5
                AND session_row.source_workout_name = 'Push A'
                AND exercise_row.exercise_slug = 'barbell_california_press'
            THEN
                exercise_mode := 'skipped';
                actual_exercise_id := NULL;
                actual_variant_id := NULL;
            END IF;

            exercise_comment := CASE
                WHEN exercise_row.exercise_slug = 'barbell_bench_press'
                    AND session_row.microcycle_ordinal = 3
                    THEN 'Technique stayed smooth; the final set needed a small load reduction.'
                WHEN exercise_row.exercise_slug = 'barbell_bench_press'
                    AND session_row.microcycle_ordinal = 5
                    THEN 'Reload felt controlled after the deload.'
                WHEN exercise_mode = 'substituted' THEN
                    'The prescribed machine was occupied; used the Smith incline press.'
                WHEN exercise_mode = 'skipped' THEN
                    'Skipped because the elbow felt irritated.'
                ELSE NULL
            END;

            IF actual_exercise_id IS NOT NULL THEN
                SELECT engine.etu_vector
                INTO etu_snapshot
                FROM core.exercises AS exercise
                LEFT JOIN engine.exercises AS engine ON engine.slug = exercise.slug
                WHERE exercise.id = actual_exercise_id;
            ELSE
                etu_snapshot := NULL;
            END IF;

            INSERT INTO exec.exercise_unit_performances (
                workout_unit_performance_id,
                prescribed_exercise_unit_id,
                exercise_unit_track_id,
                ordinal,
                execution_mode,
                actual_exercise_id,
                actual_plan_exercise_variant_id,
                performance_comment,
                engine_model_version,
                etu_vector_snapshot
            )
            VALUES (
                workout_performance_id,
                exercise_row.id,
                exercise_row.exercise_unit_track_id,
                exercise_row.ordinal,
                exercise_mode,
                actual_exercise_id,
                actual_variant_id,
                exercise_comment,
                CASE WHEN actual_exercise_id IS NULL THEN NULL ELSE 'engine-snapshot-2026-10-demo' END,
                etu_snapshot
            )
            RETURNING id INTO exercise_performance_id;

            FOR prescribed_set_row IN
                SELECT *
                FROM exec.set_prescriptions
                WHERE exercise_unit_prescription_id = exercise_row.id
                  AND (
                      session_row.status = 'completed'
                      OR ordinal <= CASE WHEN exercise_row.ordinal = 0 THEN 1 ELSE 0 END
                  )
                ORDER BY ordinal
            LOOP
                IF exercise_mode = 'skipped' THEN
                    INSERT INTO exec.set_performances (
                        exercise_unit_performance_id,
                        prescribed_set_id,
                        ordinal,
                        status,
                        performance_comment
                    )
                    VALUES (
                        exercise_performance_id,
                        prescribed_set_row.id,
                        prescribed_set_row.ordinal,
                        'skipped',
                        'Set omitted with the skipped exercise-unit.'
                    );
                    CONTINUE;
                END IF;

                performed_load := prescribed_set_row.prescribed_load_kg;
                performed_repetitions := prescribed_set_row.rep_min;
                performed_rir := CASE prescribed_set_row.target_rir::text
                    WHEN 'RIR0' THEN 0
                    WHEN 'RIR1' THEN 1
                    WHEN 'RIR2' THEN 2
                    WHEN 'RIR3' THEN 3
                    WHEN 'RIR4' THEN 4
                    ELSE NULL
                END;
                set_comment := NULL;

                IF exercise_row.exercise_slug = 'barbell_bench_press' THEN
                    performed_repetitions := CASE session_row.microcycle_ordinal
                        WHEN 1 THEN (ARRAY[7, 6, 5]::smallint[])[prescribed_set_row.ordinal + 1]
                        WHEN 2 THEN (ARRAY[7, 7, 6]::smallint[])[prescribed_set_row.ordinal + 1]
                        WHEN 3 THEN (ARRAY[7, 6, 5]::smallint[])[prescribed_set_row.ordinal + 1]
                        WHEN 4 THEN (ARRAY[7, 7, 7]::smallint[])[prescribed_set_row.ordinal + 1]
                        WHEN 5 THEN (ARRAY[7, 6, 5]::smallint[])[prescribed_set_row.ordinal + 1]
                        WHEN 6 THEN (ARRAY[7, 6, 5]::smallint[])[prescribed_set_row.ordinal + 1]
                    END;
                    performed_rir := CASE prescribed_set_row.ordinal
                        WHEN 0 THEN 1
                        WHEN 1 THEN 1
                        ELSE 0
                    END;

                    IF session_row.microcycle_ordinal = 3
                        AND prescribed_set_row.ordinal = 2
                    THEN
                        performed_load := performed_load - 2.5;
                        set_comment := 'Reduced by 2.5 kg after bar speed dropped.';
                    ELSIF session_row.microcycle_ordinal = 6
                        AND prescribed_set_row.ordinal = 1
                    THEN
                        set_comment := 'Technique remained repeatable; one rep short of target.';
                    END IF;
                ELSIF exercise_mode = 'substituted' THEN
                    performed_load := greatest(performed_load - 2.5, 0);
                    performed_repetitions := prescribed_set_row.rep_min + 1;
                    set_comment := 'Load adjusted for the substitute machine.';
                ELSE
                    performed_repetitions := least(
                        prescribed_set_row.rep_max,
                        prescribed_set_row.rep_min
                            + ((session_row.microcycle_ordinal + prescribed_set_row.ordinal) % 3)
                    );
                END IF;

                INSERT INTO exec.set_performances (
                    exercise_unit_performance_id,
                    prescribed_set_id,
                    ordinal,
                    status,
                    load_kg,
                    repetitions,
                    rir,
                    performance_comment,
                    recorded_at
                )
                VALUES (
                    exercise_performance_id,
                    prescribed_set_row.id,
                    prescribed_set_row.ordinal,
                    'performed',
                    performed_load,
                    performed_repetitions,
                    performed_rir,
                    set_comment,
                    session_row.started_at
                        + ((prescribed_set_row.ordinal + 1) * INTERVAL '5 minutes')
                );
            END LOOP;

            IF exercise_row.exercise_slug = 'barbell_bench_press'
                AND session_row.microcycle_ordinal = 3
            THEN
                INSERT INTO exec.set_performances (
                    exercise_unit_performance_id,
                    prescribed_set_id,
                    ordinal,
                    status,
                    load_kg,
                    repetitions,
                    rir,
                    performance_comment,
                    recorded_at
                )
                VALUES (
                    exercise_performance_id,
                    NULL,
                    3,
                    'performed',
                    65,
                    4,
                    0,
                    'Unplanned back-off set added after the load reduction.',
                    session_row.started_at + INTERVAL '22 minutes'
                );
            END IF;
        END LOOP;
    END LOOP;

    INSERT INTO exec.plan_run_events (
        plan_run_id,
        microcycle_id,
        event_type,
        occurred_at,
        title,
        details
    )
    SELECT
        run_id,
        microcycle.id,
        'observation',
        '2026-09-01 08:00:00+00',
        'Plan run started',
        'Locked in for eight microcycles using the existing PPL upper-focus plan.'
    FROM exec.microcycles AS microcycle
    WHERE microcycle.plan_run_id = run_id AND microcycle.ordinal = 1;

    INSERT INTO exec.plan_run_events (
        plan_run_id,
        microcycle_id,
        workout_session_id,
        event_type,
        occurred_at,
        title,
        details
    )
    SELECT
        run_id,
        microcycle.id,
        session.id,
        'training_break',
        '2026-09-18 09:00:00+00',
        'Short training break',
        'Pull B was missed rather than pausing the plan run.'
    FROM exec.microcycles AS microcycle
    JOIN exec.workout_sessions AS session ON session.microcycle_id = microcycle.id
    JOIN exec.workout_unit_tracks AS track ON track.id = session.workout_unit_track_id
    WHERE microcycle.plan_run_id = run_id
      AND microcycle.ordinal = 3
      AND track.name = 'Pull B';

    INSERT INTO exec.plan_run_events (
        plan_run_id,
        microcycle_id,
        workout_session_id,
        exercise_unit_track_id,
        event_type,
        occurred_at,
        title,
        details,
        metadata
    )
    SELECT
        run_id,
        microcycle.id,
        session.id,
        exercise_track.id,
        'personal_record',
        '2026-09-15 19:15:00+00',
        'Bench Press working-load PR',
        'First controlled exposure at 67.5 kg in this plan run.',
        jsonb_build_object('load_kg', 67.5, 'exercise_slug', 'barbell_bench_press')
    FROM exec.microcycles AS microcycle
    JOIN exec.workout_sessions AS session ON session.microcycle_id = microcycle.id
    JOIN exec.workout_unit_tracks AS workout_track
        ON workout_track.id = session.workout_unit_track_id
    JOIN exec.exercise_unit_tracks AS exercise_track
        ON exercise_track.workout_unit_track_id = workout_track.id
    WHERE microcycle.plan_run_id = run_id
      AND microcycle.ordinal = 3
      AND workout_track.name = 'Push A'
      AND exercise_track.logical_key = 'slot:0';

    INSERT INTO exec.plan_run_events (
        plan_run_id,
        microcycle_id,
        event_type,
        occurred_at,
        title,
        details,
        from_plan_revision_id,
        to_plan_revision_id
    )
    SELECT
        run_id,
        microcycle.id,
        'plan_revision_changed',
        '2026-09-21 18:00:00+00',
        'Plan revision changed',
        'The evolved revision became effective from microcycle 4; existing traces were retained.',
        source_revision_id,
        evolved_revision_id
    FROM exec.microcycles AS microcycle
    WHERE microcycle.plan_run_id = run_id AND microcycle.ordinal = 4;

    INSERT INTO exec.plan_run_events (
        plan_run_id,
        microcycle_id,
        event_type,
        occurred_at,
        title,
        details
    )
    SELECT
        run_id,
        microcycle.id,
        'deload_started',
        '2026-09-22 07:00:00+00',
        'Deload started',
        'Loads reduced and one Legs session cancelled for recovery.'
    FROM exec.microcycles AS microcycle
    WHERE microcycle.plan_run_id = run_id AND microcycle.ordinal = 4;

    INSERT INTO exec.plan_run_events (
        plan_run_id,
        microcycle_id,
        event_type,
        occurred_at,
        title,
        details
    )
    SELECT
        run_id,
        microcycle.id,
        'reload_started',
        '2026-09-29 07:00:00+00',
        'Reload started',
        'Training loads returned toward the pre-deload baseline.'
    FROM exec.microcycles AS microcycle
    WHERE microcycle.plan_run_id = run_id AND microcycle.ordinal = 5;
END;
$$;

COMMIT;
