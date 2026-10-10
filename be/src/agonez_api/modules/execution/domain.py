from __future__ import annotations

from dataclasses import dataclass
from datetime import date, timedelta
from decimal import Decimal
from typing import Any

from agonez_api.modules.execution.schemas import (
    BlockedReason,
    LoadDivergence,
    NextPrescriptionState,
    PrescriptionCompleteness,
    RepsPosition,
    RIRDivergence,
)

Row = dict[str, Any]


def numeric(value: Any) -> float | None:
    if value is None:
        return None
    return float(value)


def version_of(value: Any) -> str:
    return value.isoformat() if hasattr(value, "isoformat") else str(value)


def target_rir(value: Any) -> int | None:
    text = str(value)
    return int(text[-1]) if text.startswith("RIR") and text[-1].isdigit() else None


def delta_pct(first: float | None, latest: float | None) -> float | None:
    if first in (None, 0) or latest is None:
        return None
    assert first is not None
    return round((latest - first) / first * 100, 1)


def divergence(
    *,
    execution_mode: str,
    performed_status: str,
    prescribed_load: Any,
    performed_load: Any,
    rep_min: int | None,
    rep_max: int | None,
    repetitions: int | None,
    prescribed_rir: int | None,
    performed_rir: int | None,
    is_additional: bool,
) -> dict[str, str | None]:
    if performed_status in {"skipped", "not_performed"}:
        return {"load": None, "reps": None, "rir": None}

    load_result: LoadDivergence | None = None
    if not is_additional and execution_mode == "as_prescribed":
        if prescribed_load is not None and performed_load is not None:
            prescribed = Decimal(str(prescribed_load))
            performed = Decimal(str(performed_load))
            load_result = (
                LoadDivergence.BELOW
                if performed < prescribed
                else LoadDivergence.ABOVE
                if performed > prescribed
                else LoadDivergence.EQUAL
            )

    reps_result: RepsPosition | None = None
    if repetitions is not None and rep_min is not None and rep_max is not None:
        reps_result = (
            RepsPosition.BELOW_RANGE
            if repetitions < rep_min
            else RepsPosition.AT_FLOOR
            if repetitions == rep_min
            else RepsPosition.ABOVE_RANGE
            if repetitions > rep_max
            else RepsPosition.TOP_OF_RANGE
            if repetitions == rep_max
            else RepsPosition.IN_RANGE
        )

    rir_result: RIRDivergence | None = None
    if performed_rir is not None and prescribed_rir is not None:
        rir_result = (
            RIRDivergence.DEEPER
            if performed_rir < prescribed_rir
            else RIRDivergence.SHALLOWER
            if performed_rir > prescribed_rir
            else RIRDivergence.ON_TARGET
        )
    return {
        "load": load_result.value if load_result else None,
        "reps": reps_result.value if reps_result else None,
        "rir": rir_result.value if rir_result else None,
    }


def projection_end(starts_on: date, microcycle_count: int, duration: int) -> date:
    return starts_on + timedelta(days=microcycle_count * duration - 1)


def day_for(starts_on: date, microcycle_ordinal: int, duration: int, day: int) -> date:
    return starts_on + timedelta(days=(microcycle_ordinal - 1) * duration + day)


def prescription_completeness(saved: int, total: int) -> PrescriptionCompleteness:
    if saved == 0:
        return PrescriptionCompleteness.NONE
    if total > 0 and saved >= total:
        return PrescriptionCompleteness.COMPLETE
    return PrescriptionCompleteness.PARTIAL


def attendance_for(microcycle: Row, sessions: list[Row], as_of: date) -> dict[str, Any]:
    due_sessions = [item for item in sessions if item["scheduled_date"] <= as_of]
    due = len(due_sessions)
    completed = sum(item["status"] == "completed" for item in due_sessions)
    return {
        "microcycle_ordinal": microcycle["ordinal"],
        "due": due,
        "completed": completed,
        "missed": sum(item["status"] == "missed" for item in due_sessions),
        "cancelled": sum(item["status"] == "cancelled" for item in due_sessions),
        "in_progress": sum(item["status"] == "in_progress" for item in due_sessions),
        "ratio": round(completed / due, 4) if due else None,
    }


@dataclass(frozen=True)
class NextResolution:
    state: NextPrescriptionState
    blocked_reason: BlockedReason | None
    target: Row | None
    basis_performance: Row | None
    blocking_session: Row | None


def resolve_next(
    *,
    run: Row,
    sessions: list[Row],
    prescriptions: list[Row],
    performances: list[Row],
    workout_track_id: int,
    exercise_track_id: int,
) -> NextResolution:
    """Authoritative §4.2 readiness resolver used by every read and write path."""
    relevant_performances = [
        item
        for item in performances
        if item["exercise_unit_track_id"] == exercise_track_id
        and item["workout_performance_status"] == "finalized"
    ]
    relevant_performances.sort(
        key=lambda item: (
            item["scheduled_date"],
            item.get("workout_completed_at") or item["scheduled_date"],
            item["id"],
        )
    )
    basis = relevant_performances[-1] if relevant_performances else None
    basis_date = basis["scheduled_date"] if basis else None

    track_sessions = [
        item
        for item in sessions
        if item["workout_unit_track_id"] == workout_track_id
        and (basis_date is None or item["scheduled_date"] > basis_date)
    ]
    track_sessions.sort(key=lambda item: (item["scheduled_date"], item["id"]))
    target = next((item for item in track_sessions if item["status"] == "scheduled"), None)

    if run["status"] not in {"active", "scheduled"}:
        return NextResolution(
            NextPrescriptionState.NONE,
            BlockedReason.RUN_NOT_ACTIVE,
            target,
            basis,
            None,
        )
    if target is None:
        locked = next(
            (
                item
                for item in track_sessions
                if item["status"] != "scheduled"
                and any(
                    prescription["workout_session_id"] == item["id"]
                    and prescription["exercise_unit_track_id"] == exercise_track_id
                    for prescription in prescriptions
                )
            ),
            None,
        )
        if locked is not None:
            return NextResolution(
                NextPrescriptionState.LOCKED,
                BlockedReason.SESSION_STARTED,
                locked,
                basis,
                locked,
            )
        return NextResolution(
            NextPrescriptionState.NONE,
            BlockedReason.NO_FUTURE_SESSION,
            None,
            basis,
            None,
        )

    intervening = [
        item
        for item in track_sessions
        if item["scheduled_date"] < target["scheduled_date"]
    ]
    in_progress = next((item for item in intervening if item["status"] == "in_progress"), None)
    if in_progress is not None:
        return NextResolution(
            NextPrescriptionState.BLOCKED,
            BlockedReason.PREVIOUS_EXPOSURE_IN_PROGRESS,
            target,
            basis,
            in_progress,
        )
    prescribed_session_ids = {
        item["workout_session_id"]
        for item in prescriptions
        if item["exercise_unit_track_id"] == exercise_track_id
    }
    not_performed = next(
        (
            item
            for item in intervening
            if item["status"] == "scheduled" and item["id"] in prescribed_session_ids
        ),
        None,
    )
    if not_performed is not None:
        return NextResolution(
            NextPrescriptionState.BLOCKED,
            BlockedReason.PREVIOUS_EXPOSURE_NOT_PERFORMED,
            target,
            basis,
            not_performed,
        )
    return NextResolution(NextPrescriptionState.EDITABLE, None, target, basis, None)


def flags_for(
    *,
    execution_mode: str | None,
    prescribed_sets: list[Row],
    performed_sets: list[Row],
    personal_record: bool = False,
) -> list[str]:
    flags: list[str] = []
    if execution_mode == "substituted":
        flags.append("substituted")
    if execution_mode == "skipped":
        flags.append("skipped")
    if any(item.get("prescribed_set_id") is None for item in performed_sets):
        flags.append("additional_set")

    prescribed_by_id = {item["id"]: item for item in prescribed_sets}
    for performed in performed_sets:
        prescribed = prescribed_by_id.get(performed.get("prescribed_set_id"))
        if prescribed is None or performed["status"] == "skipped":
            continue
        repetitions = performed.get("repetitions")
        if repetitions is not None and repetitions < prescribed["rep_min"]:
            flags.append("reps_below_range")
        elif repetitions == prescribed["rep_min"]:
            flags.append("reps_at_floor")
        elif repetitions == prescribed["rep_max"]:
            flags.append("top_of_range")
        if (
            performed.get("load_kg") is not None
            and prescribed.get("prescribed_load_kg") is not None
            and performed["load_kg"] < prescribed["prescribed_load_kg"]
        ):
            flags.append("load_reduced")
    if personal_record:
        flags.append("personal_record")
    return list(dict.fromkeys(flags))
