CREATE TABLE core.resistance_source_load_defaults (
    resistance_source core.resistance_source_enum PRIMARY KEY,
    default_load_step_kg numeric(8,2) NOT NULL,
    CONSTRAINT resistance_source_load_defaults_step_valid CHECK (
        default_load_step_kg > 0 AND default_load_step_kg <= 1000
    )
);

COMMENT ON TABLE core.resistance_source_load_defaults IS
    'Product defaults for the smallest useful load increment, keyed by resistance family.';

COMMENT ON COLUMN core.resistance_source_load_defaults.default_load_step_kg IS
    'Default load increment in kilograms; plan exercise variants may override it.';

INSERT INTO core.resistance_source_load_defaults (
    resistance_source,
    default_load_step_kg
) VALUES
    ('Bodyweight', 2.50),
    ('Barbell', 2.50),
    ('Dumbbell', 2.00),
    ('Kettlebell', 4.00),
    ('Cable', 2.50),
    ('Selectorized_Machine', 5.00),
    ('Plate_Loaded_Machine', 2.50),
    ('Smith_Machine', 2.50),
    ('Resistance_Band', 2.50),
    ('Suspension', 2.50),
    ('Partner_Resistance', 2.50),
    ('Other', 2.50);

UPDATE plans.exercise_variants AS variant
SET load_step_kg = defaults.default_load_step_kg
FROM core.exercises AS exercise
JOIN core.resistance_source_load_defaults AS defaults
  ON defaults.resistance_source = exercise.resistance_source
WHERE variant.exercise_id = exercise.id
  AND variant.load_step_kg IS NULL;

UPDATE exec.exercise_unit_prescriptions AS prescription
SET load_step_kg_snapshot = defaults.default_load_step_kg
FROM core.exercises AS exercise
JOIN core.resistance_source_load_defaults AS defaults
  ON defaults.resistance_source = exercise.resistance_source
WHERE prescription.prescribed_exercise_id = exercise.id
  AND prescription.load_step_kg_snapshot IS NULL;
