"""Pre-flight of migration 0019: ``scripts/run_plans_preflight.sql`` (T-PRE-01).

The audit runs against the restored backup *without* pending migrations: the state a human
checks before deploying 0019, so the result keeps its meaning once 0019 exists in the package.

The detection tests prove that "zero rows" is not vacuous. Each builds a small legacy run of
its own with SQL (once runs copy their plan, the application can no longer create one), breaks
it and expects exactly the checks that cover the damage.
"""

from collections.abc import Iterator
from dataclasses import dataclass
from datetime import date, timedelta
from typing import Any
from uuid import uuid4

import psycopg
import pytest
from conftest import (
    INTEGRATION_DIR,
    DatabaseServer,
    _drop_database,
    _dump_owner_roles,
    _dump_path,
    _restore,
)
from psycopg import sql
from psycopg.conninfo import make_conninfo
from psycopg.rows import dict_row

PREFLIGHT_SQL = INTEGRATION_DIR.parents[1] / "scripts" / "run_plans_preflight.sql"
BACKUP_TEMPLATE = "agonez_it_preflight_backup"
STARTS_ON = date(2027, 1, 4)


@pytest.fixture(scope="module")
def backup_template(database_server: DatabaseServer) -> Iterator[str]:
    """The newest dump as it is, with no packaged migration applied on top."""
    dump = _dump_path()
    with database_server.connect_admin() as admin:
        for role in sorted(_dump_owner_roles(dump)):
            if admin.execute("SELECT 1 FROM pg_roles WHERE rolname = %s", (role,)).fetchone():
                continue
            admin.execute(sql.SQL("CREATE ROLE {}").format(sql.Identifier(role)))
        _drop_database(admin, BACKUP_TEMPLATE)
        admin.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(BACKUP_TEMPLATE)))
    try:
        _restore(database_server, dump, BACKUP_TEMPLATE)
        yield BACKUP_TEMPLATE
    finally:
        with database_server.connect_admin() as admin:
            _drop_database(admin, BACKUP_TEMPLATE)


@pytest.fixture
def backup(database_server: DatabaseServer, backup_template: str) -> Iterator[psycopg.Connection]:
    """Autocommit, dict-row connection to a fresh clone of the restored backup."""
    name = f"agonez_it_{uuid4().hex[:12]}"
    with database_server.connect_admin() as admin:
        admin.execute(
            sql.SQL("CREATE DATABASE {} TEMPLATE {}").format(
                sql.Identifier(name), sql.Identifier(backup_template)
            )
        )
    try:
        conninfo = make_conninfo(
            "",
            host="127.0.0.1",
            port=database_server.port,
            user=database_server.user,
            password=database_server.password,
            dbname=name,
            connect_timeout=5,
        )
        with psycopg.connect(conninfo, autocommit=True, row_factory=dict_row) as connection:
            yield connection
    finally:
        with database_server.connect_admin() as admin:
            _drop_database(admin, name)


def run_preflight(connection: psycopg.Connection) -> list[dict[str, Any]]:
    """Run the script as shipped, in a transaction that refuses every write."""
    with connection.transaction():
        connection.execute("SET TRANSACTION READ ONLY")
        # A prepared statement holds exactly one command, so nothing can follow the SELECT.
        return connection.execute(PREFLIGHT_SQL.read_text("utf-8"), prepare=True).fetchall()


def test_t_pre_01_restored_backup_passes_every_check(backup: psycopg.Connection) -> None:
    # Guard against a vacuous pass: the dump must still hold runs that 0019 would convert.
    legacy = backup.execute(
        """
        SELECT count(*) AS total
        FROM exec.plan_runs AS run
        WHERE to_jsonb(run) ->> 'run_plan_id' IS NULL
        """
    ).fetchone()
    assert legacy["total"] > 0

    findings = run_preflight(backup)

    assert findings == [], "\n".join(str(row) for row in findings)


# --- A minimal legacy run --------------------------------------------------------------


def _insert(connection: psycopg.Connection, table: str, **values: Any) -> int:
    query = sql.SQL("INSERT INTO {} ({}) VALUES ({}) RETURNING id").format(
        sql.Identifier(*table.split(".")),
        sql.SQL(", ").join(map(sql.Identifier, values)),
        sql.SQL(", ").join(sql.Placeholder() * len(values)),
    )
    return connection.execute(query, list(values.values())).fetchone()["id"]


@dataclass
class Revision:
    """Row ids by position: ``days[d]``, ``units[d]``, ``slots[d][s]``."""

    id: int
    days: list[int]
    units: list[int]
    slots: list[list[int]]


@dataclass
class LegacyRun:
    """Two microcycles of two training days; day 0 has two slots, day 1 has one.

    Tracks carry positional keys. ``sessions[m][d]`` is microcycle ``m``, day ``d``;
    ``exercise_tracks[d][s]`` is day ``d``, slot ``s``.
    """

    run_id: int
    plan_id: int
    revision: Revision
    exercise_id: int
    microcycles: list[int]
    workout_tracks: list[int]
    exercise_tracks: list[list[int]]
    sessions: list[list[int]]


def _add_slot(connection: psycopg.Connection, unit_id: int, ordinal: int) -> int:
    return _insert(
        connection,
        "plans.exercise_slots",
        workout_unit_id=unit_id,
        ordinal=ordinal,
        role="PRIMARY_PROGRESSIVE",
    )


def _add_day(connection: psycopg.Connection, revision_id: int, ordinal: int) -> tuple[int, int]:
    day = _insert(
        connection,
        "plans.day_prescriptions",
        revision_id=revision_id,
        ordinal=ordinal,
        name=f"Day {ordinal}",
    )
    unit = _insert(
        connection, "plans.workout_unit_prescriptions", day_id=day, name=f"Workout {ordinal}"
    )
    return day, unit


def _add_revision(
    connection: psycopg.Connection,
    plan_id: int,
    revision_no: int,
    **values: Any,
) -> Revision:
    revision_id = _insert(
        connection,
        "plans.plan_revisions",
        plan_id=plan_id,
        revision_no=revision_no,
        **values,
    )
    days, units, slots = [], [], []
    for ordinal, slot_count in enumerate((2, 1)):
        day, unit = _add_day(connection, revision_id, ordinal)
        days.append(day)
        units.append(unit)
        slots.append([_add_slot(connection, unit, index) for index in range(slot_count)])
    return Revision(revision_id, days, units, slots)


@pytest.fixture
def legacy_run(backup: psycopg.Connection) -> LegacyRun:
    plan_id = _insert(backup, "plans.workout_plans", name="Preflight plan")
    revision = _add_revision(backup, plan_id, 1)
    exercise_id = backup.execute("SELECT min(id) AS id FROM core.exercises").fetchone()["id"]
    run_id = _insert(
        backup,
        "exec.plan_runs",
        name="Preflight run",
        initial_plan_revision_id=revision.id,
        starts_on=STARTS_ON,
        microcycle_count=2,
        microcycle_duration_days=2,
    )
    workout_tracks, exercise_tracks = [], []
    for day, slots in enumerate(revision.slots):
        workout_track = _insert(
            backup,
            "exec.workout_unit_tracks",
            plan_run_id=run_id,
            logical_key=f"day:{day}",
            name=f"Workout {day}",
        )
        workout_tracks.append(workout_track)
        exercise_tracks.append(
            [
                _insert(
                    backup,
                    "exec.exercise_unit_tracks",
                    plan_run_id=run_id,
                    workout_unit_track_id=workout_track,
                    logical_key=f"slot:{slot}",
                    name=f"Slot {slot}",
                )
                for slot in range(len(slots))
            ]
        )
    microcycles, sessions = [], []
    for index in range(2):
        starts_on = STARTS_ON + timedelta(days=2 * index)
        microcycle = _insert(
            backup,
            "exec.microcycles",
            plan_run_id=run_id,
            ordinal=index + 1,
            starts_on=starts_on,
            ends_on=starts_on + timedelta(days=1),
            plan_revision_id=revision.id,
        )
        microcycles.append(microcycle)
        sessions.append(
            [
                _insert(
                    backup,
                    "exec.workout_sessions",
                    plan_run_id=run_id,
                    microcycle_id=microcycle,
                    workout_unit_track_id=workout_tracks[day],
                    source_plan_day_id=revision.days[day],
                    source_plan_workout_unit_id=revision.units[day],
                    scheduled_date=starts_on + timedelta(days=day),
                )
                for day in range(2)
            ]
        )
    return LegacyRun(
        run_id=run_id,
        plan_id=plan_id,
        revision=revision,
        exercise_id=exercise_id,
        microcycles=microcycles,
        workout_tracks=workout_tracks,
        exercise_tracks=exercise_tracks,
        sessions=sessions,
    )


def _prescribe(
    connection: psycopg.Connection,
    run: LegacyRun,
    microcycle: int,
    *,
    track_slot: int,
    plan_slot: int,
) -> None:
    """Prescribe a day-0 exercise track in one microcycle from a day-0 plan slot."""
    slot_id = run.revision.slots[0][plan_slot]
    variant = _insert(
        connection,
        "plans.exercise_variants",
        slot_id=slot_id,
        ordinal=microcycle,  # one throwaway variant per call
        variant_type="DEFAULT" if microcycle == 0 else "FALLBACK",
        exercise_id=run.exercise_id,
    )
    workout = _insert(
        connection,
        "exec.workout_unit_prescriptions",
        workout_session_id=run.sessions[microcycle][0],
        source_plan_revision_id=run.revision.id,
        source_plan_workout_unit_id=run.revision.units[0],
        name_snapshot="Workout 0",
    )
    _insert(
        connection,
        "exec.exercise_unit_prescriptions",
        workout_unit_prescription_id=workout,
        exercise_unit_track_id=run.exercise_tracks[0][track_slot],
        ordinal=0,
        source_plan_exercise_slot_id=slot_id,
        source_plan_exercise_variant_id=variant,
        prescribed_exercise_id=run.exercise_id,
        slot_role_snapshot="PRIMARY_PROGRESSIVE",
    )


def _findings(connection: psycopg.Connection, run: LegacyRun) -> set[tuple]:
    """The run's findings as ``(check_no, revision_id, entity_kind, track_ids, entity_ids)``."""
    return {
        (
            row["check_no"],
            row["revision_id"],
            row["entity_kind"],
            tuple(row["track_ids"]),
            tuple(row["entity_ids"]),
        )
        for row in run_preflight(connection)
        if row["plan_run_id"] == run.run_id
    }


# --- Detection -------------------------------------------------------------------------


def test_consistent_legacy_run_passes(backup: psycopg.Connection, legacy_run: LegacyRun) -> None:
    _prescribe(backup, legacy_run, 0, track_slot=0, plan_slot=0)
    _prescribe(backup, legacy_run, 1, track_slot=0, plan_slot=0)

    assert _findings(backup, legacy_run) == set()


def test_check_1_workout_track_bound_to_two_units(
    backup: psycopg.Connection,
    legacy_run: LegacyRun,
) -> None:
    revision = legacy_run.revision
    backup.execute(
        """
        UPDATE exec.workout_sessions
        SET source_plan_day_id = %s, source_plan_workout_unit_id = %s
        WHERE id = %s
        """,
        (revision.days[1], revision.units[1], legacy_run.sessions[1][0]),
    )

    findings = _findings(backup, legacy_run)

    first, second = legacy_run.workout_tracks
    assert (1, revision.id, "workout_unit", (first,), tuple(revision.units)) in findings
    # The same damage contradicts the day key and lets two tracks claim the second unit.
    assert (2, revision.id, "workout_unit", (first,), (revision.units[1],)) in findings
    assert (5, revision.id, "workout_unit", (first, second), (revision.units[1],)) in findings
    assert {item[0] for item in findings} == {1, 2, 5}


@pytest.mark.parametrize("logical_key", ["day:7", "workout-b"])
def test_check_2_sessions_disagree_with_day_key(
    backup: psycopg.Connection,
    legacy_run: LegacyRun,
    logical_key: str,
) -> None:
    track = legacy_run.workout_tracks[1]
    backup.execute(
        "UPDATE exec.workout_unit_tracks SET logical_key = %s WHERE id = %s",
        (logical_key, track),
    )

    # A malformed key is reported once, without a revision.
    revision_id = legacy_run.revision.id if logical_key.startswith("day:") else None
    assert _findings(backup, legacy_run) == {
        (2, revision_id, "workout_unit", (track,), (legacy_run.revision.units[1],))
    }


def test_check_3_exercise_track_prescribed_from_two_slots(
    backup: psycopg.Connection,
    legacy_run: LegacyRun,
) -> None:
    _prescribe(backup, legacy_run, 0, track_slot=0, plan_slot=0)
    _prescribe(backup, legacy_run, 1, track_slot=0, plan_slot=1)

    findings = _findings(backup, legacy_run)

    revision = legacy_run.revision
    first, second = legacy_run.exercise_tracks[0]
    assert (3, revision.id, "exercise_slot", (first,), tuple(revision.slots[0])) in findings
    # The never-prescribed neighbour maps to the second slot by position.
    assert (5, revision.id, "exercise_slot", (first, second), (revision.slots[0][1],)) in findings
    assert {item[0] for item in findings} == {3, 5}


def test_check_4_slot_and_unit_without_track(
    backup: psycopg.Connection,
    legacy_run: LegacyRun,
) -> None:
    revision = legacy_run.revision
    slot = _add_slot(backup, revision.units[0], 2)
    _, unit = _add_day(backup, revision.id, 2)

    assert _findings(backup, legacy_run) == {
        (4, revision.id, "exercise_slot", (), (slot,)),
        (4, revision.id, "workout_unit", (), (unit,)),
    }


def test_check_4_looks_only_at_the_latest_used_revision(
    backup: psycopg.Connection,
    legacy_run: LegacyRun,
) -> None:
    old = legacy_run.revision
    new = _add_revision(backup, legacy_run.plan_id, 2, status="RELEASED", released_at=STARTS_ON)
    backup.execute(
        "UPDATE exec.microcycles SET plan_revision_id = %s WHERE id = %s",
        (new.id, legacy_run.microcycles[1]),
    )
    for day, session_id in enumerate(legacy_run.sessions[1]):
        backup.execute(
            """
            UPDATE exec.workout_sessions
            SET source_plan_day_id = %s, source_plan_workout_unit_id = %s
            WHERE id = %s
            """,
            (new.days[day], new.units[day], session_id),
        )
    # Exercise tracks reach the second revision by position.
    assert _findings(backup, legacy_run) == set()

    _add_slot(backup, old.units[1], 1)
    assert _findings(backup, legacy_run) == set()

    added = _add_slot(backup, new.units[1], 1)
    assert _findings(backup, legacy_run) == {(4, new.id, "exercise_slot", (), (added,))}


@pytest.mark.parametrize("entity_kind", ["workout_unit", "exercise_slot"])
def test_check_5_two_tracks_map_to_one_entity(
    backup: psycopg.Connection,
    legacy_run: LegacyRun,
    entity_kind: str,
) -> None:
    # "00" is a distinct label for the same position 0.
    if entity_kind == "workout_unit":
        original = legacy_run.workout_tracks[0]
        duplicate = _insert(
            backup,
            "exec.workout_unit_tracks",
            plan_run_id=legacy_run.run_id,
            logical_key="day:00",
            name="Duplicate",
        )
        entity = legacy_run.revision.units[0]
    else:
        original = legacy_run.exercise_tracks[0][0]
        duplicate = _insert(
            backup,
            "exec.exercise_unit_tracks",
            plan_run_id=legacy_run.run_id,
            workout_unit_track_id=legacy_run.workout_tracks[0],
            logical_key="slot:00",
            name="Duplicate",
        )
        entity = legacy_run.revision.slots[0][0]

    assert _findings(backup, legacy_run) == {
        (5, legacy_run.revision.id, entity_kind, (original, duplicate), (entity,))
    }


def test_runs_that_already_own_a_run_plan_are_not_audited(
    backup: psycopg.Connection,
    legacy_run: LegacyRun,
) -> None:
    """0019 skips runs with run_plan_id; their empty slots must not block a deploy."""
    _add_slot(backup, legacy_run.revision.units[0], 2)
    assert {item[0] for item in _findings(backup, legacy_run)} == {4}

    # Before migration 0018 the column does not exist; add a bare stand-in for it.
    backup.execute("ALTER TABLE exec.plan_runs ADD COLUMN IF NOT EXISTS run_plan_id integer")
    scoped = backup.execute(
        """
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'plans' AND table_name = 'workout_plans' AND column_name = 'scope'
        """
    ).fetchone()
    if scoped:  # 0018's foreign key only accepts a run-scoped plan.
        backup.execute(
            "UPDATE plans.workout_plans SET scope = 'run' WHERE id = %s",
            (legacy_run.plan_id,),
        )
    backup.execute(
        "UPDATE exec.plan_runs SET run_plan_id = %s WHERE id = %s",
        (legacy_run.plan_id, legacy_run.run_id),
    )

    assert _findings(backup, legacy_run) == set()
