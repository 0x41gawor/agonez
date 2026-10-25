CREATE TYPE exec.prescribed_load_source AS ENUM (
    'analysis',
    'last_exposure'
);

ALTER TABLE exec.set_prescriptions
    ADD COLUMN load_source exec.prescribed_load_source;

UPDATE exec.set_prescriptions
SET load_source = 'analysis'
WHERE prescribed_load_kg IS NOT NULL;

ALTER TABLE exec.set_prescriptions
    ADD CONSTRAINT set_prescriptions_load_source_requires_load CHECK (
        load_source IS NULL OR prescribed_load_kg IS NOT NULL
    );

COMMENT ON COLUMN exec.set_prescriptions.load_source IS
    'Which agent decided this load: analysis for a manual Post-Workout-Analysis save, last_exposure for the default progression agent that repeats the previous exposure. NULL when no load is prescribed. Future model-aware progression agents add their own value here.';

COMMENT ON TYPE exec.prescribed_load_source IS
    'Provenance of exec.set_prescriptions.prescribed_load_kg. Extend with one value per progression agent that can decide loads without manual analysis.';
