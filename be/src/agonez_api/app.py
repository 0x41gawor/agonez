import logging
import time
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Any
from uuid import uuid4

from fastapi import FastAPI, HTTPException, Request
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
    media = MediaResolver(
        root=settings.media_root,
        url_prefix=settings.media_url_prefix,
        public_base_url=settings.public_media_base_url,
    )
    service = AtlasService(repository, media)

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
            "Read-only REST API for the Agonez exercise and muscle Atlas. "
            "This module is intentionally public and has no per-user state."
        ),
        lifespan=lifespan,
    )
    app.state.settings = settings
    app.state.database_pool = database_pool
    app.state.atlas_repository = repository
    app.state.atlas_service = service

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=False,
        allow_methods=["GET", "OPTIONS"],
        allow_headers=["Accept", "Content-Type", "X-Request-ID"],
        expose_headers=["X-Request-ID"],
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
    app.mount(
        settings.media_url_prefix,
        StaticFiles(directory=settings.media_root, check_dir=False),
        name="media",
    )
    return app
