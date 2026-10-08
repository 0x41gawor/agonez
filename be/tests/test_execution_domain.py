from datetime import date, datetime, timezone
from typing import Any

import pytest

from agonez_api.modules.execution.domain import (
    attendance_for,
    delta_pct,
    divergence,
    prescription_completeness,
    resolve_next,
)


def session(
    identifier: int,
    scheduled_date: date,
    status: str,
    *,
    track_id: int = 10,
) -> dict[str, Any]:
    return {
        "id": identifier,
        "scheduled_date": scheduled_date,
        "status": status,
        "workout_unit_track_id": track_id,
        "started_at": (
            datetime(2026, 10, 7, 18, tzinfo=timezone.utc)
            if status == "in_progress"
            else None
        ),
    }


def performance(
    identifier: int,
    scheduled_date: date,
    *,
    exercise_track_id: int = 20,
) -> dict[str, Any]:
    return {
        "id": identifier,
        "exercise_unit_track_id": exercise_track_id,
        "workout_performance_status": "finalized",
        "scheduled_date": scheduled_date,
        "workout_completed_at": datetime.combine(
            scheduled_date,
            datetime.min.time(),
            tzinfo=timezone.utc,
        ),
        "workout_session_id": identifier,
        "microcycle_ordinal": identifier,
        "execution_mode": "as_prescribed",
    }


def resolve(
    sessions: list[dict[str, Any]],
    *,
    performances: list[dict[str, Any]] | None = None,
    prescriptions: list[dict[str, Any]] | None = None,
    run_status: str = "active",
):
    return resolve_next(
        run={"status": run_status},
        sessions=sessions,
        prescriptions=prescriptions or [],
        performances=performances or [],
        workout_track_id=10,
        exercise_track_id=20,
    )


def test_first_exposure_is_editable_without_a_basis() -> None:
    result = resolve([session(1, date(2026, 10, 13), "scheduled")])

    assert result.state.value == "editable"
    assert result.basis_performance is None
    assert result.target is not None and result.target["id"] == 1


def test_latest_finalized_performance_is_the_basis() -> None:
    result = resolve(
        [session(3, date(2026, 10, 13), "scheduled")],
        performances=[
            performance(1, date(2026, 9, 29)),
            performance(2, date(2026, 10, 6)),
        ],
    )

    assert result.basis_performance is not None
    assert result.basis_performance["id"] == 2
    assert result.target is not None and result.target["id"] == 3


def test_in_progress_intervening_exposure_blocks() -> None:
    result = resolve(
        [
            session(2, date(2026, 10, 7), "in_progress"),
            session(3, date(2026, 10, 13), "scheduled"),
        ],
        performances=[performance(1, date(2026, 10, 6))],
    )

    assert result.state.value == "blocked"
    assert result.blocked_reason is not None
    assert result.blocked_reason.value == "previous_exposure_in_progress"
    assert result.blocking_session is not None and result.blocking_session["id"] == 2


@pytest.mark.parametrize("status", ["missed", "cancelled"])
def test_missed_and_cancelled_intervening_exposures_do_not_block(status: str) -> None:
    result = resolve(
        [
            session(2, date(2026, 10, 7), status),
            session(3, date(2026, 10, 13), "scheduled"),
        ],
        performances=[performance(1, date(2026, 10, 6))],
    )

    assert result.state.value == "editable"
    assert result.target is not None and result.target["id"] == 3


@pytest.mark.parametrize("status", ["cancelled", "completed"])
def test_inactive_run_has_no_next_prescription(status: str) -> None:
    result = resolve(
        [session(2, date(2026, 10, 13), "scheduled")],
        run_status=status,
    )

    assert result.state.value == "none"
    assert result.blocked_reason is not None
    assert result.blocked_reason.value == "run_not_active"


def test_no_future_session_returns_none() -> None:
    result = resolve([], performances=[performance(1, date(2026, 10, 6))])

    assert result.state.value == "none"
    assert result.blocked_reason is not None
    assert result.blocked_reason.value == "no_future_session"


def test_started_last_prescribed_session_is_locked_when_run_has_no_later_target() -> None:
    result = resolve(
        [session(2, date(2026, 10, 7), "in_progress")],
        performances=[performance(1, date(2026, 10, 6))],
        prescriptions=[
            {
                "workout_session_id": 2,
                "exercise_unit_track_id": 20,
            }
        ],
    )

    assert result.state.value == "locked"
    assert result.blocked_reason is not None
    assert result.blocked_reason.value == "session_started"


def test_divergence_preserves_directional_semantics() -> None:
    result = divergence(
        execution_mode="as_prescribed",
        performed_status="performed",
        prescribed_load=67.5,
        performed_load=65,
        rep_min=5,
        rep_max=7,
        repetitions=5,
        prescribed_rir=1,
        performed_rir=0,
        is_additional=False,
    )

    assert result == {"load": "below", "reps": "at_floor", "rir": "deeper"}


@pytest.mark.parametrize("mode", ["substituted", "skipped"])
def test_non_comparable_load_is_null(mode: str) -> None:
    result = divergence(
        execution_mode=mode,
        performed_status="performed" if mode == "substituted" else "skipped",
        prescribed_load=67.5,
        performed_load=50 if mode == "substituted" else None,
        rep_min=5,
        rep_max=7,
        repetitions=7 if mode == "substituted" else None,
        prescribed_rir=1,
        performed_rir=1 if mode == "substituted" else None,
        is_additional=False,
    )

    assert result["load"] is None


def test_attendance_excludes_future_sessions() -> None:
    value = attendance_for(
        {"ordinal": 6},
        [
            session(1, date(2026, 10, 6), "completed"),
            session(2, date(2026, 10, 7), "missed"),
            session(3, date(2026, 10, 9), "scheduled"),
        ],
        date(2026, 10, 8),
    )

    assert value == {
        "microcycle_ordinal": 6,
        "due": 2,
        "completed": 1,
        "missed": 1,
        "cancelled": 0,
        "in_progress": 0,
        "ratio": 0.5,
    }


def test_completeness_and_delta_helpers() -> None:
    assert prescription_completeness(0, 3).value == "none"
    assert prescription_completeness(2, 3).value == "partial"
    assert prescription_completeness(3, 3).value == "complete"
    assert delta_pct(65, 67.5) == 3.8
    assert delta_pct(0, 10) is None
