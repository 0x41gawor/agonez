"""The harness itself: a full lifecycle on a fresh clone, plus the assertion helpers."""

from datetime import timedelta
from importlib.resources import files

import httpx
from builders import (
    PlanSpec,
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
from conftest import FrozenClock
from psycopg import AsyncConnection

PLAN_NAME = "Harness smoke plan"


async def _two_day_plan(db: AsyncConnection) -> PlanSpec:
    press, fly, squat = await exercise_slugs(db, 3)
    return PlanSpec(
        name=PLAN_NAME,
        days=(
            training("Upper", SlotSpec(press, fallbacks=(fly,)), SlotSpec(fly)),
            rest(),
            training("Lower", SlotSpec(squat)),
        ),
    )


async def test_template_has_every_packaged_migration(db: AsyncConnection) -> None:
    packaged = {
        item.name
        for item in files("agonez_api.migrations").joinpath("versions").iterdir()
        if item.name.endswith(".sql")
    }
    rows = await (
        await db.execute("SELECT version FROM public.agonez_schema_migrations")
    ).fetchall()

    assert packaged == {row["version"] for row in rows}


async def test_plan_run_mobile_workout_and_overview(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    clock: FrozenClock,
) -> None:
    plan = await make_library_plan(client, await _two_day_plan(db))
    assert [day["workout_unit"] is None for day in plan["days"]] == [False, True, False]

    created = await make_run(client, plan["revision_id"], clock.today, 2)
    sessions = run_sessions(created)
    assert [item["scheduled_date"] for item in sessions] == [
        (clock.today + timedelta(days=offset)).isoformat() for offset in (0, 2, 3, 5)
    ]

    first = sessions[0]
    workout = await finalize_session(client, first["session_id"], clock.today)
    assert workout.result["status"] == "completed"
    assert workout.result["summary"]["prescribed_sets"] == 6
    assert workout.result["summary"]["performed_sets"] == 6

    run_id = created["run"]["plan_run_id"]
    overview = expect(await client.get(f"/api/v1/exec/plan-runs/{run_id}/overview"))
    assert overview["as_of"] == clock.today.isoformat()
    statuses = {item["session_id"]: item["status"] for item in run_sessions(overview)}
    assert statuses.pop(first["session_id"]) == "completed"
    assert set(statuses.values()) == {"scheduled"}

    # Moving the frozen clock moves the service's date-owned transitions.
    clock.today += timedelta(days=3)
    later = expect(await client.get(f"/api/v1/exec/plan-runs/{run_id}/overview"))
    assert [item["status"] for item in run_sessions(later)] == [
        "completed",
        "missed",
        "scheduled",
        "scheduled",
    ]


async def test_each_test_gets_its_own_database(
    client: httpx.AsyncClient,
    db: AsyncConnection,
) -> None:
    # The lifecycle test above creates a plan with this name in its own clone.
    names = [item["name"] for item in expect(await client.get("/api/plans"))["items"]]

    assert PLAN_NAME not in names


async def test_snapshot_tables_detects_only_real_changes(
    client: httpx.AsyncClient,
    db: AsyncConnection,
) -> None:
    tables = await table_names(db, "plans", "exec")
    assert "plans.workout_plans" in tables and "exec.plan_runs" in tables
    before = await snapshot_tables(db, tables)

    expect(await client.get("/api/plans"))
    assert await snapshot_tables(db, tables) == before

    plan = await make_library_plan(client, await _two_day_plan(db))
    after = await snapshot_tables(db, tables)
    assert after["plans.workout_plans"] != before["plans.workout_plans"]
    assert after["exec.plan_runs"] == before["exec.plan_runs"]

    only_new = {"plans.workout_plans": ("row_.id = %s", (plan["id"],))}
    filtered = await snapshot_tables(db, ["plans.workout_plans"], where=only_new)
    assert filtered["plans.workout_plans"].startswith("1:")
    await db.execute(
        "UPDATE plans.workout_plans SET name = 'Renamed' WHERE id = %s",
        (plan["id"],),
    )
    assert await snapshot_tables(db, ["plans.workout_plans"], where=only_new) != filtered
