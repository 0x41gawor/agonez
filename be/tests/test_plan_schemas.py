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
    slot = draft.days[0].workout_unit.exercise_slots[0]
    assert slot.loading_mode.value == "moderate_load"
    assert slot.variants[0].sets[0].loading_mode is None
    variant = slot.variants[0]
    assert variant.progression_id is not None
    assert variant.active_working_sets is None
    assert variant.sets[0].role.value == "working"
    assert variant.sets[0].load_spec.kind == "absolute"
    assert variant.sets[0].reps.semantics.value == "undefined"
    assert variant.sets[0].rir.value == "RIR2"


def test_progression_model_is_variant_level_metadata() -> None:
    payload = draft_payload()
    variant = payload["days"][0]["workout_unit"]["exercise_slots"][0]["variants"][0]  # type: ignore[index]
    variant["progression_model_slug"] = "double_progression"

    draft = PlanDraftUpdate.model_validate(payload)

    parsed = draft.days[0].workout_unit.exercise_slots[0].variants[0]  # type: ignore[union-attr]
    assert parsed.progression_model_slug == "double_progression"


def test_progression_model_slug_rejects_non_catalog_shape() -> None:
    payload = draft_payload()
    variant = payload["days"][0]["workout_unit"]["exercise_slots"][0]["variants"][0]  # type: ignore[index]
    variant["progression_model_slug"] = "Double progression"

    with pytest.raises(ValidationError, match="progression_model_slug"):
        PlanDraftUpdate.model_validate(payload)


def test_loading_mode_inheritance_and_cycles_are_accepted() -> None:
    payload = draft_payload()
    slot = payload["days"][0]["workout_unit"]["exercise_slots"][0]  # type: ignore[index]
    slot["loading_mode"] = "high_load"
    slot["loading_cycle"] = ["high_load", "high_load", "low_load"]
    item = slot["variants"][0]["sets"][0]
    item["loading_mode"] = "low_load"
    item["loading_cycle"] = ["low_load", "high_load"]

    draft = PlanDraftUpdate.model_validate(payload)
    parsed_slot = draft.days[0].workout_unit.exercise_slots[0]  # type: ignore[union-attr]
    assert [mode.value for mode in parsed_slot.loading_cycle or []] == [
        "high_load",
        "high_load",
        "low_load",
    ]
    assert [mode.value for mode in parsed_slot.variants[0].sets[0].loading_cycle or []] == [
        "low_load",
        "high_load",
    ]


@pytest.mark.parametrize("cycle", [[], ["high_load"], ["unknown", "low_load"]])
def test_invalid_loading_cycles_are_rejected(cycle: list[str]) -> None:
    payload = draft_payload()
    slot = payload["days"][0]["workout_unit"]["exercise_slots"][0]  # type: ignore[index]
    slot["loading_cycle"] = cycle

    with pytest.raises(ValidationError):
        PlanDraftUpdate.model_validate(payload)


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


def test_extended_set_metadata_and_active_working_range_are_accepted() -> None:
    payload = draft_payload()
    variant = payload["days"][0]["workout_unit"]["exercise_slots"][0]["variants"][0]  # type: ignore[index]
    variant["active_working_sets"] = {"min": 1, "max": 1}
    variant["sets"].insert(  # type: ignore[index]
        0,
        {
            "id": None,
            "ordinal": 0,
            "reps": {"min": 5, "max": 5, "semantics": "undefined"},
            "rir": "NOT_APPLICABLE",
            "role": "rampup",
            "load_spec": {"kind": "relative_to_set", "ref_set_idx": 1, "pct": 50},
        },
    )
    variant["sets"][1]["ordinal"] = 1  # type: ignore[index]
    variant["sets"][1]["reps"]["semantics"] = "gating"  # type: ignore[index]
    variant["sets"][1]["rir"] = "UNDEFINED"  # type: ignore[index]
    variant["sets"][1]["role"] = "working_topset"  # type: ignore[index]
    variant["sets"][1]["load_spec"] = {"kind": "athlete_selected"}  # type: ignore[index]

    draft = PlanDraftUpdate.model_validate(payload)
    parsed = draft.days[0].workout_unit.exercise_slots[0].variants[0]  # type: ignore[union-attr]

    assert parsed.active_working_sets is not None
    assert parsed.active_working_sets.max == 1
    assert parsed.sets[0].rir.value == "NOT_APPLICABLE"
    assert parsed.sets[0].load_spec.kind == "relative_to_set"
    assert parsed.sets[1].reps.semantics.value == "gating"
    assert parsed.sets[1].rir.value == "UNDEFINED"


@pytest.mark.parametrize(
    ("load_spec", "message"),
    [
        ({"kind": "relative_to_set", "ref_set_idx": 0, "pct": 92}, "must not reference itself"),
        ({"kind": "table_derived", "ref_set_idx": 4, "table": "apre10"}, "references missing set"),
    ],
)
def test_invalid_set_references_are_rejected(
    load_spec: dict[str, object],
    message: str,
) -> None:
    payload = draft_payload()
    item = payload["days"][0]["workout_unit"]["exercise_slots"][0]["variants"][0]["sets"][0]  # type: ignore[index]
    item["load_spec"] = load_spec

    with pytest.raises(ValidationError, match=message):
        PlanDraftUpdate.model_validate(payload)


def test_active_working_set_max_excludes_rampup_sets() -> None:
    payload = draft_payload()
    variant = payload["days"][0]["workout_unit"]["exercise_slots"][0]["variants"][0]  # type: ignore[index]
    variant["sets"][0]["role"] = "rampup"  # type: ignore[index]
    variant["sets"][0]["rir"] = "NOT_APPLICABLE"  # type: ignore[index]
    variant["active_working_sets"] = {"min": 0, "max": 1}

    with pytest.raises(ValidationError, match="must not exceed prescribed working sets"):
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
