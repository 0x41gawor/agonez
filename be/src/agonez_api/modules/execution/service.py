from __future__ import annotations

from collections import defaultdict
from collections.abc import Callable
from datetime import date, timedelta
from statistics import mean
from typing import Any, cast

from agonez_api.modules.execution.domain import (
    NextResolution,
    attendance_for,
    delta_pct,
    divergence,
    flags_for,
    numeric,
    prescription_completeness,
    projection_end,
    resolve_next,
    target_rir,
    version_of,
)
from agonez_api.modules.execution.errors import invalid, not_found
from agonez_api.modules.execution.repository import (
    ExecutionRepository,
    RevisionTree,
    Row,
    RunBundle,
)
from agonez_api.modules.execution.schemas import (
    AnalysisQueue,
    CalendarResponse,
    EventCreate,
    EventDTO,
    EventListResponse,
    EventPatch,
    ExercisePrescriptionPut,
    ExerciseTraceResponse,
    LoadSeriesResponse,
    MicrocyclePatch,
    MicrocycleTimeline,
    PlanRunCreate,
    PlanRunListResponse,
    PlanRunOverview,
    PlanRunPatch,
    PlanRunPreview,
    PrescriptionWriteResponse,
    SessionPatch,
    SessionStatusResponse,
    TimelineMicrocycle,
    WorkoutPrescriptionPatch,
    WorkoutPrescriptionResponse,
    WorkoutTraceList,
    WorkoutTraceResponse,
)


class ExecutionService:
    def __init__(
        self,
        repository: ExecutionRepository,
        *,
        today: Callable[[], date] = date.today,
    ) -> None:
        self._repository = repository
        self._today = today

    async def list_plan_runs(
        self,
        *,
        statuses: tuple[str, ...],
        limit: int,
    ) -> PlanRunListResponse:
        if not 1 <= limit <= 200:
            raise invalid("invalid_limit", "limit must be between 1 and 200")
        allowed = {"scheduled", "active", "cancelled", "completed"}
        if any(item not in allowed for item in statuses):
            raise invalid("invalid_status", "Unknown plan run status")
        as_of = self._today()
        await self._repository.reconcile(None, as_of)
        rows = await self._repository.list_plan_runs(
            statuses=statuses,
            limit=limit,
            as_of=as_of,
        )
        return PlanRunListResponse.model_validate(
            {
                "as_of": as_of,
                "items": [
                    {
                        "plan_run_id": row["plan_run_id"],
                        "name": row["name"],
                        "status": row["status"],
                        "plan": {
                            "plan_id": row["plan_id"],
                            "code": row["plan_code"],
                            "name": row["plan_name"],
                        },
                        "starts_on": row["starts_on"],
                        "ends_on": row["ends_on"],
                        "microcycle_count": row["microcycle_count"],
                        "microcycle_duration_days": row["microcycle_duration_days"],
                        "current_microcycle_ordinal": row["current_microcycle_ordinal"],
                    }
                    for row in rows
                ],
            }
        )

    async def preview_plan_run(
        self,
        *,
        plan_revision_id: int,
        starts_on: date,
        microcycle_count: int,
    ) -> PlanRunPreview:
        if not 1 <= microcycle_count <= 52:
            raise invalid(
                "invalid_microcycle_count",
                "microcycle_count must be between 1 and 52",
            )
        tree = await self._repository.get_revision_tree(plan_revision_id)
        projected = self._project(tree, starts_on, microcycle_count)
        projected["overlapping_runs"] = await self._repository.list_overlapping_runs(
            starts_on=starts_on,
            ends_on=projected["ends_on"],
        )
        return PlanRunPreview.model_validate(projected)

    async def create_plan_run(self, payload: PlanRunCreate) -> PlanRunOverview:
        run_id = await self._repository.create_plan_run(payload, as_of=self._today())
        return await self.get_overview(run_id)

    async def get_overview(self, plan_run_id: int) -> PlanRunOverview:
        as_of, bundle = await self._bundle(plan_run_id)
        current = self._current_microcycle(bundle, as_of)
        attendance = [
            attendance_for(
                microcycle,
                [item for item in bundle.sessions if item["microcycle_id"] == microcycle["id"]],
                as_of,
            )
            for microcycle in bundle.microcycles
        ]
        microcycles = [
            {
                **self._microcycle_base(bundle, microcycle, current),
                "sessions": [
                    self._session_brief(session)
                    for session in bundle.sessions
                    if session["microcycle_id"] == microcycle["id"]
                ],
            }
            for microcycle in bundle.microcycles
        ]
        current_sessions = (
            [
                self._current_session(bundle, session)
                for session in bundle.sessions
                if session["microcycle_id"] == current["id"]
            ]
            if current
            else []
        )
        queue = self._analysis_queue(bundle, as_of, target_microcycle=None)
        position = self._position(bundle, as_of, current)
        return PlanRunOverview.model_validate(
            {
                "as_of": as_of,
                "run": self._run_header(bundle.run),
                "position": position,
                "microcycles": microcycles,
                "current_microcycle_sessions": current_sessions,
                "analysis_readiness": {
                    "target_microcycle_ordinal": (
                        queue["target_microcycle"]["ordinal"]
                        if queue["target_microcycle"]
                        else None
                    ),
                    "workouts": [
                        {
                            "workout_trace_id": item["workout_trace_id"],
                            "workout_name": item["workout_name"],
                            "state": item["state"],
                            "blocked_reason": item["blocked_reason"],
                            "basis_date": (
                                item["basis_session"]["scheduled_date"]
                                if item["basis_session"]
                                else None
                            ),
                            "exercises_total": len(item["exercises"]),
                            "exercises_prescribed": sum(
                                exercise["prescription_saved"]
                                for exercise in item["exercises"]
                            ),
                        }
                        for item in queue["workouts"]
                    ],
                },
                "latest_exposure": self._latest_exposure(bundle),
                "attendance": attendance,
                "latest_events": [self._event_dto(bundle, item) for item in bundle.events[:4]],
            }
        )

    async def update_plan_run(
        self,
        plan_run_id: int,
        payload: PlanRunPatch,
    ) -> PlanRunOverview:
        await self._repository.update_plan_run(plan_run_id, payload)
        return await self.get_overview(plan_run_id)

    async def get_analysis_queue(
        self,
        plan_run_id: int,
        *,
        target_microcycle: int | None,
    ) -> AnalysisQueue:
        as_of, bundle = await self._bundle(plan_run_id)
        if target_microcycle is not None and not any(
            item["ordinal"] == target_microcycle for item in bundle.microcycles
        ):
            raise not_found("microcycle_not_found", "Target microcycle was not found")
        return AnalysisQueue.model_validate(
            self._analysis_queue(bundle, as_of, target_microcycle=target_microcycle)
        )

    async def get_exercise_trace(
        self,
        plan_run_id: int,
        exercise_track_id: int,
        *,
        include_next: bool,
    ) -> ExerciseTraceResponse:
        as_of, bundle = await self._bundle(plan_run_id)
        return ExerciseTraceResponse.model_validate(
            self._exercise_trace(bundle, as_of, exercise_track_id, include_next=include_next)
        )

    async def get_next_prescription(
        self,
        plan_run_id: int,
        exercise_track_id: int,
    ) -> dict[str, Any]:
        as_of, bundle = await self._bundle(plan_run_id)
        track = self._exercise_track(bundle, exercise_track_id)
        return self._next_prescription(bundle, track, as_of)

    async def save_exercise_prescription(
        self,
        *,
        plan_run_id: int,
        session_id: int,
        exercise_track_id: int,
        payload: ExercisePrescriptionPut,
    ) -> PrescriptionWriteResponse:
        await self._repository.save_exercise_prescription(
            plan_run_id=plan_run_id,
            session_id=session_id,
            exercise_track_id=exercise_track_id,
            payload=payload,
        )
        as_of, bundle = await self._bundle(plan_run_id)
        track = self._exercise_track(bundle, exercise_track_id)
        next_item = self._next_prescription(bundle, track, as_of)
        session = self._session(bundle, session_id)
        return PrescriptionWriteResponse.model_validate(
            {
                "next": next_item,
                "workout_prescription_completeness": self._completeness(bundle, session),
            }
        )

    async def delete_exercise_prescription(
        self,
        *,
        plan_run_id: int,
        session_id: int,
        exercise_track_id: int,
    ) -> None:
        await self._repository.delete_exercise_prescription(
            plan_run_id=plan_run_id,
            session_id=session_id,
            exercise_track_id=exercise_track_id,
        )

    async def update_workout_prescription_comment(
        self,
        *,
        plan_run_id: int,
        session_id: int,
        payload: WorkoutPrescriptionPatch,
    ) -> WorkoutPrescriptionResponse:
        await self._repository.update_workout_prescription_comment(
            plan_run_id=plan_run_id,
            session_id=session_id,
            payload=payload,
        )
        _, bundle = await self._bundle(plan_run_id)
        item = next(
            (
                row
                for row in bundle.workout_prescriptions
                if row["workout_session_id"] == session_id
            ),
            None,
        )
        if item is None:
            raise not_found("prescription_not_found", "Workout prescription was not found")
        return WorkoutPrescriptionResponse.model_validate(
            {
                "session_id": session_id,
                "prescription_comment": item["prescription_comment"],
                "version": version_of(item["updated_at"]),
                "updated_at": item["updated_at"],
            }
        )

    async def list_workout_traces(self, plan_run_id: int) -> WorkoutTraceList:
        _, bundle = await self._bundle(plan_run_id)
        return WorkoutTraceList.model_validate(
            {
                "items": [
                    {
                        "workout_trace_id": item["id"],
                        "workout_name": item["name"],
                        "day_ordinal": self._logical_ordinal(item["logical_key"], "day"),
                        "exercise_trace_count": sum(
                            exercise["workout_unit_track_id"] == item["id"]
                            for exercise in bundle.exercise_tracks
                        ),
                    }
                    for item in bundle.workout_tracks
                ]
            }
        )

    async def get_workout_trace(
        self,
        plan_run_id: int,
        workout_track_id: int,
    ) -> WorkoutTraceResponse:
        as_of, bundle = await self._bundle(plan_run_id)
        workout = next(
            (item for item in bundle.workout_tracks if item["id"] == workout_track_id),
            None,
        )
        if workout is None:
            raise not_found("workout_trace_not_found", "Workout trace was not found")
        return WorkoutTraceResponse.model_validate(
            self._workout_trace(bundle, as_of, workout)
        )

    async def get_microcycles(self, plan_run_id: int) -> MicrocycleTimeline:
        as_of, bundle = await self._bundle(plan_run_id)
        return MicrocycleTimeline.model_validate(self._timeline(bundle, as_of))

    async def update_microcycle(
        self,
        *,
        plan_run_id: int,
        ordinal: int,
        payload: MicrocyclePatch,
    ) -> TimelineMicrocycle:
        await self._repository.update_microcycle(
            plan_run_id=plan_run_id,
            ordinal=ordinal,
            payload=payload,
            as_of=self._today(),
        )
        timeline = await self.get_microcycles(plan_run_id)
        item = next((row for row in timeline.microcycles if row.ordinal == ordinal), None)
        if item is None:
            raise not_found("microcycle_not_found", "Microcycle was not found")
        return item

    async def get_calendar(
        self,
        plan_run_id: int,
        *,
        from_date: date | None,
        to_date: date | None,
    ) -> CalendarResponse:
        as_of, bundle = await self._bundle(plan_run_id)
        start = from_date or bundle.run["starts_on"]
        end = to_date or bundle.run["ends_on"]
        if end < start:
            raise invalid("invalid_date_range", "to must be on or after from")
        sessions = [item for item in bundle.sessions if start <= item["scheduled_date"] <= end]
        microcycles = [
            item
            for item in bundle.microcycles
            if item["ends_on"] >= start and item["starts_on"] <= end
        ]
        return CalendarResponse.model_validate(
            {
                "as_of": as_of,
                "sessions": [
                    {
                        "session_id": item["id"],
                        "scheduled_date": item["scheduled_date"],
                        "microcycle_ordinal": item["microcycle_ordinal"],
                        "day_ordinal": item["day_ordinal"],
                        "workout_trace_id": item["workout_unit_track_id"],
                        "workout_name": item["workout_name"],
                        "status": item["status"],
                        "completion_mode": item["completion_mode"],
                        "prescription_completeness": self._completeness(bundle, item),
                        "performance_status": self._workout_performance_status(bundle, item["id"]),
                        "fallback_workout_name": item["fallback_workout_name"],
                    }
                    for item in sessions
                ],
                "microcycle_bounds": [
                    {
                        "ordinal": item["ordinal"],
                        "starts_on": item["starts_on"],
                        "ends_on": item["ends_on"],
                        "classification": item["classification"],
                    }
                    for item in microcycles
                ],
            }
        )

    async def update_session_status(
        self,
        *,
        plan_run_id: int,
        session_id: int,
        payload: SessionPatch,
    ) -> SessionStatusResponse:
        await self._repository.update_session_status(
            plan_run_id=plan_run_id,
            session_id=session_id,
            payload=payload,
            as_of=self._today(),
        )
        _, bundle = await self._bundle(plan_run_id)
        session = self._session(bundle, session_id)
        return SessionStatusResponse.model_validate(
            {"session_id": session_id, "status": session["status"], "notes": session["notes"]}
        )

    async def list_events(
        self,
        plan_run_id: int,
        *,
        types: tuple[str, ...],
        microcycle: int | None,
        cursor: str | None,
        limit: int,
    ) -> EventListResponse:
        if not 1 <= limit <= 200:
            raise invalid("invalid_limit", "limit must be between 1 and 200")
        _, bundle = await self._bundle(plan_run_id)
        rows = bundle.events
        if types:
            rows = [item for item in rows if item["event_type"] in types]
        if microcycle is not None:
            rows = [item for item in rows if item["microcycle_ordinal"] == microcycle]
        if cursor is not None:
            try:
                cursor_id = int(cursor)
            except ValueError as exc:
                raise invalid("invalid_cursor", "cursor is invalid") from exc
            rows = [item for item in rows if item["id"] < cursor_id]
        page = rows[: limit + 1]
        next_cursor = str(page[limit - 1]["id"]) if len(page) > limit else None
        return EventListResponse.model_validate(
            {
                "items": [self._event_dto(bundle, item) for item in page[:limit]],
                "next_cursor": next_cursor,
            }
        )

    async def create_event(self, plan_run_id: int, payload: EventCreate) -> EventDTO:
        event_id = await self._repository.create_event(plan_run_id, payload)
        return await self._get_event(plan_run_id, event_id)

    async def update_event(
        self,
        *,
        plan_run_id: int,
        event_id: int,
        payload: EventPatch,
    ) -> EventDTO:
        await self._repository.update_event(
            plan_run_id=plan_run_id,
            event_id=event_id,
            payload=payload,
        )
        return await self._get_event(plan_run_id, event_id)

    async def delete_event(self, *, plan_run_id: int, event_id: int) -> None:
        await self._repository.delete_event(plan_run_id=plan_run_id, event_id=event_id)

    async def get_load_series(
        self,
        plan_run_id: int,
        *,
        metric: str,
        normalize: str,
        workout_track_ids: tuple[int, ...],
        exercise_track_ids: tuple[int, ...],
        include_draft: bool,
        x_axis: str,
    ) -> LoadSeriesResponse:
        del x_axis
        if metric not in {"top_set_load", "mean_set_load", "volume_load"}:
            raise invalid("invalid_metric", "Unknown load metric")
        if normalize not in {"none", "first_exposure"}:
            raise invalid("invalid_normalization", "Unknown normalization mode")
        as_of, bundle = await self._bundle(plan_run_id)
        return LoadSeriesResponse.model_validate(
            self._load_series(
                bundle,
                as_of,
                metric=metric,
                normalize=normalize,
                workout_track_ids=workout_track_ids,
                exercise_track_ids=exercise_track_ids,
                include_draft=include_draft,
            )
        )

    async def _get_event(self, plan_run_id: int, event_id: int) -> EventDTO:
        _, bundle = await self._bundle(plan_run_id)
        event = next((item for item in bundle.events if item["id"] == event_id), None)
        if event is None:
            raise not_found("event_not_found", "Event was not found")
        return EventDTO.model_validate(self._event_dto(bundle, event))

    async def _bundle(self, plan_run_id: int) -> tuple[date, RunBundle]:
        as_of = self._today()
        await self._repository.reconcile(plan_run_id, as_of)
        return as_of, await self._repository.get_bundle(plan_run_id)

    @staticmethod
    def _project(tree: RevisionTree, starts_on: date, count: int) -> dict[str, Any]:
        duration = len(tree.days)
        workouts_by_day = {item["day_id"]: item for item in tree.workouts}
        workout_ids = {item["id"] for item in tree.workouts}
        return {
            "revision": {
                "plan_revision_id": tree.revision["plan_revision_id"],
                "revision_no": tree.revision["revision_no"],
                "status": tree.revision["status"],
            },
            "microcycle_duration_days": duration,
            "ends_on": projection_end(starts_on, count, duration),
            "session_count": len(tree.workouts) * count,
            "workout_track_count": len(tree.workouts),
            "exercise_track_count": sum(
                item["workout_unit_id"] in workout_ids for item in tree.slots
            ),
            "first_microcycle": [
                {
                    "day_ordinal": item["ordinal"],
                    "date": starts_on + timedelta(days=item["ordinal"]),
                    "workout_unit_name": (
                        workouts_by_day[item["id"]]["name"]
                        if item["id"] in workouts_by_day
                        else None
                    ),
                }
                for item in tree.days
            ],
            "overlapping_runs": [],
        }

    @staticmethod
    def _run_header(run: Row) -> dict[str, Any]:
        return {
            "plan_run_id": run["id"],
            "name": run["name"],
            "status": run["status"],
            "plan": {
                "plan_id": run["plan_id"],
                "code": run["plan_code"],
                "name": run["plan_name"],
            },
            "initial_revision": {
                "plan_revision_id": run["initial_plan_revision_id"],
                "revision_no": run["initial_revision_no"],
                "status": run["initial_revision_status"],
            },
            "starts_on": run["starts_on"],
            "ends_on": run["ends_on"],
            "microcycle_count": run["microcycle_count"],
            "microcycle_duration_days": run["microcycle_duration_days"],
            "version": version_of(run["updated_at"]),
        }

    @staticmethod
    def _current_microcycle(bundle: RunBundle, as_of: date) -> Row | None:
        return next(
            (
                item
                for item in bundle.microcycles
                if item["starts_on"] <= as_of <= item["ends_on"]
            ),
            None,
        )

    @staticmethod
    def _position(bundle: RunBundle, as_of: date, current: Row | None) -> dict[str, Any]:
        run_day = (as_of - bundle.run["starts_on"]).days + 1
        total = bundle.run["microcycle_count"] * bundle.run["microcycle_duration_days"]
        return {
            "microcycle_ordinal": current["ordinal"] if current else None,
            "day_in_microcycle": ((as_of - current["starts_on"]).days + 1) if current else None,
            "run_day": run_day if 1 <= run_day <= total else None,
            "run_days_total": total,
            "days_left": max((bundle.run["ends_on"] - as_of).days + 1, 0),
        }

    @staticmethod
    def _microcycle_ref(microcycle: Row) -> dict[str, Any]:
        return {
            "ordinal": microcycle["ordinal"],
            "starts_on": microcycle["starts_on"],
            "ends_on": microcycle["ends_on"],
            "classification": microcycle["classification"],
            "plan_revision_no": microcycle["plan_revision_no"],
        }

    def _microcycle_base(
        self,
        bundle: RunBundle,
        microcycle: Row,
        current: Row | None,
    ) -> dict[str, Any]:
        index = bundle.microcycles.index(microcycle)
        return {
            **self._microcycle_ref(microcycle),
            "revision_changed_here": (
                index > 0
                and bundle.microcycles[index - 1]["plan_revision_id"]
                != microcycle["plan_revision_id"]
            ),
            "is_current": bool(current and current["id"] == microcycle["id"]),
        }

    @staticmethod
    def _session_brief(session: Row) -> dict[str, Any]:
        return {
            "session_id": session["id"],
            "workout_trace_id": session["workout_unit_track_id"],
            "workout_name": session["workout_name"],
            "scheduled_date": session["scheduled_date"],
            "status": session["status"],
            "completion_mode": session["completion_mode"],
        }

    def _current_session(self, bundle: RunBundle, session: Row) -> dict[str, Any]:
        performance = next(
            (
                item
                for item in bundle.workout_performances
                if item["workout_session_id"] == session["id"]
            ),
            None,
        )
        exercise_count = sum(
            item["workout_unit_track_id"] == session["workout_unit_track_id"]
            for item in bundle.exercise_tracks
        )
        synced = (
            sum(
                item["workout_unit_performance_id"] == performance["id"]
                for item in bundle.exercise_performances
            )
            if performance
            else 0
        )
        return {
            "session_id": session["id"],
            "workout_name": session["workout_name"],
            "scheduled_date": session["scheduled_date"],
            "status": session["status"],
            "started_at": session["started_at"],
            "completed_at": session["completed_at"],
            "prescription_completeness": self._completeness(bundle, session),
            "exercise_count": exercise_count,
            "performance": (
                {"status": performance["status"], "synced_exercise_count": synced}
                if performance
                else None
            ),
        }

    @staticmethod
    def _session(bundle: RunBundle, session_id: int) -> Row:
        session = next((item for item in bundle.sessions if item["id"] == session_id), None)
        if session is None:
            raise not_found("session_not_found", "Workout session was not found")
        return session

    @staticmethod
    def _exercise_track(bundle: RunBundle, exercise_track_id: int) -> Row:
        track = next(
            (item for item in bundle.exercise_tracks if item["id"] == exercise_track_id),
            None,
        )
        if track is None:
            raise not_found("exercise_trace_not_found", "Exercise trace was not found")
        return track

    @staticmethod
    def _logical_ordinal(logical_key: str, expected: str) -> int:
        prefix, value = logical_key.split(":", 1)
        if prefix != expected:
            raise RuntimeError(f"Invalid {expected} logical key: {logical_key}")
        return int(value)

    def _completeness(self, bundle: RunBundle, session: Row) -> str:
        total = sum(
            item["workout_unit_track_id"] == session["workout_unit_track_id"]
            for item in bundle.exercise_tracks
        )
        saved = sum(
            item["workout_session_id"] == session["id"]
            for item in bundle.exercise_prescriptions
        )
        return prescription_completeness(saved, total).value

    @staticmethod
    def _workout_performance_status(bundle: RunBundle, session_id: int) -> str | None:
        item = next(
            (
                performance
                for performance in bundle.workout_performances
                if performance["workout_session_id"] == session_id
            ),
            None,
        )
        return cast(str, item["status"]) if item else None

    def _analysis_queue(
        self,
        bundle: RunBundle,
        as_of: date,
        target_microcycle: int | None,
    ) -> dict[str, Any]:
        workouts: list[dict[str, Any]] = []
        target_ordinals: list[int] = []
        for workout in bundle.workout_tracks:
            tracks = [
                item
                for item in bundle.exercise_tracks
                if item["workout_unit_track_id"] == workout["id"]
            ]
            resolved = [
                (
                    track,
                    resolve_next(
                        run=bundle.run,
                        sessions=bundle.sessions,
                        prescriptions=bundle.exercise_prescriptions,
                        performances=bundle.exercise_performances,
                        workout_track_id=workout["id"],
                        exercise_track_id=track["id"],
                    ),
                )
                for track in tracks
            ]
            representative = self._representative_resolution([item[1] for item in resolved])
            target = representative.target if representative else None
            target_ordinals.extend(
                cast(int, resolution.target["microcycle_ordinal"])
                for _, resolution in resolved
                if resolution.state.value == "editable" and resolution.target is not None
            )
            basis = representative.basis_performance if representative else None
            completeness = self._completeness(bundle, target) if target else "none"
            exercises = [
                self._queue_exercise(bundle, track, resolution.target)
                for track, resolution in resolved
            ]
            workouts.append(
                {
                    "workout_trace_id": workout["id"],
                    "workout_name": workout["name"],
                    "day_ordinal": self._logical_ordinal(workout["logical_key"], "day"),
                    "target_session": (
                        {
                            "session_id": target["id"],
                            "scheduled_date": target["scheduled_date"],
                            "status": target["status"],
                        }
                        if target
                        else None
                    ),
                    "basis_session": (
                        {
                            "session_id": basis["workout_session_id"],
                            "scheduled_date": basis["scheduled_date"],
                            "microcycle_ordinal": basis["microcycle_ordinal"],
                        }
                        if basis
                        else None
                    ),
                    "state": representative.state.value if representative else "none",
                    "blocked_reason": (
                        representative.blocked_reason.value
                        if representative and representative.blocked_reason
                        else None
                    ),
                    "blocked_detail": self._blocked_detail(bundle, representative),
                    "prescription_completeness": completeness,
                    "exercises": exercises,
                }
            )
        selected_ordinal = (
            target_microcycle
            if target_microcycle is not None
            else min(target_ordinals)
            if target_ordinals
            else self._fallback_target_ordinal(bundle, as_of)
        )
        target_mc = next(
            (item for item in bundle.microcycles if item["ordinal"] == selected_ordinal),
            None,
        )
        return {
            "as_of": as_of,
            "target_microcycle": self._microcycle_ref(target_mc) if target_mc else None,
            "workouts": workouts,
        }

    @staticmethod
    def _representative_resolution(items: list[NextResolution]) -> NextResolution | None:
        priority = {"blocked": 0, "locked": 1, "editable": 2, "none": 3}
        return min(items, key=lambda item: priority[item.state.value]) if items else None

    @staticmethod
    def _fallback_target_ordinal(bundle: RunBundle, as_of: date) -> int | None:
        current = next(
            (
                item
                for item in bundle.microcycles
                if item["starts_on"] <= as_of <= item["ends_on"]
            ),
            None,
        )
        if current and current["ordinal"] < bundle.run["microcycle_count"]:
            return cast(int, current["ordinal"] + 1)
        return cast(int | None, current["ordinal"] if current else None)

    def _queue_exercise(
        self,
        bundle: RunBundle,
        track: Row,
        target: Row | None,
    ) -> dict[str, Any]:
        last = self._latest_performance(bundle, track["id"])
        performed_sets = self._performed_sets(bundle, last["id"]) if last else []
        target_saved = bool(
            target
            and any(
                item["workout_session_id"] == target["id"]
                and item["exercise_unit_track_id"] == track["id"]
                for item in bundle.exercise_prescriptions
            )
        )
        return {
            "exercise_trace_id": track["id"],
            "slot_ordinal": self._logical_ordinal(track["logical_key"], "slot"),
            "name": self._display_name(bundle, track),
            "prescription_saved": target_saved,
            "last_summary": (
                {
                    "microcycle_ordinal": last["microcycle_ordinal"],
                    "execution_mode": last["execution_mode"],
                    "top_load_kg": self._top_load(performed_sets),
                    "reps": [item["repetitions"] for item in performed_sets],
                }
                if last
                else None
            ),
        }

    def _blocked_detail(
        self,
        bundle: RunBundle,
        resolution: NextResolution | None,
    ) -> dict[str, Any] | None:
        session = resolution.blocking_session if resolution else None
        if session is None:
            return None
        performance = next(
            (
                item
                for item in bundle.workout_performances
                if item["workout_session_id"] == session["id"]
            ),
            None,
        )
        exercise_count = sum(
            item["workout_unit_track_id"] == session["workout_unit_track_id"]
            for item in bundle.exercise_tracks
        )
        synced = (
            sum(
                item["workout_unit_performance_id"] == performance["id"]
                for item in bundle.exercise_performances
            )
            if performance
            else 0
        )
        return {
            "session_id": session["id"],
            "scheduled_date": session["scheduled_date"],
            "started_at": session["started_at"],
            "synced_exercise_count": synced,
            "exercise_count": exercise_count,
        }

    def _next_prescription(
        self,
        bundle: RunBundle,
        track: Row,
        as_of: date,
    ) -> dict[str, Any]:
        del as_of
        resolution = resolve_next(
            run=bundle.run,
            sessions=bundle.sessions,
            prescriptions=bundle.exercise_prescriptions,
            performances=bundle.exercise_performances,
            workout_track_id=track["workout_unit_track_id"],
            exercise_track_id=track["id"],
        )
        target = resolution.target
        structure = self._target_structure(bundle, track, target)
        plan_sets = structure["sets"]
        basis = resolution.basis_performance
        basis_prescription = (
            next(
                (
                    item
                    for item in bundle.exercise_prescriptions
                    if item["workout_session_id"] == basis["workout_session_id"]
                    and item["exercise_unit_track_id"] == track["id"]
                ),
                None,
            )
            if basis
            else None
        )
        previous_sets = (
            self._prescribed_sets(bundle, basis_prescription["id"])
            if basis_prescription
            else []
        )
        performed_sets = self._performed_sets(bundle, basis["id"]) if basis else []
        performed_by_prescribed_id = {
            item["prescribed_set_id"]: item
            for item in performed_sets
            if item["prescribed_set_id"] is not None and item["status"] == "performed"
        }
        previous_by_ordinal = {item["ordinal"]: item for item in previous_sets}
        previous_loads = [
            numeric(previous_by_ordinal.get(item["ordinal"], {}).get("prescribed_load_kg"))
            for item in plan_sets
        ]
        performance_loads: list[float | None] = []
        for item in plan_sets:
            prescribed = previous_by_ordinal.get(item["ordinal"])
            performed = (
                performed_by_prescribed_id.get(prescribed["id"])
                if prescribed is not None
                else None
            )
            performance_loads.append(
                numeric(performed["load_kg"])
                if performed is not None
                and basis is not None
                and basis["execution_mode"] != "substituted"
                else None
            )
        saved = (
            next(
                (
                    item
                    for item in bundle.exercise_prescriptions
                    if target
                    and item["workout_session_id"] == target["id"]
                    and item["exercise_unit_track_id"] == track["id"]
                ),
                None,
            )
            if target
            else None
        )
        saved_sets = self._prescribed_sets(bundle, saved["id"]) if saved else []
        workout_prescription = (
            next(
                (
                    item
                    for item in bundle.workout_prescriptions
                    if target and item["workout_session_id"] == target["id"]
                ),
                None,
            )
            if target
            else None
        )
        microcycle = (
            next(item for item in bundle.microcycles if item["id"] == target["microcycle_id"])
            if target
            else None
        )
        return {
            "state": resolution.state.value,
            "blocked_reason": (
                resolution.blocked_reason.value if resolution.blocked_reason else None
            ),
            "target": (
                {
                    "session_id": target["id"],
                    "workout_trace_id": target["workout_unit_track_id"],
                    "scheduled_date": target["scheduled_date"],
                    "microcycle": self._microcycle_ref(microcycle),
                    "session_status": target["status"],
                }
                if target and microcycle
                else None
            ),
            "basis": (
                {
                    "exercise_performance_id": basis["id"],
                    "microcycle_ordinal": basis["microcycle_ordinal"],
                    "scheduled_date": basis["scheduled_date"],
                    "status": basis["workout_performance_status"],
                    "execution_mode": basis["execution_mode"],
                }
                if basis
                else None
            ),
            "plan_sets": [self._plan_set(item) for item in plan_sets],
            "plan_comment": structure["slot"]["description"] if structure["slot"] else None,
            "defaults": {
                "from_previous_prescription": previous_loads,
                "from_previous_performance": performance_loads,
                "from_seed_run": None,
            },
            "prescription": (
                {
                    "exercise_prescription_id": saved["id"],
                    "version": version_of(saved["updated_at"]),
                    "workout_prescription_version": version_of(
                        cast(Row, workout_prescription)["updated_at"]
                    ),
                    "sets": [
                        {
                            "ordinal": item["ordinal"],
                            "load_kg": numeric(item["prescribed_load_kg"]),
                            "comment": item["prescription_comment"],
                        }
                        for item in saved_sets
                    ],
                    "prescription_comment": saved["prescription_comment"],
                    "updated_at": saved["updated_at"],
                }
                if saved
                else None
            ),
            "suggestion": None,
        }

    def _exercise_trace(
        self,
        bundle: RunBundle,
        as_of: date,
        exercise_track_id: int,
        *,
        include_next: bool,
    ) -> dict[str, Any]:
        track = self._exercise_track(bundle, exercise_track_id)
        workout = next(
            item
            for item in bundle.workout_tracks
            if item["id"] == track["workout_unit_track_id"]
        )
        exposures: list[dict[str, Any]] = []
        prescriptions = [
            item
            for item in bundle.exercise_prescriptions
            if item["exercise_unit_track_id"] == exercise_track_id
        ]
        for prescription in prescriptions:
            session = self._session(bundle, prescription["workout_session_id"])
            microcycle = next(
                item for item in bundle.microcycles if item["id"] == session["microcycle_id"]
            )
            performance = next(
                (
                    item
                    for item in bundle.exercise_performances
                    if item["prescribed_exercise_unit_id"] == prescription["id"]
                ),
                None,
            )
            prescribed_sets = self._prescribed_sets(bundle, prescription["id"])
            exposures.append(
                {
                    "microcycle": self._microcycle_ref(microcycle),
                    "session": {
                        "session_id": session["id"],
                        "scheduled_date": session["scheduled_date"],
                        "status": session["status"],
                        "completion_mode": session["completion_mode"],
                    },
                    "prescription": {
                        "exercise_prescription_id": prescription["id"],
                        "exercise": self._exercise_ref(
                            prescription["prescribed_exercise_id"],
                            prescription["prescribed_exercise_slug"],
                            prescription["prescribed_exercise_name"],
                            prescription["prescribed_exercise_name_full"],
                        ),
                        "plan_comment": prescription["plan_description_snapshot"],
                        "prescription_comment": prescription["prescription_comment"],
                        "based_on_performance_microcycle_ordinal": self._basis_microcycle(
                            bundle, prescription["previous_exercise_performance_id"]
                        ),
                        "sets": [self._prescription_set(item) for item in prescribed_sets],
                    },
                    "performance": (
                        self._exposure_performance(bundle, performance, prescribed_sets)
                        if performance
                        else None
                    ),
                }
            )
        exposures.sort(key=lambda item: item["session"]["scheduled_date"])
        structure = self._target_structure(bundle, track, None)
        revision_nos = sorted(
            {item["microcycle"]["plan_revision_no"] for item in exposures}
            or {item["plan_revision_no"] for item in bundle.microcycles}
        )
        first_ordinal = (
            min(item["microcycle"]["ordinal"] for item in exposures)
            if exposures
            else bundle.microcycles[0]["ordinal"]
        )
        return {
            "as_of": as_of,
            "trace": {
                "exercise_trace_id": track["id"],
                "workout_trace": {
                    "workout_trace_id": workout["id"],
                    "workout_name": workout["name"],
                },
                "slot_ordinal": self._logical_ordinal(track["logical_key"], "slot"),
                "display_name": self._display_name(bundle, track),
                "current_plan": {
                    "plan_revision_no": structure["revision_no"],
                    "slot_role": self._role_label(structure["slot"]["role"]),
                    "exercise": self._variant_exercise_ref(structure["variant"]),
                    "sets": [self._plan_set(item) for item in structure["sets"]],
                    "plan_comment": structure["slot"]["description"],
                    "progression_model": structure["variant"]["progression_model_slug"],
                    "load_step_kg": None,
                },
                "continuity": {
                    "first_microcycle_ordinal": first_ordinal,
                    "revisions_spanned": revision_nos,
                    "continues_from": None,
                    "continued_by": None,
                },
            },
            "revision_transitions": self._exercise_revision_transitions(bundle, track),
            "exposures": exposures,
            "next": self._next_prescription(bundle, track, as_of) if include_next else None,
        }

    def _exposure_performance(
        self,
        bundle: RunBundle,
        performance: Row,
        prescribed_sets: list[Row],
    ) -> dict[str, Any]:
        sets = self._performed_sets(bundle, performance["id"])
        prescribed_by_id = {item["id"]: item for item in prescribed_sets}
        output_sets = []
        for item in sets:
            prescribed = prescribed_by_id.get(item["prescribed_set_id"])
            comparison_set = prescribed or (prescribed_sets[-1] if prescribed_sets else None)
            prescribed_rir = (
                target_rir(comparison_set["target_rir"]) if comparison_set else None
            )
            output_sets.append(
                {
                    "ordinal": item["ordinal"],
                    "prescribed_set_ordinal": prescribed["ordinal"] if prescribed else None,
                    "status": item["status"],
                    "load_kg": numeric(item["load_kg"]),
                    "repetitions": item["repetitions"],
                    "rir": item["rir"],
                    "comment": item["performance_comment"],
                    "recorded_at": item["recorded_at"],
                    "is_additional": prescribed is None,
                    "divergence": divergence(
                        execution_mode=performance["execution_mode"],
                        performed_status=item["status"],
                        prescribed_load=(prescribed["prescribed_load_kg"] if prescribed else None),
                        performed_load=item["load_kg"],
                        rep_min=comparison_set["rep_min"] if comparison_set else None,
                        rep_max=comparison_set["rep_max"] if comparison_set else None,
                        repetitions=item["repetitions"],
                        prescribed_rir=prescribed_rir,
                        performed_rir=item["rir"],
                        is_additional=prescribed is None,
                    ),
                }
            )
        total_reps = sum(item["repetitions"] or 0 for item in sets if item["status"] == "performed")
        volume = sum(
            numeric(item["load_kg"]) * item["repetitions"]
            for item in sets
            if item["status"] == "performed"
            and item["load_kg"] is not None
            and item["repetitions"] is not None
        )
        return {
            "status": performance["workout_performance_status"],
            "execution_mode": performance["execution_mode"],
            "actual_exercise": (
                self._exercise_ref(
                    performance["actual_exercise_id"],
                    performance["actual_exercise_slug"],
                    performance["actual_exercise_name"],
                    performance["actual_exercise_name_full"],
                )
                if performance["actual_exercise_id"] is not None
                else None
            ),
            "comment": performance["performance_comment"],
            "sets": output_sets,
            "summary": {
                "total_reps": total_reps,
                "volume_load_kg": round(volume, 2),
                "top_load_kg": self._top_load(sets),
            },
        }

    def _target_structure(
        self,
        bundle: RunBundle,
        track: Row,
        target: Row | None,
    ) -> dict[str, Any]:
        if target is not None:
            revision_id = target["plan_revision_id"]
            day_ordinal = target["day_ordinal"]
            revision_no = target["plan_revision_no"]
        else:
            governing = bundle.microcycles[-1]
            revision_id = governing["plan_revision_id"]
            revision_no = governing["plan_revision_no"]
            workout = next(
                item
                for item in bundle.workout_tracks
                if item["id"] == track["workout_unit_track_id"]
            )
            day_ordinal = self._logical_ordinal(workout["logical_key"], "day")
        workout_source = next(
            (
                item
                for item in bundle.plan_workouts
                if item["revision_id"] == revision_id and item["day_ordinal"] == day_ordinal
            ),
            None,
        )
        slot_ordinal = self._logical_ordinal(track["logical_key"], "slot")
        slot = (
            next(
                (
                    item
                    for item in bundle.plan_slots
                    if workout_source
                    and item["workout_unit_id"] == workout_source["id"]
                    and item["ordinal"] == slot_ordinal
                ),
                None,
            )
            if workout_source
            else None
        )
        variant = (
            next(
                (
                    item
                    for item in bundle.plan_variants
                    if slot
                    and item["slot_id"] == slot["id"]
                    and item["variant_type"] == "DEFAULT"
                ),
                None,
            )
            if slot
            else None
        )
        if slot is None or variant is None:
            raise not_found(
                "exercise_trace_not_found",
                "Exercise trace is not present in the governing revision",
            )
        sets = sorted(
            (
                item
                for item in bundle.plan_sets
                if item["exercise_variant_id"] == variant["id"]
            ),
            key=lambda item: item["ordinal"],
        )
        return {
            "revision_id": revision_id,
            "revision_no": revision_no,
            "workout": workout_source,
            "slot": slot,
            "variant": variant,
            "sets": sets,
        }

    def _display_name(self, bundle: RunBundle, track: Row) -> str:
        return cast(str, self._target_structure(bundle, track, None)["variant"]["exercise_name"])

    @staticmethod
    def _plan_set(item: Row) -> dict[str, Any]:
        return {
            "ordinal": item["ordinal"],
            "role": item.get("role") or item.get("set_role_snapshot"),
            "rep_min": item["rep_min"],
            "rep_max": item["rep_max"],
            "target_rir": target_rir(item["target_rir"]),
        }

    def _prescription_set(self, item: Row) -> dict[str, Any]:
        return {
            **self._plan_set(item),
            "load_kg": numeric(item["prescribed_load_kg"]),
            "comment": item["prescription_comment"],
        }

    @staticmethod
    def _exercise_ref(
        exercise_id: int,
        slug: str,
        name: str,
        name_full: str,
    ) -> dict[str, Any]:
        return {
            "exercise_id": exercise_id,
            "slug": slug,
            "name": name,
            "variant_label": name_full,
        }

    def _variant_exercise_ref(self, variant: Row) -> dict[str, Any]:
        return self._exercise_ref(
            variant["exercise_id"],
            variant["exercise_slug"],
            variant["exercise_name"],
            variant["exercise_name_full"],
        )

    @staticmethod
    def _role_label(value: str) -> str:
        return value.replace("_", " ").title()

    @staticmethod
    def _prescribed_sets(bundle: RunBundle, prescription_id: int) -> list[Row]:
        return [
            item
            for item in bundle.set_prescriptions
            if item["exercise_unit_prescription_id"] == prescription_id
        ]

    @staticmethod
    def _performed_sets(bundle: RunBundle, performance_id: int) -> list[Row]:
        return [
            item
            for item in bundle.set_performances
            if item["exercise_unit_performance_id"] == performance_id
        ]

    @staticmethod
    def _latest_performance(bundle: RunBundle, exercise_track_id: int) -> Row | None:
        rows = [
            item
            for item in bundle.exercise_performances
            if item["exercise_unit_track_id"] == exercise_track_id
            and item["workout_performance_status"] == "finalized"
        ]
        return max(rows, key=lambda item: (item["scheduled_date"], item["id"])) if rows else None

    @staticmethod
    def _top_load(sets: list[Row]) -> float | None:
        loads = [
            numeric(item["load_kg"])
            for item in sets
            if item.get("status", "performed") == "performed" and item.get("load_kg") is not None
        ]
        return max(cast(list[float], loads)) if loads else None

    @staticmethod
    def _basis_microcycle(bundle: RunBundle, performance_id: int | None) -> int | None:
        if performance_id is None:
            return None
        performance = next(
            (item for item in bundle.exercise_performances if item["id"] == performance_id),
            None,
        )
        return cast(int, performance["microcycle_ordinal"]) if performance else None

    def _exercise_revision_transitions(
        self,
        bundle: RunBundle,
        track: Row,
    ) -> list[dict[str, Any]]:
        output: list[dict[str, Any]] = []
        for previous, current in zip(
            bundle.microcycles, bundle.microcycles[1:], strict=False
        ):
            if previous["plan_revision_id"] == current["plan_revision_id"]:
                continue
            before = self._structure_for_microcycle(bundle, track, previous)
            after = self._structure_for_microcycle(bundle, track, current)
            changes: list[str] = []
            if before["slot"]["description"] != after["slot"]["description"]:
                changes.append("plan_comment")
            if before["variant"]["exercise_id"] != after["variant"]["exercise_id"]:
                changes.append("exercise")
            if len(before["sets"]) != len(after["sets"]):
                changes.append("set_count")
            if [
                (item["rep_min"], item["rep_max"]) for item in before["sets"]
            ] != [(item["rep_min"], item["rep_max"]) for item in after["sets"]]:
                changes.append("rep_range")
            if [item["target_rir"] for item in before["sets"]] != [
                item["target_rir"] for item in after["sets"]
            ]:
                changes.append("target_rir")
            if before["slot"]["role"] != after["slot"]["role"]:
                changes.append("role")
            event = next(
                (
                    item
                    for item in bundle.events
                    if item["event_type"] == "plan_revision_changed"
                    and item["microcycle_id"] == current["id"]
                ),
                None,
            )
            output.append(
                {
                    "before_microcycle_ordinal": current["ordinal"],
                    "from_revision_no": previous["plan_revision_no"],
                    "to_revision_no": current["plan_revision_no"],
                    "effective_on": current["starts_on"],
                    "slot_changes": changes,
                    "event_id": event["id"] if event else None,
                }
            )
        return output

    def _structure_for_microcycle(
        self,
        bundle: RunBundle,
        track: Row,
        microcycle: Row,
    ) -> dict[str, Any]:
        workout = next(
            item
            for item in bundle.workout_tracks
            if item["id"] == track["workout_unit_track_id"]
        )
        day_ordinal = self._logical_ordinal(workout["logical_key"], "day")
        target = next(
            (
                item
                for item in bundle.sessions
                if item["microcycle_id"] == microcycle["id"]
                and item["workout_unit_track_id"] == workout["id"]
            ),
            None,
        )
        if target is None:
            target = {
                "plan_revision_id": microcycle["plan_revision_id"],
                "plan_revision_no": microcycle["plan_revision_no"],
                "day_ordinal": day_ordinal,
            }
        return self._target_structure(bundle, track, target)

    def _latest_exposure(self, bundle: RunBundle) -> dict[str, Any] | None:
        if not bundle.workout_performances:
            return None
        latest = max(
            bundle.workout_performances,
            key=lambda item: (
                self._session(bundle, item["workout_session_id"])["scheduled_date"],
                item["id"],
            ),
        )
        session = self._session(bundle, latest["workout_session_id"])
        exercise_performances = [
            item
            for item in bundle.exercise_performances
            if item["workout_unit_performance_id"] == latest["id"]
        ]
        exercises = []
        for performance in exercise_performances:
            prescription = next(
                (
                    item
                    for item in bundle.exercise_prescriptions
                    if item["id"] == performance["prescribed_exercise_unit_id"]
                ),
                None,
            )
            prescribed_sets = (
                self._prescribed_sets(bundle, prescription["id"])
                if prescription
                else []
            )
            performed_sets = self._performed_sets(bundle, performance["id"])
            events = [
                item
                for item in bundle.events
                if item["event_type"] == "personal_record"
                and item["exercise_unit_track_id"] == performance["exercise_unit_track_id"]
                and item["workout_session_id"] == session["id"]
            ]
            exercises.append(
                {
                    "exercise_trace_id": performance["exercise_unit_track_id"],
                    "name": (
                        prescription["prescribed_exercise_name"]
                        if prescription
                        else performance["actual_exercise_name"]
                    ),
                    "execution_mode": performance["execution_mode"],
                    "prescribed_summary": {
                        "set_count": len(prescribed_sets),
                        "top_load_kg": (
                            max(
                                cast(
                                    list[float],
                                    [
                                        numeric(item["prescribed_load_kg"])
                                        for item in prescribed_sets
                                        if item["prescribed_load_kg"] is not None
                                    ],
                                )
                            )
                            if any(
                                item["prescribed_load_kg"] is not None
                                for item in prescribed_sets
                            )
                            else None
                        ),
                        "rep_min": min((item["rep_min"] for item in prescribed_sets), default=None),
                        "rep_max": max((item["rep_max"] for item in prescribed_sets), default=None),
                        "target_rir": (
                            target_rir(prescribed_sets[0]["target_rir"])
                            if prescribed_sets
                            else None
                        ),
                    },
                    "performed_reps": [item["repetitions"] for item in performed_sets],
                    "performed_rir": [item["rir"] for item in performed_sets],
                    "flags": flags_for(
                        execution_mode=performance["execution_mode"],
                        prescribed_sets=prescribed_sets,
                        performed_sets=performed_sets,
                        personal_record=bool(events),
                    ),
                }
            )
        return {
            "session_id": session["id"],
            "workout_trace_id": session["workout_unit_track_id"],
            "workout_name": session["workout_name"],
            "scheduled_date": session["scheduled_date"],
            "exercises": exercises,
        }

    def _event_dto(self, bundle: RunBundle, event: Row) -> dict[str, Any]:
        microcycle = next(
            (item for item in bundle.microcycles if item["id"] == event["microcycle_id"]),
            None,
        )
        metadata = dict(event["metadata"] or {})
        source = metadata.pop("_source", None)
        if source not in {"system", "user"}:
            source = (
                "system"
                if event["event_type"]
                in {"plan_revision_changed", "deload_started", "reload_started"}
                or metadata.get("kind") == "run_created"
                else "user"
            )
        return {
            "event_id": event["id"],
            "event_type": event["event_type"],
            "title": event["title"],
            "occurred_at": event["occurred_at"],
            "date": event["occurred_at"].date(),
            "microcycle_ordinal": event["microcycle_ordinal"],
            "day_in_microcycle": (
                (event["occurred_at"].date() - microcycle["starts_on"]).days + 1
                if microcycle
                else None
            ),
            "session": (
                {
                    "session_id": event["workout_session_id"],
                    "workout_name": event["event_workout_name"],
                }
                if event["workout_session_id"]
                else None
            ),
            "exercise_trace": (
                {
                    "exercise_trace_id": event["exercise_unit_track_id"],
                    "display_name": event["exercise_trace_name"],
                }
                if event["exercise_unit_track_id"]
                else None
            ),
            "from_revision_no": event["from_revision_no"],
            "to_revision_no": event["to_revision_no"],
            "body": event["details"],
            "source": source,
            "metadata": metadata,
        }

    def _workout_trace(
        self,
        bundle: RunBundle,
        as_of: date,
        workout: Row,
    ) -> dict[str, Any]:
        tracks = [
            item
            for item in bundle.exercise_tracks
            if item["workout_unit_track_id"] == workout["id"]
        ]
        tracks.sort(key=lambda item: self._logical_ordinal(item["logical_key"], "slot"))
        sessions = [
            item
            for item in bundle.sessions
            if item["workout_unit_track_id"] == workout["id"]
        ]
        sessions.sort(key=lambda item: item["microcycle_ordinal"])
        columns = []
        for track in tracks:
            structure = self._target_structure(bundle, track, None)
            series: list[float | None] = []
            exposure_ordinals: list[int] = []
            for microcycle in bundle.microcycles:
                session = next(
                    (
                        item
                        for item in sessions
                        if item["microcycle_id"] == microcycle["id"]
                    ),
                    None,
                )
                performance = self._performance_for_session_trace(
                    bundle, session["id"] if session else None, track["id"]
                )
                value = (
                    self._top_load(self._performed_sets(bundle, performance["id"]))
                    if performance and performance["execution_mode"] == "as_prescribed"
                    else None
                )
                series.append(value)
                if session and any(
                    item["workout_session_id"] == session["id"]
                    and item["exercise_unit_track_id"] == track["id"]
                    for item in bundle.exercise_prescriptions
                ):
                    exposure_ordinals.append(microcycle["ordinal"])
            values = [item for item in series if item is not None]
            plan_sets = structure["sets"]
            columns.append(
                {
                    "exercise_trace_id": track["id"],
                    "slot_ordinal": self._logical_ordinal(track["logical_key"], "slot"),
                    "display_name": self._display_name(bundle, track),
                    "scheme": {
                        "set_count": len(plan_sets),
                        "rep_min": min((item["rep_min"] for item in plan_sets), default=None),
                        "rep_max": max((item["rep_max"] for item in plan_sets), default=None),
                        "target_rir": target_rir(plan_sets[0]["target_rir"]) if plan_sets else None,
                    },
                    "top_load_series": series,
                    "delta_pct_first_to_latest": (
                        delta_pct(values[0], values[-1]) if values else None
                    ),
                    "first_microcycle_ordinal": min(exposure_ordinals) if exposure_ordinals else 1,
                    "last_microcycle_ordinal": None,
                }
            )
        rows = [self._workout_trace_row(bundle, session, tracks) for session in sessions]
        transitions: list[dict[str, Any]] = []
        for previous, current in zip(
            bundle.microcycles, bundle.microcycles[1:], strict=False
        ):
            if previous["plan_revision_id"] == current["plan_revision_id"]:
                continue
            summaries: list[str] = []
            for track in tracks:
                transition = next(
                    (
                        item
                        for item in self._exercise_revision_transitions(bundle, track)
                        if item["before_microcycle_ordinal"] == current["ordinal"]
                    ),
                    None,
                )
                if transition and transition["slot_changes"]:
                    summaries.append(
                        f"{track['name']}: {', '.join(transition['slot_changes'])}"
                    )
            transitions.append(
                {
                    "before_microcycle_ordinal": current["ordinal"],
                    "from_revision_no": previous["plan_revision_no"],
                    "to_revision_no": current["plan_revision_no"],
                    "summary": "; ".join(summaries) or "No tracked slot changes",
                }
            )
        return {
            "as_of": as_of,
            "workout": {
                "workout_trace_id": workout["id"],
                "workout_name": workout["name"],
                "day_ordinal": self._logical_ordinal(workout["logical_key"], "day"),
            },
            "columns": columns,
            "revision_transitions": transitions,
            "rows": rows,
        }

    def _workout_trace_row(
        self,
        bundle: RunBundle,
        session: Row,
        tracks: list[Row],
    ) -> dict[str, Any]:
        microcycle = next(
            item for item in bundle.microcycles if item["id"] == session["microcycle_id"]
        )
        workout_performance = next(
            (
                item
                for item in bundle.workout_performances
                if item["workout_session_id"] == session["id"]
            ),
            None,
        )
        cells = []
        volume = 0.0
        has_volume = False
        for track in tracks:
            prescription = next(
                (
                    item
                    for item in bundle.exercise_prescriptions
                    if item["workout_session_id"] == session["id"]
                    and item["exercise_unit_track_id"] == track["id"]
                ),
                None,
            )
            performance = self._performance_for_session_trace(
                bundle, session["id"], track["id"]
            )
            prescribed_sets = (
                self._prescribed_sets(bundle, prescription["id"])
                if prescription
                else []
            )
            performed_sets = (
                self._performed_sets(bundle, performance["id"])
                if performance
                else []
            )
            for item in performed_sets:
                if (
                    item["status"] == "performed"
                    and item["load_kg"] is not None
                    and item["repetitions"] is not None
                ):
                    volume += cast(float, numeric(item["load_kg"])) * item["repetitions"]
                    has_volume = True
            kind = "performed" if performance else "prescribed" if prescription else "empty"
            cells.append(
                {
                    "exercise_trace_id": track["id"],
                    "kind": kind,
                    "execution_mode": performance["execution_mode"] if performance else None,
                    "actual_exercise_name": (
                        performance["actual_exercise_name"] if performance else None
                    ),
                    "prescribed_top_load_kg": (
                        max(
                            cast(
                                list[float],
                                [
                                    numeric(item["prescribed_load_kg"])
                                    for item in prescribed_sets
                                    if item["prescribed_load_kg"] is not None
                                ],
                            )
                        )
                        if any(item["prescribed_load_kg"] is not None for item in prescribed_sets)
                        else None
                    ),
                    "performed_top_load_kg": self._top_load(performed_sets),
                    "reps": [
                        item["repetitions"] if item["status"] == "performed" else None
                        for item in performed_sets
                    ],
                    "flags": flags_for(
                        execution_mode=(performance["execution_mode"] if performance else None),
                        prescribed_sets=prescribed_sets,
                        performed_sets=performed_sets,
                    ),
                    "next_prescription_saved": bool(prescription)
                    if session["status"] == "scheduled"
                    else None,
                }
            )
        return {
            "microcycle": self._microcycle_ref(microcycle),
            "session": {
                "session_id": session["id"],
                "scheduled_date": session["scheduled_date"],
                "status": session["status"],
                "completion_mode": session["completion_mode"],
                "started_at": session["started_at"],
                "completed_at": session["completed_at"],
            },
            "prescription_completeness": self._completeness(bundle, session),
            "performance_comment": (
                workout_performance["performance_comment"] if workout_performance else None
            ),
            "volume_load_kg": round(volume, 2) if has_volume else None,
            "progress_marker": None,
            "cells": cells,
        }

    @staticmethod
    def _performance_for_session_trace(
        bundle: RunBundle,
        session_id: int | None,
        exercise_track_id: int,
    ) -> Row | None:
        return next(
            (
                item
                for item in bundle.exercise_performances
                if item["workout_session_id"] == session_id
                and item["exercise_unit_track_id"] == exercise_track_id
            ),
            None,
        )

    def _timeline(self, bundle: RunBundle, as_of: date) -> dict[str, Any]:
        current = self._current_microcycle(bundle, as_of)
        governing = current or bundle.microcycles[-1]
        plan_days = [
            item
            for item in bundle.plan_days
            if item["revision_id"] == governing["plan_revision_id"]
        ]
        workouts_by_day = {
            self._logical_ordinal(item["logical_key"], "day"): item
            for item in bundle.workout_tracks
        }
        # Track identity is day-based; rest days intentionally have no track.
        day_columns = [
            {
                "day_ordinal": day["ordinal"],
                "workout_trace_id": (
                    workouts_by_day[day["ordinal"]]["id"]
                    if day["ordinal"] in workouts_by_day
                    else None
                ),
                "workout_name": (
                    workouts_by_day[day["ordinal"]]["name"]
                    if day["ordinal"] in workouts_by_day
                    else None
                ),
            }
            for day in plan_days
        ]
        output = []
        for index, microcycle in enumerate(bundle.microcycles):
            sessions = [
                item for item in bundle.sessions if item["microcycle_id"] == microcycle["id"]
            ]
            events = [
                item for item in bundle.events if item["microcycle_id"] == microcycle["id"]
            ]
            volume = self._microcycle_volume(bundle, microcycle["id"])
            output.append(
                {
                    **self._microcycle_ref(microcycle),
                    "revision_changed_here": (
                        index > 0
                        and bundle.microcycles[index - 1]["plan_revision_id"]
                        != microcycle["plan_revision_id"]
                    ),
                    "is_current": bool(current and current["id"] == microcycle["id"]),
                    "notes": microcycle["notes"],
                    "version": version_of(microcycle["updated_at"]),
                    "days": [
                        self._timeline_day(microcycle, day_ordinal, sessions)
                        for day_ordinal in range(bundle.run["microcycle_duration_days"])
                    ],
                    "attendance": attendance_for(microcycle, sessions, as_of),
                    "volume_load_kg": volume,
                    "progress_marker": None,
                    "events": [
                        {
                            "event_id": event["id"],
                            "event_type": event["event_type"],
                            "title": event["title"],
                            "occurred_at": event["occurred_at"],
                        }
                        for event in events
                    ],
                }
            )
        return {"as_of": as_of, "day_columns": day_columns, "microcycles": output}

    @staticmethod
    def _timeline_day(
        microcycle: Row,
        day_ordinal: int,
        sessions: list[Row],
    ) -> dict[str, Any]:
        day_date = microcycle["starts_on"] + timedelta(days=day_ordinal)
        session = next((item for item in sessions if item["scheduled_date"] == day_date), None)
        return {
            "day_ordinal": day_ordinal,
            "date": day_date,
            "session": (
                {
                    "session_id": session["id"],
                    "workout_name": session["workout_name"],
                    "status": session["status"],
                    "completion_mode": session["completion_mode"],
                }
                if session
                else None
            ),
        }

    def _microcycle_volume(self, bundle: RunBundle, microcycle_id: int) -> float | None:
        session_ids = {
            item["id"] for item in bundle.sessions if item["microcycle_id"] == microcycle_id
        }
        performance_ids = {
            item["id"]
            for item in bundle.exercise_performances
            if item["workout_session_id"] in session_ids
            and item["workout_performance_status"] == "finalized"
        }
        values = [
            cast(float, numeric(item["load_kg"])) * item["repetitions"]
            for item in bundle.set_performances
            if item["exercise_unit_performance_id"] in performance_ids
            and item["status"] == "performed"
            and item["load_kg"] is not None
            and item["repetitions"] is not None
        ]
        return round(sum(values), 2) if values else None

    def _load_series(
        self,
        bundle: RunBundle,
        as_of: date,
        *,
        metric: str,
        normalize: str,
        workout_track_ids: tuple[int, ...],
        exercise_track_ids: tuple[int, ...],
        include_draft: bool,
    ) -> dict[str, Any]:
        tracks = [
            item
            for item in bundle.exercise_tracks
            if (not workout_track_ids or item["workout_unit_track_id"] in workout_track_ids)
            and (not exercise_track_ids or item["id"] in exercise_track_ids)
        ]
        series_output: list[dict[str, Any]] = []
        for track in tracks:
            performances = [
                item
                for item in bundle.exercise_performances
                if item["exercise_unit_track_id"] == track["id"]
                and (include_draft or item["workout_performance_status"] == "finalized")
            ]
            performances.sort(key=lambda item: (item["scheduled_date"], item["id"]))
            raw_points: list[dict[str, Any]] = []
            for performance in performances:
                sets = self._performed_sets(bundle, performance["id"])
                performed = [
                    item
                    for item in sets
                    if item["status"] == "performed" and item["load_kg"] is not None
                ]
                value: float | None = None
                if performance["execution_mode"] == "as_prescribed" and performed:
                    loads = [cast(float, numeric(item["load_kg"])) for item in performed]
                    if metric == "top_set_load":
                        value = max(loads)
                    elif metric == "mean_set_load":
                        value = round(mean(loads), 2)
                    else:
                        value = round(
                            sum(
                                load * (item["repetitions"] or 0)
                                for load, item in zip(loads, performed, strict=True)
                            ),
                            2,
                        )
                raw_points.append(
                    {
                        "microcycle_ordinal": performance["microcycle_ordinal"],
                        "date": performance["scheduled_date"],
                        "value": value,
                        "set_count": len(sets),
                        "reps": [
                            item["repetitions"] if item["status"] == "performed" else None
                            for item in sets
                        ],
                        "status": performance["workout_performance_status"],
                        "execution_mode": performance["execution_mode"],
                    }
                )
            comparable = [item["value"] for item in raw_points if item["value"] is not None]
            raw_first = comparable[0] if comparable else None
            raw_latest = comparable[-1] if comparable else None
            if normalize == "first_exposure" and raw_first not in (None, 0):
                for point in raw_points:
                    point["value"] = (
                        round(point["value"] / raw_first * 100, 2)
                        if point["value"] is not None
                        else None
                    )
                first_value: float | None = 100.0
                latest_value = (
                    round(raw_latest / raw_first * 100, 2)
                    if raw_latest is not None
                    else None
                )
            else:
                first_value = raw_first
                latest_value = raw_latest
            workout = next(
                item
                for item in bundle.workout_tracks
                if item["id"] == track["workout_unit_track_id"]
            )
            series_output.append(
                {
                    "exercise_trace_id": track["id"],
                    "display_name": self._display_name(bundle, track),
                    "workout_trace_id": workout["id"],
                    "workout_name": workout["name"],
                    "points": raw_points,
                    "first_value": first_value,
                    "latest_value": latest_value,
                    "delta_pct": delta_pct(raw_first, raw_latest),
                }
            )
        by_workout: dict[int, list[dict[str, Any]]] = defaultdict(list)
        for item in series_output:
            by_workout[item["workout_trace_id"]].append(item)
        summaries = []
        for workout_id, items in by_workout.items():
            deltas = [item["delta_pct"] for item in items if item["delta_pct"] is not None]
            summaries.append(
                {
                    "workout_trace_id": workout_id,
                    "workout_name": items[0]["workout_name"],
                    "mean_delta_pct": round(mean(deltas), 1) if deltas else None,
                    "series_count": len(items),
                }
            )
        return {
            "as_of": as_of,
            "metric": metric,
            "x_domain": [
                {
                    "microcycle_ordinal": item["ordinal"],
                    "starts_on": item["starts_on"],
                    "classification": item["classification"],
                    "plan_revision_no": item["plan_revision_no"],
                }
                for item in bundle.microcycles
            ],
            "series": series_output,
            "workout_summaries": summaries,
        }
