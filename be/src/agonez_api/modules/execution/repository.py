from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime, time, timezone
from decimal import Decimal, InvalidOperation
from typing import Any, cast

from psycopg.types.json import Jsonb

from agonez_api.core.database import DatabasePool
from agonez_api.modules.execution.domain import (
    day_for,
    projection_end,
    resolve_next,
    version_of,
)
from agonez_api.modules.execution.errors import conflict, invalid, not_found
from agonez_api.modules.execution.schemas import (
    EventCreate,
    EventPatch,
    ExercisePrescriptionPut,
    MicrocyclePatch,
    PlanRunCreate,
    PlanRunPatch,
    SessionPatch,
    WorkoutPrescriptionPatch,
)

Row = dict[str, Any]


@dataclass(frozen=True)
class RevisionTree:
    revision: Row
    days: list[Row]
    workouts: list[Row]
    slots: list[Row]
    variants: list[Row]
    sets: list[Row]


@dataclass(frozen=True)
class RunBundle:
    run: Row
    microcycles: list[Row]
    workout_tracks: list[Row]
    exercise_tracks: list[Row]
    sessions: list[Row]
    workout_prescriptions: list[Row]
    exercise_prescriptions: list[Row]
    set_prescriptions: list[Row]
    workout_performances: list[Row]
    exercise_performances: list[Row]
    set_performances: list[Row]
    events: list[Row]
    plan_days: list[Row]
    plan_workouts: list[Row]
    plan_slots: list[Row]
    plan_variants: list[Row]
    plan_sets: list[Row]


class ExecutionRepository:
    """Bulk read-model loading and transactional Execution persistence."""

    def __init__(self, pool: DatabasePool) -> None:
        self._pool = pool

    async def reconcile(self, plan_run_id: int | None, as_of: date) -> None:
        """Apply date-owned lifecycle transitions without background infrastructure."""
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

    async def list_plan_runs(
        self,
        *,
        statuses: tuple[str, ...],
        limit: int,
        as_of: date,
    ) -> list[Row]:
        async with self._pool.connection() as connection:
            return await self._fetch_all(
                connection,
                """
                SELECT run.id AS plan_run_id, run.name, run.status::text AS status,
                       plan.id AS plan_id,
                       'P' || lpad(plan.id::text, 3, '0') AS plan_code,
                       plan.name AS plan_name, run.starts_on, run.ends_on,
                       run.microcycle_count, run.microcycle_duration_days,
                       current_mc.ordinal AS current_microcycle_ordinal
                FROM exec.plan_runs AS run
                JOIN plans.plan_revisions AS revision
                  ON revision.id = run.initial_plan_revision_id
                JOIN plans.workout_plans AS plan ON plan.id = revision.plan_id
                LEFT JOIN exec.microcycles AS current_mc
                  ON current_mc.plan_run_id = run.id
                 AND %s BETWEEN current_mc.starts_on AND current_mc.ends_on
                WHERE (cardinality(%s::text[]) = 0 OR run.status::text = ANY(%s::text[]))
                ORDER BY run.starts_on DESC, run.id DESC
                LIMIT %s
                """,
                (as_of, list(statuses), list(statuses), limit),
            )

    async def get_revision_tree(self, revision_id: int) -> RevisionTree:
        async with self._pool.connection() as connection:
            return await self._load_revision_tree(connection, revision_id)

    async def _load_revision_tree(self, connection: Any, revision_id: int) -> RevisionTree:
        revision = await self._fetch_optional(
            connection,
            """
            SELECT revision.id AS plan_revision_id, revision.plan_id,
                   revision.revision_no, lower(revision.status::text) AS status,
                   plan.name AS plan_name,
                   'P' || lpad(plan.id::text, 3, '0') AS plan_code
            FROM plans.plan_revisions AS revision
            JOIN plans.workout_plans AS plan ON plan.id = revision.plan_id
            WHERE revision.id = %s
            """,
            (revision_id,),
        )
        if revision is None:
            raise not_found("plan_revision_not_found", "Plan revision was not found")
        days = await self._fetch_all(
            connection,
            """
            SELECT id, revision_id, ordinal, weekday, name, description
            FROM plans.day_prescriptions
            WHERE revision_id = %s
            ORDER BY ordinal
            """,
            (revision_id,),
        )
        if not days:
            raise invalid("revision_has_no_days", "Plan revision has no days")
        workouts = await self._fetch_all(
            connection,
            """
            SELECT workout.id, workout.day_id, day.ordinal AS day_ordinal,
                   workout.name, workout.description, workout.warmup_notes,
                   workout.stretch_notes
            FROM plans.workout_unit_prescriptions AS workout
            JOIN plans.day_prescriptions AS day ON day.id = workout.day_id
            WHERE day.revision_id = %s
            ORDER BY day.ordinal
            """,
            (revision_id,),
        )
        slots = await self._fetch_all(
            connection,
            """
            SELECT slot.id, slot.workout_unit_id, slot.ordinal, slot.name,
                   slot.description, slot.goal, slot.role::text AS role,
                   slot.volume_axis
            FROM plans.exercise_slots AS slot
            JOIN plans.workout_unit_prescriptions AS workout
              ON workout.id = slot.workout_unit_id
            JOIN plans.day_prescriptions AS day ON day.id = workout.day_id
            WHERE day.revision_id = %s
            ORDER BY day.ordinal, slot.ordinal
            """,
            (revision_id,),
        )
        variants = await self._fetch_all(
            connection,
            """
            SELECT variant.id, variant.slot_id, variant.ordinal,
                   variant.variant_type::text AS variant_type,
                   variant.exercise_id, variant.progression_id,
                   variant.progression_model_slug,
                   exercise.slug AS exercise_slug, exercise.name AS exercise_name,
                   exercise.name_full AS exercise_name_full
            FROM plans.exercise_variants AS variant
            JOIN core.exercises AS exercise ON exercise.id = variant.exercise_id
            JOIN plans.exercise_slots AS slot ON slot.id = variant.slot_id
            JOIN plans.workout_unit_prescriptions AS workout
              ON workout.id = slot.workout_unit_id
            JOIN plans.day_prescriptions AS day ON day.id = workout.day_id
            WHERE day.revision_id = %s
            ORDER BY slot.ordinal, variant.ordinal
            """,
            (revision_id,),
        )
        sets = await self._fetch_all(
            connection,
            """
            SELECT item.id, item.exercise_variant_id, item.ordinal,
                   item.role::text AS role, item.rep_min, item.rep_max,
                   item.rir::text AS target_rir
            FROM plans.set_infra_prescriptions AS item
            JOIN plans.exercise_variants AS variant ON variant.id = item.exercise_variant_id
            JOIN plans.exercise_slots AS slot ON slot.id = variant.slot_id
            JOIN plans.workout_unit_prescriptions AS workout
              ON workout.id = slot.workout_unit_id
            JOIN plans.day_prescriptions AS day ON day.id = workout.day_id
            WHERE day.revision_id = %s
            ORDER BY item.exercise_variant_id, item.ordinal
            """,
            (revision_id,),
        )
        return RevisionTree(revision, days, workouts, slots, variants, sets)

    async def list_overlapping_runs(
        self,
        *,
        starts_on: date,
        ends_on: date,
    ) -> list[Row]:
        async with self._pool.connection() as connection:
            return await self._fetch_all(
                connection,
                """
                SELECT id AS plan_run_id, name, starts_on, ends_on
                FROM exec.plan_runs
                WHERE status <> 'cancelled'
                  AND daterange(starts_on, ends_on, '[]') && daterange(%s, %s, '[]')
                ORDER BY starts_on, id
                """,
                (starts_on, ends_on),
            )

    async def create_plan_run(
        self,
        payload: PlanRunCreate,
        *,
        as_of: date,
    ) -> int:
        if not 1 <= payload.microcycle_count <= 52:
            raise invalid(
                "invalid_microcycle_count",
                "microcycle_count must be between 1 and 52",
            )
        async with self._pool.connection() as connection:
            async with connection.transaction():
                tree = await self._load_revision_tree(connection, payload.plan_revision_id)
                duration = len(tree.days)
                run = await self._fetch_one(
                    connection,
                    """
                    INSERT INTO exec.plan_runs (
                        name, initial_plan_revision_id, starts_on,
                        microcycle_count, microcycle_duration_days, status
                    )
                    VALUES (%s, %s, %s, %s, %s, %s)
                    RETURNING id
                    """,
                    (
                        payload.name.strip(),
                        payload.plan_revision_id,
                        payload.starts_on,
                        payload.microcycle_count,
                        duration,
                        "scheduled" if payload.starts_on > as_of else "active",
                    ),
                )
                run_id = cast(int, run["id"])
                microcycle_ids: dict[int, int] = {}
                for ordinal in range(1, payload.microcycle_count + 1):
                    starts = day_for(payload.starts_on, ordinal, duration, 0)
                    inserted = await self._fetch_one(
                        connection,
                        """
                        INSERT INTO exec.microcycles (
                            plan_run_id, ordinal, starts_on, ends_on,
                            plan_revision_id, classification
                        )
                        VALUES (%s, %s, %s, %s, %s, 'normal')
                        RETURNING id
                        """,
                        (
                            run_id,
                            ordinal,
                            starts,
                            starts + (projection_end(starts, 1, duration) - starts),
                            payload.plan_revision_id,
                        ),
                    )
                    microcycle_ids[ordinal] = cast(int, inserted["id"])

                slots_by_workout: dict[int, list[Row]] = {}
                for slot in tree.slots:
                    slots_by_workout.setdefault(cast(int, slot["workout_unit_id"]), []).append(slot)
                variants_by_slot = {
                    cast(int, item["slot_id"]): item
                    for item in tree.variants
                    if item["variant_type"] == "DEFAULT"
                }
                workout_track_ids: dict[int, int] = {}
                exercise_track_ids: dict[tuple[int, int], int] = {}
                for workout in tree.workouts:
                    track = await self._fetch_one(
                        connection,
                        """
                        INSERT INTO exec.workout_unit_tracks (
                            plan_run_id, logical_key, name, description
                        ) VALUES (%s, %s, %s, %s)
                        RETURNING id
                        """,
                        (
                            run_id,
                            f"day:{workout['day_ordinal']}",
                            workout["name"],
                            workout["description"],
                        ),
                    )
                    workout_id = cast(int, workout["id"])
                    workout_track_id = cast(int, track["id"])
                    workout_track_ids[workout_id] = workout_track_id
                    for slot in slots_by_workout.get(workout_id, []):
                        variant = variants_by_slot.get(cast(int, slot["id"]))
                        if variant is None:
                            continue
                        exercise_track = await self._fetch_one(
                            connection,
                            """
                            INSERT INTO exec.exercise_unit_tracks (
                                plan_run_id, workout_unit_track_id, logical_key,
                                name, source_progression_id
                            ) VALUES (%s, %s, %s, %s, %s)
                            RETURNING id
                            """,
                            (
                                run_id,
                                workout_track_id,
                                f"slot:{slot['ordinal']}",
                                slot["name"] or variant["exercise_name"],
                                variant["progression_id"],
                            ),
                        )
                        exercise_track_ids[(workout_id, cast(int, slot["id"]))] = cast(
                            int, exercise_track["id"]
                        )

                day_by_id = {cast(int, day["id"]): day for day in tree.days}
                for ordinal in range(1, payload.microcycle_count + 1):
                    for workout in tree.workouts:
                        day = day_by_id[cast(int, workout["day_id"])]
                        await self._execute(
                            connection,
                            """
                            INSERT INTO exec.workout_sessions (
                                plan_run_id, microcycle_id, workout_unit_track_id,
                                source_plan_day_id, source_plan_workout_unit_id,
                                scheduled_date, status
                            ) VALUES (%s, %s, %s, %s, %s, %s, 'scheduled')
                            """,
                            (
                                run_id,
                                microcycle_ids[ordinal],
                                workout_track_ids[cast(int, workout["id"])],
                                day["id"],
                                workout["id"],
                                day_for(
                                    payload.starts_on,
                                    ordinal,
                                    duration,
                                    cast(int, day["ordinal"]),
                                ),
                            ),
                        )
                await self._execute(
                    connection,
                    """
                    INSERT INTO exec.plan_run_events (
                        plan_run_id, microcycle_id, event_type, occurred_at,
                        title, details, metadata
                    )
                    VALUES (%s, %s, 'observation', %s, 'Run started', NULL, %s)
                    """,
                    (
                        run_id,
                        microcycle_ids[1],
                        datetime.combine(payload.starts_on, time.min, tzinfo=timezone.utc),
                        Jsonb({"kind": "run_created", "_source": "system"}),
                    ),
                )
                return run_id

    async def get_bundle(self, plan_run_id: int) -> RunBundle:
        async with self._pool.connection() as connection:
            return await self._load_bundle(connection, plan_run_id)

    async def _load_bundle(self, connection: Any, plan_run_id: int) -> RunBundle:
        run = await self._fetch_optional(
            connection,
            """
            SELECT run.*, run.status::text AS status,
                   plan.id AS plan_id, plan.name AS plan_name,
                   'P' || lpad(plan.id::text, 3, '0') AS plan_code,
                   revision.revision_no AS initial_revision_no,
                   lower(revision.status::text) AS initial_revision_status
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
        microcycles = await self._fetch_all(
            connection,
            """
            SELECT mc.*, mc.classification::text AS classification,
                   revision.revision_no AS plan_revision_no,
                   lower(revision.status::text) AS plan_revision_status
            FROM exec.microcycles AS mc
            JOIN plans.plan_revisions AS revision ON revision.id = mc.plan_revision_id
            WHERE mc.plan_run_id = %s
            ORDER BY mc.ordinal
            """,
            (plan_run_id,),
        )
        workout_tracks = await self._fetch_all(
            connection,
            """SELECT * FROM exec.workout_unit_tracks
               WHERE plan_run_id = %s ORDER BY id""",
            (plan_run_id,),
        )
        exercise_tracks = await self._fetch_all(
            connection,
            """SELECT * FROM exec.exercise_unit_tracks
               WHERE plan_run_id = %s ORDER BY workout_unit_track_id, id""",
            (plan_run_id,),
        )
        sessions = await self._fetch_all(
            connection,
            """
            SELECT session.*, session.status::text AS status,
                   session.completion_mode::text AS completion_mode,
                   mc.ordinal AS microcycle_ordinal,
                   mc.plan_revision_id, revision.revision_no AS plan_revision_no,
                   track.name AS workout_name, track.logical_key AS workout_logical_key,
                   source_day.ordinal AS day_ordinal,
                   fallback.name AS fallback_workout_name
            FROM exec.workout_sessions AS session
            JOIN exec.microcycles AS mc ON mc.id = session.microcycle_id
            JOIN plans.plan_revisions AS revision ON revision.id = mc.plan_revision_id
            JOIN exec.workout_unit_tracks AS track
              ON track.id = session.workout_unit_track_id
            JOIN plans.day_prescriptions AS source_day
              ON source_day.id = session.source_plan_day_id
            LEFT JOIN plans.workout_unit_prescriptions AS fallback
              ON fallback.id = session.fallback_source_plan_workout_unit_id
            WHERE session.plan_run_id = %s
            ORDER BY session.scheduled_date, session.id
            """,
            (plan_run_id,),
        )
        workout_prescriptions = await self._fetch_all(
            connection,
            """
            SELECT prescription.*, session.plan_run_id,
                   session.id AS workout_session_id
            FROM exec.workout_unit_prescriptions AS prescription
            JOIN exec.workout_sessions AS session
              ON session.id = prescription.workout_session_id
            WHERE session.plan_run_id = %s
            ORDER BY session.scheduled_date, prescription.id
            """,
            (plan_run_id,),
        )
        exercise_prescriptions = await self._fetch_all(
            connection,
            """
            SELECT exercise.*, workout.workout_session_id,
                   prescribed.slug AS prescribed_exercise_slug,
                   prescribed.name AS prescribed_exercise_name,
                   prescribed.name_full AS prescribed_exercise_name_full
            FROM exec.exercise_unit_prescriptions AS exercise
            JOIN exec.workout_unit_prescriptions AS workout
              ON workout.id = exercise.workout_unit_prescription_id
            JOIN exec.workout_sessions AS session ON session.id = workout.workout_session_id
            JOIN core.exercises AS prescribed ON prescribed.id = exercise.prescribed_exercise_id
            WHERE session.plan_run_id = %s
            ORDER BY session.scheduled_date, exercise.ordinal, exercise.id
            """,
            (plan_run_id,),
        )
        set_prescriptions = await self._fetch_all(
            connection,
            """
            SELECT item.*, item.set_role_snapshot::text AS set_role_snapshot,
                   item.target_rir::text AS target_rir
            FROM exec.set_prescriptions AS item
            JOIN exec.exercise_unit_prescriptions AS exercise
              ON exercise.id = item.exercise_unit_prescription_id
            JOIN exec.workout_unit_prescriptions AS workout
              ON workout.id = exercise.workout_unit_prescription_id
            JOIN exec.workout_sessions AS session ON session.id = workout.workout_session_id
            WHERE session.plan_run_id = %s
            ORDER BY item.exercise_unit_prescription_id, item.ordinal
            """,
            (plan_run_id,),
        )
        workout_performances = await self._fetch_all(
            connection,
            """
            SELECT performance.*, performance.status::text AS status,
                   workout.workout_session_id
            FROM exec.workout_unit_performances AS performance
            JOIN exec.workout_unit_prescriptions AS workout
              ON workout.id = performance.workout_unit_prescription_id
            JOIN exec.workout_sessions AS session ON session.id = workout.workout_session_id
            WHERE session.plan_run_id = %s
            ORDER BY performance.id
            """,
            (plan_run_id,),
        )
        exercise_performances = await self._fetch_all(
            connection,
            """
            SELECT exercise.*, exercise.execution_mode::text AS execution_mode,
                   workout.status::text AS workout_performance_status,
                   workout.completed_at AS workout_completed_at,
                   prescription.workout_session_id,
                   session.scheduled_date, mc.ordinal AS microcycle_ordinal,
                   actual.slug AS actual_exercise_slug,
                   actual.name AS actual_exercise_name,
                   actual.name_full AS actual_exercise_name_full
            FROM exec.exercise_unit_performances AS exercise
            JOIN exec.workout_unit_performances AS workout
              ON workout.id = exercise.workout_unit_performance_id
            JOIN exec.workout_unit_prescriptions AS prescription
              ON prescription.id = workout.workout_unit_prescription_id
            JOIN exec.workout_sessions AS session
              ON session.id = prescription.workout_session_id
            JOIN exec.microcycles AS mc ON mc.id = session.microcycle_id
            LEFT JOIN core.exercises AS actual ON actual.id = exercise.actual_exercise_id
            WHERE session.plan_run_id = %s
            ORDER BY session.scheduled_date, exercise.ordinal, exercise.id
            """,
            (plan_run_id,),
        )
        set_performances = await self._fetch_all(
            connection,
            """
            SELECT item.*, item.status::text AS status
            FROM exec.set_performances AS item
            JOIN exec.exercise_unit_performances AS exercise
              ON exercise.id = item.exercise_unit_performance_id
            JOIN exec.workout_unit_performances AS workout
              ON workout.id = exercise.workout_unit_performance_id
            JOIN exec.workout_unit_prescriptions AS prescription
              ON prescription.id = workout.workout_unit_prescription_id
            JOIN exec.workout_sessions AS session
              ON session.id = prescription.workout_session_id
            WHERE session.plan_run_id = %s
            ORDER BY item.exercise_unit_performance_id, item.ordinal
            """,
            (plan_run_id,),
        )
        events = await self._fetch_all(
            connection,
            """
            SELECT event.*, event.event_type::text AS event_type,
                   mc.ordinal AS microcycle_ordinal,
                   from_revision.revision_no AS from_revision_no,
                   to_revision.revision_no AS to_revision_no,
                   track.name AS exercise_trace_name,
                   session_track.name AS event_workout_name
            FROM exec.plan_run_events AS event
            LEFT JOIN exec.microcycles AS mc ON mc.id = event.microcycle_id
            LEFT JOIN plans.plan_revisions AS from_revision
              ON from_revision.id = event.from_plan_revision_id
            LEFT JOIN plans.plan_revisions AS to_revision
              ON to_revision.id = event.to_plan_revision_id
            LEFT JOIN exec.exercise_unit_tracks AS track
              ON track.id = event.exercise_unit_track_id
            LEFT JOIN exec.workout_sessions AS event_session
              ON event_session.id = event.workout_session_id
            LEFT JOIN exec.workout_unit_tracks AS session_track
              ON session_track.id = event_session.workout_unit_track_id
            WHERE event.plan_run_id = %s
            ORDER BY event.occurred_at DESC, event.id DESC
            """,
            (plan_run_id,),
        )
        revision_ids = [cast(int, item["plan_revision_id"]) for item in microcycles]
        plan_days, plan_workouts, plan_slots, plan_variants, plan_sets = (
            await self._load_plan_structures(connection, revision_ids)
        )
        return RunBundle(
            run,
            microcycles,
            workout_tracks,
            exercise_tracks,
            sessions,
            workout_prescriptions,
            exercise_prescriptions,
            set_prescriptions,
            workout_performances,
            exercise_performances,
            set_performances,
            events,
            plan_days,
            plan_workouts,
            plan_slots,
            plan_variants,
            plan_sets,
        )

    async def _load_plan_structures(
        self,
        connection: Any,
        revision_ids: list[int],
    ) -> tuple[list[Row], list[Row], list[Row], list[Row], list[Row]]:
        ids = list(dict.fromkeys(revision_ids))
        days = await self._fetch_all(
            connection,
            """
            SELECT day.*, revision.revision_no
            FROM plans.day_prescriptions AS day
            JOIN plans.plan_revisions AS revision ON revision.id = day.revision_id
            WHERE day.revision_id = ANY(%s)
            ORDER BY revision.revision_no, day.ordinal
            """,
            (ids,),
        )
        workouts = await self._fetch_all(
            connection,
            """
            SELECT workout.*, day.revision_id, day.ordinal AS day_ordinal
            FROM plans.workout_unit_prescriptions AS workout
            JOIN plans.day_prescriptions AS day ON day.id = workout.day_id
            WHERE day.revision_id = ANY(%s)
            ORDER BY day.revision_id, day.ordinal
            """,
            (ids,),
        )
        slots = await self._fetch_all(
            connection,
            """
            SELECT slot.*, slot.role::text AS role,
                   day.revision_id, day.ordinal AS day_ordinal
            FROM plans.exercise_slots AS slot
            JOIN plans.workout_unit_prescriptions AS workout
              ON workout.id = slot.workout_unit_id
            JOIN plans.day_prescriptions AS day ON day.id = workout.day_id
            WHERE day.revision_id = ANY(%s)
            ORDER BY day.revision_id, day.ordinal, slot.ordinal
            """,
            (ids,),
        )
        variants = await self._fetch_all(
            connection,
            """
            SELECT variant.*, variant.variant_type::text AS variant_type,
                   day.revision_id, day.ordinal AS day_ordinal,
                   exercise.slug AS exercise_slug, exercise.name AS exercise_name,
                   exercise.name_full AS exercise_name_full
            FROM plans.exercise_variants AS variant
            JOIN core.exercises AS exercise ON exercise.id = variant.exercise_id
            JOIN plans.exercise_slots AS slot ON slot.id = variant.slot_id
            JOIN plans.workout_unit_prescriptions AS workout
              ON workout.id = slot.workout_unit_id
            JOIN plans.day_prescriptions AS day ON day.id = workout.day_id
            WHERE day.revision_id = ANY(%s)
            ORDER BY day.revision_id, day.ordinal, slot.ordinal, variant.ordinal
            """,
            (ids,),
        )
        sets = await self._fetch_all(
            connection,
            """
            SELECT item.*, item.role::text AS role, item.rir::text AS target_rir,
                   day.revision_id, day.ordinal AS day_ordinal
            FROM plans.set_infra_prescriptions AS item
            JOIN plans.exercise_variants AS variant ON variant.id = item.exercise_variant_id
            JOIN plans.exercise_slots AS slot ON slot.id = variant.slot_id
            JOIN plans.workout_unit_prescriptions AS workout
              ON workout.id = slot.workout_unit_id
            JOIN plans.day_prescriptions AS day ON day.id = workout.day_id
            WHERE day.revision_id = ANY(%s)
            ORDER BY day.revision_id, day.ordinal, slot.ordinal, item.ordinal
            """,
            (ids,),
        )
        return days, workouts, slots, variants, sets

    async def update_plan_run(
        self,
        plan_run_id: int,
        payload: PlanRunPatch,
    ) -> None:
        async with self._pool.connection() as connection:
            async with connection.transaction():
                current = await self._fetch_optional(
                    connection,
                    "SELECT * FROM exec.plan_runs WHERE id = %s FOR UPDATE",
                    (plan_run_id,),
                )
                if current is None:
                    raise not_found("plan_run_not_found", "Plan run was not found")
                if version_of(current["updated_at"]) != payload.expected_version:
                    raise conflict(
                        "version_conflict",
                        "Plan run changed after it was loaded",
                        {"current": self._public_run_version(current)},
                    )
                status = str(current["status"])
                requested = payload.status.value if payload.status else status
                allowed = {
                    ("scheduled", "active"),
                    ("scheduled", "cancelled"),
                    ("active", "cancelled"),
                    ("active", "completed"),
                }
                if requested != status and (status, requested) not in allowed:
                    raise conflict(
                        "invalid_status_transition",
                        f"Cannot change plan run from {status} to {requested}",
                    )
                await self._execute(
                    connection,
                    """
                    UPDATE exec.plan_runs
                    SET name = COALESCE(%s, name), status = %s,
                        updated_at = clock_timestamp()
                    WHERE id = %s
                    """,
                    (payload.name.strip() if payload.name else None, requested, plan_run_id),
                )

    async def save_exercise_prescription(
        self,
        *,
        plan_run_id: int,
        session_id: int,
        exercise_track_id: int,
        payload: ExercisePrescriptionPut,
    ) -> None:
        async with self._pool.connection() as connection:
            async with connection.transaction():
                locked_session = await self._fetch_optional(
                    connection,
                    """
                    SELECT * FROM exec.workout_sessions
                    WHERE id = %s AND plan_run_id = %s
                    FOR UPDATE
                    """,
                    (session_id, plan_run_id),
                )
                if locked_session is None:
                    raise not_found("session_not_found", "Workout session was not found")
                if str(locked_session["status"]) != "scheduled":
                    raise conflict("session_locked", "Session prescription is historical")

                bundle = await self._load_bundle(connection, plan_run_id)
                exercise_track = next(
                    (item for item in bundle.exercise_tracks if item["id"] == exercise_track_id),
                    None,
                )
                if exercise_track is None:
                    raise not_found("exercise_trace_not_found", "Exercise trace was not found")
                resolution = resolve_next(
                    run=bundle.run,
                    sessions=bundle.sessions,
                    prescriptions=bundle.exercise_prescriptions,
                    performances=bundle.exercise_performances,
                    workout_track_id=cast(int, exercise_track["workout_unit_track_id"]),
                    exercise_track_id=exercise_track_id,
                )
                if resolution.state.value == "blocked":
                    raise conflict(
                        "prescription_blocked",
                        "The next prescription is blocked by an earlier exposure",
                        {
                            "blocked_reason": (
                                resolution.blocked_reason.value
                                if resolution.blocked_reason
                                else None
                            )
                        },
                    )
                if resolution.target is None or resolution.target["id"] != session_id:
                    raise conflict(
                        "not_next_session",
                        "The selected session is not the next valid target",
                        {
                            "current_target_session_id": (
                                resolution.target["id"] if resolution.target else None
                            )
                        },
                    )
                current_basis_id = (
                    resolution.basis_performance["id"]
                    if resolution.basis_performance is not None
                    else None
                )
                if payload.based_on_exercise_performance_id != current_basis_id:
                    raise conflict(
                        "stale_basis",
                        "A newer finalized exercise performance is available",
                        {"current_basis": self._basis_detail(resolution.basis_performance)},
                    )

                slot_ordinal = self._logical_ordinal(cast(str, exercise_track["logical_key"]))
                target_slot = next(
                    (
                        item
                        for item in bundle.plan_slots
                        if item["workout_unit_id"]
                        == resolution.target["source_plan_workout_unit_id"]
                        and item["ordinal"] == slot_ordinal
                    ),
                    None,
                )
                if target_slot is None:
                    raise not_found(
                        "exercise_trace_not_found",
                        "Exercise trace has no slot in the target revision",
                    )
                target_variant = next(
                    (
                        item
                        for item in bundle.plan_variants
                        if item["slot_id"] == target_slot["id"]
                        and item["variant_type"] == "DEFAULT"
                    ),
                    None,
                )
                if target_variant is None:
                    raise invalid("set_count_mismatch", "Target slot has no default variant")
                target_sets = sorted(
                    (
                        item
                        for item in bundle.plan_sets
                        if item["exercise_variant_id"] == target_variant["id"]
                    ),
                    key=lambda item: item["ordinal"],
                )
                requested_ordinals = [item.ordinal for item in payload.sets]
                if requested_ordinals != list(range(len(target_sets))):
                    raise invalid(
                        "set_count_mismatch",
                        "Set ordinals must exactly match the target plan sets",
                        {
                            "expected_count": len(target_sets),
                            "submitted_ordinals": requested_ordinals,
                        },
                    )
                invalid_load_ordinals = self._invalid_load_ordinals(payload)
                if invalid_load_ordinals:
                    raise invalid(
                        "invalid_load",
                        "Loads must be between 0 and 1000 kg with at most two decimals",
                        {"ordinals": invalid_load_ordinals},
                    )

                workout_source = next(
                    item
                    for item in bundle.plan_workouts
                    if item["id"] == resolution.target["source_plan_workout_unit_id"]
                )
                workout_prescription = next(
                    (
                        item
                        for item in bundle.workout_prescriptions
                        if item["workout_session_id"] == session_id
                    ),
                    None,
                )
                if workout_prescription is None:
                    workout_prescription = await self._fetch_one(
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
                            resolution.target["plan_revision_id"],
                            workout_source["id"],
                            workout_source["name"],
                            workout_source["description"],
                            workout_source["warmup_notes"],
                            workout_source["stretch_notes"],
                        ),
                    )
                current = next(
                    (
                        item
                        for item in bundle.exercise_prescriptions
                        if item["workout_session_id"] == session_id
                        and item["exercise_unit_track_id"] == exercise_track_id
                    ),
                    None,
                )
                if current is None:
                    if payload.expected_version is not None:
                        raise conflict(
                            "version_conflict",
                            "Prescription no longer matches the loaded version",
                            {"current": None},
                        )
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
                            prescription_comment, previous_exercise_performance_id
                        ) VALUES (
                            %s, %s, %s, %s, %s, %s, %s, %s,
                            %s, %s, %s, %s, %s, %s
                        ) RETURNING id
                        """,
                        (
                            workout_prescription["id"],
                            exercise_track_id,
                            target_slot["ordinal"],
                            target_slot["id"],
                            target_variant["id"],
                            target_variant["progression_id"],
                            target_variant["exercise_id"],
                            target_slot["name"],
                            target_slot["description"],
                            target_slot["goal"],
                            target_slot["role"],
                            target_variant["progression_model_slug"],
                            payload.prescription_comment,
                            current_basis_id,
                        ),
                    )
                    exercise_prescription_id = cast(int, inserted["id"])
                else:
                    current_version = version_of(current["updated_at"])
                    if payload.expected_version != current_version:
                        raise conflict(
                            "version_conflict",
                            "Prescription changed after it was loaded",
                            {"current": self._public_prescription_version(current)},
                        )
                    exercise_prescription_id = cast(int, current["id"])
                    await self._execute(
                        connection,
                        """
                        UPDATE exec.exercise_unit_prescriptions
                        SET source_plan_exercise_slot_id = %s,
                            source_plan_exercise_variant_id = %s,
                            source_progression_id = %s,
                            prescribed_exercise_id = %s,
                            slot_name_snapshot = %s,
                            plan_description_snapshot = %s,
                            plan_goal_snapshot = %s,
                            slot_role_snapshot = %s,
                            progression_model_slug_snapshot = %s,
                            prescription_comment = %s,
                            previous_exercise_performance_id = %s,
                            updated_at = clock_timestamp()
                        WHERE id = %s
                        """,
                        (
                            target_slot["id"],
                            target_variant["id"],
                            target_variant["progression_id"],
                            target_variant["exercise_id"],
                            target_slot["name"],
                            target_slot["description"],
                            target_slot["goal"],
                            target_slot["role"],
                            target_variant["progression_model_slug"],
                            payload.prescription_comment,
                            current_basis_id,
                            exercise_prescription_id,
                        ),
                    )
                    await self._execute(
                        connection,
                        """DELETE FROM exec.set_prescriptions
                           WHERE exercise_unit_prescription_id = %s""",
                        (exercise_prescription_id,),
                    )
                for source, submitted in zip(target_sets, payload.sets, strict=True):
                    await self._execute(
                        connection,
                        """
                        INSERT INTO exec.set_prescriptions (
                            exercise_unit_prescription_id, ordinal,
                            source_plan_set_infra_id, set_role_snapshot,
                            rep_min, rep_max, target_rir,
                            prescribed_load_kg, prescription_comment
                        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                        """,
                        (
                            exercise_prescription_id,
                            source["ordinal"],
                            source["id"],
                            source["role"],
                            source["rep_min"],
                            source["rep_max"],
                            source["target_rir"],
                            submitted.load_kg,
                            submitted.comment,
                        ),
                    )

    async def delete_exercise_prescription(
        self,
        *,
        plan_run_id: int,
        session_id: int,
        exercise_track_id: int,
    ) -> None:
        async with self._pool.connection() as connection:
            async with connection.transaction():
                session = await self._fetch_optional(
                    connection,
                    """SELECT * FROM exec.workout_sessions
                       WHERE id = %s AND plan_run_id = %s FOR UPDATE""",
                    (session_id, plan_run_id),
                )
                if session is None:
                    raise not_found("session_not_found", "Workout session was not found")
                if str(session["status"]) != "scheduled":
                    raise conflict("session_locked", "Session prescription is historical")
                row = await self._fetch_optional(
                    connection,
                    """
                    DELETE FROM exec.exercise_unit_prescriptions AS exercise
                    USING exec.workout_unit_prescriptions AS workout
                    WHERE exercise.workout_unit_prescription_id = workout.id
                      AND workout.workout_session_id = %s
                      AND exercise.exercise_unit_track_id = %s
                    RETURNING workout.id AS workout_prescription_id
                    """,
                    (session_id, exercise_track_id),
                )
                if row is not None:
                    await self._execute(
                        connection,
                        """
                        DELETE FROM exec.workout_unit_prescriptions AS workout
                        WHERE workout.id = %s
                          AND NOT EXISTS (
                              SELECT 1 FROM exec.exercise_unit_prescriptions AS exercise
                              WHERE exercise.workout_unit_prescription_id = workout.id
                          )
                        """,
                        (row["workout_prescription_id"],),
                    )

    async def update_workout_prescription_comment(
        self,
        *,
        plan_run_id: int,
        session_id: int,
        payload: WorkoutPrescriptionPatch,
    ) -> None:
        async with self._pool.connection() as connection:
            async with connection.transaction():
                session = await self._fetch_optional(
                    connection,
                    """
                    SELECT id, status::text AS session_status
                    FROM exec.workout_sessions AS session
                    WHERE session.id = %s AND session.plan_run_id = %s
                    FOR UPDATE
                    """,
                    (session_id, plan_run_id),
                )
                if session is None:
                    raise not_found("session_not_found", "Workout session was not found")
                if session["session_status"] != "scheduled":
                    raise conflict("session_locked", "Session prescription is historical")
                row = await self._fetch_optional(
                    connection,
                    """
                    SELECT * FROM exec.workout_unit_prescriptions
                    WHERE workout_session_id = %s
                    FOR UPDATE
                    """,
                    (session_id,),
                )
                if row is None:
                    raise not_found("prescription_not_found", "Workout prescription was not found")
                if version_of(row["updated_at"]) != payload.expected_version:
                    raise conflict(
                        "version_conflict",
                        "Workout prescription changed after it was loaded",
                        {"current": self._public_workout_prescription_version(row)},
                    )
                await self._execute(
                    connection,
                    """
                    UPDATE exec.workout_unit_prescriptions
                    SET prescription_comment = %s, updated_at = clock_timestamp()
                    WHERE id = %s
                    """,
                    (payload.prescription_comment, row["id"]),
                )

    async def update_microcycle(
        self,
        *,
        plan_run_id: int,
        ordinal: int,
        payload: MicrocyclePatch,
        as_of: date,
    ) -> None:
        async with self._pool.connection() as connection:
            async with connection.transaction():
                current = await self._fetch_optional(
                    connection,
                    """
                    SELECT * FROM exec.microcycles
                    WHERE plan_run_id = %s AND ordinal = %s
                    FOR UPDATE
                    """,
                    (plan_run_id, ordinal),
                )
                if current is None:
                    raise not_found("microcycle_not_found", "Microcycle was not found")
                if version_of(current["updated_at"]) != payload.expected_version:
                    raise conflict(
                        "version_conflict",
                        "Microcycle changed after it was loaded",
                        {"current": self._public_microcycle_version(current)},
                    )
                current_classification = str(current["classification"])
                requested = (
                    payload.classification.value
                    if payload.classification is not None
                    else current_classification
                )
                if requested != current_classification:
                    started = await self._fetch_optional(
                        connection,
                        """
                        SELECT id
                        FROM exec.workout_sessions
                        WHERE microcycle_id = %s
                          AND (started_at IS NOT NULL OR status IN ('in_progress', 'completed'))
                        LIMIT 1
                        """,
                        (current["id"],),
                    )
                    is_future = current["starts_on"] > as_of
                    is_current_unstarted = (
                        current["starts_on"] <= as_of <= current["ends_on"]
                        and started is None
                    )
                    if not (is_future or is_current_unstarted):
                        raise conflict(
                            "microcycle_started",
                            "Classification cannot change after a microcycle has started",
                        )
                notes = payload.notes if "notes" in payload.model_fields_set else current["notes"]
                await self._execute(
                    connection,
                    """
                    UPDATE exec.microcycles
                    SET notes = %s, classification = %s, updated_at = clock_timestamp()
                    WHERE id = %s
                    """,
                    (notes, requested, current["id"]),
                )
                if requested in {"deload", "reload"} and requested != current_classification:
                    event_type = f"{requested}_started"
                    await self._execute(
                        connection,
                        """
                        INSERT INTO exec.plan_run_events (
                            plan_run_id, microcycle_id, event_type, occurred_at,
                            title, details, metadata
                        ) VALUES (%s, %s, %s, %s, %s, NULL, %s)
                        """,
                        (
                            plan_run_id,
                            current["id"],
                            event_type,
                            datetime.combine(
                                current["starts_on"], time.min, tzinfo=timezone.utc
                            ),
                            "Deload started" if requested == "deload" else "Reload started",
                            Jsonb({"kind": "classification_change", "_source": "system"}),
                        ),
                    )
                elif (
                    requested == "normal"
                    and requested != current_classification
                    and current["starts_on"] > as_of
                ):
                    await self._execute(
                        connection,
                        """
                        DELETE FROM exec.plan_run_events
                        WHERE plan_run_id = %s AND microcycle_id = %s
                          AND event_type IN ('deload_started', 'reload_started')
                          AND metadata ->> 'kind' = 'classification_change'
                          AND metadata ->> '_source' = 'system'
                        """,
                        (plan_run_id, current["id"]),
                    )

    async def update_session_status(
        self,
        *,
        plan_run_id: int,
        session_id: int,
        payload: SessionPatch,
        as_of: date,
    ) -> None:
        async with self._pool.connection() as connection:
            async with connection.transaction():
                current = await self._fetch_optional(
                    connection,
                    """
                    SELECT session.*, mc.id AS microcycle_id
                    FROM exec.workout_sessions AS session
                    JOIN exec.microcycles AS mc ON mc.id = session.microcycle_id
                    WHERE session.id = %s AND session.plan_run_id = %s
                    FOR UPDATE OF session
                    """,
                    (session_id, plan_run_id),
                )
                if current is None:
                    raise not_found("session_not_found", "Workout session was not found")
                old = str(current["status"])
                new = payload.status.value
                allowed = {
                    ("scheduled", "cancelled"),
                    ("scheduled", "missed"),
                    ("missed", "cancelled"),
                    ("cancelled", "scheduled"),
                }
                if old == new:
                    return
                if (old, new) not in allowed:
                    raise conflict(
                        "invalid_status_transition",
                        f"Cannot change session from {old} to {new}",
                    )
                if old == "scheduled" and new == "missed" and current["scheduled_date"] >= as_of:
                    raise conflict(
                        "invalid_status_transition",
                        "A session can be missed only after its scheduled date",
                    )
                if old == "cancelled" and new == "scheduled" and current["scheduled_date"] < as_of:
                    raise conflict(
                        "invalid_status_transition",
                        "A past cancelled session cannot be rescheduled",
                    )
                has_performance = await self._fetch_optional(
                    connection,
                    """
                    SELECT performance.id
                    FROM exec.workout_unit_prescriptions AS prescription
                    JOIN exec.workout_unit_performances AS performance
                      ON performance.workout_unit_prescription_id = prescription.id
                    WHERE prescription.workout_session_id = %s
                    """,
                    (session_id,),
                )
                if has_performance is not None:
                    raise conflict(
                        "session_has_performance",
                        "A session with a performance cannot be reclassified",
                    )
                await self._execute(
                    connection,
                    """
                    UPDATE exec.workout_sessions
                    SET status = %s, notes = COALESCE(%s, notes),
                        updated_at = clock_timestamp()
                    WHERE id = %s
                    """,
                    (new, payload.reason, session_id),
                )
                if payload.log_event:
                    requested_type = payload.details.get("event_type")
                    event_type = (
                        "training_break"
                        if new == "missed"
                        else requested_type
                        if requested_type in {"vacation", "observation"}
                        else "observation"
                    )
                    await self._execute(
                        connection,
                        """
                        INSERT INTO exec.plan_run_events (
                            plan_run_id, microcycle_id, workout_session_id,
                            event_type, occurred_at, title, details, metadata
                        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                        """,
                        (
                            plan_run_id,
                            current["microcycle_id"],
                            session_id,
                            event_type,
                            datetime.combine(
                                current["scheduled_date"], time.min, tzinfo=timezone.utc
                            ),
                            self._event_title(event_type),
                            payload.reason,
                            Jsonb({"_source": "user"}),
                        ),
                    )

    async def create_event(self, plan_run_id: int, payload: EventCreate) -> int:
        async with self._pool.connection() as connection:
            async with connection.transaction():
                run = await self._fetch_optional(
                    connection,
                    "SELECT * FROM exec.plan_runs WHERE id = %s",
                    (plan_run_id,),
                )
                if run is None:
                    raise not_found("plan_run_not_found", "Plan run was not found")
                event_type = payload.event_type.value
                self._validate_user_event(event_type, payload.exercise_trace_id, payload.metadata)
                microcycle = await self._resolve_event_microcycle(
                    connection, plan_run_id, payload.date
                )
                if microcycle is None and event_type != "observation":
                    raise invalid(
                        "date_outside_run",
                        "Only observations may be positioned outside the run",
                    )
                await self._validate_event_links(
                    connection,
                    plan_run_id,
                    payload.session_id,
                    payload.exercise_trace_id,
                )
                metadata = dict(payload.metadata)
                metadata["_source"] = "user"
                row = await self._fetch_one(
                    connection,
                    """
                    INSERT INTO exec.plan_run_events (
                        plan_run_id, microcycle_id, workout_session_id,
                        exercise_unit_track_id, event_type, occurred_at,
                        title, details, metadata
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                    RETURNING id
                    """,
                    (
                        plan_run_id,
                        microcycle["id"] if microcycle else None,
                        payload.session_id,
                        payload.exercise_trace_id,
                        event_type,
                        self._event_timestamp(payload.date),
                        self._event_title(event_type),
                        payload.body,
                        Jsonb(metadata),
                    ),
                )
                return cast(int, row["id"])

    async def update_event(
        self,
        *,
        plan_run_id: int,
        event_id: int,
        payload: EventPatch,
    ) -> None:
        async with self._pool.connection() as connection:
            async with connection.transaction():
                current = await self._fetch_optional(
                    connection,
                    """
                    SELECT * FROM exec.plan_run_events
                    WHERE id = %s AND plan_run_id = %s FOR UPDATE
                    """,
                    (event_id, plan_run_id),
                )
                if current is None:
                    raise not_found("event_not_found", "Event was not found")
                if self._event_source(current) != "user":
                    raise conflict("event_system_managed", "System events cannot be edited")
                fields = payload.model_fields_set
                event_date = payload.date if "date" in fields else current["occurred_at"].date()
                assert event_date is not None
                body = payload.body if "body" in fields else current["details"]
                session_id = (
                    payload.session_id if "session_id" in fields else current["workout_session_id"]
                )
                exercise_id = (
                    payload.exercise_trace_id
                    if "exercise_trace_id" in fields
                    else current["exercise_unit_track_id"]
                )
                metadata = (
                    dict(payload.metadata or {})
                    if "metadata" in fields
                    else dict(current["metadata"])
                )
                metadata["_source"] = "user"
                event_type = str(current["event_type"])
                self._validate_user_event(event_type, exercise_id, metadata)
                microcycle = await self._resolve_event_microcycle(
                    connection, plan_run_id, event_date
                )
                if microcycle is None and event_type != "observation":
                    raise invalid(
                        "date_outside_run",
                        "Only observations may be positioned outside the run",
                    )
                await self._validate_event_links(
                    connection, plan_run_id, session_id, exercise_id
                )
                await self._execute(
                    connection,
                    """
                    UPDATE exec.plan_run_events
                    SET microcycle_id = %s, workout_session_id = %s,
                        exercise_unit_track_id = %s, occurred_at = %s,
                        details = %s, metadata = %s
                    WHERE id = %s
                    """,
                    (
                        microcycle["id"] if microcycle else None,
                        session_id,
                        exercise_id,
                        self._event_timestamp(event_date),
                        body,
                        Jsonb(metadata),
                        event_id,
                    ),
                )

    async def delete_event(self, *, plan_run_id: int, event_id: int) -> None:
        async with self._pool.connection() as connection:
            async with connection.transaction():
                current = await self._fetch_optional(
                    connection,
                    """SELECT * FROM exec.plan_run_events
                       WHERE id = %s AND plan_run_id = %s FOR UPDATE""",
                    (event_id, plan_run_id),
                )
                if current is None:
                    raise not_found("event_not_found", "Event was not found")
                if self._event_source(current) != "user":
                    raise conflict("event_system_managed", "System events cannot be deleted")
                await self._execute(
                    connection,
                    "DELETE FROM exec.plan_run_events WHERE id = %s",
                    (event_id,),
                )

    async def _resolve_event_microcycle(
        self,
        connection: Any,
        plan_run_id: int,
        event_date: date,
    ) -> Row | None:
        return await self._fetch_optional(
            connection,
            """
            SELECT id, ordinal FROM exec.microcycles
            WHERE plan_run_id = %s AND %s BETWEEN starts_on AND ends_on
            """,
            (plan_run_id, event_date),
        )

    async def _validate_event_links(
        self,
        connection: Any,
        plan_run_id: int,
        session_id: int | None,
        exercise_track_id: int | None,
    ) -> None:
        if session_id is not None:
            session = await self._fetch_optional(
                connection,
                "SELECT id FROM exec.workout_sessions WHERE id = %s AND plan_run_id = %s",
                (session_id, plan_run_id),
            )
            if session is None:
                raise not_found("session_not_found", "Workout session was not found")
        if exercise_track_id is not None:
            trace = await self._fetch_optional(
                connection,
                "SELECT id FROM exec.exercise_unit_tracks WHERE id = %s AND plan_run_id = %s",
                (exercise_track_id, plan_run_id),
            )
            if trace is None:
                raise not_found("exercise_trace_not_found", "Exercise trace was not found")

    @staticmethod
    def _validate_user_event(
        event_type: str,
        exercise_trace_id: int | None,
        metadata: dict[str, Any],
    ) -> None:
        if event_type not in {"observation", "vacation", "training_break", "personal_record"}:
            raise invalid(
                "event_type_system_managed",
                "This event type is created only by the system",
            )
        if event_type == "personal_record":
            if exercise_trace_id is None:
                raise invalid(
                    "missing_exercise_trace",
                    "A personal record requires an exercise trace",
                )
            if "load_kg" not in metadata or "repetitions" not in metadata:
                raise invalid(
                    "missing_exercise_trace",
                    "A personal record requires load_kg and repetitions metadata",
                )

    @staticmethod
    def _event_source(event: Row) -> str:
        metadata = event.get("metadata") or {}
        explicit = metadata.get("_source")
        if explicit in {"system", "user"}:
            return cast(str, explicit)
        return (
            "system"
            if str(event["event_type"])
            in {"plan_revision_changed", "deload_started", "reload_started"}
            or metadata.get("kind") == "run_created"
            else "user"
        )

    @staticmethod
    def _event_timestamp(value: date) -> datetime:
        now = datetime.now(timezone.utc)
        return datetime.combine(value, now.timetz())

    @staticmethod
    def _event_title(event_type: str) -> str:
        return {
            "observation": "Observation",
            "vacation": "Vacation",
            "training_break": "Training break",
            "personal_record": "Personal record",
            "plan_revision_changed": "Plan revision changed",
            "deload_started": "Deload started",
            "reload_started": "Reload started",
        }[event_type]

    @staticmethod
    def _logical_ordinal(logical_key: str) -> int:
        try:
            prefix, value = logical_key.split(":", 1)
            if prefix != "slot":
                raise ValueError
            return int(value)
        except ValueError as exc:
            raise RuntimeError(f"Invalid exercise track logical key: {logical_key}") from exc

    @staticmethod
    def _invalid_load_ordinals(payload: ExercisePrescriptionPut) -> list[int]:
        invalid_ordinals: list[int] = []
        for item in payload.sets:
            if item.load_kg is None:
                continue
            try:
                value = Decimal(str(item.load_kg))
            except InvalidOperation:
                invalid_ordinals.append(item.ordinal)
                continue
            exponent = value.as_tuple().exponent
            if (
                value < 0
                or value > 1000
                or not isinstance(exponent, int)
                or exponent < -2
            ):
                invalid_ordinals.append(item.ordinal)
        return invalid_ordinals

    @staticmethod
    def _basis_detail(basis: Row | None) -> dict[str, Any] | None:
        if basis is None:
            return None
        return {
            "exercise_performance_id": basis["id"],
            "microcycle_ordinal": basis["microcycle_ordinal"],
            "scheduled_date": basis["scheduled_date"].isoformat(),
            "status": basis["workout_performance_status"],
            "execution_mode": basis["execution_mode"],
        }

    @staticmethod
    def _public_run_version(row: Row) -> dict[str, Any]:
        return {
            "plan_run_id": row["id"],
            "name": row["name"],
            "status": str(row["status"]),
            "version": version_of(row["updated_at"]),
        }

    @staticmethod
    def _public_microcycle_version(row: Row) -> dict[str, Any]:
        return {
            "ordinal": row["ordinal"],
            "notes": row["notes"],
            "classification": str(row["classification"]),
            "version": version_of(row["updated_at"]),
        }

    @staticmethod
    def _public_prescription_version(row: Row) -> dict[str, Any]:
        return {
            "exercise_prescription_id": row["id"],
            "version": version_of(row["updated_at"]),
        }

    @staticmethod
    def _public_workout_prescription_version(row: Row) -> dict[str, Any]:
        return {
            "session_id": row["workout_session_id"],
            "prescription_comment": row["prescription_comment"],
            "version": version_of(row["updated_at"]),
        }

    @staticmethod
    async def _execute(
        connection: Any,
        query: str,
        params: tuple[Any, ...] | None = None,
    ) -> None:
        async with connection.cursor() as cursor:
            await cursor.execute(query, params)

    @staticmethod
    async def _fetch_all(
        connection: Any,
        query: str,
        params: tuple[Any, ...] | None = None,
    ) -> list[Row]:
        async with connection.cursor() as cursor:
            await cursor.execute(query, params)
            return list(await cursor.fetchall())

    @classmethod
    async def _fetch_one(
        cls,
        connection: Any,
        query: str,
        params: tuple[Any, ...] | None = None,
    ) -> Row:
        row = await cls._fetch_optional(connection, query, params)
        if row is None:
            raise RuntimeError("Database query unexpectedly returned no rows")
        return row

    @staticmethod
    async def _fetch_optional(
        connection: Any,
        query: str,
        params: tuple[Any, ...] | None = None,
    ) -> Row | None:
        async with connection.cursor() as cursor:
            await cursor.execute(query, params)
            return cast(Row | None, await cursor.fetchone())
