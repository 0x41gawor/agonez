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
