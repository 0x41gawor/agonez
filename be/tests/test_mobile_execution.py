from datetime import datetime, timezone
from decimal import Decimal
from pathlib import Path

import pytest
from pydantic import ValidationError

from agonez_api.app import create_app
from agonez_api.core.config import Settings
from agonez_api.modules.execution.errors import ExecutionAPIError
from agonez_api.modules.mobile_execution.repository import MobileExecutionRepository
from agonez_api.modules.mobile_execution.schemas import OperationBatch, StartWorkout
from agonez_api.modules.mobile_execution.service import MobileExecutionService, etag_for


def operation(seq: int, op_id: str) -> dict[str, object]:
    return {
        "op_id": op_id,
        "seq": seq,
        "at": "2026-10-10T17:00:00+02:00",
        "type": "set_workout_comment",
        "data": {"comment": "offline"},
    }


def test_operation_batch_requires_contiguous_sequence() -> None:
    with pytest.raises(ValidationError):
        OperationBatch.model_validate(
            {
                "lease_epoch": 1,
                "base_seq": 4,
                "ops": [operation(6, "10000000-0000-4000-8000-000000000001")],
            }
        )


def test_operation_batch_exposes_discriminated_operation_catalogue() -> None:
    batch = OperationBatch.model_validate(
        {
            "lease_epoch": 2,
            "base_seq": 0,
            "ops": [operation(1, "10000000-0000-4000-8000-000000000001")],
        }
    )
    assert batch.ops[0].type == "set_workout_comment"


def test_conflict_comparison_normalizes_decimal_scale_and_timezones() -> None:
    first = {
        "load_kg": Decimal("38.5"),
        "performed_at": datetime(2026, 10, 10, 17, tzinfo=timezone.utc),
    }
    second = {
        "load_kg": Decimal("38.500"),
        "performed_at": datetime(2026, 10, 10, 19, tzinfo=timezone.utc),
    }
    assert MobileExecutionRepository._states_equal(first, first)
    assert not MobileExecutionRepository._states_equal(first, second)

    same_in_other_offset = {
        "load_kg": Decimal("38.500"),
        "performed_at": datetime.fromisoformat("2026-10-10T19:00:00+02:00"),
    }
    assert MobileExecutionRepository._states_equal(first, same_in_other_offset)


def test_atlas_peek_reuses_anatomy_slug_mapping_and_normalizes_intensity() -> None:
    peek = MobileExecutionService._atlas_peek(
        {
            "exercise": {
                "id": 1,
                "slug": "press",
                "name": "Press",
                "full_name": "Press",
                "body_part": "Upper",
                "target_category": "Chest",
                "mechanics_tier": "Heavy_Compound",
                "resistance_source": "Free_Weight",
                "execution_pattern": "Bilateral",
                "technique": {"tldr": {"setup": "Brace"}},
            },
            "muscles": [
                {
                    "muscle_id": 4,
                    "slug": "deltoid_anterior",
                    "name": "Anterior deltoid",
                    "etu_cm2": Decimal("10"),
                    "capacity_share": Decimal("0.5"),
                },
                {
                    "muscle_id": 2,
                    "slug": "pectoralis_major_sternal",
                    "name": "Pectoralis major",
                    "etu_cm2": Decimal("8"),
                    "capacity_share": Decimal("0.25"),
                },
            ],
        },
        "en",
    )
    assert peek.body_map.asset == "anatomy.svg"
    assert peek.body_map.regions[0].region_id == "anterior_deltoid"
    assert peek.body_map.regions[0].intensity == 1
    assert peek.body_map.regions[1].intensity == 0.5
    assert peek.technique_tldr.setup == "Brace"


def test_mobile_openapi_has_all_routes_headers_and_operation_discriminator(
    tmp_path: Path,
) -> None:
    app = create_app(
        settings=Settings(
            NOME="atlas_user",
            AGANDSKODE="secret",
            MINA=33327,
            MEDIA_ROOT=tmp_path,
        )
    )
    schema = app.openapi()
    paths = schema["paths"]
    expected = {
        "/api/v1/mobile/context",
        "/api/v1/mobile/plan-runs",
        "/api/v1/mobile/sessions/{session_id}/prescription",
        "/api/v1/mobile/workouts",
        "/api/v1/mobile/workouts/active",
        "/api/v1/mobile/workouts/{workout_id}",
        "/api/v1/mobile/workouts/{workout_id}/claim",
        "/api/v1/mobile/workouts/{workout_id}/ops",
        "/api/v1/mobile/workouts/{workout_id}/finalize",
        "/api/v1/mobile/atlas/exercises/{exercise_id}/peek",
        "/api/v1/mobile/atlas/exercises",
    }
    assert expected <= set(paths)
    context_headers = {
        item["name"] for item in paths["/api/v1/mobile/context"]["get"]["parameters"]
    }
    assert {"X-Agonez-Device-Id", "X-Agonez-Client", "Accept-Language"} <= context_headers
    plan_run_schema = paths["/api/v1/mobile/plan-runs"]["get"]["responses"]["200"][
        "content"
    ]["application/json"]["schema"]
    assert plan_run_schema["type"] == "array"

    ops = schema["components"]["schemas"]["OperationBatch"]["properties"]["ops"]
    discriminator = ops["items"]["discriminator"]
    assert discriminator["propertyName"] == "type"
    assert set(discriminator["mapping"]) == {
        "upsert_set",
        "skip_set",
        "clear_set",
        "set_exercise_comment",
        "skip_exercise",
        "substitute_exercise",
        "add_unplanned_exercise",
        "reorder_exercises",
        "set_cursor",
        "set_workout_comment",
    }


def test_etag_ignores_context_generation_time() -> None:
    class Model:
        def __init__(self, generated_at: str) -> None:
            self.generated_at = generated_at

        def model_dump(self, *, mode: str, exclude: set[str]) -> dict[str, object]:
            assert mode == "json"
            assert exclude == {"generated_at"}
            return {"context_version": "ctx-stable"}

    assert etag_for(Model("first")) == etag_for(Model("second"))


@pytest.mark.asyncio
async def test_stale_start_includes_fresh_prescription() -> None:
    class Repository:
        async def start_workout(self, payload: object, *, device_id: object) -> object:
            del payload, device_id
            raise ExecutionAPIError(
                409,
                "prescription_changed",
                "changed",
                {"prescription_version": "rx-new"},
            )

        async def load_prescription(self, session_id: int, *, locale: str) -> dict[str, object]:
            del session_id, locale
            return {
                "session": {
                    "session_id": 9,
                    "prescription_id": 90,
                    "workout_unit_name": "Push A",
                    "workout_track_id": 3,
                    "microcycle_ordinal": 4,
                    "microcycle_classification": "normal",
                    "description_snapshot": None,
                    "workout_prescription_comment": None,
                },
                "exercises": [],
                "sets": [],
                "alternatives": [],
                "previous": [],
                "previous_sets": [],
                "peeks": {},
                "version": "rx-new",
                "locale": "en",
            }

    service = MobileExecutionService(Repository())  # type: ignore[arg-type]
    payload = StartWorkout.model_validate(
        {
            "workout_id": "10000000-0000-4000-8000-000000000001",
            "session_id": 9,
            "prescription_version": "rx-old",
            "started_at": "2026-10-10T17:00:00Z",
        }
    )
    with pytest.raises(ExecutionAPIError) as caught:
        await service.start_workout(
            payload,
            device_id=payload.workout_id,
            locale="en",
        )
    assert caught.value.code == "prescription_changed"
    assert caught.value.details["prescription"]["prescription_version"] == "rx-new"
