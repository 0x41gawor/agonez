# Database documentation

The database has three application schemas and one migration-ledger table:

- `core` — canonical exercises, muscles, progression models, and translations;
- `engine` — calculated exercise biomechanics/exposure vectors;
- `plans` — editable relational plan prescriptions;
- `public.agonez_schema_migrations` — backend migration history.

## Which schema state is documented?

The exact physical baseline is the checked-in plain-text PostgreSQL 15 dump `agonez_db_backup_2026-09-17.sql` (created 2026-09-17 08:48 UTC at the filesystem level). The dump contains migration-ledger entries only for `0001_plancreator_foundation.sql` and `0002_loading_prescriptions.sql`.

Current application code also requires the packaged but absent-from-dump migrations:

- `0003_progression_models.sql` adds `plans.exercise_variants.progression_model_slug` and its FK/index.
- `0004_progression_model_display_order.sql` adds constrained `core.progression_models.display_order`.

Documents use **physical snapshot** for exact dump state and **projected application schema** for snapshot plus those two migrations. Never assume `0003`/`0004` are present merely because they exist in source; verify the target database migration ledger.

## Reading paths

- Start at [Schema overview](schema-overview.md).
- Read [ERD layer 1](erd-layer-1.md) for concepts.
- Read [ERD layer 2](erd-layer-2.md) for logical keys and business fields.
- Use [ERD layer 3](erd-layer-3.md) and the [Data dictionary](data-dictionary.md) as physical references.
- Read [Schema ownership](schema-ownership.md) before adding cross-schema dependencies.
- Review [Ambiguities](../findings/ambiguities.md) before changing DDL or JSON structures.

## Evidence notes

The dump contains data as well as DDL. Its observed row counts are recorded only to describe the inspected snapshot; they are not system limits. No credentials or connection strings are reproduced in this documentation.
