# ERD layer 3 — physical model

The diagrams below describe exact columns in `agonez_db_backup_2026-09-17.sql`. A final overlay lists changes from packaged migrations `0003` and `0004` because current code depends on them.

Legend: `PK` primary key, `FK` foreign key, `UK` unique. Mermaid does not encode nullability; the tables below the diagrams do.

## `core` schema

```mermaid
erDiagram
    EXERCISE_TRANSLATIONS {
        bigint exercise_id PK,FK
        varchar_35 locale PK
        text name
        text name_full
        jsonb technique
        jsonb comments
        varchar_20 status
        timestamptz created_at
        timestamptz updated_at
    }
    EXERCISES {
        integer id PK
        varchar_100 slug UK
        varchar_255 name UK
        varchar_255 name_full UK
        body_part_enum body_part
        target_category_enum target_category
        mechanics_tier_enum mechanics_tier
        resistance_source_enum resistance_source
        jsonb technique
        jsonb comments
        text_array video_links
        execution_pattern_enum execution_pattern
        timestamptz created_at
        timestamptz updated_at
        jsonb recommended_rep_profile
    }
    MUSCLE_EXERCISE_MAPPINGS {
        integer muscle_id PK,FK
        integer exercise_id PK
        mechanics_tier_enum complexity PK
        resistance_profile_enum resistance_profile PK
    }
    MUSCLE_TRANSLATIONS {
        bigint muscle_id PK,FK
        varchar_35 locale PK
        text display_name
        text bible_markdown
        timestamptz created_at
        timestamptz updated_at
    }
    MUSCLES {
        integer id PK
        varchar_100 slug UK
        varchar_100 name UK
        body_part_enum body_part
        muscle_complex_enum complex
        numeric_8_2 mass_g
        numeric_8_2 mv_cm3
        numeric_6_2 pcsa
        muscle_architecture_enum architecture
        numeric_4_3 fiber_bias_type_i
        numeric_4_3 fiber_bias_type_ii
        smh_factor_enum smh_factor
        strength_curve_enum strength_curve
        leverage_peak_enum leverage_peak
        text bible_markdown
        text_array article_links
        text_array video_links
        anatomical_reference_enum mass_reference
        numeric_5_2 optimal_fiber_length_cm
        numeric_5_2 pennation_angle_deg
        numeric_4_3 pennation_cos
        numeric_5_2 pcsa_fiber_cm2
        numeric_5_2 pcsa_projected_fcsa_cm2
    }
    PROGRESSION_MODEL_TRANSLATIONS {
        text progression_model_slug PK,FK
        varchar_5 locale PK
        text name
        text name_full
        text when_to_use
        text how_to_apply
        timestamptz created_at
        timestamptz updated_at
    }
    PROGRESSION_MODELS {
        text slug PK
        text name UK
        text name_full
        text when_to_use
        text how_to_apply
    }

    EXERCISES ||--o{ EXERCISE_TRANSLATIONS : exercise_id
    MUSCLES ||--o{ MUSCLE_TRANSLATIONS : muscle_id
    MUSCLES ||--o{ MUSCLE_EXERCISE_MAPPINGS : muscle_id
    PROGRESSION_MODELS ||--o{ PROGRESSION_MODEL_TRANSLATIONS : progression_model_slug
```

Nullability exceptions: translated `technique`, translated `comments`, translated muscle `bible_markdown`, and the five muscle measurements from `optimal_fiber_length_cm` through `pcsa_projected_fcsa_cm2` are nullable. All other diagrammed `core` columns are NOT NULL. `muscle_exercise_mappings.exercise_id` has no physical FK in this snapshot.

## `engine` schema

```mermaid
erDiagram
    ENGINE_EXERCISES {
        varchar slug PK
        numeric_5_2 load_capacity_kg
        numeric_6_2 systemic_propulsive_fcsa_demand
        jsonb propulsive_fcsa_contribution_vector
        jsonb active_tension_exposure_vector
        jsonb active_tension_exposure_vector_eval_notes
        jsonb etu_vector
        jsonb etu_vector_eval_notes
        jsonb muscle_recovery_cost_modifier_vector
        jsonb muscle_recovery_cost_modifier_vector_eval_notes
        jsonb joint_load_exposure_vector
        jsonb joint_load_exposure_vector_eval_notes
        jsonb systemic_propulsive_fcsa_eval_note
    }
```

Only `slug` and `systemic_propulsive_fcsa_eval_note` are NOT NULL. The notes column defaults to `{}`. No physical FK links the slug to `core.exercises`.

Expected JSON vector shapes:

```json
{
  "<muscle_slug>": 33.62,
  "<another_muscle_slug>": 4.0
}
```

`joint_load_exposure_vector` uses joint slugs instead:

```json
{
  "glenohumeral_joint": 0.46,
  "lumbar_spine": 0.68
}
```

Eval-note objects usually contain `slug` and `notes` plus calculation-specific fields. Their exact structure is not constrained or consumed by the API.

## `plans` schema

```mermaid
erDiagram
    WORKOUT_PLANS {
        integer id PK
        varchar_200 name
        text description
        timestamptz created_at
        timestamptz updated_at
    }
    PLAN_REVISIONS {
        integer id PK
        integer plan_id FK
        integer revision_no
        plan_revision_status status
        integer based_on_revision_id FK
        integer lock_version
        jsonb snapshot
        timestamptz created_at
        timestamptz updated_at
        timestamptz released_at
    }
    DAY_PRESCRIPTIONS {
        integer id PK
        integer revision_id FK
        integer ordinal
        varchar_200 name
        text description
        smallint weekday
    }
    WORKOUT_UNIT_PRESCRIPTIONS {
        integer id PK
        integer day_id FK,UK
        varchar_200 name
        text description
        text warmup_notes
        text stretch_notes
    }
    EXERCISE_SLOTS {
        integer id PK
        integer workout_unit_id FK
        integer ordinal
        varchar_200 name
        text description
        text goal
        exercise_slot_role role
        varchar_100 volume_axis
        loading_mode loading_mode
        loading_mode_array loading_cycle
    }
    EXERCISE_SLOT_TARGET_MUSCLES {
        integer slot_id PK,FK
        integer muscle_id PK,FK
    }
    EXERCISE_VARIANTS {
        integer id PK
        integer slot_id FK
        integer ordinal
        exercise_variant_type variant_type
        integer exercise_id FK
    }
    SET_INFRA_PRESCRIPTIONS {
        integer id PK
        integer exercise_variant_id FK
        integer ordinal
        smallint rep_min
        smallint rep_max
        smallint rir
        smallint min_volume_level
        loading_mode loading_mode
        loading_mode_array loading_cycle
    }

    WORKOUT_PLANS ||--o{ PLAN_REVISIONS : plan_id
    PLAN_REVISIONS ||--o{ PLAN_REVISIONS : based_on_revision_id
    PLAN_REVISIONS ||--o{ DAY_PRESCRIPTIONS : revision_id
    DAY_PRESCRIPTIONS ||--o| WORKOUT_UNIT_PRESCRIPTIONS : day_id
    WORKOUT_UNIT_PRESCRIPTIONS ||--o{ EXERCISE_SLOTS : workout_unit_id
    EXERCISE_SLOTS ||--o{ EXERCISE_SLOT_TARGET_MUSCLES : slot_id
    EXERCISE_SLOTS ||--o{ EXERCISE_VARIANTS : slot_id
    EXERCISE_VARIANTS ||--o{ SET_INFRA_PRESCRIPTIONS : exercise_variant_id
```

Nullable fields: plan/day/unit/slot descriptions; `based_on_revision_id`, `snapshot`, `released_at`; day `weekday`; slot `name`, `goal`, `volume_axis`, `loading_cycle`; set `loading_mode`, `loading_cycle`. All other plan columns are NOT NULL.

Cross-schema FKs omitted from the diagram for readability:

- `plans.exercise_slot_target_muscles.muscle_id` → `core.muscles.id` (`ON DELETE RESTRICT`).
- `plans.exercise_variants.exercise_id` → `core.exercises.id` (`ON DELETE RESTRICT`).

## `public` migration ledger

```mermaid
erDiagram
    AGONEZ_SCHEMA_MIGRATIONS {
        text version PK
        text checksum
        timestamptz applied_at
    }
```

All three columns are NOT NULL. The inspected rows are `0001_plancreator_foundation.sql` and `0002_loading_prescriptions.sql`.

## Projected migration overlay required by current code

After `0003` and `0004`:

| Table | Added column | Constraints/indexes |
| --- | --- | --- |
| `plans.exercise_variants` | `progression_model_slug text NULL` | FK to `core.progression_models(slug)` with update cascade/delete restrict; partial btree index where non-null |
| `core.progression_models` | `display_order integer NOT NULL` | `CHECK (display_order > 0)`; unique constraint; documented stable catalog order |

No other physical columns are added by the four packaged migrations.
