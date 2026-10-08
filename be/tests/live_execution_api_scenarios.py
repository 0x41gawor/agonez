"""Seed-backed desktop Execution acceptance scenario for a deployed test API.

Run only against a disposable database containing ``0001_execution_demo.sql``. The
script removes the prescription it creates, but it intentionally exercises real writes.
"""

import json
import os
import urllib.error
import urllib.parse
import urllib.request
from typing import Any

BASE_URL = os.getenv("EXEC_API_BASE_URL", "http://127.0.0.1:8000")
DEMO_RUN = "Execution Demo — PPL Upper Focus 2026"


def request(
    method: str,
    path: str,
    payload: dict[str, Any] | None = None,
) -> tuple[int, Any]:
    body = json.dumps(payload).encode() if payload is not None else None
    headers = {"Content-Type": "application/json"} if body is not None else {}
    outgoing = urllib.request.Request(
        BASE_URL + path,
        data=body,
        headers=headers,
        method=method,
    )
    try:
        with urllib.request.urlopen(outgoing, timeout=20) as response:
            content = response.read()
            return response.status, json.loads(content) if content else None
    except urllib.error.HTTPError as exc:
        content = exc.read()
        return exc.code, json.loads(content) if content else None


def expect(
    method: str,
    path: str,
    status: int,
    payload: dict[str, Any] | None = None,
) -> Any:
    actual, response = request(method, path, payload)
    assert actual == status, (method, path, actual, response)
    return response


def main() -> None:
    runs = expect("GET", "/api/v1/exec/plan-runs", 200)
    run = next(item for item in runs["items"] if item["name"] == DEMO_RUN)
    run_id = run["plan_run_id"]
    base = f"/api/v1/exec/plan-runs/{run_id}"

    overview = expect("GET", f"{base}/overview", 200)
    assert overview["run"]["status"] == "active"

    queue = expect("GET", f"{base}/analysis/queue", 200)
    bench = next(
        exercise
        for workout in queue["workouts"]
        for exercise in workout["exercises"]
        if exercise["name"] == "Bench Press"
    )
    trace_id = bench["exercise_trace_id"]
    trace_path = f"{base}/exercise-traces/{trace_id}"
    before = expect("GET", trace_path, 200)
    assert len(before["exposures"]) >= 6
    assert len(before["trace"]["continuity"]["revisions_spanned"]) >= 2
    assert before["next"]["state"] == "editable"
    assert before["next"]["prescription"] is None

    next_item = before["next"]
    target_session_id = next_item["target"]["session_id"]
    default_loads = next_item["defaults"]["from_previous_performance"]
    write_path = (
        f"{base}/sessions/{target_session_id}/exercise-prescriptions/{trace_id}"
    )
    payload = {
        "based_on_exercise_performance_id": next_item["basis"][
            "exercise_performance_id"
        ],
        "sets": [
            {
                "ordinal": plan_set["ordinal"],
                "load_kg": default_loads[index],
                "comment": None,
            }
            for index, plan_set in enumerate(next_item["plan_sets"])
        ],
        "prescription_comment": "Live Execution API validation.",
        "expected_version": None,
    }
    try:
        saved = expect("PUT", write_path, 200, payload)
        assert saved["next"]["prescription"] is not None
        reloaded = expect("GET", trace_path, 200)
        assert reloaded["next"]["prescription"]["prescription_comment"] == payload[
            "prescription_comment"
        ]

        stale = expect("PUT", write_path, 409, payload)
        assert stale["error"]["code"] == "version_conflict"
    finally:
        expect("DELETE", write_path, 204)

    workout_id = before["trace"]["workout_trace"]["workout_trace_id"]
    expect("GET", f"{base}/workout-traces", 200)
    expect("GET", f"{base}/workout-traces/{workout_id}", 200)
    expect("GET", f"{base}/microcycles", 200)
    expect("GET", f"{base}/calendar", 200)
    expect("GET", f"{base}/events", 200)
    expect(
        "GET",
        f"{base}/load-series?{urllib.parse.urlencode({'metric': 'top_set_load'})}",
        200,
    )
    print("Execution desktop API acceptance scenario passed")


if __name__ == "__main__":
    main()
