from datetime import date
from typing import Any, cast

import pytest

from agonez_api.modules.execution.errors import ExecutionAPIError
from agonez_api.modules.execution.repository import ExecutionRepository, RevisionTree
from agonez_api.modules.execution.schemas import ExercisePrescriptionPut
from agonez_api.modules.execution.service import ExecutionService


def revision_tree() -> RevisionTree:
    return RevisionTree(
        revision={
            "plan_revision_id": 31,
            "plan_id": 6,
            "revision_no": 2,
            "status": "released",
            "plan_name": "PPL",
            "plan_code": "P006",
        },
        days=[
            {"id": 1, "ordinal": 0},
            {"id": 2, "ordinal": 1},
            {"id": 3, "ordinal": 2},
        ],
        workouts=[
            {"id": 10, "day_id": 1, "name": "Push A"},
            {"id": 11, "day_id": 3, "name": "Pull A"},
        ],
        slots=[
            {"id": 20, "workout_unit_id": 10},
            {"id": 21, "workout_unit_id": 10},
            {"id": 22, "workout_unit_id": 11},
        ],
        variants=[],
        sets=[],
    )


def test_projection_is_shared_screen_shape() -> None:
    value = ExecutionService._project(revision_tree(), date(2026, 10, 27), 8)

    assert value["microcycle_duration_days"] == 3
    assert value["ends_on"] == date(2026, 11, 19)
    assert value["session_count"] == 16
    assert value["workout_track_count"] == 2
    assert value["exercise_track_count"] == 3
    assert value["first_microcycle"] == [
        {"day_ordinal": 0, "date": date(2026, 10, 27), "workout_unit_name": "Push A"},
        {"day_ordinal": 1, "date": date(2026, 10, 28), "workout_unit_name": None},
        {"day_ordinal": 2, "date": date(2026, 10, 29), "workout_unit_name": "Pull A"},
    ]


@pytest.mark.asyncio
async def test_preview_rejects_invalid_microcycle_count_before_database_access() -> None:
    service = ExecutionService(cast(Any, None))

    with pytest.raises(ExecutionAPIError) as caught:
        await service.preview_plan_run(
            plan_revision_id=31,
            starts_on=date(2026, 10, 27),
            microcycle_count=0,
        )

    assert caught.value.code == "invalid_microcycle_count"


@pytest.mark.parametrize(
    ("loads", "expected"),
    [
        ([0, 67.5, 1000], []),
        ([-0.01, 67.555, 1000.01], [0, 1, 2]),
    ],
)
def test_load_validation_reports_exact_ordinals(
    loads: list[float],
    expected: list[int],
) -> None:
    payload = ExercisePrescriptionPut.model_validate(
        {
            "based_on_exercise_performance_id": None,
            "sets": [
                {"ordinal": ordinal, "load_kg": load, "comment": None}
                for ordinal, load in enumerate(loads)
            ],
            "prescription_comment": None,
            "expected_version": None,
        }
    )

    assert ExecutionRepository._invalid_load_ordinals(payload) == expected


@pytest.mark.parametrize(
    ("event_type", "exercise_id", "metadata", "code"),
    [
        ("plan_revision_changed", None, {}, "event_type_system_managed"),
        ("personal_record", None, {"load_kg": 75, "repetitions": 9}, "missing_exercise_trace"),
        ("personal_record", 4, {"load_kg": 75}, "missing_exercise_trace"),
    ],
)
def test_user_event_validation(
    event_type: str,
    exercise_id: int | None,
    metadata: dict[str, Any],
    code: str,
) -> None:
    with pytest.raises(ExecutionAPIError) as caught:
        ExecutionRepository._validate_user_event(event_type, exercise_id, metadata)

    assert caught.value.code == code
