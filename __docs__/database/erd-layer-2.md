# ERD layer 2 — logical/domain

## Catalog and engine

```mermaid
erDiagram
    CORE_EXERCISES {
        int id PK
        varchar slug UK
        varchar name UK
        body_part_enum body_part
        target_category_enum target_category
        mechanics_tier_enum mechanics_tier
        resistance_source_enum resistance_source
        execution_pattern_enum execution_pattern
        jsonb technique
        jsonb comments
        jsonb recommended_rep_profile
    }
    EXERCISE_TRANSLATIONS {
        bigint exercise_id PK,FK
        varchar locale PK
        text name
        text name_full
        jsonb technique
        jsonb comments
        varchar status
    }
    ENGINE_EXERCISES {
        varchar slug PK
        numeric load_capacity_kg
        numeric systemic_propulsive_fcsa_demand
        jsonb propulsive_fcsa_contribution_vector
        jsonb active_tension_exposure_vector
        jsonb etu_vector
        jsonb muscle_recovery_cost_modifier_vector
        jsonb joint_load_exposure_vector
    }
    CORE_MUSCLES {
        int id PK
        varchar slug UK
        varchar name UK
        body_part_enum body_part
        muscle_complex_enum complex
        numeric mass_g
        numeric mv_cm3
        numeric pcsa
        numeric pcsa_projected_fcsa_cm2
        numeric fiber_bias_type_i
        numeric fiber_bias_type_ii
    }
    MUSCLE_TRANSLATIONS {
        bigint muscle_id PK,FK
        varchar locale PK
        text display_name
        text bible_markdown
    }
    MUSCLE_EXERCISE_MAPPINGS {
        int muscle_id PK,FK
        int exercise_id PK
        resistance_profile_enum resistance_profile PK
        mechanics_tier_enum complexity PK
    }
    PROGRESSION_MODELS {
        text slug PK
        text name UK
        text name_full
        text when_to_use
        text how_to_apply
        int display_order "projected 0004"
    }
    PROGRESSION_TRANSLATIONS {
        text progression_model_slug PK,FK
        varchar locale PK
        text name
        text name_full
        text when_to_use
        text how_to_apply
    }

    CORE_EXERCISES ||--o{ EXERCISE_TRANSLATIONS : exercise_id
    CORE_MUSCLES ||--o{ MUSCLE_TRANSLATIONS : muscle_id
    CORE_MUSCLES ||--o{ MUSCLE_EXERCISE_MAPPINGS : muscle_id
    CORE_EXERCISES ||--o{ MUSCLE_EXERCISE_MAPPINGS : "exercise_id; logical only"
    CORE_EXERCISES ||--o| ENGINE_EXERCISES : "slug; logical only"
    PROGRESSION_MODELS ||--o{ PROGRESSION_TRANSLATIONS : progression_model_slug
```

The engine vectors logically reference muscles/joints through JSON keys. Those are not relational FKs. Muscle keys are validated in the evaluator only as numeric map entries; unknown keys can flow into diagnostics/summaries.

## Plans

```mermaid
erDiagram
    WORKOUT_PLANS {
        int id PK
        varchar name
        text description
        timestamptz created_at
        timestamptz updated_at
    }
    PLAN_REVISIONS {
        int id PK
        int plan_id FK
        int revision_no
        plan_revision_status status
        int based_on_revision_id FK
        int lock_version
        jsonb snapshot
    }
    DAY_PRESCRIPTIONS {
        int id PK
        int revision_id FK
        int ordinal
        smallint weekday
        varchar name
    }
    WORKOUT_UNITS {
        int id PK
        int day_id FK,UK
        varchar name
        text warmup_notes
        text stretch_notes
    }
    EXERCISE_SLOTS {
        int id PK
        int workout_unit_id FK
        int ordinal
        exercise_slot_role role
        varchar volume_axis
        loading_mode loading_mode
        loading_mode_array loading_cycle
    }
    SLOT_TARGET_MUSCLES {
        int slot_id PK,FK
        int muscle_id PK,FK
    }
    EXERCISE_VARIANTS {
        int id PK
        int slot_id FK
        int ordinal
        exercise_variant_type variant_type
        int exercise_id FK
        text progression_model_slug "projected FK"
    }
    SET_PRESCRIPTIONS {
        int id PK
        int exercise_variant_id FK
        int ordinal
        smallint rep_min
        smallint rep_max
        smallint rir
        smallint min_volume_level
        loading_mode loading_mode
        loading_mode_array loading_cycle
    }
    CORE_EXERCISES {
        int id PK
        varchar slug UK
    }
    CORE_MUSCLES {
        int id PK
        varchar slug UK
    }
    PROGRESSION_MODELS {
        text slug PK
    }

    WORKOUT_PLANS ||--o{ PLAN_REVISIONS : plan_id
    PLAN_REVISIONS ||--o{ PLAN_REVISIONS : based_on_revision_id
    PLAN_REVISIONS ||--o{ DAY_PRESCRIPTIONS : revision_id
    DAY_PRESCRIPTIONS ||--o| WORKOUT_UNITS : day_id
    WORKOUT_UNITS ||--o{ EXERCISE_SLOTS : workout_unit_id
    EXERCISE_SLOTS ||--o{ SLOT_TARGET_MUSCLES : slot_id
    CORE_MUSCLES ||--o{ SLOT_TARGET_MUSCLES : muscle_id
    EXERCISE_SLOTS ||--o{ EXERCISE_VARIANTS : slot_id
    CORE_EXERCISES ||--o{ EXERCISE_VARIANTS : exercise_id
    PROGRESSION_MODELS ||--o{ EXERCISE_VARIANTS : progression_model_slug
    EXERCISE_VARIANTS ||--o{ SET_PRESCRIPTIONS : exercise_variant_id
```

The nested JSON API is not stored as one JSON document. `PlanService.assemble_draft()` groups these rows into `PlanDraftArtifact`; saves perform the reverse mapping inside one transaction.
