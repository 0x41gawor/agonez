ALTER TABLE exec.workout_unit_prescriptions
    ADD COLUMN updated_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE exec.exercise_unit_prescriptions
    ADD COLUMN updated_at timestamptz NOT NULL DEFAULT now();

COMMENT ON COLUMN exec.workout_unit_prescriptions.updated_at IS
    'Optimistic-concurrency version for scheduled-session prescription edits.';
COMMENT ON COLUMN exec.exercise_unit_prescriptions.updated_at IS
    'Optimistic-concurrency version for scheduled-session exercise prescription edits.';
