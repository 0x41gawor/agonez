from pathlib import Path
from typing import Any

import pytest

from agonez_api.core.media import MediaResolver
from agonez_api.modules.atlas.exceptions import AtlasEntityNotFoundError
from agonez_api.modules.atlas.service import AtlasService


class FakeRepository:
    async def list_exercises(self, **kwargs: Any) -> tuple[list[dict[str, Any]], dict[str, Any]]:
        del kwargs
        return (
            [
                {
                    "slug": "dragon_flag",
                    "name": "Dragon Flag",
                    "name_full": "Flat Bench Dragon Flag",
                    "body_part": "Core",
                    "target_category": "Core",
                    "mechanics_tier": "Secondary_Compound",
                    "resistance_source": "Bodyweight",
                    "execution_pattern": "Bilateral",
                    "load_capacity": 55,
                    "systemic_propulsive_fcsa_demand": 115,
                    "has_engine_vectors": True,
                }
            ],
            {
                "total": 1,
                "body_part": {"Core": 1},
                "target_category": {"Core": 1},
                "mechanics_tier": {"Secondary_Compound": 1},
                "resistance_source": {"Bodyweight": 1},
            },
        )

    async def get_muscle(self, slug: str) -> dict[str, Any] | None:
        if slug == "missing":
            return None
        return {
            "slug": slug,
            "complex": "Back",
            "pcsa_projected_fcsa_cm2": 40.0,
        }

    async def measured_related_exercises(self, *, muscle_slug: str) -> list[dict[str, Any]]:
        del muscle_slug
        return [
            {
                "slug": "neutral_grip_lat_pulldown",
                "name": "Neutral-Grip Lat Pulldown",
                "name_full": "Selectorized Neutral-Grip Lat Pulldown",
                "target_category": "Back_V",
                "mechanics_tier": "Secondary_Compound",
                "etu_cm2": 20.0,
            }
        ]

    async def fallback_related_exercises(self, **kwargs: Any) -> list[dict[str, Any]]:
        assert kwargs["target_categories"] == (
            "Back_V",
            "Back_3D",
            "Upper_Traps",
            "Serratus",
        )
        assert kwargs["excluded_slugs"] == ["neutral_grip_lat_pulldown"]
        return [
            {
                "slug": "wide_pronated_grip_pull_up",
                "name": "Wide-Grip Pull-Up",
                "name_full": "Wide Pronated-Grip Pull-Up",
                "target_category": "Back_V",
                "mechanics_tier": "Heavy_Compound",
            }
        ]


@pytest.fixture
def service(tmp_path: Path) -> AtlasService:
    exercise_dir = tmp_path / "exercises"
    exercise_dir.mkdir()
    (exercise_dir / "dragon_flag.png").write_bytes(b"png")
    return AtlasService(  # type: ignore[arg-type]
        FakeRepository(),
        MediaResolver(root=tmp_path, url_prefix="/media"),
    )


async def test_exercise_list_is_shaped_for_the_contract(service: AtlasService) -> None:
    response = await service.list_exercises(
        q=None,
        body_parts=(),
        target_categories=(),
        mechanics_tiers=(),
        resistance_sources=(),
        sort="name",
        order="asc",
        page=1,
        per_page=50,
    )

    assert response.total == 1
    assert response.facets.body_part == {"Core": 1}
    assert response.items[0].image_url == "/media/exercises/dragon_flag.png"
    assert response.items[0].has_engine_vectors is True


async def test_related_exercises_put_measured_values_first(service: AtlasService) -> None:
    response = await service.related_exercises(
        muscle_slug="latissimus_dorsi",
        limit=8,
        sort="etu",
    )

    assert [item.relation for item in response.items] == ["measured", "by_target"]
    assert response.items[0].etu_cm2 == 20.0
    assert response.items[0].normalized_etu == 0.5
    assert response.items[1].etu_cm2 is None


async def test_related_exercises_404_for_missing_muscle(service: AtlasService) -> None:
    with pytest.raises(AtlasEntityNotFoundError):
        await service.related_exercises(muscle_slug="missing", limit=8, sort="etu")
