"""Run creation and deletion with run plans (T2.2; ``02`` §3.3, §3.6; ``04`` §2).

T-INT-RUN-01…09, T-DEL-01, T-DEL-02 and T-IMM-04 of ``07``. Every new run copies the library
revision it is created from into its own run plan (r1 RELEASED, executed; r2 DRAFT, the
working copy) and binds only to r1. T-INT-RUN-05/06 cover the run-plan draft half; their
Apply half lands with T3.3.
"""

import copy
from dataclasses import dataclass
from datetime import date, timedelta
from typing import Any

import httpx
import pytest
from builders import (
    DEVICE_ID,
    PlanSpec,
    SetSpec,
    SlotSpec,
    exercise_slugs,
    expect,
    finalize_session,
    make_library_plan,
    make_run,
    rest,
    run_sessions,
    snapshot_tables,
    table_names,
    training,
)
from conftest import RUN_PLAN_CONVERSION, FrozenClock
from psycopg import AsyncConnection, errors

from agonez_api.modules.plans.fingerprint import definition_fingerprint
from agonez_api.modules.plans.repository import load_revision_rows

DEVICE_HEADERS = {"X-Agonez-Device-Id": str(DEVICE_ID)}
PNG = b"\x89PNG\r\n\x1a\n" + b"0" * 64
RUNS = "/api/v1/exec/plan-runs"


@dataclass(frozen=True)
class CreatedRun:
    run_id: int
    plan_id: int  # the run plan
    released_id: int  # r1
    draft_id: int  # r2
    overview: dict[str, Any]


@pytest.fixture
async def spare_exercise(db: AsyncConnection) -> str:
    return (await exercise_slugs(db, 5))[4]


@pytest.fixture
async def library(client: httpx.AsyncClient, db: AsyncConnection) -> dict[str, Any]:
    """Upper (press with a fallback, fly) / rest / Lower (squat), with identity and a cover."""
    press, row, fly, squat = (await exercise_slugs(db, 4))[:4]
    plan = await make_library_plan(
        client,
        PlanSpec(
            name="Run creation plan",
            days=(
                training(
                    "Upper",
                    SlotSpec(press, sets=(SetSpec(4, 6),) * 3, fallbacks=(row,)),
                    SlotSpec(fly, sets=(SetSpec(10, 15),) * 2),
                ),
                rest(),
                training("Lower", SlotSpec(squat)),
            ),
        ),
    )
    plan["description"] = "Two training days"
    plan["accent"] = "teal"
    plan = expect(await client.put(f"/api/plans/{plan['id']}/draft", json=plan))
    expect(
        await client.put(
            f"/api/plans/{plan['id']}/image", content=PNG, headers={"Content-Type": "image/png"}
        )
    )
    return expect(await client.get(f"/api/plans/{plan['id']}/draft"))


async def create_run(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    revision_id: int,
    clock: FrozenClock,
    count: int = 2,
) -> CreatedRun:
    overview = await make_run(client, revision_id, clock.today, count)
    run_id = int(overview["run"]["plan_run_id"])
    row = await (
        await db.execute(
            """
            SELECT run.run_plan_id,
                   (SELECT id FROM plans.plan_revisions
                    WHERE plan_id = run.run_plan_id AND status = 'RELEASED') AS released_id,
                   (SELECT id FROM plans.plan_revisions
                    WHERE plan_id = run.run_plan_id AND status = 'DRAFT') AS draft_id
            FROM exec.plan_runs AS run
            WHERE run.id = %s
            """,
            (run_id,),
        )
    ).fetchone()
    assert row is not None and row["run_plan_id"] is not None
    return CreatedRun(run_id, row["run_plan_id"], row["released_id"], row["draft_id"], overview)


async def fingerprint(db: AsyncConnection, revision_id: int) -> str:
    return definition_fingerprint(await load_revision_rows(db, revision_id))


async def one(db: AsyncConnection, query: str, *params: Any) -> dict[str, Any]:
    row = await (await db.execute(query, params)).fetchone()
    assert row is not None
    return row


async def all_rows(db: AsyncConnection, query: str, *params: Any) -> list[dict[str, Any]]:
    return await (await db.execute(query, params)).fetchall()


def run_tables(run_id: int) -> dict[str, tuple[str, tuple[Any, ...]]]:
    """``snapshot_tables`` filters for every exec row of one run."""
    by_run = ("row_.plan_run_id = %s", (run_id,))
    by_session = (
        "row_.workout_session_id IN "
        "(SELECT id FROM exec.workout_sessions WHERE plan_run_id = %s)",
        (run_id,),
    )
    return {
        "exec.plan_runs": ("row_.id = %s", (run_id,)),
        "exec.microcycles": by_run,
        "exec.workout_unit_tracks": by_run,
        "exec.exercise_unit_tracks": by_run,
        "exec.workout_sessions": by_run,
        "exec.plan_run_events": by_run,
        "exec.workout_unit_prescriptions": by_session,
        "exec.exercise_setup_notes": (
            "row_.exercise_unit_track_id IN "
            "(SELECT id FROM exec.exercise_unit_tracks WHERE plan_run_id = %s)",
            (run_id,),
        ),
    }


async def run_snapshot(db: AsyncConnection, run_id: int) -> dict[str, str]:
    tables = run_tables(run_id)
    return await snapshot_tables(db, tables, where=tables)


async def plan_snapshot(db: AsyncConnection, plan_id: int) -> dict[str, str]:
    """Every row of one plan: the plan, its revisions, image and revision trees."""
    revisions = "SELECT id FROM plans.plan_revisions WHERE plan_id = %s"
    days = f"SELECT id FROM plans.day_prescriptions WHERE revision_id IN ({revisions})"
    units = f"SELECT id FROM plans.workout_unit_prescriptions WHERE day_id IN ({days})"
    slots = f"SELECT id FROM plans.exercise_slots WHERE workout_unit_id IN ({units})"
    variants = f"SELECT id FROM plans.exercise_variants WHERE slot_id IN ({slots})"
    where = {
        "plans.workout_plans": ("row_.id = %s", (plan_id,)),
        "plans.plan_revisions": ("row_.plan_id = %s", (plan_id,)),
        "plans.plan_images": ("row_.plan_id = %s", (plan_id,)),
        "plans.day_prescriptions": (f"row_.revision_id IN ({revisions})", (plan_id,)),
        "plans.workout_unit_prescriptions": (f"row_.day_id IN ({days})", (plan_id,)),
        "plans.exercise_slots": (f"row_.workout_unit_id IN ({units})", (plan_id,)),
        "plans.exercise_slot_target_muscles": (f"row_.slot_id IN ({slots})", (plan_id,)),
        "plans.exercise_variants": (f"row_.slot_id IN ({slots})", (plan_id,)),
        "plans.set_infra_prescriptions": (
            f"row_.exercise_variant_id IN ({variants})",
            (plan_id,),
        ),
    }
    return await snapshot_tables(db, where, where=where)


async def test_int_run_01_the_run_owns_a_copy_of_the_library_revision(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    clock: FrozenClock,
    library: dict[str, Any],
) -> None:
    run = await create_run(client, db, library["revision_id"], clock)

    plan = await one(
        db,
        """
        SELECT plan.scope::text AS scope, plan.source_plan_id, plan.name, plan.description,
               plan.accent::text AS accent, image.checksum, image.content_type,
               run.initial_plan_revision_id, run.run_plan_scope::text AS run_plan_scope
        FROM plans.workout_plans AS plan
        LEFT JOIN plans.plan_images AS image ON image.plan_id = plan.id
        JOIN exec.plan_runs AS run ON run.run_plan_id = plan.id
        WHERE plan.id = %s
        """,
        run.plan_id,
    )
    library_image = await one(
        db, "SELECT checksum FROM plans.plan_images WHERE plan_id = %s", library["id"]
    )
    assert plan == {
        "scope": "run",
        "source_plan_id": library["id"],
        "name": library["name"],
        "description": "Two training days",
        "accent": "teal",
        "checksum": library_image["checksum"],
        "content_type": "image/png",
        "initial_plan_revision_id": run.released_id,
        "run_plan_scope": "run",
    }
    revisions = await all_rows(
        db,
        """
        SELECT id, revision_no, status::text AS status, based_on_revision_id,
               released_at IS NOT NULL AS released
        FROM plans.plan_revisions WHERE plan_id = %s ORDER BY revision_no
        """,
        run.plan_id,
    )
    assert revisions == [
        {
            "id": run.released_id,
            "revision_no": 1,
            "status": "RELEASED",
            "based_on_revision_id": library["revision_id"],
            "released": True,
        },
        {
            "id": run.draft_id,
            "revision_no": 2,
            "status": "DRAFT",
            "based_on_revision_id": run.released_id,
            "released": False,
        },
    ]
    library_fingerprint = await fingerprint(db, library["revision_id"])
    assert await fingerprint(db, run.released_id) == library_fingerprint
    assert await fingerprint(db, run.draft_id) == library_fingerprint
    released = await load_revision_rows(db, run.released_id)
    assert (released.header["plan_run_id"], released.header["revision_status"]) == (
        run.run_id,
        "RELEASED",
    )

    # The header reads the plan through initial_plan_revision_id: same name, the run plan's
    # id and code until T3.1/T4.5 add the source plan.
    header = run.overview["run"]
    assert header["plan"] == {
        "plan_id": run.plan_id,
        "code": f"P{run.plan_id:03d}",
        "name": library["name"],
    }
    assert header["initial_revision"]["plan_revision_id"] == run.released_id
    # My Plans still shows only the library plan.
    listed = {item["id"] for item in expect(await client.get("/api/plans"))["items"]}
    assert library["id"] in listed and run.plan_id not in listed


async def test_int_run_02_tracks_carry_the_lineage_keys_and_positional_labels(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    clock: FrozenClock,
    library: dict[str, Any],
) -> None:
    run = await create_run(client, db, library["revision_id"], clock)

    expected_workouts = await all_rows(
        db,
        """
        SELECT 'day:' || day.ordinal AS logical_key, unit.lineage_key, unit.name
        FROM plans.workout_unit_prescriptions AS unit
        JOIN plans.day_prescriptions AS day ON day.id = unit.day_id
        WHERE day.revision_id = %s
        ORDER BY day.ordinal
        """,
        run.released_id,
    )
    workouts = await all_rows(
        db,
        """
        SELECT logical_key, plan_lineage_key AS lineage_key, name
        FROM exec.workout_unit_tracks WHERE plan_run_id = %s ORDER BY logical_key
        """,
        run.run_id,
    )
    assert workouts == expected_workouts and len(workouts) == 2

    expected_exercises = await all_rows(
        db,
        """
        SELECT 'day:' || day.ordinal AS workout_key, 'slot:' || slot.ordinal AS logical_key,
               slot.lineage_key, variant.progression_id
        FROM plans.exercise_slots AS slot
        JOIN plans.exercise_variants AS variant
          ON variant.slot_id = slot.id AND variant.variant_type = 'DEFAULT'
        JOIN plans.workout_unit_prescriptions AS unit ON unit.id = slot.workout_unit_id
        JOIN plans.day_prescriptions AS day ON day.id = unit.day_id
        WHERE day.revision_id = %s
        ORDER BY day.ordinal, slot.ordinal
        """,
        run.released_id,
    )
    exercises = await all_rows(
        db,
        """
        SELECT workout.logical_key AS workout_key, track.logical_key,
               track.plan_lineage_key AS lineage_key,
               track.source_progression_id AS progression_id
        FROM exec.exercise_unit_tracks AS track
        JOIN exec.workout_unit_tracks AS workout ON workout.id = track.workout_unit_track_id
        WHERE track.plan_run_id = %s
        ORDER BY workout.logical_key, track.logical_key
        """,
        run.run_id,
    )
    assert exercises == expected_exercises and len(exercises) == 3

    # The keys are copies of the library plan's (unique per plan, not globally).
    library_keys = {
        row["lineage_key"]
        for row in await all_rows(
            db,
            """
            SELECT unit.lineage_key FROM plans.workout_unit_prescriptions AS unit
            JOIN plans.day_prescriptions AS day ON day.id = unit.day_id
            WHERE day.revision_id = %s
            UNION ALL
            SELECT slot.lineage_key FROM plans.exercise_slots AS slot
            JOIN plans.workout_unit_prescriptions AS unit ON unit.id = slot.workout_unit_id
            JOIN plans.day_prescriptions AS day ON day.id = unit.day_id
            WHERE day.revision_id = %s
            """,
            library["revision_id"],
            library["revision_id"],
        )
    }
    assert {row["lineage_key"] for row in (*workouts, *exercises)} == library_keys


async def test_int_run_03_sessions_bind_to_r1_and_match_the_preview(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    clock: FrozenClock,
    library: dict[str, Any],
) -> None:
    preview = expect(
        await client.get(
            f"{RUNS}/preview",
            params={
                "plan_revision_id": library["revision_id"],
                "starts_on": clock.today.isoformat(),
                "microcycle_count": 3,
            },
        )
    )
    run = await create_run(client, db, library["revision_id"], clock, count=3)

    counts = await one(
        db,
        """
        SELECT
            (SELECT count(*) FROM exec.workout_sessions WHERE plan_run_id = run.id) AS sessions,
            (SELECT count(*) FROM exec.workout_unit_tracks WHERE plan_run_id = run.id)
                AS workout_tracks,
            (SELECT count(*) FROM exec.exercise_unit_tracks WHERE plan_run_id = run.id)
                AS exercise_tracks,
            run.ends_on, run.microcycle_duration_days
        FROM exec.plan_runs AS run WHERE run.id = %s
        """,
        run.run_id,
    )
    assert counts == {
        "sessions": preview["session_count"],
        "workout_tracks": preview["workout_track_count"],
        "exercise_tracks": preview["exercise_track_count"],
        "ends_on": date.fromisoformat(preview["ends_on"]),
        "microcycle_duration_days": preview["microcycle_duration_days"],
    }
    assert (counts["sessions"], counts["exercise_tracks"]) == (6, 3)

    bindings = await one(
        db,
        """
        SELECT
            (SELECT count(*) FROM exec.microcycles
             WHERE plan_run_id = %s AND plan_revision_id IS DISTINCT FROM %s) AS other_cycles,
            (SELECT count(*) FROM exec.workout_sessions AS session
             JOIN plans.day_prescriptions AS day ON day.id = session.source_plan_day_id
             JOIN plans.workout_unit_prescriptions AS unit
               ON unit.id = session.source_plan_workout_unit_id
             WHERE session.plan_run_id = %s AND day.revision_id = %s AND unit.day_id = day.id)
                AS bound_to_r1
        """,
        run.run_id,
        run.released_id,
        run.run_id,
        run.released_id,
    )
    assert bindings == {"other_cycles": 0, "bound_to_r1": 6}

    # A "My setup" note per exercise a slot can hold: the press slot has a fallback.
    notes = await all_rows(
        db,
        """
        SELECT track.logical_key, count(*) AS notes, bool_and(note.note_text IS NULL) AS empty
        FROM exec.exercise_setup_notes AS note
        JOIN exec.exercise_unit_tracks AS track ON track.id = note.exercise_unit_track_id
        WHERE track.plan_run_id = %s
        GROUP BY track.workout_unit_track_id, track.logical_key
        ORDER BY track.workout_unit_track_id, track.logical_key
        """,
        run.run_id,
    )
    assert [(row["logical_key"], row["notes"], row["empty"]) for row in notes] == [
        ("slot:0", 2, True),
        ("slot:1", 1, True),
        ("slot:0", 1, True),
    ]
    # Nothing of the run references the library plan's rows (I1).
    library_refs = await one(
        db,
        """
        SELECT count(*) AS n
        FROM exec.workout_sessions AS session
        JOIN plans.day_prescriptions AS day ON day.id = session.source_plan_day_id
        WHERE session.plan_run_id = %s AND day.revision_id = %s
        """,
        run.run_id,
        library["revision_id"],
    )
    assert library_refs == {"n": 0}


async def test_new_run_works_with_the_current_read_code(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    clock: FrozenClock,
    library: dict[str, Any],
) -> None:
    """``06`` T2.2: overview, queue, timeline, mobile context and fallback/start work."""
    run = await create_run(client, db, library["revision_id"], clock)
    base = f"{RUNS}/{run.run_id}"
    sessions = run_sessions(run.overview)
    assert [item["scheduled_date"] for item in sessions][:2] == [
        clock.today.isoformat(),
        (clock.today + timedelta(days=2)).isoformat(),
    ]

    queue = expect(await client.get(f"{base}/analysis/queue"))
    assert [len(workout["exercises"]) for workout in queue["workouts"]] == [2, 1]
    for workout in queue["workouts"]:
        for exercise in workout["exercises"]:
            trace_id = exercise["exercise_trace_id"]
            expect(await client.get(f"{base}/exercise-traces/{trace_id}"))
            expect(await client.get(f"{base}/exercise-traces/{trace_id}/next"))
    for path in ("microcycles", "calendar", "workout-traces", "events"):
        expect(await client.get(f"{base}/{path}"))
    context = expect(
        await client.get(
            "/api/v1/mobile/context",
            params={"plan_run_id": run.run_id, "date": clock.today.isoformat()},
            headers=DEVICE_HEADERS,
        )
    )
    assert context["plan_run"]["plan_name"] == library["name"]

    workout = await finalize_session(client, sessions[0]["session_id"], clock.today)
    assert len(workout.prescription["exercises"]) == 2
    overview = expect(await client.get(f"{base}/overview"))
    statuses = {item["session_id"]: item["status"] for item in run_sessions(overview)}
    assert statuses[sessions[0]["session_id"]] == "completed"


async def test_int_run_04_library_edits_do_not_reach_the_run(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    clock: FrozenClock,
    library: dict[str, Any],
    spare_exercise: str,
) -> None:
    run = await create_run(client, db, library["revision_id"], clock)
    base = f"{RUNS}/{run.run_id}"
    queue = expect(await client.get(f"{base}/analysis/queue"))
    trace_ids = [item["exercise_trace_id"] for w in queue["workouts"] for item in w["exercises"]]

    async def seen_by_run() -> dict[str, Any]:
        return {
            "r1": await fingerprint(db, run.released_id),
            "r2": await fingerprint(db, run.draft_id),
            "plan": await plan_snapshot(db, run.plan_id),
            "rows": await run_snapshot(db, run.run_id),
            "overview": expect(await client.get(f"{base}/overview")),
            "next": [
                expect(await client.get(f"{base}/exercise-traces/{trace_id}/next"))
                for trace_id in trace_ids
            ],
        }

    before = await seen_by_run()

    # Rename (swap) an exercise, change sets, delete a training day: the save succeeds.
    edited = copy.deepcopy(library)
    upper = edited["days"][0]["workout_unit"]
    upper["exercise_slots"][1]["variants"][0]["exercise_slug"] = spare_exercise
    for item in upper["exercise_slots"][0]["variants"][0]["sets"]:
        item["reps"] = {"min": 1, "max": 3}
    edited["days"].pop()
    saved = expect(await client.put(f"/api/plans/{library['id']}/draft", json=edited))
    assert len(saved["days"]) == 2

    assert await seen_by_run() == before


async def test_int_run_05_run_plan_edits_do_not_reach_the_library(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    clock: FrozenClock,
    library: dict[str, Any],
) -> None:
    """Draft half; the Apply half lands with T3.3."""
    run = await create_run(client, db, library["revision_id"], clock)
    library_before = (
        await plan_snapshot(db, library["id"]),
        expect(await client.get(f"/api/plans/{library['id']}")),
    )
    released_before = await fingerprint(db, run.released_id)
    run_before = await run_snapshot(db, run.run_id)

    # The working copy is unreferenced, so even a training day can be removed (R2).
    draft = expect(await client.get(f"/api/plans/{run.plan_id}/draft"))
    assert (draft["revision_id"], draft["scope"], draft["plan_run_id"]) == (
        run.draft_id,
        "run",
        run.run_id,
    )
    draft["days"][0]["workout_unit"]["exercise_slots"][0]["variants"][0]["sets"].pop()
    draft["days"].pop()
    expect(await client.put(f"/api/plans/{run.plan_id}/draft", json=draft))

    assert await fingerprint(db, run.draft_id) != released_before
    assert await fingerprint(db, run.released_id) == released_before
    assert await run_snapshot(db, run.run_id) == run_before
    assert (
        await plan_snapshot(db, library["id"]),
        expect(await client.get(f"/api/plans/{library['id']}")),
    ) == library_before


async def test_int_run_06_two_runs_from_one_plan_are_independent(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    clock: FrozenClock,
    library: dict[str, Any],
    spare_exercise: str,
) -> None:
    """Draft half; the Apply half lands with T3.3."""
    first = await create_run(client, db, library["revision_id"], clock)
    second = await create_run(client, db, library["revision_id"], clock)
    assert first.plan_id != second.plan_id
    shared = await one(
        db,
        """
        SELECT count(*) AS n
        FROM exec.workout_sessions AS a
        JOIN exec.workout_sessions AS b
          ON b.source_plan_workout_unit_id = a.source_plan_workout_unit_id
        WHERE a.plan_run_id = %s AND b.plan_run_id = %s
        """,
        first.run_id,
        second.run_id,
    )
    assert shared == {"n": 0}

    second_before = (
        await plan_snapshot(db, second.plan_id),
        await run_snapshot(db, second.run_id),
        expect(await client.get(f"{RUNS}/{second.run_id}/overview")),
    )

    draft = expect(await client.get(f"/api/plans/{first.plan_id}/draft"))
    draft["name"] = "Renamed run plan"
    draft["days"][0]["workout_unit"]["exercise_slots"][1]["variants"][0]["exercise_slug"] = (
        spare_exercise
    )
    expect(await client.put(f"/api/plans/{first.plan_id}/draft", json=draft))

    assert (
        await plan_snapshot(db, second.plan_id),
        await run_snapshot(db, second.run_id),
        expect(await client.get(f"{RUNS}/{second.run_id}/overview")),
    ) == second_before


async def test_int_run_07_t_del_02_deleting_the_run_deletes_its_run_plan(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    clock: FrozenClock,
    library: dict[str, Any],
) -> None:
    run = await create_run(client, db, library["revision_id"], clock)
    other = await create_run(client, db, library["revision_id"], clock)
    library_before = await plan_snapshot(db, library["id"])
    other_before = (await plan_snapshot(db, other.plan_id), await run_snapshot(db, other.run_id))
    # A plan promoted from the run plan (T5.1 sets source_plan_id; done by hand here).
    promoted = expect(await client.post(f"/api/plans/{run.plan_id}/duplicate"), 201)
    await db.execute(
        "UPDATE plans.workout_plans SET source_plan_id = %s WHERE id = %s",
        (run.plan_id, promoted["id"]),
    )
    promoted_fingerprint = await fingerprint(db, promoted["revision_id"])

    expect(await client.delete(f"{RUNS}/{run.run_id}"), 204)

    gone = await plan_snapshot(db, run.plan_id)
    assert {table: value.split(":")[0] for table, value in gone.items()} == dict.fromkeys(
        gone, "0"
    )
    assert (await client.get(f"{RUNS}/{run.run_id}/overview")).status_code == 404
    assert await plan_snapshot(db, library["id"]) == library_before
    assert (
        await plan_snapshot(db, other.plan_id),
        await run_snapshot(db, other.run_id),
    ) == other_before
    lineage = await one(
        db,
        """
        SELECT plan.source_plan_id, revision.based_on_revision_id
        FROM plans.workout_plans AS plan
        JOIN plans.plan_revisions AS revision ON revision.plan_id = plan.id
        WHERE plan.id = %s
        """,
        promoted["id"],
    )
    assert lineage == {"source_plan_id": None, "based_on_revision_id": None}
    assert await fingerprint(db, promoted["revision_id"]) == promoted_fingerprint
    expect(await client.get(f"/api/plans/{promoted['id']}/draft"))


# Legacy runs exist only before 0019, which converts them and makes run_plan_id NOT NULL.
@pytest.mark.before_migration(RUN_PLAN_CONVERSION)
async def test_deleting_a_legacy_run_keeps_its_library_plan(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    clock: FrozenClock,
    library: dict[str, Any],
) -> None:
    """Runs created before T2.2 own no run plan until 0019; their delete is unchanged."""
    legacy = await one(
        db,
        """
        INSERT INTO exec.plan_runs (
            name, initial_plan_revision_id, starts_on, microcycle_count,
            microcycle_duration_days
        ) VALUES ('Legacy run', %s, %s, 1, 3)
        RETURNING id
        """,
        library["revision_id"],
        clock.today,
    )
    before = await plan_snapshot(db, library["id"])

    expect(await client.delete(f"{RUNS}/{legacy['id']}"), 204)

    assert await plan_snapshot(db, library["id"]) == before


async def test_int_run_08_a_run_plan_revision_is_not_a_source(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    clock: FrozenClock,
    library: dict[str, Any],
) -> None:
    run = await create_run(client, db, library["revision_id"], clock)
    tables = await table_names(db, "plans", "exec")
    before = await snapshot_tables(db, tables)

    for revision_id in (run.released_id, run.draft_id):
        response = await client.post(
            RUNS,
            json={
                "plan_revision_id": revision_id,
                "name": "Copy of a copy",
                "starts_on": clock.today.isoformat(),
                "microcycle_count": 1,
            },
        )
        assert response.status_code == 422, response.text
        error = response.json()["error"]
        assert error["code"] == "plan_revision_not_library"
        assert error["details"] == {"plan_revision_id": revision_id, "plan_id": run.plan_id}

    missing = await client.post(
        RUNS,
        json={
            "plan_revision_id": 987654,
            "name": "Missing",
            "starts_on": clock.today.isoformat(),
            "microcycle_count": 1,
        },
    )
    assert missing.status_code == 404, missing.text
    assert missing.json()["error"]["code"] == "plan_revision_not_found"
    assert await snapshot_tables(db, tables) == before


async def test_int_run_09_a_non_executable_revision_is_refused(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    clock: FrozenClock,
) -> None:
    """Q1: 422 ``plan_not_executable`` with one issue per problem; nothing is created."""
    press, fly = await exercise_slugs(db, 2)
    plan = await make_library_plan(
        client,
        PlanSpec(
            name="Unfinished plan",
            days=(
                training("Upper", SlotSpec(press), SlotSpec(fly), SlotSpec(fly, sets=())),
                rest(),
                training("Core"),
            ),
        ),
    )
    # The plans API keeps unfinished plans: an empty slot is saved without variants.
    plan["days"][0]["workout_unit"]["exercise_slots"][1]["variants"] = []
    plan = expect(await client.put(f"/api/plans/{plan['id']}/draft", json=plan))
    only_rest = await make_library_plan(
        client, PlanSpec(name="Rest only", days=(rest(), rest()))
    )
    tables = await table_names(db, "plans", "exec")
    before = await snapshot_tables(db, tables)

    response = await client.post(
        RUNS,
        json={
            "plan_revision_id": plan["revision_id"],
            "name": "Unfinished run",
            "starts_on": clock.today.isoformat(),
            "microcycle_count": 2,
        },
    )

    assert response.status_code == 422, response.text
    error = response.json()["error"]
    assert error["code"] == "plan_not_executable"
    assert error["details"]["issues"] == [
        {
            "code": "slot_without_exercise",
            "path": "days.0.workout_unit.exercise_slots.1",
            "day_ordinal": 0,
            "slot_ordinal": 1,
            "message": 'Day 1 "Upper", exercise 2: choose the exercise to perform.',
        },
        {
            "code": "exercise_without_sets",
            "path": "days.0.workout_unit.exercise_slots.2",
            "day_ordinal": 0,
            "slot_ordinal": 2,
            "message": f'Day 1 "Upper", exercise 3 "{fly}": the exercise has no sets.',
        },
        {
            "code": "workout_without_exercises",
            "path": "days.2.workout_unit",
            "day_ordinal": 2,
            "slot_ordinal": None,
            "message": 'Day 3 "Core": the workout has no exercises.',
        },
    ]
    assert error["message"] == (
        "This plan cannot be started yet. "
        'Day 1 "Upper", exercise 2: choose the exercise to perform. '
        f'Day 1 "Upper", exercise 3 "{fly}": the exercise has no sets. '
        'Day 3 "Core": the workout has no exercises.'
    )

    rest_only = await client.post(
        RUNS,
        json={
            "plan_revision_id": only_rest["revision_id"],
            "name": "Rest run",
            "starts_on": clock.today.isoformat(),
            "microcycle_count": 1,
        },
    )
    assert rest_only.status_code == 422, rest_only.text
    assert [item["code"] for item in rest_only.json()["error"]["details"]["issues"]] == [
        "no_workouts"
    ]
    assert await snapshot_tables(db, tables) == before

    # The preview stays permissive (unchanged), and so does My Plans.
    expect(
        await client.get(
            f"{RUNS}/preview",
            params={
                "plan_revision_id": plan["revision_id"],
                "starts_on": clock.today.isoformat(),
                "microcycle_count": 2,
            },
        )
    )


async def test_t_del_01_deleting_the_library_plan_leaves_the_run(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    clock: FrozenClock,
    library: dict[str, Any],
) -> None:
    run = await create_run(client, db, library["revision_id"], clock)
    await finalize_session(client, run_sessions(run.overview)[0]["session_id"], clock.today)
    overview = expect(await client.get(f"{RUNS}/{run.run_id}/overview"))
    before = (
        await fingerprint(db, run.released_id),
        await fingerprint(db, run.draft_id),
        await run_snapshot(db, run.run_id),
    )

    expect(await client.delete(f"/api/plans/{library['id']}"), 204)

    lineage = await one(
        db,
        """
        SELECT plan.source_plan_id, revision.based_on_revision_id
        FROM plans.workout_plans AS plan
        JOIN plans.plan_revisions AS revision ON revision.plan_id = plan.id
        WHERE revision.id = %s
        """,
        run.released_id,
    )
    assert lineage == {"source_plan_id": None, "based_on_revision_id": None}
    assert (
        await fingerprint(db, run.released_id),
        await fingerprint(db, run.draft_id),
        await run_snapshot(db, run.run_id),
    ) == before
    assert expect(await client.get(f"{RUNS}/{run.run_id}/overview")) == overview


async def test_t_imm_04_referenced_released_rows_cannot_be_deleted(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    clock: FrozenClock,
    library: dict[str, Any],
) -> None:
    """RESTRICT FKs from exec refuse deleting r1 rows, r1 itself and the run plan."""
    run = await create_run(client, db, library["revision_id"], clock)
    await finalize_session(client, run_sessions(run.overview)[0]["session_id"], clock.today)
    released = await load_revision_rows(db, run.released_id)
    before = await plan_snapshot(db, run.plan_id)
    statements = [
        ("plans.set_infra_prescriptions", released.sets[0]["id"]),
        ("plans.exercise_variants", released.variants[0]["id"]),
        ("plans.exercise_slots", released.slots[0]["id"]),
        ("plans.workout_unit_prescriptions", released.workout_units[0]["id"]),
        ("plans.day_prescriptions", released.days[0]["id"]),
        ("plans.plan_revisions", run.released_id),
        ("plans.workout_plans", run.plan_id),
    ]
    for table, row_id in statements:
        with pytest.raises(errors.ForeignKeyViolation):
            async with db.transaction():
                await db.execute(f"DELETE FROM {table} WHERE id = %s", (row_id,))

    assert await plan_snapshot(db, run.plan_id) == before
