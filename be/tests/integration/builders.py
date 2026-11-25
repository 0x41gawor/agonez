"""Compact builders for integration tests.

Plans, runs and workouts are created through the HTTP API, so tests exercise the same
validation and transactions as the real clients.
"""

from collections.abc import Iterable, Mapping, Sequence
from dataclasses import dataclass
from datetime import date, datetime, time, timedelta, timezone
from typing import Any
from uuid import UUID, uuid4, uuid5

import httpx
from psycopg import AsyncConnection, sql
from psycopg.rows import tuple_row

DEVICE_ID = UUID("00000000-0000-4000-8000-00000000a901")
MAX_OPERATIONS_PER_BATCH = 200


@dataclass(frozen=True)
class SetSpec:
    rep_min: int = 6
    rep_max: int = 10
    rir: str = "RIR2"
    role: str = "working"


THREE_SETS = (SetSpec(), SetSpec(), SetSpec())


@dataclass(frozen=True)
class SlotSpec:
    """One exercise slot: a DEFAULT variant and optional FALLBACK variants with equal sets."""

    exercise: str
    sets: tuple[SetSpec, ...] = THREE_SETS
    fallbacks: tuple[str, ...] = ()
    role: str = "PRIMARY_PROGRESSIVE"
    name: str | None = None


@dataclass(frozen=True)
class DaySpec:
    """A training day when it has a ``workout`` name, otherwise a rest day."""

    workout: str | None = None
    slots: tuple[SlotSpec, ...] = ()
    weekday: int | None = None


@dataclass(frozen=True)
class PlanSpec:
    days: tuple[DaySpec, ...]
    name: str = "Integration plan"


def training(workout: str, *slots: SlotSpec) -> DaySpec:
    return DaySpec(workout=workout, slots=slots)


def rest() -> DaySpec:
    return DaySpec()


def expect(response: httpx.Response, status: int = 200) -> Any:
    """Assert the status and return the decoded body (None when empty)."""
    request = response.request
    assert response.status_code == status, (
        f"{request.method} {request.url.path}: expected {status}, "
        f"got {response.status_code}: {response.text}"
    )
    return response.json() if response.content else None


async def exercise_slugs(connection: AsyncConnection, count: int) -> list[str]:
    """Stable catalog slugs that Execution can prescribe (they have a load-step default)."""
    async with connection.cursor(row_factory=tuple_row) as cursor:
        await cursor.execute(
            """
            SELECT exercise.slug
            FROM core.exercises AS exercise
            JOIN core.resistance_source_load_defaults AS defaults
              ON defaults.resistance_source = exercise.resistance_source
            ORDER BY exercise.id
            LIMIT %s
            """,
            (count,),
        )
        slugs = [row[0] for row in await cursor.fetchall()]
    assert len(slugs) == count, f"The catalog has only {len(slugs)} usable exercises"
    return slugs


def _set_payload(ordinal: int, spec: SetSpec) -> dict[str, Any]:
    return {
        "id": None,
        "ordinal": ordinal,
        "reps": {"min": spec.rep_min, "max": spec.rep_max},
        "rir": spec.rir,
        "role": spec.role,
    }


def _slot_payload(ordinal: int, spec: SlotSpec) -> dict[str, Any]:
    return {
        "id": None,
        "ordinal": ordinal,
        "name": spec.name,
        "description": None,
        "goal": None,
        "role": spec.role,
        "volume_axis": None,
        "target_muscle_slugs": [],
        "variants": [
            {
                "id": None,
                "ordinal": variant_ordinal,
                "variant_type": "DEFAULT" if variant_ordinal == 0 else "FALLBACK",
                "exercise_slug": slug,
                "sets": [_set_payload(index, item) for index, item in enumerate(spec.sets)],
            }
            for variant_ordinal, slug in enumerate((spec.exercise, *spec.fallbacks))
        ],
    }


def day_payload(ordinal: int, spec: DaySpec) -> dict[str, Any]:
    """A new (id-less) day in the shape PUT /api/plans/{id}/draft accepts."""
    assert spec.workout is not None or not spec.slots, "A rest day cannot have slots"
    return {
        "id": None,
        "ordinal": ordinal,
        "weekday": spec.weekday,
        "name": spec.workout or "Rest",
        "description": None,
        "icon": None,
        "workout_unit": (
            {
                "id": None,
                "name": spec.workout,
                "description": None,
                "warmup_notes": None,
                "stretch_notes": None,
                "exercise_slots": [
                    _slot_payload(index, item) for index, item in enumerate(spec.slots)
                ],
            }
            if spec.workout is not None
            else None
        ),
    }


async def make_library_plan(client: httpx.AsyncClient, spec: PlanSpec) -> dict[str, Any]:
    """Create a library plan and save its draft; returns the saved draft artifact.

    To edit it later, change the returned dict and PUT it back to
    ``/api/plans/{id}/draft``.
    """
    draft = expect(await client.post("/api/plans", json={"name": spec.name}), 201)
    draft["days"] = [day_payload(index, item) for index, item in enumerate(spec.days)]
    return expect(await client.put(f"/api/plans/{draft['id']}/draft", json=draft))


async def make_run(
    client: httpx.AsyncClient,
    revision_id: int,
    starts_on: date,
    count: int,
    *,
    name: str = "Integration run",
) -> dict[str, Any]:
    """Start a plan run; returns its overview."""
    return expect(
        await client.post(
            "/api/v1/exec/plan-runs",
            json={
                "plan_revision_id": revision_id,
                "name": name,
                "starts_on": starts_on.isoformat(),
                "microcycle_count": count,
            },
        ),
        201,
    )


def run_sessions(overview: Mapping[str, Any]) -> list[dict[str, Any]]:
    """All sessions of an overview, in calendar order."""
    sessions = [item for cycle in overview["microcycles"] for item in cycle["sessions"]]
    return sorted(sessions, key=lambda item: (item["scheduled_date"], item["session_id"]))


@dataclass(frozen=True)
class FinalizedWorkout:
    workout_id: UUID
    prescription: dict[str, Any]
    result: dict[str, Any]


async def finalize_session(
    client: httpx.AsyncClient,
    session_id: int,
    performed_on: date,
    *,
    load_kg: float = 20.0,
    device_id: UUID = DEVICE_ID,
) -> FinalizedWorkout:
    """Perform every prescribed set of a session through the mobile API and finalize it.

    Prepares the fallback prescription first (saved analysis rows are kept), then runs
    start, ops and finalize. ``performed_on`` must be the session's scheduled date: this
    helper does not send an off-schedule acknowledgement. Sets without a resolved load are
    performed with ``load_kg``.
    """
    headers = {"X-Agonez-Device-Id": str(device_id)}
    prescription = expect(
        await client.post(
            f"/api/v1/mobile/sessions/{session_id}/prescription/fallback",
            headers=headers,
        )
    )
    workout_id = uuid4()
    started_at = datetime.combine(performed_on, time(17, 0), tzinfo=timezone.utc)
    at = started_at.isoformat()
    snapshot = expect(
        await client.post(
            "/api/v1/mobile/workouts",
            headers=headers,
            json={
                "workout_id": str(workout_id),
                "session_id": session_id,
                "prescription_version": prescription["prescription_version"],
                "started_at": at,
                "allow_missing_loads": True,
            },
        ),
        201,
    )
    performance_ids = {
        item["exercise_prescription_id"]: item["exercise_performance_id"]
        for item in snapshot["performance"]["exercises"]
    }
    prescribed = [
        (exercise, item) for exercise in prescription["exercises"] for item in exercise["sets"]
    ]
    operations = [
        {
            "op_id": str(uuid4()),
            "seq": seq,
            "at": at,
            "type": "upsert_set",
            "data": {
                "set_performance_id": str(uuid5(workout_id, f"set:{item['set_prescription_id']}")),
                "exercise_performance_id": performance_ids[exercise["exercise_prescription_id"]],
                "exercise_prescription_id": exercise["exercise_prescription_id"],
                "prescribed_set_id": item["set_prescription_id"],
                "ordinal": item["ordinal"],
                "status": "performed",
                "load_kg": (
                    load_kg if item["prescribed_load_kg"] is None else item["prescribed_load_kg"]
                ),
                "repetitions": item["rep_min"],
                "rir": item["target_rir"],
                "performed_at": at,
            },
        }
        for seq, (exercise, item) in enumerate(prescribed, start=1)
    ]
    epoch = snapshot["lease"]["epoch"]
    for offset in range(0, len(operations), MAX_OPERATIONS_PER_BATCH):
        batch = operations[offset : offset + MAX_OPERATIONS_PER_BATCH]
        synced = expect(
            await client.post(
                f"/api/v1/mobile/workouts/{workout_id}/ops",
                headers=headers,
                json={"lease_epoch": epoch, "base_seq": offset, "ops": batch},
            )
        )
        rejected = [item for item in synced["results"] if item["status"] != "applied"]
        assert not rejected, rejected
    result = expect(
        await client.post(
            f"/api/v1/mobile/workouts/{workout_id}/finalize",
            headers=headers,
            json={
                "lease_epoch": epoch,
                "final_seq": len(operations),
                "finished_at": (started_at + timedelta(hours=1)).isoformat(),
                "unrecorded": "mark_not_performed",
                "acknowledged_incomplete": False,
            },
        )
    )
    return FinalizedWorkout(workout_id=workout_id, prescription=prescription, result=result)


async def table_names(connection: AsyncConnection, *schemas: str) -> list[str]:
    """Qualified names of all base tables in the given schemas."""
    async with connection.cursor(row_factory=tuple_row) as cursor:
        await cursor.execute(
            """
            SELECT table_schema || '.' || table_name
            FROM information_schema.tables
            WHERE table_schema = ANY(%s) AND table_type = 'BASE TABLE'
            ORDER BY 1
            """,
            (list(schemas),),
        )
        return [row[0] for row in await cursor.fetchall()]


async def snapshot_tables(
    connection: AsyncConnection,
    tables: Iterable[str],
    *,
    where: Mapping[str, tuple[str, Sequence[Any]]] | None = None,
) -> dict[str, str]:
    """Fingerprint ``schema.table`` contents as ``"<row count>:<sha256 of ordered rows>"``.

    Compare two snapshots to assert that nothing changed. ``where`` narrows single tables:
    ``{"exec.microcycles": ("row_.plan_run_id = %s", (run_id,))}``; the table alias is
    ``row_`` and the condition is trusted test code.
    """
    tables = list(tables)
    where = where or {}
    unknown = set(where) - set(tables)
    assert not unknown, f"Filters for tables that are not snapshotted: {sorted(unknown)}"
    snapshot: dict[str, str] = {}
    async with connection.cursor(row_factory=tuple_row) as cursor:
        for table in tables:
            condition, parameters = where.get(table, ("TRUE", ()))
            query = sql.SQL(
                """
                SELECT count(*),
                       encode(sha256(convert_to(
                           coalesce(string_agg(line, E'\\n' ORDER BY line COLLATE "C"), ''),
                           'UTF8'
                       )), 'hex')
                FROM (
                    SELECT row_::text AS line FROM {table} AS row_ WHERE {condition}
                ) AS lines
                """
            ).format(
                table=sql.Identifier(*table.split(".")),
                condition=sql.SQL(condition),
            )
            # `E'\n'` holds no percent sign, so the query is safe with and without parameters.
            await cursor.execute(query, tuple(parameters) or None)
            row = await cursor.fetchone()
            assert row is not None
            snapshot[table] = f"{row[0]}:{row[1]}"
    return snapshot
