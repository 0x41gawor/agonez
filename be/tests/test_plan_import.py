from typing import Any, cast

import pytest
from pydantic import ValidationError

from agonez_api.modules.plans.analysis.schemas import PlanAIImportDocument
from agonez_api.modules.plans.repository import DraftRows, PlanRepository


def import_payload() -> dict[str, object]:
    return {
        "format": "agonez-plan-sanity-v1",
        "plan_name": "Imported strength plan",
        "resolution_context": {
            "global_volume_level": 0,
            "focus_area": None,
            "axis_overrides": {},
        },
        "days": [
            {
                "day": 1,
                "name": "Full body",
                "weekday": "Monday",
                "rest": False,
                "exercises": [
                    {
                        "name": "Barbell Bench Press",
                        "slug": "barbell_bench_press",
                        "sets": [{"reps": {"min": 5, "max": 7}, "rir": 2}],
                    },
                    {
                        "name": "Pendlay Row",
                        "slug": "pendlay_row",
                        "sets": [{"reps": {"min": 6, "max": 8}, "rir": 2}],
                    },
                    {
                        "name": "Barbell Curl",
                        "slug": "barbell_curl",
                        "sets": [{"reps": {"min": 8, "max": 12}, "rir": 1}],
                    },
                ],
            },
            {
                "day": 2,
                "name": "Rest",
                "weekday": "Tuesday",
                "rest": True,
                "exercises": [],
            },
        ],
    }


def test_import_schema_accepts_the_export_interchange_format() -> None:
    document = PlanAIImportDocument.model_validate(import_payload())

    assert document.plan_name == "Imported strength plan"
    assert document.days[0].exercises[0].sets[0].rir == 2
    assert document.days[1].rest is True


def test_import_schema_accepts_v2_progression_metadata() -> None:
    payload = import_payload()
    payload["format"] = "agonez-plan-sanity-v2"
    exercises = payload["days"][0]["exercises"]  # type: ignore[index]
    for index, exercise in enumerate(exercises):
        exercise["progression_model"] = (  # type: ignore[index]
            {
                "slug": "double_progression",
                "name": "Double progression",
                "when_to_use": "Use for stable ranges.",
            }
            if index == 0
            else None
        )

    document = PlanAIImportDocument.model_validate(payload)

    assert document.days[0].exercises[0].progression_model is not None
    assert document.days[0].exercises[0].progression_model.slug == "double_progression"
    assert document.days[0].exercises[1].progression_model is None


def test_v2_requires_progression_field_and_v1_rejects_it() -> None:
    v2 = import_payload()
    v2["format"] = "agonez-plan-sanity-v2"
    with pytest.raises(ValidationError, match="must contain progression_model"):
        PlanAIImportDocument.model_validate(v2)

    v1 = import_payload()
    v1["days"][0]["exercises"][0]["progression_model"] = None  # type: ignore[index]
    with pytest.raises(ValidationError, match="must not contain progression_model"):
        PlanAIImportDocument.model_validate(v1)


def test_import_schema_rejects_non_consecutive_days_and_populated_rest_days() -> None:
    payload = import_payload()
    payload["days"][0]["day"] = 2  # type: ignore[index]
    payload["days"][1]["exercises"] = payload["days"][0]["exercises"]  # type: ignore[index]

    with pytest.raises(ValidationError, match="rest day|Day numbers"):
        PlanAIImportDocument.model_validate(payload)


def test_import_schema_requires_every_documented_field() -> None:
    payload = import_payload()
    del payload["resolution_context"]["axis_overrides"]  # type: ignore[index]
    del payload["days"][0]["exercises"][0]["sets"]  # type: ignore[index]

    with pytest.raises(ValidationError, match="axis_overrides|sets"):
        PlanAIImportDocument.model_validate(payload)


class _Context:
    def __init__(self, value: Any) -> None:
        self.value = value

    async def __aenter__(self) -> Any:
        return self.value

    async def __aexit__(self, *_: object) -> None:
        return None


class _Connection:
    def transaction(self) -> _Context:
        return _Context(self)


class _Pool:
    def __init__(self, connection: _Connection) -> None:
        self._connection = connection

    def connection(self) -> _Context:
        return _Context(self._connection)


@pytest.mark.asyncio
async def test_import_persists_a_complete_tree_in_one_transaction_with_derived_roles() -> None:
    document = PlanAIImportDocument.model_validate(import_payload())
    repository = PlanRepository(cast(Any, _Pool(_Connection())))
    events: list[tuple[str, tuple[Any, ...] | None]] = []
    returned_ids = iter(range(101, 200))
    assembled = DraftRows(
        header={"id": 101},
        days=[],
        workout_units=[],
        slots=[],
        target_muscles=[],
        variants=[],
        sets=[],
    )

    async def resolve_catalog_slugs(
        connection: Any,
        *,
        table: str,
        slugs: set[str],
        entity_label: str,
    ) -> dict[str, int]:
        del connection
        events.append((f"resolve:{table}:{entity_label}", tuple(sorted(slugs))))
        return {slug: index for index, slug in enumerate(sorted(slugs), start=1)}

    async def fetch_one(
        connection: Any,
        query: str,
        params: tuple[Any, ...] | None = None,
    ) -> dict[str, int]:
        del connection
        events.append((query, params))
        return {"id": next(returned_ids)}

    async def load_rows(connection: Any, plan_id: int) -> DraftRows:
        del connection
        assert plan_id == 101
        return assembled

    async def validate_progression_model_slugs(
        connection: Any,
        slugs: set[str],
    ) -> None:
        del connection
        events.append(("validate:progression-models", tuple(sorted(slugs))))

    repository._resolve_catalog_slugs = resolve_catalog_slugs  # type: ignore[method-assign]
    repository._validate_progression_model_slugs = validate_progression_model_slugs  # type: ignore[method-assign]
    repository._fetch_one = fetch_one  # type: ignore[method-assign]
    repository._load_draft_rows = load_rows  # type: ignore[method-assign]

    result = await repository.import_plan(document)

    assert result is assembled
    assert events[0][0] == "resolve:core.exercises:exercise"
    assert events[1] == ("validate:progression-models", ())
    slot_parameters = [
        params
        for query, params in events
        if "INSERT INTO plans.exercise_slots" in query
    ]
    assert [params[-1] for params in slot_parameters if params] == [
        "PRIMARY_PROGRESSIVE",
        "SECONDARY_PROGRESSIVE",
        "ACCESSORY",
    ]
    inserted_units = [query for query, _ in events if "workout_unit_prescriptions" in query]
    assert len(inserted_units) == 1
