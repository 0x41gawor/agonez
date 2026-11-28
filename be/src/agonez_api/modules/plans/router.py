from typing import Annotated, cast

from fastapi import APIRouter, Body, Depends, Header, Path, Request, Response, status

from agonez_api.core.localization import negotiate_content_locale
from agonez_api.modules.plans.analysis.schemas import (
    PlanAIExportResult,
    PlanAIImportDocument,
    PlanAnalysisRequest,
    PlanAnalysisResult,
    PlanExportRequest,
)
from agonez_api.modules.plans.analysis.service import PlanAnalysisService
from agonez_api.modules.plans.images import MAX_IMAGE_BYTES
from agonez_api.modules.plans.schemas import (
    PlanCreate,
    PlanDetail,
    PlanDraftArtifact,
    PlanDraftUpdate,
    PlanDuplicateRequest,
    PlanImageWritten,
    PlanListResponse,
    ProgressionModelCatalogResponse,
)
from agonez_api.modules.plans.service import PlanService

router = APIRouter(prefix="/api/plans", tags=["Plans"])
PlanId = Annotated[int, Path(ge=1)]


def get_plan_service(request: Request) -> PlanService:
    return cast(PlanService, request.app.state.plan_service)


def get_plan_analysis_service(request: Request) -> PlanAnalysisService:
    return cast(PlanAnalysisService, request.app.state.plan_analysis_service)


def get_content_locale(
    response: Response,
    accept_language: Annotated[str | None, Header(alias="Accept-Language")] = None,
) -> str:
    locale = negotiate_content_locale(accept_language)
    response.headers["Content-Language"] = locale
    response.headers["Vary"] = "Accept-Language"
    return locale


ContentLocaleDependency = Annotated[str, Depends(get_content_locale)]


@router.post("", response_model=PlanDraftArtifact, status_code=status.HTTP_201_CREATED)
async def create_plan(
    payload: Annotated[PlanCreate, Body()],
    service: Annotated[PlanService, Depends(get_plan_service)],
) -> PlanDraftArtifact:
    return await service.create_plan(payload)


@router.post("/import", response_model=PlanDraftArtifact, status_code=status.HTTP_201_CREATED)
async def import_plan(
    payload: Annotated[PlanAIImportDocument, Body()],
    service: Annotated[PlanService, Depends(get_plan_service)],
) -> PlanDraftArtifact:
    return await service.import_plan(payload)


@router.get("", response_model=PlanListResponse)
async def list_plans(
    service: Annotated[PlanService, Depends(get_plan_service)],
) -> PlanListResponse:
    return await service.list_plans()


@router.get(
    "/catalog/progression-models",
    response_model=ProgressionModelCatalogResponse,
)
async def list_progression_models(
    service: Annotated[PlanService, Depends(get_plan_service)],
    locale: ContentLocaleDependency,
) -> ProgressionModelCatalogResponse:
    return await service.list_progression_models(locale=locale)


@router.post(
    "/{plan_id}/duplicate",
    response_model=PlanDraftArtifact,
    status_code=status.HTTP_201_CREATED,
    description=(
        "Copy one revision of a plan (default: its draft) into a new library plan with fresh "
        "progression ids and the same cover. The body is optional. Duplicating a run plan "
        "saves it to My Plans: the new plan's source_plan_id is the run plan. A "
        "source_revision_id that is not a revision of this plan is refused (422)."
    ),
)
async def duplicate_plan(
    plan_id: PlanId,
    service: Annotated[PlanService, Depends(get_plan_service)],
    payload: Annotated[PlanDuplicateRequest | None, Body()] = None,
) -> PlanDraftArtifact:
    return await service.duplicate_plan(plan_id, payload)


@router.get("/{plan_id}", response_model=PlanDetail)
async def get_plan(
    plan_id: PlanId,
    service: Annotated[PlanService, Depends(get_plan_service)],
) -> PlanDetail:
    return await service.get_plan(plan_id)


@router.delete(
    "/{plan_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    description=(
        "Delete a library plan with its revisions and cover image. A run plan is deleted "
        "only together with its plan run (409), and so is a library plan whose revisions a "
        "plan run still uses (409)."
    ),
)
async def delete_plan(
    plan_id: PlanId,
    service: Annotated[PlanService, Depends(get_plan_service)],
) -> Response:
    await service.delete_plan(plan_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get(
    "/{plan_id}/image",
    response_class=Response,
    responses={
        200: {"content": {"image/webp": {}, "image/png": {}, "image/jpeg": {}}},
        304: {"description": "The cached image is current"},
    },
)
async def get_plan_image(
    plan_id: PlanId,
    service: Annotated[PlanService, Depends(get_plan_service)],
    if_none_match: Annotated[str | None, Header(alias="If-None-Match")] = None,
) -> Response:
    image = await service.get_plan_image(plan_id)
    etag = f'"{image["checksum"]}"'
    # The URL carries the checksum, so a cached body is only ever the right one.
    headers = {"ETag": etag, "Cache-Control": "private, max-age=31536000, immutable"}
    if if_none_match and etag in {value.strip() for value in if_none_match.split(",")}:
        return Response(status_code=status.HTTP_304_NOT_MODIFIED, headers=headers)
    return Response(
        content=bytes(image["data"]),
        media_type=cast(str, image["content_type"]),
        headers=headers,
    )


@router.put(
    "/{plan_id}/image",
    response_model=PlanImageWritten,
    description=(
        "Replace the plan's cover image. The body is the image itself; supported types "
        f"are image/webp, image/png and image/jpeg, up to {MAX_IMAGE_BYTES} bytes."
    ),
)
async def put_plan_image(
    plan_id: PlanId,
    request: Request,
    service: Annotated[PlanService, Depends(get_plan_service)],
) -> PlanImageWritten:
    """Replace the plan's cover image.

    The image is the whole request body rather than a multipart part: one file, no
    other fields, and no extra dependency to parse it.
    """
    body = await request.body()
    return await service.save_plan_image(
        plan_id,
        content_type=request.headers.get("Content-Type"),
        data=body,
    )


@router.delete("/{plan_id}/image", status_code=status.HTTP_204_NO_CONTENT)
async def delete_plan_image(
    plan_id: PlanId,
    service: Annotated[PlanService, Depends(get_plan_service)],
) -> Response:
    await service.delete_plan_image(plan_id)
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
