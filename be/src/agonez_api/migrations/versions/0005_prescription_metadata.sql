CREATE TYPE plans.set_role AS ENUM (
    'rampup',
    'working',
    'working_topset',
    'working_backoff',
    'working_amrap'
);

CREATE TYPE plans.rep_range_semantics AS ENUM (
    'gating',
    'estimate',
    'undefined'
);

CREATE TYPE plans.rir_prescription AS ENUM (
    'RIR0',
    'RIR1',
    'RIR2',
    'RIR3',
    'RIR4',
    'NOT_APPLICABLE',
    'UNDEFINED'
);

ALTER TABLE plans.exercise_variants
    ADD COLUMN progression_id uuid NOT NULL DEFAULT gen_random_uuid(),
    ADD COLUMN active_working_set_min smallint,
    ADD COLUMN active_working_set_max smallint,
    ADD CONSTRAINT exercise_variants_active_working_sets_valid CHECK (
        (active_working_set_min IS NULL AND active_working_set_max IS NULL)
        OR (
            active_working_set_min IS NOT NULL
            AND active_working_set_max IS NOT NULL
            AND active_working_set_min >= 0
            AND active_working_set_max >= active_working_set_min
        )
    );

CREATE INDEX exercise_variants_by_progression_id
    ON plans.exercise_variants (progression_id);

ALTER TABLE plans.set_infra_prescriptions
    ADD COLUMN role plans.set_role NOT NULL DEFAULT 'working',
    ADD COLUMN load_spec jsonb NOT NULL DEFAULT '{"kind":"absolute"}'::jsonb,
    ADD COLUMN rep_range_semantics plans.rep_range_semantics NOT NULL DEFAULT 'undefined',
    ADD COLUMN rir_prescription plans.rir_prescription;

UPDATE plans.set_infra_prescriptions
SET rir_prescription = ('RIR' || rir::text)::plans.rir_prescription;

ALTER TABLE plans.set_infra_prescriptions
    ALTER COLUMN rir_prescription SET NOT NULL,
    DROP CONSTRAINT set_infra_rir_valid,
    DROP COLUMN rir;

ALTER TABLE plans.set_infra_prescriptions
    RENAME COLUMN rir_prescription TO rir;

ALTER TABLE plans.set_infra_prescriptions
    ADD CONSTRAINT set_infra_load_spec_object CHECK (jsonb_typeof(load_spec) = 'object'),
    ADD CONSTRAINT set_infra_load_spec_kind CHECK (
        load_spec ->> 'kind' IN (
            'absolute',
            'athlete_selected',
            'relative_to_set',
            'relative_to_working',
            'table_derived',
            'ordinal_variant'
        )
    );

COMMENT ON COLUMN plans.exercise_variants.progression_id IS
    'Progression-loop identity. Multiple exercise units may intentionally share it.';
COMMENT ON COLUMN plans.exercise_variants.active_working_set_min IS
    'Optional future-execution lower bound for active working sets.';
COMMENT ON COLUMN plans.exercise_variants.active_working_set_max IS
    'Optional future-execution upper bound for active working sets.';
COMMENT ON COLUMN plans.set_infra_prescriptions.role IS
    'Explicit set purpose; ramp-up sets are excluded from working-set analysis.';
COMMENT ON COLUMN plans.set_infra_prescriptions.load_spec IS
    'Unresolved tagged load prescription metadata for future Plan-Execution.';
COMMENT ON COLUMN plans.set_infra_prescriptions.rep_range_semantics IS
    'Whether the prescribed rep range is a progression gate, estimate, or undefined.';
