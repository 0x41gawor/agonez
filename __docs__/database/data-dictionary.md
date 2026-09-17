# Data dictionary

This dictionary describes the 2026-09-17 physical snapshot. Fields added by unapplied-in-snapshot migrations are marked **Projected**.

## Unit conventions

- Explicit units are encoded in column names or formulas.
- “Dimensionless” means ratio, enum, count, ordinal, or model index with no physical unit.
- “Inferred — verify” is used where source naming/formulas suggest meaning but no enforced definition exists.
- Timestamps are PostgreSQL `timestamptz` and serialize as ISO 8601.

## `core.exercises`

Purpose: canonical exercise identity, authored instructions, categorization, media references, and rep-range recommendations.

Primary key: `id`. Alternate keys: `slug`, `name`, `name_full`.

| Column | SQL type / nullability | Meaning | Unit |
| --- | --- | --- | --- |
| `id` | `integer NOT NULL`, sequence default | Internal catalog identity | Dimensionless |
| `slug` | `varchar(100) NOT NULL UNIQUE` | Stable public/cross-system identifier | Dimensionless |
| `name`, `name_full` | `varchar(255) NOT NULL UNIQUE` | Canonical English labels | N/A |
| `body_part` | `core.body_part_enum NOT NULL` | Broad anatomical region | Dimensionless |
| `target_category` | `core.target_category_enum NOT NULL` | Programming target category | Dimensionless |
| `mechanics_tier` | `core.mechanics_tier_enum NOT NULL` | Exercise complexity/mechanics class | Dimensionless |
| `resistance_source` | `core.resistance_source_enum NOT NULL` | Equipment/resistance family | Dimensionless |
| `technique` | `jsonb NOT NULL DEFAULT {}` | Authored execution object | N/A |
| `comments` | `jsonb NOT NULL DEFAULT {}` | Additional structured prose | N/A |
| `video_links` | `text[] NOT NULL DEFAULT {}` | Demonstration URLs | N/A |
| `execution_pattern` | `core.execution_pattern_enum NOT NULL` | Bilateral/unilateral/alternating | Dimensionless |
| `created_at`, `updated_at` | `timestamptz NOT NULL DEFAULT now()` | Audit timestamps | Timestamp |
| `recommended_rep_profile` | `jsonb NOT NULL` | Rep-range recommendation per loading mode | Repetitions |

`recommended_rep_profile` expected shape (validated by API response models, not by SQL):

```json
{
  "high_load": {"min": 5, "max": 8},
  "moderate_load": {"min": 8, "max": 12},
  "low_load": null
}
```

All three keys are required in Python. Each value is null or a positive integer range with `max >= min`.

Observed `technique` objects include top-level prose keys such as `grip` and `stance` and a nested `tldr` object with `setup`, `execution`, `focus`, and `stop_when`. The SQL schema permits any JSON.

## `core.exercise_translations`

Purpose: locale-specific overlays for selected exercise fields. Primary key: (`exercise_id`, `locale`). FK: `exercise_id` → `core.exercises.id` with cascade delete.

| Column | Type | Meaning |
| --- | --- | --- |
| `exercise_id` | `bigint NOT NULL` | Parent exercise; width differs from parent `integer` but is compatible |
| `locale` | `varchar(35) NOT NULL` | Locale tag; not constrained to API-supported set |
| `name`, `name_full` | `text NOT NULL` | Localized labels |
| `technique`, `comments` | `jsonb NULL` | Optional field-level overlays |
| `status` | `varchar(20) NOT NULL DEFAULT 'published'` | Only `published` rows are served; values are not enum/check constrained |
| `created_at`, `updated_at` | `timestamptz NOT NULL` | Audit timestamps |

## `core.muscles`

Purpose: canonical anatomy, morphology, capacity, programming traits, authored content, and media references.

Primary key: `id`. Alternate keys: `slug`, `name`.

| Column | Type | Meaning | Unit |
| --- | --- | --- | --- |
| `id` | `integer NOT NULL` | Internal identity | Dimensionless |
| `slug` | `varchar(100) NOT NULL UNIQUE` | Stable vector/API identifier | Dimensionless |
| `name` | `varchar(100) NOT NULL UNIQUE` | Canonical/Latin name | N/A |
| `body_part` | `core.body_part_enum NOT NULL` | Region | Dimensionless |
| `complex` | `core.muscle_complex_enum NOT NULL` | Muscle group | Dimensionless |
| `mass_g` | `numeric(8,2) NOT NULL`, positive | Muscle mass | g — explicit |
| `mv_cm3` | `numeric(8,2) NOT NULL`, positive | Muscle volume | cm³ — explicit |
| `pcsa` | `numeric(6,2) NOT NULL`, positive | Physiological cross-sectional area | cm² — inferred from API/UI; verify source definition |
| `architecture` | `core.muscle_architecture_enum NOT NULL` | Fiber architecture classification | Dimensionless |
| `fiber_bias_type_i`, `fiber_bias_type_ii` | `numeric(4,3) NOT NULL`, 0–1, sum≈1 | Fiber-type fractions | Ratio — explicit from checks |
| `smh_factor` | `core.smh_factor_enum NOT NULL` | Programming/recovery trait; expansion not defined in code | Ordinal category — unknown semantics |
| `strength_curve` | enum, default `Bell-shaped` | Length–strength behavior category | Dimensionless |
| `leverage_peak` | enum, default `Mid_Range` | Range position of leverage peak | Dimensionless |
| `bible_markdown` | `text NOT NULL DEFAULT ''` | Canonical article | Markdown text |
| `article_links`, `video_links` | `text[] NOT NULL DEFAULT {}` | References/media URLs | N/A |
| `mass_reference` | anatomical enum, default `Bilateral` | Whether mass measurement is bilateral/unilateral | Dimensionless |
| `optimal_fiber_length_cm` | `numeric(5,2) NULL` | Optimal fiber length | cm — explicit |
| `pennation_angle_deg` | `numeric(5,2) NULL` | Pennation angle | degrees — explicit |
| `pennation_cos` | `numeric(4,3) NULL` | Cosine of pennation angle | Dimensionless |
| `pcsa_fiber_cm2` | `numeric(5,2) NULL` | Fiber-derived PCSA | cm² — explicit |
| `pcsa_projected_fcsa_cm2` | `numeric(5,2) NULL` | Projected functional cross-sectional area used as analysis denominator | cm² — explicit |

## `core.muscle_translations`

Purpose: localized display name and article overlay. Primary key: (`muscle_id`, `locale`). FK: muscle cascade delete.

| Column | Type | Meaning |
| --- | --- | --- |
| `muscle_id` | `bigint NOT NULL` | Parent muscle |
| `locale` | `varchar(35) NOT NULL` | Locale tag; unconstrained |
| `display_name` | `text NOT NULL` | Localized common name |
| `bible_markdown` | `text NULL` | Optional localized article |
| `created_at`, `updated_at` | `timestamptz NOT NULL` | Audit timestamps |

## `core.muscle_exercise_mappings`

Purpose: structured classification of a muscle's relationship to an exercise. The table is empty in the inspected dump and unused by current API queries.

Primary key: (`muscle_id`, `exercise_id`, `resistance_profile`, `complexity`). Only `muscle_id` has a physical FK.

| Column | Type | Meaning |
| --- | --- | --- |
| `muscle_id` | `integer NOT NULL`, FK cascade | Muscle identity |
| `exercise_id` | `integer NOT NULL`, no FK | Intended exercise identity — inferred |
| `complexity` | `core.mechanics_tier_enum NOT NULL` | Relationship/exercise mechanics classification; exact semantics unclear |
| `resistance_profile` | `core.resistance_profile_enum NOT NULL` | Lengthened/mid/shortened bias |

## `core.progression_models`

Purpose: localized descriptive catalog for progression intent; it does not store executable policy parameters.

| Column | Snapshot type | Meaning |
| --- | --- | --- |
| `slug` | `text PK`, regex `[a-z0-9_]+` | Stable model identifier |
| `name` | `text NOT NULL UNIQUE` | Short canonical label |
| `name_full` | `text NOT NULL` | Expanded label |
| `when_to_use` | `text NOT NULL` | Selection guidance |
| `how_to_apply` | `text NOT NULL` | Human application guidance |
| `display_order` | **Projected:** `integer NOT NULL UNIQUE CHECK > 0` | Stable simple-to-complex catalog order |

## `core.progression_model_translations`

Purpose: localized progression guidance. Primary key: (`progression_model_slug`, `locale`). FK updates/deletes cascade from the model.

`locale` is constrained to `pl`, `fr`, `es`, `de`, `it`, `pt-BR`, `sv`, `nl`, or `uk`; English lives on the parent. All text and timestamp fields are NOT NULL.

## `engine.exercises`

Purpose: calculated enrichment for a catalog exercise. Primary key: `slug`; no catalog FK.

| Column | Type | Meaning | Unit |
| --- | --- | --- | --- |
| `slug` | `varchar NOT NULL PK` | Logical join to exercise slug | Dimensionless |
| `load_capacity_kg` | `numeric(5,2) NULL` | Effective/external load capacity | kg — explicit; bodyweight interpretation may be model-specific |
| `systemic_propulsive_fcsa_demand` | `numeric(6,2) NULL`, nonnegative | Aggregate propulsive FCSA demand | cm² — inferred from API/UI; verify calculation definition |
| `propulsive_fcsa_contribution_vector` | `jsonb NULL` | Muscle slug → propulsive contribution | cm² — inferred |
| `active_tension_exposure_vector` | `jsonb NULL` | Muscle slug → active-tension exposure | Model value; inferred cm²-like, verify |
| `etu_vector` | `jsonb NULL` | Muscle slug → ETU per effective rep factor | ETU-like model unit; not a physical unit |
| `muscle_recovery_cost_modifier_vector` | `jsonb NULL` | Muscle slug → recovery cost multiplier | Dimensionless ratio |
| `joint_load_exposure_vector` | `jsonb NULL` | Joint slug → load exposure index | Dimensionless model index; explicitly not a safety score |
| corresponding `*_eval_notes` | `jsonb NULL` | Provenance/explanation objects | N/A |
| `systemic_propulsive_fcsa_eval_note` | `jsonb NOT NULL DEFAULT {}` | Systemic-demand explanation | N/A |

The SQL object-type check covers propulsive, active-tension, active-tension notes, ETU, and ETU notes. It does not cover recovery/joint vectors or their notes. Python rejects non-map inputs and ignores malformed/negative vector entries while adding diagnostics.

## `plans.workout_plans`

Purpose: stable plan aggregate root.

| Column | Type | Meaning |
| --- | --- | --- |
| `id` | identity `integer PK` | Plan identity |
| `name` | `varchar(200) NOT NULL`, nonblank | Display name |
| `description` | `text NULL` | Optional prose |
| `created_at`, `updated_at` | `timestamptz NOT NULL` | Audit timestamps; saves update `updated_at` |

## `plans.plan_revisions`

Purpose: revision and optimistic-lock boundary. Unique (`plan_id`, `revision_no`); partial unique index permits one DRAFT per plan.

| Column | Type | Meaning | Unit |
| --- | --- | --- | --- |
| `id` | identity `integer PK` | Revision identity | Dimensionless |
| `plan_id` | `integer FK NOT NULL`, cascade | Parent plan | Dimensionless |
| `revision_no` | `integer NOT NULL CHECK > 0` | Plan-local revision number | Dimensionless |
| `status` | enum NOT NULL, default DRAFT | Lifecycle state | Dimensionless |
| `based_on_revision_id` | self-FK NULL, set null on delete | Ancestry (used on duplicate across plans) | Dimensionless |
| `lock_version` | `integer NOT NULL CHECK > 0` | Optimistic concurrency token | Dimensionless |
| `snapshot` | `jsonb NULL` | Unused/undefined snapshot payload | Unknown |
| `created_at`, `updated_at`, `released_at` | timestamps | Audit/lifecycle timestamps | Timestamp |

## `plans.day_prescriptions`

Purpose: zero-based ordered microcycle day. Unique (`revision_id`, `ordinal`), deferred.

| Column | Type | Meaning | Unit |
| --- | --- | --- | --- |
| `id` | identity integer PK | Stable day identity | Dimensionless |
| `revision_id` | integer FK NOT NULL, cascade | Parent revision | Dimensionless |
| `ordinal` | integer NOT NULL CHECK ≥0 | Order and analysis day offset | Days as ordinal; analysis multiplies by 24 h |
| `name` | varchar(200) NOT NULL nonblank | Label | N/A |
| `description` | text NULL | Prose | N/A |
| `weekday` | smallint NULL, 1–7 | ISO weekday display metadata | Dimensionless |

## `plans.workout_unit_prescriptions`

Purpose: optional workout content for a day. Unique deferred `day_id` enforces zero or one unit per day.

All columns: identity `id`; cascading `day_id` FK; nonblank `name`; nullable `description`, `warmup_notes`, `stretch_notes`. Text has no encoded units.

## `plans.exercise_slots`

Purpose: stable workout role containing intent and exercise alternatives. Unique deferred (`workout_unit_id`, `ordinal`).

| Column | Type | Meaning | Unit |
| --- | --- | --- | --- |
| `id` | identity integer PK | Slot identity | Dimensionless |
| `workout_unit_id` | integer FK NOT NULL, cascade | Parent workout | Dimensionless |
| `ordinal` | integer NOT NULL CHECK ≥0 | Order | Dimensionless |
| `name` | varchar(200) NULL | Optional label | N/A |
| `description`, `goal` | text NULL | Author intent | N/A |
| `role` | `plans.exercise_slot_role NOT NULL` | Programming role | Dimensionless |
| `volume_axis` | varchar(100) NULL | Key used to select an axis override | Dimensionless string |
| `loading_mode` | enum NOT NULL default `moderate_load` | Static loading intent | Dimensionless category |
| `loading_cycle` | enum array NULL, 2–52 entries | Repeating per-microcycle loading intent | One category per microcycle position |

## `plans.exercise_slot_target_muscles`

Purpose: many-to-many intentional target declaration. Composite PK (`slot_id`, `muscle_id`). Slot deletion cascades; muscle deletion is restricted.

No weighting is stored. Analysis classifies a matching contribution as intentional, a nonmatching contribution as incidental, and all contributions as unclassified when the slot has no target rows.

## `plans.exercise_variants`

Purpose: ordered concrete exercise alternatives for a slot. Unique deferred (`slot_id`, `ordinal`); partial unique index permits at most one DEFAULT.

| Column | Type | Meaning |
| --- | --- | --- |
| `id` | identity integer PK | Stable variant identity |
| `slot_id` | integer FK NOT NULL, cascade | Parent slot |
| `ordinal` | integer NOT NULL CHECK ≥0 | Order |
| `variant_type` | enum NOT NULL | DEFAULT or FALLBACK |
| `exercise_id` | integer FK NOT NULL, restrict | Catalog exercise |
| `progression_model_slug` | **Projected:** text NULL, FK update cascade/delete restrict | Optional descriptive progression intent |

## `plans.set_infra_prescriptions`

Purpose: ordered set prescription. Unique deferred (`exercise_variant_id`, `ordinal`).

| Column | Type | Meaning | Unit |
| --- | --- | --- | --- |
| `id` | identity integer PK | Stable set identity | Dimensionless |
| `exercise_variant_id` | integer FK NOT NULL, cascade | Parent variant | Dimensionless |
| `ordinal` | integer NOT NULL CHECK ≥0 | Order | Dimensionless |
| `rep_min`, `rep_max` | smallint NOT NULL, valid positive range | Concrete repetition range | Repetitions — explicit |
| `rir` | smallint NOT NULL, 0–4 | Repetitions in reserve | Repetitions — explicit |
| `min_volume_level` | smallint NOT NULL default 0, ≥0 | Activation threshold in resolver | Dimensionless level |
| `loading_mode` | enum NULL | Static override; null inherits | Dimensionless category |
| `loading_cycle` | enum array NULL, 2–52 entries | Repeating set-level override | Per microcycle position |

No load, rest interval, tempo, or performed result is stored.

## `public.agonez_schema_migrations`

Purpose: migration idempotency/integrity.

| Column | Type | Meaning |
| --- | --- | --- |
| `version` | `text PK` | Packaged SQL filename |
| `checksum` | `text NOT NULL` | SHA-256 of SQL content; changed applied migrations are rejected |
| `applied_at` | `timestamptz NOT NULL DEFAULT now()` | Application time |
