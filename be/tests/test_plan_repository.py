from typing import Any, cast

import pytest

from agonez_api.modules.plans.repository import PlanRepository
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
