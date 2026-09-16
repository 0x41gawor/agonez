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
        locale="pl",
    )

    list_query = queries[0]
    assert (
        "eng.load_capacity_kg AS load_capacity,\n"
        "                eng.systemic_propulsive_fcsa_demand"
    ) in list_query
    assert "eng.systemic_propulsive_fcsa_demand" in list_query
    assert "ORDER BY eng.load_capacity_kg DESC" in list_query
    assert "COALESCE(et.name, e.name) AS name" in list_query
    assert "et.status = 'published'" in list_query
    assert EXERCISE_SORTS["load_capacity"] == "eng.load_capacity_kg"
    assert EXERCISE_SORTS["systemic_propulsive_fcsa_demand"] == (
        "eng.systemic_propulsive_fcsa_demand"
    )
    assert EXERCISE_SORTS["created_at"] == "e.created_at"
    assert EXERCISE_SORTS["updated_at"] == "e.updated_at"
    assert "e.created_at" in list_query
    assert "e.updated_at" in list_query
    assert "e.recommended_rep_profile" in list_query


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
    await repository.get_exercise("barbell_bench_press", locale="fr")

    assert (
        "eng.load_capacity_kg AS load_capacity,\n"
        "                eng.systemic_propulsive_fcsa_demand"
    ) in captured_query
    assert "eng.systemic_propulsive_fcsa_demand" in captured_query
    assert "eng.propulsive_fcsa_contribution_vector" in captured_query
    assert "e.created_at" in captured_query
    assert "e.updated_at" in captured_query
    assert "e.recommended_rep_profile" in captured_query
    assert "e.load_capacity," not in captured_query
    assert "e.systemic_propulsive_fcsa_demand" not in captured_query
    assert "e.propulsive_fcsa_contribution_vector" not in captured_query
    assert "COALESCE(et.name, e.name) AS name" in captured_query
    assert "COALESCE(et.technique, e.technique) AS technique" in captured_query
    assert "COALESCE(et.comments, e.comments) AS comments" in captured_query


async def test_exercise_catalog_is_complete_lightweight_and_sorted() -> None:
    repository = AtlasRepository(None)  # type: ignore[arg-type]
    captured_query = ""

    async def fetch_all(
        query: str,
        params: tuple[Any, ...] | None = None,
    ) -> list[dict[str, Any]]:
        nonlocal captured_query
        assert params == ("es",)
        captured_query = query
        return []

    repository._fetch_all = fetch_all  # type: ignore[method-assign]
    await repository.list_exercise_catalog(locale="es")

    assert "e.target_category::text AS target_category" in captured_query
    assert "e.mechanics_tier::text AS mechanics_tier" in captured_query
    assert "eng.systemic_propulsive_fcsa_demand" in captured_query
    assert "e.recommended_rep_profile" in captured_query
    assert "LEFT JOIN engine.exercises AS eng" in captured_query
    assert "ORDER BY LOWER(COALESCE(et.name_full, e.name_full)) ASC, e.slug ASC" in captured_query
    assert "et.status = 'published'" in captured_query
    assert "LIMIT" not in captured_query
    assert "OFFSET" not in captured_query
    assert "created_at" not in captured_query


async def test_localized_search_uses_resolved_and_canonical_exercise_names() -> None:
    repository = AtlasRepository(None)  # type: ignore[arg-type]
    calls: list[tuple[str, tuple[Any, ...] | None]] = []

    async def fetch_all(
        query: str,
        params: tuple[Any, ...] | None = None,
    ) -> list[dict[str, Any]]:
        calls.append((query, params))
        return []

    async def fetch_one(
        query: str,
        params: tuple[Any, ...] | None = None,
    ) -> dict[str, Any]:
        calls.append((query, params))
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
        q="wyciskanie",
        body_parts=(),
        target_categories=(),
        mechanics_tiers=(),
        resistance_sources=(),
        sort="name",
        order="asc",
        limit=50,
        offset=0,
        locale="pl",
    )

    assert all("core.exercise_translations" in query for query, _ in calls)
    assert "COALESCE(et.name, e.name)" in calls[0][0]
    assert "e.name, e.name_full, e.slug" in calls[0][0]
    assert calls[0][1] == ("pl", "%wyciskanie%", 50, 0)
    assert calls[1][1] == ("pl", "%wyciskanie%")


async def test_muscle_queries_fall_back_per_translated_field() -> None:
    repository = AtlasRepository(None)  # type: ignore[arg-type]
    captured: list[tuple[str, tuple[Any, ...] | None]] = []

    async def fetch_optional(
        query: str,
        params: tuple[Any, ...] | None = None,
    ) -> None:
        captured.append((query, params))
        return None

    repository._fetch_optional = fetch_optional  # type: ignore[method-assign]
    await repository.get_muscle("pectoralis_minor", locale="de")

    query, params = captured[0]
    assert "COALESCE(mt.display_name, m.name) AS display_name" in query
    assert "COALESCE(mt.bible_markdown, m.bible_markdown) AS bible_markdown" in query
    assert "core.muscle_translations" in query
    assert params == ("de", "pectoralis_minor")


async def test_adding_a_video_updates_timestamp_only_for_a_new_link() -> None:
    repository = AtlasRepository(None)  # type: ignore[arg-type]
    captured_query = ""
    captured_params: tuple[Any, ...] | None = None

    async def fetch_optional(
        query: str,
        params: tuple[Any, ...] | None = None,
    ) -> dict[str, Any]:
        nonlocal captured_query, captured_params
        captured_query = query
        captured_params = params
        return {"video_links": ["https://youtu.be/YE7VzlLtp-4"]}

    repository._fetch_optional = fetch_optional  # type: ignore[method-assign]
    url = "https://youtu.be/YE7VzlLtp-4"
    await repository.add_exercise_video(slug="barbell_bench_press", url=url)

    assert "WHEN %s = ANY(video_links) THEN updated_at" in captured_query
    assert "ELSE now()" in captured_query
    assert "RETURNING video_links, updated_at" in captured_query
    assert captured_params == (url, url, url, "barbell_bench_press")
