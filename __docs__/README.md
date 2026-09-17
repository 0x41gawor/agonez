# Agonez technical documentation

Agonez is a Vue 3 and FastAPI application for browsing an exercise/muscle atlas and authoring relational resistance-training plans. Its distinctive subsystem is a request-time analysis engine: a saved draft is resolved into active exercise sets, combined with muscle and joint exposure vectors from PostgreSQL, and evaluated for ETU-like stimulus and recovery debt. It is currently a prescription and analysis system, not a workout-execution tracker: no athlete, session, performed-set, or progression-runtime persistence exists.

## Evidence baseline

This package was reverse-engineered from the repository on 2026-09-17. Evidence was prioritized in this order:

1. `agonez_db_backup_2026-09-17.sql` for the physical PostgreSQL snapshot;
2. packaged migrations under `be/src/agonez_api/migrations/versions/` for the intended post-migration schema;
3. registered FastAPI routes, Pydantic models, repository SQL, and calculation code;
4. tests, frontend consumers, deployment configuration, and older handoff documents.

The latest dump and current application do not describe exactly the same schema. The difference is called out throughout the database documents and summarized in [Ambiguities](findings/ambiguities.md).

Evidence labels used in these documents:

- **Confirmed** — directly represented by current code, DDL, or tests.
- **Inferred** — strongly suggested by naming, formulas, or examples, but not enforced.
- **Unknown** — the repository does not settle the point.
- **Potentially stale** — present in an older artifact but contradicted by newer evidence.

## Suggested reading order

1. [System overview](architecture/system-overview.md)
2. [Domain map](architecture/domain-map.md)
3. [Conceptual ERD](database/erd-layer-1.md)
4. [Logical ERD](database/erd-layer-2.md)
5. [Endpoint catalog](api/endpoint-catalog.md)
6. [Endpoint flows](api/endpoint-flows.md)
7. [Execution pipeline](flows/execution-pipeline.md)
8. [Physical ERD](database/erd-layer-3.md)
9. [Data dictionary](database/data-dictionary.md)

## Documentation map

### Architecture

- [System overview](architecture/system-overview.md) — system context, runtime components, boundaries, and operational shape.
- [Repository map](architecture/repository-map.md) — significant directories and their responsibilities.
- [Module dependencies](architecture/module-dependencies.md) — backend and frontend dependency direction.
- [Domain map](architecture/domain-map.md) — core concepts and the distinction between persisted and derived models.

### Database

- [Database guide](database/README.md) — source-of-truth rules and quick navigation.
- [Schema overview](database/schema-overview.md) — inventory, row counts, enums, constraints, and version drift.
- [Conceptual ERD](database/erd-layer-1.md) — the smallest useful relationship view.
- [Logical ERD](database/erd-layer-2.md) — important keys and domain-bearing columns.
- [Physical ERD](database/erd-layer-3.md) — exact snapshot columns and projected migration overlay.
- [Schema ownership](database/schema-ownership.md) — responsibilities and cross-schema dependencies.
- [Data dictionary](database/data-dictionary.md) — table-by-table fields, JSON shapes, units, and semantics.

### API

- [API guide](api/README.md) — conventions, localization, media, pagination, and errors.
- [Endpoint catalog](api/endpoint-catalog.md) — every registered application operation plus health/static surfaces.
- [Endpoint flows](api/endpoint-flows.md) — request-to-database sequence diagrams.
- [Generated OpenAPI](api/openapi.yaml) — FastAPI-generated OpenAPI 3.1 contract.
- [Example payloads](api/examples/) — valid request and representative response documents.

### Data and calculations

- [Data lineage](flows/data-lineage.md) — database rows through Python/domain transformations to HTTP and back.
- [Execution pipeline](flows/execution-pipeline.md) — draft resolution, ETU/MRU/JRU calculations, recovery simulation, import, and export.

### Findings

- [Ambiguities](findings/ambiguities.md) — schema drift, ungoverned JSON, missing relationships, and unresolved semantics.
- [Documentation gaps](findings/documentation-gaps.md) — prioritized follow-up work.

## Major components

| Component | Responsibility | Primary evidence |
| --- | --- | --- |
| Vue SPA | Atlas browsing, PlanCreator editor, analysis visualization, import/export UI | `web-fe/src/` |
| FastAPI application | HTTP validation, dependency wiring, error mapping, localization headers, media delivery | `be/src/agonez_api/app.py` |
| Atlas module | Read-heavy exercise/muscle catalog plus video-link append | `be/src/agonez_api/modules/atlas/` |
| Plans module | Relational draft persistence, optimistic locking, duplication, import/export | `be/src/agonez_api/modules/plans/` |
| Analysis module | In-memory resolution and ETU/MRU/JRU/recovery evaluation | `be/src/agonez_api/modules/plans/analysis/` |
| PostgreSQL | Canonical catalog, calculated exercise vectors, relational plans | `agonez_db_backup_2026-09-17.sql` |
| Filesystem media | Exercise/muscle images, galleries, anatomy SVG | `media/` |

## Scope boundaries

**Confirmed present:** catalog browsing, localization overlays, relational plan drafts, loading metadata, progression-model metadata in current code, compact plan import/export, request-time analysis, static media, and PostgreSQL-backed health checks.

**Confirmed absent:** authentication, authorization, user ownership, performed workout/session storage, actual load tracking, automatic progression execution, analysis persistence, and a canonical joint table.

**Important:** all plan data is currently application-global. The source explicitly warns that ownership must be added before plans are treated as private user data.
