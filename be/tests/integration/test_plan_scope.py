"""The plans module with run-scope plans (T1.2): loader, copy, fingerprint, scope guards.

T-API-PLANS-01…05 (``07`` §3) and the T1.2 acceptance criteria (``06``). Run plans are made
by hand here (run creation copies plans from T2.2 on): a ``scope = 'run'`` plan with a RELEASED
revision 1 and a DRAFT revision 2, both copied with ``copy_revision``, optionally bound to a
run created from the library plan.
"""

import copy
from dataclasses import dataclass
from typing import Any

import httpx
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
from conftest import FrozenClock
from plan_trees import (
    assert_regenerated_progression_ids,
    bodies,
    built_plan_revision,
    progression_ids_outside,
    read_tree,
)
from psycopg import AsyncConnection, errors

from agonez_api.modules.plans.exceptions import PlanRevisionNotFoundError
from agonez_api.modules.plans.fingerprint import definition_fingerprint
from agonez_api.modules.plans.repository import copy_revision, load_revision_rows

RUN_PLAN_DELETE_DETAIL = "Run plans are deleted together with their plan run"


@dataclass(frozen=True)
class RunPlan:
    plan_id: int
    released_id: int
    draft_id: int


async def make_run_plan(
    db: AsyncConnection,
    library: dict[str, Any],
    *,
    name: str | None = None,
) -> RunPlan:
    """A run plan copied from a library draft: r1 RELEASED, r2 DRAFT (``02`` §3.3)."""
    plan = await (
        await db.execute(
            """
            INSERT INTO plans.workout_plans (name, description, accent, scope, source_plan_id)
            VALUES (%s, %s, %s, 'run', %s)
            RETURNING id
            """,
            (name or library["name"], library["description"], library["accent"], library["id"]),
        )
    ).fetchone()
    assert plan is not None
    released = await (
        await db.execute(
            """
            INSERT INTO plans.plan_revisions
                (plan_id, revision_no, status, based_on_revision_id, released_at)
            VALUES (%s, 1, 'RELEASED', %s, now())
            RETURNING id
            """,
            (plan["id"], library["revision_id"]),
        )
    ).fetchone()
    assert released is not None
    await copy_revision(
        db, library["revision_id"], released["id"], regenerate_progression_ids=False
    )
    draft = await (
        await db.execute(
            """
            INSERT INTO plans.plan_revisions (plan_id, revision_no, status, based_on_revision_id)
            VALUES (%s, 2, 'DRAFT', %s)
            RETURNING id
            """,
            (plan["id"], released["id"]),
        )
    ).fetchone()
    assert draft is not None
    await copy_revision(db, released["id"], draft["id"], regenerate_progression_ids=False)
    return RunPlan(plan["id"], released["id"], draft["id"])


async def bind_to_new_run(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    library: dict[str, Any],
    run_plan: RunPlan,
    clock: FrozenClock,
) -> int:
    """A run created from the library plan whose ``run_plan_id`` is set by hand (T2.2's job)."""
    overview = await make_run(client, library["revision_id"], clock.today, 1)
    run_id = int(overview["run"]["plan_run_id"])
    await db.execute(
        "UPDATE exec.plan_runs SET run_plan_id = %s WHERE id = %s", (run_plan.plan_id, run_id)
    )
    return run_id


async def fingerprint(db: AsyncConnection, revision_id: int, **options: bool) -> str:
    return definition_fingerprint(await load_revision_rows(db, revision_id), **options)


@pytest.fixture
async def library(client: httpx.AsyncClient, db: AsyncConnection) -> dict[str, Any]:
    press, row, squat = await exercise_slugs(db, 3)
    return await make_library_plan(
        client,
        PlanSpec(
            name="Scope plan",
            days=(
                training("Upper", SlotSpec(press, fallbacks=(row,)), SlotSpec(row)),
                rest(),
                training("Lower", SlotSpec(squat)),
            ),
        ),
    )


async def test_api_plans_01_list_shows_library_plans_only(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    library: dict[str, Any],
) -> None:
    """T-API-PLANS-01; plans created through the API are library plans."""
    run_plan = await make_run_plan(db, library, name=f"{library['name']} copy")

    listed = expect(await client.get("/api/plans"))["items"]

    by_id = {item["id"]: item for item in listed}
    assert run_plan.plan_id not in by_id
    assert by_id[library["id"]]["scope"] == "library"
    assert by_id[library["id"]]["source_plan_id"] is None
    assert {item["scope"] for item in listed} == {"library"}
    scopes = await (
        await db.execute("SELECT DISTINCT scope::text FROM plans.workout_plans")
    ).fetchall()
    assert {row["scope"] for row in scopes} == {"library", "run"}

    # A run plan's name does not take a duplicate name: My Plans does not show it.
    duplicate = expect(await client.post(f"/api/plans/{library['id']}/duplicate"), 201)
    assert duplicate["name"] == f"{library['name']} copy"
    assert duplicate["scope"] == "library"


async def test_api_plans_02_run_plan_is_not_deleted_through_the_plans_api(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    library: dict[str, Any],
    clock: FrozenClock,
) -> None:
    """T-API-PLANS-02: 409 with the documented detail, with or without its run."""
    unbound = await make_run_plan(db, library)
    bound = await make_run_plan(db, library)
    await bind_to_new_run(client, db, library, bound, clock)

    for run_plan in (unbound, bound):
        response = await client.delete(f"/api/plans/{run_plan.plan_id}")
        assert response.status_code == 409, response.text
        assert response.json() == {"detail": RUN_PLAN_DELETE_DETAIL}
        revisions = await (
            await db.execute(
                "SELECT count(*) AS n FROM plans.plan_revisions WHERE plan_id = %s",
                (run_plan.plan_id,),
            )
        ).fetchone()
        assert revisions is not None and revisions["n"] == 2

    assert (await client.delete("/api/plans/987654")).status_code == 404


async def test_api_plans_03_library_plan_with_runs_is_refused_instead_of_500(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    library: dict[str, Any],
    clock: FrozenClock,
) -> None:
    """T-API-PLANS-03, interim (T1.2): 409, not 500, while a run still uses the plan's rows.

    The matrix expects 204: runs stop referencing library rows when run creation copies the
    plan (T2.2, new runs) and when 0019 converts the old runs (T2.1). T2.2 turns this into 204.
    """
    overview = await make_run(client, library["revision_id"], clock.today, 1)
    run_id = overview["run"]["plan_run_id"]

    response = await client.delete(f"/api/plans/{library['id']}")

    assert response.status_code == 409, response.text
    assert response.json() == {"detail": f"Plan {library['id']} is still used by a plan run"}
    assert expect(await client.get(f"/api/plans/{library['id']}/draft")) == library
    after = expect(await client.get(f"/api/v1/exec/plan-runs/{run_id}/overview"))
    assert after["microcycles"] == overview["microcycles"]

    # A library plan without runs is deleted as before.
    unused = expect(await client.post(f"/api/plans/{library['id']}/duplicate"), 201)
    expect(await client.delete(f"/api/plans/{unused['id']}"), 204)
    assert (await client.get(f"/api/plans/{unused['id']}")).status_code == 404


async def test_api_plans_04_run_plan_draft_round_trip(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    library: dict[str, Any],
    clock: FrozenClock,
) -> None:
    """T-API-PLANS-04: GET→PUT of a run plan's draft with the new fields; they are read-only."""
    run_plan = await make_run_plan(db, library)
    run_id = await bind_to_new_run(client, db, library, run_plan, clock)
    released_before = await read_tree(db, run_plan.released_id)
    released_fingerprint = await fingerprint(db, run_plan.released_id)

    draft = expect(await client.get(f"/api/plans/{run_plan.plan_id}/draft"))
    assert (draft["scope"], draft["source_plan_id"], draft["plan_run_id"]) == (
        "run",
        library["id"],
        run_id,
    )
    assert (draft["revision_id"], draft["revision_no"]) == (run_plan.draft_id, 2)
    detail = expect(await client.get(f"/api/plans/{run_plan.plan_id}"))
    assert (detail["scope"], detail["source_plan_id"], detail["plan_run_id"]) == (
        "run",
        library["id"],
        run_id,
    )
    assert [(item["id"], item["status"]) for item in detail["revisions"]] == [
        (run_plan.draft_id, "DRAFT"),
        (run_plan.released_id, "RELEASED"),
    ]
    library_draft = expect(await client.get(f"/api/plans/{library['id']}/draft"))
    assert (library_draft["scope"], library_draft["plan_run_id"]) == ("library", None)

    # Unchanged round trip: accepted, nothing in the definition changes.
    saved = expect(await client.put(f"/api/plans/{run_plan.plan_id}/draft", json=draft))
    assert saved == {**draft, "lock_version": draft["lock_version"] + 1}
    assert await fingerprint(db, run_plan.draft_id) == released_fingerprint

    # Read-only fields are ignored, not applied.
    tampered = {**saved, "scope": "library", "source_plan_id": None, "plan_run_id": 1}
    saved = expect(await client.put(f"/api/plans/{run_plan.plan_id}/draft", json=tampered))
    assert (saved["scope"], saved["source_plan_id"], saved["plan_run_id"]) == (
        "run",
        library["id"],
        run_id,
    )

    # The working copy is edited like any draft; the applied revision is not touched.
    edited = copy.deepcopy(saved)
    edited["days"][0]["workout_unit"]["exercise_slots"][0]["variants"][0]["sets"][0]["reps"][
        "max"
    ] = 12
    expect(await client.put(f"/api/plans/{run_plan.plan_id}/draft", json=edited))
    assert await fingerprint(db, run_plan.draft_id) != released_fingerprint
    assert await read_tree(db, run_plan.released_id) == released_before
    assert await fingerprint(db, run_plan.released_id) == released_fingerprint
    # Still excluded from My Plans after its identity fields were saved.
    listed = expect(await client.get("/api/plans"))["items"]
    assert run_plan.plan_id not in {item["id"] for item in listed}


async def test_api_plans_05_analysis_and_export_work_for_a_run_plan(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    library: dict[str, Any],
) -> None:
    """T-API-PLANS-05: the draft endpoints are reused unchanged."""
    run_plan = await make_run_plan(db, library)

    analysis = await client.post(f"/api/plans/{run_plan.plan_id}/draft/analysis", json={})
    export = await client.post(f"/api/plans/{run_plan.plan_id}/draft/export", json={})

    assert analysis.status_code == 200, analysis.text
    assert export.status_code == 200, export.text
    library_export = expect(await client.post(f"/api/plans/{library['id']}/draft/export", json={}))
    assert export.json() == library_export


async def test_loader_reads_any_revision_and_fingerprints_follow_lineage(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    library: dict[str, Any],
    clock: FrozenClock,
) -> None:
    """Acceptance (``06`` T1.2): fingerprint is id-insensitive and lineage-sensitive."""
    run_plan = await make_run_plan(db, library)
    run_id = await bind_to_new_run(client, db, library, run_plan, clock)

    released = await load_revision_rows(db, run_plan.released_id)
    assert released.header["revision_status"] == "RELEASED"
    assert (released.header["scope"], released.header["plan_run_id"]) == ("run", run_id)
    assert released.header["revision_no"] == 1
    assert all(row["lineage_key"] for row in (*released.workout_units, *released.slots))

    # Copies (new ids, same lineage and progression ids) fingerprint like their source.
    library_fingerprint = await fingerprint(db, library["revision_id"])
    assert await fingerprint(db, run_plan.released_id) == library_fingerprint
    assert await fingerprint(db, run_plan.draft_id) == library_fingerprint

    # Removing a slot and adding an identical one: same API body apart from ids, new lineage.
    draft = expect(await client.get(f"/api/plans/{run_plan.plan_id}/draft"))
    slots = draft["days"][0]["workout_unit"]["exercise_slots"]
    readded = copy.deepcopy(slots[1])
    readded["id"] = None
    for variant in readded["variants"]:
        variant["id"] = None
        for item in variant["sets"]:
            item["id"] = None
    slots[1] = readded
    saved = expect(await client.put(f"/api/plans/{run_plan.plan_id}/draft", json=draft))
    assert saved["days"][0]["workout_unit"]["exercise_slots"][1]["id"] != readded["id"]
    assert await fingerprint(db, run_plan.draft_id) != library_fingerprint

    with pytest.raises(PlanRevisionNotFoundError):
        await load_revision_rows(db, 987654)


async def test_copy_revision_returns_the_id_map_and_refuses_a_non_empty_target(
    db: AsyncConnection,
    library: dict[str, Any],
) -> None:
    run_plan = await make_run_plan(db, library)
    source = await load_revision_rows(db, library["revision_id"])
    target = await load_revision_rows(db, run_plan.released_id)

    # Copy the draft once more into a fresh revision and check the returned map.
    created = await (
        await db.execute(
            """
            INSERT INTO plans.plan_revisions (plan_id, revision_no, status, released_at)
            VALUES (%s, 3, 'RELEASED', now())
            RETURNING id
            """,
            (run_plan.plan_id,),
        )
    ).fetchone()
    assert created is not None
    mapping = await copy_revision(
        db, run_plan.draft_id, created["id"], regenerate_progression_ids=False
    )
    draft = await load_revision_rows(db, run_plan.draft_id)
    copied = await load_revision_rows(db, created["id"])
    for entity, rows in (
        ("day", "days"),
        ("workout_unit", "workout_units"),
        ("exercise_slot", "slots"),
        ("exercise_variant", "variants"),
        ("set_infra", "sets"),
    ):
        assert set(mapping[entity]) == {row["id"] for row in getattr(draft, rows)}, entity
        assert set(mapping[entity].values()) == {row["id"] for row in getattr(copied, rows)}
    assert len(target.slots) == len(source.slots)

    with pytest.raises(errors.ObjectNotInPrerequisiteState):
        await copy_revision(
            db, library["revision_id"], run_plan.draft_id, regenerate_progression_ids=False
        )


async def test_duplicate_copies_the_draft_with_the_sql_function(
    client: httpx.AsyncClient,
    db: AsyncConnection,
) -> None:
    """``duplicate_plan`` = ``copy_revision(…, regenerate_progression_ids=True)``.

    Replaces the unit test of the removed Python remapping (``_copy_draft_tree``). Every column
    is copied as stored: lineage keys, and ``load_step_kg`` raw (a NULL stays NULL; the API
    shows the resistance-source default either way). Progression ids are fresh, sharing kept.
    """
    source_id = await built_plan_revision(client, db)
    source = await read_tree(db, source_id)
    others = await progression_ids_outside(db, source_id)
    plan_row = await (
        await db.execute("SELECT plan_id FROM plans.plan_revisions WHERE id = %s", (source_id,))
    ).fetchone()
    assert plan_row is not None
    plan_id = plan_row["plan_id"]
    source_artifact = expect(await client.get(f"/api/plans/{plan_id}/draft"))

    duplicate = expect(await client.post(f"/api/plans/{plan_id}/duplicate"), 201)

    copied = await read_tree(db, duplicate["revision_id"])
    assert bodies(copied, without=("progression_id",)) == bodies(
        source, without=("progression_id",)
    )
    assert_regenerated_progression_ids(source, copied, others)
    assert copied["exercise_variant"][(0, 0, 0)].body["load_step_kg"] is None
    for entity in ("workout_unit", "exercise_slot"):
        for path, node in source[entity].items():
            assert copied[entity][path].body["lineage_key"] == node.body["lineage_key"]

    revision = await (
        await db.execute(
            "SELECT revision_no, status::text AS status, based_on_revision_id "
            "FROM plans.plan_revisions WHERE id = %s",
            (duplicate["revision_id"],),
        )
    ).fetchone()
    assert revision == {"revision_no": 1, "status": "DRAFT", "based_on_revision_id": source_id}

    # The API shows the same plan: new ids, name and progression ids only.
    def comparable(artifact: dict[str, Any]) -> Any:
        days = copy.deepcopy(artifact["days"])
        for day in days:
            day["id"] = None
            unit = day["workout_unit"]
            if unit is None:
                continue
            unit["id"] = None
            for slot in unit["exercise_slots"]:
                slot["id"] = None
                for variant in slot["variants"]:
                    variant["id"] = variant["progression_id"] = None
                    for item in variant["sets"]:
                        item["id"] = None
        return days

    assert comparable(duplicate) == comparable(source_artifact)
    assert duplicate["name"] == f"{source_artifact['name']} copy"
    assert (duplicate["scope"], duplicate["source_plan_id"], duplicate["plan_run_id"]) == (
        "library",
        None,
        None,
    )
    assert await fingerprint(db, duplicate["revision_id"]) != await fingerprint(db, source_id)
    assert await fingerprint(
        db, duplicate["revision_id"], include_progression_ids=False
    ) == await fingerprint(db, source_id, include_progression_ids=False)
