from __future__ import annotations

import hashlib
import json
from datetime import date, datetime, timedelta, timezone
from typing import Any, cast
from uuid import UUID

from agonez_api.modules.execution.errors import ExecutionAPIError, not_found
from agonez_api.modules.mobile_execution.repository import MobileExecutionRepository, Row
from agonez_api.modules.mobile_execution.schemas import (
    ActiveWorkoutSummary,
    AtlasPeek,
    AtlasSearchResponse,
    ClaimWorkout,
    FinalizeResponse,
    FinalizeWorkout,
    MobileContext,
    OperationBatch,
    OperationBatchResponse,
    PlanRunCompact,
    StartWorkout,
    WorkoutPrescription,
    WorkoutSnapshot,
)

DB_TO_SVG = {
    "deltoid_anterior": "anterior_deltoid",
    "deltoid_lateral": "lateral_deltoid",
    "deltoid_posterior": "posterior_deltoid",
    "rotator_cuffs": "rotator_cuff",
}


class MobileExecutionService:
    """Mobile-oriented aggregation over the existing Execution and Atlas facts."""

    def __init__(self, repository: MobileExecutionRepository) -> None:
        self._repository = repository

    async def list_plan_runs(self, *, as_of: date | None = None) -> list[PlanRunCompact]:
        target_date = as_of or date.today()
        await self._repository.reconcile(None, target_date)
        rows = await self._repository.list_plan_runs(as_of=target_date)
        return [PlanRunCompact.model_validate(self._plan_run(item)) for item in rows]

    async def get_context(
        self,
        *,
        plan_run_id: int | None,
        as_of: date | None,
        device_id: UUID,
        locale: str,
    ) -> MobileContext:
        target_date = as_of or date.today()
        await self._repository.reconcile(plan_run_id, target_date)
        all_runs = await self._repository.list_plan_runs(as_of=target_date)
        if plan_run_id is None:
            active = [item for item in all_runs if item["status"] == "active"]
            if len(active) > 1:
                return self._empty_context(selection_required=True, target_date=target_date)
            if not active:
                return self._empty_context(selection_required=False, target_date=target_date)
            plan_run_id = cast(int, active[0]["id"])
        context = await self._repository.load_context(plan_run_id=plan_run_id, as_of=target_date)
        active_workout = await self._repository.load_active(plan_run_id=plan_run_id, locale=locale)
        microcycle = context["microcycle"]
        sessions = context["sessions"]
        expected_row = next(
            (
                item
                for item in sessions
                if item["scheduled_date"] == target_date and item["status"] == "scheduled"
            ),
            None,
        )
        alternatives = [
            self._session_summary(
                item,
                relation=(
                    "earlier_missed"
                    if item["scheduled_date"] < target_date
                    else "later_in_microcycle"
                ),
            )
            for item in sessions
            if item is not expected_row and item["status"] in {"scheduled", "missed"}
        ]
        days: list[dict[str, Any]] = []
        today: dict[str, Any] | None = None
        if microcycle is not None:
            day_count = (microcycle["ends_on"] - microcycle["starts_on"]).days + 1
            by_date = {item["scheduled_date"]: item for item in sessions}
            for offset in range(day_count):
                current = microcycle["starts_on"] + timedelta(days=offset)
                session = by_date.get(current)
                days.append(
                    {
                        "date": current,
                        "day_ordinal": offset + 1,
                        "session_id": session["session_id"] if session else None,
                        "workout_unit_name": session["workout_unit_name"] if session else None,
                        "status": session["status"] if session else "rest_day",
                    }
                )
            today = {
                "date": target_date,
                "microcycle": {
                    "id": microcycle["id"],
                    "ordinal": microcycle["ordinal"],
                    "day_ordinal": (target_date - microcycle["starts_on"]).days + 1,
                    "classification": microcycle["classification"],
                },
            }
        run = context["run"]
        active_summary = self._active_summary(active_workout, device_id) if active_workout else None
        version_payload = {
            "run": str(run["updated_at"]),
            "microcycle": str(microcycle["updated_at"]) if microcycle else None,
            "sessions": [
                (item["session_id"], item["status"], item["prescription_version"])
                for item in sessions
            ],
            "active_revision": (active_workout["workout"]["revision"] if active_workout else None),
        }
        version = hashlib.sha256(json.dumps(version_payload, sort_keys=True).encode()).hexdigest()[
            :12
        ]
        return MobileContext(
            generated_at=datetime.now(timezone.utc),
            context_version=f"ctx-{version}",
            plan_run={
                **self._plan_run(run),
                "current_microcycle_ordinal": (
                    microcycle["ordinal"] if microcycle is not None else None
                ),
                "plan_name": run["plan_name"],
                "microcycle_duration_days": run["microcycle_duration_days"],
            },
            selection_required=False,
            today=today,
            microcycle_days=days,
            expected_session=(
                self._session_summary(expected_row) if expected_row is not None else None
            ),
            alternatives=alternatives,
            fallbacks=[],
            active_workout=active_summary,
            recent=[
                {
                    "session_id": item["session_id"],
                    "workout_unit_name": item["workout_unit_name"],
                    "completed_at": item["completed_at"],
                    "performed_sets": item["performed_sets"],
                    "prescribed_sets": item["prescribed_sets"],
                    "skipped_sets": item["skipped_sets"],
                }
                for item in context["recent"]
            ],
        )

    async def get_prescription(self, session_id: int, *, locale: str) -> WorkoutPrescription:
        data = await self._repository.load_prescription(session_id, locale=locale)
        return self._prescription(data)

    async def get_active(
        self, *, plan_run_id: int, device_id: UUID, locale: str
    ) -> ActiveWorkoutSummary:
        data = await self._repository.load_active(plan_run_id=plan_run_id, locale=locale)
        if data is None:
            raise not_found("no_active_workout", "No active workout was found")
        return self._active_summary(data, device_id)

    async def get_workout(
        self, workout_id: UUID, *, device_id: UUID, locale: str
    ) -> WorkoutSnapshot:
        data = await self._repository.load_workout(workout_id, locale=locale)
        prescription = await self._repository.load_prescription(
            data["workout"]["session_id"], locale=locale
        )
        return self._snapshot(data, prescription, device_id)

    async def start_workout(
        self,
        payload: StartWorkout,
        *,
        device_id: UUID,
        locale: str,
    ) -> tuple[WorkoutSnapshot, bool]:
        try:
            workout_id, created = await self._repository.start_workout(
                payload, device_id=device_id
            )
        except ExecutionAPIError as exc:
            if exc.code == "prescription_changed":
                fresh = await self.get_prescription(payload.session_id, locale=locale)
                exc.details["prescription"] = fresh.model_dump(mode="json")
            raise
        return (
            await self.get_workout(workout_id, device_id=device_id, locale=locale),
            created,
        )

    async def claim_workout(
        self,
        workout_id: UUID,
        payload: ClaimWorkout,
        *,
        device_id: UUID,
        locale: str,
    ) -> WorkoutSnapshot:
        await self._repository.claim_workout(workout_id, payload, header_device_id=device_id)
        return await self.get_workout(workout_id, device_id=device_id, locale=locale)

    async def apply_operations(
        self,
        workout_id: UUID,
        batch: OperationBatch,
        *,
        device_id: UUID,
    ) -> OperationBatchResponse:
        result = await self._repository.apply_operations(workout_id, batch, device_id=device_id)
        return OperationBatchResponse(
            **result,
            unsupported_fields=[],
            server_time=datetime.now(timezone.utc),
        )

    async def finalize_workout(
        self,
        workout_id: UUID,
        payload: FinalizeWorkout,
        *,
        device_id: UUID,
    ) -> FinalizeResponse:
        result = await self._repository.finalize_workout(workout_id, payload, device_id=device_id)
        return FinalizeResponse(**result)

    async def get_atlas_peek(self, exercise_id: int, *, locale: str) -> AtlasPeek:
        return self._atlas_peek(
            await self._repository.load_atlas_peek(exercise_id, locale=locale), locale
        )

    async def search_atlas(
        self,
        *,
        q: str | None,
        limit: int,
        plan_run_id: int | None,
        locale: str,
    ) -> AtlasSearchResponse:
        rows = await self._repository.search_atlas(
            q=q, limit=limit, plan_run_id=plan_run_id, locale=locale
        )
        return AtlasSearchResponse(
            items=[
                {
                    "id": row["id"],
                    "slug": row["slug"],
                    "name": row["name"],
                    "full_name": row["full_name"],
                    "mechanics_tier": row["mechanics_tier"],
                    "target_category": row["target_category"],
                    "last_performed_in_run": (
                        {
                            "microcycle_ordinal": row["last_performed_in_run"][
                                "microcycle_ordinal"
                            ],
                            "sets": [
                                {
                                    "load_kg": self._number(item["load_kg"]),
                                    "repetitions": item["repetitions"],
                                    "rir": item["rir"],
                                }
                                for item in row["last_performed_in_run"]["sets"]
                            ],
                        }
                        if row["last_performed_in_run"] is not None
                        else None
                    ),
                }
                for row in rows
            ]
        )

    def _prescription(self, data: dict[str, Any]) -> WorkoutPrescription:
        session = data["session"]
        sets_by_exercise: dict[int, list[Row]] = {}
        for item in data["sets"]:
            sets_by_exercise.setdefault(item["exercise_unit_prescription_id"], []).append(item)
        alternatives_by_exercise: dict[int, list[Row]] = {}
        for item in data["alternatives"]:
            alternatives_by_exercise.setdefault(item["exercise_prescription_id"], []).append(item)
        previous_by_exercise = {item["exercise_prescription_id"]: item for item in data["previous"]}
        previous_sets: dict[int, list[Row]] = {}
        for item in data["previous_sets"]:
            previous_sets.setdefault(item["exercise_prescription_id"], []).append(item)
        exercises: list[dict[str, Any]] = []
        for item in data["exercises"]:
            exercise_id = item["exercise_prescription_id"]
            previous = previous_by_exercise.get(exercise_id)
            role = item["slot_role"]
            exercises.append(
                {
                    "exercise_prescription_id": exercise_id,
                    "ordinal": item["ordinal"],
                    "exercise_track_id": item["exercise_track_id"],
                    "slot": {"goal": item["plan_goal_snapshot"], "role": role},
                    "exercise": self._exercise_identity(
                        item["prescribed_exercise_id"],
                        item["slug"],
                        item["name"],
                        item["full_name"],
                    ),
                    "variant_label": item["slot_name_snapshot"] or item["full_name"],
                    "plan_comment": item["plan_description_snapshot"],
                    "prescription_comment": item["prescription_comment"],
                    "load_step_kg": 2.5,
                    "default_rest_s": (
                        180 if role in {"primary_progressive", "secondary_progressive"} else 90
                    ),
                    "sets": [
                        {
                            "set_prescription_id": set_item["set_prescription_id"],
                            "ordinal": set_item["ordinal"],
                            "role": set_item["role"],
                            "prescribed_load_kg": self._number(set_item["prescribed_load_kg"]),
                            "rep_min": set_item["rep_min"],
                            "rep_max": set_item["rep_max"],
                            "target_rir": self._target_rir(set_item["target_rir"]),
                            "comment": set_item["prescription_comment"],
                        }
                        for set_item in sets_by_exercise.get(exercise_id, [])
                    ],
                    "alternatives": [
                        {
                            "exercise": self._exercise_identity(
                                alternative["exercise_id"],
                                alternative["slug"],
                                alternative["name"],
                                alternative["full_name"],
                            ),
                            "source": "plan_variant",
                            "variant_ordinal": alternative["variant_ordinal"],
                            "atlas_peek": self._atlas_peek(
                                data["peeks"][alternative["exercise_id"]],
                                data["locale"],
                            ),
                        }
                        for alternative in alternatives_by_exercise.get(exercise_id, [])
                    ],
                    "history": {
                        "previous_exposure": (
                            {
                                "microcycle_ordinal": previous["microcycle_ordinal"],
                                "performed_on": previous["performed_on"],
                                "exercise": self._exercise_identity(
                                    previous["actual_exercise_id"],
                                    previous["slug"],
                                    previous["name"],
                                    previous["full_name"],
                                ),
                                "sets": [
                                    {
                                        "ordinal": set_item["ordinal"],
                                        "status": set_item["status"],
                                        "load_kg": self._number(set_item["load_kg"]),
                                        "repetitions": set_item["repetitions"],
                                        "rir": set_item["rir"],
                                    }
                                    for set_item in previous_sets.get(exercise_id, [])
                                ],
                            }
                            if previous and previous["exercise_performance_id"] is not None
                            else None
                        )
                    },
                    "atlas_peek": self._atlas_peek(
                        data["peeks"][item["prescribed_exercise_id"]], data["locale"]
                    ),
                }
            )
        return WorkoutPrescription(
            session_id=session["session_id"],
            prescription_id=session["prescription_id"],
            prescription_version=data["version"],
            workout_unit_name=session["workout_unit_name"],
            workout_track_id=session["workout_track_id"],
            microcycle={
                "ordinal": session["microcycle_ordinal"],
                "classification": session["microcycle_classification"],
            },
            plan_comment=session["description_snapshot"],
            prescription_comment=session["workout_prescription_comment"],
            exercises=exercises,
        )

    def _snapshot(
        self,
        data: dict[str, Any],
        prescription: dict[str, Any],
        device_id: UUID,
    ) -> WorkoutSnapshot:
        workout = data["workout"]
        sets_by_exercise: dict[int, list[Row]] = {}
        for item in data["sets"]:
            sets_by_exercise.setdefault(item["exercise_unit_performance_id"], []).append(item)
        return WorkoutSnapshot(
            workout_id=workout["client_uuid"],
            session_id=workout["session_id"],
            status=("completed" if workout["performance_status"] == "finalized" else "in_progress"),
            started_at=workout["started_at"],
            finished_at=workout["completed_at"],
            lease=self._lease(workout, device_id),
            applied_seq=workout["applied_seq"],
            revision=workout["revision"],
            position_hint=self._position_hint(workout),
            prescription=self._prescription(prescription),
            performance={
                "comment": workout["performance_comment"],
                "exercises": [
                    {
                        "exercise_performance_id": exercise["client_uuid"],
                        "exercise_prescription_id": exercise["prescribed_exercise_unit_id"],
                        "performed_ordinal": exercise["performed_ordinal"],
                        "mode": (
                            "added"
                            if exercise["execution_mode"] == "additional"
                            else exercise["execution_mode"]
                        ),
                        "actual_exercise": (
                            self._exercise_identity(
                                exercise["actual_exercise_id"],
                                exercise["actual_slug"],
                                exercise["actual_name"],
                                exercise["actual_full_name"],
                            )
                            if exercise["actual_exercise_id"] is not None
                            else None
                        ),
                        "comment": exercise["performance_comment"],
                        "rev": exercise["rev"],
                        "sets": [
                            {
                                "set_performance_id": set_item["client_uuid"],
                                "prescribed_set_id": set_item["prescribed_set_id"],
                                "ordinal": set_item["ordinal"],
                                "status": set_item["status"],
                                "load_kg": self._number(set_item["load_kg"]),
                                "repetitions": set_item["repetitions"],
                                "rir": set_item["rir"],
                                "comment": set_item["performance_comment"],
                                "heart_rate_bpm": set_item["heart_rate_bpm"],
                                "performed_at": set_item["performed_at"],
                                "received_at": set_item["received_at"],
                                "rev": set_item["rev"],
                            }
                            for set_item in sets_by_exercise.get(exercise["id"], [])
                        ],
                    }
                    for exercise in data["exercises"]
                ],
            },
        )

    def _active_summary(self, data: dict[str, Any], device_id: UUID) -> ActiveWorkoutSummary:
        workout = data["workout"]
        return ActiveWorkoutSummary(
            workout_id=workout["client_uuid"],
            session_id=workout["session_id"],
            workout_unit_name=workout["workout_unit_name"],
            started_at=workout["started_at"],
            lease=self._lease(workout, device_id),
            applied_seq=workout["applied_seq"],
            revision=workout["revision"],
            position_hint=self._position_hint(workout),
            counts=data["counts"],
        )

    @staticmethod
    def _lease(workout: Row, device_id: UUID) -> dict[str, Any]:
        return {
            "device_id": workout["lease_device_id"],
            "epoch": workout["lease_epoch"],
            "is_this_device": workout["lease_device_id"] == device_id,
        }

    @staticmethod
    def _position_hint(workout: Row) -> dict[str, Any] | None:
        if workout["position_exercise_performance_uuid"] is None:
            return None
        return {
            "exercise_performance_id": workout["position_exercise_performance_uuid"],
            "set_ordinal": workout["position_set_ordinal"],
            "phase": workout["position_phase"],
        }

    @staticmethod
    def _plan_run(row: Row) -> dict[str, Any]:
        return {
            "id": row["id"],
            "name": row["name"],
            "status": row["status"],
            "starts_on": row["starts_on"],
            "ends_on": row["ends_on"],
            "microcycle_count": row["microcycle_count"],
            "current_microcycle_ordinal": row.get("current_microcycle_ordinal"),
        }

    def _session_summary(self, row: Row, *, relation: str | None = None) -> dict[str, Any]:
        ready = (
            row["prescription_id"] is not None
            and row["exercise_count"] > 0
            and row["set_count"] > 0
            and row["missing_load_count"] == 0
        )
        return {
            "session_id": row["session_id"],
            "workout_unit_name": row["workout_unit_name"],
            "workout_track_id": row["workout_track_id"],
            "scheduled_on": row["scheduled_date"],
            "status": row["status"],
            "relation": relation,
            "prescription": {
                "readiness": "ready" if ready else "missing",
                "prescription_version": row["prescription_version"],
                "updated_at": row["updated_at"],
                "exercise_count": row["exercise_count"],
                "set_count": row["set_count"],
                "estimated_duration_min": (
                    max(15, round(row["set_count"] * 4.5)) if row["set_count"] else None
                ),
            },
        }

    @staticmethod
    def _empty_context(*, selection_required: bool, target_date: date) -> MobileContext:
        marker = f"none-{target_date.isoformat()}-{int(selection_required)}"
        return MobileContext(
            generated_at=datetime.now(timezone.utc),
            context_version=f"ctx-{marker}",
            plan_run=None,
            selection_required=selection_required,
            today=None,
            microcycle_days=[],
            expected_session=None,
            alternatives=[],
            fallbacks=[],
            active_workout=None,
            recent=[],
        )

    @staticmethod
    def _exercise_identity(
        exercise_id: int, slug: str, name: str, full_name: str | None
    ) -> dict[str, Any]:
        return {"id": exercise_id, "slug": slug, "name": name, "full_name": full_name}

    @staticmethod
    def _target_rir(value: str) -> int | None:
        return int(value[-1]) if value.startswith("RIR") and value[-1].isdigit() else None

    @staticmethod
    def _number(value: Any) -> float | None:
        return float(value) if value is not None else None

    @classmethod
    def _atlas_peek(cls, data: dict[str, Any], locale: str) -> AtlasPeek:
        exercise = data["exercise"]
        technique = exercise.get("technique") or {}
        tldr = technique.get("tldr") if isinstance(technique, dict) else {}
        tldr = tldr if isinstance(tldr, dict) else {}
        muscles = data["muscles"]
        shares = [
            float(item["capacity_share"]) for item in muscles if item["capacity_share"] is not None
        ]
        maximum = max(shares, default=0.0)
        return AtlasPeek(
            exercise=cls._exercise_identity(
                exercise["id"],
                exercise["slug"],
                exercise["name"],
                exercise["full_name"],
            ),
            tags=[
                exercise["body_part"],
                exercise["target_category"],
                exercise["mechanics_tier"],
                exercise["resistance_source"],
                exercise["execution_pattern"],
            ],
            technique_tldr={
                "setup": tldr.get("setup"),
                "execution": tldr.get("execution"),
                "focus": tldr.get("focus"),
                "stop_when": tldr.get("stop_when"),
            },
            muscles_top=[
                {
                    "muscle_id": item["muscle_id"],
                    "slug": item["slug"],
                    "name": item["name"],
                    "etu_cm2": float(item["etu_cm2"]),
                    "capacity_share": (
                        float(item["capacity_share"])
                        if item["capacity_share"] is not None
                        else None
                    ),
                }
                for item in muscles
            ],
            body_map={
                "asset": "anatomy.svg",
                "asset_version": "v1",
                "regions": [
                    {
                        "region_id": DB_TO_SVG.get(item["slug"], item["slug"]),
                        "intensity": (
                            float(item["capacity_share"]) / maximum
                            if maximum > 0 and item["capacity_share"] is not None
                            else 0.0
                        ),
                    }
                    for item in muscles
                ],
            },
            content_locale=locale,
            atlas_version="0.1",
        )


def etag_for(model: Any) -> str:
    payload = model.model_dump(mode="json", exclude={"generated_at"})
    digest = hashlib.sha256(
        json.dumps(payload, sort_keys=True, separators=(",", ":")).encode()
    ).hexdigest()
    return f'"{digest}"'
