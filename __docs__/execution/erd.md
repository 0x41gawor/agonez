# Execution ERDs

## Conceptual ERD

```mermaid
erDiagram
    PLAN_REVISION ||--o{ PLAN_RUN : "starts"
    PLAN_RUN ||--|{ MICROCYCLE : materializes
    PLAN_REVISION ||--o{ MICROCYCLE : governs
    PLAN_RUN ||--o{ WORKOUT_TRACK : identifies
    WORKOUT_TRACK ||--o{ EXERCISE_TRACK : identifies
    MICROCYCLE ||--o{ WORKOUT_SESSION : schedules
    WORKOUT_TRACK ||--o{ WORKOUT_SESSION : repeats
    WORKOUT_SESSION ||--o| WORKOUT_PRESCRIPTION : receives
    WORKOUT_PRESCRIPTION ||--o{ EXERCISE_PRESCRIPTION : contains
    EXERCISE_TRACK ||--o{ EXERCISE_PRESCRIPTION : traces
    EXERCISE_PRESCRIPTION ||--o{ SET_PRESCRIPTION : contains
    WORKOUT_PRESCRIPTION ||--o| WORKOUT_PERFORMANCE : produces
    WORKOUT_PERFORMANCE ||--o{ EXERCISE_PERFORMANCE : contains
    EXERCISE_TRACK ||--o{ EXERCISE_PERFORMANCE : traces
    EXERCISE_PERFORMANCE ||--o{ SET_PERFORMANCE : contains
    PLAN_RUN ||--o{ PLAN_RUN_EVENT : journals
```

## Physical run, calendar, and identity ERD

```mermaid
erDiagram
    plans_plan_revisions {
        integer id PK
        integer plan_id FK
        integer revision_no
    }
    exec_plan_runs {
        integer id PK
        integer initial_plan_revision_id FK
        date starts_on
        integer microcycle_count
        integer microcycle_duration_days
        date ends_on_generated
        plan_run_status status
    }
    exec_microcycles {
        integer id PK
        integer plan_run_id FK
        integer ordinal
        date starts_on
        date ends_on
        integer plan_revision_id FK
        microcycle_classification classification
    }
    exec_workout_unit_tracks {
        integer id PK
        integer plan_run_id FK
        text logical_key
        varchar name
    }
    exec_exercise_unit_tracks {
        integer id PK
        integer plan_run_id FK
        integer workout_unit_track_id FK
        text logical_key
        uuid source_progression_id
    }
    exec_workout_sessions {
        integer id PK
        integer plan_run_id FK
        integer microcycle_id FK
        integer workout_unit_track_id FK
        integer source_plan_day_id FK
        integer source_plan_workout_unit_id FK
        integer fallback_source_plan_workout_unit_id FK
        date scheduled_date
        workout_session_status status
        completion_mode completion_mode
    }
    exec_plan_run_events {
        integer id PK
        integer plan_run_id FK
        integer microcycle_id FK
        integer workout_session_id FK
        integer exercise_unit_track_id FK
        plan_run_event_type event_type
        timestamptz occurred_at
    }

    plans_plan_revisions ||--o{ exec_plan_runs : initial_plan_revision_id
    exec_plan_runs ||--|{ exec_microcycles : plan_run_id
    plans_plan_revisions ||--o{ exec_microcycles : plan_revision_id
    exec_plan_runs ||--o{ exec_workout_unit_tracks : plan_run_id
    exec_workout_unit_tracks ||--o{ exec_exercise_unit_tracks : workout_unit_track_id
    exec_microcycles ||--o{ exec_workout_sessions : microcycle_id
    exec_workout_unit_tracks ||--o{ exec_workout_sessions : workout_unit_track_id
    exec_plan_runs ||--o{ exec_plan_run_events : plan_run_id
```

## Physical prescription and performance ERD

```mermaid
erDiagram
    exec_workout_sessions {
        integer id PK
        integer microcycle_id FK
        workout_session_status status
        completion_mode completion_mode
    }
    exec_workout_unit_prescriptions {
        integer id PK
        integer workout_session_id FK_UK
        integer source_plan_revision_id FK
        integer source_plan_workout_unit_id FK
        varchar name_snapshot
        text prescription_comment
    }
    exec_exercise_unit_prescriptions {
        integer id PK
        integer workout_unit_prescription_id FK
        integer exercise_unit_track_id FK
        integer source_plan_exercise_slot_id FK
        integer source_plan_exercise_variant_id FK
        integer prescribed_exercise_id FK
        integer previous_exercise_performance_id FK
        integer ordinal
    }
    exec_set_prescriptions {
        integer id PK
        integer exercise_unit_prescription_id FK
        integer source_plan_set_infra_id FK
        integer ordinal
        numeric prescribed_load_kg
        smallint rep_min
        smallint rep_max
        rir_prescription target_rir
    }
    exec_workout_unit_performances {
        integer id PK
        integer workout_unit_prescription_id FK_UK
        performance_status status
        timestamptz started_at
        timestamptz completed_at
    }
    exec_exercise_unit_performances {
        integer id PK
        integer workout_unit_performance_id FK
        integer prescribed_exercise_unit_id FK_UK
        integer exercise_unit_track_id FK
        integer actual_exercise_id FK
        exercise_execution_mode execution_mode
        jsonb etu_vector_snapshot
    }
    exec_set_performances {
        integer id PK
        integer exercise_unit_performance_id FK
        integer prescribed_set_id FK_UK
        integer ordinal
        performed_set_status status
        numeric load_kg
        smallint repetitions
        smallint rir
    }

    exec_workout_sessions ||--o| exec_workout_unit_prescriptions : workout_session_id
    exec_workout_unit_prescriptions ||--o{ exec_exercise_unit_prescriptions : workout_unit_prescription_id
    exec_exercise_unit_prescriptions ||--o{ exec_set_prescriptions : exercise_unit_prescription_id
    exec_workout_unit_prescriptions ||--o| exec_workout_unit_performances : workout_unit_prescription_id
    exec_workout_unit_performances ||--o{ exec_exercise_unit_performances : workout_unit_performance_id
    exec_exercise_unit_prescriptions ||--o| exec_exercise_unit_performances : prescribed_exercise_unit_id
    exec_exercise_unit_performances ||--o{ exec_set_performances : exercise_unit_performance_id
    exec_set_prescriptions ||--o| exec_set_performances : prescribed_set_id
    exec_exercise_unit_performances ||--o{ exec_exercise_unit_prescriptions : previous_exercise_performance_id
```

Additional cross-schema lineage FKs point to `plans.day_prescriptions`,
`plans.workout_unit_prescriptions`, `plans.exercise_slots`, `plans.exercise_variants`,
`plans.set_infra_prescriptions`, and `core.exercises`.

