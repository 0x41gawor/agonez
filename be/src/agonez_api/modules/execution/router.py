from datetime import date
from typing import Annotated, Any, Literal, cast

from fastapi import APIRouter, Body, Depends, Path, Query, Request, Response, status

from agonez_api.modules.execution.schemas import (
    AnalysisQueue,
    CalendarResponse,
    ErrorEnvelope,
    EventCreate,
    EventDTO,
    EventListResponse,
    EventPatch,
    ExercisePrescriptionPut,
    ExerciseTraceResponse,
    LoadSeriesResponse,
    MicrocyclePatch,
    MicrocycleTimeline,
    NextPrescription,
    PlanRunCreate,
    PlanRunListResponse,
    PlanRunOverview,
    PlanRunPatch,
    PlanRunPreview,
    PlanRunStatus,
    PrescriptionWriteResponse,
    SessionPatch,
    SessionStatusResponse,
    TimelineMicrocycle,
    WorkoutPrescriptionPatch,
    WorkoutPrescriptionResponse,
    WorkoutTraceList,
    WorkoutTraceResponse,
)
from agonez_api.modules.execution.service import ExecutionService

router = APIRouter(prefix="/api/v1/exec", tags=["Execution"])
Identifier = Annotated[int, Path(ge=1)]
ERROR_RESPONSES: dict[int | str, dict[str, Any]] = {
    404: {"model": ErrorEnvelope, "description": "Execution resource not found"},
    409: {"model": ErrorEnvelope, "description": "Execution state conflict"},
    422: {"model": ErrorEnvelope, "description": "Execution request validation failed"},
}


def get_execution_service(request: Request) -> ExecutionService:
    return cast(ExecutionService, request.app.state.execution_service)


@router.get("/plan-runs", response_model=PlanRunListResponse, responses=ERROR_RESPONSES)
async def list_plan_runs(
    service: Annotated[ExecutionService, Depends(get_execution_service)],
    status_filter: Annotated[
        list[PlanRunStatus] | None,
        Query(alias="status"),
    ] = None,
    limit: Annotated[int, Query()] = 50,
) -> PlanRunListResponse:
    return await service.list_plan_runs(
        statuses=tuple(item.value for item in status_filter or []),
        limit=limit,
    )


@router.get(
    "/plan-runs/preview",
    response_model=PlanRunPreview,
    responses=ERROR_RESPONSES,
)
async def preview_plan_run(
    service: Annotated[ExecutionService, Depends(get_execution_service)],
    plan_revision_id: Annotated[int, Query(ge=1)],
    starts_on: Annotated[date, Query()],
    microcycle_count: Annotated[int, Query()],
) -> PlanRunPreview:
    return await service.preview_plan_run(
        plan_revision_id=plan_revision_id,
        starts_on=starts_on,
        microcycle_count=microcycle_count,
    )


@router.post(
    "/plan-runs",
    response_model=PlanRunOverview,
    status_code=status.HTTP_201_CREATED,
    responses=ERROR_RESPONSES,
)
async def create_plan_run(
    payload: Annotated[PlanRunCreate, Body()],
    service: Annotated[ExecutionService, Depends(get_execution_service)],
) -> PlanRunOverview:
    return await service.create_plan_run(payload)


@router.get(
    "/plan-runs/{plan_run_id}/overview",
    response_model=PlanRunOverview,
    responses=ERROR_RESPONSES,
)
async def get_plan_run_overview(
    plan_run_id: Identifier,
    service: Annotated[ExecutionService, Depends(get_execution_service)],
) -> PlanRunOverview:
    return await service.get_overview(plan_run_id)


@router.patch(
    "/plan-runs/{plan_run_id}",
    response_model=PlanRunOverview,
    responses=ERROR_RESPONSES,
)
async def update_plan_run(
    plan_run_id: Identifier,
    payload: Annotated[PlanRunPatch, Body()],
    service: Annotated[ExecutionService, Depends(get_execution_service)],
) -> PlanRunOverview:
    return await service.update_plan_run(plan_run_id, payload)


@router.get(
    "/plan-runs/{plan_run_id}/analysis/queue",
    response_model=AnalysisQueue,
    responses=ERROR_RESPONSES,
)
async def get_analysis_queue(
    plan_run_id: Identifier,
    service: Annotated[ExecutionService, Depends(get_execution_service)],
    target_microcycle: Annotated[int | None, Query(ge=1)] = None,
) -> AnalysisQueue:
    return await service.get_analysis_queue(
        plan_run_id,
        target_microcycle=target_microcycle,
    )


@router.get(
    "/plan-runs/{plan_run_id}/exercise-traces/{exercise_trace_id}",
    response_model=ExerciseTraceResponse,
    responses=ERROR_RESPONSES,
)
async def get_exercise_trace(
    plan_run_id: Identifier,
    exercise_trace_id: Identifier,
    service: Annotated[ExecutionService, Depends(get_execution_service)],
    include_next: Annotated[bool, Query()] = True,
) -> ExerciseTraceResponse:
    return await service.get_exercise_trace(
        plan_run_id,
        exercise_trace_id,
        include_next=include_next,
    )


@router.get(
    "/plan-runs/{plan_run_id}/exercise-traces/{exercise_trace_id}/next",
    response_model=NextPrescription,
    responses=ERROR_RESPONSES,
)
async def get_next_prescription(
    plan_run_id: Identifier,
    exercise_trace_id: Identifier,
    service: Annotated[ExecutionService, Depends(get_execution_service)],
) -> dict[str, object]:
    return await service.get_next_prescription(plan_run_id, exercise_trace_id)


@router.put(
    "/plan-runs/{plan_run_id}/sessions/{session_id}/exercise-prescriptions/{exercise_trace_id}",
    response_model=PrescriptionWriteResponse,
    responses=ERROR_RESPONSES,
)
async def save_exercise_prescription(
    plan_run_id: Identifier,
    session_id: Identifier,
    exercise_trace_id: Identifier,
    payload: Annotated[ExercisePrescriptionPut, Body()],
    service: Annotated[ExecutionService, Depends(get_execution_service)],
) -> PrescriptionWriteResponse:
    return await service.save_exercise_prescription(
        plan_run_id=plan_run_id,
        session_id=session_id,
        exercise_track_id=exercise_trace_id,
        payload=payload,
    )


@router.delete(
    "/plan-runs/{plan_run_id}/sessions/{session_id}/exercise-prescriptions/{exercise_trace_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    responses=ERROR_RESPONSES,
)
async def delete_exercise_prescription(
    plan_run_id: Identifier,
    session_id: Identifier,
    exercise_trace_id: Identifier,
    service: Annotated[ExecutionService, Depends(get_execution_service)],
) -> Response:
    await service.delete_exercise_prescription(
        plan_run_id=plan_run_id,
        session_id=session_id,
        exercise_track_id=exercise_trace_id,
    )
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.patch(
    "/plan-runs/{plan_run_id}/sessions/{session_id}/prescription",
    response_model=WorkoutPrescriptionResponse,
    responses=ERROR_RESPONSES,
)
async def update_workout_prescription(
    plan_run_id: Identifier,
    session_id: Identifier,
    payload: Annotated[WorkoutPrescriptionPatch, Body()],
    service: Annotated[ExecutionService, Depends(get_execution_service)],
) -> WorkoutPrescriptionResponse:
    return await service.update_workout_prescription_comment(
        plan_run_id=plan_run_id,
        session_id=session_id,
        payload=payload,
    )


@router.get(
    "/plan-runs/{plan_run_id}/workout-traces",
    response_model=WorkoutTraceList,
    responses=ERROR_RESPONSES,
)
async def list_workout_traces(
    plan_run_id: Identifier,
    service: Annotated[ExecutionService, Depends(get_execution_service)],
) -> WorkoutTraceList:
    return await service.list_workout_traces(plan_run_id)


@router.get(
    "/plan-runs/{plan_run_id}/workout-traces/{workout_trace_id}",
    response_model=WorkoutTraceResponse,
    responses=ERROR_RESPONSES,
)
async def get_workout_trace(
    plan_run_id: Identifier,
    workout_trace_id: Identifier,
    service: Annotated[ExecutionService, Depends(get_execution_service)],
) -> WorkoutTraceResponse:
    return await service.get_workout_trace(plan_run_id, workout_trace_id)


@router.get(
    "/plan-runs/{plan_run_id}/microcycles",
    response_model=MicrocycleTimeline,
    responses=ERROR_RESPONSES,
)
async def get_microcycles(
    plan_run_id: Identifier,
    service: Annotated[ExecutionService, Depends(get_execution_service)],
) -> MicrocycleTimeline:
    return await service.get_microcycles(plan_run_id)


@router.patch(
    "/plan-runs/{plan_run_id}/microcycles/{ordinal}",
    response_model=TimelineMicrocycle,
    responses=ERROR_RESPONSES,
)
async def update_microcycle(
    plan_run_id: Identifier,
    ordinal: Identifier,
    payload: Annotated[MicrocyclePatch, Body()],
    service: Annotated[ExecutionService, Depends(get_execution_service)],
) -> TimelineMicrocycle:
    return await service.update_microcycle(
        plan_run_id=plan_run_id,
        ordinal=ordinal,
        payload=payload,
    )


@router.get(
    "/plan-runs/{plan_run_id}/calendar",
    response_model=CalendarResponse,
    responses=ERROR_RESPONSES,
)
async def get_calendar(
    plan_run_id: Identifier,
    service: Annotated[ExecutionService, Depends(get_execution_service)],
    from_date: Annotated[date | None, Query(alias="from")] = None,
    to_date: Annotated[date | None, Query(alias="to")] = None,
) -> CalendarResponse:
    return await service.get_calendar(
        plan_run_id,
        from_date=from_date,
        to_date=to_date,
    )


@router.patch(
    "/plan-runs/{plan_run_id}/sessions/{session_id}",
    response_model=SessionStatusResponse,
    responses=ERROR_RESPONSES,
)
async def update_session_status(
    plan_run_id: Identifier,
    session_id: Identifier,
    payload: Annotated[SessionPatch, Body()],
    service: Annotated[ExecutionService, Depends(get_execution_service)],
) -> SessionStatusResponse:
    return await service.update_session_status(
        plan_run_id=plan_run_id,
        session_id=session_id,
        payload=payload,
    )


@router.get(
    "/plan-runs/{plan_run_id}/events",
    response_model=EventListResponse,
    responses=ERROR_RESPONSES,
)
async def list_events(
    plan_run_id: Identifier,
    service: Annotated[ExecutionService, Depends(get_execution_service)],
    event_types: Annotated[list[str] | None, Query(alias="type")] = None,
    microcycle: Annotated[int | None, Query(ge=1)] = None,
    cursor: Annotated[str | None, Query()] = None,
    limit: Annotated[int, Query()] = 50,
) -> EventListResponse:
    return await service.list_events(
        plan_run_id,
        types=tuple(event_types or []),
        microcycle=microcycle,
        cursor=cursor,
        limit=limit,
    )


@router.post(
    "/plan-runs/{plan_run_id}/events",
    response_model=EventDTO,
    status_code=status.HTTP_201_CREATED,
    responses=ERROR_RESPONSES,
)
async def create_event(
    plan_run_id: Identifier,
    payload: Annotated[EventCreate, Body()],
    service: Annotated[ExecutionService, Depends(get_execution_service)],
) -> EventDTO:
    return await service.create_event(plan_run_id, payload)


@router.patch(
    "/plan-runs/{plan_run_id}/events/{event_id}",
    response_model=EventDTO,
    responses=ERROR_RESPONSES,
)
async def update_event(
    plan_run_id: Identifier,
    event_id: Identifier,
    payload: Annotated[EventPatch, Body()],
    service: Annotated[ExecutionService, Depends(get_execution_service)],
) -> EventDTO:
    return await service.update_event(
        plan_run_id=plan_run_id,
        event_id=event_id,
        payload=payload,
    )


@router.delete(
    "/plan-runs/{plan_run_id}/events/{event_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    responses=ERROR_RESPONSES,
)
async def delete_event(
    plan_run_id: Identifier,
    event_id: Identifier,
    service: Annotated[ExecutionService, Depends(get_execution_service)],
) -> Response:
    await service.delete_event(plan_run_id=plan_run_id, event_id=event_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get(
    "/plan-runs/{plan_run_id}/load-series",
    response_model=LoadSeriesResponse,
    responses=ERROR_RESPONSES,
)
async def get_load_series(
    plan_run_id: Identifier,
    service: Annotated[ExecutionService, Depends(get_execution_service)],
    metric: Annotated[
        Literal["top_set_load", "mean_set_load", "volume_load"], Query()
    ] = "top_set_load",
    normalize: Annotated[Literal["none", "first_exposure"], Query()] = "none",
    workout_trace_id: Annotated[list[int] | None, Query()] = None,
    exercise_trace_id: Annotated[list[int] | None, Query()] = None,
    include_draft: Annotated[bool, Query()] = False,
    x: Annotated[Literal["microcycle", "date"], Query()] = "microcycle",
) -> LoadSeriesResponse:
    return await service.get_load_series(
        plan_run_id,
        metric=metric,
        normalize=normalize,
        workout_track_ids=tuple(workout_trace_id or []),
        exercise_track_ids=tuple(exercise_trace_id or []),
        include_draft=include_draft,
        x_axis=x,
    )
