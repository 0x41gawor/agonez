ALTER TABLE plans.exercise_variants
    ADD COLUMN load_step_kg numeric(8,2),
    ADD CONSTRAINT exercise_variants_load_step_kg_valid CHECK (
        load_step_kg IS NULL OR (load_step_kg > 0 AND load_step_kg <= 1000)
    );

COMMENT ON COLUMN plans.exercise_variants.load_step_kg IS
    'Smallest useful load increment for this exercise variant, in kilograms.';

ALTER TABLE exec.exercise_unit_prescriptions
    ADD COLUMN load_step_kg_snapshot numeric(8,2),
    ADD CONSTRAINT exercise_unit_prescriptions_load_step_kg_valid CHECK (
        load_step_kg_snapshot IS NULL
        OR (load_step_kg_snapshot > 0 AND load_step_kg_snapshot <= 1000)
    );

COMMENT ON COLUMN exec.exercise_unit_prescriptions.load_step_kg_snapshot IS
    'Immutable load increment copied from the governing plan variant when prescribed.';
