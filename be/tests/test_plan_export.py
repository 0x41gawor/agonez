from agonez_api.modules.plans.analysis.resolver import resolve_plan
from agonez_api.modules.plans.analysis.schemas import PlanResolutionContext
from agonez_api.modules.plans.analysis.service import build_plan_ai_export
from agonez_api.modules.plans.schemas import PlanDraftArtifact


def test_ai_export_is_small_and_uses_the_resolved_basic_plan() -> None:
    draft = PlanDraftArtifact.model_validate(
        {
            "id": 6,
            "revision_id": 9,
            "revision_no": 1,
            "lock_version": 55,
            "name": "Push and rest",
            "description": "Not exported",
            "days": [
                {
                    "id": 100,
                    "ordinal": 0,
                    "weekday": 1,
                    "name": "Push A",
                    "description": None,
                    "workout_unit": {
                        "id": 200,
                        "name": "Push workout",
                        "description": None,
                        "warmup_notes": None,
                        "stretch_notes": None,
                        "exercise_slots": [
                            {
                                "id": 300,
                                "ordinal": 0,
                                "name": "Primary press",
                                "description": None,
                                "goal": None,
                                "role": "PRIMARY_PROGRESSIVE",
                                "volume_axis": None,
                                "target_muscle_slugs": [],
                                "variants": [
                                    {
                                        "id": 400,
                                        "ordinal": 0,
                                        "variant_type": "DEFAULT",
                                        "exercise_slug": "barbell_bench_press",
                                        "sets": [
                                            {
                                                "id": 500,
                                                "ordinal": 0,
                                                "reps": {"min": 5, "max": 7},
                                                "rir": 2,
                                                "min_volume_level": 0,
                                            },
                                            {
                                                "id": 501,
                                                "ordinal": 1,
                                                "reps": {"min": 8, "max": 10},
                                                "rir": 1,
                                                "min_volume_level": 1,
                                            },
                                        ],
                                    },
                                    {
                                        "id": 401,
                                        "ordinal": 1,
                                        "variant_type": "FALLBACK",
                                        "exercise_slug": "dumbbell_bench_press",
                                        "sets": [
                                            {
                                                "id": 502,
                                                "ordinal": 0,
                                                "reps": {"min": 8, "max": 12},
                                                "rir": 2,
                                                "min_volume_level": 0,
                                            }
                                        ],
                                    },
                                ],
                            }
                        ],
                    },
                },
                {
                    "id": 101,
                    "ordinal": 1,
                    "weekday": 2,
                    "name": "Rest",
                    "description": None,
                    "workout_unit": None,
                },
            ],
        }
    )
    resolved, _, _ = resolve_plan(draft, PlanResolutionContext())

    result = build_plan_ai_export(
        draft,
        resolved,
        {"barbell_bench_press": "Barbell Bench Press"},
    ).model_dump(mode="json")

    assert result == {
        "format": "agonez-plan-sanity-v1",
        "plan_name": "Push and rest",
        "resolution_context": {
            "global_volume_level": 0,
            "focus_area": None,
            "axis_overrides": {},
        },
        "days": [
            {
                "day": 1,
                "name": "Push A",
                "weekday": "Monday",
                "rest": False,
                "exercises": [
                    {
                        "name": "Barbell Bench Press",
                        "slug": "barbell_bench_press",
                        "sets": [{"reps": {"min": 5, "max": 7}, "rir": 2}],
                    }
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
