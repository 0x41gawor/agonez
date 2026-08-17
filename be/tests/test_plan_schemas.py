import pytest
from pydantic import ValidationError

from agonez_api.modules.plans.schemas import PlanDraftUpdate


def draft_payload() -> dict[str, object]:
    return {
        "id": 1,
        "revision_id": 2,
        "revision_no": 1,
        "lock_version": 1,
        "name": "Push plan",
        "description": None,
        "days": [
            {
                "id": None,
                "ordinal": 0,
                "weekday": 1,
                "name": "Push A",
                "description": None,
                "workout_unit": {
                    "id": None,
                    "name": "Push A",
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
                            "target_muscle_slugs": ["pectoralis_major_sternal"],
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


def test_nested_draft_schema_accepts_the_plan_artifact() -> None:
    draft = PlanDraftUpdate.model_validate(draft_payload())

    assert draft.days[0].workout_unit is not None
    assert draft.days[0].workout_unit.exercise_slots[0].variants[0].sets[0].reps.max == 7


@pytest.mark.parametrize(
    ("field", "value"),
    [("rir", 5), ("rir", -1)],
)
def test_set_rir_is_limited_to_zero_through_four(field: str, value: int) -> None:
    payload = draft_payload()
    sets = payload["days"][0]["workout_unit"]["exercise_slots"][0]["variants"][0]["sets"]  # type: ignore[index]
    sets[0][field] = value

    with pytest.raises(ValidationError):
        PlanDraftUpdate.model_validate(payload)


def test_invalid_rep_range_is_rejected() -> None:
    payload = draft_payload()
    item = payload["days"][0]["workout_unit"]["exercise_slots"][0]["variants"][0]["sets"][0]  # type: ignore[index]
    item["reps"] = {"min": 10, "max": 8}

    with pytest.raises(ValidationError, match="reps.max"):
        PlanDraftUpdate.model_validate(payload)


def test_duplicate_default_variant_is_rejected() -> None:
    payload = draft_payload()
    variants = payload["days"][0]["workout_unit"]["exercise_slots"][0]["variants"]  # type: ignore[index]
    variants.append(
        {
            "id": None,
            "ordinal": 1,
            "variant_type": "DEFAULT",
            "exercise_slug": "barbell_california_press",
            "sets": [],
        }
    )

    with pytest.raises(ValidationError, match="exactly one DEFAULT"):
        PlanDraftUpdate.model_validate(payload)


def test_duplicate_target_muscle_is_rejected() -> None:
    payload = draft_payload()
    slot = payload["days"][0]["workout_unit"]["exercise_slots"][0]  # type: ignore[index]
    slot["target_muscle_slugs"] = [
        "pectoralis_major_sternal",
        "pectoralis_major_sternal",
    ]

    with pytest.raises(ValidationError, match="Duplicate target"):
        PlanDraftUpdate.model_validate(payload)


def test_non_deterministic_ordinals_are_rejected() -> None:
    payload = draft_payload()
    payload["days"][0]["ordinal"] = 1  # type: ignore[index]

    with pytest.raises(ValidationError, match="Day ordinals"):
        PlanDraftUpdate.model_validate(payload)
