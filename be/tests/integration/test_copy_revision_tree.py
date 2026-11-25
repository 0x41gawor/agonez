"""Migration 0018 and ``plans.copy_revision_tree`` (T-UNIT-COPY-01…06 in ``07`` §1).

Trees are read with ``plan_trees.read_tree``: every column except the row id and the parent
reference, keyed by natural-key path, so a column added to a plan table later and forgotten in
the function fails these tests.
"""

import asyncio
from pathlib import Path
from typing import Any
from uuid import uuid4

import httpx
import psycopg
import pytest
from builders import (
    PlanSpec,
    SlotSpec,
    exercise_slugs,
    expect,
    make_library_plan,
    make_run,
    rest,
    training,
)
from conftest import DatabaseServer, FrozenClock, _drop_database, _dump_path, _restore
from plan_trees import (
    assert_complete_copy,
    assert_regenerated_progression_ids,
    built_plan_revision,
    copy_tree,
    new_target_revision,
    progression_ids_outside,
    read_tree,
)
from psycopg import AsyncConnection, errors, sql

from agonez_api.migrations import runner

MIGRATION = "0018_run_plans_schema.sql"


async def test_copies_every_real_revision_completely(db: AsyncConnection) -> None:
    """T-UNIT-COPY-01…06 on every non-empty revision of the restored production data."""
    revisions = await (
        await db.execute(
            """
            SELECT revision.id, revision.status::text AS status
            FROM plans.plan_revisions AS revision
            WHERE EXISTS (
                SELECT 1 FROM plans.day_prescriptions AS day WHERE day.revision_id = revision.id
            )
            ORDER BY revision.id
            """
        )
    ).fetchall()
    covered: set[str] = set()
    for revision in revisions:
        source_id = revision["id"]
        source = await read_tree(db, source_id)
        if revision["status"] == "RELEASED":
            covered.add("released revision")
        if source["target_muscle"]:
            covered.add("target muscles")
        if any(node.body["loading_cycle"] for node in source["exercise_slot"].values()):
            covered.add("slot loading cycle")
        if any(node.body["loading_cycle"] for node in source["set_infra"].values()):
            covered.add("set loading cycle")
        if any(node.body["icon"] for node in source["day"].values()):
            covered.add("day icon")
        if len(source["exercise_slot"]) >= 40:
            covered.add("40+ slots")

        kept_target = await new_target_revision(db, source_id, in_new_run_plan=True)
        kept_map = await copy_tree(db, source_id, kept_target, False)
        assert_complete_copy(
            source, await read_tree(db, kept_target), kept_map, progression_ids_kept=True
        )

        others = await progression_ids_outside(db, source_id)
        fresh_target = await new_target_revision(db, source_id, in_new_run_plan=True)
        fresh_map = await copy_tree(db, source_id, fresh_target, True)
        fresh = await read_tree(db, fresh_target)
        assert_complete_copy(source, fresh, fresh_map, progression_ids_kept=False)
        assert_regenerated_progression_ids(source, fresh, others)

        # The source is read only.
        assert await read_tree(db, source_id) == source

    assert covered == {
        "released revision",
        "target muscles",
        "slot loading cycle",
        "set loading cycle",
        "day icon",
        "40+ slots",
    }


async def test_copies_a_built_plan_with_every_optional_column(
    client: httpx.AsyncClient,
    db: AsyncConnection,
) -> None:
    """T-UNIT-COPY-01…04 and -06 on a builder plan, draft → next RELEASED revision (Apply)."""
    source_id = await built_plan_revision(client, db)
    source = await read_tree(db, source_id)
    target_id = await new_target_revision(db, source_id, in_new_run_plan=False)

    mapping = await copy_tree(db, source_id, target_id, False)
    target = await read_tree(db, target_id)

    assert_complete_copy(source, target, mapping, progression_ids_kept=True)
    assert {entity: len(nodes) for entity, nodes in target.items()} == {
        "day": 4,
        "workout_unit": 3,
        "exercise_slot": 5,
        "target_muscle": 3,
        "exercise_variant": 8,
        "set_infra": 24,
    }
    # The columns the builders cannot set, checked by value (T-UNIT-COPY-06).
    assert target["day"][(0,)].body["icon"] == "push"
    assert target["day"][(1,)].body["icon"] is None
    assert target["workout_unit"][(0,)].body["warmup_notes"] == "Bands"
    assert target["exercise_slot"][(0, 0)].body["loading_mode"] == "high_load"
    assert target["exercise_slot"][(0, 0)].body["loading_cycle"] == [
        "high_load",
        "moderate_load",
        "low_load",
    ]
    assert target["exercise_variant"][(0, 0, 0)].body["load_step_kg"] is None
    assert target["exercise_variant"][(2, 0, 0)].body["load_step_kg"] is None
    assert target["exercise_variant"][(0, 0, 1)].body["load_step_kg"] == 1.25
    assert target["exercise_variant"][(0, 0, 1)].body["active_working_set_max"] == 3
    assert [
        node.body["variant_type"]
        for path, node in sorted(target["exercise_variant"].items())
        if path[:2] == (0, 0)
    ] == ["DEFAULT", "FALLBACK", "FALLBACK"]
    copied_set = target["set_infra"][(2, 1, 0, 1)].body
    assert copied_set["load_spec"] == {"kind": "athlete_selected"}
    assert copied_set["min_volume_level"] == 2
    assert copied_set["loading_cycle"] == ["low_load", "high_load"]
    assert target["set_infra"][(2, 1, 0, 0)].body["role"] == "rampup"
    shared = target["exercise_variant"][(0, 0, 0)].body["progression_id"]
    assert target["exercise_variant"][(2, 0, 0)].body["progression_id"] == shared

    # A copy of the copy (Discard, the next Apply) still carries the same lineage keys.
    next_id = await new_target_revision(db, target_id, in_new_run_plan=True)
    next_map = await copy_tree(db, target_id, next_id, False)
    assert_complete_copy(target, await read_tree(db, next_id), next_map, progression_ids_kept=True)


async def test_regenerated_progression_ids_are_new_and_keep_sharing(
    client: httpx.AsyncClient,
    db: AsyncConnection,
) -> None:
    """T-UNIT-COPY-05: library duplicate and promotion semantics."""
    source_id = await built_plan_revision(client, db)
    source = await read_tree(db, source_id)
    others = await progression_ids_outside(db, source_id)
    source_ids = {node.body["progression_id"] for node in source["exercise_variant"].values()}
    assert len(source_ids) == len(source["exercise_variant"]) - 1  # one pair shares a loop

    first_id = await new_target_revision(db, source_id, in_new_run_plan=True)
    first_map = await copy_tree(db, source_id, first_id, True)
    first = await read_tree(db, first_id)
    assert_complete_copy(source, first, first_map, progression_ids_kept=False)
    assert_regenerated_progression_ids(source, first, others)
    shared = first["exercise_variant"][(0, 0, 0)].body["progression_id"]
    assert first["exercise_variant"][(2, 0, 0)].body["progression_id"] == shared

    # Each regenerating copy draws its own ids.
    second_id = await new_target_revision(db, source_id, in_new_run_plan=True)
    await copy_tree(db, source_id, second_id, True)
    second = await read_tree(db, second_id)
    assert_regenerated_progression_ids(source, second, others | source_ids)
    assert {node.body["progression_id"] for node in second["exercise_variant"].values()}.isdisjoint(
        node.body["progression_id"] for node in first["exercise_variant"].values()
    )


async def test_refuses_a_non_empty_or_missing_target(
    client: httpx.AsyncClient,
    db: AsyncConnection,
) -> None:
    """T-UNIT-COPY-06: the function only ever populates an empty revision."""
    source_id = await built_plan_revision(client, db)
    target_id = await new_target_revision(db, source_id, in_new_run_plan=True)
    await copy_tree(db, source_id, target_id, False)
    copied = await read_tree(db, target_id)

    with pytest.raises(errors.ObjectNotInPrerequisiteState, match="is not empty"):
        await copy_tree(db, source_id, target_id, False)
    # The source itself is never empty, so copying a revision onto itself is refused as well.
    with pytest.raises(errors.ObjectNotInPrerequisiteState, match="is not empty"):
        await copy_tree(db, source_id, source_id, True)
    assert await read_tree(db, target_id) == copied

    missing = await (
        await db.execute("SELECT max(id) + 1000 AS id FROM plans.plan_revisions")
    ).fetchone()
    assert missing is not None
    with pytest.raises(errors.NoDataFound, match="source revision"):
        await copy_tree(db, missing["id"], target_id, False)
    with pytest.raises(errors.NoDataFound, match="target revision"):
        await copy_tree(db, source_id, missing["id"], False)
    with pytest.raises(errors.NullValueNotAllowed):
        await db.execute("SELECT * FROM plans.copy_revision_tree(%s, %s, NULL)", (1, 2))

    # An empty source (a new plan without days) copies nothing.
    empty = expect(await client.post("/api/plans", json={"name": "Empty plan"}), 201)
    empty_target = await new_target_revision(db, empty["revision_id"], in_new_run_plan=True)
    assert await copy_tree(db, empty["revision_id"], empty_target, False) == set()
    assert all(not nodes for nodes in (await read_tree(db, empty_target)).values())


async def test_existing_rows_and_todays_writers_get_the_defaults(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    clock: FrozenClock,
) -> None:
    """0018 is invisible to today's code: its inserts work unchanged and get the defaults."""
    before = await (
        await db.execute(
            """
            SELECT
                (SELECT count(*) FROM plans.workout_plans
                 WHERE scope <> 'library' OR source_plan_id IS NOT NULL) AS non_library_plans,
                (SELECT count(*) FROM exec.plan_runs
                 WHERE run_plan_id IS NOT NULL OR run_plan_scope <> 'run') AS owning_runs,
                (SELECT count(*) FROM exec.workout_unit_tracks
                 WHERE plan_lineage_key IS NOT NULL) AS keyed_workout_tracks,
                (SELECT count(*) FROM exec.exercise_unit_tracks
                 WHERE plan_lineage_key IS NOT NULL) AS keyed_exercise_tracks,
                (SELECT count(*) - count(DISTINCT lineage_key)
                 FROM plans.workout_unit_prescriptions) AS repeated_unit_keys,
                (SELECT count(*) - count(DISTINCT lineage_key)
                 FROM plans.exercise_slots) AS repeated_slot_keys,
                (SELECT count(*) FROM exec.plan_runs) AS runs
            """
        )
    ).fetchone()
    assert before is not None and before["runs"] > 0
    assert {key: value for key, value in before.items() if key != "runs"} == dict.fromkeys(
        (
            "non_library_plans",
            "owning_runs",
            "keyed_workout_tracks",
            "keyed_exercise_tracks",
            "repeated_unit_keys",
            "repeated_slot_keys",
        ),
        0,
    )

    (lift,) = await exercise_slugs(db, 1)
    plan = await make_library_plan(
        client, PlanSpec(name="Defaults plan", days=(training("A", SlotSpec(lift)), rest()))
    )
    tree = await read_tree(db, plan["revision_id"])
    keys = (
        tree["workout_unit"][(0,)].body["lineage_key"],
        tree["exercise_slot"][(0, 0)].body["lineage_key"],
    )
    # A draft save keeps the lineage keys of rows it updates (D5: clients never send them).
    plan["days"][0]["workout_unit"]["name"] = "A renamed"
    plan["days"][0]["workout_unit"]["exercise_slots"][0]["goal"] = "Updated"
    expect(await client.put(f"/api/plans/{plan['id']}/draft", json=plan))
    tree = await read_tree(db, plan["revision_id"])
    assert tree["workout_unit"][(0,)].body["name"] == "A renamed"
    assert (
        tree["workout_unit"][(0,)].body["lineage_key"],
        tree["exercise_slot"][(0, 0)].body["lineage_key"],
    ) == keys

    overview = await make_run(client, plan["revision_id"], clock.today, 1)
    run_id = overview["run"]["plan_run_id"]
    created = await (
        await db.execute(
            """
            SELECT plan.scope::text AS scope, plan.source_plan_id,
                   run.run_plan_id, run.run_plan_scope::text AS run_plan_scope,
                   (SELECT count(*) FROM exec.workout_unit_tracks AS track
                    WHERE track.plan_run_id = run.id AND track.plan_lineage_key IS NULL)
                       AS unkeyed_workout_tracks,
                   (SELECT count(*) FROM exec.exercise_unit_tracks AS track
                    WHERE track.plan_run_id = run.id AND track.plan_lineage_key IS NULL)
                       AS unkeyed_exercise_tracks
            FROM exec.plan_runs AS run
            JOIN plans.workout_plans AS plan ON plan.id = %s
            WHERE run.id = %s
            """,
            (plan["id"], run_id),
        )
    ).fetchone()
    assert created == {
        "scope": "library",
        "source_plan_id": None,
        "run_plan_id": None,
        "run_plan_scope": "run",
        "unkeyed_workout_tracks": 1,
        "unkeyed_exercise_tracks": 1,
    }
    listed = expect(await client.get("/api/plans"))
    assert plan["id"] in {item["id"] for item in listed["items"]}
    expect(await client.get(f"/api/v1/exec/plan-runs/{run_id}/overview"))


async def test_run_ownership_constraints(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    clock: FrozenClock,
) -> None:
    """D2 / I1 in the database: a run can own only a run-scope plan, and only one run can."""
    (lift,) = await exercise_slugs(db, 1)
    plan = await make_library_plan(
        client, PlanSpec(name="Ownership plan", days=(training("A", SlotSpec(lift)),))
    )
    first = (await make_run(client, plan["revision_id"], clock.today, 1))["run"]["plan_run_id"]
    second = (await make_run(client, plan["revision_id"], clock.today, 1))["run"]["plan_run_id"]
    run_plan = await (
        await db.execute(
            """
            INSERT INTO plans.workout_plans (name, scope, source_plan_id)
            VALUES ('Run plan', 'run', %s)
            RETURNING id
            """,
            (plan["id"],),
        )
    ).fetchone()
    assert run_plan is not None
    run_plan_id = run_plan["id"]

    with pytest.raises(errors.ForeignKeyViolation, match="plan_runs_run_plan_fk"):
        await db.execute(
            "UPDATE exec.plan_runs SET run_plan_id = %s WHERE id = %s", (plan["id"], first)
        )
    with pytest.raises(errors.CheckViolation, match="plan_runs_run_plan_scope_is_run"):
        await db.execute(
            "UPDATE exec.plan_runs SET run_plan_scope = 'library' WHERE id = %s", (first,)
        )
    await db.execute(
        "UPDATE exec.plan_runs SET run_plan_id = %s WHERE id = %s", (run_plan_id, first)
    )
    with pytest.raises(errors.UniqueViolation, match="plan_runs_run_plan_unique"):
        await db.execute(
            "UPDATE exec.plan_runs SET run_plan_id = %s WHERE id = %s", (run_plan_id, second)
        )
    with pytest.raises(errors.ForeignKeyViolation, match="plan_runs_run_plan_fk"):
        await db.execute("DELETE FROM plans.workout_plans WHERE id = %s", (run_plan_id,))
    with pytest.raises(errors.ForeignKeyViolation, match="plan_runs_run_plan_fk"):
        await db.execute(
            "UPDATE plans.workout_plans SET scope = 'library' WHERE id = %s", (run_plan_id,)
        )

    # Deleting the plan another plan was promoted from only clears the informational lineage.
    await db.execute("UPDATE exec.plan_runs SET run_plan_id = NULL WHERE id = %s", (first,))
    promoted = await (
        await db.execute(
            """
            INSERT INTO plans.workout_plans (name, source_plan_id) VALUES ('Promoted', %s)
            RETURNING id
            """,
            (run_plan_id,),
        )
    ).fetchone()
    assert promoted is not None
    await db.execute("DELETE FROM plans.workout_plans WHERE id = %s", (run_plan_id,))
    row = await (
        await db.execute(
            "SELECT source_plan_id FROM plans.workout_plans WHERE id = %s", (promoted["id"],)
        )
    ).fetchone()
    assert row == {"source_plan_id": None}


async def test_every_new_column_and_the_function_are_documented(db: AsyncConnection) -> None:
    columns = {
        ("plans", "workout_plans", "scope"),
        ("plans", "workout_plans", "source_plan_id"),
        ("plans", "workout_unit_prescriptions", "lineage_key"),
        ("plans", "exercise_slots", "lineage_key"),
        ("exec", "plan_runs", "run_plan_id"),
        ("exec", "plan_runs", "run_plan_scope"),
        ("exec", "workout_unit_tracks", "plan_lineage_key"),
        ("exec", "exercise_unit_tracks", "plan_lineage_key"),
    }
    for schema, table, column in sorted(columns):
        row = await (
            await db.execute(
                """
                SELECT col_description(format('%%I.%%I', %s::text, %s::text)::regclass,
                                       attnum) AS comment
                FROM pg_attribute
                WHERE attrelid = format('%%I.%%I', %s::text, %s::text)::regclass
                  AND attname = %s
                """,
                (schema, table, schema, table, column),
            )
        ).fetchone()
        assert row is not None and row["comment"], (schema, table, column)
    function = await (
        await db.execute(
            """
            SELECT obj_description(
                'plans.copy_revision_tree(integer, integer, boolean)'::regprocedure, 'pg_proc'
            ) AS comment
            """
        )
    ).fetchone()
    assert function is not None and function["comment"]


def test_an_error_anywhere_in_the_migration_rolls_all_of_it_back(
    database_server: DatabaseServer,
    template_database: str,  # creates the dump's owner roles
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """The runner applies a file in one transaction, PL/pgSQL ``$$`` bodies included.

    Replays the dump into a fresh database, then runs the real migrations with 0018 extended
    by a failing statement after the function: nothing of 0018 may remain. The unchanged
    file then applies.
    """
    packaged = Path(str(runner.files("agonez_api.migrations").joinpath("versions")))
    broken_root = tmp_path / "broken"
    (broken_root / "versions").mkdir(parents=True)
    for source in packaged.iterdir():
        if source.name.endswith(".sql"):
            text = source.read_text(encoding="utf-8")
            if source.name == MIGRATION:
                text += "\nSELECT 1 / 0;\n"
            (broken_root / "versions" / source.name).write_text(text, encoding="utf-8")

    name = f"agonez_it_{uuid4().hex[:12]}"
    with database_server.connect_admin() as admin:
        _drop_database(admin, name)
        admin.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(name)))
    try:
        _restore(database_server, _dump_path(), name)
        settings = database_server.settings(name, tmp_path)
        with psycopg.connect(settings.database_dsn, autocommit=True) as connection:
            applied = connection.execute(
                "SELECT 1 FROM public.agonez_schema_migrations WHERE version = %s", (MIGRATION,)
            ).fetchone()
        if applied is not None:
            pytest.skip(f"the dump already contains {MIGRATION}")

        monkeypatch.setattr(runner, "files", lambda _package: broken_root)
        with pytest.raises(errors.DivisionByZero):
            asyncio.run(runner.run_migrations(settings))
        monkeypatch.undo()

        def schema_state(connection: psycopg.Connection) -> tuple[Any, ...]:
            row = connection.execute(
                """
                SELECT
                    to_regtype('plans.plan_scope') IS NOT NULL,
                    to_regprocedure('plans.copy_revision_tree(integer, integer, boolean)')
                        IS NOT NULL,
                    EXISTS (SELECT 1 FROM information_schema.columns
                            WHERE table_schema = 'plans' AND table_name = 'exercise_slots'
                              AND column_name = 'lineage_key'),
                    EXISTS (SELECT 1 FROM public.agonez_schema_migrations
                            WHERE version = %s)
                """,
                (MIGRATION,),
            ).fetchone()
            assert row is not None
            return tuple(row)

        with psycopg.connect(settings.database_dsn, autocommit=True) as connection:
            assert schema_state(connection) == (False, False, False, False)

        asyncio.run(runner.run_migrations(settings))
        with psycopg.connect(settings.database_dsn, autocommit=True) as connection:
            assert schema_state(connection) == (True, True, True, True)
    finally:
        with database_server.connect_admin() as admin:
            _drop_database(admin, name)
