"""Migration 0018 and ``plans.copy_revision_tree`` (T-UNIT-COPY-01…06 in ``07`` §1).

A revision tree is read as ``{entity: {path: Node}}``. The path is the chain of natural keys
from the day down (day ordinal, slot ordinal, variant ordinal, set ordinal; muscle id for
target muscles), so a source row and its copy have the same path. ``Node.body`` holds every
column except the row id and the parent reference, read with ``to_jsonb``: a column added to a
plan table later and forgotten in the function fails these tests.
"""

import asyncio
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from uuid import uuid4

import httpx
import psycopg
import pytest
from builders import (
    PlanSpec,
    SetSpec,
    SlotSpec,
    exercise_slugs,
    expect,
    make_library_plan,
    make_run,
    rest,
    training,
)
from conftest import DatabaseServer, FrozenClock, _drop_database, _dump_path, _restore
from psycopg import AsyncConnection, errors, sql

from agonez_api.migrations import runner

MIGRATION = "0018_run_plans_schema.sql"

Path_ = tuple[Any, ...]

ENTITIES = (
    "day",
    "workout_unit",
    "exercise_slot",
    "target_muscle",
    "exercise_variant",
    "set_infra",
)
# Entities the function reports in its id map; target muscles have no id of their own.
MAPPED_ENTITIES = tuple(entity for entity in ENTITIES if entity != "target_muscle")

PARENT = {
    "workout_unit": "day",
    "exercise_slot": "workout_unit",
    "target_muscle": "exercise_slot",
    "exercise_variant": "exercise_slot",
    "set_infra": "exercise_variant",
}

TREE_QUERIES = {
    "day": """
        SELECT jsonb_build_array(day.ordinal) AS path, day.id, NULL::integer AS parent_id,
               to_jsonb(day) - 'id' - 'revision_id' AS body
        FROM plans.day_prescriptions AS day
        WHERE day.revision_id = %(revision)s
    """,
    "workout_unit": """
        SELECT jsonb_build_array(day.ordinal) AS path, unit.id, unit.day_id AS parent_id,
               to_jsonb(unit) - 'id' - 'day_id' AS body
        FROM plans.workout_unit_prescriptions AS unit
        JOIN plans.day_prescriptions AS day ON day.id = unit.day_id
        WHERE day.revision_id = %(revision)s
    """,
    "exercise_slot": """
        SELECT jsonb_build_array(day.ordinal, slot.ordinal) AS path, slot.id,
               slot.workout_unit_id AS parent_id,
               to_jsonb(slot) - 'id' - 'workout_unit_id' AS body
        FROM plans.exercise_slots AS slot
        JOIN plans.workout_unit_prescriptions AS unit ON unit.id = slot.workout_unit_id
        JOIN plans.day_prescriptions AS day ON day.id = unit.day_id
        WHERE day.revision_id = %(revision)s
    """,
    "target_muscle": """
        SELECT jsonb_build_array(day.ordinal, slot.ordinal, target.muscle_id) AS path,
               NULL::integer AS id, target.slot_id AS parent_id,
               to_jsonb(target) - 'slot_id' AS body
        FROM plans.exercise_slot_target_muscles AS target
        JOIN plans.exercise_slots AS slot ON slot.id = target.slot_id
        JOIN plans.workout_unit_prescriptions AS unit ON unit.id = slot.workout_unit_id
        JOIN plans.day_prescriptions AS day ON day.id = unit.day_id
        WHERE day.revision_id = %(revision)s
    """,
    "exercise_variant": """
        SELECT jsonb_build_array(day.ordinal, slot.ordinal, variant.ordinal) AS path,
               variant.id, variant.slot_id AS parent_id,
               to_jsonb(variant) - 'id' - 'slot_id' AS body
        FROM plans.exercise_variants AS variant
        JOIN plans.exercise_slots AS slot ON slot.id = variant.slot_id
        JOIN plans.workout_unit_prescriptions AS unit ON unit.id = slot.workout_unit_id
        JOIN plans.day_prescriptions AS day ON day.id = unit.day_id
        WHERE day.revision_id = %(revision)s
    """,
    "set_infra": """
        SELECT jsonb_build_array(day.ordinal, slot.ordinal, variant.ordinal, item.ordinal)
                   AS path,
               item.id, item.exercise_variant_id AS parent_id,
               to_jsonb(item) - 'id' - 'exercise_variant_id' AS body
        FROM plans.set_infra_prescriptions AS item
        JOIN plans.exercise_variants AS variant ON variant.id = item.exercise_variant_id
        JOIN plans.exercise_slots AS slot ON slot.id = variant.slot_id
        JOIN plans.workout_unit_prescriptions AS unit ON unit.id = slot.workout_unit_id
        JOIN plans.day_prescriptions AS day ON day.id = unit.day_id
        WHERE day.revision_id = %(revision)s
    """,
}


@dataclass(frozen=True)
class Node:
    id: int | None
    parent_id: int | None
    body: dict[str, Any]


Tree = dict[str, dict[Path_, Node]]


def parent_path(entity: str, path: Path_) -> Path_:
    """Path of the parent row: a unit shares its day's path, the others drop their last key."""
    return path if entity == "workout_unit" else path[:-1]


async def read_tree(db: AsyncConnection, revision_id: int) -> Tree:
    tree: Tree = {}
    for entity, query in TREE_QUERIES.items():
        rows = await (await db.execute(query, {"revision": revision_id})).fetchall()
        tree[entity] = {
            tuple(row["path"]): Node(row["id"], row["parent_id"], row["body"]) for row in rows
        }
        assert len(tree[entity]) == len(rows), f"duplicate {entity} paths"
    return tree


def bodies(tree: Tree, *, without: tuple[str, ...] = ()) -> dict[str, dict[Path_, Any]]:
    return {
        entity: {
            path: {key: value for key, value in node.body.items() if key not in without}
            for path, node in nodes.items()
        }
        for entity, nodes in tree.items()
    }


async def new_target_revision(
    db: AsyncConnection,
    source_revision_id: int,
    *,
    in_new_run_plan: bool,
) -> int:
    """An empty RELEASED revision, in a new run-scope plan or after the source's revisions."""
    source = await (
        await db.execute(
            """
            SELECT plan.id AS plan_id, plan.name
            FROM plans.plan_revisions AS revision
            JOIN plans.workout_plans AS plan ON plan.id = revision.plan_id
            WHERE revision.id = %s
            """,
            (source_revision_id,),
        )
    ).fetchone()
    assert source is not None
    plan_id = source["plan_id"]
    if in_new_run_plan:
        created = await (
            await db.execute(
                """
                INSERT INTO plans.workout_plans (name, scope, source_plan_id)
                VALUES (%s, 'run', %s)
                RETURNING id
                """,
                (source["name"], plan_id),
            )
        ).fetchone()
        assert created is not None
        plan_id = created["id"]
    revision = await (
        await db.execute(
            """
            INSERT INTO plans.plan_revisions
                (plan_id, revision_no, status, based_on_revision_id, released_at)
            SELECT %(plan)s, coalesce(max(revision_no), 0) + 1, 'RELEASED', %(source)s, now()
            FROM plans.plan_revisions
            WHERE plan_id = %(plan)s
            RETURNING id
            """,
            {"plan": plan_id, "source": source_revision_id},
        )
    ).fetchone()
    assert revision is not None
    return int(revision["id"])


async def copy_tree(
    db: AsyncConnection,
    source_revision_id: int,
    target_revision_id: int,
    regenerate_progression_ids: bool,
) -> set[tuple[str, int, int]]:
    rows = await (
        await db.execute(
            "SELECT entity, source_id, target_id FROM plans.copy_revision_tree(%s, %s, %s)",
            (source_revision_id, target_revision_id, regenerate_progression_ids),
        )
    ).fetchall()
    mapping = {(row["entity"], row["source_id"], row["target_id"]) for row in rows}
    assert len(mapping) == len(rows), "the id map repeats a row"
    return mapping


def assert_complete_copy(
    source: Tree,
    target: Tree,
    mapping: set[tuple[str, int, int]],
    *,
    progression_ids_kept: bool,
) -> None:
    # T-UNIT-COPY-01: the same rows per entity (same natural-key paths, so the same counts).
    for entity in ENTITIES:
        assert target[entity].keys() == source[entity].keys(), entity

    # T-UNIT-COPY-02: copied children reference copied parents only, and the ids are new.
    for entity, parent in PARENT.items():
        for path, node in target[entity].items():
            assert node.parent_id == target[parent][parent_path(entity, path)].id, (entity, path)
    for entity in MAPPED_ENTITIES:
        source_ids = {node.id for node in source[entity].values()}
        assert source_ids.isdisjoint(node.id for node in target[entity].values()), entity

    # The returned map pairs each source row with its copy, and nothing else.
    assert mapping == {
        (entity, node.id, target[entity][path].id)
        for entity in MAPPED_ENTITIES
        for path, node in source[entity].items()
    }

    # T-UNIT-COPY-03/-06: every column equal (lineage keys, raw load_step_kg, icons, loading
    # cycles, load specs, …). T-UNIT-COPY-04: so are progression ids when they are kept.
    without = () if progression_ids_kept else ("progression_id",)
    assert bodies(target, without=without) == bodies(source, without=without)
    for entity in ("workout_unit", "exercise_slot"):
        for path, node in source[entity].items():
            assert target[entity][path].body["lineage_key"] == node.body["lineage_key"]


def assert_regenerated_progression_ids(source: Tree, target: Tree, others: set[str]) -> None:
    """T-UNIT-COPY-05: all new, shared ids still shared, distinct ids still distinct."""
    pairs = {
        path: (node.body["progression_id"], target["exercise_variant"][path].body["progression_id"])
        for path, node in source["exercise_variant"].items()
    }
    old_to_new: dict[str, set[str]] = defaultdict(set)
    new_to_old: dict[str, set[str]] = defaultdict(set)
    for old, new in pairs.values():
        old_to_new[old].add(new)
        new_to_old[new].add(old)
    assert all(len(new) == 1 for new in old_to_new.values())
    assert all(len(old) == 1 for old in new_to_old.values())
    assert set(new_to_old).isdisjoint(others)


async def progression_ids_outside(db: AsyncConnection, revision_id: int) -> set[str]:
    rows = await (
        await db.execute(
            """
            SELECT variant.progression_id::text AS progression_id
            FROM plans.exercise_variants AS variant
            JOIN plans.exercise_slots AS slot ON slot.id = variant.slot_id
            JOIN plans.workout_unit_prescriptions AS unit ON unit.id = slot.workout_unit_id
            JOIN plans.day_prescriptions AS day ON day.id = unit.day_id
            WHERE day.revision_id <> %s
            """,
            (revision_id,),
        )
    ).fetchall()
    return {row["progression_id"] for row in rows}


async def built_plan_revision(client: httpx.AsyncClient, db: AsyncConnection) -> int:
    """A library plan saved through the API, then given every optional column by hand.

    Fallback variants and a rest day come from the builders; the rest (icon, loading cycles,
    target muscles, NULL load step, shared progression loop, set metadata) is not settable in
    one PUT with the builders, so it is written directly into the disposable clone.
    """
    push, fly, row, squat, curl = await exercise_slugs(db, 5)
    plan = await make_library_plan(
        client,
        PlanSpec(
            name="Copy tree plan",
            days=(
                training("Push", SlotSpec(push, fallbacks=(fly, curl)), SlotSpec(fly)),
                rest(),
                training(
                    "Pull",
                    SlotSpec(row, fallbacks=(push,)),
                    SlotSpec(
                        curl,
                        sets=(SetSpec(role="rampup"), SetSpec(rep_min=8, rep_max=12), SetSpec()),
                        role="ACCESSORY",
                    ),
                ),
                training("Legs", SlotSpec(squat)),
            ),
        ),
    )
    revision_id = int(plan["revision_id"])
    tree = await read_tree(db, revision_id)
    slot = {path: node.id for path, node in tree["exercise_slot"].items()}
    variant = {path: node.id for path, node in tree["exercise_variant"].items()}
    item = {path: node.id for path, node in tree["set_infra"].items()}
    muscle_rows = await (
        await db.execute("SELECT id FROM core.muscles ORDER BY id LIMIT 3")
    ).fetchall()
    muscles = [row["id"] for row in muscle_rows]
    model = await (
        await db.execute("SELECT slug FROM core.progression_models ORDER BY display_order LIMIT 1")
    ).fetchone()
    assert model is not None and len(muscles) == 3

    await db.execute(
        """
        UPDATE plans.day_prescriptions
        SET icon = 'push', weekday = 1, description = 'Heavy pressing'
        WHERE id = %s
        """,
        (tree["day"][(0,)].id,),
    )
    await db.execute(
        """
        UPDATE plans.workout_unit_prescriptions
        SET description = 'Upper push', warmup_notes = 'Bands', stretch_notes = 'Pecs'
        WHERE id = %s
        """,
        (tree["workout_unit"][(0,)].id,),
    )
    await db.execute(
        """
        UPDATE plans.exercise_slots
        SET loading_mode = 'high_load',
            loading_cycle = ARRAY['high_load', 'moderate_load', 'low_load']::plans.loading_mode[],
            goal = 'Strength', volume_axis = 'press', description = 'Main lift'
        WHERE id = %s
        """,
        (slot[(0, 0)],),
    )
    await db.execute(
        """
        INSERT INTO plans.exercise_slot_target_muscles (slot_id, muscle_id)
        VALUES (%s, %s), (%s, %s), (%s, %s)
        """,
        (slot[(0, 0)], muscles[0], slot[(0, 0)], muscles[1], slot[(2, 1)], muscles[2]),
    )
    # Raw NULL load step (the loader would COALESCE it), an explicit one, and a progression
    # loop shared by the default variants of Push slot 0 and Pull slot 0.
    await db.execute(
        "UPDATE plans.exercise_variants SET load_step_kg = NULL WHERE id = %s",
        (variant[(0, 0, 0)],),
    )
    await db.execute(
        """
        UPDATE plans.exercise_variants
        SET load_step_kg = 1.25, progression_model_slug = %s,
            active_working_set_min = 1, active_working_set_max = 3
        WHERE id = %s
        """,
        (model["slug"], variant[(0, 0, 1)]),
    )
    await db.execute(
        """
        UPDATE plans.exercise_variants
        SET load_step_kg = NULL,
            progression_id = (SELECT progression_id FROM plans.exercise_variants WHERE id = %s)
        WHERE id = %s
        """,
        (variant[(0, 0, 0)], variant[(2, 0, 0)]),
    )
    await db.execute(
        """
        UPDATE plans.set_infra_prescriptions
        SET load_spec = '{"kind": "athlete_selected"}', min_volume_level = 2,
            rep_range_semantics = 'gating', loading_mode = 'low_load',
            loading_cycle = ARRAY['low_load', 'high_load']::plans.loading_mode[]
        WHERE id = %s
        """,
        (item[(2, 1, 0, 1)],),
    )
    return revision_id


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
