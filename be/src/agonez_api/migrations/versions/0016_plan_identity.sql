-- Plan identity: a cover image and an accent colour per plan, and a goal icon per
-- training day. All three are presentation, never training semantics: nothing here
-- participates in analysis, execution or the AI export contract.

-- The accent is a named token, not a free hex value: the app renders each name
-- differently in the light and dark themes, which a stored colour could not do.
CREATE TYPE plans.plan_accent AS ENUM (
    'amber',
    'clay',
    'rust',
    'olive',
    'sage',
    'teal',
    'ocean',
    'indigo',
    'violet',
    'plum',
    'rose',
    'slate'
);

-- NULL means "no accent chosen"; the plan then renders in the app's own accent.
ALTER TABLE plans.workout_plans
    ADD COLUMN accent plans.plan_accent;

CREATE TYPE plans.day_icon AS ENUM (
    'full_body',
    'upper',
    'lower',
    'push',
    'pull',
    'legs',
    'glutes',
    'calves',
    'chest',
    'back',
    'shoulders',
    'arms',
    'core',
    'cardio',
    'liss',
    'hiit',
    'conditioning',
    'mobility',
    'rest',
    'deload',
    'test',
    'sport'
);

-- NULL means "no icon chosen"; the day keeps its ordinal mark.
ALTER TABLE plans.day_prescriptions
    ADD COLUMN icon plans.day_icon;

-- The image lives in its own table so that listing plans never reads the bytes:
-- every plan query stays as cheap as it was before this migration.
CREATE TABLE plans.plan_images (
    plan_id integer PRIMARY KEY REFERENCES plans.workout_plans(id) ON DELETE CASCADE,
    content_type varchar(60) NOT NULL,
    byte_size integer NOT NULL,
    checksum char(64) NOT NULL,
    data bytea NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT plan_images_content_type_supported
        CHECK (content_type IN ('image/webp', 'image/png', 'image/jpeg')),
    -- Kept well under the 2m nginx body limit so an oversized upload is refused by
    -- the API with a readable error instead of by the proxy with a bare 413.
    CONSTRAINT plan_images_byte_size_bounded
        CHECK (byte_size > 0 AND byte_size <= 1500000),
    CONSTRAINT plan_images_byte_size_matches_data
        CHECK (byte_size = octet_length(data)),
    CONSTRAINT plan_images_checksum_hex
        CHECK (checksum ~ '^[0-9a-f]{64}$')
);
