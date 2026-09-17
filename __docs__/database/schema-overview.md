# Database schema overview

## Snapshot inventory

The 2026-09-17 dump was produced by PostgreSQL 15.13 and contains no application views, materialized views, functions, or triggers. It contains 15 application tables plus one migration-ledger table, 16 PostgreSQL enum types, two explicit catalog sequences, and identity sequences for plan tables.

| Schema | Tables | Responsibility | Rows in inspected dump |
| --- | ---: | --- | ---: |
| `core` | 7 | Catalog identity, anatomy, authored content, localization, progression descriptions | 2,158 total rows across tables |
| `engine` | 1 | Calculated exercise metrics and sparse exposure vectors | 159 |
| `plans` | 7 | Plan aggregate, revisions, ordered prescription tree, targets | 1,143 |
| `public` | 1 | Applied migration checksums | 2 |

### Per-table observed counts

| Table | Rows | Note |
| --- | ---: | --- |
| `core.exercises` | 159 | Canonical exercise records |
| `core.exercise_translations` | 1,431 | Nine translated rows per exercise in this snapshot |
| `core.muscles` | 47 | Canonical muscles |
| `core.muscle_translations` | 423 | Nine translated rows per muscle |
| `core.muscle_exercise_mappings` | 0 | Structurally present but unpopulated |
| `core.progression_models` | 14 | Canonical descriptive catalog |
| `core.progression_model_translations` | 84 | Partial locale coverage |
| `engine.exercises` | 159 | One observed row per core exercise, not FK-enforced |
| `plans.workout_plans` | 9 | Plan aggregate roots |
| `plans.plan_revisions` | 9 | All observed rows are drafts; enum permits more states |
| `plans.day_prescriptions` | 65 | Ordered microcycle days |
| `plans.workout_unit_prescriptions` | 37 | At most one per day |
| `plans.exercise_slots` | 226 | Stable plan roles |
| `plans.exercise_variants` | 226 | Default/fallback catalog references |
| `plans.set_infra_prescriptions` | 556 | Concrete rep/RIR prescriptions |
| `plans.exercise_slot_target_muscles` | 15 | Intent declarations |

## Enum types

### `core`

| Enum | Values |
| --- | --- |
| `anatomical_reference_enum` | `Bilateral`, `Unilateral` |
| `body_part_enum` | `Upper`, `Lower`, `Core`, `Full` |
| `execution_pattern_enum` | `Bilateral`, `Unilateral`, `Alternating` |
| `leverage_peak_enum` | `Lengthened_Range`, `Mid_Range`, `Shortened_Range`, `Flat_Profile` |
| `mechanics_tier_enum` | `Heavy_Compound`, `Secondary_Compound`, `Isolation`, `Stability_Isometric` |
| `muscle_complex_enum` | `Neck`, `Shoulder`, `Chest`, `Back`, `Biceps`, `Triceps`, `Forearms`, `Core`, `Glutes`, `Quads`, `Hamstrings`, `Hip_FA`, `Calves`, `Shin` |
| `resistance_profile_enum` | `Lengthened-biased`, `Mid-range-biased`, `Shortened-biased` |
| `resistance_source_enum` | `Bodyweight`, `Barbell`, `Dumbbell`, `Kettlebell`, `Cable`, `Selectorized_Machine`, `Plate_Loaded_Machine`, `Smith_Machine`, `Resistance_Band`, `Suspension`, `Partner_Resistance`, `Other` |
| `smh_factor_enum` | `zero`, `very_low`, `low`, `medium`, `high`, `very_high`, `extreme_high` |
| `strength_curve_enum` | `Ascending`, `Descending`, `Bell-shaped` |
| `target_category_enum` | 22 programming categories including `Chest_Clav_AD`, `Back_V`, `Core`, `Quads`, `Global_P`, and `Posterior_Delt` |
| `muscle_architecture_enum` | 43 literal values; several near-duplicates/typos exist and are listed as an ambiguity |

### `plans`

| Enum | Values |
| --- | --- |
| `plan_revision_status` | `DRAFT`, `RELEASED`, `ARCHIVED` |
| `exercise_slot_role` | `PRIMARY_PROGRESSIVE`, `SECONDARY_PROGRESSIVE`, `VOLUME_ACCUMULATION`, `ACCESSORY` |
| `exercise_variant_type` | `DEFAULT`, `FALLBACK` |
| `loading_mode` | `high_load`, `moderate_load`, `low_load` |

## Relationship and constraint highlights

- Plan child FKs use `ON DELETE CASCADE`; catalog references from plan targets/variants use `ON DELETE RESTRICT`.
- One workout unit per day is enforced by a unique constraint on `day_id`.
- Day, slot, variant, and set ordinals are unique within their parent and are `DEFERRABLE INITIALLY DEFERRED` to permit reordering inside a transaction.
- Partial unique indexes enforce at most one DRAFT per plan and at most one DEFAULT variant per slot.
- The API adds a stronger rule: a populated slot must have exactly one DEFAULT variant.
- RIR is constrained to 0–4; rep minimum must be positive; maximum must be at least minimum.
- Loading cycles are nullable arrays with cardinality 2–52. SQL has no explicit element-null check, while Pydantic expects every submitted entry to be a valid enum value.
- Muscle fiber fractions are each 0–1 and must sum to 1 within 0.001.
- The physical dump does not FK `core.muscle_exercise_mappings.exercise_id` to `core.exercises`, nor `engine.exercises.slug` to `core.exercises.slug`.

## JSONB and array inventory

| Table.column | Shape/evidence |
| --- | --- |
| `core.exercises.technique` | Authored object; observed keys include prose fields plus nested `tldr` (`setup`, `execution`, `focus`, `stop_when`). Not DB-schema validated. |
| `core.exercises.comments` | Arbitrary object; often `{}`. |
| `core.exercises.recommended_rep_profile` | Required object with `high_load`, `moderate_load`, `low_load`; each value is null or `{min,max}`. Pydantic validates responses, DB does not validate shape. |
| `core.exercise_translations.technique/comments` | Nullable locale-specific object overlays. |
| `engine.exercises.*_vector` | Sparse objects keyed by muscle or joint slug with non-negative numeric values expected by code. Only a subset of vector columns have DB object-type checks. |
| `engine.exercises.*_eval_notes` | Authored audit objects, observed as `{slug, notes, ...}` with vector-specific extra fields. Not served by current API. |
| `plans.plan_revisions.snapshot` | Nullable JSONB with no current writer/reader in application code. |
| `*.video_links`, `*.article_links` | PostgreSQL `text[]`; video values are URLs and exercise writes are YouTube-normalized. |
| `plans.*.loading_cycle` | `plans.loading_mode[]`, a repeating per-microcycle pattern. |

## Physical-to-projected drift

```mermaid
flowchart LR
    Dump["2026-09-17 physical dump\nledger: 0001, 0002"]
    M3["0003\nvariant.progression_model_slug\nFK + partial index"]
    M4["0004\nprogression_model.display_order\nNOT NULL + positive + unique"]
    Expected["Schema expected by current code"]

    Dump --> M3 --> M4 --> Expected
```

Without `0003`, plan load/import/save/duplicate SQL referencing `progression_model_slug` fails. Without `0004`, the progression-model catalog query referencing `display_order` fails. The backend Docker command runs migrations before Uvicorn, so a normal container start should close the gap; the checked-in dump proves only that the snapshot itself had not done so.
