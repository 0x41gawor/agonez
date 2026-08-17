from dataclasses import dataclass
from typing import Any, cast

from agonez_api.core.database import DatabasePool
from agonez_api.modules.plans.exceptions import (
    PlanConflictError,
    PlanDomainValidationError,
    PlanDraftNotFoundError,
    PlanNotFoundError,
)
from agonez_api.modules.plans.schemas import PlanCreate, PlanDraftUpdate

Row = dict[str, Any]


@dataclass(frozen=True)
class DraftRows:
    header: Row
    days: list[Row]
    workout_units: list[Row]
    slots: list[Row]
    target_muscles: list[Row]
    variants: list[Row]
    sets: list[Row]


class PlanRepository:
    """Relational persistence and transactional reconciliation for plan drafts."""

    def __init__(self, pool: DatabasePool) -> None:
        self._pool = pool

    async def create_plan(self, payload: PlanCreate) -> DraftRows:
        async with self._pool.connection() as connection:
            async with connection.transaction():
                plan = await self._fetch_one(
                    connection,
                    """
                    INSERT INTO plans.workout_plans (name, description)
                    VALUES (%s, %s)
                    RETURNING id
                    """,
                    (payload.name, payload.description),
                )
                await self._execute(
                    connection,
                    """
                    INSERT INTO plans.plan_revisions (plan_id, revision_no, status)
                    VALUES (%s, 1, 'DRAFT')
                    """,
                    (plan["id"],),
                )
                return await self._load_draft_rows(connection, cast(int, plan["id"]))

    async def list_plans(self) -> list[Row]:
        async with self._pool.connection() as connection:
            return await self._fetch_all(
                connection,
                """
                SELECT
                    p.id,
                    p.name,
                    p.description,
                    p.created_at,
                    p.updated_at,
                    draft.id AS draft_revision_id,
                    draft.lock_version AS draft_lock_version
                FROM plans.workout_plans AS p
                LEFT JOIN plans.plan_revisions AS draft
                    ON draft.plan_id = p.id AND draft.status = 'DRAFT'
                ORDER BY p.updated_at DESC, p.id DESC
                """,
            )

    async def get_plan(self, plan_id: int) -> tuple[Row, list[Row]]:
        async with self._pool.connection() as connection:
            plan = await self._fetch_optional(
                connection,
                """
                SELECT id, name, description, created_at, updated_at
                FROM plans.workout_plans
                WHERE id = %s
                """,
                (plan_id,),
            )
            if plan is None:
                raise PlanNotFoundError(plan_id)
            revisions = await self._fetch_all(
                connection,
                """
                SELECT
                    id,
                    revision_no,
                    status::text AS status,
                    lock_version,
                    based_on_revision_id,
                    created_at,
                    updated_at,
                    released_at
                FROM plans.plan_revisions
                WHERE plan_id = %s
                ORDER BY revision_no DESC
                """,
                (plan_id,),
            )
            return plan, revisions

    async def delete_plan(self, plan_id: int) -> None:
        async with self._pool.connection() as connection:
            row = await self._fetch_optional(
                connection,
                """
                DELETE FROM plans.workout_plans
                WHERE id = %s
                RETURNING id
                """,
                (plan_id,),
            )
            if row is None:
                raise PlanNotFoundError(plan_id)

    async def get_draft(self, plan_id: int) -> DraftRows:
        async with self._pool.connection() as connection:
            plan_exists = await self._fetch_optional(
                connection,
                "SELECT id FROM plans.workout_plans WHERE id = %s",
                (plan_id,),
            )
            if plan_exists is None:
                raise PlanNotFoundError(plan_id)
            return await self._load_draft_rows(connection, plan_id)

    async def save_draft(self, plan_id: int, payload: PlanDraftUpdate) -> DraftRows:
        async with self._pool.connection() as connection:
            async with connection.transaction():
                await self._execute(connection, "SET CONSTRAINTS ALL DEFERRED")
                plan = await self._fetch_optional(
                    connection,
                    "SELECT id FROM plans.workout_plans WHERE id = %s FOR UPDATE",
                    (plan_id,),
                )
                if plan is None:
                    raise PlanNotFoundError(plan_id)

                revision = await self._fetch_optional(
                    connection,
                    """
                    SELECT id, revision_no, lock_version
                    FROM plans.plan_revisions
                    WHERE plan_id = %s AND status = 'DRAFT'
                    FOR UPDATE
                    """,
                    (plan_id,),
                )
                if revision is None:
                    raise PlanDraftNotFoundError(plan_id)
                self._validate_draft_identity(plan_id, payload, revision)
                current_version = cast(int, revision["lock_version"])
                if payload.lock_version != current_version:
                    raise PlanConflictError(
                        submitted_lock_version=payload.lock_version,
                        current_lock_version=current_version,
                    )

                existing = await self._load_draft_rows(connection, plan_id)
                submitted_ids = self._validate_nested_ids(payload, existing)
                exercise_ids = await self._resolve_catalog_slugs(
                    connection,
                    table="core.exercises",
                    slugs={
                        variant.exercise_slug
                        for day in payload.days
                        if day.workout_unit is not None
                        for slot in day.workout_unit.exercise_slots
                        for variant in slot.variants
                    },
                    entity_label="exercise",
                )
                muscle_ids = await self._resolve_catalog_slugs(
                    connection,
                    table="core.muscles",
                    slugs={
                        slug
                        for day in payload.days
                        if day.workout_unit is not None
                        for slot in day.workout_unit.exercise_slots
                        for slug in slot.target_muscle_slugs
                    },
                    entity_label="muscle",
                )

                await self._execute(
                    connection,
                    """
                    UPDATE plans.workout_plans
                    SET name = %s, description = %s, updated_at = now()
                    WHERE id = %s
                    """,
                    (payload.name, payload.description, plan_id),
                )

                existing_variant_ids = [row["id"] for row in existing.variants]
                if existing_variant_ids:
                    await self._execute(
                        connection,
                        """
                        UPDATE plans.exercise_variants
                        SET variant_type = 'FALLBACK'
                        WHERE id = ANY(%s)
                        """,
                        (existing_variant_ids,),
                    )

                revision_id = cast(int, revision["id"])
                for day in payload.days:
                    day_id = await self._upsert_day(connection, revision_id, day)
                    if day.workout_unit is None:
                        continue
                    unit_id = await self._upsert_workout_unit(
                        connection, day_id, day.workout_unit
                    )
                    for slot in day.workout_unit.exercise_slots:
                        slot_id = await self._upsert_slot(connection, unit_id, slot)
                        await self._replace_target_muscles(
                            connection,
                            slot_id,
                            [muscle_ids[slug] for slug in slot.target_muscle_slugs],
                        )
                        for variant in slot.variants:
                            variant_id = await self._upsert_variant(
                                connection,
                                slot_id,
                                exercise_ids[variant.exercise_slug],
                                variant,
                            )
                            for set_prescription in variant.sets:
                                await self._upsert_set(
                                    connection,
                                    variant_id,
                                    set_prescription,
                                )

                # Delete only after retained children have been updated/reparented. This
                # prevents an omitted old parent from cascading a submitted stable ID.
                await self._delete_omitted(connection, existing, submitted_ids)
                await self._execute(
                    connection,
                    """
                    UPDATE plans.plan_revisions
                    SET lock_version = lock_version + 1, updated_at = now()
                    WHERE id = %s
                    """,
                    (revision_id,),
                )
                return await self._load_draft_rows(connection, plan_id)

    @staticmethod
    def _validate_draft_identity(plan_id: int, payload: PlanDraftUpdate, revision: Row) -> None:
        if payload.id != plan_id:
            raise PlanDomainValidationError(
                f"Payload plan id {payload.id} does not match route plan id {plan_id}"
            )
        if payload.revision_id != revision["id"]:
            raise PlanDomainValidationError("Payload revision_id is not this plan's draft revision")
        if payload.revision_no != revision["revision_no"]:
            raise PlanDomainValidationError("Payload revision_no is not this plan's draft revision")

    @staticmethod
    def _validate_nested_ids(
        payload: PlanDraftUpdate,
        existing: DraftRows,
    ) -> dict[str, set[int]]:
        existing_ids = {
            "days": {cast(int, row["id"]) for row in existing.days},
            "workout_units": {cast(int, row["id"]) for row in existing.workout_units},
            "slots": {cast(int, row["id"]) for row in existing.slots},
            "variants": {cast(int, row["id"]) for row in existing.variants},
            "sets": {cast(int, row["id"]) for row in existing.sets},
        }
        submitted: dict[str, list[int]] = {
            "days": [],
            "workout_units": [],
            "slots": [],
            "variants": [],
            "sets": [],
        }
        for day in payload.days:
            if day.id is not None:
                submitted["days"].append(day.id)
            if day.workout_unit is None:
                continue
            if day.workout_unit.id is not None:
                submitted["workout_units"].append(day.workout_unit.id)
            for slot in day.workout_unit.exercise_slots:
                if slot.id is not None:
                    submitted["slots"].append(slot.id)
                for variant in slot.variants:
                    if variant.id is not None:
                        submitted["variants"].append(variant.id)
                    for set_prescription in variant.sets:
                        if set_prescription.id is not None:
                            submitted["sets"].append(set_prescription.id)

        result: dict[str, set[int]] = {}
        labels = {
            "days": "day",
            "workout_units": "workout unit",
            "slots": "exercise slot",
            "variants": "exercise variant",
            "sets": "set prescription",
        }
        for key, values in submitted.items():
            if len(values) != len(set(values)):
                raise PlanDomainValidationError(f"Duplicate {labels[key]} id in submitted draft")
            foreign_ids = set(values) - existing_ids[key]
            if foreign_ids:
                value = min(foreign_ids)
                raise PlanDomainValidationError(
                    f"{labels[key].capitalize()} id {value} does not belong to this draft"
                )
            result[key] = set(values)
        return result

    async def _resolve_catalog_slugs(
        self,
        connection: Any,
        *,
        table: str,
        slugs: set[str],
        entity_label: str,
    ) -> dict[str, int]:
        if not slugs:
            return {}
        rows = await self._fetch_all(
            connection,
            f"SELECT id, slug FROM {table} WHERE slug = ANY(%s)",
            (list(slugs),),
        )
        resolved = {cast(str, row["slug"]): cast(int, row["id"]) for row in rows}
        missing = sorted(slugs - resolved.keys())
        if missing:
            raise PlanDomainValidationError(
                f"Unknown {entity_label} slug{'s' if len(missing) > 1 else ''}: "
                + ", ".join(missing)
            )
        return resolved

    async def _delete_omitted(
        self,
        connection: Any,
        existing: DraftRows,
        submitted_ids: dict[str, set[int]],
    ) -> None:
        tables_and_rows = (
            ("plans.set_infra_prescriptions", "sets", existing.sets),
            ("plans.exercise_variants", "variants", existing.variants),
            ("plans.exercise_slots", "slots", existing.slots),
            ("plans.workout_unit_prescriptions", "workout_units", existing.workout_units),
            ("plans.day_prescriptions", "days", existing.days),
        )
        for table, key, rows in tables_and_rows:
            omitted = [row["id"] for row in rows if row["id"] not in submitted_ids[key]]
            if omitted:
                await self._execute(
                    connection,
                    f"DELETE FROM {table} WHERE id = ANY(%s)",
                    (omitted,),
                )

    async def _upsert_day(self, connection: Any, revision_id: int, day: Any) -> int:
        if day.id is None:
            row = await self._fetch_one(
                connection,
                """
                INSERT INTO plans.day_prescriptions
                    (revision_id, ordinal, weekday, name, description)
                VALUES (%s, %s, %s, %s, %s)
                RETURNING id
                """,
                (revision_id, day.ordinal, day.weekday, day.name, day.description),
            )
            return cast(int, row["id"])
        await self._execute(
            connection,
            """
            UPDATE plans.day_prescriptions
            SET revision_id = %s, ordinal = %s, weekday = %s, name = %s, description = %s
            WHERE id = %s
            """,
            (revision_id, day.ordinal, day.weekday, day.name, day.description, day.id),
        )
        return cast(int, day.id)

    async def _upsert_workout_unit(self, connection: Any, day_id: int, unit: Any) -> int:
        values = (day_id, unit.name, unit.description, unit.warmup_notes, unit.stretch_notes)
        if unit.id is None:
            row = await self._fetch_one(
                connection,
                """
                INSERT INTO plans.workout_unit_prescriptions
                    (day_id, name, description, warmup_notes, stretch_notes)
                VALUES (%s, %s, %s, %s, %s)
                RETURNING id
                """,
                values,
            )
            return cast(int, row["id"])
        await self._execute(
            connection,
            """
            UPDATE plans.workout_unit_prescriptions
            SET day_id = %s, name = %s, description = %s,
                warmup_notes = %s, stretch_notes = %s
            WHERE id = %s
            """,
            (*values, unit.id),
        )
        return cast(int, unit.id)

    async def _upsert_slot(self, connection: Any, unit_id: int, slot: Any) -> int:
        values = (
            unit_id,
            slot.ordinal,
            slot.name,
            slot.description,
            slot.goal,
            slot.role.value,
            slot.volume_axis,
        )
        if slot.id is None:
            row = await self._fetch_one(
                connection,
                """
                INSERT INTO plans.exercise_slots
                    (workout_unit_id, ordinal, name, description, goal, role, volume_axis)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                RETURNING id
                """,
                values,
            )
            return cast(int, row["id"])
        await self._execute(
            connection,
            """
            UPDATE plans.exercise_slots
            SET workout_unit_id = %s, ordinal = %s, name = %s, description = %s,
                goal = %s, role = %s, volume_axis = %s
            WHERE id = %s
            """,
            (*values, slot.id),
        )
        return cast(int, slot.id)

    async def _replace_target_muscles(
        self,
        connection: Any,
        slot_id: int,
        muscle_ids: list[int],
    ) -> None:
        if muscle_ids:
            await self._execute(
                connection,
                """
                DELETE FROM plans.exercise_slot_target_muscles
                WHERE slot_id = %s AND NOT (muscle_id = ANY(%s))
                """,
                (slot_id, muscle_ids),
            )
            for muscle_id in muscle_ids:
                await self._execute(
                    connection,
                    """
                    INSERT INTO plans.exercise_slot_target_muscles (slot_id, muscle_id)
                    VALUES (%s, %s)
                    ON CONFLICT DO NOTHING
                    """,
                    (slot_id, muscle_id),
                )
            return
        await self._execute(
            connection,
            "DELETE FROM plans.exercise_slot_target_muscles WHERE slot_id = %s",
            (slot_id,),
        )

    async def _upsert_variant(
        self,
        connection: Any,
        slot_id: int,
        exercise_id: int,
        variant: Any,
    ) -> int:
        values = (slot_id, variant.ordinal, variant.variant_type.value, exercise_id)
        if variant.id is None:
            row = await self._fetch_one(
                connection,
                """
                INSERT INTO plans.exercise_variants
                    (slot_id, ordinal, variant_type, exercise_id)
                VALUES (%s, %s, %s, %s)
                RETURNING id
                """,
                values,
            )
            return cast(int, row["id"])
        await self._execute(
            connection,
            """
            UPDATE plans.exercise_variants
            SET slot_id = %s, ordinal = %s, variant_type = %s, exercise_id = %s
            WHERE id = %s
            """,
            (*values, variant.id),
        )
        return cast(int, variant.id)

    async def _upsert_set(self, connection: Any, variant_id: int, item: Any) -> int:
        values = (
            variant_id,
            item.ordinal,
            item.reps.min,
            item.reps.max,
            item.rir,
            item.min_volume_level,
        )
        if item.id is None:
            row = await self._fetch_one(
                connection,
                """
                INSERT INTO plans.set_infra_prescriptions
                    (exercise_variant_id, ordinal, rep_min, rep_max, rir, min_volume_level)
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING id
                """,
                values,
            )
            return cast(int, row["id"])
        await self._execute(
            connection,
            """
            UPDATE plans.set_infra_prescriptions
            SET exercise_variant_id = %s, ordinal = %s, rep_min = %s, rep_max = %s,
                rir = %s, min_volume_level = %s
            WHERE id = %s
            """,
            (*values, item.id),
        )
        return cast(int, item.id)

    async def _load_draft_rows(self, connection: Any, plan_id: int) -> DraftRows:
        header = await self._fetch_optional(
            connection,
            """
            SELECT
                p.id,
                p.name,
                p.description,
                revision.id AS revision_id,
                revision.revision_no,
                revision.lock_version
            FROM plans.workout_plans AS p
            JOIN plans.plan_revisions AS revision
                ON revision.plan_id = p.id AND revision.status = 'DRAFT'
            WHERE p.id = %s
            """,
            (plan_id,),
        )
        if header is None:
            raise PlanDraftNotFoundError(plan_id)
        revision_id = header["revision_id"]
        days = await self._fetch_all(
            connection,
            """
            SELECT id, revision_id, ordinal, weekday, name, description
            FROM plans.day_prescriptions
            WHERE revision_id = %s
            ORDER BY ordinal, id
            """,
            (revision_id,),
        )
        workout_units = await self._fetch_all(
            connection,
            """
            SELECT unit.id, unit.day_id, unit.name, unit.description,
                   unit.warmup_notes, unit.stretch_notes
            FROM plans.workout_unit_prescriptions AS unit
            JOIN plans.day_prescriptions AS day ON day.id = unit.day_id
            WHERE day.revision_id = %s
            ORDER BY day.ordinal, unit.id
            """,
            (revision_id,),
        )
        slots = await self._fetch_all(
            connection,
            """
            SELECT slot.id, slot.workout_unit_id, slot.ordinal, slot.name,
                   slot.description, slot.goal, slot.role::text AS role, slot.volume_axis
            FROM plans.exercise_slots AS slot
            JOIN plans.workout_unit_prescriptions AS unit ON unit.id = slot.workout_unit_id
            JOIN plans.day_prescriptions AS day ON day.id = unit.day_id
            WHERE day.revision_id = %s
            ORDER BY day.ordinal, slot.ordinal, slot.id
            """,
            (revision_id,),
        )
        target_muscles = await self._fetch_all(
            connection,
            """
            SELECT target.slot_id, muscle.slug
            FROM plans.exercise_slot_target_muscles AS target
            JOIN core.muscles AS muscle ON muscle.id = target.muscle_id
            JOIN plans.exercise_slots AS slot ON slot.id = target.slot_id
            JOIN plans.workout_unit_prescriptions AS unit ON unit.id = slot.workout_unit_id
            JOIN plans.day_prescriptions AS day ON day.id = unit.day_id
            WHERE day.revision_id = %s
            ORDER BY target.slot_id, muscle.slug
            """,
            (revision_id,),
        )
        variants = await self._fetch_all(
            connection,
            """
            SELECT variant.id, variant.slot_id, variant.ordinal,
                   variant.variant_type::text AS variant_type, exercise.slug AS exercise_slug
            FROM plans.exercise_variants AS variant
            JOIN core.exercises AS exercise ON exercise.id = variant.exercise_id
            JOIN plans.exercise_slots AS slot ON slot.id = variant.slot_id
            JOIN plans.workout_unit_prescriptions AS unit ON unit.id = slot.workout_unit_id
            JOIN plans.day_prescriptions AS day ON day.id = unit.day_id
            WHERE day.revision_id = %s
            ORDER BY variant.slot_id, variant.ordinal, variant.id
            """,
            (revision_id,),
        )
        sets = await self._fetch_all(
            connection,
            """
            SELECT item.id, item.exercise_variant_id, item.ordinal,
                   item.rep_min, item.rep_max, item.rir, item.min_volume_level
            FROM plans.set_infra_prescriptions AS item
            JOIN plans.exercise_variants AS variant ON variant.id = item.exercise_variant_id
            JOIN plans.exercise_slots AS slot ON slot.id = variant.slot_id
            JOIN plans.workout_unit_prescriptions AS unit ON unit.id = slot.workout_unit_id
            JOIN plans.day_prescriptions AS day ON day.id = unit.day_id
            WHERE day.revision_id = %s
            ORDER BY item.exercise_variant_id, item.ordinal, item.id
            """,
            (revision_id,),
        )
        return DraftRows(header, days, workout_units, slots, target_muscles, variants, sets)

    @staticmethod
    async def _execute(
        connection: Any,
        query: str,
        params: tuple[Any, ...] | None = None,
    ) -> None:
        async with connection.cursor() as cursor:
            await cursor.execute(query, params)

    @staticmethod
    async def _fetch_all(
        connection: Any,
        query: str,
        params: tuple[Any, ...] | None = None,
    ) -> list[Row]:
        async with connection.cursor() as cursor:
            await cursor.execute(query, params)
            return list(await cursor.fetchall())

    @classmethod
    async def _fetch_one(
        cls,
        connection: Any,
        query: str,
        params: tuple[Any, ...] | None = None,
    ) -> Row:
        row = await cls._fetch_optional(connection, query, params)
        if row is None:
            raise RuntimeError("Database query unexpectedly returned no rows")
        return row

    @staticmethod
    async def _fetch_optional(
        connection: Any,
        query: str,
        params: tuple[Any, ...] | None = None,
    ) -> Row | None:
        async with connection.cursor() as cursor:
            await cursor.execute(query, params)
            return cast(Row | None, await cursor.fetchone())
