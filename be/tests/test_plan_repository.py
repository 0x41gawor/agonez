from typing import Any, cast

import pytest

from agonez_api.modules.plans.repository import DraftRows, PlanRepository
from agonez_api.modules.plans.schemas import PlanDraftUpdate


@pytest.mark.asyncio
async def test_new_nested_draft_records_receive_fresh_database_ids() -> None:
    payload = PlanDraftUpdate.model_validate(
        {
            "id": 1,
            "revision_id": 2,
            "revision_no": 1,
            "lock_version": 1,
            "name": "Duplicated-day plan",
            "description": None,
            "days": [
                {
                    "id": None,
                    "ordinal": 0,
                    "weekday": 1,
                    "name": "Push A copy",
                    "description": None,
                    "workout_unit": {
                        "id": None,
                        "name": "Push A copy",
                        "description": None,
                        "warmup_notes": None,
                        "stretch_notes": None,
                        "exercise_slots": [
                            {
                                "id": None,
                                "ordinal": 0,
                                "name": "Chest press",
                                "description": None,
                                "goal": "Progressive chest stimulus",
                                "role": "PRIMARY_PROGRESSIVE",
                                "volume_axis": None,
                                "target_muscle_slugs": [],
                                "variants": [
                                    {
                                        "id": None,
                                        "ordinal": 0,
                                        "variant_type": "DEFAULT",
                                        "exercise_slug": "barbell_bench_press",
                                        "sets": [
                                            {
                                                "id": None,
                                                "ordinal": 0,
                                                "reps": {"min": 5, "max": 7},
                                                "rir": 2,
                                                "min_volume_level": 0,
                                            }
                                        ],
                                    }
                                ],
                            }
                        ],
                    },
                }
            ],
        }
    )
    day = payload.days[0]
    unit = cast(Any, day.workout_unit)
    slot = unit.exercise_slots[0]
    variant = slot.variants[0]
    set_prescription = variant.sets[0]
    repository = PlanRepository(cast(Any, None))
    returned_ids = iter((101, 102, 103, 104, 105))
    insert_queries: list[str] = []

    async def fetch_one(
        connection: Any,
        query: str,
        params: tuple[Any, ...] | None = None,
    ) -> dict[str, int]:
        del connection, params
        insert_queries.append(query)
        return {"id": next(returned_ids)}

    repository._fetch_one = fetch_one  # type: ignore[method-assign]
    connection = object()

    day_id = await repository._upsert_day(connection, payload.revision_id, day)
    unit_id = await repository._upsert_workout_unit(connection, day_id, unit)
    slot_id = await repository._upsert_slot(connection, unit_id, slot)
    variant_id = await repository._upsert_variant(connection, slot_id, 99, variant)
    set_id = await repository._upsert_set(connection, variant_id, set_prescription)

    assert [day_id, unit_id, slot_id, variant_id, set_id] == [101, 102, 103, 104, 105]
    assert [
        "INSERT INTO plans.day_prescriptions",
        "INSERT INTO plans.workout_unit_prescriptions",
        "INSERT INTO plans.exercise_slots",
        "INSERT INTO plans.exercise_variants",
        "INSERT INTO plans.set_infra_prescriptions",
    ] == [
        next(line.strip() for line in query.splitlines() if "INSERT INTO" in line)
        for query in insert_queries
    ]


def test_duplicate_plan_name_is_stable_unique_and_length_safe() -> None:
    existing = ["Power", "Power copy", "POWER COPY 2"]

    assert PlanRepository._duplicate_plan_name("Power copy", existing) == "Power copy 3"
    assert len(PlanRepository._duplicate_plan_name("X" * 200, [])) == 200


@pytest.mark.asyncio
async def test_copy_draft_tree_remaps_every_parent_and_catalog_reference() -> None:
    source = DraftRows(
        header={"revision_id": 2},
        days=[
            {
                "id": 10,
                "ordinal": 0,
                "weekday": 1,
                "name": "Push A",
                "description": "Primary session",
            }
        ],
        workout_units=[
            {
                "id": 20,
                "day_id": 10,
                "name": "Push A",
                "description": None,
                "warmup_notes": "Warm up",
                "stretch_notes": None,
            }
        ],
        slots=[
            {
                "id": 30,
                "workout_unit_id": 20,
                "ordinal": 0,
                "name": "Primary press",
                "description": None,
                "goal": "Progress",
                "role": "PRIMARY_PROGRESSIVE",
                "volume_axis": None,
            }
        ],
        target_muscles=[
            {"slot_id": 30, "muscle_id": 40, "slug": "pectoralis_major_sternal"}
        ],
        variants=[
            {
                "id": 50,
                "slot_id": 30,
                "ordinal": 0,
                "variant_type": "DEFAULT",
                "exercise_id": 60,
                "exercise_slug": "barbell_bench_press",
            }
        ],
        sets=[
            {
                "id": 70,
                "exercise_variant_id": 50,
                "ordinal": 0,
                "rep_min": 5,
                "rep_max": 7,
                "rir": 2,
                "min_volume_level": 0,
            }
        ],
    )
    repository = PlanRepository(cast(Any, None))
    returned_ids = iter((101, 102, 103, 104, 105))
    inserts: list[tuple[str, tuple[Any, ...] | None]] = []
    statements: list[tuple[str, tuple[Any, ...] | None]] = []

    async def fetch_one(
        connection: Any,
        query: str,
        params: tuple[Any, ...] | None = None,
    ) -> dict[str, int]:
        del connection
        inserts.append((query, params))
        return {"id": next(returned_ids)}

    async def execute(
        connection: Any,
        query: str,
        params: tuple[Any, ...] | None = None,
    ) -> None:
        del connection
        statements.append((query, params))

    repository._fetch_one = fetch_one  # type: ignore[method-assign]
    repository._execute = execute  # type: ignore[method-assign]

    await repository._copy_draft_tree(object(), source, new_revision_id=99)

    assert [params for _, params in inserts] == [
        (99, 0, 1, "Push A", "Primary session"),
        (101, "Push A", None, "Warm up", None),
        (102, 0, "Primary press", None, "Progress", "PRIMARY_PROGRESSIVE", None),
        (103, 0, "DEFAULT", 60),
        (104, 0, 5, 7, 2, 0),
    ]
    assert len(statements) == 1
    assert "INSERT INTO plans.exercise_slot_target_muscles" in statements[0][0]
    assert statements[0][1] == (103, 40)
