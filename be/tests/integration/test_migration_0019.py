"""Migration 0019: every legacy run gets its own run plan (T2.1, T-MIG-01…09 and -11 of ``07``).

Every test starts from the newest dump that does not record 0019, with the packaged migrations
before it applied (``before_migration``), and then runs 0019 through the real runner, as a deploy
does. Besides the matrix rows: a pre-flight finding or an unmappable reference aborts the
migration with the database unchanged, the embedded pre-flight is the shipped script, and the
demo seed refuses to run afterwards (Q5).

Facts of the dumps the run-specific tests rely on (2026-11-25 and 2026-11-28): the legacy runs
are 1, 2, 3, 5, 11, 14 and 17; run 1 uses library revision 6 in microcycles 1-3 and revision 25
(the demo seed's RELEASED revision of plan 6) in microcycles 4-8, with a ``plan_revision_changed``
event from 6 to 25; runs 3 and 14 share revision 15 (plan 15), runs 2 and 11 revision 17.
"""

import time
from dataclasses import dataclass, replace
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from uuid import uuid4

import httpx
import psycopg
import pytest
from builders import (
    DEVICE_ID,
    PlanSpec,
    SlotSpec,
    exercise_slugs,
    expect,
    make_library_plan,
    rest,
    snapshot_tables,
    table_names,
    training,
)
from conftest import (
    INTEGRATION_DIR,
    RUN_PLAN_CONVERSION,
    FrozenClock,
    _packaged_migrations,
    apply_migrations,
)
from plan_trees import Tree, bodies, read_tree
from psycopg import AsyncConnection, errors, sql
from test_plan_scope import bind_to_new_run, make_run_plan

from agonez_api.core.config import Settings
from agonez_api.modules.plans.fingerprint import definition_fingerprint
from agonez_api.modules.plans.repository import load_revision_rows

pytestmark = pytest.mark.before_migration(RUN_PLAN_CONVERSION)

PREFLIGHT_SQL = INTEGRATION_DIR.parents[1] / "scripts" / "run_plans_preflight.sql"
SEED_SQL = (
    _packaged_migrations()[RUN_PLAN_CONVERSION].parents[1] / "seeds" / "0001_execution_demo.sql"
)
DEVICE_HEADERS = {"X-Agonez-Device-Id": str(DEVICE_ID)}

# exec reference columns F1-F13 (audit §4) and the reference-map entity each one points at.
REMAPPED: dict[str, dict[str, str]] = {
    "exec.plan_runs": {"initial_plan_revision_id": "plan_revision"},
    "exec.microcycles": {"plan_revision_id": "plan_revision"},
    "exec.workout_sessions": {
        "source_plan_day_id": "day",
        "source_plan_workout_unit_id": "workout_unit",
        "fallback_source_plan_workout_unit_id": "workout_unit",
    },
    "exec.workout_unit_prescriptions": {
        "source_plan_revision_id": "plan_revision",
        "source_plan_workout_unit_id": "workout_unit",
    },
    "exec.exercise_unit_prescriptions": {
        "source_plan_exercise_slot_id": "exercise_slot",
        "source_plan_exercise_variant_id": "exercise_variant",
    },
    "exec.set_prescriptions": {"source_plan_set_infra_id": "set_infra"},
    "exec.exercise_unit_performances": {"actual_plan_exercise_variant_id": "exercise_variant"},
    "exec.plan_run_events": {
        "from_plan_revision_id": "plan_revision",
        "to_plan_revision_id": "plan_revision",
    },
}
# Columns 0019 fills in; NULL before.
ADDED: dict[str, tuple[str, ...]] = {
    "exec.plan_runs": ("run_plan_id",),
    "exec.workout_unit_tracks": ("plan_lineage_key",),
    "exec.exercise_unit_tracks": ("plan_lineage_key",),
}
_SESSION_OF_WORKOUT = (
    "(SELECT ws.plan_run_id FROM exec.workout_unit_prescriptions AS wup"
    " JOIN exec.workout_sessions AS ws ON ws.id = wup.workout_session_id"
    " WHERE wup.id = {})"
)
# The run each row belongs to (the migration remaps along the same ownership chain).
RUN_OF: dict[str, str] = {
    "exec.plan_runs": "row_.id",
    "exec.microcycles": "row_.plan_run_id",
    "exec.workout_unit_tracks": "row_.plan_run_id",
    "exec.exercise_unit_tracks": "row_.plan_run_id",
    "exec.workout_sessions": "row_.plan_run_id",
    "exec.plan_run_events": "row_.plan_run_id",
    "exec.workout_unit_prescriptions": (
        "(SELECT ws.plan_run_id FROM exec.workout_sessions AS ws"
        " WHERE ws.id = row_.workout_session_id)"
    ),
    "exec.exercise_unit_prescriptions": _SESSION_OF_WORKOUT.format(
        "row_.workout_unit_prescription_id"
    ),
    "exec.set_prescriptions": _SESSION_OF_WORKOUT.format(
        "(SELECT eup.workout_unit_prescription_id FROM exec.exercise_unit_prescriptions AS eup"
        " WHERE eup.id = row_.exercise_unit_prescription_id)"
    ),
    "exec.exercise_unit_performances": _SESSION_OF_WORKOUT.format(
        "(SELECT wupf.workout_unit_prescription_id FROM exec.workout_unit_performances AS wupf"
        " WHERE wupf.id = row_.workout_unit_performance_id)"
    ),
}

_LIBRARY_PLANS = "(SELECT id FROM plans.workout_plans WHERE scope = 'library')"
_LIBRARY_REVISIONS = f"(SELECT id FROM plans.plan_revisions WHERE plan_id IN {_LIBRARY_PLANS})"
_LIBRARY_DAYS = (
    f"(SELECT id FROM plans.day_prescriptions WHERE revision_id IN {_LIBRARY_REVISIONS})"
)
_LIBRARY_UNITS = (
    f"(SELECT id FROM plans.workout_unit_prescriptions WHERE day_id IN {_LIBRARY_DAYS})"
)
_LIBRARY_SLOTS = f"(SELECT id FROM plans.exercise_slots WHERE workout_unit_id IN {_LIBRARY_UNITS})"
_LIBRARY_VARIANTS = f"(SELECT id FROM plans.exercise_variants WHERE slot_id IN {_LIBRARY_SLOTS})"
# The rows of library plans in every plans table.
LIBRARY_ROWS: dict[str, tuple[str, tuple[Any, ...]]] = {
    "plans.workout_plans": ("row_.scope = 'library'", ()),
    "plans.plan_images": (f"row_.plan_id IN {_LIBRARY_PLANS}", ()),
    "plans.plan_revisions": (f"row_.plan_id IN {_LIBRARY_PLANS}", ()),
    "plans.day_prescriptions": (f"row_.revision_id IN {_LIBRARY_REVISIONS}", ()),
    "plans.workout_unit_prescriptions": (f"row_.day_id IN {_LIBRARY_DAYS}", ()),
    "plans.exercise_slots": (f"row_.workout_unit_id IN {_LIBRARY_UNITS}", ()),
    "plans.exercise_slot_target_muscles": (f"row_.slot_id IN {_LIBRARY_SLOTS}", ()),
    "plans.exercise_variants": (f"row_.slot_id IN {_LIBRARY_SLOTS}", ()),
    "plans.set_infra_prescriptions": (f"row_.exercise_variant_id IN {_LIBRARY_VARIANTS}", ()),
}

Rows = dict[str, dict[int, tuple[int, dict[str, Any]]]]
ReferenceMap = dict[tuple[int, str, int], int]


# --- Helpers --------------------------------------------------------------------------------


async def convert(settings: Settings, tmp_path: Path) -> float:
    """Run 0019 with the real runner; returns the seconds the runner took."""
    started = time.perf_counter()
    await apply_migrations(
        settings, tmp_path / f"versions_{uuid4().hex[:8]}", through=RUN_PLAN_CONVERSION
    )
    return time.perf_counter() - started


async def fetch_all(db: AsyncConnection, query: str, *params: Any) -> list[dict[str, Any]]:
    return await (await db.execute(query, params or None)).fetchall()


async def legacy_run_ids(db: AsyncConnection) -> list[int]:
    rows = await fetch_all(
        db, "SELECT id FROM exec.plan_runs WHERE run_plan_id IS NULL ORDER BY id"
    )
    return [row["id"] for row in rows]


async def exec_rows(db: AsyncConnection) -> Rows:
    """Every row of the exec tables that hold F1-F13 or tracks, with the run it belongs to."""
    rows: Rows = {}
    for table, run_of in RUN_OF.items():
        query = sql.SQL(
            "SELECT row_.id, {run} AS plan_run_id, to_jsonb(row_) AS row FROM {table} AS row_"
        ).format(run=sql.SQL(run_of), table=sql.Identifier(*table.split(".")))
        fetched = await (await db.execute(query)).fetchall()
        rows[table] = {row["id"]: (row["plan_run_id"], row["row"]) for row in fetched}
    return rows


async def reference_map(db: AsyncConnection) -> ReferenceMap:
    rows = await fetch_all(
        db,
        "SELECT plan_run_id, entity, library_id, run_plan_id FROM public.agonez_0019_reference_map",
    )
    return {
        (row["plan_run_id"], row["entity"], row["library_id"]): row["run_plan_id"] for row in rows
    }


async def run_plan_revisions(db: AsyncConnection, run_id: int) -> list[dict[str, Any]]:
    return await fetch_all(
        db,
        """
        SELECT rev.id, rev.revision_no, rev.status::text AS status, rev.based_on_revision_id,
               rev.released_at, rev.plan_id
        FROM exec.plan_runs AS pr
        JOIN plans.plan_revisions AS rev ON rev.plan_id = pr.run_plan_id
        WHERE pr.id = %s
        ORDER BY rev.revision_no
        """,
        run_id,
    )


async def library_revision_ids(db: AsyncConnection) -> list[int]:
    rows = await fetch_all(
        db,
        f"SELECT id FROM plans.plan_revisions WHERE plan_id IN {_LIBRARY_PLANS} ORDER BY id",
    )
    return [row["id"] for row in rows]


def without_lineage(tree: Tree) -> dict[str, Any]:
    return bodies(tree, without=("lineage_key",))


async def whole_database(db: AsyncConnection) -> dict[str, str]:
    """Snapshot of every plans, exec and public table, plus the recorded migrations."""
    return await snapshot_tables(db, await table_names(db, "plans", "exec", "public"))


async def exec_tables_without_references(db: AsyncConnection) -> list[str]:
    return sorted(set(await table_names(db, "exec")) - set(RUN_OF))


@dataclass(frozen=True)
class Converted:
    """A converted clone and what it held before."""

    legacy_runs: list[int]
    before: Rows
    other_exec_tables: dict[str, str]
    library_tables: dict[str, str]
    library_trees: dict[int, Tree]
    fingerprints: dict[int, str]
    seconds: float = 0.0


@pytest.fixture
async def converted(db: AsyncConnection, settings: Settings, tmp_path: Path) -> Converted:
    legacy = await legacy_run_ids(db)
    assert legacy, "the dump holds no legacy run"
    assert set(await table_names(db, "plans")) == set(LIBRARY_ROWS), "a plans table is missing"
    revisions = await library_revision_ids(db)
    state = Converted(
        legacy_runs=legacy,
        before=await exec_rows(db),
        other_exec_tables=await snapshot_tables(db, await exec_tables_without_references(db)),
        library_tables=await snapshot_tables(db, list(LIBRARY_ROWS), where=LIBRARY_ROWS),
        library_trees={revision: await read_tree(db, revision) for revision in revisions},
        fingerprints={
            revision: definition_fingerprint(await load_revision_rows(db, revision))
            for revision in revisions
        },
    )
    return replace(state, seconds=await convert(settings, tmp_path))


# --- T-MIG-01 … T-MIG-09 ----------------------------------------------------------------------


async def test_mig_01_every_run_owns_a_run_plan_with_one_draft(
    db: AsyncConnection, converted: Converted
) -> None:
    """T-MIG-01, plus the constraints of ``02`` §1.2 and the migration's duration."""
    runs = await fetch_all(
        db,
        """
        SELECT pr.id, wp.scope::text AS scope,
               count(*) FILTER (WHERE rev.status = 'DRAFT') AS drafts,
               count(*) FILTER (WHERE rev.status = 'RELEASED') AS applied
        FROM exec.plan_runs AS pr
        JOIN plans.workout_plans AS wp ON wp.id = pr.run_plan_id
        JOIN plans.plan_revisions AS rev ON rev.plan_id = wp.id
        GROUP BY pr.id, wp.scope
        ORDER BY pr.id
        """,
    )
    assert set(converted.legacy_runs) <= {row["id"] for row in runs}
    assert len(runs) == len(await fetch_all(db, "SELECT id FROM exec.plan_runs"))
    assert all(row["scope"] == "run" and row["drafts"] == 1 for row in runs), runs
    assert all(row["applied"] >= 1 for row in runs), runs
    # The draft is always the newest revision.
    for run_id in converted.legacy_runs:
        revisions = await run_plan_revisions(db, run_id)
        assert [row["revision_no"] for row in revisions] == list(range(1, len(revisions) + 1))
        assert [row["status"] for row in revisions] == ["RELEASED"] * (len(revisions) - 1) + [
            "DRAFT"
        ]

    columns = await fetch_all(
        db,
        """
        SELECT attrelid::regclass::text AS tbl, attname, attnotnull
        FROM pg_attribute
        WHERE (attrelid, attname) IN (('exec.plan_runs'::regclass, 'run_plan_id'),
                                      ('exec.workout_unit_tracks'::regclass, 'plan_lineage_key'),
                                      ('exec.exercise_unit_tracks'::regclass, 'plan_lineage_key'))
        """,
    )
    assert len(columns) == 3 and all(row["attnotnull"] for row in columns), columns
    constraints = await fetch_all(
        db,
        """
        SELECT conname, pg_get_constraintdef(oid) AS definition FROM pg_constraint
        WHERE conname IN ('workout_unit_tracks_run_lineage_unique',
                          'exercise_unit_tracks_workout_lineage_unique')
        ORDER BY conname
        """,
    )
    assert [(row["conname"], row["definition"]) for row in constraints] == [
        (
            "exercise_unit_tracks_workout_lineage_unique",
            "UNIQUE (workout_unit_track_id, plan_lineage_key)",
        ),
        ("workout_unit_tracks_run_lineage_unique", "UNIQUE (plan_run_id, plan_lineage_key)"),
    ]
    recorded = await fetch_all(
        db, "SELECT 1 FROM public.agonez_schema_migrations WHERE version = %s", RUN_PLAN_CONVERSION
    )
    assert len(recorded) == 1
    # The API's statement_timeout is 10 s; on the dumps the runner needs well under a second.
    assert converted.seconds < 5, converted.seconds


async def test_mig_02_no_reference_reaches_a_library_plan(
    db: AsyncConnection, converted: Converted
) -> None:
    """T-MIG-02 (I1): every F1-F13 reference points into the run's own run plan."""
    plan_of = {
        "plan_revision": "SELECT plan_id FROM plans.plan_revisions WHERE id = {}",
        "day": (
            "SELECT rev.plan_id FROM plans.day_prescriptions AS dp"
            " JOIN plans.plan_revisions AS rev ON rev.id = dp.revision_id WHERE dp.id = {}"
        ),
        "workout_unit": (
            "SELECT rev.plan_id FROM plans.workout_unit_prescriptions AS wu"
            " JOIN plans.day_prescriptions AS dp ON dp.id = wu.day_id"
            " JOIN plans.plan_revisions AS rev ON rev.id = dp.revision_id WHERE wu.id = {}"
        ),
        "exercise_slot": (
            "SELECT rev.plan_id FROM plans.exercise_slots AS es"
            " JOIN plans.workout_unit_prescriptions AS wu ON wu.id = es.workout_unit_id"
            " JOIN plans.day_prescriptions AS dp ON dp.id = wu.day_id"
            " JOIN plans.plan_revisions AS rev ON rev.id = dp.revision_id WHERE es.id = {}"
        ),
        "exercise_variant": (
            "SELECT rev.plan_id FROM plans.exercise_variants AS ev"
            " JOIN plans.exercise_slots AS es ON es.id = ev.slot_id"
            " JOIN plans.workout_unit_prescriptions AS wu ON wu.id = es.workout_unit_id"
            " JOIN plans.day_prescriptions AS dp ON dp.id = wu.day_id"
            " JOIN plans.plan_revisions AS rev ON rev.id = dp.revision_id WHERE ev.id = {}"
        ),
        "set_infra": (
            "SELECT rev.plan_id FROM plans.set_infra_prescriptions AS si"
            " JOIN plans.exercise_variants AS ev ON ev.id = si.exercise_variant_id"
            " JOIN plans.exercise_slots AS es ON es.id = ev.slot_id"
            " JOIN plans.workout_unit_prescriptions AS wu ON wu.id = es.workout_unit_id"
            " JOIN plans.day_prescriptions AS dp ON dp.id = wu.day_id"
            " JOIN plans.plan_revisions AS rev ON rev.id = dp.revision_id WHERE si.id = {}"
        ),
    }
    checked = 0
    for table, columns in REMAPPED.items():
        for column, entity in columns.items():
            query = sql.SQL(
                """
                SELECT row_.id, {run} AS plan_run_id, pr.run_plan_id,
                       ({plan_of}) AS referenced_plan_id,
                       (SELECT wp.scope::text FROM plans.workout_plans AS wp
                        WHERE wp.id = ({plan_of})) AS referenced_scope
                FROM {table} AS row_
                JOIN exec.plan_runs AS pr ON pr.id = {run}
                WHERE row_.{column} IS NOT NULL
                """
            ).format(
                run=sql.SQL(RUN_OF[table]),
                plan_of=sql.SQL(plan_of[entity].format(f"row_.{column}")),
                table=sql.Identifier(*table.split(".")),
                column=sql.Identifier(column),
            )
            rows = await (await db.execute(query)).fetchall()
            checked += len(rows)
            wrong = [row for row in rows if row["referenced_plan_id"] != row["run_plan_id"]]
            assert wrong == [], (table, column, wrong[:5])
            assert {row["referenced_scope"] for row in rows} <= {"run"}, (table, column)
    assert checked > 2000  # 3 443 on the 2026-11-28 dump


async def test_mig_03_sessions_bind_to_applied_revisions_of_their_run_plan(
    db: AsyncConnection, converted: Converted
) -> None:
    """T-MIG-03; the bound unit is the source day's unit, as before."""
    sessions = await fetch_all(
        db,
        """
        SELECT ws.id, rev.status::text AS status, rev.plan_id = pr.run_plan_id AS own_plan,
               wu.day_id = ws.source_plan_day_id AS unit_on_day
        FROM exec.workout_sessions AS ws
        JOIN exec.plan_runs AS pr ON pr.id = ws.plan_run_id
        JOIN plans.day_prescriptions AS dp ON dp.id = ws.source_plan_day_id
        JOIN plans.plan_revisions AS rev ON rev.id = dp.revision_id
        JOIN plans.workout_unit_prescriptions AS wu ON wu.id = ws.source_plan_workout_unit_id
        """,
    )
    assert len(sessions) == len(converted.before["exec.workout_sessions"])
    bad = [
        row
        for row in sessions
        if (row["status"], row["own_plan"], row["unit_on_day"]) != ("RELEASED", True, True)
    ]
    assert bad == []


async def test_mig_04_run_1_applies_library_revisions_6_and_25(
    db: AsyncConnection, converted: Converted
) -> None:
    """T-MIG-04."""
    first, second, draft = await run_plan_revisions(db, 1)
    utc = timezone.utc
    assert (first["revision_no"], first["status"], first["based_on_revision_id"]) == (
        1,
        "RELEASED",
        6,
    )
    assert first["released_at"] == datetime(2026, 9, 1, tzinfo=utc)  # microcycle 1
    assert (second["revision_no"], second["status"], second["based_on_revision_id"]) == (
        2,
        "RELEASED",
        first["id"],
    )
    assert second["released_at"] == datetime(2026, 9, 22, tzinfo=utc)  # microcycle 4
    assert (draft["revision_no"], draft["status"], draft["based_on_revision_id"]) == (
        3,
        "DRAFT",
        second["id"],
    )
    plan = (
        await fetch_all(
            db,
            """
            SELECT wp.name, wp.description, wp.accent::text AS accent, wp.source_plan_id,
                   img.checksum
            FROM plans.workout_plans AS wp
            LEFT JOIN plans.plan_images AS img ON img.plan_id = wp.id
            WHERE wp.id = %s
            """,
            first["plan_id"],
        )
    )[0]
    library = (
        await fetch_all(
            db,
            """
            SELECT wp.name, wp.description, wp.accent::text AS accent, wp.id AS source_plan_id,
                   img.checksum
            FROM plans.workout_plans AS wp
            LEFT JOIN plans.plan_images AS img ON img.plan_id = wp.id
            WHERE wp.id = 6
            """,
        )
    )[0]
    assert plan == library and plan["checksum"] is not None

    # Copies of the library revisions as they are now; only the lineage keys are the run's own.
    first_tree, second_tree = await read_tree(db, first["id"]), await read_tree(db, second["id"])
    assert without_lineage(first_tree) == without_lineage(converted.library_trees[6])
    assert without_lineage(second_tree) == without_lineage(converted.library_trees[25])
    assert bodies(await read_tree(db, draft["id"])) == bodies(second_tree)

    microcycles = await fetch_all(
        db,
        """
        SELECT ordinal, plan_revision_id FROM exec.microcycles
        WHERE plan_run_id = 1 ORDER BY ordinal
        """,
    )
    assert [(row["ordinal"], row["plan_revision_id"]) for row in microcycles] == [
        (ordinal, first["id"] if ordinal <= 3 else second["id"]) for ordinal in range(1, 9)
    ]
    sessions = await fetch_all(
        db,
        """
        SELECT DISTINCT mc.ordinal, dp.revision_id
        FROM exec.workout_sessions AS ws
        JOIN exec.microcycles AS mc ON mc.id = ws.microcycle_id
        JOIN plans.day_prescriptions AS dp ON dp.id = ws.source_plan_day_id
        WHERE ws.plan_run_id = 1
        ORDER BY mc.ordinal
        """,
    )
    assert [(row["ordinal"], row["revision_id"]) for row in sessions] == [
        (row["ordinal"], row["plan_revision_id"]) for row in microcycles
    ]
    events = await fetch_all(
        db,
        """
        SELECT from_plan_revision_id, to_plan_revision_id FROM exec.plan_run_events
        WHERE plan_run_id = 1 AND event_type = 'plan_revision_changed'
        """,
    )
    assert events == [{"from_plan_revision_id": first["id"], "to_plan_revision_id": second["id"]}]
    run = (await fetch_all(db, "SELECT initial_plan_revision_id FROM exec.plan_runs WHERE id = 1"))[
        0
    ]
    assert run["initial_plan_revision_id"] == first["id"]


@pytest.mark.parametrize(("runs", "library_revision"), [((3, 14), 15), ((2, 11), 17)])
async def test_mig_05_runs_sharing_a_library_revision_own_distinct_run_plans(
    db: AsyncConnection,
    converted: Converted,
    runs: tuple[int, int],
    library_revision: int,
) -> None:
    """T-MIG-05: two independent copies with their own lineage."""
    left, right = [await run_plan_revisions(db, run_id) for run_id in runs]
    assert left[0]["plan_id"] != right[0]["plan_id"]
    assert {row["id"] for row in left}.isdisjoint(row["id"] for row in right)
    trees = [await read_tree(db, revisions[0]["id"]) for revisions in (left, right)]
    library = without_lineage(converted.library_trees[library_revision])
    assert all(without_lineage(tree) == library for tree in trees)
    keys = [
        {
            node.body["lineage_key"]
            for entity in ("workout_unit", "exercise_slot")
            for node in tree[entity].values()
        }
        for tree in trees
    ]
    assert keys[0].isdisjoint(keys[1])


async def test_mig_06_tracks_carry_lineage_keys_that_follow_their_bindings(
    db: AsyncConnection, converted: Converted
) -> None:
    """T-MIG-06: keys on every track, unique per revision, matching bound and positional rows."""
    tracks = await fetch_all(
        db,
        """
        SELECT 'workout' AS kind, id, plan_run_id, logical_key, plan_lineage_key
        FROM exec.workout_unit_tracks
        UNION ALL
        SELECT 'exercise', id, plan_run_id, logical_key, plan_lineage_key
        FROM exec.exercise_unit_tracks
        """,
    )
    assert tracks and all(row["plan_lineage_key"] is not None for row in tracks)

    violations = {
        "repeated unit key in a revision": """
            SELECT dp.revision_id, wu.lineage_key FROM plans.workout_unit_prescriptions AS wu
            JOIN plans.day_prescriptions AS dp ON dp.id = wu.day_id
            GROUP BY 1, 2 HAVING count(*) > 1
        """,
        "repeated slot key in a revision": """
            SELECT dp.revision_id, es.lineage_key FROM plans.exercise_slots AS es
            JOIN plans.workout_unit_prescriptions AS wu ON wu.id = es.workout_unit_id
            JOIN plans.day_prescriptions AS dp ON dp.id = wu.day_id
            GROUP BY 1, 2 HAVING count(*) > 1
        """,
        "session bound to a unit of another lineage": """
            SELECT ws.id FROM exec.workout_sessions AS ws
            JOIN exec.workout_unit_tracks AS wt ON wt.id = ws.workout_unit_track_id
            JOIN plans.workout_unit_prescriptions AS wu ON wu.id = ws.source_plan_workout_unit_id
            WHERE wu.lineage_key <> wt.plan_lineage_key
        """,
        "prescription bound to a slot of another lineage": """
            SELECT eup.id FROM exec.exercise_unit_prescriptions AS eup
            JOIN exec.exercise_unit_tracks AS et ON et.id = eup.exercise_unit_track_id
            JOIN plans.exercise_slots AS es ON es.id = eup.source_plan_exercise_slot_id
            WHERE es.lineage_key <> et.plan_lineage_key
        """,
        # Positional identity, bound or not (no drift in the dumps): day:N in every revision of
        # the run plan is the track's unit, slot:N under it the exercise track's slot.
        "unit at the track's day position with another key": """
            SELECT wt.id, rev.id FROM exec.workout_unit_tracks AS wt
            JOIN exec.plan_runs AS pr ON pr.id = wt.plan_run_id
            JOIN plans.plan_revisions AS rev ON rev.plan_id = pr.run_plan_id
            JOIN plans.day_prescriptions AS dp
              ON dp.revision_id = rev.id AND 'day:' || dp.ordinal = wt.logical_key
            JOIN plans.workout_unit_prescriptions AS wu ON wu.day_id = dp.id
            WHERE wu.lineage_key <> wt.plan_lineage_key
        """,
        "slot at the track's slot position with another key": """
            SELECT et.id, rev.id FROM exec.exercise_unit_tracks AS et
            JOIN exec.workout_unit_tracks AS wt ON wt.id = et.workout_unit_track_id
            JOIN exec.plan_runs AS pr ON pr.id = wt.plan_run_id
            JOIN plans.plan_revisions AS rev ON rev.plan_id = pr.run_plan_id
            JOIN plans.day_prescriptions AS dp
              ON dp.revision_id = rev.id AND 'day:' || dp.ordinal = wt.logical_key
            JOIN plans.workout_unit_prescriptions AS wu ON wu.day_id = dp.id
            JOIN plans.exercise_slots AS es
              ON es.workout_unit_id = wu.id AND 'slot:' || es.ordinal = et.logical_key
            WHERE es.lineage_key <> et.plan_lineage_key
        """,
        # Full coverage, which the dumps have: every unit and slot of every revision of a run plan
        # belongs to a track of the run (the slot to an exercise track of its unit's track).
        "unit without a track": """
            SELECT wu.id FROM plans.workout_unit_prescriptions AS wu
            JOIN plans.day_prescriptions AS dp ON dp.id = wu.day_id
            JOIN plans.plan_revisions AS rev ON rev.id = dp.revision_id
            JOIN exec.plan_runs AS pr ON pr.run_plan_id = rev.plan_id
            WHERE NOT EXISTS (
                SELECT 1 FROM exec.workout_unit_tracks AS wt
                WHERE wt.plan_run_id = pr.id AND wt.plan_lineage_key = wu.lineage_key
            )
        """,
        "slot without a track": """
            SELECT es.id FROM plans.exercise_slots AS es
            JOIN plans.workout_unit_prescriptions AS wu ON wu.id = es.workout_unit_id
            JOIN plans.day_prescriptions AS dp ON dp.id = wu.day_id
            JOIN plans.plan_revisions AS rev ON rev.id = dp.revision_id
            JOIN exec.plan_runs AS pr ON pr.run_plan_id = rev.plan_id
            WHERE NOT EXISTS (
                SELECT 1 FROM exec.exercise_unit_tracks AS et
                JOIN exec.workout_unit_tracks AS wt ON wt.id = et.workout_unit_track_id
                WHERE wt.plan_run_id = pr.id AND wt.plan_lineage_key = wu.lineage_key
                  AND et.plan_lineage_key = es.lineage_key
            )
        """,
    }
    for name, query in violations.items():
        assert await fetch_all(db, query) == [], name

    # Labels stay positional (the pre-T3.1 code parses them); the draft inherits the lineage.
    assert all(
        row["logical_key"].startswith("day:" if row["kind"] == "workout" else "slot:")
        for row in tracks
    )
    for run_id in converted.legacy_runs:
        revisions = await run_plan_revisions(db, run_id)
        last_applied, draft = revisions[-2], revisions[-1]
        assert bodies(await read_tree(db, draft["id"])) == bodies(
            await read_tree(db, last_applied["id"])
        )


async def test_mig_07_library_plans_are_untouched_and_deletable(
    db: AsyncConnection, client: httpx.AsyncClient, converted: Converted
) -> None:
    """T-MIG-07: no library row changed (updated_at, lineage keys included); all deletable."""
    after = await snapshot_tables(db, list(LIBRARY_ROWS), where=LIBRARY_ROWS)
    assert after == converted.library_tables
    revisions = await library_revision_ids(db)
    assert revisions == sorted(converted.fingerprints)
    for revision in revisions:
        assert await read_tree(db, revision) == converted.library_trees[revision]
        fingerprint = definition_fingerprint(await load_revision_rows(db, revision))
        assert fingerprint == converted.fingerprints[revision], revision

    plans = await fetch_all(db, f"SELECT id FROM plans.workout_plans WHERE id IN {_LIBRARY_PLANS}")
    assert 15 in {row["id"] for row in plans}
    for plan in plans:
        async with db.transaction(force_rollback=True):
            await db.execute("DELETE FROM plans.workout_plans WHERE id = %s", (plan["id"],))
    # Through the API too: plan 15 (runs 3 and 14) goes, its runs stay readable.
    expect(await client.delete("/api/plans/15"), 204)
    for run_id in (3, 14):
        expect(await client.get(f"/api/v1/exec/plan-runs/{run_id}/overview"))
    copies = await fetch_all(
        db,
        """
        SELECT wp.source_plan_id, rev.based_on_revision_id FROM exec.plan_runs AS pr
        JOIN plans.workout_plans AS wp ON wp.id = pr.run_plan_id
        JOIN plans.plan_revisions AS rev ON rev.plan_id = wp.id AND rev.revision_no = 1
        WHERE pr.id IN (3, 14)
        """,
    )
    assert copies == [{"source_plan_id": None, "based_on_revision_id": None}] * 2


async def test_mig_08_history_is_unchanged_apart_from_the_remapped_references(
    db: AsyncConnection, converted: Converted
) -> None:
    """T-MIG-08: same rows, same values; references moved along the id maps, nothing else."""
    after = await exec_rows(db)
    mapping = await reference_map(db)
    for table, rows in converted.before.items():
        assert after[table].keys() == rows.keys(), table
        remapped = REMAPPED.get(table, {})
        ignored = set(remapped) | set(ADDED.get(table, ()))
        for row_id, (run_id, row) in rows.items():
            after_run, after_row = after[table][row_id]
            assert after_run == run_id
            assert {k: v for k, v in after_row.items() if k not in ignored} == {
                k: v for k, v in row.items() if k not in ignored
            }, (table, row_id)
            for column in ADDED.get(table, ()):
                assert row[column] is None and after_row[column] is not None, (table, column)
            for column, entity in remapped.items():
                expected = None if row[column] is None else mapping[(run_id, entity, row[column])]
                assert after_row[column] == expected, (table, row_id, column)

    # Tables without plan references are unchanged row for row.
    others = await exec_tables_without_references(db)
    assert others == [
        "exec.exercise_setup_notes",
        "exec.mobile_sync_ops",
        "exec.set_performances",
        "exec.workout_unit_performances",
    ]
    assert await snapshot_tables(db, others) == converted.other_exec_tables


async def test_mig_09_reference_map_covers_every_remapped_id(
    db: AsyncConnection, converted: Converted
) -> None:
    """T-MIG-09: every remapped reference is in the map; the map is the complete copy maps."""
    mapping = await reference_map(db)
    used: set[tuple[int, str, int]] = set()
    for table, columns in REMAPPED.items():
        for run_id, row in converted.before[table].values():
            for column, entity in columns.items():
                if row[column] is not None:
                    used.add((run_id, entity, row[column]))
    assert used <= mapping.keys()

    for run_id in converted.legacy_runs:
        revisions = await run_plan_revisions(db, run_id)
        applied = [row for row in revisions if row["status"] == "RELEASED"]
        sources = {
            library_id: target
            for (run, entity, library_id), target in mapping.items()
            if run == run_id and entity == "plan_revision"
        }
        assert sorted(sources.values()) == [row["id"] for row in applied]
        plan_entry = {
            target
            for (run, entity, _), target in mapping.items()
            if run == run_id and entity == "workout_plan"
        }
        assert plan_entry == {applied[0]["plan_id"]}
        for library_revision, applied_revision in sources.items():
            source = converted.library_trees[library_revision]
            target = await read_tree(db, applied_revision)
            for entity in ("day", "workout_unit", "exercise_slot", "exercise_variant", "set_infra"):
                pairs = {
                    (node.id, target[entity][path].id) for path, node in source[entity].items()
                }
                sources_ids = {library_id for library_id, _ in pairs}
                entries = {
                    (library_id, copy)
                    for (run, kind, library_id), copy in mapping.items()
                    if run == run_id and kind == entity and library_id in sources_ids
                }
                assert entries == pairs, (run_id, library_revision, entity)
    assert {entity for (_, entity, _) in mapping} == {
        "workout_plan",
        "plan_revision",
        "day",
        "workout_unit",
        "exercise_slot",
        "exercise_variant",
        "set_infra",
    }


# --- T-MIG-11 ---------------------------------------------------------------------------------


async def t22_style_run(
    client: httpx.AsyncClient, db: AsyncConnection, clock: FrozenClock
) -> tuple[int, int]:
    """A run as T2.2's creation leaves it: run plan r1/r2, bound to r1, keyed tracks.

    Built by SQL from a run of today's creation (T2.2 is not on this branch); after the rebase
    onto T2.2, create it through the API instead.
    """
    press, row, squat = await exercise_slugs(db, 3)
    library = await make_library_plan(
        client,
        PlanSpec(
            name="T2.2 style plan",
            days=(
                training("Upper", SlotSpec(press), SlotSpec(row)),
                rest(),
                training("Lower", SlotSpec(squat)),
            ),
        ),
    )
    run_plan = await make_run_plan(db, library)
    run_id = await bind_to_new_run(client, db, library, run_plan, clock)
    first = run_plan.released_id
    await db.execute(
        "UPDATE exec.plan_runs SET initial_plan_revision_id = %s WHERE id = %s", (first, run_id)
    )
    await db.execute(
        "UPDATE exec.microcycles SET plan_revision_id = %s WHERE plan_run_id = %s", (first, run_id)
    )
    await db.execute(
        """
        UPDATE exec.workout_sessions AS ws
        SET source_plan_day_id = copy_day.id, source_plan_workout_unit_id = copy_unit.id
        FROM plans.day_prescriptions AS old_day, plans.day_prescriptions AS copy_day,
             plans.workout_unit_prescriptions AS copy_unit
        WHERE ws.plan_run_id = %(run)s AND old_day.id = ws.source_plan_day_id
          AND copy_day.revision_id = %(revision)s AND copy_day.ordinal = old_day.ordinal
          AND copy_unit.day_id = copy_day.id
        """,
        {"run": run_id, "revision": first},
    )
    await db.execute(
        """
        UPDATE exec.workout_unit_tracks AS wt SET plan_lineage_key = wu.lineage_key
        FROM plans.day_prescriptions AS dp
        JOIN plans.workout_unit_prescriptions AS wu ON wu.day_id = dp.id
        WHERE wt.plan_run_id = %(run)s AND dp.revision_id = %(revision)s
          AND wt.logical_key = 'day:' || dp.ordinal
        """,
        {"run": run_id, "revision": first},
    )
    await db.execute(
        """
        UPDATE exec.exercise_unit_tracks AS et SET plan_lineage_key = es.lineage_key
        FROM exec.workout_unit_tracks AS wt, plans.workout_unit_prescriptions AS wu,
             plans.exercise_slots AS es
        WHERE et.plan_run_id = %(run)s AND wt.id = et.workout_unit_track_id
          AND wu.lineage_key = wt.plan_lineage_key AND es.workout_unit_id = wu.id
          AND et.logical_key = 'slot:' || es.ordinal
          AND wu.day_id IN (SELECT id FROM plans.day_prescriptions WHERE revision_id = %(revision)s)
        """,
        {"run": run_id, "revision": first},
    )
    unkeyed = await fetch_all(
        db,
        """
        SELECT id FROM exec.workout_unit_tracks WHERE plan_run_id = %s AND plan_lineage_key IS NULL
        UNION ALL
        SELECT id FROM exec.exercise_unit_tracks WHERE plan_run_id = %s AND plan_lineage_key IS NULL
        """,
        run_id,
        run_id,
    )
    assert unkeyed == []
    return run_id, run_plan.plan_id


async def read_models(client: httpx.AsyncClient, run_id: int, clock: FrozenClock) -> dict[str, Any]:
    """Every Execution read of a run, with today's (pre-T3.1) code; each must answer 200."""
    base = f"/api/v1/exec/plan-runs/{run_id}"
    reads: dict[str, Any] = {}
    for name in (
        "overview",
        "analysis/queue",
        "microcycles",
        "calendar",
        "events",
        "workout-traces",
        "load-series",
    ):
        reads[name] = expect(await client.get(f"{base}/{name}"))
    for item in reads["workout-traces"]["items"]:
        trace = item["workout_trace_id"]
        reads[f"workout-traces/{trace}"] = expect(
            await client.get(f"{base}/workout-traces/{trace}")
        )
    for workout in reads["analysis/queue"]["workouts"]:
        for exercise in workout["exercises"]:
            trace = exercise["exercise_trace_id"]
            reads[f"exercise-traces/{trace}"] = expect(
                await client.get(f"{base}/exercise-traces/{trace}")
            )
            reads[f"exercise-traces/{trace}/next"] = expect(
                await client.get(f"{base}/exercise-traces/{trace}/next")
            )
    reads["mobile context"] = expect(
        await client.get(
            "/api/v1/mobile/context",
            params={"plan_run_id": run_id, "date": clock.today.isoformat()},
            headers=DEVICE_HEADERS,
        )
    )
    return reads


async def test_mig_11_owned_runs_are_skipped_and_converted_runs_stay_readable(
    db: AsyncConnection,
    client: httpx.AsyncClient,
    settings: Settings,
    clock: FrozenClock,
    tmp_path: Path,
) -> None:
    """T-MIG-11."""
    owned_run, owned_plan = await t22_style_run(client, db, clock)
    legacy = await legacy_run_ids(db)
    assert owned_run not in legacy
    exec_tables = await table_names(db, "exec")
    plans_tables = await table_names(db, "plans")
    owned_rows: dict[str, tuple[str, tuple[Any, ...]]] = {
        table: (f"{RUN_OF[table]} = %s", (owned_run,)) for table in exec_tables if table in RUN_OF
    }
    owned_plan_rows = {
        "plans.workout_plans": ("row_.id = %s", (owned_plan,)),
        "plans.plan_revisions": ("row_.plan_id = %s", (owned_plan,)),
        "plans.day_prescriptions": (
            "row_.revision_id IN (SELECT id FROM plans.plan_revisions WHERE plan_id = %s)",
            (owned_plan,),
        ),
        "plans.workout_unit_prescriptions": (
            "row_.day_id IN (SELECT dp.id FROM plans.day_prescriptions AS dp"
            " JOIN plans.plan_revisions AS rev ON rev.id = dp.revision_id WHERE rev.plan_id = %s)",
            (owned_plan,),
        ),
        "plans.exercise_slots": (
            "row_.workout_unit_id IN (SELECT wu.id FROM plans.workout_unit_prescriptions AS wu"
            " JOIN plans.day_prescriptions AS dp ON dp.id = wu.day_id"
            " JOIN plans.plan_revisions AS rev ON rev.id = dp.revision_id WHERE rev.plan_id = %s)",
            (owned_plan,),
        ),
    }
    assert set(owned_plan_rows) <= set(plans_tables)
    before_owned = await snapshot_tables(db, list(owned_rows), where=owned_rows)
    before_plan = await snapshot_tables(db, list(owned_plan_rows), where=owned_plan_rows)
    before_labels = await fetch_all(
        db,
        """
        SELECT id, logical_key FROM exec.workout_unit_tracks
        UNION ALL SELECT id, logical_key FROM exec.exercise_unit_tracks ORDER BY 1, 2
        """,
    )

    await convert(settings, tmp_path)

    assert await snapshot_tables(db, list(owned_rows), where=owned_rows) == before_owned
    assert await snapshot_tables(db, list(owned_plan_rows), where=owned_plan_rows) == before_plan
    mapped_runs = await fetch_all(
        db, "SELECT DISTINCT plan_run_id FROM public.agonez_0019_reference_map ORDER BY 1"
    )
    assert [row["plan_run_id"] for row in mapped_runs] == legacy
    # Legacy tracks keep their positional labels.
    after_labels = await fetch_all(
        db,
        """
        SELECT id, logical_key FROM exec.workout_unit_tracks
        UNION ALL SELECT id, logical_key FROM exec.exercise_unit_tracks ORDER BY 1, 2
        """,
    )
    assert after_labels == before_labels
    # Today's read code answers for every converted run (T2.3 compares the payloads).
    for run_id in legacy:
        await read_models(client, run_id, clock)


# --- Atomicity ------------------------------------------------------------------------------


async def assert_migration_aborts(
    db: AsyncConnection, settings: Settings, tmp_path: Path, message: str
) -> None:
    before = await whole_database(db)
    with pytest.raises(errors.RaiseException, match=message):
        await convert(settings, tmp_path)
    assert await whole_database(db) == before
    leftovers = await fetch_all(
        db,
        """
        SELECT to_regclass('public.agonez_0019_reference_map') AS reference_map,
               (SELECT count(*) FROM public.agonez_schema_migrations
                WHERE version = %s) AS recorded,
               (SELECT attnotnull FROM pg_attribute
                WHERE attrelid = 'exec.plan_runs'::regclass AND attname = 'run_plan_id') AS not_null
        """,
        RUN_PLAN_CONVERSION,
    )
    assert leftovers == [{"reference_map": None, "recorded": 0, "not_null": False}]


async def test_a_preflight_finding_aborts_the_migration(
    db: AsyncConnection, settings: Settings, tmp_path: Path
) -> None:
    """Check 2: a workout track whose day key disagrees with its sessions."""
    await db.execute(
        """
        UPDATE exec.workout_unit_tracks SET logical_key = 'day:99'
        WHERE id = (SELECT min(id) FROM exec.workout_unit_tracks WHERE plan_run_id = 2)
        """
    )
    await assert_migration_aborts(db, settings, tmp_path, r"pre-flight audit found 1 problem\(s\)")


async def test_a_reference_the_copies_cannot_map_aborts_the_migration(
    db: AsyncConnection, settings: Settings, tmp_path: Path
) -> None:
    """A prescription slot of a revision the run does not otherwise use: no pre-flight check."""
    await db.execute(
        """
        UPDATE exec.exercise_unit_prescriptions
        SET source_plan_exercise_slot_id = (
            SELECT min(es.id) FROM plans.exercise_slots AS es
            JOIN plans.workout_unit_prescriptions AS wu ON wu.id = es.workout_unit_id
            JOIN plans.day_prescriptions AS dp ON dp.id = wu.day_id
            WHERE dp.revision_id = 10
        )
        WHERE id = (
            SELECT min(eup.id) FROM exec.exercise_unit_prescriptions AS eup
            JOIN exec.exercise_unit_tracks AS et ON et.id = eup.exercise_unit_track_id
            WHERE et.plan_run_id = 2
        )
        """
    )
    await assert_migration_aborts(
        db, settings, tmp_path, r"references outside the run's own run plan \(I1\): F8 "
    )


def test_the_embedded_preflight_is_the_shipped_script() -> None:
    script = PREFLIGHT_SQL.read_text("utf-8")
    statement = script[script.index("\nWITH\n") + 1 : script.rindex("\nORDER BY ")]
    migration = _packaged_migrations()[RUN_PLAN_CONVERSION].read_text("utf-8")
    embedded = migration[
        migration.index("-- preflight:begin\n") + len("-- preflight:begin\n") : migration.index(
            "\n-- preflight:end\n"
        )
    ]
    assert embedded == statement


# --- Demo seed (Q5) ---------------------------------------------------------------------------


def _run_seed(settings: Settings) -> None:
    with psycopg.connect(settings.database_dsn, autocommit=True) as connection:
        connection.execute(SEED_SQL.read_text("utf-8"))


def test_demo_seed_guard_lets_the_seed_through_before_0019(settings: Settings) -> None:
    """The guard refuses only once 0019 is recorded.

    The seed itself has not run on the current schema since 0009 (it inserts workout performances
    without ``client_uuid``), so it may still fail here, just not because of the guard.
    """
    try:
        _run_seed(settings)
    except psycopg.Error as error:
        assert "Execution demo seed refused" not in str(error)


async def test_demo_seed_refuses_to_run_after_0019(
    db: AsyncConnection, settings: Settings, converted: Converted
) -> None:
    before = await whole_database(db)
    with pytest.raises(errors.RaiseException, match="Execution demo seed refused"):
        _run_seed(settings)
    assert await whole_database(db) == before
