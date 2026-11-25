-- Run plans, schema part (design: docs/plan_modifications_during_plan_run/02 §1.1 and §2).
--
-- Every plan run will own a private copy of its plan, the run plan: an ordinary
-- plans.workout_plans row with scope = 'run'. This migration is additive only: every new
-- column is nullable or has a default, nothing existing is altered or dropped, and today's
-- code neither reads nor writes the new columns. Migration 0019 converts the existing runs
-- and tightens the constraints (run_plan_id and plan_lineage_key NOT NULL).

-- D1: the scope of a plan row.
CREATE TYPE plans.plan_scope AS ENUM ('library', 'run');

COMMENT ON TYPE plans.plan_scope IS
    'library: a reusable plan listed in My Plans. run: the private plan of exactly one plan run.';

ALTER TABLE plans.workout_plans
    ADD COLUMN scope plans.plan_scope NOT NULL DEFAULT 'library',
    ADD COLUMN source_plan_id integer
        REFERENCES plans.workout_plans(id) ON DELETE SET NULL,
    -- Redundant with the primary key, but a composite foreign key needs a unique target:
    -- exec.plan_runs (run_plan_id, run_plan_scope) references it.
    ADD CONSTRAINT workout_plans_id_scope_unique UNIQUE (id, scope);

-- The My Plans list (ordered by updated_at) only ever shows library plans.
CREATE INDEX workout_plans_library_by_updated
    ON plans.workout_plans (updated_at DESC, id DESC)
    WHERE scope = 'library';

COMMENT ON COLUMN plans.workout_plans.scope IS
    'library: reusable plan listed in My Plans. run: plan owned by exactly one exec.plan_runs row (run_plan_id).';
COMMENT ON COLUMN plans.workout_plans.source_plan_id IS
    'Informational lineage: library plan a run plan was copied from, or run plan a library plan was promoted from.';

-- D5: lineage keys. Existing rows receive fresh UUIDs; 0019 re-keys the plans of existing runs.
-- The volatile default rewrites both tables once; they hold a few thousand rows.
ALTER TABLE plans.workout_unit_prescriptions
    ADD COLUMN lineage_key uuid NOT NULL DEFAULT gen_random_uuid();
ALTER TABLE plans.exercise_slots
    ADD COLUMN lineage_key uuid NOT NULL DEFAULT gen_random_uuid();

COMMENT ON COLUMN plans.workout_unit_prescriptions.lineage_key IS
    'Identity of the logical workout across revision copies. Preserved by plans.copy_revision_tree; never sent by clients.';
COMMENT ON COLUMN plans.exercise_slots.lineage_key IS
    'Identity of the logical exercise unit across revision copies. Preserved by plans.copy_revision_tree; never sent by clients.';

-- D2: a run owns its run plan. run_plan_scope is a constant so that the composite foreign key
-- lets the database itself reject a run pointing at a library plan.
ALTER TABLE exec.plan_runs
    ADD COLUMN run_plan_id integer,
    ADD COLUMN run_plan_scope plans.plan_scope NOT NULL DEFAULT 'run',
    ADD CONSTRAINT plan_runs_run_plan_scope_is_run CHECK (run_plan_scope = 'run'),
    ADD CONSTRAINT plan_runs_run_plan_unique UNIQUE (run_plan_id),
    ADD CONSTRAINT plan_runs_run_plan_fk
        FOREIGN KEY (run_plan_id, run_plan_scope)
        REFERENCES plans.workout_plans(id, scope) ON DELETE RESTRICT;

COMMENT ON COLUMN exec.plan_runs.run_plan_id IS
    'The run plan (plans.workout_plans, scope run) this run executes and owns; one run per run plan. NULL only for runs created before run plans, until migration 0019 converts them.';
COMMENT ON COLUMN exec.plan_runs.run_plan_scope IS
    'Constant run. Exists only so that plan_runs_run_plan_fk can require the referenced plan to have scope run.';

-- D5: track identity. Nullable until 0019 backfills the existing tracks.
ALTER TABLE exec.workout_unit_tracks ADD COLUMN plan_lineage_key uuid;
ALTER TABLE exec.exercise_unit_tracks ADD COLUMN plan_lineage_key uuid;

COMMENT ON COLUMN exec.workout_unit_tracks.plan_lineage_key IS
    'lineage_key of the run-plan workout units this track follows across revisions. NULL only for tracks created before run plans, until migration 0019 backfills them.';
COMMENT ON COLUMN exec.exercise_unit_tracks.plan_lineage_key IS
    'lineage_key of the run-plan exercise slots this track follows across revisions, within its workout track. NULL only for tracks created before run plans, until migration 0019 backfills them.';

-- D3: the single implementation of copying a revision's tree.
CREATE FUNCTION plans.copy_revision_tree(
    p_source_revision_id integer,
    p_target_revision_id integer,
    p_regenerate_progression_ids boolean
) RETURNS TABLE (entity text, source_id integer, target_id integer)
LANGUAGE plpgsql
VOLATILE
AS $$
BEGIN
    IF p_source_revision_id IS NULL
        OR p_target_revision_id IS NULL
        OR p_regenerate_progression_ids IS NULL
    THEN
        RAISE EXCEPTION 'plans.copy_revision_tree: arguments must not be NULL'
            USING ERRCODE = 'null_value_not_allowed';
    END IF;

    PERFORM 1 FROM plans.plan_revisions WHERE id = p_source_revision_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'plans.copy_revision_tree: source revision % does not exist',
            p_source_revision_id
            USING ERRCODE = 'no_data_found';
    END IF;

    -- Serialises concurrent copies into the same target, so the emptiness check holds.
    PERFORM 1 FROM plans.plan_revisions WHERE id = p_target_revision_id FOR NO KEY UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'plans.copy_revision_tree: target revision % does not exist',
            p_target_revision_id
            USING ERRCODE = 'no_data_found';
    END IF;

    -- Insert-only into an empty revision: the function can never modify an existing revision.
    IF EXISTS (SELECT 1 FROM plans.day_prescriptions WHERE revision_id = p_target_revision_id) THEN
        RAISE EXCEPTION 'plans.copy_revision_tree: target revision % is not empty',
            p_target_revision_id
            USING ERRCODE = 'object_not_in_prerequisite_state';
    END IF;

    -- One statement, so the whole source tree is read from one snapshot. Every child table has
    -- a key unique within its parent; each step joins its RETURNING rows back to the source on
    -- (mapped parent, key). Every column except id and the parent reference is copied as stored
    -- (load_step_kg raw: NULL stays NULL).
    RETURN QUERY
    WITH source_days AS (
        SELECT day.*
        FROM plans.day_prescriptions AS day
        WHERE day.revision_id = p_source_revision_id
    ), inserted_days AS (
        INSERT INTO plans.day_prescriptions (
            revision_id, ordinal, name, description, weekday, icon
        )
        SELECT p_target_revision_id, day.ordinal, day.name, day.description, day.weekday, day.icon
        FROM source_days AS day
        ORDER BY day.ordinal
        RETURNING id, ordinal
    ), day_map AS (
        SELECT day.id AS old_id, inserted.id AS new_id
        FROM source_days AS day
        JOIN inserted_days AS inserted ON inserted.ordinal = day.ordinal
    ), source_units AS (
        SELECT unit.*, day_map.new_id AS new_day_id
        FROM plans.workout_unit_prescriptions AS unit
        JOIN day_map ON day_map.old_id = unit.day_id
    ), inserted_units AS (
        INSERT INTO plans.workout_unit_prescriptions (
            day_id, name, description, warmup_notes, stretch_notes, lineage_key
        )
        SELECT unit.new_day_id, unit.name, unit.description, unit.warmup_notes,
               unit.stretch_notes, unit.lineage_key
        FROM source_units AS unit
        ORDER BY unit.new_day_id
        RETURNING id, day_id
    ), unit_map AS (
        SELECT unit.id AS old_id, inserted.id AS new_id
        FROM source_units AS unit
        JOIN inserted_units AS inserted ON inserted.day_id = unit.new_day_id
    ), source_slots AS (
        SELECT slot.*, unit_map.new_id AS new_unit_id
        FROM plans.exercise_slots AS slot
        JOIN unit_map ON unit_map.old_id = slot.workout_unit_id
    ), inserted_slots AS (
        INSERT INTO plans.exercise_slots (
            workout_unit_id, ordinal, name, description, goal, role, volume_axis,
            loading_mode, loading_cycle, lineage_key
        )
        SELECT slot.new_unit_id, slot.ordinal, slot.name, slot.description, slot.goal,
               slot.role, slot.volume_axis, slot.loading_mode, slot.loading_cycle,
               slot.lineage_key
        FROM source_slots AS slot
        ORDER BY slot.new_unit_id, slot.ordinal
        RETURNING id, workout_unit_id, ordinal
    ), slot_map AS (
        SELECT slot.id AS old_id, inserted.id AS new_id
        FROM source_slots AS slot
        JOIN inserted_slots AS inserted
          ON inserted.workout_unit_id = slot.new_unit_id
         AND inserted.ordinal = slot.ordinal
    ), inserted_target_muscles AS (
        INSERT INTO plans.exercise_slot_target_muscles (slot_id, muscle_id)
        SELECT slot_map.new_id, target.muscle_id
        FROM plans.exercise_slot_target_muscles AS target
        JOIN slot_map ON slot_map.old_id = target.slot_id
        ORDER BY slot_map.new_id, target.muscle_id
        RETURNING slot_id
    ), source_variants AS (
        SELECT variant.*, slot_map.new_id AS new_slot_id
        FROM plans.exercise_variants AS variant
        JOIN slot_map ON slot_map.old_id = variant.slot_id
    ), progression_map AS (
        -- One new id per distinct old id: variants that shared a progression loop still share
        -- one, but none shares it with the source. Materialised, so each id is drawn once.
        SELECT shared.progression_id AS old_id,
               CASE WHEN p_regenerate_progression_ids THEN gen_random_uuid()
                    ELSE shared.progression_id
               END AS new_id
        FROM (SELECT DISTINCT variant.progression_id FROM source_variants AS variant) AS shared
    ), inserted_variants AS (
        INSERT INTO plans.exercise_variants (
            slot_id, ordinal, variant_type, exercise_id, progression_model_slug,
            progression_id, active_working_set_min, active_working_set_max, load_step_kg
        )
        SELECT variant.new_slot_id, variant.ordinal, variant.variant_type, variant.exercise_id,
               variant.progression_model_slug, progression_map.new_id,
               variant.active_working_set_min, variant.active_working_set_max,
               variant.load_step_kg
        FROM source_variants AS variant
        JOIN progression_map ON progression_map.old_id = variant.progression_id
        ORDER BY variant.new_slot_id, variant.ordinal
        RETURNING id, slot_id, ordinal
    ), variant_map AS (
        SELECT variant.id AS old_id, inserted.id AS new_id
        FROM source_variants AS variant
        JOIN inserted_variants AS inserted
          ON inserted.slot_id = variant.new_slot_id
         AND inserted.ordinal = variant.ordinal
    ), source_sets AS (
        SELECT item.*, variant_map.new_id AS new_variant_id
        FROM plans.set_infra_prescriptions AS item
        JOIN variant_map ON variant_map.old_id = item.exercise_variant_id
    ), inserted_sets AS (
        INSERT INTO plans.set_infra_prescriptions (
            exercise_variant_id, ordinal, rep_min, rep_max, min_volume_level, loading_mode,
            loading_cycle, role, load_spec, rep_range_semantics, rir
        )
        SELECT item.new_variant_id, item.ordinal, item.rep_min, item.rep_max,
               item.min_volume_level, item.loading_mode, item.loading_cycle, item.role,
               item.load_spec, item.rep_range_semantics, item.rir
        FROM source_sets AS item
        ORDER BY item.new_variant_id, item.ordinal
        RETURNING id, exercise_variant_id, ordinal
    ), set_map AS (
        SELECT item.id AS old_id, inserted.id AS new_id
        FROM source_sets AS item
        JOIN inserted_sets AS inserted
          ON inserted.exercise_variant_id = item.new_variant_id
         AND inserted.ordinal = item.ordinal
    )
    SELECT 'day'::text, day_map.old_id, day_map.new_id FROM day_map
    UNION ALL
    SELECT 'workout_unit'::text, unit_map.old_id, unit_map.new_id FROM unit_map
    UNION ALL
    SELECT 'exercise_slot'::text, slot_map.old_id, slot_map.new_id FROM slot_map
    UNION ALL
    SELECT 'exercise_variant'::text, variant_map.old_id, variant_map.new_id FROM variant_map
    UNION ALL
    SELECT 'set_infra'::text, set_map.old_id, set_map.new_id FROM set_map;
END;
$$;

COMMENT ON FUNCTION plans.copy_revision_tree(integer, integer, boolean) IS
    'Copies the days, workout units, exercise slots, slot target muscles, exercise variants and set prescriptions of the source revision into the target revision, which must exist and be empty (no days; raises object_not_in_prerequisite_state otherwise). Every column is copied as stored, lineage keys always. p_regenerate_progression_ids false keeps progression_id; true gives each distinct source progression_id one new id, preserving sharing. Returns (entity, source_id, target_id) for entity day, workout_unit, exercise_slot, exercise_variant, set_infra; target muscles have no id. The caller creates the target revision and owns the transaction. A column added to any of these tables must be added here too (CREATE OR REPLACE FUNCTION in the same migration).';
