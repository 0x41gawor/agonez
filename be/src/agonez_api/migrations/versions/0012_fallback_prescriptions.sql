CREATE TYPE exec.prescription_generation_source AS ENUM (
    'analysis',
    'plan_fallback'
);

ALTER TABLE exec.exercise_unit_prescriptions
    ADD COLUMN generation_source exec.prescription_generation_source
        NOT NULL DEFAULT 'analysis';

COMMENT ON COLUMN exec.exercise_unit_prescriptions.generation_source IS
    'Whether the exercise snapshot was saved by post-workout analysis or generated from plan targets as an execution fallback.';

ALTER TABLE exec.set_performances
    ADD CONSTRAINT set_performances_performed_load_required CHECK (
        status <> 'performed' OR load_kg IS NOT NULL
    ) NOT VALID;

COMMENT ON CONSTRAINT set_performances_performed_load_required
    ON exec.set_performances IS
    'New performed-set writes must record an explicit load. Historical rows are intentionally not rewritten; zero represents no external load.';
