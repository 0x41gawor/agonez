from __future__ import annotations

import hashlib
import json
from datetime import date, datetime, timezone
from decimal import Decimal
from typing import Any, cast
from uuid import UUID, uuid5

from psycopg.types.json import Jsonb

from agonez_api.core.database import DatabasePool
from agonez_api.modules.execution.errors import conflict, invalid, not_found
from agonez_api.modules.execution.progression import (
    PerformedSet,
    PlannedSet,
    ProgressionRequest,
    ResolvedLoad,
    resolve_loads,
)
from agonez_api.modules.mobile_execution.schemas import (
    AddUnplannedExerciseOperation,
    ClaimWorkout,
    ClearSetOperation,
    FinalizeWorkout,
    MobileOperation,
    OperationBatch,
    ReorderExercisesOperation,
    SetCursorOperation,
    SetExerciseCommentOperation,
    SetWorkoutCommentOperation,
    SkipExerciseOperation,
    SkipSetOperation,
    StartWorkout,
    SubstituteExerciseOperation,
    UpsertSetOperation,
)

Row = dict[str, Any]


def expected_plan_structure_sql(workout_unit_ref: str) -> str:
    """Return the single definition of a session's complete plan structure.

    ``workout_unit_ref`` is a SQL expression naming the plan workout unit a session
    was built from — a bound ``%s`` placeholder or a column reference chosen by the
    caller, never user input. Context readiness, the start's completeness check and
    fallback preparation all read these counts so they cannot drift apart.
    """
    return f"""
        (
            SELECT count(*)::integer
            FROM plans.exercise_slots AS expected_slot
            WHERE expected_slot.workout_unit_id = {workout_unit_ref}
        ) AS expected_exercise_count,
        (
            SELECT count(*)::integer
            FROM plans.set_infra_prescriptions AS expected_set
            JOIN plans.exercise_variants AS expected_variant
              ON expected_variant.id = expected_set.exercise_variant_id
             AND expected_variant.variant_type = 'DEFAULT'
            JOIN plans.exercise_slots AS expected_slot
              ON expected_slot.id = expected_variant.slot_id
            WHERE expected_slot.workout_unit_id = {workout_unit_ref}
        ) AS expected_set_count
    """


def prescription_is_complete(row: Row) -> bool:
    """Whether a prescription covers the whole plan structure of its session."""
    return bool(
        row["exercise_count"] == row["expected_exercise_count"]
        and row["set_count"] == row["expected_set_count"]
    )


def resolve_start_mode(
    payload: StartWorkout,
    *,
    session_status: str,
    expected_session_id: int | None,
    next_track_session_id: int | None,
) -> str:
    """Validate the selected occurrence and return its persisted start mode."""
    if session_status not in {"scheduled", "missed"}:
        raise conflict(
            "session_not_startable",
            "The workout session cannot be started",
            {"status": session_status},
        )
    if next_track_session_id != payload.session_id:
        raise conflict(
            "not_next_track_exposure",
            "The selected session is not the next unresolved exposure of this workout type",
            {
                "selected_session_id": payload.session_id,
                "next_session_id": next_track_session_id,
            },
        )

    is_off_schedule = expected_session_id != payload.session_id or session_status == "missed"
    if not is_off_schedule:
        if payload.off_schedule is not None:
            raise invalid(
                "off_schedule_not_applicable",
                "The selected session is already the expected scheduled workout",
                {"expected_session_id": expected_session_id},
            )
        return "on_schedule"

    acknowledgement = payload.off_schedule
    if acknowledgement is None:
        raise invalid(
            "off_schedule_acknowledgement_required",
            "Starting the next workout-type exposure off schedule requires acknowledgement",
            {
                "expected_session_id": expected_session_id,
                "next_session_id": next_track_session_id,
            },
        )
    if acknowledgement.expected_session_id != expected_session_id:
        raise conflict(
            "schedule_changed",
            "The expected scheduled workout changed before start",
            {"expected_session_id": expected_session_id},
        )
    return acknowledgement.mode


class MobileExecutionRepository:
    """PostgreSQL persistence boundary for mobile reads and ordered writes."""

    def __init__(self, pool: DatabasePool) -> None:
        self._pool = pool

    async def reconcile(self, plan_run_id: int | None, as_of: date) -> None:
        async with self._pool.connection() as connection:
            async with connection.transaction():
                await self._execute(
                    connection,
                    """
                    UPDATE exec.plan_runs
                    SET status = 'active', updated_at = clock_timestamp()
                    WHERE (%s::integer IS NULL OR id = %s)
                      AND status = 'scheduled' AND starts_on <= %s
                    """,
                    (plan_run_id, plan_run_id, as_of),
                )
                await self._execute(
                    connection,
                    """
                    UPDATE exec.workout_sessions AS session
                    SET status = 'missed', updated_at = clock_timestamp()
                    WHERE (%s::integer IS NULL OR session.plan_run_id = %s)
                      AND session.status = 'scheduled'
                      AND session.scheduled_date < %s
                      AND NOT EXISTS (
                          SELECT 1
                          FROM exec.workout_unit_prescriptions AS prescription
                          JOIN exec.workout_unit_performances AS performance
                            ON performance.workout_unit_prescription_id = prescription.id
                          WHERE prescription.workout_session_id = session.id
                      )
                    """,
                    (plan_run_id, plan_run_id, as_of),
                )

    async def list_plan_runs(self, *, as_of: date) -> list[Row]:
        async with self._pool.connection() as connection:
            return await self._fetch_all(
                connection,
                """
                SELECT run.id, run.name, run.status::text AS status,
                       run.starts_on, run.ends_on, run.microcycle_count,
                       run.microcycle_duration_days, plan.name AS plan_name,
                       current_mc.ordinal AS current_microcycle_ordinal
                FROM exec.plan_runs AS run
                JOIN plans.plan_revisions AS revision
                  ON revision.id = run.initial_plan_revision_id
                JOIN plans.workout_plans AS plan ON plan.id = revision.plan_id
                LEFT JOIN exec.microcycles AS current_mc
                  ON current_mc.plan_run_id = run.id
                 AND %s BETWEEN current_mc.starts_on AND current_mc.ends_on
                ORDER BY CASE run.status WHEN 'active' THEN 0 WHEN 'scheduled' THEN 1 ELSE 2 END,
                         run.starts_on DESC, run.id DESC
                """,
                (as_of,),
            )

    async def load_context(self, *, plan_run_id: int, as_of: date) -> dict[str, Any]:
        async with self._pool.connection() as connection:
            run = await self._fetch_optional(
                connection,
                """
                SELECT run.*, run.status::text AS status, plan.name AS plan_name
                FROM exec.plan_runs AS run
                JOIN plans.plan_revisions AS revision
                  ON revision.id = run.initial_plan_revision_id
                JOIN plans.workout_plans AS plan ON plan.id = revision.plan_id
                WHERE run.id = %s
                """,
                (plan_run_id,),
            )
            if run is None:
                raise not_found("plan_run_not_found", "Plan run was not found")
            microcycle = await self._fetch_optional(
                connection,
                """
                SELECT id, ordinal, starts_on, ends_on, classification::text AS classification,
                       updated_at
                FROM exec.microcycles
                WHERE plan_run_id = %s AND %s BETWEEN starts_on AND ends_on
                """,
                (plan_run_id, as_of),
            )
            current_microcycle_id = microcycle["id"] if microcycle is not None else None
            sessions = await self._fetch_all(
                connection,
                f"""
                    SELECT session.id AS session_id, session.scheduled_date,
                           session.status::text AS status,
                           session.workout_unit_track_id AS workout_track_id,
                           session_mc.ordinal AS microcycle_ordinal,
                           track.name AS workout_unit_name,
                           prescription.id AS prescription_id,
                           prescription.updated_at,
                           count(DISTINCT exercise.id)::integer AS exercise_count,
                           count(DISTINCT exercise.id) FILTER (
                               WHERE exercise.generation_source = 'analysis'
                           )::integer AS analysis_exercise_count,
                           count(DISTINCT exercise.id) FILTER (
                               WHERE exercise.generation_source = 'plan_fallback'
                           )::integer AS fallback_exercise_count,
                           count(sets.id)::integer AS set_count,
                           count(sets.id) FILTER (WHERE sets.prescribed_load_kg IS NULL)::integer
                               AS missing_load_count,
                           {expected_plan_structure_sql("session.source_plan_workout_unit_id")}
                    FROM exec.workout_sessions AS session
                    JOIN exec.microcycles AS session_mc ON session_mc.id = session.microcycle_id
                    JOIN exec.workout_unit_tracks AS track
                      ON track.id = session.workout_unit_track_id
                    LEFT JOIN exec.workout_unit_prescriptions AS prescription
                      ON prescription.workout_session_id = session.id
                    LEFT JOIN exec.exercise_unit_prescriptions AS exercise
                      ON exercise.workout_unit_prescription_id = prescription.id
                    LEFT JOIN exec.set_prescriptions AS sets
                      ON sets.exercise_unit_prescription_id = exercise.id
                    WHERE (%s::integer IS NOT NULL AND session.microcycle_id = %s)
                       OR (
                           session.plan_run_id = %s
                           AND session.status = 'missed'
                           AND session.scheduled_date < %s
                       )
                    GROUP BY session.id, session_mc.ordinal, track.name,
                             prescription.id, prescription.updated_at
                    ORDER BY session_mc.ordinal, session.scheduled_date, session.id
                """,
                (current_microcycle_id, current_microcycle_id, plan_run_id, as_of),
            )
            for session in sessions:
                session["prescription_version"] = (
                    await self._prescription_version(connection, session["session_id"])
                    if session["prescription_id"] is not None
                    else None
                )
            recent = await self._fetch_all(
                connection,
                """
                SELECT session.id AS session_id, track.name AS workout_unit_name,
                       performance.completed_at,
                       (
                           SELECT count(*)::integer
                           FROM exec.exercise_unit_performances AS exercise_perf
                           JOIN exec.set_performances AS set_perf
                             ON set_perf.exercise_unit_performance_id = exercise_perf.id
                           WHERE exercise_perf.workout_unit_performance_id = performance.id
                             AND set_perf.status = 'performed'
                       ) AS performed_sets,
                       (
                           SELECT count(*)::integer
                           FROM exec.exercise_unit_prescriptions AS exercise_rx
                           JOIN exec.set_prescriptions AS set_rx
                             ON set_rx.exercise_unit_prescription_id = exercise_rx.id
                           WHERE exercise_rx.workout_unit_prescription_id = workout_rx.id
                       ) AS prescribed_sets,
                       (
                           SELECT count(*)::integer
                           FROM exec.exercise_unit_performances AS exercise_perf
                           JOIN exec.set_performances AS set_perf
                             ON set_perf.exercise_unit_performance_id = exercise_perf.id
                           WHERE exercise_perf.workout_unit_performance_id = performance.id
                             AND set_perf.status = 'skipped'
                       ) AS skipped_sets
                FROM exec.workout_sessions AS session
                JOIN exec.workout_unit_tracks AS track
                  ON track.id = session.workout_unit_track_id
                JOIN exec.workout_unit_prescriptions AS workout_rx
                  ON workout_rx.workout_session_id = session.id
                JOIN exec.workout_unit_performances AS performance
                  ON performance.workout_unit_prescription_id = workout_rx.id
                WHERE session.plan_run_id = %s AND performance.status = 'finalized'
                ORDER BY performance.completed_at DESC
                LIMIT 3
                """,
                (plan_run_id,),
            )
            return {
                "run": run,
                "microcycle": microcycle,
                "sessions": sessions,
                "recent": recent,
            }

    async def load_prescription(self, session_id: int, *, locale: str) -> dict[str, Any]:
        async with self._pool.connection() as connection:
            return await self._load_prescription(connection, session_id, locale=locale)

    async def prepare_fallback_prescription(
        self, session_id: int, *, locale: str
    ) -> dict[str, Any]:
        """Materialize a complete plan-backed snapshot without deciding start schedule policy."""
        async with self._pool.connection() as connection:
            async with connection.transaction():
                await self._ensure_fallback_prescription(connection, session_id)
                return await self._load_prescription(connection, session_id, locale=locale)

    async def preview_fallback_prescription(
        self, session_id: int, *, locale: str
    ) -> dict[str, Any]:
        """Return the snapshot preparation *would* produce, without writing anything.

        This runs the very same materialization as
        :meth:`prepare_fallback_prescription` and then rolls the transaction back, so a
        preview can never disagree with what a later ``POST`` persists. Nothing is
        committed: the rows it builds exist only for the lifetime of the transaction,
        which is why the caller marks the payload as a preview and the app must still
        prepare explicitly before starting.
        """
        async with self._pool.connection() as connection:
            async with connection.transaction(force_rollback=True):
                await self._ensure_fallback_prescription(connection, session_id)
                return await self._load_prescription(connection, session_id, locale=locale)

    async def _load_prescription(
        self,
        connection: Any,
        session_id: int,
        *,
        locale: str,
    ) -> dict[str, Any]:
        session = await self._fetch_optional(
            connection,
            """
            SELECT session.id AS session_id, session.plan_run_id,
                   session.workout_unit_track_id AS workout_track_id,
                   track.name AS workout_unit_name, session.status::text AS session_status,
                   mc.ordinal AS microcycle_ordinal,
                   mc.classification::text AS microcycle_classification,
                   workout.id AS prescription_id, workout.description_snapshot,
                   workout.prescription_comment AS workout_prescription_comment,
                   workout.updated_at AS prescription_updated_at
            FROM exec.workout_sessions AS session
            JOIN exec.workout_unit_tracks AS track
              ON track.id = session.workout_unit_track_id
            JOIN exec.microcycles AS mc ON mc.id = session.microcycle_id
            LEFT JOIN exec.workout_unit_prescriptions AS workout
              ON workout.workout_session_id = session.id
            WHERE session.id = %s
            """,
            (session_id,),
        )
        if session is None:
            raise not_found("session_not_found", "Workout session was not found")
        if session["prescription_id"] is None:
            raise conflict(
                "prescription_missing",
                "The workout prescription is not ready",
                {"session_id": session_id},
            )
        exercises = await self._fetch_all(
            connection,
            """
            SELECT exercise.id AS exercise_prescription_id, exercise.ordinal,
                   exercise.generation_source::text AS generation_source,
                   exercise.exercise_unit_track_id AS exercise_track_id,
                   exercise.source_plan_exercise_slot_id,
                   exercise.source_plan_exercise_variant_id,
                   exercise.prescribed_exercise_id,
                   exercise.slot_name_snapshot, exercise.plan_description_snapshot,
                   exercise.plan_goal_snapshot,
                   lower(exercise.slot_role_snapshot::text) AS slot_role,
                   exercise.progression_model_slug_snapshot,
                   COALESCE(
                       exercise.load_step_kg_snapshot,
                       rs_default.default_load_step_kg
                   ) AS load_step_kg,
                   exercise.prescription_comment,
                   core.slug, COALESCE(translation.name, core.name) AS name,
                   COALESCE(translation.name_full, core.name_full) AS full_name
            FROM exec.exercise_unit_prescriptions AS exercise
            JOIN core.exercises AS core ON core.id = exercise.prescribed_exercise_id
            JOIN core.resistance_source_load_defaults AS rs_default
              ON rs_default.resistance_source = core.resistance_source
            LEFT JOIN core.exercise_translations AS translation
              ON translation.exercise_id = core.id
             AND translation.locale = %s AND translation.status = 'published'
            WHERE exercise.workout_unit_prescription_id = %s
            ORDER BY exercise.ordinal, exercise.id
            """,
            (locale, session["prescription_id"]),
        )
        sets = await self._fetch_all(
            connection,
            """
            SELECT sets.id AS set_prescription_id, sets.exercise_unit_prescription_id,
                   sets.ordinal, sets.set_role_snapshot::text AS role,
                   sets.prescribed_load_kg, sets.rep_min, sets.rep_max,
                   sets.target_rir::text AS target_rir, sets.prescription_comment,
                   sets.load_source::text AS load_source
            FROM exec.set_prescriptions AS sets
            JOIN exec.exercise_unit_prescriptions AS exercise
              ON exercise.id = sets.exercise_unit_prescription_id
            WHERE exercise.workout_unit_prescription_id = %s
            ORDER BY sets.exercise_unit_prescription_id, sets.ordinal
            """,
            (session["prescription_id"],),
        )
        alternatives = await self._fetch_all(
            connection,
            """
            SELECT exercise.id AS exercise_prescription_id, variant.id AS variant_id,
                   variant.ordinal AS variant_ordinal, variant.exercise_id,
                   core.slug, COALESCE(translation.name, core.name) AS name,
                   COALESCE(translation.name_full, core.name_full) AS full_name
            FROM exec.exercise_unit_prescriptions AS exercise
            JOIN plans.exercise_variants AS variant
              ON variant.slot_id = exercise.source_plan_exercise_slot_id
             AND variant.id <> exercise.source_plan_exercise_variant_id
            JOIN core.exercises AS core ON core.id = variant.exercise_id
            LEFT JOIN core.exercise_translations AS translation
              ON translation.exercise_id = core.id
             AND translation.locale = %s AND translation.status = 'published'
            WHERE exercise.workout_unit_prescription_id = %s
            ORDER BY exercise.ordinal, variant.ordinal
            """,
            (locale, session["prescription_id"]),
        )
        previous = await self._fetch_all(
            connection,
            """
            SELECT current.id AS exercise_prescription_id,
                   prior.id AS exercise_performance_id,
                   mc.ordinal AS microcycle_ordinal,
                   workout_perf.completed_at::date AS performed_on,
                   actual.id AS actual_exercise_id, actual.slug,
                   COALESCE(translation.name, actual.name) AS name,
                   COALESCE(translation.name_full, actual.name_full) AS full_name
            FROM exec.exercise_unit_prescriptions AS current
            LEFT JOIN exec.exercise_unit_performances AS prior
              ON prior.id = current.previous_exercise_performance_id
            LEFT JOIN exec.workout_unit_performances AS workout_perf
              ON workout_perf.id = prior.workout_unit_performance_id
            LEFT JOIN exec.workout_unit_prescriptions AS prior_rx
              ON prior_rx.id = workout_perf.workout_unit_prescription_id
            LEFT JOIN exec.workout_sessions AS prior_session
              ON prior_session.id = prior_rx.workout_session_id
            LEFT JOIN exec.microcycles AS mc ON mc.id = prior_session.microcycle_id
            LEFT JOIN core.exercises AS actual ON actual.id = prior.actual_exercise_id
            LEFT JOIN core.exercise_translations AS translation
              ON translation.exercise_id = actual.id
             AND translation.locale = %s AND translation.status = 'published'
            WHERE current.workout_unit_prescription_id = %s
            ORDER BY current.ordinal
            """,
            (locale, session["prescription_id"]),
        )
        previous_sets = await self._fetch_all(
            connection,
            """
            SELECT current.id AS exercise_prescription_id, sets.ordinal,
                   sets.status::text AS status, sets.load_kg, sets.repetitions, sets.rir
            FROM exec.exercise_unit_prescriptions AS current
            JOIN exec.set_performances AS sets
              ON sets.exercise_unit_performance_id = current.previous_exercise_performance_id
            WHERE current.workout_unit_prescription_id = %s
            ORDER BY current.ordinal, sets.ordinal
            """,
            (session["prescription_id"],),
        )
        exercise_ids = {cast(int, item["prescribed_exercise_id"]) for item in exercises}
        exercise_ids.update(cast(int, item["exercise_id"]) for item in alternatives)
        peeks = {
            exercise_id: await self._load_atlas_peek(connection, exercise_id, locale=locale)
            for exercise_id in exercise_ids
        }
        return {
            "session": session,
            "locale": locale,
            "version": await self._prescription_version(connection, session_id),
            "exercises": exercises,
            "sets": sets,
            "alternatives": alternatives,
            "previous": previous,
            "previous_sets": previous_sets,
            "peeks": peeks,
        }

    async def _ensure_fallback_prescription(self, connection: Any, session_id: int) -> None:
        session = await self._fetch_optional(
            connection,
            """
            SELECT session.id, session.plan_run_id, session.microcycle_id,
                   session.workout_unit_track_id, session.source_plan_workout_unit_id,
                   session.scheduled_date, session.status::text AS session_status,
                   mc.plan_revision_id, mc.ordinal AS microcycle_ordinal,
                   source_day.revision_id AS source_revision_id,
                   source_workout.name, source_workout.description,
                   source_workout.warmup_notes, source_workout.stretch_notes
            FROM exec.workout_sessions AS session
            JOIN exec.microcycles AS mc ON mc.id = session.microcycle_id
            JOIN plans.workout_unit_prescriptions AS source_workout
              ON source_workout.id = session.source_plan_workout_unit_id
            JOIN plans.day_prescriptions AS source_day
              ON source_day.id = source_workout.day_id
            WHERE session.id = %s
            FOR UPDATE OF session
            """,
            (session_id,),
        )
        if session is None:
            raise not_found("session_not_found", "Workout session was not found")
        if session["session_status"] not in {"scheduled", "missed"}:
            raise conflict(
                "session_not_startable",
                "Fallback prescription can only be prepared for a pending session",
                {"status": session["session_status"]},
            )
        if session["source_revision_id"] != session["plan_revision_id"]:
            raise invalid(
                "fallback_unavailable",
                "The session plan source does not belong to its governing revision",
                {"session_id": session_id},
            )

        workout = await self._fetch_optional(
            connection,
            """
            SELECT *
            FROM exec.workout_unit_prescriptions
            WHERE workout_session_id = %s
            FOR UPDATE
            """,
            (session_id,),
        )
        changed = False
        if workout is None:
            workout = await self._fetch_one(
                connection,
                """
                INSERT INTO exec.workout_unit_prescriptions (
                    workout_session_id, source_plan_revision_id,
                    source_plan_workout_unit_id, name_snapshot,
                    description_snapshot, warmup_notes_snapshot,
                    stretch_notes_snapshot
                ) VALUES (%s, %s, %s, %s, %s, %s, %s)
                RETURNING *
                """,
                (
                    session_id,
                    session["plan_revision_id"],
                    session["source_plan_workout_unit_id"],
                    session["name"],
                    session["description"],
                    session["warmup_notes"],
                    session["stretch_notes"],
                ),
            )
            changed = True

        plan_exercises = await self._fetch_all(
            connection,
            """
            SELECT slot.id AS slot_id, slot.ordinal, slot.name AS slot_name,
                   slot.description AS slot_description, slot.goal AS slot_goal,
                   slot.role::text AS slot_role,
                   variant.id AS variant_id, variant.progression_id,
                   variant.exercise_id, variant.progression_model_slug,
                   COALESCE(variant.load_step_kg, defaults.default_load_step_kg)
                       AS load_step_kg,
                   track.id AS exercise_track_id,
                   previous.id AS previous_exercise_performance_id
            FROM plans.exercise_slots AS slot
            LEFT JOIN plans.exercise_variants AS variant
              ON variant.slot_id = slot.id AND variant.variant_type = 'DEFAULT'
            LEFT JOIN core.exercises AS exercise ON exercise.id = variant.exercise_id
            LEFT JOIN core.resistance_source_load_defaults AS defaults
              ON defaults.resistance_source = exercise.resistance_source
            LEFT JOIN exec.exercise_unit_tracks AS track
              ON track.plan_run_id = %s
             AND track.workout_unit_track_id = %s
             AND track.logical_key = 'slot:' || slot.ordinal::text
            LEFT JOIN LATERAL (
                SELECT exercise_performance.id
                FROM exec.exercise_unit_performances AS exercise_performance
                JOIN exec.workout_unit_performances AS workout_performance
                  ON workout_performance.id = exercise_performance.workout_unit_performance_id
                JOIN exec.workout_unit_prescriptions AS prior_prescription
                  ON prior_prescription.id = workout_performance.workout_unit_prescription_id
                JOIN exec.workout_sessions AS prior_session
                  ON prior_session.id = prior_prescription.workout_session_id
                WHERE exercise_performance.exercise_unit_track_id = track.id
                  AND workout_performance.status = 'finalized'
                  AND exercise_performance.actual_exercise_id = variant.exercise_id
                  AND EXISTS (
                      SELECT 1
                      FROM exec.set_performances AS performed_set
                      WHERE performed_set.exercise_unit_performance_id = exercise_performance.id
                        AND performed_set.status = 'performed'
                        AND performed_set.load_kg IS NOT NULL
                  )
                  AND prior_session.plan_run_id = %s
                  AND prior_session.id <> %s
                ORDER BY workout_performance.completed_at DESC,
                         exercise_performance.id DESC
                LIMIT 1
            ) AS previous ON TRUE
            WHERE slot.workout_unit_id = %s
            ORDER BY slot.ordinal, slot.id
            """,
            (
                session["plan_run_id"],
                session["workout_unit_track_id"],
                session["plan_run_id"],
                session["id"],
                session["source_plan_workout_unit_id"],
            ),
        )
        if not plan_exercises:
            raise invalid(
                "fallback_unavailable",
                "The plan workout has no executable exercise slots",
                {"session_id": session_id},
            )
        invalid_slots = [
            item["ordinal"]
            for item in plan_exercises
            if item["variant_id"] is None
            or item["exercise_track_id"] is None
            or item["load_step_kg"] is None
        ]
        if invalid_slots:
            raise invalid(
                "fallback_unavailable",
                "The plan workout cannot be mapped to executable exercise tracks",
                {"session_id": session_id, "slot_ordinals": invalid_slots},
            )

        variant_ids = [item["variant_id"] for item in plan_exercises]
        plan_sets = await self._fetch_all(
            connection,
            """
            SELECT item.id, item.exercise_variant_id, item.ordinal,
                   item.role::text AS role, item.rep_min, item.rep_max,
                   item.rir::text AS target_rir
            FROM plans.set_infra_prescriptions AS item
            WHERE item.exercise_variant_id = ANY(%s)
            ORDER BY item.exercise_variant_id, item.ordinal, item.id
            """,
            (variant_ids,),
        )
        sets_by_variant: dict[int, list[Row]] = {}
        for item in plan_sets:
            sets_by_variant.setdefault(item["exercise_variant_id"], []).append(item)

        loads_by_track = await self._resolve_fallback_loads(
            connection, plan_exercises, sets_by_variant
        )

        existing_exercises = await self._fetch_all(
            connection,
            """
            SELECT exercise.*, exercise.generation_source::text AS generation_source
            FROM exec.exercise_unit_prescriptions AS exercise
            WHERE exercise.workout_unit_prescription_id = %s
            ORDER BY exercise.ordinal, exercise.id
            FOR UPDATE
            """,
            (workout["id"],),
        )
        existing_by_track = {
            item["exercise_unit_track_id"]: item for item in existing_exercises
        }
        planned_track_ids = {item["exercise_track_id"] for item in plan_exercises}
        for stale in existing_exercises:
            if (
                stale["generation_source"] == "plan_fallback"
                and stale["exercise_unit_track_id"] not in planned_track_ids
            ):
                await self._execute(
                    connection,
                    "DELETE FROM exec.exercise_unit_prescriptions WHERE id = %s",
                    (stale["id"],),
                )
                changed = True

        for plan in plan_exercises:
            source_sets = sets_by_variant.get(plan["variant_id"], [])
            existing = existing_by_track.get(plan["exercise_track_id"])
            if existing is not None and existing["generation_source"] == "analysis":
                continue

            replace_sets = existing is None or existing["source_plan_exercise_variant_id"] != plan[
                "variant_id"
            ]
            snapshot_changed = existing is not None and any(
                (
                    existing["ordinal"] != plan["ordinal"],
                    existing["source_plan_exercise_slot_id"] != plan["slot_id"],
                    existing["source_plan_exercise_variant_id"] != plan["variant_id"],
                    existing["source_progression_id"] != plan["progression_id"],
                    existing["prescribed_exercise_id"] != plan["exercise_id"],
                    existing["slot_name_snapshot"] != plan["slot_name"],
                    existing["plan_description_snapshot"] != plan["slot_description"],
                    existing["plan_goal_snapshot"] != plan["slot_goal"],
                    str(existing["slot_role_snapshot"]) != plan["slot_role"],
                    existing["progression_model_slug_snapshot"]
                    != plan["progression_model_slug"],
                    existing["load_step_kg_snapshot"] != plan["load_step_kg"],
                )
            )
            if existing is None:
                inserted = await self._fetch_one(
                    connection,
                    """
                    INSERT INTO exec.exercise_unit_prescriptions (
                        workout_unit_prescription_id, exercise_unit_track_id,
                        ordinal, source_plan_exercise_slot_id,
                        source_plan_exercise_variant_id, source_progression_id,
                        prescribed_exercise_id, slot_name_snapshot,
                        plan_description_snapshot, plan_goal_snapshot,
                        slot_role_snapshot, progression_model_slug_snapshot,
                        load_step_kg_snapshot, previous_exercise_performance_id,
                        generation_source
                    ) VALUES (
                        %s, %s, %s, %s, %s, %s, %s, %s,
                        %s, %s, %s, %s, %s, %s, 'plan_fallback'
                    ) RETURNING id
                    """,
                    (
                        workout["id"],
                        plan["exercise_track_id"],
                        plan["ordinal"],
                        plan["slot_id"],
                        plan["variant_id"],
                        plan["progression_id"],
                        plan["exercise_id"],
                        plan["slot_name"],
                        plan["slot_description"],
                        plan["slot_goal"],
                        plan["slot_role"],
                        plan["progression_model_slug"],
                        plan["load_step_kg"],
                        plan["previous_exercise_performance_id"],
                    ),
                )
                exercise_prescription_id = inserted["id"]
                replace_sets = True
                changed = True
            else:
                exercise_prescription_id = existing["id"]
                if snapshot_changed or existing["previous_exercise_performance_id"] != plan[
                    "previous_exercise_performance_id"
                ]:
                    await self._execute(
                        connection,
                        """
                        UPDATE exec.exercise_unit_prescriptions
                        SET ordinal = %s,
                            source_plan_exercise_slot_id = %s,
                            source_plan_exercise_variant_id = %s,
                            source_progression_id = %s,
                            prescribed_exercise_id = %s,
                            slot_name_snapshot = %s,
                            plan_description_snapshot = %s,
                            plan_goal_snapshot = %s,
                            slot_role_snapshot = %s,
                            progression_model_slug_snapshot = %s,
                            load_step_kg_snapshot = %s,
                            previous_exercise_performance_id = %s,
                            updated_at = clock_timestamp()
                        WHERE id = %s
                        """,
                        (
                            plan["ordinal"],
                            plan["slot_id"],
                            plan["variant_id"],
                            plan["progression_id"],
                            plan["exercise_id"],
                            plan["slot_name"],
                            plan["slot_description"],
                            plan["slot_goal"],
                            plan["slot_role"],
                            plan["progression_model_slug"],
                            plan["load_step_kg"],
                            plan["previous_exercise_performance_id"],
                            exercise_prescription_id,
                        ),
                    )
                    changed = True

            if not replace_sets:
                existing_sets = await self._fetch_all(
                    connection,
                    """
                    SELECT source_plan_set_infra_id AS id, ordinal,
                           set_role_snapshot::text AS role, rep_min, rep_max,
                           target_rir::text AS target_rir
                    FROM exec.set_prescriptions
                    WHERE exercise_unit_prescription_id = %s
                    ORDER BY ordinal, id
                    """,
                    (exercise_prescription_id,),
                )
                replace_sets = self._set_structure(existing_sets) != self._set_structure(
                    source_sets
                )
            decided = loads_by_track.get(plan["exercise_track_id"], {})
            if replace_sets:
                await self._execute(
                    connection,
                    "DELETE FROM exec.set_prescriptions WHERE exercise_unit_prescription_id = %s",
                    (exercise_prescription_id,),
                )
                for source_set in source_sets:
                    load = decided.get(source_set["ordinal"])
                    await self._execute(
                        connection,
                        """
                        INSERT INTO exec.set_prescriptions (
                            exercise_unit_prescription_id, ordinal,
                            source_plan_set_infra_id, set_role_snapshot,
                            rep_min, rep_max, target_rir,
                            prescribed_load_kg, load_source
                        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                        """,
                        (
                            exercise_prescription_id,
                            source_set["ordinal"],
                            source_set["id"],
                            source_set["role"],
                            source_set["rep_min"],
                            source_set["rep_max"],
                            source_set["target_rir"],
                            load.load_kg if load else None,
                            load.source if load and load.load_kg is not None else None,
                        ),
                    )
                changed = True
            elif await self._fill_missing_fallback_loads(
                connection, exercise_prescription_id, decided
            ):
                changed = True

        if changed:
            await self._execute(
                connection,
                """
                UPDATE exec.workout_unit_prescriptions
                SET updated_at = clock_timestamp()
                WHERE id = %s
                """,
                (workout["id"],),
            )

        completeness = await self._fetch_one(
            connection,
            f"""
            SELECT count(DISTINCT exercise.id)::integer AS exercise_count,
                   count(sets.id)::integer AS set_count,
                   {expected_plan_structure_sql("%s")}
            FROM exec.exercise_unit_prescriptions AS exercise
            LEFT JOIN exec.set_prescriptions AS sets
              ON sets.exercise_unit_prescription_id = exercise.id
            WHERE exercise.workout_unit_prescription_id = %s
            """,
            (
                session["source_plan_workout_unit_id"],
                session["source_plan_workout_unit_id"],
                workout["id"],
            ),
        )
        if not prescription_is_complete(completeness):
            raise invalid(
                "fallback_unavailable",
                "The resulting prescription does not match the complete plan structure",
                {
                    "session_id": session_id,
                    "expected_exercises": completeness["expected_exercise_count"],
                    "actual_exercises": completeness["exercise_count"],
                    "expected_sets": completeness["expected_set_count"],
                    "actual_sets": completeness["set_count"],
                },
            )

    async def _fill_missing_fallback_loads(
        self,
        connection: Any,
        exercise_prescription_id: int,
        decided: dict[int, ResolvedLoad],
    ) -> bool:
        """Fill loads that are still empty on an already generated exercise.

        Repeating the preparation before the session starts picks up history that
        appeared since — a session performed in the meantime. Only empty loads are
        written, so a load the agent decided earlier is never silently revised, and the
        set rows keep their ids.
        """
        filled = False
        for ordinal, load in sorted(decided.items()):
            if load.load_kg is None:
                continue
            updated = await self._fetch_optional(
                connection,
                """
                UPDATE exec.set_prescriptions
                SET prescribed_load_kg = %s, load_source = %s
                WHERE exercise_unit_prescription_id = %s AND ordinal = %s
                  AND prescribed_load_kg IS NULL
                RETURNING id
                """,
                (load.load_kg, load.source, exercise_prescription_id, ordinal),
            )
            filled = filled or updated is not None
        return filled

    async def _resolve_fallback_loads(
        self,
        connection: Any,
        plan_exercises: list[Row],
        sets_by_variant: dict[int, list[Row]],
    ) -> dict[int, dict[int, ResolvedLoad]]:
        """Decide the load of every generated set through its progression agent.

        The athlete's last exposure of each exercise was already resolved by the
        ``plan_exercises`` query; this reads all of those exposures in one statement and
        hands each exercise to the agent registered for its progression model. Returns
        the decided loads keyed by exercise track id, then by set ordinal.
        """
        performance_ids = [
            item["previous_exercise_performance_id"]
            for item in plan_exercises
            if item["previous_exercise_performance_id"] is not None
        ]
        exposures: dict[int, list[PerformedSet]] = {}
        if performance_ids:
            performed = await self._fetch_all(
                connection,
                """
                SELECT performed.exercise_unit_performance_id AS performance_id,
                       performed.ordinal, performed.load_kg,
                       performed.repetitions, performed.rir,
                       prescribed.set_role_snapshot::text AS role
                FROM exec.set_performances AS performed
                LEFT JOIN exec.set_prescriptions AS prescribed
                  ON prescribed.id = performed.prescribed_set_id
                WHERE performed.exercise_unit_performance_id = ANY(%s)
                  AND performed.status = 'performed'
                  AND performed.load_kg IS NOT NULL
                ORDER BY performed.exercise_unit_performance_id, performed.ordinal
                """,
                (performance_ids,),
            )
            for item in performed:
                exposures.setdefault(item["performance_id"], []).append(
                    PerformedSet(
                        ordinal=item["ordinal"],
                        role=item["role"],
                        load_kg=item["load_kg"],
                        repetitions=item["repetitions"],
                        rir=item["rir"],
                    )
                )

        resolved: dict[int, dict[int, ResolvedLoad]] = {}
        for plan in plan_exercises:
            planned = tuple(
                PlannedSet(
                    ordinal=item["ordinal"],
                    role=item["role"],
                    rep_min=item["rep_min"],
                    rep_max=item["rep_max"],
                    target_rir=item["target_rir"],
                )
                for item in sets_by_variant.get(plan["variant_id"], [])
            )
            decisions = resolve_loads(
                ProgressionRequest(
                    progression_model_slug=plan["progression_model_slug"],
                    planned_sets=planned,
                    last_exposure=tuple(
                        exposures.get(plan["previous_exercise_performance_id"], [])
                    ),
                    load_step_kg=plan["load_step_kg"],
                )
            )
            resolved[plan["exercise_track_id"]] = {
                item.ordinal: item for item in decisions
            }
        return resolved

    @staticmethod
    def _set_structure(rows: list[Row]) -> list[tuple[Any, ...]]:
        return [
            (
                item["id"],
                item["ordinal"],
                item["role"],
                item["rep_min"],
                item["rep_max"],
                item["target_rir"],
            )
            for item in rows
        ]

    async def load_active(self, *, plan_run_id: int, locale: str = "en") -> dict[str, Any] | None:
        async with self._pool.connection() as connection:
            row = await self._fetch_optional(
                connection,
                """
                SELECT performance.client_uuid AS workout_id
                FROM exec.workout_sessions AS session
                JOIN exec.workout_unit_prescriptions AS prescription
                  ON prescription.workout_session_id = session.id
                JOIN exec.workout_unit_performances AS performance
                  ON performance.workout_unit_prescription_id = prescription.id
                WHERE session.plan_run_id = %s AND session.status = 'in_progress'
                  AND performance.client_uuid IS NOT NULL
                """,
                (plan_run_id,),
            )
            if row is None:
                return None
            return await self._load_workout(connection, row["workout_id"], locale=locale)

    async def load_workout(self, workout_id: UUID, *, locale: str = "en") -> dict[str, Any]:
        async with self._pool.connection() as connection:
            return await self._load_workout(connection, workout_id, locale=locale)

    async def _load_workout(
        self, connection: Any, workout_id: UUID, *, locale: str = "en"
    ) -> dict[str, Any]:
        workout = await self._fetch_optional(
            connection,
            """
            SELECT performance.*, performance.status::text AS performance_status,
                   session.id AS session_id, session.status::text AS session_status,
                   session.plan_run_id, session.completion_mode::text AS completion_mode,
                   session.scheduled_date, session.start_mode::text AS start_mode,
                   session.off_schedule_selected_from,
                   session.off_schedule_expected_session_id,
                   mc.ordinal AS microcycle_ordinal,
                   track.name AS workout_unit_name
            FROM exec.workout_unit_performances AS performance
            JOIN exec.workout_unit_prescriptions AS prescription
              ON prescription.id = performance.workout_unit_prescription_id
            JOIN exec.workout_sessions AS session
              ON session.id = prescription.workout_session_id
            JOIN exec.microcycles AS mc ON mc.id = session.microcycle_id
            JOIN exec.workout_unit_tracks AS track
              ON track.id = session.workout_unit_track_id
            WHERE performance.client_uuid = %s
            """,
            (workout_id,),
        )
        if workout is None:
            raise not_found("workout_not_found", "Workout was not found")
        exercises = await self._fetch_all(
            connection,
            """
            SELECT performance.*, performance.execution_mode::text AS execution_mode,
                   actual.slug AS actual_slug,
                   COALESCE(translation.name, actual.name) AS actual_name,
                   COALESCE(translation.name_full, actual.name_full) AS actual_full_name
            FROM exec.exercise_unit_performances AS performance
            LEFT JOIN core.exercises AS actual ON actual.id = performance.actual_exercise_id
            LEFT JOIN core.exercise_translations AS translation
              ON translation.exercise_id = actual.id
             AND translation.locale = %s AND translation.status = 'published'
            WHERE performance.workout_unit_performance_id = %s
            ORDER BY performance.performed_ordinal, performance.id
            """,
            (locale, workout["id"]),
        )
        sets = await self._fetch_all(
            connection,
            """
            SELECT sets.*, sets.status::text AS status
            FROM exec.set_performances AS sets
            JOIN exec.exercise_unit_performances AS exercise
              ON exercise.id = sets.exercise_unit_performance_id
            WHERE exercise.workout_unit_performance_id = %s
            ORDER BY exercise.performed_ordinal, sets.ordinal, sets.id
            """,
            (workout["id"],),
        )
        counts = await self._fetch_one(
            connection,
            """
            SELECT count(DISTINCT set_rx.id)::integer AS prescribed_sets,
                   count(DISTINCT set_perf.id) FILTER
                     (WHERE set_perf.status = 'performed')::integer AS performed_sets,
                   count(DISTINCT set_perf.id) FILTER
                     (WHERE set_perf.status = 'skipped')::integer AS skipped_sets
            FROM exec.workout_unit_performances AS performance
            JOIN exec.workout_unit_prescriptions AS workout_rx
              ON workout_rx.id = performance.workout_unit_prescription_id
            LEFT JOIN exec.exercise_unit_prescriptions AS exercise_rx
              ON exercise_rx.workout_unit_prescription_id = workout_rx.id
            LEFT JOIN exec.set_prescriptions AS set_rx
              ON set_rx.exercise_unit_prescription_id = exercise_rx.id
            LEFT JOIN exec.exercise_unit_performances AS exercise_perf
              ON exercise_perf.workout_unit_performance_id = performance.id
            LEFT JOIN exec.set_performances AS set_perf
              ON set_perf.exercise_unit_performance_id = exercise_perf.id
            WHERE performance.id = %s
            """,
            (workout["id"],),
        )
        return {"workout": workout, "exercises": exercises, "sets": sets, "counts": counts}

    async def load_atlas_peek(self, exercise_id: int, *, locale: str) -> dict[str, Any]:
        async with self._pool.connection() as connection:
            return await self._load_atlas_peek(connection, exercise_id, locale=locale)

    async def _load_atlas_peek(
        self, connection: Any, exercise_id: int, *, locale: str
    ) -> dict[str, Any]:
        exercise = await self._fetch_optional(
            connection,
            """
            SELECT core.id, core.slug, COALESCE(translation.name, core.name) AS name,
                   COALESCE(translation.name_full, core.name_full) AS full_name,
                   core.body_part::text AS body_part,
                   core.target_category::text AS target_category,
                   core.mechanics_tier::text AS mechanics_tier,
                   core.resistance_source::text AS resistance_source,
                   core.execution_pattern::text AS execution_pattern,
                   COALESCE(translation.technique, core.technique) AS technique,
                   engine.etu_vector
            FROM core.exercises AS core
            LEFT JOIN core.exercise_translations AS translation
              ON translation.exercise_id = core.id
             AND translation.locale = %s AND translation.status = 'published'
            LEFT JOIN engine.exercises AS engine ON engine.slug = core.slug
            WHERE core.id = %s
            """,
            (locale, exercise_id),
        )
        if exercise is None:
            raise not_found("exercise_not_found", "Exercise was not found")
        muscles = await self._fetch_all(
            connection,
            """
            SELECT muscle.id AS muscle_id, muscle.slug,
                   COALESCE(translation.display_name, muscle.name) AS name,
                   vector.value::numeric AS etu_cm2,
                   CASE WHEN muscle.pcsa_projected_fcsa_cm2 > 0
                        THEN vector.value::numeric / muscle.pcsa_projected_fcsa_cm2
                        ELSE NULL END AS capacity_share
            FROM engine.exercises AS engine
            CROSS JOIN LATERAL jsonb_each_text(COALESCE(engine.etu_vector, '{}'::jsonb))
                AS vector(slug, value)
            JOIN core.muscles AS muscle ON muscle.slug = vector.slug
            LEFT JOIN core.muscle_translations AS translation
              ON translation.muscle_id = muscle.id AND translation.locale = %s
            WHERE engine.slug = %s AND vector.value::numeric > 0
            ORDER BY vector.value::numeric DESC, muscle.slug
            LIMIT 5
            """,
            (locale, exercise["slug"]),
        )
        return {"exercise": exercise, "muscles": muscles}

    async def search_atlas(
        self,
        *,
        q: str | None,
        limit: int,
        plan_run_id: int | None,
        locale: str,
    ) -> list[Row]:
        async with self._pool.connection() as connection:
            rows = await self._fetch_all(
                connection,
                """
                SELECT core.id, core.slug,
                       COALESCE(translation.name, core.name) AS name,
                       COALESCE(translation.name_full, core.name_full) AS full_name,
                       core.mechanics_tier::text AS mechanics_tier,
                       core.target_category::text AS target_category
                FROM core.exercises AS core
                LEFT JOIN core.exercise_translations AS translation
                  ON translation.exercise_id = core.id
                 AND translation.locale = %s AND translation.status = 'published'
                WHERE (%s::text IS NULL OR core.slug ILIKE '%%' || %s || '%%'
                    OR core.name ILIKE '%%' || %s || '%%'
                    OR core.name_full ILIKE '%%' || %s || '%%'
                    OR translation.name ILIKE '%%' || %s || '%%'
                    OR translation.name_full ILIKE '%%' || %s || '%%')
                ORDER BY lower(COALESCE(translation.name, core.name)), core.id
                LIMIT %s
                """,
                (locale, q, q, q, q, q, q, limit),
            )
            if plan_run_id is not None:
                exists = await self._fetch_optional(
                    connection, "SELECT id FROM exec.plan_runs WHERE id = %s", (plan_run_id,)
                )
                if exists is None:
                    raise not_found("plan_run_not_found", "Plan run was not found")
                for row in rows:
                    row["last_performed_in_run"] = await self._last_exercise_in_run(
                        connection, plan_run_id, row["id"]
                    )
            else:
                for row in rows:
                    row["last_performed_in_run"] = None
            return rows

    async def _last_exercise_in_run(
        self, connection: Any, plan_run_id: int, exercise_id: int
    ) -> dict[str, Any] | None:
        exposure = await self._fetch_optional(
            connection,
            """
            SELECT exercise.id, mc.ordinal AS microcycle_ordinal
            FROM exec.exercise_unit_performances AS exercise
            JOIN exec.workout_unit_performances AS workout
              ON workout.id = exercise.workout_unit_performance_id
            JOIN exec.workout_unit_prescriptions AS prescription
              ON prescription.id = workout.workout_unit_prescription_id
            JOIN exec.workout_sessions AS session
              ON session.id = prescription.workout_session_id
            JOIN exec.microcycles AS mc ON mc.id = session.microcycle_id
            WHERE session.plan_run_id = %s AND exercise.actual_exercise_id = %s
              AND workout.status = 'finalized'
            ORDER BY workout.completed_at DESC, exercise.id DESC
            LIMIT 1
            """,
            (plan_run_id, exercise_id),
        )
        if exposure is None:
            return None
        sets = await self._fetch_all(
            connection,
            """
            SELECT load_kg, repetitions, rir
            FROM exec.set_performances
            WHERE exercise_unit_performance_id = %s AND status = 'performed'
            ORDER BY ordinal, id
            """,
            (exposure["id"],),
        )
        return {"microcycle_ordinal": exposure["microcycle_ordinal"], "sets": sets}

    async def start_workout(
        self,
        payload: StartWorkout,
        *,
        device_id: UUID,
    ) -> tuple[UUID, bool]:
        async with self._pool.connection() as connection:
            async with connection.transaction():
                existing = await self._fetch_optional(
                    connection,
                    """
                    SELECT client_uuid FROM exec.workout_unit_performances
                    WHERE client_uuid = %s
                    """,
                    (payload.workout_id,),
                )
                if existing is not None:
                    return cast(UUID, existing["client_uuid"]), False

                session_scope = await self._fetch_optional(
                    connection,
                    """
                    SELECT plan_run_id
                    FROM exec.workout_sessions
                    WHERE id = %s
                    """,
                    (payload.session_id,),
                )
                if session_scope is None:
                    raise not_found("session_not_found", "Workout session was not found")
                await self._execute(
                    connection,
                    "SELECT pg_advisory_xact_lock(674202114, %s)",
                    (session_scope["plan_run_id"],),
                )
                session = await self._fetch_optional(
                    connection,
                    """
                    SELECT session.*, session.status::text AS session_status,
                           workout.id AS prescription_id
                    FROM exec.workout_sessions AS session
                    LEFT JOIN exec.workout_unit_prescriptions AS workout
                      ON workout.workout_session_id = session.id
                    WHERE session.id = %s AND session.plan_run_id = %s
                    FOR UPDATE OF session
                    """,
                    (payload.session_id, session_scope["plan_run_id"]),
                )
                if session is None:
                    raise not_found("session_not_found", "Workout session was not found")

                active = await self._fetch_optional(
                    connection,
                    """
                    SELECT performance.client_uuid AS workout_id
                    FROM exec.workout_sessions AS active_session
                    JOIN exec.workout_unit_prescriptions AS prescription
                      ON prescription.workout_session_id = active_session.id
                    JOIN exec.workout_unit_performances AS performance
                      ON performance.workout_unit_prescription_id = prescription.id
                    WHERE active_session.plan_run_id = %s
                      AND active_session.status = 'in_progress'
                    FOR UPDATE OF active_session, performance
                    """,
                    (session["plan_run_id"],),
                )
                if active is not None:
                    raise conflict(
                        "active_workout_exists",
                        "A workout is already active in this plan run",
                        {"workout_id": str(active["workout_id"])},
                    )
                expected = await self._fetch_optional(
                    connection,
                    """
                    SELECT id
                    FROM exec.workout_sessions
                    WHERE plan_run_id = %s AND scheduled_date = %s
                      AND status = 'scheduled'
                    ORDER BY id
                    LIMIT 1
                    FOR UPDATE
                    """,
                    (session["plan_run_id"], payload.started_at.date()),
                )
                next_track = await self._fetch_optional(
                    connection,
                    """
                    SELECT candidate.id
                    FROM exec.workout_sessions AS candidate
                    JOIN exec.microcycles AS candidate_mc
                      ON candidate_mc.id = candidate.microcycle_id
                    WHERE candidate.plan_run_id = %s
                      AND candidate.workout_unit_track_id = %s
                      AND candidate.status IN ('scheduled', 'missed')
                    ORDER BY candidate_mc.ordinal, candidate.id
                    LIMIT 1
                    FOR UPDATE OF candidate
                    """,
                    (session["plan_run_id"], session["workout_unit_track_id"]),
                )
                expected_session_id = cast(int, expected["id"]) if expected else None
                next_track_session_id = cast(int, next_track["id"]) if next_track else None
                start_mode = resolve_start_mode(
                    payload,
                    session_status=cast(str, session["session_status"]),
                    expected_session_id=expected_session_id,
                    next_track_session_id=next_track_session_id,
                )
                if session["prescription_id"] is None:
                    raise invalid("prescription_missing", "The workout prescription is not ready")
                current_version = await self._prescription_version(connection, payload.session_id)
                if payload.prescription_version != current_version:
                    raise conflict(
                        "prescription_changed",
                        "The workout prescription changed before start",
                        {"prescription_version": current_version},
                    )
                readiness = await self._fetch_one(
                    connection,
                    f"""
                    SELECT count(DISTINCT exercise.id)::integer AS exercise_count,
                           count(sets.id)::integer AS set_count,
                           count(sets.id) FILTER
                             (WHERE sets.prescribed_load_kg IS NULL)::integer AS missing_loads,
                           {expected_plan_structure_sql("%s")}
                    FROM exec.workout_unit_prescriptions AS workout
                    LEFT JOIN exec.exercise_unit_prescriptions AS exercise
                      ON exercise.workout_unit_prescription_id = workout.id
                    LEFT JOIN exec.set_prescriptions AS sets
                      ON sets.exercise_unit_prescription_id = exercise.id
                    WHERE workout.id = %s
                    """,
                    (
                        session["source_plan_workout_unit_id"],
                        session["source_plan_workout_unit_id"],
                        session["prescription_id"],
                    ),
                )
                if not prescription_is_complete(readiness):
                    raise invalid(
                        "prescription_incomplete",
                        "The prescription does not contain the complete plan structure",
                        {
                            "session_id": payload.session_id,
                            "exercise_count": readiness["exercise_count"],
                            "expected_exercise_count": readiness["expected_exercise_count"],
                            "set_count": readiness["set_count"],
                            "expected_set_count": readiness["expected_set_count"],
                        },
                    )
                missing = (
                    readiness["exercise_count"] == 0
                    or readiness["set_count"] == 0
                    or readiness["missing_loads"] > 0
                )
                if missing and not payload.allow_missing_loads:
                    raise invalid(
                        "prescription_missing",
                        "Resolved prescription loads are missing",
                        {"session_id": payload.session_id},
                    )

                await self._execute(
                    connection,
                    """
                    UPDATE exec.workout_sessions
                    SET status = 'in_progress', started_at = %s,
                        start_mode = %s, off_schedule_selected_from = %s,
                        off_schedule_expected_session_id = %s,
                        updated_at = clock_timestamp()
                    WHERE id = %s
                    """,
                    (
                        payload.started_at,
                        start_mode,
                        payload.off_schedule.selected_from if payload.off_schedule else None,
                        (
                            payload.off_schedule.expected_session_id
                            if payload.off_schedule
                            else None
                        ),
                        payload.session_id,
                    ),
                )
                performance = await self._fetch_one(
                    connection,
                    """
                    INSERT INTO exec.workout_unit_performances (
                        workout_unit_prescription_id, client_uuid, status,
                        started_at, received_at, lease_device_id,
                        lease_epoch, applied_seq, revision
                    ) VALUES (%s, %s, 'draft', %s, clock_timestamp(), %s, 1, 0, 0)
                    RETURNING id
                    """,
                    (
                        session["prescription_id"],
                        payload.workout_id,
                        payload.started_at,
                        device_id,
                    ),
                )
                prescribed_exercises = await self._fetch_all(
                    connection,
                    """
                    SELECT id, exercise_unit_track_id, ordinal,
                           prescribed_exercise_id, source_plan_exercise_variant_id
                    FROM exec.exercise_unit_prescriptions
                    WHERE workout_unit_prescription_id = %s
                    ORDER BY ordinal, id
                    """,
                    (session["prescription_id"],),
                )
                for exercise in prescribed_exercises:
                    client_uuid = uuid5(payload.workout_id, f"ex:{exercise['id']}")
                    await self._execute(
                        connection,
                        """
                        INSERT INTO exec.exercise_unit_performances (
                            workout_unit_performance_id, prescribed_exercise_unit_id,
                            exercise_unit_track_id, ordinal, performed_ordinal,
                            execution_mode, actual_exercise_id,
                            actual_plan_exercise_variant_id, client_uuid
                        ) VALUES (%s, %s, %s, %s, %s, 'as_prescribed', %s, %s, %s)
                        """,
                        (
                            performance["id"],
                            exercise["id"],
                            exercise["exercise_unit_track_id"],
                            exercise["ordinal"],
                            exercise["ordinal"],
                            exercise["prescribed_exercise_id"],
                            exercise["source_plan_exercise_variant_id"],
                            client_uuid,
                        ),
                    )
                return payload.workout_id, True

    async def claim_workout(
        self,
        workout_id: UUID,
        payload: ClaimWorkout,
        *,
        header_device_id: UUID,
    ) -> UUID:
        if payload.device_id != header_device_id:
            raise invalid(
                "device_id_mismatch",
                "Claim device_id must match X-Agonez-Device-Id",
            )
        async with self._pool.connection() as connection:
            async with connection.transaction():
                workout = await self._lock_workout(connection, workout_id)
                if workout["performance_status"] != "draft":
                    raise conflict("workout_finalized", "Workout has already been finalized")
                if workout["lease_device_id"] == payload.device_id:
                    return workout_id
                await self._execute(
                    connection,
                    """
                    UPDATE exec.workout_unit_performances
                    SET lease_device_id = %s, lease_epoch = lease_epoch + 1,
                        applied_seq = 0, revision = revision + 1,
                        updated_at = clock_timestamp()
                    WHERE id = %s
                    """,
                    (payload.device_id, workout["id"]),
                )
                return workout_id

    async def apply_operations(
        self,
        workout_id: UUID,
        batch: OperationBatch,
        *,
        device_id: UUID,
    ) -> dict[str, Any]:
        async with self._pool.connection() as connection:
            async with connection.transaction():
                workout = await self._lock_workout(connection, workout_id)
                self._assert_writable_lease(workout, batch.lease_epoch, device_id)
                applied_seq = cast(int, workout["applied_seq"])
                if batch.base_seq > applied_seq:
                    raise conflict(
                        "seq_gap",
                        "The operation batch starts after the next expected sequence",
                        {"expected_seq": applied_seq + 1},
                    )
                results: list[dict[str, Any]] = []
                revision = cast(int, workout["revision"])
                for operation in batch.ops:
                    existing = await self._fetch_optional(
                        connection,
                        """
                        SELECT op_id, result_status, result
                        FROM exec.mobile_sync_ops
                        WHERE workout_unit_performance_id = %s
                          AND lease_epoch = %s AND seq = %s
                        """,
                        (workout["id"], batch.lease_epoch, operation.seq),
                    )
                    if existing is not None:
                        if existing["op_id"] != operation.op_id:
                            raise conflict(
                                "seq_mismatch",
                                "This sequence was already used by another operation",
                                {"seq": operation.seq},
                            )
                        duplicate = dict(existing["result"])
                        duplicate["status"] = "duplicate"
                        results.append(duplicate)
                        continue
                    duplicate_op = await self._fetch_optional(
                        connection,
                        "SELECT seq FROM exec.mobile_sync_ops WHERE op_id = %s",
                        (operation.op_id,),
                    )
                    if duplicate_op is not None:
                        raise conflict(
                            "seq_mismatch",
                            "This operation id was already used at another sequence",
                            {"seq": operation.seq, "existing_seq": duplicate_op["seq"]},
                        )
                    if operation.seq != applied_seq + 1:
                        raise conflict(
                            "seq_gap",
                            "An operation sequence is missing",
                            {"expected_seq": applied_seq + 1},
                        )
                    result = await self._apply_operation(connection, workout, operation)
                    applied_seq = operation.seq
                    revision += 1
                    await self._execute(
                        connection,
                        """
                        INSERT INTO exec.mobile_sync_ops (
                            workout_unit_performance_id, lease_epoch, seq, op_id,
                            client_at, op_type, payload, result_status, result
                        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                        """,
                        (
                            workout["id"],
                            batch.lease_epoch,
                            operation.seq,
                            operation.op_id,
                            operation.at,
                            operation.type,
                            Jsonb(operation.data.model_dump(mode="json")),
                            result["status"],
                            Jsonb(result),
                        ),
                    )
                    results.append(result)
                await self._execute(
                    connection,
                    """
                    UPDATE exec.workout_unit_performances
                    SET applied_seq = %s, revision = %s, updated_at = clock_timestamp()
                    WHERE id = %s
                    """,
                    (applied_seq, revision, workout["id"]),
                )
                return {
                    "applied_seq": applied_seq,
                    "revision": revision,
                    "results": results,
                }

    async def _apply_operation(
        self,
        connection: Any,
        workout: Row,
        operation: MobileOperation,
    ) -> dict[str, Any]:
        try:
            entity_rev: int | None = None
            server_state: dict[str, Any] | None = None
            if isinstance(operation, UpsertSetOperation):
                entity_rev, server_state = await self._upsert_set(connection, workout, operation)
            elif isinstance(operation, SkipSetOperation):
                entity_rev, server_state = await self._skip_set(connection, workout, operation)
            elif isinstance(operation, ClearSetOperation):
                entity_rev, server_state = await self._clear_set(connection, workout, operation)
            elif isinstance(operation, SetExerciseCommentOperation):
                entity_rev, server_state = await self._set_exercise_comment(
                    connection, workout, operation
                )
            elif isinstance(operation, SkipExerciseOperation):
                entity_rev, server_state = await self._skip_exercise(connection, workout, operation)
            elif isinstance(operation, SubstituteExerciseOperation):
                entity_rev, server_state = await self._substitute_exercise(
                    connection, workout, operation
                )
            elif isinstance(operation, AddUnplannedExerciseOperation):
                entity_rev, server_state = await self._add_unplanned_exercise(
                    connection, workout, operation
                )
            elif isinstance(operation, ReorderExercisesOperation):
                await self._reorder_exercises(connection, workout, operation)
            elif isinstance(operation, SetCursorOperation):
                await self._set_cursor(connection, workout, operation)
            elif isinstance(operation, SetWorkoutCommentOperation):
                await self._execute(
                    connection,
                    """
                    UPDATE exec.workout_unit_performances
                    SET performance_comment = %s, updated_at = clock_timestamp()
                    WHERE id = %s
                    """,
                    (operation.data.comment, workout["id"]),
                )
            status = "conflict" if server_state is not None else "applied"
            return self._operation_result(
                operation,
                status=status,
                entity_rev=entity_rev,
                server_state=server_state,
            )
        except _OperationRejected as exc:
            return self._operation_result(
                operation,
                status="rejected",
                error={"code": exc.code, "message": exc.message},
            )

    async def _upsert_set(
        self, connection: Any, workout: Row, operation: UpsertSetOperation
    ) -> tuple[int | None, dict[str, Any] | None]:
        data = operation.data
        self._validate_set_values(
            load_kg=data.load_kg,
            repetitions=data.repetitions,
            rir=data.rir,
            heart_rate_bpm=data.heart_rate_bpm,
        )
        exercise = await self._resolve_exercise_performance(
            connection,
            workout,
            data.exercise_performance_id,
            data.exercise_prescription_id,
        )
        await self._validate_set_reference(
            connection,
            workout,
            exercise,
            data.prescribed_set_id,
        )
        existing = await self._set_by_client_uuid(connection, workout, data.set_performance_id)
        await self._ensure_set_ordinal_available(
            connection,
            exercise["id"],
            data.ordinal,
            existing["id"] if existing else None,
        )
        desired = {
            "prescribed_set_id": data.prescribed_set_id,
            "ordinal": data.ordinal,
            "status": "performed",
            "load_kg": data.load_kg,
            "repetitions": data.repetitions,
            "rir": data.rir,
            "comment": data.comment,
            "heart_rate_bpm": data.heart_rate_bpm,
            "performed_at": data.performed_at,
        }
        if existing is None:
            if data.prescribed_set_id is not None:
                by_prescription = await self._fetch_optional(
                    connection,
                    "SELECT client_uuid FROM exec.set_performances WHERE prescribed_set_id = %s",
                    (data.prescribed_set_id,),
                )
                if by_prescription is not None:
                    raise _OperationRejected(
                        "identity_mismatch",
                        "The prescribed set already has another performance identity",
                    )
            inserted = await self._fetch_one(
                connection,
                """
                INSERT INTO exec.set_performances (
                    exercise_unit_performance_id, prescribed_set_id, ordinal,
                    status, load_kg, repetitions, rir, performance_comment,
                    client_uuid, rev, performed_at, received_at, heart_rate_bpm
                ) VALUES (%s, %s, %s, 'performed', %s, %s, %s, %s, %s, 1,
                          %s, clock_timestamp(), %s)
                RETURNING rev
                """,
                (
                    exercise["id"],
                    data.prescribed_set_id,
                    data.ordinal,
                    data.load_kg,
                    data.repetitions,
                    data.rir,
                    data.comment,
                    data.set_performance_id,
                    data.performed_at,
                    data.heart_rate_bpm,
                ),
            )
            return cast(int, inserted["rev"]), None
        if existing["exercise_unit_performance_id"] != exercise["id"]:
            raise _OperationRejected(
                "identity_mismatch", "Set performance belongs to another exercise"
            )
        current_state = self._set_state(existing)
        if self._stale_and_different(data.if_rev, existing["rev"], desired, current_state):
            return cast(int, existing["rev"]), current_state
        if self._states_equal(desired, current_state):
            return cast(int, existing["rev"]), None
        updated = await self._fetch_one(
            connection,
            """
            UPDATE exec.set_performances
            SET prescribed_set_id = %s, ordinal = %s, status = 'performed',
                load_kg = %s, repetitions = %s, rir = %s,
                performance_comment = %s, heart_rate_bpm = %s,
                performed_at = %s, received_at = clock_timestamp(), rev = rev + 1
            WHERE id = %s
            RETURNING rev
            """,
            (
                data.prescribed_set_id,
                data.ordinal,
                data.load_kg,
                data.repetitions,
                data.rir,
                data.comment,
                data.heart_rate_bpm,
                data.performed_at,
                existing["id"],
            ),
        )
        return cast(int, updated["rev"]), None

    async def _skip_set(
        self, connection: Any, workout: Row, operation: SkipSetOperation
    ) -> tuple[int | None, dict[str, Any] | None]:
        data = operation.data
        exercise = await self._resolve_exercise_performance(
            connection,
            workout,
            data.exercise_performance_id,
            data.exercise_prescription_id,
        )
        await self._validate_set_reference(connection, workout, exercise, data.prescribed_set_id)
        existing = await self._set_by_client_uuid(connection, workout, data.set_performance_id)
        await self._ensure_set_ordinal_available(
            connection,
            exercise["id"],
            data.ordinal,
            existing["id"] if existing else None,
        )
        desired = {
            "prescribed_set_id": data.prescribed_set_id,
            "ordinal": data.ordinal,
            "status": "skipped",
            "load_kg": None,
            "repetitions": None,
            "rir": None,
            "comment": data.comment,
            "heart_rate_bpm": None,
            "performed_at": None,
        }
        if existing is None:
            by_prescription = await self._fetch_optional(
                connection,
                "SELECT client_uuid FROM exec.set_performances WHERE prescribed_set_id = %s",
                (data.prescribed_set_id,),
            )
            if by_prescription is not None:
                raise _OperationRejected(
                    "identity_mismatch",
                    "The prescribed set already has another performance identity",
                )
            inserted = await self._fetch_one(
                connection,
                """
                INSERT INTO exec.set_performances (
                    exercise_unit_performance_id, prescribed_set_id, ordinal,
                    status, performance_comment, client_uuid, rev, received_at
                ) VALUES (%s, %s, %s, 'skipped', %s, %s, 1, clock_timestamp())
                RETURNING rev
                """,
                (
                    exercise["id"],
                    data.prescribed_set_id,
                    data.ordinal,
                    data.comment,
                    data.set_performance_id,
                ),
            )
            return cast(int, inserted["rev"]), None
        if existing["exercise_unit_performance_id"] != exercise["id"]:
            raise _OperationRejected(
                "identity_mismatch", "Set performance belongs to another exercise"
            )
        current_state = self._set_state(existing)
        if self._stale_and_different(data.if_rev, existing["rev"], desired, current_state):
            return cast(int, existing["rev"]), current_state
        if self._states_equal(desired, current_state):
            return cast(int, existing["rev"]), None
        updated = await self._fetch_one(
            connection,
            """
            UPDATE exec.set_performances
            SET prescribed_set_id = %s, ordinal = %s, status = 'skipped',
                load_kg = NULL, repetitions = NULL, rir = NULL,
                performance_comment = %s, heart_rate_bpm = NULL,
                performed_at = NULL, received_at = clock_timestamp(), rev = rev + 1
            WHERE id = %s
            RETURNING rev
            """,
            (data.prescribed_set_id, data.ordinal, data.comment, existing["id"]),
        )
        return cast(int, updated["rev"]), None

    async def _clear_set(
        self, connection: Any, workout: Row, operation: ClearSetOperation
    ) -> tuple[int | None, dict[str, Any] | None]:
        existing = await self._set_by_client_uuid(
            connection, workout, operation.data.set_performance_id
        )
        if existing is None:
            return None, None
        current_state = self._set_state(existing)
        if operation.data.if_rev is not None and operation.data.if_rev != existing["rev"]:
            return cast(int, existing["rev"]), current_state
        await self._execute(
            connection, "DELETE FROM exec.set_performances WHERE id = %s", (existing["id"],)
        )
        return None, None

    async def _set_exercise_comment(
        self,
        connection: Any,
        workout: Row,
        operation: SetExerciseCommentOperation,
    ) -> tuple[int | None, dict[str, Any] | None]:
        exercise = await self._resolve_exercise_performance(
            connection,
            workout,
            operation.data.exercise_performance_id,
            operation.data.exercise_prescription_id,
        )
        desired = {"comment": operation.data.comment}
        current = {"comment": exercise["performance_comment"]}
        if self._stale_and_different(operation.data.if_rev, exercise["rev"], desired, current):
            return cast(int, exercise["rev"]), self._exercise_state(exercise)
        if desired == current:
            return cast(int, exercise["rev"]), None
        updated = await self._fetch_one(
            connection,
            """
            UPDATE exec.exercise_unit_performances
            SET performance_comment = %s, rev = rev + 1,
                updated_at = clock_timestamp()
            WHERE id = %s RETURNING rev
            """,
            (operation.data.comment, exercise["id"]),
        )
        return cast(int, updated["rev"]), None

    async def _skip_exercise(
        self, connection: Any, workout: Row, operation: SkipExerciseOperation
    ) -> tuple[int | None, dict[str, Any] | None]:
        data = operation.data
        exercise = await self._resolve_exercise_performance(
            connection,
            workout,
            data.exercise_performance_id,
            data.exercise_prescription_id,
        )
        desired = {
            "mode": "skipped",
            "actual_exercise_id": None,
            "comment": data.comment,
        }
        current = {
            "mode": exercise["execution_mode"],
            "actual_exercise_id": exercise["actual_exercise_id"],
            "comment": exercise["performance_comment"],
        }
        if self._stale_and_different(data.if_rev, exercise["rev"], desired, current):
            return cast(int, exercise["rev"]), self._exercise_state(exercise)
        if desired != current:
            exercise = await self._fetch_one(
                connection,
                """
                UPDATE exec.exercise_unit_performances
                SET execution_mode = 'skipped', actual_exercise_id = NULL,
                    actual_plan_exercise_variant_id = NULL,
                    performance_comment = %s, rev = rev + 1,
                    updated_at = clock_timestamp()
                WHERE id = %s RETURNING *, execution_mode::text AS execution_mode
                """,
                (data.comment, exercise["id"]),
            )
        missing_sets = await self._fetch_all(
            connection,
            """
            SELECT prescription.id, prescription.ordinal
            FROM exec.set_prescriptions AS prescription
            WHERE prescription.exercise_unit_prescription_id = %s
              AND NOT EXISTS (
                  SELECT 1 FROM exec.set_performances AS performance
                  WHERE performance.prescribed_set_id = prescription.id
              )
            ORDER BY prescription.ordinal
            """,
            (data.exercise_prescription_id,),
        )
        for prescribed in missing_sets:
            await self._execute(
                connection,
                """
                INSERT INTO exec.set_performances (
                    exercise_unit_performance_id, prescribed_set_id, ordinal,
                    status, client_uuid, rev, received_at
                ) VALUES (%s, %s, %s, 'skipped', %s, 1, clock_timestamp())
                """,
                (
                    exercise["id"],
                    prescribed["id"],
                    prescribed["ordinal"],
                    uuid5(cast(UUID, workout["client_uuid"]), f"set:{prescribed['id']}"),
                ),
            )
        return cast(int, exercise["rev"]), None

    async def _substitute_exercise(
        self,
        connection: Any,
        workout: Row,
        operation: SubstituteExerciseOperation,
    ) -> tuple[int | None, dict[str, Any] | None]:
        data = operation.data
        exercise = await self._resolve_exercise_performance(
            connection,
            workout,
            data.exercise_performance_id,
            data.exercise_prescription_id,
        )
        performed = await self._fetch_optional(
            connection,
            """
            SELECT id FROM exec.set_performances
            WHERE exercise_unit_performance_id = %s AND status = 'performed'
            LIMIT 1
            """,
            (exercise["id"],),
        )
        if performed is not None:
            raise _OperationRejected(
                "substitution_after_sets",
                "The actual exercise cannot change after a set was performed",
            )
        actual = await self._fetch_optional(
            connection, "SELECT id FROM core.exercises WHERE id = %s", (data.actual_exercise_id,)
        )
        if actual is None:
            raise _OperationRejected("exercise_not_found", "Exercise was not found")
        variant_id: int | None = None
        if data.source == "plan_variant":
            variant = await self._fetch_optional(
                connection,
                """
                SELECT variant.id
                FROM plans.exercise_variants AS variant
                JOIN exec.exercise_unit_prescriptions AS prescription
                  ON prescription.source_plan_exercise_slot_id = variant.slot_id
                WHERE prescription.id = %s AND variant.exercise_id = %s
                  AND (%s::integer IS NULL OR variant.ordinal = %s)
                """,
                (
                    data.exercise_prescription_id,
                    data.actual_exercise_id,
                    data.variant_ordinal,
                    data.variant_ordinal,
                ),
            )
            if variant is None:
                raise _OperationRejected(
                    "unknown_prescription_ref", "Plan exercise variant was not found"
                )
            variant_id = cast(int, variant["id"])
        desired = {
            "mode": "substituted",
            "actual_exercise_id": data.actual_exercise_id,
            "actual_plan_exercise_variant_id": variant_id,
        }
        current = {
            "mode": exercise["execution_mode"],
            "actual_exercise_id": exercise["actual_exercise_id"],
            "actual_plan_exercise_variant_id": exercise["actual_plan_exercise_variant_id"],
        }
        if self._stale_and_different(data.if_rev, exercise["rev"], desired, current):
            return cast(int, exercise["rev"]), self._exercise_state(exercise)
        if desired == current:
            return cast(int, exercise["rev"]), None
        updated = await self._fetch_one(
            connection,
            """
            UPDATE exec.exercise_unit_performances
            SET execution_mode = 'substituted', actual_exercise_id = %s,
                actual_plan_exercise_variant_id = %s, rev = rev + 1,
                updated_at = clock_timestamp()
            WHERE id = %s RETURNING rev
            """,
            (data.actual_exercise_id, variant_id, exercise["id"]),
        )
        return cast(int, updated["rev"]), None

    async def _add_unplanned_exercise(
        self,
        connection: Any,
        workout: Row,
        operation: AddUnplannedExerciseOperation,
    ) -> tuple[int | None, dict[str, Any] | None]:
        data = operation.data
        existing = await self._fetch_optional(
            connection,
            """
            SELECT *, execution_mode::text AS execution_mode
            FROM exec.exercise_unit_performances
            WHERE client_uuid = %s
            """,
            (data.exercise_performance_id,),
        )
        if existing is not None:
            if existing["workout_unit_performance_id"] != workout["id"]:
                raise _OperationRejected(
                    "identity_mismatch", "Exercise performance belongs to another workout"
                )
            desired = {
                "mode": "additional",
                "actual_exercise_id": data.actual_exercise_id,
                "performed_ordinal": data.performed_ordinal,
            }
            current = {
                "mode": existing["execution_mode"],
                "actual_exercise_id": existing["actual_exercise_id"],
                "performed_ordinal": existing["performed_ordinal"],
            }
            if self._stale_and_different(data.if_rev, existing["rev"], desired, current):
                return cast(int, existing["rev"]), self._exercise_state(existing)
            if desired == current:
                return cast(int, existing["rev"]), None
            raise _OperationRejected(
                "identity_mismatch", "An existing exercise identity cannot be repurposed"
            )
        actual = await self._fetch_optional(
            connection, "SELECT id FROM core.exercises WHERE id = %s", (data.actual_exercise_id,)
        )
        if actual is None:
            raise _OperationRejected("exercise_not_found", "Exercise was not found")
        ordinal_conflict = await self._fetch_optional(
            connection,
            """
            SELECT id FROM exec.exercise_unit_performances
            WHERE workout_unit_performance_id = %s
              AND performed_ordinal = %s
            """,
            (workout["id"], data.performed_ordinal),
        )
        if ordinal_conflict is not None:
            raise _OperationRejected(
                "ordinal_conflict", "Another exercise uses this performed ordinal"
            )
        max_ordinal = await self._fetch_one(
            connection,
            """
            SELECT COALESCE(max(ordinal), -1) + 1 AS ordinal
            FROM exec.exercise_unit_performances
            WHERE workout_unit_performance_id = %s
            """,
            (workout["id"],),
        )
        inserted = await self._fetch_one(
            connection,
            """
            INSERT INTO exec.exercise_unit_performances (
                workout_unit_performance_id, prescribed_exercise_unit_id,
                exercise_unit_track_id, ordinal, performed_ordinal,
                execution_mode, actual_exercise_id, client_uuid, rev
            ) VALUES (%s, NULL, NULL, %s, %s, 'additional', %s, %s, 1)
            RETURNING rev
            """,
            (
                workout["id"],
                max_ordinal["ordinal"],
                data.performed_ordinal,
                data.actual_exercise_id,
                data.exercise_performance_id,
            ),
        )
        return cast(int, inserted["rev"]), None

    async def _reorder_exercises(
        self, connection: Any, workout: Row, operation: ReorderExercisesOperation
    ) -> None:
        rows = await self._fetch_all(
            connection,
            """
            SELECT id, client_uuid FROM exec.exercise_unit_performances
            WHERE workout_unit_performance_id = %s
            """,
            (workout["id"],),
        )
        actual_ids = {row["client_uuid"] for row in rows}
        if actual_ids != set(operation.data.order):
            raise _OperationRejected(
                "exercise_order_incomplete",
                "Exercise order must contain every exercise performance exactly once",
            )
        await self._execute(
            connection,
            """
            UPDATE exec.exercise_unit_performances
            SET performed_ordinal = performed_ordinal + 1000000
            WHERE workout_unit_performance_id = %s
            """,
            (workout["id"],),
        )
        for ordinal, client_uuid in enumerate(operation.data.order):
            await self._execute(
                connection,
                """
                UPDATE exec.exercise_unit_performances
                SET performed_ordinal = %s, rev = rev + 1,
                    updated_at = clock_timestamp()
                WHERE workout_unit_performance_id = %s AND client_uuid = %s
                """,
                (ordinal, workout["id"], client_uuid),
            )

    async def _set_cursor(
        self, connection: Any, workout: Row, operation: SetCursorOperation
    ) -> None:
        exercise = await self._fetch_optional(
            connection,
            """
            SELECT id FROM exec.exercise_unit_performances
            WHERE workout_unit_performance_id = %s AND client_uuid = %s
            """,
            (workout["id"], operation.data.exercise_performance_id),
        )
        if exercise is None:
            raise _OperationRejected(
                "exercise_performance_not_found", "Exercise performance was not found"
            )
        await self._execute(
            connection,
            """
            UPDATE exec.workout_unit_performances
            SET position_exercise_performance_uuid = %s,
                position_set_ordinal = %s, position_phase = %s,
                updated_at = clock_timestamp()
            WHERE id = %s
            """,
            (
                operation.data.exercise_performance_id,
                operation.data.set_ordinal,
                operation.data.phase,
                workout["id"],
            ),
        )

    async def finalize_workout(
        self,
        workout_id: UUID,
        payload: FinalizeWorkout,
        *,
        device_id: UUID,
    ) -> dict[str, Any]:
        async with self._pool.connection() as connection:
            async with connection.transaction():
                workout = await self._lock_workout(connection, workout_id)
                if workout["performance_status"] == "finalized":
                    if workout["final_seq"] == payload.final_seq:
                        return await self._completion_summary(connection, workout)
                    raise conflict("workout_finalized", "Workout has already been finalized")
                self._assert_writable_lease(workout, payload.lease_epoch, device_id)
                if workout["applied_seq"] != payload.final_seq:
                    raise conflict(
                        "ops_pending",
                        "Workout operations must be synchronized before finalization",
                        {"applied_seq": workout["applied_seq"]},
                    )
                if payload.finished_at < workout["started_at"]:
                    raise invalid(
                        "finish_before_start",
                        "Workout finish time cannot be before its start time",
                    )
                missing_exercises = await self._fetch_all(
                    connection,
                    """
                    SELECT exercise_rx.*
                    FROM exec.exercise_unit_prescriptions AS exercise_rx
                    WHERE exercise_rx.workout_unit_prescription_id = %s
                      AND NOT EXISTS (
                          SELECT 1
                          FROM exec.exercise_unit_performances AS exercise_perf
                          WHERE exercise_perf.workout_unit_performance_id = %s
                            AND exercise_perf.prescribed_exercise_unit_id = exercise_rx.id
                      )
                    ORDER BY exercise_rx.ordinal, exercise_rx.id
                    """,
                    (workout["workout_unit_prescription_id"], workout["id"]),
                )
                for exercise in missing_exercises:
                    await self._execute(
                        connection,
                        """
                        INSERT INTO exec.exercise_unit_performances (
                            workout_unit_performance_id, prescribed_exercise_unit_id,
                            exercise_unit_track_id, ordinal, performed_ordinal,
                            execution_mode, actual_exercise_id,
                            actual_plan_exercise_variant_id, client_uuid
                        ) VALUES (%s, %s, %s, %s, %s, 'as_prescribed', %s, %s, %s)
                        """,
                        (
                            workout["id"],
                            exercise["id"],
                            exercise["exercise_unit_track_id"],
                            exercise["ordinal"],
                            exercise["ordinal"],
                            exercise["prescribed_exercise_id"],
                            exercise["source_plan_exercise_variant_id"],
                            uuid5(
                                cast(UUID, workout["client_uuid"]),
                                f"ex:{exercise['id']}",
                            ),
                        ),
                    )
                missing = await self._fetch_all(
                    connection,
                    """
                    SELECT set_rx.id AS set_prescription_id, set_rx.ordinal,
                           exercise_perf.id AS exercise_performance_id
                    FROM exec.workout_unit_performances AS workout_perf
                    JOIN exec.workout_unit_prescriptions AS workout_rx
                      ON workout_rx.id = workout_perf.workout_unit_prescription_id
                    JOIN exec.exercise_unit_prescriptions AS exercise_rx
                      ON exercise_rx.workout_unit_prescription_id = workout_rx.id
                    JOIN exec.exercise_unit_performances AS exercise_perf
                      ON exercise_perf.workout_unit_performance_id = workout_perf.id
                     AND exercise_perf.prescribed_exercise_unit_id = exercise_rx.id
                    JOIN exec.set_prescriptions AS set_rx
                      ON set_rx.exercise_unit_prescription_id = exercise_rx.id
                    LEFT JOIN exec.set_performances AS set_perf
                      ON set_perf.prescribed_set_id = set_rx.id
                    WHERE workout_perf.id = %s AND set_perf.id IS NULL
                    ORDER BY exercise_rx.ordinal, set_rx.ordinal
                    """,
                    (workout["id"],),
                )
                if missing and not payload.acknowledged_incomplete:
                    raise conflict(
                        "incomplete_not_acknowledged",
                        "Incomplete prescribed work must be explicitly acknowledged",
                        {"unrecorded_sets": len(missing)},
                    )
                explicit_exercises = await self._fetch_all(
                    connection,
                    """
                    SELECT exercise.id
                    FROM exec.exercise_unit_performances AS exercise
                    WHERE exercise.workout_unit_performance_id = %s
                      AND EXISTS (
                          SELECT 1 FROM exec.set_performances AS sets
                          WHERE sets.exercise_unit_performance_id = exercise.id
                      )
                    """,
                    (workout["id"],),
                )
                explicit_ids = {row["id"] for row in explicit_exercises}
                for item in missing:
                    await self._execute(
                        connection,
                        """
                        INSERT INTO exec.set_performances (
                            exercise_unit_performance_id, prescribed_set_id,
                            ordinal, status, client_uuid, rev, received_at
                        ) VALUES (%s, %s, %s, 'not_performed', %s, 1, clock_timestamp())
                        """,
                        (
                            item["exercise_performance_id"],
                            item["set_prescription_id"],
                            item["ordinal"],
                            uuid5(
                                cast(UUID, workout["client_uuid"]),
                                f"set:{item['set_prescription_id']}",
                            ),
                        ),
                    )
                if explicit_ids:
                    await self._execute(
                        connection,
                        """
                        UPDATE exec.exercise_unit_performances
                        SET execution_mode = 'not_performed', actual_exercise_id = NULL,
                            actual_plan_exercise_variant_id = NULL,
                            rev = rev + 1, updated_at = clock_timestamp()
                        WHERE workout_unit_performance_id = %s
                          AND execution_mode = 'as_prescribed'
                          AND NOT (id = ANY(%s::integer[]))
                        """,
                        (workout["id"], list(explicit_ids)),
                    )
                else:
                    await self._execute(
                        connection,
                        """
                        UPDATE exec.exercise_unit_performances
                        SET execution_mode = 'not_performed', actual_exercise_id = NULL,
                            actual_plan_exercise_variant_id = NULL,
                            rev = rev + 1, updated_at = clock_timestamp()
                        WHERE workout_unit_performance_id = %s
                          AND execution_mode = 'as_prescribed'
                        """,
                        (workout["id"],),
                    )
                await self._execute(
                    connection,
                    """
                    UPDATE exec.workout_unit_performances
                    SET status = 'finalized', completed_at = %s, final_seq = %s,
                        revision = revision + 1, updated_at = clock_timestamp()
                    WHERE id = %s
                    """,
                    (payload.finished_at, payload.final_seq, workout["id"]),
                )
                await self._execute(
                    connection,
                    """
                    UPDATE exec.workout_sessions
                    SET status = 'completed', completed_at = %s,
                        completion_mode = 'as_prescribed', updated_at = clock_timestamp()
                    WHERE id = %s
                    """,
                    (payload.finished_at, workout["session_id"]),
                )
                workout["completed_at"] = payload.finished_at
                workout["performance_status"] = "finalized"
                workout["final_seq"] = payload.final_seq
                return await self._completion_summary(connection, workout)

    async def _completion_summary(self, connection: Any, workout: Row) -> dict[str, Any]:
        summary = await self._fetch_one(
            connection,
            """
            SELECT
                count(DISTINCT set_rx.id)::integer AS prescribed_sets,
                count(DISTINCT set_perf.id) FILTER
                  (WHERE set_perf.status = 'performed')::integer AS performed_sets,
                count(DISTINCT set_perf.id) FILTER
                  (WHERE set_perf.status = 'skipped')::integer AS skipped_sets,
                count(DISTINCT set_perf.id) FILTER
                  (WHERE set_perf.status = 'not_performed')::integer AS not_performed_sets,
                count(DISTINCT set_perf.id) FILTER
                  (WHERE set_perf.prescribed_set_id IS NULL)::integer AS additional_sets,
                count(DISTINCT exercise_perf.id) FILTER
                  (WHERE exercise_perf.execution_mode = 'substituted')::integer
                    AS substitutions,
                count(DISTINCT exercise_perf.id) FILTER
                  (WHERE exercise_perf.execution_mode = 'skipped')::integer
                    AS skipped_exercises,
                count(DISTINCT exercise_perf.id) FILTER
                  (WHERE exercise_perf.execution_mode = 'additional')::integer
                    AS added_exercises,
                COALESCE(bool_or(
                    exercise_perf.prescribed_exercise_unit_id IS NOT NULL
                    AND exercise_perf.performed_ordinal <> exercise_rx.ordinal
                ), false) AS reordered
            FROM exec.workout_unit_performances AS workout_perf
            JOIN exec.workout_unit_prescriptions AS workout_rx
              ON workout_rx.id = workout_perf.workout_unit_prescription_id
            LEFT JOIN exec.exercise_unit_performances AS exercise_perf
              ON exercise_perf.workout_unit_performance_id = workout_perf.id
            LEFT JOIN exec.exercise_unit_prescriptions AS exercise_rx
              ON exercise_rx.id = exercise_perf.prescribed_exercise_unit_id
            LEFT JOIN exec.set_prescriptions AS set_rx
              ON set_rx.exercise_unit_prescription_id = exercise_rx.id
            LEFT JOIN exec.set_performances AS set_perf
              ON set_perf.exercise_unit_performance_id = exercise_perf.id
            WHERE workout_perf.id = %s
            """,
            (workout["id"],),
        )
        return {
            "workout_id": workout["client_uuid"],
            "status": "completed",
            "finished_at": workout["completed_at"],
            "summary": summary,
        }

    async def _resolve_exercise_performance(
        self,
        connection: Any,
        workout: Row,
        client_uuid: UUID,
        exercise_prescription_id: int | None,
    ) -> Row:
        exercise = await self._fetch_optional(
            connection,
            """
            SELECT *, execution_mode::text AS execution_mode
            FROM exec.exercise_unit_performances
            WHERE client_uuid = %s
            """,
            (client_uuid,),
        )
        if exercise is not None:
            if exercise["workout_unit_performance_id"] != workout["id"]:
                raise _OperationRejected(
                    "identity_mismatch", "Exercise performance belongs to another workout"
                )
            if (
                exercise_prescription_id is not None
                and exercise["prescribed_exercise_unit_id"] != exercise_prescription_id
            ):
                raise _OperationRejected(
                    "prescription_ref_mismatch",
                    "Exercise identity does not match its prescription reference",
                )
            return exercise
        if exercise_prescription_id is None:
            raise _OperationRejected(
                "exercise_performance_not_found", "Exercise performance was not found"
            )
        prescription = await self._fetch_optional(
            connection,
            """
            SELECT exercise.*
            FROM exec.exercise_unit_prescriptions AS exercise
            JOIN exec.workout_unit_prescriptions AS workout_rx
              ON workout_rx.id = exercise.workout_unit_prescription_id
            WHERE exercise.id = %s AND workout_rx.id = %s
            """,
            (exercise_prescription_id, workout["workout_unit_prescription_id"]),
        )
        if prescription is None:
            raise _OperationRejected(
                "unknown_prescription_ref", "Exercise prescription was not found"
            )
        occupied = await self._fetch_optional(
            connection,
            """
            SELECT client_uuid FROM exec.exercise_unit_performances
            WHERE prescribed_exercise_unit_id = %s
            """,
            (exercise_prescription_id,),
        )
        if occupied is not None:
            raise _OperationRejected(
                "identity_mismatch",
                "The exercise prescription already has another performance identity",
            )
        return await self._fetch_one(
            connection,
            """
            INSERT INTO exec.exercise_unit_performances (
                workout_unit_performance_id, prescribed_exercise_unit_id,
                exercise_unit_track_id, ordinal, performed_ordinal,
                execution_mode, actual_exercise_id,
                actual_plan_exercise_variant_id, client_uuid
            ) VALUES (%s, %s, %s, %s, %s, 'as_prescribed', %s, %s, %s)
            RETURNING *, execution_mode::text AS execution_mode
            """,
            (
                workout["id"],
                prescription["id"],
                prescription["exercise_unit_track_id"],
                prescription["ordinal"],
                prescription["ordinal"],
                prescription["prescribed_exercise_id"],
                prescription["source_plan_exercise_variant_id"],
                client_uuid,
            ),
        )

    async def _validate_set_reference(
        self,
        connection: Any,
        workout: Row,
        exercise: Row,
        prescribed_set_id: int | None,
    ) -> None:
        if prescribed_set_id is None:
            return
        prescribed = await self._fetch_optional(
            connection,
            """
            SELECT sets.exercise_unit_prescription_id
            FROM exec.set_prescriptions AS sets
            JOIN exec.exercise_unit_prescriptions AS exercise_rx
              ON exercise_rx.id = sets.exercise_unit_prescription_id
            WHERE sets.id = %s AND exercise_rx.workout_unit_prescription_id = %s
            """,
            (prescribed_set_id, workout["workout_unit_prescription_id"]),
        )
        if prescribed is None:
            raise _OperationRejected("unknown_prescription_ref", "Set prescription was not found")
        if prescribed["exercise_unit_prescription_id"] != exercise["prescribed_exercise_unit_id"]:
            raise _OperationRejected(
                "prescription_ref_mismatch",
                "Set prescription does not belong to the exercise prescription",
            )

    async def _set_by_client_uuid(
        self, connection: Any, workout: Row, client_uuid: UUID
    ) -> Row | None:
        row = await self._fetch_optional(
            connection,
            """
            SELECT sets.*, sets.status::text AS status
            FROM exec.set_performances AS sets
            JOIN exec.exercise_unit_performances AS exercise
              ON exercise.id = sets.exercise_unit_performance_id
            WHERE sets.client_uuid = %s
            """,
            (client_uuid,),
        )
        if row is not None:
            owner = await self._fetch_one(
                connection,
                """
                SELECT workout_unit_performance_id
                FROM exec.exercise_unit_performances WHERE id = %s
                """,
                (row["exercise_unit_performance_id"],),
            )
            if owner["workout_unit_performance_id"] != workout["id"]:
                raise _OperationRejected(
                    "identity_mismatch", "Set performance belongs to another workout"
                )
        return row

    async def _ensure_set_ordinal_available(
        self,
        connection: Any,
        exercise_performance_id: int,
        ordinal: int,
        current_id: int | None,
    ) -> None:
        if ordinal < 0:
            raise _OperationRejected("ordinal_conflict", "Set ordinal cannot be negative")
        conflict_row = await self._fetch_optional(
            connection,
            """
            SELECT id FROM exec.set_performances
            WHERE exercise_unit_performance_id = %s AND ordinal = %s
              AND (%s::integer IS NULL OR id <> %s)
            """,
            (exercise_performance_id, ordinal, current_id, current_id),
        )
        if conflict_row is not None:
            raise _OperationRejected(
                "ordinal_conflict", "Another set performance uses this ordinal"
            )

    async def _lock_workout(self, connection: Any, workout_id: UUID) -> Row:
        workout = await self._fetch_optional(
            connection,
            """
            SELECT performance.*, performance.status::text AS performance_status,
                   prescription.workout_session_id AS session_id,
                   prescription.id AS workout_unit_prescription_id
            FROM exec.workout_unit_performances AS performance
            JOIN exec.workout_unit_prescriptions AS prescription
              ON prescription.id = performance.workout_unit_prescription_id
            WHERE performance.client_uuid = %s
            FOR UPDATE OF performance
            """,
            (workout_id,),
        )
        if workout is None:
            raise not_found("workout_not_found", "Workout was not found")
        return workout

    @staticmethod
    def _assert_writable_lease(workout: Row, lease_epoch: int, device_id: UUID) -> None:
        if workout["performance_status"] != "draft":
            raise conflict("workout_finalized", "Workout has already been finalized")
        if workout["lease_epoch"] != lease_epoch or workout["lease_device_id"] != device_id:
            raise conflict(
                "superseded",
                "The workout write lease belongs to another device or epoch",
                {
                    "epoch": workout["lease_epoch"],
                    "device_id": str(workout["lease_device_id"]),
                },
            )

    async def _prescription_version(self, connection: Any, session_id: int) -> str:
        rows = await self._fetch_all(
            connection,
            """
            SELECT workout.id AS workout_id, workout.updated_at AS workout_updated_at,
                   exercise.id AS exercise_id, exercise.updated_at AS exercise_updated_at,
                   exercise.ordinal AS exercise_ordinal,
                   exercise.generation_source::text AS generation_source,
                   exercise.prescribed_exercise_id, exercise.load_step_kg_snapshot,
                   exercise.prescription_comment,
                   sets.id AS set_id, sets.ordinal AS set_ordinal,
                   sets.prescribed_load_kg, sets.rep_min, sets.rep_max,
                   sets.target_rir::text AS target_rir, sets.prescription_comment AS set_comment
            FROM exec.workout_unit_prescriptions AS workout
            LEFT JOIN exec.exercise_unit_prescriptions AS exercise
              ON exercise.workout_unit_prescription_id = workout.id
            LEFT JOIN exec.set_prescriptions AS sets
              ON sets.exercise_unit_prescription_id = exercise.id
            WHERE workout.workout_session_id = %s
            ORDER BY exercise.ordinal, exercise.id, sets.ordinal, sets.id
            """,
            (session_id,),
        )
        if not rows:
            raise conflict("prescription_missing", "The workout prescription is not ready")
        canonical = json.dumps(rows, default=str, sort_keys=True, separators=(",", ":"))
        digest = hashlib.sha256(canonical.encode()).hexdigest()[:12]
        return f"rx-{session_id}-{digest}"

    @staticmethod
    def _validate_set_values(
        *,
        load_kg: Decimal | None,
        repetitions: int,
        rir: int | None,
        heart_rate_bpm: int | None,
    ) -> None:
        if load_kg is None:
            raise _OperationRejected(
                "load_required",
                "Performed sets require an explicit load; use 0 for no external load",
            )
        exponent = load_kg.as_tuple().exponent
        if load_kg < 0 or load_kg > 1000 or not isinstance(exponent, int) or exponent < -2:
            raise _OperationRejected(
                "load_out_of_range", "Load must be 0..1000 kg with at most 2 decimals"
            )
        if repetitions < 0 or repetitions > 100:
            raise _OperationRejected("reps_out_of_range", "Repetitions must be 0..100")
        if rir is not None and not 0 <= rir <= 10:
            raise _OperationRejected("rir_out_of_range", "RIR must be 0..10")
        if heart_rate_bpm is not None and not 25 <= heart_rate_bpm <= 250:
            raise _OperationRejected("heart_rate_out_of_range", "Heart rate must be 25..250 bpm")

    @staticmethod
    def _set_state(row: Row) -> dict[str, Any]:
        return {
            "prescribed_set_id": row["prescribed_set_id"],
            "ordinal": row["ordinal"],
            "status": row["status"],
            "load_kg": row["load_kg"],
            "repetitions": row["repetitions"],
            "rir": row["rir"],
            "comment": row["performance_comment"],
            "heart_rate_bpm": row["heart_rate_bpm"],
            "performed_at": row["performed_at"],
            "rev": row["rev"],
        }

    @staticmethod
    def _exercise_state(row: Row) -> dict[str, Any]:
        return {
            "exercise_performance_id": str(row["client_uuid"]),
            "exercise_prescription_id": row["prescribed_exercise_unit_id"],
            "performed_ordinal": row["performed_ordinal"],
            "mode": "added" if row["execution_mode"] == "additional" else row["execution_mode"],
            "actual_exercise_id": row["actual_exercise_id"],
            "comment": row["performance_comment"],
            "rev": row["rev"],
        }

    @classmethod
    def _states_equal(cls, left: dict[str, Any], right: dict[str, Any]) -> bool:
        return cls._canonical_state(left) == cls._canonical_state(right)

    @classmethod
    def _stale_and_different(
        cls,
        if_rev: int | None,
        current_rev: int,
        desired: dict[str, Any],
        current: dict[str, Any],
    ) -> bool:
        return (
            if_rev is not None and if_rev != current_rev and not cls._states_equal(desired, current)
        )

    @staticmethod
    def _canonical_state(value: dict[str, Any]) -> str:
        def normalize(item: Any) -> Any:
            if isinstance(item, Decimal):
                return float(item)
            if isinstance(item, datetime):
                return item.astimezone(timezone.utc).isoformat()
            if isinstance(item, dict):
                return {key: normalize(child) for key, child in item.items()}
            if isinstance(item, (list, tuple)):
                return [normalize(child) for child in item]
            return item

        cleaned = {key: normalize(item) for key, item in value.items() if key != "rev"}
        return json.dumps(cleaned, default=str, sort_keys=True, separators=(",", ":"))

    @staticmethod
    def _operation_result(
        operation: MobileOperation,
        *,
        status: str,
        entity_rev: int | None = None,
        server_state: dict[str, Any] | None = None,
        error: dict[str, str] | None = None,
    ) -> dict[str, Any]:
        result: dict[str, Any] = {
            "seq": operation.seq,
            "op_id": str(operation.op_id),
            "status": status,
        }
        if entity_rev is not None:
            result["entity_rev"] = entity_rev
        if server_state is not None:
            result["server_state"] = json.loads(json.dumps(server_state, default=str))
        if error is not None:
            result["error"] = error
        return result

    @staticmethod
    async def _execute(connection: Any, query: str, params: tuple[Any, ...] | None = None) -> None:
        async with connection.cursor() as cursor:
            await cursor.execute(query, params)

    @staticmethod
    async def _fetch_all(
        connection: Any, query: str, params: tuple[Any, ...] | None = None
    ) -> list[Row]:
        async with connection.cursor() as cursor:
            await cursor.execute(query, params)
            return list(await cursor.fetchall())

    @staticmethod
    async def _fetch_optional(
        connection: Any, query: str, params: tuple[Any, ...] | None = None
    ) -> Row | None:
        async with connection.cursor() as cursor:
            await cursor.execute(query, params)
            return cast(Row | None, await cursor.fetchone())

    @classmethod
    async def _fetch_one(
        cls, connection: Any, query: str, params: tuple[Any, ...] | None = None
    ) -> Row:
        row = await cls._fetch_optional(connection, query, params)
        if row is None:
            raise RuntimeError("Database statement returned no row")
        return row


class _OperationRejected(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        self.message = message
        super().__init__(message)
