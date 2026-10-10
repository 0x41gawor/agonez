import logging
import time
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Any
from uuid import uuid4

from fastapi import FastAPI, HTTPException, Request
from fastapi.encoders import jsonable_encoder
from fastapi.exception_handlers import request_validation_exception_handler
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

from agonez_api.core.config import Settings, get_settings
from agonez_api.core.database import (
    DatabasePool,
    create_database_pool,
    open_database_pool,
)
from agonez_api.core.logging import configure_logging
from agonez_api.core.media import MediaResolver
from agonez_api.modules.atlas.exceptions import AtlasEntityNotFoundError
from agonez_api.modules.atlas.repository import AtlasRepository
from agonez_api.modules.atlas.router import router as atlas_router
from agonez_api.modules.atlas.service import AtlasService
from agonez_api.modules.execution.errors import ExecutionAPIError
from agonez_api.modules.execution.repository import ExecutionRepository
from agonez_api.modules.execution.router import router as execution_router
from agonez_api.modules.execution.service import ExecutionService
from agonez_api.modules.mobile_execution.repository import MobileExecutionRepository
from agonez_api.modules.mobile_execution.router import router as mobile_execution_router
from agonez_api.modules.mobile_execution.service import MobileExecutionService
from agonez_api.modules.plans.analysis.service import PlanAnalysisService
from agonez_api.modules.plans.exceptions import (
    PlanConflictError,
    PlanDomainValidationError,
    PlanDraftNotFoundError,
    PlanNotFoundError,
)
from agonez_api.modules.plans.repository import PlanRepository
from agonez_api.modules.plans.router import router as plans_router
from agonez_api.modules.plans.service import PlanService
from agonez_api.modules.waitlist.router import router as waitlist_router
from agonez_api.modules.waitlist.store import WaitlistStore

logger = logging.getLogger(__name__)


def create_app(
    *,
    settings: Settings | None = None,
    pool: DatabasePool | None = None,
) -> FastAPI:
    settings = settings or get_settings()
    configure_logging(settings.log_level)

    owns_pool = pool is None
    database_pool = pool or create_database_pool(settings)
    repository = AtlasRepository(database_pool)
    plan_repository = PlanRepository(database_pool)
    execution_repository = ExecutionRepository(database_pool)
    mobile_execution_repository = MobileExecutionRepository(database_pool)
    media = MediaResolver(
        root=settings.media_root,
        url_prefix=settings.media_url_prefix,
        public_base_url=settings.public_media_base_url,
    )
    service = AtlasService(repository, media)
    plan_service = PlanService(plan_repository)
    plan_analysis_service = PlanAnalysisService(plan_repository)
    execution_service = ExecutionService(execution_repository)
    mobile_execution_service = MobileExecutionService(mobile_execution_repository)
    waitlist_store = WaitlistStore(settings.waitlist_path)

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        if not owns_pool:
            yield
            return
        logger.info("Opening database connection pool")
        async with open_database_pool(
            database_pool,
            wait_seconds=settings.db_startup_wait_seconds,
        ):
            yield

    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description=(
            "REST API for the Agonez exercise and muscle Atlas and the relational "
            "PlanCreator draft editor and the desktop Execution workflow API. "
            "It also provides the offline-first mobile workout execution API. "
            "Authentication and ownership are intentionally deferred."
        ),
        lifespan=lifespan,
    )
    app.state.settings = settings
    app.state.database_pool = database_pool
    app.state.atlas_repository = repository
    app.state.atlas_service = service
    app.state.plan_repository = plan_repository
    app.state.plan_service = plan_service
    app.state.plan_analysis_service = plan_analysis_service
    app.state.execution_repository = execution_repository
    app.state.execution_service = execution_service
    app.state.mobile_execution_repository = mobile_execution_repository
    app.state.mobile_execution_service = mobile_execution_service
    app.state.waitlist_store = waitlist_store

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=False,
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
        allow_headers=[
            "Accept",
            "Accept-Language",
            "Content-Type",
            "If-None-Match",
            "X-Agonez-Client",
            "X-Agonez-Device-Id",
            "X-Request-ID",
        ],
        expose_headers=["Content-Language", "ETag", "X-Request-ID"],
    )

    @app.middleware("http")
    async def request_logging(request: Request, call_next: Any) -> Any:
        request_id = request.headers.get("X-Request-ID") or str(uuid4())
        started = time.perf_counter()
        status_code = 500
        try:
            response = await call_next(request)
            status_code = response.status_code
            response.headers["X-Request-ID"] = request_id
            return response
        finally:
            logger.info(
                "HTTP request",
                extra={
                    "request_id": request_id,
                    "method": request.method,
                    "path": request.url.path,
                    "status_code": status_code,
                    "duration_ms": round((time.perf_counter() - started) * 1000, 2),
                },
            )

    @app.exception_handler(AtlasEntityNotFoundError)
    async def handle_not_found(
        request: Request,
        exc: AtlasEntityNotFoundError,
    ) -> JSONResponse:
        del request
        return JSONResponse(
            status_code=404,
            content={"detail": f"{exc.entity.capitalize()} '{exc.slug}' was not found"},
        )

    async def handle_plan_not_found(
        request: Request,
        exc: Exception,
    ) -> JSONResponse:
        del request
        return JSONResponse(status_code=404, content={"detail": str(exc)})

    app.add_exception_handler(PlanNotFoundError, handle_plan_not_found)
    app.add_exception_handler(PlanDraftNotFoundError, handle_plan_not_found)

    @app.exception_handler(PlanConflictError)
    async def handle_plan_conflict(
        request: Request,
        exc: PlanConflictError,
    ) -> JSONResponse:
        del request
        return JSONResponse(
            status_code=409,
            content={
                "detail": str(exc),
                "submitted_lock_version": exc.submitted_lock_version,
                "current_lock_version": exc.current_lock_version,
            },
        )

    @app.exception_handler(PlanDomainValidationError)
    async def handle_plan_validation(
        request: Request,
        exc: PlanDomainValidationError,
    ) -> JSONResponse:
        del request
        return JSONResponse(status_code=422, content={"detail": exc.detail})

    @app.exception_handler(ExecutionAPIError)
    async def handle_execution_error(
        request: Request,
        exc: ExecutionAPIError,
    ) -> JSONResponse:
        del request
        return JSONResponse(
            status_code=exc.status_code,
            content=jsonable_encoder(
                {
                    "error": {
                        "code": exc.code,
                        "message": exc.message,
                        "details": exc.details,
                    }
                }
            ),
        )

    @app.exception_handler(RequestValidationError)
    async def handle_request_validation(
        request: Request,
        exc: RequestValidationError,
    ) -> JSONResponse:
        if not request.url.path.startswith(("/api/v1/exec", "/api/v1/mobile")):
            return await request_validation_exception_handler(request, exc)
        return JSONResponse(
            status_code=422,
            content=jsonable_encoder(
                {
                    "error": {
                        "code": "request_validation",
                        "message": "Request validation failed",
                        "details": {"issues": exc.errors()},
                    }
                }
            ),
        )

    @app.get("/health/live", tags=["Health"], include_in_schema=False)
    async def liveness() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/health/ready", tags=["Health"], include_in_schema=False)
    async def readiness() -> JSONResponse:
        try:
            await repository.ping()
        except Exception:
            logger.warning("Database readiness check failed")
            return JSONResponse(
                status_code=503,
                content={"status": "unavailable", "database": "unavailable"},
            )
        return JSONResponse(content={"status": "ok", "database": "ok"})

    @app.get(
        "/assets/anatomy.svg",
        tags=["Atlas"],
        response_class=FileResponse,
        responses={404: {"description": "Anatomy asset has not been installed"}},
    )
    async def anatomy_asset() -> FileResponse:
        anatomy_path = settings.media_root / "anatomy.svg"
        if not anatomy_path.is_file():
            raise HTTPException(status_code=404, detail="Anatomy asset is not available")
        return FileResponse(anatomy_path, media_type="image/svg+xml")

    app.include_router(atlas_router)
    app.include_router(plans_router)
    app.include_router(execution_router)
    app.include_router(mobile_execution_router)
    app.include_router(waitlist_router)
    app.mount(
        settings.media_url_prefix,
        StaticFiles(directory=settings.media_root, check_dir=False),
        name="media",
    )
    return app
