from collections.abc import Sequence
from typing import Any, cast

from agonez_api.core.database import DatabasePool

Row = dict[str, Any]

EXERCISE_SORTS = {
    "name": "LOWER(e.name)",
    "name_full": "LOWER(e.name_full)",
    "load_capacity": "eng.load_capacity_kg",
    "systemic_propulsive_fcsa_demand": "eng.systemic_propulsive_fcsa_demand",
    "created_at": "e.created_at",
    "updated_at": "e.updated_at",
}

MUSCLE_SORTS = {
    "name": "LOWER(m.name)",
    "mass_g": "m.mass_g",
    "mv_cm3": "m.mv_cm3",
    "fiber_bias_type_ii": "m.fiber_bias_type_ii",
    "pcsa_fiber_cm2": "m.pcsa_fiber_cm2",
    "pcsa_projected_fcsa_cm2": "m.pcsa_projected_fcsa_cm2",
}


class AtlasRepository:
    def __init__(self, pool: DatabasePool) -> None:
        self._pool = pool

    async def ping(self) -> None:
        await self._fetch_one("SELECT 1 AS ok")

    async def list_exercises(
        self,
        *,
        q: str | None,
        body_parts: Sequence[str],
        target_categories: Sequence[str],
        mechanics_tiers: Sequence[str],
        resistance_sources: Sequence[str],
        sort: str,
        order: str,
        limit: int,
        offset: int,
    ) -> tuple[list[Row], Row]:
        where_sql, params = self._exercise_where(
            q=q,
            body_parts=body_parts,
            target_categories=target_categories,
            mechanics_tiers=mechanics_tiers,
            resistance_sources=resistance_sources,
        )
        sort_expression = EXERCISE_SORTS[sort]
        direction = "DESC" if order == "desc" else "ASC"
        items_sql = f"""
            SELECT
                e.slug,
                e.name,
                e.name_full,
                e.body_part::text AS body_part,
                e.target_category::text AS target_category,
                e.mechanics_tier::text AS mechanics_tier,
                e.resistance_source::text AS resistance_source,
                e.execution_pattern::text AS execution_pattern,
                e.created_at,
                e.updated_at,
                eng.load_capacity_kg AS load_capacity,
                eng.systemic_propulsive_fcsa_demand,
                (
                    eng.slug IS NOT NULL
                    AND (
                        eng.active_tension_exposure_vector IS NOT NULL
                        OR eng.etu_vector IS NOT NULL
                        OR eng.muscle_recovery_cost_modifier_vector IS NOT NULL
                        OR eng.joint_load_exposure_vector IS NOT NULL
                    )
                ) AS has_engine_vectors
            FROM core.exercises AS e
            LEFT JOIN engine.exercises AS eng ON eng.slug = e.slug
            {where_sql}
            ORDER BY {sort_expression} {direction} NULLS LAST, e.slug ASC
            LIMIT %s OFFSET %s
        """
        items = await self._fetch_all(items_sql, (*params, limit, offset))

        summary_sql = f"""
            WITH filtered AS (
                SELECT
                    e.body_part::text AS body_part,
                    e.target_category::text AS target_category,
                    e.mechanics_tier::text AS mechanics_tier,
                    e.resistance_source::text AS resistance_source
                FROM core.exercises AS e
                {where_sql}
            )
            SELECT
                (SELECT COUNT(*)::integer FROM filtered) AS total,
                COALESCE((
                    SELECT jsonb_object_agg(value, amount)
                    FROM (
                        SELECT body_part AS value, COUNT(*)::integer AS amount
                        FROM filtered GROUP BY body_part ORDER BY body_part
                    ) AS counts
                ), '{{}}'::jsonb) AS body_part,
                COALESCE((
                    SELECT jsonb_object_agg(value, amount)
                    FROM (
                        SELECT target_category AS value, COUNT(*)::integer AS amount
                        FROM filtered GROUP BY target_category ORDER BY target_category
                    ) AS counts
                ), '{{}}'::jsonb) AS target_category,
                COALESCE((
                    SELECT jsonb_object_agg(value, amount)
                    FROM (
                        SELECT mechanics_tier AS value, COUNT(*)::integer AS amount
                        FROM filtered GROUP BY mechanics_tier ORDER BY mechanics_tier
                    ) AS counts
                ), '{{}}'::jsonb) AS mechanics_tier,
                COALESCE((
                    SELECT jsonb_object_agg(value, amount)
                    FROM (
                        SELECT resistance_source AS value, COUNT(*)::integer AS amount
                        FROM filtered GROUP BY resistance_source ORDER BY resistance_source
                    ) AS counts
                ), '{{}}'::jsonb) AS resistance_source
        """
        summary = await self._fetch_one(summary_sql, params)
        return items, summary

    async def get_exercise(self, slug: str) -> Row | None:
        return await self._fetch_optional(
            """
            SELECT
                e.slug,
                e.name,
                e.name_full,
                e.body_part::text AS body_part,
                e.target_category::text AS target_category,
                e.mechanics_tier::text AS mechanics_tier,
                e.resistance_source::text AS resistance_source,
                e.execution_pattern::text AS execution_pattern,
                e.created_at,
                e.updated_at,
                eng.load_capacity_kg AS load_capacity,
                eng.systemic_propulsive_fcsa_demand,
                eng.propulsive_fcsa_contribution_vector,
                e.technique,
                e.comments,
                e.video_links,
                eng.slug AS engine_slug,
                eng.propulsive_fcsa_contribution_vector AS engine_propulsive_vector,
                eng.active_tension_exposure_vector AS engine_active_tension_vector,
                eng.etu_vector AS engine_etu_vector,
                eng.muscle_recovery_cost_modifier_vector AS engine_recovery_modifier_vector,
                eng.joint_load_exposure_vector AS engine_joint_load_vector
            FROM core.exercises AS e
            LEFT JOIN engine.exercises AS eng ON eng.slug = e.slug
            WHERE e.slug = %s
            """,
            (slug,),
        )

    async def add_exercise_video(self, *, slug: str, url: str) -> Row | None:
        return await self._fetch_optional(
            """
            UPDATE core.exercises
            SET video_links = CASE
                WHEN %s = ANY(video_links) THEN video_links
                ELSE array_append(video_links, %s)
            END,
            updated_at = CASE
                WHEN %s = ANY(video_links) THEN updated_at
                ELSE now()
            END
            WHERE slug = %s
            RETURNING video_links, updated_at
            """,
            (url, url, url, slug),
        )

    async def list_muscles(
        self,
        *,
        q: str | None,
        body_parts: Sequence[str],
        complexes: Sequence[str],
        sort: str,
        order: str,
        limit: int,
        offset: int,
    ) -> tuple[list[Row], Row]:
        where_sql, params = self._muscle_where(
            q=q,
            body_parts=body_parts,
            complexes=complexes,
        )
        sort_expression = MUSCLE_SORTS[sort]
        direction = "DESC" if order == "desc" else "ASC"
        items_sql = f"""
            SELECT
                m.slug,
                m.name,
                m.body_part::text AS body_part,
                m.complex::text AS complex,
                m.mass_g,
                m.mv_cm3,
                m.fiber_bias_type_i,
                m.fiber_bias_type_ii,
                m.pcsa_projected_fcsa_cm2
            FROM core.muscles AS m
            {where_sql}
            ORDER BY {sort_expression} {direction} NULLS LAST, m.slug ASC
            LIMIT %s OFFSET %s
        """
        items = await self._fetch_all(items_sql, (*params, limit, offset))

        summary_sql = f"""
            WITH filtered AS (
                SELECT m.body_part::text AS body_part, m.complex::text AS complex
                FROM core.muscles AS m
                {where_sql}
            )
            SELECT
                (SELECT COUNT(*)::integer FROM filtered) AS total,
                COALESCE((
                    SELECT jsonb_object_agg(value, amount)
                    FROM (
                        SELECT body_part AS value, COUNT(*)::integer AS amount
                        FROM filtered GROUP BY body_part ORDER BY body_part
                    ) AS counts
                ), '{{}}'::jsonb) AS body_part,
                COALESCE((
                    SELECT jsonb_object_agg(value, amount)
                    FROM (
                        SELECT complex AS value, COUNT(*)::integer AS amount
                        FROM filtered GROUP BY complex ORDER BY complex
                    ) AS counts
                ), '{{}}'::jsonb) AS complex
        """
        summary = await self._fetch_one(summary_sql, params)
        return items, summary

    async def get_muscle(self, slug: str) -> Row | None:
        return await self._fetch_optional(
            """
            SELECT
                m.slug,
                m.name,
                m.body_part::text AS body_part,
                m.complex::text AS complex,
                m.mass_g,
                m.mv_cm3,
                m.mass_reference::text AS mass_reference,
                m.architecture::text AS architecture,
                m.fiber_bias_type_i,
                m.fiber_bias_type_ii,
                m.optimal_fiber_length_cm,
                m.pennation_angle_deg,
                m.pennation_cos,
                m.pcsa,
                m.pcsa_fiber_cm2,
                m.pcsa_projected_fcsa_cm2,
                m.smh_factor::text AS smh_factor,
                m.strength_curve::text AS strength_curve,
                m.leverage_peak::text AS leverage_peak,
                m.bible_markdown,
                m.article_links,
                m.video_links
            FROM core.muscles AS m
            WHERE m.slug = %s
            """,
            (slug,),
        )

    async def measured_related_exercises(
        self,
        *,
        muscle_slug: str,
    ) -> list[Row]:
        return await self._fetch_all(
            """
            SELECT
                e.slug,
                e.name,
                e.name_full,
                e.target_category::text AS target_category,
                e.mechanics_tier::text AS mechanics_tier,
                (eng.etu_vector ->> %s)::double precision AS etu_cm2
            FROM engine.exercises AS eng
            JOIN core.exercises AS e ON e.slug = eng.slug
            WHERE eng.etu_vector ? %s
              AND jsonb_typeof(eng.etu_vector -> %s) = 'number'
            """,
            (muscle_slug, muscle_slug, muscle_slug),
        )

    async def fallback_related_exercises(
        self,
        *,
        target_categories: Sequence[str],
        excluded_slugs: Sequence[str],
    ) -> list[Row]:
        if not target_categories:
            return []
        params: list[Any] = [list(target_categories)]
        excluded_sql = ""
        if excluded_slugs:
            excluded_sql = "AND NOT (e.slug = ANY(%s))"
            params.append(list(excluded_slugs))
        return await self._fetch_all(
            f"""
            SELECT
                e.slug,
                e.name,
                e.name_full,
                e.target_category::text AS target_category,
                e.mechanics_tier::text AS mechanics_tier
            FROM core.exercises AS e
            WHERE e.target_category::text = ANY(%s)
            {excluded_sql}
            """,
            tuple(params),
        )

    async def get_meta(self) -> Row:
        return await self._fetch_one(
            """
            SELECT
                ARRAY(
                    SELECT unnest(enum_range(NULL::core.body_part_enum))::text
                ) AS body_part,
                ARRAY(
                    SELECT unnest(enum_range(NULL::core.target_category_enum))::text
                ) AS target_category,
                ARRAY(
                    SELECT unnest(enum_range(NULL::core.mechanics_tier_enum))::text
                ) AS mechanics_tier,
                ARRAY(
                    SELECT unnest(enum_range(NULL::core.resistance_source_enum))::text
                ) AS resistance_source,
                ARRAY(
                    SELECT unnest(enum_range(NULL::core.muscle_complex_enum))::text
                ) AS muscle_complex,
                (SELECT COUNT(*)::integer FROM core.exercises) AS exercise_count,
                (SELECT COUNT(*)::integer FROM core.muscles) AS muscle_count
            """
        )

    @staticmethod
    def _exercise_where(
        *,
        q: str | None,
        body_parts: Sequence[str],
        target_categories: Sequence[str],
        mechanics_tiers: Sequence[str],
        resistance_sources: Sequence[str],
    ) -> tuple[str, tuple[Any, ...]]:
        clauses: list[str] = []
        params: list[Any] = []
        if q:
            clauses.append("CONCAT_WS(' ', e.name, e.name_full, e.slug) ILIKE %s")
            params.append(f"%{q}%")
        for column, values in (
            ("e.body_part", body_parts),
            ("e.target_category", target_categories),
            ("e.mechanics_tier", mechanics_tiers),
            ("e.resistance_source", resistance_sources),
        ):
            if values:
                clauses.append(f"{column}::text = ANY(%s)")
                params.append(list(values))
        return ("WHERE " + " AND ".join(clauses) if clauses else "", tuple(params))

    @staticmethod
    def _muscle_where(
        *,
        q: str | None,
        body_parts: Sequence[str],
        complexes: Sequence[str],
    ) -> tuple[str, tuple[Any, ...]]:
        clauses: list[str] = []
        params: list[Any] = []
        if q:
            clauses.append("CONCAT_WS(' ', m.name, m.slug) ILIKE %s")
            params.append(f"%{q}%")
        if body_parts:
            clauses.append("m.body_part::text = ANY(%s)")
            params.append(list(body_parts))
        if complexes:
            clauses.append("m.complex::text = ANY(%s)")
            params.append(list(complexes))
        return ("WHERE " + " AND ".join(clauses) if clauses else "", tuple(params))

    async def _fetch_all(
        self,
        query: str,
        params: tuple[Any, ...] | None = None,
    ) -> list[Row]:
        async with self._pool.connection() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(query, params)
                return list(await cursor.fetchall())

    async def _fetch_one(
        self,
        query: str,
        params: tuple[Any, ...] | None = None,
    ) -> Row:
        row = await self._fetch_optional(query, params)
        if row is None:
            raise RuntimeError("Database query unexpectedly returned no rows")
        return row

    async def _fetch_optional(
        self,
        query: str,
        params: tuple[Any, ...] | None = None,
    ) -> Row | None:
        async with self._pool.connection() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(query, params)
                return cast(Row | None, await cursor.fetchone())
