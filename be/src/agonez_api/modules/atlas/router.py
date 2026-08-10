from typing import Annotated, Literal, cast

from fastapi import APIRouter, Depends, Path, Query, Request

from agonez_api.modules.atlas.schemas import (
    AtlasMeta,
    ExerciseDetail,
    ExerciseListResponse,
    MuscleDetail,
    MuscleListResponse,
    RelatedExerciseResponse,
)
from agonez_api.modules.atlas.service import AtlasService

router = APIRouter(prefix="/api/atlas", tags=["Atlas"])
Slug = Annotated[
    str,
    Path(pattern=r"^[a-z0-9]+(?:_[a-z0-9]+)*$", min_length=1, max_length=100),
]


def get_atlas_service(request: Request) -> AtlasService:
    return cast(AtlasService, request.app.state.atlas_service)


AtlasServiceDependency = Annotated[AtlasService, Depends(get_atlas_service)]


@router.get("/exercises", response_model=ExerciseListResponse)
async def list_exercises(
    service: AtlasServiceDependency,
    q: Annotated[str | None, Query(min_length=1, max_length=255)] = None,
    body_part: Annotated[list[str] | None, Query()] = None,
    target_category: Annotated[list[str] | None, Query()] = None,
    mechanics_tier: Annotated[list[str] | None, Query()] = None,
    resistance_source: Annotated[list[str] | None, Query()] = None,
    sort: Literal[
        "name",
        "name_full",
        "load_capacity",
        "systemic_propulsive_fcsa_demand",
    ] = "name",
    order: Literal["asc", "desc"] = "asc",
    page: Annotated[int, Query(ge=1)] = 1,
    per_page: Annotated[int, Query(ge=1, le=100)] = 50,
) -> ExerciseListResponse:
    return await service.list_exercises(
        q=q.strip() if q else None,
        body_parts=body_part or (),
        target_categories=target_category or (),
        mechanics_tiers=mechanics_tier or (),
        resistance_sources=resistance_source or (),
        sort=sort,
        order=order,
        page=page,
        per_page=per_page,
    )


@router.get("/exercises/{slug}", response_model=ExerciseDetail)
async def get_exercise(slug: Slug, service: AtlasServiceDependency) -> ExerciseDetail:
    return await service.get_exercise(slug)


@router.get("/muscles", response_model=MuscleListResponse)
async def list_muscles(
    service: AtlasServiceDependency,
    q: Annotated[str | None, Query(min_length=1, max_length=255)] = None,
    body_part: Annotated[list[str] | None, Query()] = None,
    complex: Annotated[list[str] | None, Query()] = None,
    sort: Literal[
        "name",
        "mass_g",
        "mv_cm3",
        "fiber_bias_type_ii",
        "pcsa_fiber_cm2",
        "pcsa_projected_fcsa_cm2",
    ] = "name",
    order: Literal["asc", "desc"] = "asc",
    page: Annotated[int, Query(ge=1)] = 1,
    per_page: Annotated[int, Query(ge=1, le=100)] = 50,
) -> MuscleListResponse:
    return await service.list_muscles(
        q=q.strip() if q else None,
        body_parts=body_part or (),
        complexes=complex or (),
        sort=sort,
        order=order,
        page=page,
        per_page=per_page,
    )


@router.get("/muscles/{slug}/exercises", response_model=RelatedExerciseResponse)
async def get_related_exercises(
    slug: Slug,
    service: AtlasServiceDependency,
    limit: Annotated[int, Query(ge=1, le=50)] = 8,
    sort: Literal["etu", "name"] = "etu",
) -> RelatedExerciseResponse:
    return await service.related_exercises(muscle_slug=slug, limit=limit, sort=sort)


@router.get("/muscles/{slug}", response_model=MuscleDetail)
async def get_muscle(slug: Slug, service: AtlasServiceDependency) -> MuscleDetail:
    return await service.get_muscle(slug)


@router.get("/meta", response_model=AtlasMeta)
async def get_meta(service: AtlasServiceDependency) -> AtlasMeta:
    return await service.get_meta()
