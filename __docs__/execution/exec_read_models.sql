-- Representative Execution read models.
-- The demo lookup is intentionally by seed run name; production callers should bind plan_run_id.

-- 1. Exercise-unit trace: spreadsheet-equivalent set history, including revision changes.
SELECT
    microcycle_ordinal,
    scheduled_date,
    plan_revision_id,
    workout_unit_name,
    prescribed_plan_exercise_variant_id,
    performed_plan_exercise_variant_id,
    prescribed_exercise_name,
    performed_exercise_name,
    prescribed_set_ordinal,
    prescribed_load_kg,
    prescribed_rep_min,
    prescribed_rep_max,
    target_rir,
    performed_set_ordinal,
    performed_load_kg,
    performed_repetitions,
    performed_rir,
    exercise_prescription_comment,
    set_prescription_comment,
    exercise_performance_comment,
    set_performance_comment,
    diverged_from_prescription
FROM exec.exercise_unit_trace
WHERE plan_run_name = 'Execution Demo — PPL Upper Focus 2026'
  AND prescribed_exercise_slug = 'barbell_bench_press'
ORDER BY
    microcycle_ordinal,
    COALESCE(prescribed_set_ordinal, performed_set_ordinal);

-- 2. Workout-unit trace.
SELECT
    microcycle_ordinal,
    scheduled_date,
    plan_revision_no,
    status,
    completion_mode,
    performance_status,
    performance_comment,
    notes
FROM exec.workout_unit_trace
WHERE plan_run_id = (
    SELECT id
    FROM exec.plan_runs
    WHERE name = 'Execution Demo — PPL Upper Focus 2026'
)
  AND workout_unit_name = 'Push A'
ORDER BY microcycle_ordinal;

-- 3. Microcycle trace with attendance and volume context.
SELECT
    ordinal,
    starts_on,
    ends_on,
    plan_revision_no,
    classification,
    scheduled_session_count,
    completed_session_count,
    missed_session_count,
    cancelled_session_count,
    attendance_ratio,
    performed_volume_load_kg,
    notes
FROM exec.microcycle_trace
WHERE plan_run_id = (
    SELECT id
    FROM exec.plan_runs
    WHERE name = 'Execution Demo — PPL Upper Focus 2026'
)
ORDER BY ordinal;

-- 4. Workout calendar/history.
SELECT
    microcycle_ordinal,
    scheduled_date,
    workout_unit_name,
    status,
    completion_mode,
    performance_status,
    plan_revision_no
FROM exec.workout_session_calendar
WHERE plan_run_id = (
    SELECT id
    FROM exec.plan_runs
    WHERE name = 'Execution Demo — PPL Upper Focus 2026'
)
ORDER BY scheduled_date, workout_session_id;

-- 5. Chart-friendly performed loads. One row is one performed set.
SELECT
    exercise_unit_track_id,
    exercise_slug,
    workout_unit_logical_key,
    microcycle_ordinal,
    scheduled_date,
    set_ordinal,
    load_kg,
    repetitions,
    rir,
    engine_model_version
FROM exec.performed_load_time_series
WHERE plan_run_id = (
    SELECT id
    FROM exec.plan_runs
    WHERE name = 'Execution Demo — PPL Upper Focus 2026'
)
ORDER BY exercise_unit_track_id, scheduled_date, set_ordinal;

-- 6. Plan-run event history positioned on both calendar and run time.
SELECT
    occurred_at,
    microcycle_ordinal,
    event_type,
    title,
    details,
    workout_session_date,
    exercise_unit_name,
    from_plan_revision_no,
    to_plan_revision_no,
    metadata
FROM exec.plan_run_event_history
WHERE plan_run_id = (
    SELECT id
    FROM exec.plan_runs
    WHERE name = 'Execution Demo — PPL Upper Focus 2026'
)
ORDER BY occurred_at, event_id;
