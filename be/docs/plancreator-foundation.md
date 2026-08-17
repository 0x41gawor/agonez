# PlanCreator foundation

## Scope

This module persists the editable structural prescription used by the first PlanCreator
tab. It stops at `PlanDraft` persistence:

`Plan → Revision → Day → WorkoutUnit → ExerciseSlot → ExerciseVariant → SetInfraPrescription`

Exercise slots are stable plan roles, not aliases for catalog exercises. Their IDs—and
the IDs of all other editable children—survive reorder and ordinary edits.

Analysis, modulation, release workflow, macrocycles, execution, load tracking,
progression, ETU, recovery, and joint-load evaluation are deliberately deferred.

## Existing-system decisions

- The application uses async Psycopg repositories, Pydantic schemas, services, and
  FastAPI routers. It has no SQLAlchemy or Alembic dependency, so PlanCreator follows
  the same stack.
- Ordered SQL migrations under `agonez_api.migrations.versions` are checksum-tracked
  and applied transactionally under a PostgreSQL advisory lock.
- Existing catalog keys are `integer`; PlanCreator uses integer identity keys too.
- PostgreSQL enums follow the existing `core` convention.
- Weekdays use ISO integers: Monday `1` through Sunday `7`.
- The current application has no authentication or ownership concept. Plans are
  therefore public application data for this iteration. Ownership must be added before
  exposing personal plan/execution features to untrusted users.

## Persistence

The editable draft is relational in the `plans` schema. Nested API documents are
assembled with a constant number of catalog/child queries. Saves lock the DRAFT
revision, validate `lock_version`, resolve exercise/muscle slugs in batches, validate
submitted IDs against the aggregate, reconcile children by ID, and delete only omitted
entities. The transaction increments `lock_version` only after a successful save.

Unique ordinal constraints are deferrable so positions can be swapped without
temporary collisions. A partial unique index permits at most one DEFAULT variant per
slot, and another permits only one DRAFT revision per plan.

## API

- `POST /api/plans`
- `GET /api/plans`
- `GET /api/plans/{plan_id}`
- `DELETE /api/plans/{plan_id}`
- `GET /api/plans/{plan_id}/draft`
- `PUT /api/plans/{plan_id}/draft`

External payloads use exercise and muscle slugs. Relational rows reference catalog IDs.
