# Ambiguities and evidence conflicts

## High-impact findings

### Physical dump is behind current application SQL

**Confirmed:** `agonez_db_backup_2026-09-17.sql` records only migrations `0001` and `0002`.

**Confirmed:** current repository SQL reads/writes `plans.exercise_variants.progression_model_slug` and orders by `core.progression_models.display_order`.

**Confirmed:** those columns are absent from the dump and are introduced by packaged migrations `0003` and `0004`.

**Impact:** the progression catalog and multiple plan operations fail until startup migrations run. The normal backend Docker command does run them, but restores or direct Python deployments must do so explicitly.

### Progression catalog creation is outside packaged migrations

**Confirmed:** the dump contains `core.progression_models` and `core.progression_model_translations`, but no packaged migration creates them.

**Unknown:** which authoritative provisioning process creates and seeds these tables for a fresh database.

**Impact:** applying `0001`–`0004` to an older catalog database without these tables makes `0003`/`0004` fail.

### Analysis documentation and code have diverged

**Potentially stale:** `be/docs/plancreator-analysis-v1.md` describes `plan-analysis-v1`, weekday/fixed-168-hour timing, and velocities `0.289425511` / `0.312`.

**Confirmed current code:** emits `plan-analysis-v2`, uses ordinal timing and `len(days) * 24` hours, and uses velocities `0.70` / `1.05`. The parameter variable names still end in `_V1`, and the muscle constant line retains `# 0.289425511` as a comment.

**Unknown:** the calibration/change rationale for the v2 constants and variable-length microcycle.

### Authentication and ownership are absent

**Confirmed:** no identity middleware, owner column, tenant filter, or authorization check exists.

**Impact:** every plan and the shared exercise video list are mutable by every caller with network access.

## Database ambiguities

### Missing relational integrity

- `core.muscle_exercise_mappings.exercise_id` has no FK to `core.exercises.id`; only its muscle FK exists.
- `engine.exercises.slug` has no FK to `core.exercises.slug`.
- Muscle and joint keys inside JSON vectors have no FK/schema validation.
- There is no canonical joint catalog even though joint slugs appear in API analysis and anatomy SVG behavior.

These may be intentional loose coupling, but no ownership document in source settles that choice.

### Empty and unused mapping table

**Confirmed:** `core.muscle_exercise_mappings` has zero rows in the newest dump and is not queried by current application code.

**Unknown:** whether it is reserved, obsolete, or awaiting provisioning.

### JSONB schemas are only partially governed

- Database checks enforce object type for only some engine JSON columns.
- Technique/comments/eval-note structures have no SQL schema and use generic `dict[str, Any]` where exposed.
- `recommended_rep_profile` has a DB default but no DB shape/range check; Pydantic validates values only when read through the API.
- `plan_revisions.snapshot` has no producer, consumer, or documented shape.

### Units and model semantics

- `_kg`, `_g`, `_cm3`, `_cm2`, and `_deg` names are explicit, but `systemic_propulsive_fcsa_demand` and several engine vectors have no formal formula/schema in current source.
- ETU, MRU, JRU, joint-load exposure, and `smh_factor` are engineering model quantities, not established physical units. Their calibration/governance is not encoded in the database.
- `load_capacity_kg` can represent effective unsupported body-segment mass for bodyweight exercises according to eval notes, so it is not always an externally loaded implement weight.

### Enum quality

`core.muscle_architecture_enum` contains apparent spelling/capitalization duplicates such as `Multipenate`/`Multipennate`, `Broad Tranverse`/`Broad Transverse`, and multiple “parallel/convergent” variants. These are physical enum values and cannot be normalized silently.

### Translation constraints differ

- Progression translation locales are constrained to the nine non-English supported locales.
- Exercise/muscle translation locale strings are unconstrained `varchar(35)`.
- Exercise translation publication status is unconstrained text; only exact `published` is served.
- Older backend README/API docs list five locales, while current code/frontend support ten.

## Domain and pipeline ambiguities

### Revision lifecycle is structural only

The enum permits DRAFT → RELEASED → ARCHIVED and columns support release timestamps/snapshots, but no service or route performs these transitions. The actual transition rules are unknown.

### `based_on_revision_id` crosses aggregate roots on duplicate

Duplication points the new plan's first revision at the source plan's revision. This records ancestry, but whether revision ancestry is intended to cross plans is undocumented.

### Loading metadata is not resolved by analysis/export

Loading modes and cycles are persisted and used by the editor to initialize reps. `resolve_plan()` ignores them, and compact export emits only concrete reps/RIR. The intended future modulation semantics are described informally but not implemented.

### `focus_area` is a no-op

`PlanResolutionContext.focus_area` is accepted, validated, stored in the resolved context, echoed, imported, and exported. It is not used to select sets or change calculations.

### Rep range does not enter analysis equations

The resolver preserves `rep_min`/`rep_max`, but current ETU/MRU/JRU use a fixed effective-reps lookup based solely on RIR. It is unclear whether this is the final interpretation or a deliberate v2 approximation.

### Timing schema admits unused values

`TimingAssumption.timing_source` permits `MICROCYCLE_ORDINAL`, `WEEKDAY`, and `ORDINAL_ASSUMPTION`. Current resolver emits only `MICROCYCLE_ORDINAL`; weekday inconsistencies create diagnostics but never change timing.

### Progression models are descriptions, not executable policies

The catalog has prose only. Selecting a model does not change plan sets, analysis, import behavior beyond metadata, or future loads. The much richer `json-scheme.json` progression policy design is not connected to runtime code.

### Fallback progression inheritance has a reproducible test mismatch

**Confirmed source intent:** `ExerciseSlotEditor.addFallback()` passes the DEFAULT variant's progression slug into the new FALLBACK variant.

**Confirmed verification result:** the focused frontend test `keeps progression guidance compact and lets a new fallback inherit it once` reproducibly observes no newly added fallback and fails (`undefined` rather than the expected slug). Type checking passes, and this documentation task did not alter the behavior.

**Unknown:** whether the mismatch is in the component interaction/test selector or in user-visible fallback creation behavior.

### Compact import trusts only progression slug

V2 accepts optional client-supplied name/guidance fields inside `progression_model`, but persistence validates and stores only the slug. The supplied prose is ignored rather than compared with the server catalog.

### Joint identifiers have multiple owners

Joint slugs originate in engine JSON and are displayed through frontend mappings/anatomy groups. No database table or shared enum establishes canonical naming or descriptions.

## Operational ambiguities

- `run_db.sh` validates `PATTAN` but publishes `$MINA`, and expects a root `init.sql` regular file; the current workspace has an untracked directory named `init.sql`. It appears legacy and is not used by Compose.
- The backend package is named `agonez-atlas-api`, but it now includes PlanCreator and analysis. Naming does not reflect current scope.
- The API's generated OpenAPI omits custom global exception response shapes and hidden health routes.
- The frontend DTOs are manually maintained rather than generated from OpenAPI, so schema drift is detected mainly by tests/type errors, not contract generation.
