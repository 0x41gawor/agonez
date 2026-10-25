CREATE TYPE exec.workout_start_mode AS ENUM (
    'on_schedule',
    'next_track_exposure'
);

ALTER TABLE exec.workout_sessions
    ADD COLUMN start_mode exec.workout_start_mode,
    ADD COLUMN off_schedule_selected_from varchar(40),
    ADD COLUMN off_schedule_expected_session_id integer
        REFERENCES exec.workout_sessions(id) ON DELETE SET NULL;

UPDATE exec.workout_sessions
SET start_mode = 'on_schedule'
WHERE status IN ('in_progress', 'completed');

SET CONSTRAINTS ALL IMMEDIATE;

ALTER TABLE exec.workout_sessions
    ADD CONSTRAINT workout_sessions_start_mode_valid CHECK (
        (
            status IN ('scheduled', 'cancelled', 'missed')
            AND start_mode IS NULL
            AND off_schedule_selected_from IS NULL
            AND off_schedule_expected_session_id IS NULL
        )
        OR (
            status IN ('in_progress', 'completed')
            AND start_mode IS NOT NULL
            AND (
                (
                    start_mode = 'on_schedule'
                    AND off_schedule_selected_from IS NULL
                    AND off_schedule_expected_session_id IS NULL
                )
                OR (
                    start_mode = 'next_track_exposure'
                    AND off_schedule_selected_from IS NOT NULL
                    AND btrim(off_schedule_selected_from) <> ''
                )
            )
        )
    );

CREATE INDEX workout_sessions_off_schedule
    ON exec.workout_sessions (plan_run_id, started_at, id)
    WHERE start_mode = 'next_track_exposure';

COMMENT ON COLUMN exec.workout_sessions.start_mode IS
    'How the concrete run-scoped exposure was selected when execution started.';
COMMENT ON COLUMN exec.workout_sessions.off_schedule_selected_from IS
    'Client interaction that explicitly selected the next track exposure off schedule.';
COMMENT ON COLUMN exec.workout_sessions.off_schedule_expected_session_id IS
    'Scheduled session shown as expected when the athlete acknowledged an off-schedule start.';
