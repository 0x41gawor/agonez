from datetime import date
from typing import Annotated, Any, cast
from uuid import UUID

from fastapi import APIRouter, Body, Depends, Header, Path, Query, Request, Response, status

from agonez_api.modules.atlas.router import ContentLocaleDependency
from agonez_api.modules.execution.schemas import ErrorEnvelope
from agonez_api.modules.mobile_execution.schemas import (
    ActiveWorkoutSummary,
    AtlasPeek,
    AtlasSearchResponse,
    ClaimWorkout,
    FinalizeResponse,
    FinalizeWorkout,
    MobileContext,
    OperationBatch,
    OperationBatchResponse,
    PlanRunCompact,
    StartWorkout,
    WorkoutPrescription,
    WorkoutSnapshot,
)
from agonez_api.modules.mobile_execution.service import MobileExecutionService, etag_for

router = APIRouter(prefix="/api/v1/mobile", tags=["Mobile Execution"])
ERROR_RESPONSES: dict[int | str, dict[str, Any]] = {
    404: {"model": ErrorEnvelope, "description": "Mobile execution resource not found"},
    409: {"model": ErrorEnvelope, "description": "Mobile execution state conflict"},
    422: {"model": ErrorEnvelope, "description": "Mobile execution validation failed"},
}
WorkoutId = Annotated[UUID, Path()]


def get_mobile_service(request: Request) -> MobileExecutionService:
    return cast(MobileExecutionService, request.app.state.mobile_execution_service)


MobileServiceDependency = Annotated[MobileExecutionService, Depends(get_mobile_service)]
DeviceId = Annotated[UUID, Header(alias="X-Agonez-Device-Id")]
ClientInfo = Annotated[str | None, Header(alias="X-Agonez-Client")]


def _conditional(response: Response, if_none_match: str | None, model: Any) -> Any:
    etag = etag_for(model)
    response.headers["ETag"] = etag
    response.headers["Vary"] = "Accept-Language, X-Agonez-Device-Id"
    if if_none_match == etag:
        headers = {
            "ETag": etag,
            "Vary": "Accept-Language, X-Agonez-Device-Id",
        }
        content_language = response.headers.get("Content-Language")
        if content_language is not None:
            headers["Content-Language"] = content_language
        return Response(status_code=status.HTTP_304_NOT_MODIFIED, headers=headers)
    return model


@router.get("/context", response_model=MobileContext, responses=ERROR_RESPONSES)
async def get_context(
    response: Response,
    service: MobileServiceDependency,
    device_id: DeviceId,
    locale: ContentLocaleDependency,
    plan_run_id: Annotated[int | None, Query(ge=1)] = None,
    requested_date: Annotated[date | None, Query(alias="date")] = None,
    if_none_match: Annotated[str | None, Header(alias="If-None-Match")] = None,
    client: ClientInfo = None,
) -> Any:
    del client
    model = await service.get_context(
        plan_run_id=plan_run_id,
        as_of=requested_date,
        device_id=device_id,
        locale=locale,
    )
    return _conditional(response, if_none_match, model)


@router.get("/plan-runs", response_model=list[PlanRunCompact], responses=ERROR_RESPONSES)
async def list_plan_runs(
    service: MobileServiceDependency,
    device_id: DeviceId,
    as_of: Annotated[date | None, Query(alias="date")] = None,
    client: ClientInfo = None,
) -> list[PlanRunCompact]:
    del device_id, client
    return await service.list_plan_runs(as_of=as_of)


@router.get(
    "/sessions/{session_id}/prescription",
    response_model=WorkoutPrescription,
    responses=ERROR_RESPONSES,
)
async def get_prescription(
    session_id: Annotated[int, Path(ge=1)],
    service: MobileServiceDependency,
    device_id: DeviceId,
    locale: ContentLocaleDependency,
    client: ClientInfo = None,
) -> WorkoutPrescription:
    del device_id, client
    return await service.get_prescription(session_id, locale=locale)


@router.post(
    "/workouts",
    response_model=WorkoutSnapshot,
    status_code=status.HTTP_201_CREATED,
    responses=ERROR_RESPONSES,
)
async def start_workout(
    response: Response,
    payload: Annotated[StartWorkout, Body()],
    service: MobileServiceDependency,
    device_id: DeviceId,
    locale: ContentLocaleDependency,
    client: ClientInfo = None,
) -> WorkoutSnapshot:
    del client
    snapshot, created = await service.start_workout(payload, device_id=device_id, locale=locale)
    response.status_code = status.HTTP_201_CREATED if created else status.HTTP_200_OK
    return snapshot


@router.get(
    "/workouts/active",
    response_model=ActiveWorkoutSummary,
    responses=ERROR_RESPONSES,
)
async def get_active_workout(
    service: MobileServiceDependency,
    device_id: DeviceId,
    locale: ContentLocaleDependency,
    plan_run_id: Annotated[int, Query(ge=1)],
    client: ClientInfo = None,
) -> ActiveWorkoutSummary:
    del client
    return await service.get_active(plan_run_id=plan_run_id, device_id=device_id, locale=locale)


@router.get(
    "/workouts/{workout_id}",
    response_model=WorkoutSnapshot,
    responses=ERROR_RESPONSES,
)
async def get_workout(
    workout_id: WorkoutId,
    response: Response,
    service: MobileServiceDependency,
    device_id: DeviceId,
    locale: ContentLocaleDependency,
    if_none_match: Annotated[str | None, Header(alias="If-None-Match")] = None,
    client: ClientInfo = None,
) -> Any:
    del client
    model = await service.get_workout(workout_id, device_id=device_id, locale=locale)
    return _conditional(response, if_none_match, model)


@router.post(
    "/workouts/{workout_id}/claim",
    response_model=WorkoutSnapshot,
    responses=ERROR_RESPONSES,
)
async def claim_workout(
    workout_id: WorkoutId,
    payload: Annotated[ClaimWorkout, Body()],
    service: MobileServiceDependency,
    device_id: DeviceId,
    locale: ContentLocaleDependency,
    client: ClientInfo = None,
) -> WorkoutSnapshot:
    del client
    return await service.claim_workout(workout_id, payload, device_id=device_id, locale=locale)


@router.post(
    "/workouts/{workout_id}/ops",
    response_model=OperationBatchResponse,
    responses=ERROR_RESPONSES,
)
async def apply_workout_operations(
    workout_id: WorkoutId,
    payload: Annotated[OperationBatch, Body()],
    service: MobileServiceDependency,
    device_id: DeviceId,
    client: ClientInfo = None,
) -> OperationBatchResponse:
    del client
    return await service.apply_operations(workout_id, payload, device_id=device_id)


@router.post(
    "/workouts/{workout_id}/finalize",
    response_model=FinalizeResponse,
    responses=ERROR_RESPONSES,
)
async def finalize_workout(
    workout_id: WorkoutId,
    payload: Annotated[FinalizeWorkout, Body()],
    service: MobileServiceDependency,
    device_id: DeviceId,
    client: ClientInfo = None,
) -> FinalizeResponse:
    del client
    return await service.finalize_workout(workout_id, payload, device_id=device_id)


@router.get(
    "/atlas/exercises/{exercise_id}/peek",
    response_model=AtlasPeek,
    responses=ERROR_RESPONSES,
)
async def get_atlas_peek(
    exercise_id: Annotated[int, Path(ge=1)],
    service: MobileServiceDependency,
    device_id: DeviceId,
    locale: ContentLocaleDependency,
    client: ClientInfo = None,
) -> AtlasPeek:
    del device_id, client
    return await service.get_atlas_peek(exercise_id, locale=locale)


@router.get(
    "/atlas/exercises",
    response_model=AtlasSearchResponse,
    responses=ERROR_RESPONSES,
)
async def search_atlas(
    service: MobileServiceDependency,
    device_id: DeviceId,
    locale: ContentLocaleDependency,
    q: Annotated[str | None, Query(min_length=1, max_length=255)] = None,
    limit: Annotated[int, Query(ge=1, le=30)] = 30,
    plan_run_id: Annotated[int | None, Query(ge=1)] = None,
    client: ClientInfo = None,
) -> AtlasSearchResponse:
    del device_id, client
    return await service.search_atlas(
        q=q.strip() if q else None,
        limit=limit,
        plan_run_id=plan_run_id,
        locale=locale,
    )
