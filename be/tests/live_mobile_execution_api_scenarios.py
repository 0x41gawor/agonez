"""Destructive mobile Execution acceptance test for a disposable deployed API.

This intentionally finalizes real demo sessions and cannot clean them back to their original
state. Run it only against a disposable database restored from the Execution demo backup:

    MOBILE_API_ALLOW_DESTRUCTIVE_TEST=1 \
    MOBILE_API_BASE_URL=http://127.0.0.1:38000 \
    MOBILE_TEST_DATE=2026-10-08 \
    .venv/bin/python tests/live_mobile_execution_api_scenarios.py
"""

from __future__ import annotations

import json
import os
import urllib.error
import urllib.parse
import urllib.request
from datetime import date, datetime, timedelta
from typing import Any
from uuid import UUID, uuid4, uuid5

BASE_URL = os.getenv("MOBILE_API_BASE_URL", "http://127.0.0.1:8000")
START_DATE = date.fromisoformat(os.getenv("MOBILE_TEST_DATE", "2026-10-08"))
DEMO_RUN = os.getenv("MOBILE_TEST_PLAN_RUN", "Execution Demo — PPL Upper Focus 2026")
DEVICE_A = uuid4()
DEVICE_B = uuid4()


def request(
    method: str,
    path: str,
    *,
    device_id: UUID,
    payload: dict[str, Any] | None = None,
    headers: dict[str, str] | None = None,
) -> tuple[int, Any, dict[str, str]]:
    body = json.dumps(payload).encode() if payload is not None else None
    outgoing_headers = {
        "Accept-Language": "en",
        "X-Agonez-Client": "live-mobile-acceptance/1",
        "X-Agonez-Device-Id": str(device_id),
    }
    if body is not None:
        outgoing_headers["Content-Type"] = "application/json"
    outgoing_headers.update(headers or {})
    outgoing = urllib.request.Request(
        BASE_URL + path,
        data=body,
        headers=outgoing_headers,
        method=method,
    )
    try:
        with urllib.request.urlopen(outgoing, timeout=20) as response:
            content = response.read()
            return (
                response.status,
                json.loads(content) if content else None,
                {key.lower(): value for key, value in response.headers.items()},
            )
    except urllib.error.HTTPError as exc:
        content = exc.read()
        return (
            exc.code,
            json.loads(content) if content else None,
            {key.lower(): value for key, value in exc.headers.items()},
        )


def expect(
    method: str,
    path: str,
    status: int,
    *,
    device_id: UUID,
    payload: dict[str, Any] | None = None,
    headers: dict[str, str] | None = None,
) -> tuple[Any, dict[str, str]]:
    actual, response, response_headers = request(
        method,
        path,
        device_id=device_id,
        payload=payload,
        headers=headers,
    )
    assert actual == status, (method, path, actual, response)
    return response, response_headers


def operation(seq: int, kind: str, data: dict[str, Any], *, at: str) -> dict[str, Any]:
    return {"op_id": str(uuid4()), "seq": seq, "at": at, "type": kind, "data": data}


def context_path(run_id: int, on_date: date) -> str:
    query = urllib.parse.urlencode({"plan_run_id": run_id, "date": on_date.isoformat()})
    return f"/api/v1/mobile/context?{query}"


def complete_existing_active(run_id: int) -> None:
    active, _, _ = request(
        "GET",
        f"/api/v1/mobile/workouts/active?plan_run_id={run_id}",
        device_id=DEVICE_A,
    )
    if active == 404:
        return
    assert active == 200
    summary, _ = expect(
        "GET",
        f"/api/v1/mobile/workouts/active?plan_run_id={run_id}",
        200,
        device_id=DEVICE_A,
    )
    workout_id = summary["workout_id"]
    snapshot, _ = expect(
        "POST",
        f"/api/v1/mobile/workouts/{workout_id}/claim",
        200,
        device_id=DEVICE_A,
        payload={
            "device_id": str(DEVICE_A),
            "observed_applied_seq": summary["applied_seq"],
        },
    )
    started = datetime.fromisoformat(snapshot["started_at"].replace("Z", "+00:00"))
    expect(
        "POST",
        f"/api/v1/mobile/workouts/{workout_id}/finalize",
        200,
        device_id=DEVICE_A,
        payload={
            "lease_epoch": snapshot["lease"]["epoch"],
            "final_seq": snapshot["applied_seq"],
            "finished_at": (started + timedelta(hours=1)).isoformat(),
            "unrecorded": "mark_not_performed",
            "acknowledged_incomplete": True,
        },
    )


def find_ready_session(run_id: int) -> tuple[date, dict[str, Any]]:
    for offset in range(15):
        candidate = START_DATE + timedelta(days=offset)
        context, _ = expect(
            "GET",
            context_path(run_id, candidate),
            200,
            device_id=DEVICE_A,
        )
        expected = context["expected_session"]
        if expected is not None and expected["prescription"]["readiness"] == "ready":
            return candidate, expected
    raise AssertionError("No ready expected session was found in the 15-day test window")


def main() -> None:
    assert os.getenv("MOBILE_API_ALLOW_DESTRUCTIVE_TEST") == "1", (
        "Refusing to mutate a database without MOBILE_API_ALLOW_DESTRUCTIVE_TEST=1"
    )

    runs, _ = expect(
        "GET", "/api/v1/mobile/plan-runs", 200, device_id=DEVICE_A
    )
    run = next(item for item in runs if item["name"] == DEMO_RUN)
    run_id = run["id"]
    complete_existing_active(run_id)

    workout_date, expected = find_ready_session(run_id)
    session_id = expected["session_id"]
    prescription, _ = expect(
        "GET",
        f"/api/v1/mobile/sessions/{session_id}/prescription",
        200,
        device_id=DEVICE_A,
    )
    assert len(prescription["exercises"]) >= 3
    assert len(prescription["exercises"][0]["sets"]) >= 2
    assert prescription["exercises"][0]["atlas_peek"]["exercise"]["id"] > 0

    workout_id = uuid4()
    started_at = f"{workout_date.isoformat()}T17:00:00+00:00"
    start_payload = {
        "workout_id": str(workout_id),
        "session_id": session_id,
        "prescription_version": prescription["prescription_version"],
        "started_at": started_at,
        "allow_missing_loads": False,
    }
    snapshot, _ = expect(
        "POST",
        "/api/v1/mobile/workouts",
        201,
        device_id=DEVICE_A,
        payload=start_payload,
    )
    retry, _ = expect(
        "POST",
        "/api/v1/mobile/workouts",
        200,
        device_id=DEVICE_A,
        payload=start_payload,
    )
    assert retry["workout_id"] == snapshot["workout_id"]
    assert retry["revision"] == snapshot["revision"]

    workout_path = f"/api/v1/mobile/workouts/{workout_id}"
    current, response_headers = expect(
        "GET", workout_path, 200, device_id=DEVICE_A
    )
    etag = response_headers["etag"]
    unchanged, unchanged_headers = expect(
        "GET",
        workout_path,
        304,
        device_id=DEVICE_A,
        headers={"If-None-Match": etag},
    )
    assert unchanged is None
    assert unchanged_headers["etag"] == etag

    by_prescription = {
        item["exercise_prescription_id"]: item
        for item in current["performance"]["exercises"]
    }
    first = prescription["exercises"][0]
    second = prescription["exercises"][1]
    third = prescription["exercises"][2]
    first_perf = by_prescription[first["exercise_prescription_id"]]
    second_perf = by_prescription[second["exercise_prescription_id"]]
    third_perf = by_prescription[third["exercise_prescription_id"]]
    first_set = first["sets"][0]
    skipped_set = first["sets"][1]
    performed_id = uuid5(workout_id, f"set:{first_set['set_prescription_id']}")
    skipped_id = uuid5(workout_id, f"set:{skipped_set['set_prescription_id']}")
    performed_load = first_set["prescribed_load_kg"] or 20
    at = started_at

    first_ops = [
        operation(
            1,
            "upsert_set",
            {
                "set_performance_id": str(performed_id),
                "exercise_performance_id": first_perf["exercise_performance_id"],
                "exercise_prescription_id": first["exercise_prescription_id"],
                "prescribed_set_id": first_set["set_prescription_id"],
                "ordinal": first_set["ordinal"],
                "status": "performed",
                "load_kg": performed_load,
                "repetitions": first_set["rep_min"],
                "rir": first_set["target_rir"],
                "comment": "offline acceptance",
                "heart_rate_bpm": 132,
                "performed_at": at,
            },
            at=at,
        ),
        operation(
            2,
            "set_exercise_comment",
            {
                "exercise_performance_id": first_perf["exercise_performance_id"],
                "exercise_prescription_id": first["exercise_prescription_id"],
                "comment": "stable technique",
            },
            at=at,
        ),
        operation(
            3,
            "set_cursor",
            {
                "exercise_performance_id": first_perf["exercise_performance_id"],
                "set_ordinal": 1,
                "phase": "set",
            },
            at=at,
        ),
        operation(4, "set_workout_comment", {"comment": "offline block"}, at=at),
        operation(
            5,
            "skip_set",
            {
                "set_performance_id": str(skipped_id),
                "exercise_performance_id": first_perf["exercise_performance_id"],
                "exercise_prescription_id": first["exercise_prescription_id"],
                "prescribed_set_id": skipped_set["set_prescription_id"],
                "ordinal": skipped_set["ordinal"],
                "comment": "intentional skip",
            },
            at=at,
        ),
    ]
    first_result, _ = expect(
        "POST",
        f"{workout_path}/ops",
        200,
        device_id=DEVICE_A,
        payload={"lease_epoch": 1, "base_seq": 0, "ops": first_ops},
    )
    assert first_result["applied_seq"] == 5
    assert all(item["status"] == "applied" for item in first_result["results"])

    replay, _ = expect(
        "POST",
        f"{workout_path}/ops",
        200,
        device_id=DEVICE_A,
        payload={"lease_epoch": 1, "base_seq": 0, "ops": first_ops},
    )
    assert replay["applied_seq"] == 5
    assert all(item["status"] == "duplicate" for item in replay["results"])

    pending, _ = expect(
        "POST",
        f"{workout_path}/finalize",
        409,
        device_id=DEVICE_A,
        payload={
            "lease_epoch": 1,
            "final_seq": 9,
            "finished_at": at,
            "unrecorded": "mark_not_performed",
            "acknowledged_incomplete": True,
        },
    )
    assert pending["error"]["code"] == "ops_pending"

    second_ops = [
        operation(
            6,
            "upsert_set",
            {
                "if_rev": first_result["results"][0]["entity_rev"],
                "set_performance_id": str(performed_id),
                "exercise_performance_id": first_perf["exercise_performance_id"],
                "exercise_prescription_id": first["exercise_prescription_id"],
                "prescribed_set_id": first_set["set_prescription_id"],
                "ordinal": first_set["ordinal"],
                "status": "performed",
                "load_kg": performed_load,
                "repetitions": min(first_set["rep_min"] + 1, 100),
                "rir": first_set["target_rir"],
                "comment": "edited after reconnect",
                "heart_rate_bpm": 136,
                "performed_at": at,
            },
            at=at,
        ),
        operation(
            7,
            "clear_set",
            {
                "if_rev": first_result["results"][4]["entity_rev"],
                "set_performance_id": str(skipped_id),
            },
            at=at,
        ),
        operation(
            8,
            "skip_set",
            {
                "set_performance_id": str(skipped_id),
                "exercise_performance_id": first_perf["exercise_performance_id"],
                "exercise_prescription_id": first["exercise_prescription_id"],
                "prescribed_set_id": skipped_set["set_prescription_id"],
                "ordinal": skipped_set["ordinal"],
                "comment": "skip restored after undo",
            },
            at=at,
        ),
        operation(9, "set_workout_comment", {"comment": "online again"}, at=at),
    ]
    continued, _ = expect(
        "POST",
        f"{workout_path}/ops",
        200,
        device_id=DEVICE_A,
        payload={"lease_epoch": 1, "base_seq": 5, "ops": second_ops},
    )
    assert continued["applied_seq"] == 9

    resumed_context, _ = expect(
        "GET", context_path(run_id, workout_date), 200, device_id=DEVICE_B
    )
    assert resumed_context["active_workout"]["workout_id"] == str(workout_id)
    canonical_before_claim, _ = expect(
        "GET", workout_path, 200, device_id=DEVICE_B
    )
    claimed, _ = expect(
        "POST",
        f"{workout_path}/claim",
        200,
        device_id=DEVICE_B,
        payload={"device_id": str(DEVICE_B), "observed_applied_seq": 9},
    )
    assert claimed["lease"]["epoch"] == 2
    assert claimed["applied_seq"] == 0
    assert claimed["performance"] == canonical_before_claim["performance"]

    superseded, _ = expect(
        "POST",
        f"{workout_path}/ops",
        409,
        device_id=DEVICE_A,
        payload={
            "lease_epoch": 1,
            "base_seq": 9,
            "ops": [operation(10, "set_workout_comment", {"comment": "old device"}, at=at)],
        },
    )
    assert superseded["error"]["code"] == "superseded"

    atlas, _ = expect(
        "GET",
        f"/api/v1/mobile/atlas/exercises?limit=30&plan_run_id={run_id}",
        200,
        device_id=DEVICE_B,
    )
    prescribed_ids = {item["exercise"]["id"] for item in prescription["exercises"]}
    replacement = next(item for item in atlas["items"] if item["id"] != second["exercise"]["id"])
    added = next((item for item in atlas["items"] if item["id"] not in prescribed_ids), replacement)
    added_exercise_id = uuid4()
    added_set_id = uuid4()
    order = [
        item["exercise_performance_id"]
        for item in reversed(claimed["performance"]["exercises"])
    ] + [str(added_exercise_id)]
    takeover_ops = [
        operation(
            1,
            "substitute_exercise",
            {
                "exercise_performance_id": second_perf["exercise_performance_id"],
                "exercise_prescription_id": second["exercise_prescription_id"],
                "actual_exercise_id": replacement["id"],
                "source": "atlas",
            },
            at=at,
        ),
        operation(
            2,
            "substitute_exercise",
            {
                "exercise_performance_id": first_perf["exercise_performance_id"],
                "exercise_prescription_id": first["exercise_prescription_id"],
                "actual_exercise_id": replacement["id"],
                "source": "atlas",
            },
            at=at,
        ),
        operation(
            3,
            "skip_exercise",
            {
                "exercise_performance_id": third_perf["exercise_performance_id"],
                "exercise_prescription_id": third["exercise_prescription_id"],
                "comment": "explicit exercise skip",
            },
            at=at,
        ),
        operation(
            4,
            "add_unplanned_exercise",
            {
                "exercise_performance_id": str(added_exercise_id),
                "actual_exercise_id": added["id"],
                "performed_ordinal": len(order) - 1,
            },
            at=at,
        ),
        operation(
            5,
            "upsert_set",
            {
                "set_performance_id": str(added_set_id),
                "exercise_performance_id": str(added_exercise_id),
                "exercise_prescription_id": None,
                "prescribed_set_id": None,
                "ordinal": 0,
                "status": "performed",
                "load_kg": 10,
                "repetitions": 12,
                "rir": 2,
                "comment": "unplanned work",
                "heart_rate_bpm": 128,
                "performed_at": at,
            },
            at=at,
        ),
        operation(6, "reorder_exercises", {"order": order}, at=at),
    ]
    takeover, _ = expect(
        "POST",
        f"{workout_path}/ops",
        200,
        device_id=DEVICE_B,
        payload={"lease_epoch": 2, "base_seq": 0, "ops": takeover_ops},
    )
    assert takeover["applied_seq"] == 6
    assert takeover["results"][0]["status"] == "applied"
    assert takeover["results"][1]["status"] == "rejected"
    assert takeover["results"][1]["error"]["code"] == "substitution_after_sets"
    assert all(item["status"] == "applied" for item in takeover["results"][2:])

    incomplete, _ = expect(
        "POST",
        f"{workout_path}/finalize",
        409,
        device_id=DEVICE_B,
        payload={
            "lease_epoch": 2,
            "final_seq": 6,
            "finished_at": at,
            "unrecorded": "mark_not_performed",
            "acknowledged_incomplete": False,
        },
    )
    assert incomplete["error"]["code"] == "incomplete_not_acknowledged"

    finalize_payload = {
        "lease_epoch": 2,
        "final_seq": 6,
        "finished_at": at,
        "unrecorded": "mark_not_performed",
        "acknowledged_incomplete": True,
    }
    finalized, _ = expect(
        "POST",
        f"{workout_path}/finalize",
        200,
        device_id=DEVICE_B,
        payload=finalize_payload,
    )
    finalize_retry, _ = expect(
        "POST",
        f"{workout_path}/finalize",
        200,
        device_id=DEVICE_B,
        payload=finalize_payload,
    )
    assert finalize_retry == finalized
    assert finalized["summary"]["performed_sets"] >= 2
    assert finalized["summary"]["skipped_sets"] >= 1
    assert finalized["summary"]["not_performed_sets"] >= 1
    assert finalized["summary"]["substitutions"] == 1
    assert finalized["summary"]["added_exercises"] == 1
    assert finalized["summary"]["additional_sets"] == 1
    assert finalized["summary"]["reordered"] is True

    trace, _ = expect(
        "GET",
        f"/api/v1/exec/plan-runs/{run_id}/exercise-traces/{first['exercise_track_id']}",
        200,
        device_id=DEVICE_B,
    )
    exposure = next(
        item
        for item in trace["exposures"]
        if item["session"]["session_id"] == session_id
    )
    assert exposure["session"]["status"] == "completed"
    assert exposure["performance"]["status"] == "finalized"
    assert any(item["status"] == "performed" for item in exposure["performance"]["sets"])
    print("Mobile Execution offline/retry/resume/multi-device acceptance scenario passed")


if __name__ == "__main__":
    main()
