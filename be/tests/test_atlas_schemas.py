from agonez_api.modules.atlas.schemas import ExerciseDetail, ExerciseListItem


def exercise_fields() -> dict[str, object]:
    return {
        "slug": "unevaluated_exercise",
        "name": "Unevaluated exercise",
        "name_full": "Unevaluated exercise",
        "body_part": "Upper",
        "target_category": "Other",
        "mechanics_tier": "Accessory",
        "resistance_source": "Cable",
        "execution_pattern": "Bilateral",
        "load_capacity": None,
        "systemic_propulsive_fcsa_demand": None,
        "recommended_rep_profile": {
            "high_load": {"min": 5, "max": 8},
            "moderate_load": {"min": 8, "max": 12},
            "low_load": {"min": 12, "max": 20},
        },
        "created_at": "2026-08-20T10:00:00Z",
        "updated_at": "2026-08-21T10:00:00Z",
        "image_url": None,
    }


def test_exercise_list_item_accepts_unevaluated_engine_metrics() -> None:
    item = ExerciseListItem.model_validate(
        {**exercise_fields(), "has_engine_vectors": False}
    )

    assert item.load_capacity is None
    assert item.systemic_propulsive_fcsa_demand is None
    assert item.recommended_rep_profile.high_load.min == 5


def test_exercise_detail_accepts_unevaluated_engine_metrics() -> None:
    detail = ExerciseDetail.model_validate(
        {
            **exercise_fields(),
            "propulsive_fcsa_contribution_vector": None,
            "technique": {},
            "comments": {},
            "video_links": [],
            "engine": None,
        }
    )

    assert detail.propulsive_fcsa_contribution_vector is None
    assert detail.recommended_rep_profile.low_load is not None
    assert detail.recommended_rep_profile.low_load.max == 20


def test_recommended_rep_profile_accepts_unsupported_loading_modes() -> None:
    fields = exercise_fields()
    fields["recommended_rep_profile"] = {
        "high_load": None,
        "moderate_load": {"min": 8, "max": 12},
        "low_load": None,
    }

    item = ExerciseListItem.model_validate({**fields, "has_engine_vectors": False})

    assert item.recommended_rep_profile.high_load is None
    assert item.recommended_rep_profile.moderate_load is not None
    assert item.recommended_rep_profile.moderate_load.min == 8
    assert item.recommended_rep_profile.low_load is None
