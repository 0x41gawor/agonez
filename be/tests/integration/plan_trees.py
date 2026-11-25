"""Revision trees read straight from the database, shared by the plan copy tests.

A revision tree is read as ``{entity: {path: Node}}``. The path is the chain of natural keys
from the day down (day ordinal, slot ordinal, variant ordinal, set ordinal; muscle id for
target muscles), so a source row and its copy have the same path. ``Node.body`` holds every
column except the row id and the parent reference, read with ``to_jsonb``: a column added to a
plan table later and forgotten in ``plans.copy_revision_tree`` fails the copy tests.

Moved here from ``test_copy_revision_tree.py`` (T1.1) so later test files can reuse it.
"""

from collections import defaultdict
from dataclasses import dataclass
from typing import Any

import httpx
from builders import (
    PlanSpec,
    SetSpec,
    SlotSpec,
    exercise_slugs,
    make_library_plan,
    rest,
    training,
)
from psycopg import AsyncConnection

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
