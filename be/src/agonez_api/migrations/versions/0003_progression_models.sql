ALTER TABLE plans.exercise_variants
    ADD COLUMN progression_model_slug text;

ALTER TABLE plans.exercise_variants
    ADD CONSTRAINT exercise_variants_progression_model_fk
    FOREIGN KEY (progression_model_slug)
    REFERENCES core.progression_models(slug)
    ON UPDATE CASCADE
    ON DELETE RESTRICT;

CREATE INDEX exercise_variants_by_progression_model
    ON plans.exercise_variants (progression_model_slug)
    WHERE progression_model_slug IS NOT NULL;

COMMENT ON COLUMN plans.exercise_variants.progression_model_slug IS
    'Optional progression intent for this concrete exercise variant; null means none.';
