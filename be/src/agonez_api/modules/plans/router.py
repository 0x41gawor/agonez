from typing import Annotated, cast

from fastapi import APIRouter, Body, Depends, Path, Request, Response, status

from agonez_api.modules.plans.analysis.schemas import (
    PlanAIExportResult,
    PlanAnalysisRequest,
    PlanAnalysisResult,
    PlanExportRequest,
)
from agonez_api.modules.plans.analysis.service import PlanAnalysisService
from agonez_api.modules.plans.schemas import (
    PlanCreate,
    PlanDetail,
    PlanDraftArtifact,
    PlanDraftUpdate,
    PlanListResponse,
)
from agonez_api.modules.plans.service import PlanService

router = APIRouter(prefix="/api/plans", tags=["Plans"])
PlanId = Annotated[int, Path(ge=1)]


def get_plan_service(request: Request) -> PlanService:
    return cast(PlanService, request.app.state.plan_service)


def get_plan_analysis_service(request: Request) -> PlanAnalysisService:
    return cast(PlanAnalysisService, request.app.state.plan_analysis_service)


@router.post("", response_model=PlanDraftArtifact, status_code=status.HTTP_201_CREATED)
async def create_plan(
    payload: Annotated[PlanCreate, Body()],
    service: Annotated[PlanService, Depends(get_plan_service)],
) -> PlanDraftArtifact:
    return await service.create_plan(payload)


@router.get("", response_model=PlanListResponse)
async def list_plans(
    service: Annotated[PlanService, Depends(get_plan_service)],
) -> PlanListResponse:
    return await service.list_plans()


@router.get("/{plan_id}", response_model=PlanDetail)
async def get_plan(
    plan_id: PlanId,
    service: Annotated[PlanService, Depends(get_plan_service)],
) -> PlanDetail:
    return await service.get_plan(plan_id)


@router.delete("/{plan_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_plan(
    plan_id: PlanId,
    service: Annotated[PlanService, Depends(get_plan_service)],
) -> Response:
    await service.delete_plan(plan_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/{plan_id}/draft", response_model=PlanDraftArtifact)
async def get_draft(
    plan_id: PlanId,
    service: Annotated[PlanService, Depends(get_plan_service)],
) -> PlanDraftArtifact:
    return await service.get_draft(plan_id)


@router.put("/{plan_id}/draft", response_model=PlanDraftArtifact)
async def save_draft(
    plan_id: PlanId,
    payload: Annotated[PlanDraftUpdate, Body()],
    service: Annotated[PlanService, Depends(get_plan_service)],
) -> PlanDraftArtifact:
    return await service.save_draft(plan_id, payload)


@router.post("/{plan_id}/draft/analysis", response_model=PlanAnalysisResult)
async def analyze_draft(
    plan_id: PlanId,
    payload: Annotated[PlanAnalysisRequest, Body()],
    service: Annotated[PlanAnalysisService, Depends(get_plan_analysis_service)],
) -> PlanAnalysisResult:
    return await service.analyze_draft(plan_id, payload)


@router.post("/{plan_id}/draft/export", response_model=PlanAIExportResult)
async def export_draft(
    plan_id: PlanId,
    payload: Annotated[PlanExportRequest, Body()],
    service: Annotated[PlanAnalysisService, Depends(get_plan_analysis_service)],
) -> PlanAIExportResult:
    return await service.export_draft(plan_id, payload)
