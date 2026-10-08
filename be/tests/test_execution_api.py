import json
from collections.abc import Awaitable, Callable
from pathlib import Path
from typing import Any, cast

import pytest
from fastapi import Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from agonez_api.app import create_app
from agonez_api.core.config import Settings


@pytest.mark.asyncio
async def test_execution_request_validation_uses_stable_error_envelope(
    tmp_path: Path,
) -> None:
    settings = Settings(
        NOME="atlas_user",
        AGANDSKODE="secret",
        MINA=33327,
        MEDIA_ROOT=tmp_path,
    )
    app = create_app(settings=settings, pool=cast(Any, object()))
    handler = cast(
        Callable[[Request, RequestValidationError], Awaitable[JSONResponse]],
        app.exception_handlers[RequestValidationError],
    )
    request = Request(
        {
            "type": "http",
            "http_version": "1.1",
            "method": "GET",
            "scheme": "http",
            "path": "/api/v1/exec/plan-runs/preview",
            "raw_path": b"/api/v1/exec/plan-runs/preview",
            "query_string": b"",
            "headers": [],
            "client": ("test", 1),
            "server": ("test", 80),
        }
    )
    error = RequestValidationError(
        [
            {
                "type": "missing",
                "loc": ("query", "plan_revision_id"),
                "msg": "Field required",
                "input": None,
            }
        ]
    )

    response = await handler(request, error)
    body = json.loads(response.body)

    assert response.status_code == 422
    assert body["error"]["code"] == "request_validation"
    assert body["error"]["details"]["issues"]
