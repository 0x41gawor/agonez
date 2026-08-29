CREATE TYPE plans.loading_mode AS ENUM (
    'high_load',
    'moderate_load',
    'low_load'
);

ALTER TABLE plans.exercise_slots
    ADD COLUMN loading_mode plans.loading_mode NOT NULL DEFAULT 'moderate_load',
    ADD COLUMN loading_cycle plans.loading_mode[];

ALTER TABLE plans.exercise_slots
    ADD CONSTRAINT exercise_slots_loading_cycle_valid
    CHECK (
        loading_cycle IS NULL
        OR cardinality(loading_cycle) BETWEEN 2 AND 52
    );

ALTER TABLE plans.set_infra_prescriptions
    ADD COLUMN loading_mode plans.loading_mode,
    ADD COLUMN loading_cycle plans.loading_mode[];

ALTER TABLE plans.set_infra_prescriptions
    ADD CONSTRAINT set_infra_loading_cycle_valid
    CHECK (
        loading_cycle IS NULL
        OR cardinality(loading_cycle) BETWEEN 2 AND 52
    );

COMMENT ON COLUMN plans.exercise_slots.loading_mode IS
    'Static slot loading default; used when loading_cycle is null.';
COMMENT ON COLUMN plans.exercise_slots.loading_cycle IS
    'Optional repeating loading-mode sequence, one entry per microcycle.';
COMMENT ON COLUMN plans.set_infra_prescriptions.loading_mode IS
    'Optional static override; null inherits the exercise-slot prescription.';
COMMENT ON COLUMN plans.set_infra_prescriptions.loading_cycle IS
    'Optional repeating per-set override; takes precedence over set and slot modes.';
