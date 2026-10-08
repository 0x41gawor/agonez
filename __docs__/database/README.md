# Database documentation

The database has four application schemas and one migration-ledger table:

- `core` — canonical exercises, muscles, progression models, and translations;
- `engine` — calculated exercise biomechanics/exposure vectors;
- `plans` — editable relational plan prescriptions;
- `exec` — plan-run calendar execution, prescription snapshots, and performed field data;
- `public.agonez_schema_migrations` — backend migration history.

## Which schema state is documented?

The exact physical baseline is the checked-in plain-text PostgreSQL 15 dump `agonez_db_backup_2026-09-23.sql`. The dump contains migration-ledger entries through `0004_progression_model_display_order.sql`.

The projected application schema additionally applies the packaged migrations absent from that dump:

- `0005_prescription_metadata.sql` adds progression identity, set roles, load metadata, richer RIR, and active-set bounds to `plans`.
- `0006_execution_domain.sql` creates the database-only `exec` domain and its read views.

Documents use **physical snapshot** for exact dump state and **projected application schema** for the snapshot plus pending packaged migrations. Verify the target database migration ledger rather than assuming source files were applied.

## Reading paths

- Start at [Schema overview](schema-overview.md).
- Read [ERD layer 1](erd-layer-1.md) for concepts.
- Read [ERD layer 2](erd-layer-2.md) for logical keys and business fields.
- Use [ERD layer 3](erd-layer-3.md) and the [Data dictionary](data-dictionary.md) as physical references.
- Read [Schema ownership](schema-ownership.md) before adding cross-schema dependencies.
- Read the [Execution overview](../execution/README.md), [ERDs](../execution/erd.md), and [table catalogue](../execution/table-catalogue.md) for migration `0006`.
- Review [Ambiguities](../findings/ambiguities.md) before changing DDL or JSON structures.

## Evidence notes

The dump contains data as well as DDL. Its observed row counts are recorded only to describe the inspected snapshot; they are not system limits. No credentials or connection strings are reproduced in this documentation.
