"""Save to My Plans: duplicate with a name and a source revision (T5.1; ``04`` §4).

T-INT-PR-01…06, T-DEL-03 and T-DEL-04 of ``07``. Duplicating a run plan promotes it: the new
library plan records the run plan as ``source_plan_id`` and is independent of it afterwards.
Duplicating a library plan behaves as before. Before T3.3 a run plan's applied revision is its
r1, so T-INT-PR-03 covers the draft half; its Apply half is E2E-05 (T6.1).
"""

from typing import Any

import httpx
import pytest
import test_run_creation as run_creation
from builders import expect, finalize_session, run_sessions, snapshot_tables, table_names
from conftest import FrozenClock
from plan_trees import (
    assert_regenerated_progression_ids,
    bodies,
    copy_tree,
    new_target_revision,
    progression_ids_outside,
    read_tree,
)
from psycopg import AsyncConnection
from test_run_creation import (
    PNG,
    RUNS,
    CreatedRun,
    all_rows,
    create_run,
    fingerprint,
    one,
    plan_snapshot,
    run_snapshot,
)

from agonez_api.modules.plans.fingerprint import definition_fingerprint
from agonez_api.modules.plans.repository import load_revision_rows

# T2.2's fixtures: a library plan (two training days, a rest day, description, accent, cover)
# and an exercise it does not use.
library = run_creation.library
spare_exercise = run_creation.spare_exercise


async def promote(
    client: httpx.AsyncClient, plan_id: int, body: dict[str, Any] | None = None
) -> dict[str, Any]:
    """``POST …/duplicate``; ``body=None`` sends no body at all."""
    return expect(await client.post(f"/api/plans/{plan_id}/duplicate", json=body), 201)


async def definition(db: AsyncConnection, revision_id: int) -> str:
    """The fingerprint a copy with fresh progression ids shares with its source."""
    return definition_fingerprint(
        await load_revision_rows(db, revision_id), include_progression_ids=False
    )


async def edit_draft(client: httpx.AsyncClient, plan_id: int, exercise: str, name: str) -> None:
    """Rename a plan and change its working copy: exchange an exercise, drop a set and a day."""
    draft = expect(await client.get(f"/api/plans/{plan_id}/draft"))
    draft["name"] = name
    slots = draft["days"][0]["workout_unit"]["exercise_slots"]
    slots[1]["variants"][0]["exercise_slug"] = exercise
    slots[0]["variants"][0]["sets"].pop()
    draft["days"].pop()
    expect(await client.put(f"/api/plans/{plan_id}/draft", json=draft))


async def origin(db: AsyncConnection, plan_id: int) -> dict[str, Any]:
    """Scope and lineage of a plan that has exactly one revision (a duplicate)."""
    rows = await all_rows(
        db,
        """
        SELECT plan.scope::text AS scope, plan.source_plan_id, revision.id AS revision_id,
               revision.revision_no, revision.status::text AS status,
               revision.based_on_revision_id
        FROM plans.workout_plans AS plan
        JOIN plans.plan_revisions AS revision ON revision.plan_id = plan.id
        WHERE plan.id = %s
        """,
        plan_id,
    )
    assert len(rows) == 1, rows
    return rows[0]


async def identity(db: AsyncConnection, plan_id: int) -> dict[str, Any]:
    """Description, accent and cover bytes: what a duplicate takes from the plan itself."""
    return await one(
        db,
        """
        SELECT plan.description, plan.accent::text AS accent, image.content_type,
               image.byte_size, image.checksum, image.data
        FROM plans.workout_plans AS plan
        LEFT JOIN plans.plan_images AS image ON image.plan_id = plan.id
        WHERE plan.id = %s
        """,
        plan_id,
    )


async def listed_plans(client: httpx.AsyncClient) -> dict[int, dict[str, Any]]:
    return {item["id"]: item for item in expect(await client.get("/api/plans"))["items"]}


async def database_snapshot(db: AsyncConnection) -> dict[str, str]:
    return await snapshot_tables(db, await table_names(db, "plans", "exec"))


async def executed_run(
    client: httpx.AsyncClient, db: AsyncConnection, revision_id: int, clock: FrozenClock
) -> CreatedRun:
    """A run with one finished workout, so Execution references the run plan's rows."""
    run = await create_run(client, db, revision_id, clock)
    await finalize_session(client, run_sessions(run.overview)[0]["session_id"], clock.today)
    return run


async def test_int_pr_01_save_the_applied_revision_to_my_plans(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    clock: FrozenClock,
    library: dict[str, Any],
    spare_exercise: str,
) -> None:
    run = await executed_run(client, db, library["revision_id"], clock)
    # The working copy, name and cover move on; the applied revision stays what it was.
    await edit_draft(client, run.plan_id, spare_exercise, "Block two")
    expect(
        await client.put(
            f"/api/plans/{run.plan_id}/image",
            content=PNG + b"run plan cover",
            headers={"Content-Type": "image/png"},
        )
    )
    source = await read_tree(db, run.released_id)
    before = (
        await plan_snapshot(db, run.plan_id),
        await plan_snapshot(db, library["id"]),
        await run_snapshot(db, run.run_id),
    )

    promoted = await promote(
        client,
        run.plan_id,
        {"name": "PPL after cycle 1", "source_revision_id": run.released_id},
    )

    assert promoted["id"] not in {library["id"], run.plan_id}
    assert {
        key: promoted[key]
        for key in (
            "name",
            "scope",
            "source_plan_id",
            "plan_run_id",
            "revision_no",
            "lock_version",
        )
    } == {
        "name": "PPL after cycle 1",
        "scope": "library",
        "source_plan_id": run.plan_id,
        "plan_run_id": None,
        "revision_no": 1,
        "lock_version": 1,
    }
    assert await origin(db, promoted["id"]) == {
        "scope": "library",
        "source_plan_id": run.plan_id,
        "revision_id": promoted["revision_id"],
        "revision_no": 1,
        "status": "DRAFT",
        "based_on_revision_id": run.released_id,
    }

    # The applied revision's definition, not the working copy's, with fresh progression ids.
    saved = await definition(db, promoted["revision_id"])
    assert saved == await definition(db, run.released_id)
    assert saved != await definition(db, run.draft_id)
    copied = await read_tree(db, promoted["revision_id"])
    assert bodies(copied, without=("progression_id",)) == bodies(
        source, without=("progression_id",)
    )
    assert_regenerated_progression_ids(
        source, copied, await progression_ids_outside(db, promoted["revision_id"])
    )

    # Identity and cover are the run plan's current ones.
    assert await identity(db, promoted["id"]) == await identity(db, run.plan_id)
    assert (await client.get(promoted["image_url"])).content == PNG + b"run plan cover"

    listed = await listed_plans(client)
    assert run.plan_id not in listed
    assert (listed[promoted["id"]]["scope"], listed[promoted["id"]]["source_plan_id"]) == (
        "library",
        run.plan_id,
    )
    detail = expect(await client.get(f"/api/plans/{promoted['id']}"))
    assert (detail["source_plan_id"], detail["plan_run_id"]) == (run.plan_id, None)
    assert expect(await client.get(f"/api/plans/{promoted['id']}/draft")) == promoted

    assert (
        await plan_snapshot(db, run.plan_id),
        await plan_snapshot(db, library["id"]),
        await run_snapshot(db, run.run_id),
    ) == before


@pytest.mark.parametrize("body", ["none", "empty", "explicit draft"])
async def test_int_pr_02_save_the_working_copy_to_my_plans(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    clock: FrozenClock,
    library: dict[str, Any],
    spare_exercise: str,
    body: str,
) -> None:
    run = await create_run(client, db, library["revision_id"], clock)
    await edit_draft(client, run.plan_id, spare_exercise, "Block two")
    source = await read_tree(db, run.draft_id)
    before = (await plan_snapshot(db, run.plan_id), await run_snapshot(db, run.run_id))
    bodies_by_case: dict[str, dict[str, Any] | None] = {
        "none": None,
        "empty": {},
        "explicit draft": {"source_revision_id": run.draft_id},
    }

    promoted = await promote(client, run.plan_id, bodies_by_case[body])

    # The default name follows the "<name> copy" rule, from the run plan's current name.
    assert promoted["name"] == "Block two copy"
    assert await origin(db, promoted["id"]) == {
        "scope": "library",
        "source_plan_id": run.plan_id,
        "revision_id": promoted["revision_id"],
        "revision_no": 1,
        "status": "DRAFT",
        "based_on_revision_id": run.draft_id,
    }
    saved = await definition(db, promoted["revision_id"])
    assert saved == await definition(db, run.draft_id)
    assert saved != await definition(db, run.released_id)
    copied = await read_tree(db, promoted["revision_id"])
    assert_regenerated_progression_ids(
        source, copied, await progression_ids_outside(db, promoted["revision_id"])
    )
    assert await identity(db, promoted["id"]) == await identity(db, run.plan_id)
    assert promoted["id"] in await listed_plans(client)
    assert (await plan_snapshot(db, run.plan_id), await run_snapshot(db, run.run_id)) == before


async def test_int_pr_03_a_run_from_the_promoted_plan_is_independent(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    clock: FrozenClock,
    library: dict[str, Any],
    spare_exercise: str,
) -> None:
    """Draft half; the Apply half is E2E-05 (T6.1)."""
    original = await executed_run(client, db, library["revision_id"], clock)
    promoted = await promote(client, original.plan_id, {"source_revision_id": original.released_id})
    original_before = (
        await plan_snapshot(db, original.plan_id),
        await run_snapshot(db, original.run_id),
    )
    promoted_before = await plan_snapshot(db, promoted["id"])

    second = await executed_run(client, db, promoted["revision_id"], clock)

    assert len({library["id"], original.plan_id, promoted["id"], second.plan_id}) == 4
    assert await fingerprint(db, second.released_id) == await fingerprint(
        db, promoted["revision_id"]
    )
    assert (
        await plan_snapshot(db, original.plan_id),
        await run_snapshot(db, original.run_id),
    ) == original_before
    assert await plan_snapshot(db, promoted["id"]) == promoted_before
    source = await one(
        db, "SELECT source_plan_id FROM plans.workout_plans WHERE id = %s", second.plan_id
    )
    assert source == {"source_plan_id": promoted["id"]}
    # The two runs share no plan rows and no progression loop.
    runs = (original.run_id, second.run_id)
    shared = await one(
        db,
        """
        SELECT
            (SELECT count(*) FROM exec.workout_sessions AS a
             JOIN exec.workout_sessions AS b
               ON b.source_plan_workout_unit_id = a.source_plan_workout_unit_id
             WHERE a.plan_run_id = %s AND b.plan_run_id = %s) AS units,
            (SELECT count(*) FROM exec.exercise_unit_tracks AS a
             JOIN exec.exercise_unit_tracks AS b
               ON b.source_progression_id = a.source_progression_id
             WHERE a.plan_run_id = %s AND b.plan_run_id = %s) AS progressions
        """,
        *runs,
        *runs,
    )
    assert shared == {"units": 0, "progressions": 0}

    plans = {
        "library": library["id"],
        "original run plan": original.plan_id,
        "promoted": promoted["id"],
        "second run plan": second.plan_id,
    }

    async def everything_but(edited: str) -> dict[str, Any]:
        return {
            "plans": {
                label: await plan_snapshot(db, plan_id)
                for label, plan_id in plans.items()
                if label != edited
            },
            "runs": [
                await run_snapshot(db, original.run_id),
                await run_snapshot(db, second.run_id),
            ],
            "applied": [
                await fingerprint(db, original.released_id),
                await fingerprint(db, second.released_id),
            ],
        }

    for edited in ("promoted", "original run plan", "second run plan"):
        draft = expect(await client.get(f"/api/plans/{plans[edited]}/draft"))
        draft_before = await fingerprint(db, draft["revision_id"])
        before = await everything_but(edited)

        await edit_draft(client, plans[edited], spare_exercise, f"Edited {edited}")

        assert await fingerprint(db, draft["revision_id"]) != draft_before, edited
        assert await everything_but(edited) == before, edited


async def test_int_pr_04_a_foreign_source_revision_is_refused(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    clock: FrozenClock,
    library: dict[str, Any],
) -> None:
    run = await create_run(client, db, library["revision_id"], clock)
    other = await create_run(client, db, library["revision_id"], clock)
    before = await database_snapshot(db)
    cases = [
        (run.plan_id, library["revision_id"]),  # the library plan it was copied from
        (run.plan_id, other.released_id),  # another run's plan
        (run.plan_id, other.draft_id),
        (library["id"], run.released_id),  # a run plan's revision through the library plan
        (run.plan_id, 999_999),  # no such revision
        (run.plan_id, 2**40),  # beyond the column type
    ]

    for plan_id, revision_id in cases:
        refused = await client.post(
            f"/api/plans/{plan_id}/duplicate",
            json={"name": "Never saved", "source_revision_id": revision_id},
        )
        assert expect(refused, 422) == {
            "detail": f"source_revision_id {revision_id} does not belong to plan {plan_id}"
        }

    missing = await client.post(
        "/api/plans/999999/duplicate", json={"source_revision_id": run.released_id}
    )
    assert expect(missing, 404) == {"detail": "Plan 999999 was not found"}
    for body in (
        {"name": ""},
        {"name": "   "},
        {"name": "x" * 201},
        {"source_revision_id": 0},
        {"source_plan_id": run.plan_id},
    ):
        expect(await client.post(f"/api/plans/{run.plan_id}/duplicate", json=body), 422)
    assert await database_snapshot(db) == before


@pytest.mark.parametrize(
    "request_options",
    [
        pytest.param({}, id="no body"),
        pytest.param({"json": {}}, id="empty object"),
        pytest.param(
            {"content": b"", "headers": {"Content-Type": "application/json"}},
            id="empty JSON body",
        ),
        pytest.param({"json": {"name": None, "source_revision_id": None}}, id="null fields"),
    ],
)
async def test_int_pr_05_an_empty_body_duplicates_as_before(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    library: dict[str, Any],
    request_options: dict[str, Any],
) -> None:
    source = await read_tree(db, library["revision_id"])
    before = await plan_snapshot(db, library["id"])
    url = f"/api/plans/{library['id']}/duplicate"

    first = expect(await client.post(url, **request_options), 201)
    second = expect(await client.post(url, **request_options), 201)

    assert [first["name"], second["name"]] == [
        f"{library['name']} copy",
        f"{library['name']} copy 2",
    ]
    for duplicate in (first, second):
        assert (duplicate["scope"], duplicate["source_plan_id"], duplicate["plan_run_id"]) == (
            "library",
            None,
            None,
        )
        assert await origin(db, duplicate["id"]) == {
            "scope": "library",
            "source_plan_id": None,
            "revision_id": duplicate["revision_id"],
            "revision_no": 1,
            "status": "DRAFT",
            "based_on_revision_id": library["revision_id"],
        }
        copied = await read_tree(db, duplicate["revision_id"])
        assert bodies(copied, without=("progression_id",)) == bodies(
            source, without=("progression_id",)
        )
        assert_regenerated_progression_ids(
            source, copied, await progression_ids_outside(db, duplicate["revision_id"])
        )
        assert await identity(db, duplicate["id"]) == await identity(db, library["id"])
    assert await plan_snapshot(db, library["id"]) == before


async def test_int_pr_05_a_library_duplicate_takes_a_name_and_a_revision(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    library: dict[str, Any],
    spare_exercise: str,
) -> None:
    """A library→library duplicate records no source plan, whatever the body says."""
    applied_id = await new_target_revision(db, library["revision_id"], in_new_run_plan=False)
    await copy_tree(db, library["revision_id"], applied_id, False)
    await edit_draft(client, library["id"], spare_exercise, library["name"])
    assert await definition(db, applied_id) != await definition(db, library["revision_id"])

    # An explicit name is used as given: taken or padded with spaces.
    for name in (library["name"], library["name"], "  Spaced name  ", "x" * 200):
        duplicate = await promote(client, library["id"], {"name": name})
        assert (duplicate["name"], duplicate["source_plan_id"]) == (name, None)
        assert await definition(db, duplicate["revision_id"]) == await definition(
            db, library["revision_id"]
        )

    from_applied = await promote(client, library["id"], {"source_revision_id": applied_id})

    # The "copy" rule is unchanged, and the draft stays the default beside other revisions.
    assert from_applied["name"] == f"{library['name']} copy"
    assert await origin(db, from_applied["id"]) == {
        "scope": "library",
        "source_plan_id": None,
        "revision_id": from_applied["revision_id"],
        "revision_no": 1,
        "status": "DRAFT",
        "based_on_revision_id": applied_id,
    }
    assert await definition(db, from_applied["revision_id"]) == await definition(db, applied_id)
    default = await promote(client, library["id"])
    assert default["name"] == f"{library['name']} copy 2"
    assert (await origin(db, default["id"]))["based_on_revision_id"] == library["revision_id"]


async def test_int_pr_06_t_del_03_deleting_the_run_keeps_the_promoted_plan(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    clock: FrozenClock,
    library: dict[str, Any],
    spare_exercise: str,
) -> None:
    run = await executed_run(client, db, library["revision_id"], clock)
    await edit_draft(client, run.plan_id, spare_exercise, "Block two")
    promoted = [
        await promote(client, run.plan_id, {"source_revision_id": run.released_id}),
        await promote(client, run.plan_id, {"name": "From the working copy"}),
    ]

    async def saved(plan: dict[str, Any]) -> dict[str, Any]:
        return {
            "fingerprint": await fingerprint(db, plan["revision_id"]),
            "tree": await read_tree(db, plan["revision_id"]),
            "identity": await identity(db, plan["id"]),
            "draft": {
                key: value
                for key, value in expect(await client.get(f"/api/plans/{plan['id']}/draft")).items()
                if key != "source_plan_id"
            },
        }

    before = [await saved(plan) for plan in promoted]

    expect(await client.delete(f"{RUNS}/{run.run_id}"), 204)

    gone = await plan_snapshot(db, run.plan_id)
    assert all(value.startswith("0:") for value in gone.values()), gone
    listed = await listed_plans(client)
    for plan, expected in zip(promoted, before, strict=True):
        assert await saved(plan) == expected
        assert listed[plan["id"]]["source_plan_id"] is None
        lineage = await origin(db, plan["id"])
        assert (lineage["source_plan_id"], lineage["based_on_revision_id"]) == (None, None)
        assert (await client.get(plan["image_url"])).status_code == 200
        again = await create_run(client, db, plan["revision_id"], clock)
        assert await fingerprint(db, again.released_id) == expected["fingerprint"]


@pytest.mark.parametrize("deleted", ["promoted", "library"])
async def test_t_del_04_deleting_a_plan_after_promotion_leaves_the_run(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    clock: FrozenClock,
    library: dict[str, Any],
    deleted: str,
) -> None:
    run = await executed_run(client, db, library["revision_id"], clock)
    promoted = await promote(client, run.plan_id, {"source_revision_id": run.released_id})
    ids = {"promoted": promoted["id"], "library": library["id"]}
    survivor = ids["library" if deleted == "promoted" else "promoted"]

    async def run_plan_and_run() -> dict[str, Any]:
        return {
            "r1": await read_tree(db, run.released_id),
            "r2": await read_tree(db, run.draft_id),
            "identity": await identity(db, run.plan_id),
            "rows": await run_snapshot(db, run.run_id),
            "overview": expect(await client.get(f"{RUNS}/{run.run_id}/overview")),
        }

    before = await run_plan_and_run()
    run_plan_before = await plan_snapshot(db, run.plan_id)
    # Neither survivor refers to the deleted plan, so not one of its rows changes.
    survivor_before = await plan_snapshot(db, survivor)

    expect(await client.delete(f"/api/plans/{ids[deleted]}"), 204)

    assert (await client.get(f"/api/plans/{ids[deleted]}")).status_code == 404
    assert await run_plan_and_run() == before
    assert await plan_snapshot(db, survivor) == survivor_before
    if deleted == "promoted":
        assert await plan_snapshot(db, run.plan_id) == run_plan_before
    else:
        # Only the informational links to the deleted library plan are cleared (SET NULL).
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
        assert (await origin(db, promoted["id"]))["source_plan_id"] == run.plan_id
