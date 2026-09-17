ALTER TABLE core.progression_models
    ADD COLUMN display_order integer;

UPDATE core.progression_models
SET display_order = CASE slug
    WHEN 'single_progression' THEN 10
    WHEN 'single_progression_with_2_for_2' THEN 20
    WHEN 'shared_reprange_shared_load_double_progression' THEN 30
    WHEN 'independent_reprange_shared_load_double_progression' THEN 40
    WHEN 'shared_reprange_independent_load_double_progression' THEN 50
    WHEN 'independent_reprange_independent_load_double_progression' THEN 60
    WHEN 'cascade_driven_shared_reprange_triple_progression' THEN 70
    WHEN 'rescue_driven_shared_reprange_triple_progression' THEN 80
    WHEN 'cascade_driven_independent_reprange_triple_progression' THEN 90
    WHEN 'rescue_driven_independent_reprange_triple_progression' THEN 100
    WHEN 'e1rm_top_set_backoffs' THEN 110
    WHEN 'apre3' THEN 120
    WHEN 'apre6' THEN 130
    WHEN 'apre10' THEN 140
END;

WITH unordered AS (
    SELECT slug, 1000 + row_number() OVER (ORDER BY slug) * 10 AS fallback_order
    FROM core.progression_models
    WHERE display_order IS NULL
)
UPDATE core.progression_models AS model
SET display_order = unordered.fallback_order
FROM unordered
WHERE model.slug = unordered.slug;

ALTER TABLE core.progression_models
    ALTER COLUMN display_order SET NOT NULL,
    ADD CONSTRAINT progression_models_display_order_positive
        CHECK (display_order > 0),
    ADD CONSTRAINT progression_models_display_order_unique
        UNIQUE (display_order);

COMMENT ON COLUMN core.progression_models.display_order IS
    'Stable catalog order from simplest to most complex; gaps permit later insertion.';
