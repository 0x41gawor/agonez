from typing import Any

from agonez_api.modules.atlas.repository import EXERCISE_SORTS, AtlasRepository


async def test_exercise_list_metrics_and_sorting_are_sourced_from_engine() -> None:
    repository = AtlasRepository(None)  # type: ignore[arg-type]
    queries: list[str] = []

    async def fetch_all(
        query: str,
        params: tuple[Any, ...] | None = None,
    ) -> list[dict[str, Any]]:
        del params
        queries.append(query)
        return []

    async def fetch_one(
        query: str,
        params: tuple[Any, ...] | None = None,
    ) -> dict[str, Any]:
        del params
        queries.append(query)
        return {
            "total": 0,
            "body_part": {},
            "target_category": {},
            "mechanics_tier": {},
            "resistance_source": {},
        }

    repository._fetch_all = fetch_all  # type: ignore[method-assign]
    repository._fetch_one = fetch_one  # type: ignore[method-assign]

    await repository.list_exercises(
        q=None,
        body_parts=(),
        target_categories=(),
        mechanics_tiers=(),
        resistance_sources=(),
        sort="load_capacity",
        order="desc",
        limit=50,
        offset=0,
    )

    list_query = queries[0]
    assert (
        "eng.load_capacity_kg AS load_capacity,\n"
        "                eng.systemic_propulsive_fcsa_demand"
    ) in list_query
    assert "eng.systemic_propulsive_fcsa_demand" in list_query
    assert "ORDER BY eng.load_capacity_kg DESC" in list_query
    assert EXERCISE_SORTS["load_capacity"] == "eng.load_capacity_kg"
    assert EXERCISE_SORTS["systemic_propulsive_fcsa_demand"] == (
        "eng.systemic_propulsive_fcsa_demand"
    )


async def test_exercise_detail_propulsive_fields_are_sourced_from_engine() -> None:
    repository = AtlasRepository(None)  # type: ignore[arg-type]
    captured_query = ""

    async def fetch_optional(
        query: str,
        params: tuple[Any, ...] | None = None,
    ) -> None:
        nonlocal captured_query
        del params
        captured_query = query
        return None

    repository._fetch_optional = fetch_optional  # type: ignore[method-assign]
    await repository.get_exercise("barbell_bench_press")

    assert (
        "eng.load_capacity_kg AS load_capacity,\n"
        "                eng.systemic_propulsive_fcsa_demand"
    ) in captured_query
    assert "eng.systemic_propulsive_fcsa_demand" in captured_query
    assert "eng.propulsive_fcsa_contribution_vector" in captured_query
    assert "e.load_capacity," not in captured_query
    assert "e.systemic_propulsive_fcsa_demand" not in captured_query
    assert "e.propulsive_fcsa_contribution_vector" not in captured_query
