from datetime import datetime, timezone
from decimal import Decimal
from pathlib import Path
from types import SimpleNamespace

import pytest
from pydantic import ValidationError

from agonez_api.app import create_app
from agonez_api.core.config import Settings
from agonez_api.modules.execution.errors import ExecutionAPIError
from agonez_api.modules.execution.service import ExecutionService
from agonez_api.modules.mobile_execution.repository import (
    MobileExecutionRepository,
    _OperationRejected,
    resolve_start_mode,
)
from agonez_api.modules.mobile_execution.schemas import OperationBatch, StartWorkout
from agonez_api.modules.mobile_execution.service import (
    MobileExecutionService,
    etag_for,
    next_pending_session_ids,
)


def operation(seq: int, op_id: str) -> dict[str, object]:
    return {
        "op_id": op_id,
        "seq": seq,
        "at": "2026-10-10T17:00:00+02:00",
        "type": "set_workout_comment",
        "data": {"comment": "offline"},
    }


def start_payload(
    *,
    session_id: int = 9,
    off_schedule: dict[str, object] | None = None,
) -> StartWorkout:
    return StartWorkout.model_validate(
        {
            "workout_id": "10000000-0000-4000-8000-000000000001",
            "session_id": session_id,
            "prescription_version": "rx-9-current",
            "started_at": "2026-10-10T17:00:00+02:00",
            "off_schedule": off_schedule,
        }
    )


def test_on_schedule_start_uses_on_schedule_mode() -> None:
    payload = start_payload()

    assert (
        resolve_start_mode(
            payload,
            session_status="scheduled",
            expected_session_id=9,
            next_track_session_id=9,
        )
        == "on_schedule"
    )


def test_off_schedule_start_requires_explicit_acknowledgement() -> None:
    with pytest.raises(ExecutionAPIError) as caught:
        resolve_start_mode(
            start_payload(),
            session_status="scheduled",
            expected_session_id=8,
            next_track_session_id=9,
        )

    assert caught.value.code == "off_schedule_acknowledgement_required"


def test_missed_next_track_exposure_can_start_off_schedule() -> None:
    payload = start_payload(
        off_schedule={
            "mode": "next_track_exposure",
            "acknowledged": True,
            "selected_from": "picker",
            "expected_session_id": 8,
        }
    )

    assert (
        resolve_start_mode(
            payload,
            session_status="missed",
            expected_session_id=8,
            next_track_session_id=9,
        )
        == "next_track_exposure"
    )


def test_later_occurrence_cannot_skip_an_unresolved_track_exposure() -> None:
    payload = start_payload(
        off_schedule={
            "mode": "next_track_exposure",
            "acknowledged": True,
            "selected_from": "picker",
            "expected_session_id": 8,
        }
    )

    with pytest.raises(ExecutionAPIError) as caught:
        resolve_start_mode(
            payload,
            session_status="scheduled",
            expected_session_id=8,
            next_track_session_id=7,
        )

    assert caught.value.code == "not_next_track_exposure"
    assert caught.value.details["next_session_id"] == 7


def test_off_schedule_acknowledgement_detects_expected_session_change() -> None:
    payload = start_payload(
        off_schedule={
            "mode": "next_track_exposure",
            "acknowledged": True,
            "selected_from": "picker",
            "expected_session_id": 8,
        }
    )

    with pytest.raises(ExecutionAPIError) as caught:
        resolve_start_mode(
            payload,
            session_status="scheduled",
            expected_session_id=6,
            next_track_session_id=9,
        )

    assert caught.value.code == "schedule_changed"
    assert caught.value.details["expected_session_id"] == 6


@pytest.mark.parametrize(
    "off_schedule",
    [
        {"acknowledged": True, "selected_from": "picker"},
        {
            "mode": "next_track_exposure",
            "acknowledged": False,
            "selected_from": "picker",
        },
    ],
)
def test_off_schedule_contract_requires_mode_and_true_acknowledgement(
    off_schedule: dict[str, object],
) -> None:
    with pytest.raises(ValidationError):
        start_payload(off_schedule=off_schedule)


def test_context_offers_only_the_next_unresolved_occurrence_per_track() -> None:
    sessions = [
        {"session_id": 31, "workout_track_id": 1, "microcycle_ordinal": 7, "status": "missed"},
        {
            "session_id": 36,
            "workout_track_id": 1,
            "microcycle_ordinal": 8,
            "status": "scheduled",
        },
        {"session_id": 32, "workout_track_id": 2, "microcycle_ordinal": 7, "status": "missed"},
        {
            "session_id": 27,
            "workout_track_id": 3,
            "microcycle_ordinal": 6,
            "status": "completed",
        },
        {
            "session_id": 38,
            "workout_track_id": 3,
            "microcycle_ordinal": 8,
            "status": "scheduled",
        },
    ]

    assert next_pending_session_ids(sessions) == {31, 32, 38}


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


async def test_prescription_version_includes_the_load_step_snapshot() -> None:
    repository = MobileExecutionRepository(None)  # type: ignore[arg-type]
    captured_query = ""

    async def fetch_all(
        connection: object,
        query: str,
        params: tuple[object, ...] | None = None,
    ) -> list[dict[str, object]]:
        nonlocal captured_query
        del connection, params
        captured_query = query
        return [{"exercise_id": 1, "load_step_kg_snapshot": Decimal("2.50")}]

    repository._fetch_all = fetch_all  # type: ignore[method-assign]

    version = await repository._prescription_version(object(), 7)

    assert version.startswith("rx-7-")
    assert "exercise.load_step_kg_snapshot" in captured_query


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
        "/api/v1/mobile/sessions/{session_id}/prescription/fallback",
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


def test_prescription_source_distinguishes_analysis_fallback_and_hybrid() -> None:
    service = MobileExecutionService(None)  # type: ignore[arg-type]

    assert service._prescription_source([]) == "analysis"
    assert service._prescription_source([{"generation_source": "analysis"}]) == "analysis"
    assert (
        service._prescription_source([{"generation_source": "plan_fallback"}])
        == "plan_fallback"
    )
    assert (
        service._prescription_source(
            [
                {"generation_source": "analysis"},
                {"generation_source": "plan_fallback"},
            ]
        )
        == "hybrid"
    )


def test_fallback_rows_do_not_count_as_saved_desktop_analysis() -> None:
    bundle = SimpleNamespace(
        exercise_tracks=[{"workout_unit_track_id": 4}, {"workout_unit_track_id": 4}],
        exercise_prescriptions=[
            {"workout_session_id": 7, "generation_source": "analysis"},
            {"workout_session_id": 7, "generation_source": "plan_fallback"},
        ],
    )

    assert ExecutionService._completeness(  # type: ignore[arg-type]
        ExecutionService(None), bundle, {"id": 7, "workout_unit_track_id": 4}  # type: ignore[arg-type]
    ) == "partial"


def test_performed_set_requires_an_explicit_load() -> None:
    with pytest.raises(_OperationRejected) as caught:
        MobileExecutionRepository._validate_set_values(
            load_kg=None,
            repetitions=8,
            rir=2,
            heart_rate_bpm=None,
        )

    assert getattr(caught.value, "code", None) == "load_required"


@pytest.mark.asyncio
async def test_fallback_materialization_preserves_analysis_and_fills_missing_slots() -> None:
    repository = MobileExecutionRepository(None)  # type: ignore[arg-type]
    writes: list[tuple[str, tuple[object, ...] | None]] = []

    async def fetch_optional(
        connection: object,
        query: str,
        params: tuple[object, ...] | None = None,
    ) -> dict[str, object] | None:
        del connection, params
        if "source_workout" in query:
            return {
                "id": 7,
                "plan_run_id": 3,
                "microcycle_id": 5,
                "workout_unit_track_id": 4,
                "source_plan_workout_unit_id": 40,
                "scheduled_date": datetime(2026, 10, 10, tzinfo=timezone.utc).date(),
                    "session_status": "scheduled",
                    "plan_revision_id": 2,
                    "microcycle_ordinal": 4,
                    "source_revision_id": 2,
                "name": "Push A",
                "description": None,
                "warmup_notes": None,
                "stretch_notes": None,
            }
        if "FROM exec.workout_unit_prescriptions" in query:
            return {"id": 90}
        raise AssertionError(query)

    async def fetch_all(
        connection: object,
        query: str,
        params: tuple[object, ...] | None = None,
    ) -> list[dict[str, object]]:
        del connection, params
        if "FROM plans.exercise_slots AS slot" in query:
            return [
                {
                    "slot_id": 41,
                    "ordinal": 0,
                    "slot_name": "Press",
                    "slot_description": None,
                    "slot_goal": None,
                    "slot_role": "PRIMARY_PROGRESSIVE",
                    "variant_id": 51,
                    "progression_id": None,
                    "exercise_id": 61,
                    "progression_model_slug": None,
                    "load_step_kg": Decimal("2.50"),
                    "exercise_track_id": 71,
                    "previous_exercise_performance_id": 801,
                },
                {
                    "slot_id": 42,
                    "ordinal": 1,
                    "slot_name": "Fly",
                    "slot_description": None,
                    "slot_goal": None,
                    "slot_role": "ACCESSORY",
                    "variant_id": 52,
                    "progression_id": None,
                    "exercise_id": 62,
                    "progression_model_slug": None,
                    "load_step_kg": Decimal("2.50"),
                    "exercise_track_id": 72,
                    "previous_exercise_performance_id": 802,
                },
            ]
        if "FROM plans.set_infra_prescriptions AS item" in query:
            return [
                {
                    "id": 501,
                    "exercise_variant_id": 51,
                    "ordinal": 0,
                    "role": "working",
                    "rep_min": 5,
                    "rep_max": 7,
                    "target_rir": "RIR1",
                },
                {
                    "id": 502,
                    "exercise_variant_id": 52,
                    "ordinal": 0,
                    "role": "working",
                    "rep_min": 8,
                    "rep_max": 12,
                    "target_rir": "RIR2",
                },
            ]
        if "SELECT exercise.*" in query:
            return [
                {
                    "id": 101,
                    "exercise_unit_track_id": 71,
                    "generation_source": "analysis",
                    "source_plan_exercise_variant_id": 51,
                }
            ]
        raise AssertionError(query)

    async def fetch_one(
        connection: object,
        query: str,
        params: tuple[object, ...] | None = None,
    ) -> dict[str, object]:
        del connection
        if "INSERT INTO exec.exercise_unit_prescriptions" in query:
            writes.append((query, params))
            return {"id": 102}
        if "SELECT count(DISTINCT exercise.id)" in query:
            return {"exercise_count": 2, "set_count": 2}
        raise AssertionError(query)

    async def execute(
        connection: object,
        query: str,
        params: tuple[object, ...] | None = None,
    ) -> None:
        del connection
        writes.append((query, params))

    repository._fetch_optional = fetch_optional  # type: ignore[method-assign]
    repository._fetch_all = fetch_all  # type: ignore[method-assign]
    repository._fetch_one = fetch_one  # type: ignore[method-assign]
    repository._execute = execute  # type: ignore[method-assign]

    await repository._ensure_fallback_prescription(object(), 7)

    exercise_inserts = [
        item for item in writes if "INSERT INTO exec.exercise_unit_prescriptions" in item[0]
    ]
    set_inserts = [item for item in writes if "INSERT INTO exec.set_prescriptions" in item[0]]
    assert not any("DELETE FROM exec.exercise_unit_prescriptions" in query for query, _ in writes)
    assert len(exercise_inserts) == 1
    assert "'plan_fallback'" in exercise_inserts[0][0]
    assert len(set_inserts) == 1
    assert set_inserts[0][1] == (102, 0, 502, "working", 8, 12, "RIR2")
    assert any("UPDATE exec.workout_unit_prescriptions" in query for query, _ in writes)


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
