from collections.abc import Sequence
from typing import Any, Literal

from agonez_api.core.media import MediaResolver
from agonez_api.modules.atlas.exceptions import AtlasEntityNotFoundError
from agonez_api.modules.atlas.repository import AtlasRepository, Row
from agonez_api.modules.atlas.schemas import (
    AtlasCounts,
    AtlasMeta,
    ExerciseDetail,
    ExerciseEngine,
    ExerciseFacets,
    ExerciseListItem,
    ExerciseListResponse,
    ExerciseVideoLinks,
    MuscleDetail,
    MuscleFacets,
    MuscleListItem,
    MuscleListResponse,
    RelatedExercise,
    RelatedExerciseResponse,
)
from agonez_api.modules.atlas.youtube import normalize_youtube_url

TARGET_CATEGORIES_BY_COMPLEX: dict[str, tuple[str, ...]] = {
    "Neck": ("Neck",),
    "Shoulder": ("Lateral_Delt", "Anterior_Delt", "Back_3D"),
    "Chest": ("Chest_Clav_AD", "Chest_Sternal"),
    "Back": ("Back_V", "Back_3D", "Upper_Traps", "Serratus"),
    "Biceps": ("Biceps",),
    "Triceps": ("Triceps",),
    "Forearms": ("Forearms",),
    "Core": ("Core",),
    "Glutes": ("Glutes",),
    "Quads": ("Quads",),
    "Hamstrings": ("Hamstrings",),
    "Hip_FA": ("Hip_AF",),
    "Calves": ("Calves",),
    "Shin": ("Tibialis",),
}


class AtlasService:
    def __init__(self, repository: AtlasRepository, media: MediaResolver) -> None:
        self._repository = repository
        self._media = media

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
        page: int,
        per_page: int,
    ) -> ExerciseListResponse:
        rows, summary = await self._repository.list_exercises(
            q=q,
            body_parts=body_parts,
            target_categories=target_categories,
            mechanics_tiers=mechanics_tiers,
            resistance_sources=resistance_sources,
            sort=sort,
            order=order,
            limit=per_page,
            offset=(page - 1) * per_page,
        )
        items = [
            ExerciseListItem(
                **row,
                image_url=self._media.image_url("exercises", row["slug"]),
            )
            for row in rows
        ]
        return ExerciseListResponse(
            items=items,
            total=summary["total"],
            page=page,
            per_page=per_page,
            facets=ExerciseFacets(
                body_part=summary["body_part"],
                target_category=summary["target_category"],
                mechanics_tier=summary["mechanics_tier"],
                resistance_source=summary["resistance_source"],
            ),
        )

    async def get_exercise(self, slug: str) -> ExerciseDetail:
        row = await self._repository.get_exercise(slug)
        if row is None:
            raise AtlasEntityNotFoundError("exercise", slug)
        engine = None
        evaluated_vector_keys = (
            "engine_active_tension_vector",
            "engine_etu_vector",
            "engine_recovery_modifier_vector",
            "engine_joint_load_vector",
        )
        if row["engine_slug"] is not None and any(
            row[key] is not None for key in evaluated_vector_keys
        ):
            engine = ExerciseEngine(
                propulsive_fcsa_contribution_vector=row["engine_propulsive_vector"],
                active_tension_exposure_vector=row["engine_active_tension_vector"],
                etu_vector=row["engine_etu_vector"],
                muscle_recovery_cost_modifier_vector=row["engine_recovery_modifier_vector"],
                joint_load_exposure_vector=row["engine_joint_load_vector"],
            )
        return ExerciseDetail(
            slug=row["slug"],
            name=row["name"],
            name_full=row["name_full"],
            body_part=row["body_part"],
            target_category=row["target_category"],
            mechanics_tier=row["mechanics_tier"],
            resistance_source=row["resistance_source"],
            execution_pattern=row["execution_pattern"],
            load_capacity=row["load_capacity_kg"],
            systemic_propulsive_fcsa_demand=row["systemic_propulsive_fcsa_demand"],
            propulsive_fcsa_contribution_vector=row["propulsive_fcsa_contribution_vector"],
            technique=row["technique"] or {},
            comments=row["comments"] or {},
            video_links=list(row["video_links"] or []),
            image_url=self._media.image_url("exercises", row["slug"]),
            engine=engine,
        )

    async def add_exercise_video(self, *, slug: str, url: str) -> ExerciseVideoLinks:
        exercise = await self._repository.get_exercise(slug)
        if exercise is None:
            raise AtlasEntityNotFoundError("exercise", slug)

        current_links = list(exercise["video_links"] or [])
        for current in current_links:
            try:
                if normalize_youtube_url(current) == url:
                    return ExerciseVideoLinks(video_links=current_links)
            except ValueError:
                continue

        row = await self._repository.add_exercise_video(slug=slug, url=url)
        if row is None:
            raise AtlasEntityNotFoundError("exercise", slug)
        return ExerciseVideoLinks(video_links=list(row["video_links"] or []))

    async def list_muscles(
        self,
        *,
        q: str | None,
        body_parts: Sequence[str],
        complexes: Sequence[str],
        sort: str,
        order: str,
        page: int,
        per_page: int,
    ) -> MuscleListResponse:
        rows, summary = await self._repository.list_muscles(
            q=q,
            body_parts=body_parts,
            complexes=complexes,
            sort=sort,
            order=order,
            limit=per_page,
            offset=(page - 1) * per_page,
        )
        items = [
            MuscleListItem(
                **row,
                display_name=self.display_name(row["slug"]),
                image_url=self._media.image_url("muscles", row["slug"]),
            )
            for row in rows
        ]
        return MuscleListResponse(
            items=items,
            total=summary["total"],
            page=page,
            per_page=per_page,
            facets=MuscleFacets(
                body_part=summary["body_part"],
                complex=summary["complex"],
            ),
        )

    async def get_muscle(self, slug: str) -> MuscleDetail:
        row = await self._repository.get_muscle(slug)
        if row is None:
            raise AtlasEntityNotFoundError("muscle", slug)
        payload = {
            **row,
            "display_name": self.display_name(row["slug"]),
            "article_links": list(row["article_links"] or []),
            "video_links": list(row["video_links"] or []),
            "image_url": self._media.image_url("muscles", row["slug"]),
            "gallery": self._media.gallery_urls("muscles", row["slug"]),
        }
        return MuscleDetail(**payload)

    async def related_exercises(
        self,
        *,
        muscle_slug: str,
        limit: int,
        sort: Literal["etu", "name"],
    ) -> RelatedExerciseResponse:
        muscle = await self._repository.get_muscle(muscle_slug)
        if muscle is None:
            raise AtlasEntityNotFoundError("muscle", muscle_slug)

        capacity = self._as_positive_float(muscle["pcsa_projected_fcsa_cm2"])
        measured_rows = await self._repository.measured_related_exercises(
            muscle_slug=muscle_slug
        )
        measured = [self._measured_relation(row, capacity) for row in measured_rows]
        measured_slugs = [item.slug for item in measured]

        fallback_rows = await self._repository.fallback_related_exercises(
            target_categories=TARGET_CATEGORIES_BY_COMPLEX.get(muscle["complex"], ()),
            excluded_slugs=measured_slugs,
        )
        fallback = [self._fallback_relation(row) for row in fallback_rows]

        if sort == "name":
            items = sorted([*measured, *fallback], key=lambda item: item.name.casefold())
        else:
            measured.sort(key=lambda item: item.etu_cm2 or 0.0, reverse=True)
            fallback.sort(key=lambda item: item.name.casefold())
            items = [*measured, *fallback]
        return RelatedExerciseResponse(items=items[:limit])

    async def get_meta(self) -> AtlasMeta:
        row = await self._repository.get_meta()
        return AtlasMeta(
            body_part=row["body_part"],
            target_category=row["target_category"],
            mechanics_tier=row["mechanics_tier"],
            resistance_source=row["resistance_source"],
            muscle_complex=row["muscle_complex"],
            counts=AtlasCounts(
                exercises=row["exercise_count"],
                muscles=row["muscle_count"],
            ),
        )

    @staticmethod
    def display_name(slug: str) -> str:
        return slug.replace("_", " ").capitalize()

    @staticmethod
    def _as_positive_float(value: Any) -> float | None:
        if value is None:
            return None
        number = float(value)
        return number if number > 0 else None

    @staticmethod
    def _measured_relation(row: Row, capacity: float | None) -> RelatedExercise:
        etu = float(row["etu_cm2"])
        return RelatedExercise(
            slug=row["slug"],
            name=row["name"],
            name_full=row["name_full"],
            target_category=row["target_category"],
            mechanics_tier=row["mechanics_tier"],
            relation="measured",
            etu_cm2=etu,
            normalized_etu=etu / capacity if capacity else None,
        )

    @staticmethod
    def _fallback_relation(row: Row) -> RelatedExercise:
        return RelatedExercise(
            slug=row["slug"],
            name=row["name"],
            name_full=row["name_full"],
            target_category=row["target_category"],
            mechanics_tier=row["mechanics_tier"],
            relation="by_target",
            etu_cm2=None,
            normalized_etu=None,
        )
