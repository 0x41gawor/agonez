"""Self-cleaning production-proxy smoke for the PlanCreator routes and API methods."""

import json
import os
import urllib.error
import urllib.request
from typing import Any

BASE_URL = os.environ.get("AGONEZ_WEB_BASE_URL", "http://host.docker.internal:33288")


def request(method: str, path: str, payload: dict[str, Any] | None = None) -> tuple[int, bytes]:
    body = json.dumps(payload).encode() if payload is not None else None
    headers = {"Content-Type": "application/json"} if payload is not None else {}
    outgoing = urllib.request.Request(BASE_URL + path, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(outgoing, timeout=10) as response:
            return response.status, response.read()
    except urllib.error.HTTPError as exc:
        return exc.code, exc.read()


def main() -> None:
    plan_id: int | None = None
    status, html = request("GET", "/plans")
    assert status == 200 and b'<div id="app"></div>' in html

    try:
        status, body = request(
            "POST",
            "/api/plans",
            {"name": "Frontend proxy validation", "description": None},
        )
        assert status == 201, body
        draft = json.loads(body)
        plan_id = draft["id"]
        draft["name"] = "Frontend proxy validation saved"

        status, body = request("PUT", f"/api/plans/{plan_id}/draft", draft)
        assert status == 200, body
        saved = json.loads(body)
        assert saved["lock_version"] == 2
        assert saved["name"] == "Frontend proxy validation saved"

        status, body = request("GET", f"/api/plans/{plan_id}/draft")
        assert status == 200 and json.loads(body) == saved
        print("PlanCreator frontend proxy smoke passed")
    finally:
        if plan_id is not None:
            status, body = request("DELETE", f"/api/plans/{plan_id}")
            assert status == 204, body


if __name__ == "__main__":
    main()
