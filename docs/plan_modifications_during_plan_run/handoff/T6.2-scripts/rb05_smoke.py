"""RB-05: run-creation smoke through the local API on the converted scratch DB (T-INT-RUN-04 + T-DEL-01 checks).

Creates a run from library plan LIB (default 15, also the source of converted runs 3 and 14), edits the
library draft (swap an exercise, change sets, drop a day), then deletes the library plan. Checks that the
new run and the converted runs of the same library plan are unaffected.
usage (from be/, PYTHONPATH=src, api-env.sh sourced): python rb05_smoke.py <base_url> [library_plan_id]
"""
import asyncio, copy, sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path("tests/integration").resolve()))
import httpx
from psycopg import AsyncConnection
from psycopg.rows import dict_row

from agonez_api.core.config import get_settings
from builders import exercise_slugs, expect
from test_run_creation import fingerprint, plan_snapshot, run_snapshot

BASE = sys.argv[1]
LIB = int(sys.argv[2]) if len(sys.argv) > 2 else 15
RUNS = "/api/v1/exec/plan-runs"


async def main() -> None:
    settings = get_settings()
    assert settings.db_port not in (33327, 3421) and settings.db_host == "127.0.0.1"
    db = await AsyncConnection.connect(settings.database_dsn, autocommit=True, row_factory=dict_row)
    client = httpx.AsyncClient(base_url=BASE, timeout=60)
    library = expect(await client.get(f"/api/plans/{LIB}/draft"))
    assert library["scope"] == "library", library["scope"]
    converted = [r["id"] for r in await (await db.execute(
        "SELECT r.id FROM exec.plan_runs r JOIN plans.workout_plans p ON p.id = r.run_plan_id "
        "WHERE p.source_plan_id = %s AND r.id IN (SELECT plan_run_id FROM public.agonez_0019_reference_map) ORDER BY r.id",
        (LIB,))).fetchall()]
    print(f"library plan {LIB} (draft revision {library['revision_id']}), converted runs from it: {converted}")

    overview = expect(await client.post(RUNS, json={
        "plan_revision_id": library["revision_id"], "name": "T6.2 smoke run",
        "starts_on": date.today().isoformat(), "microcycle_count": 2}), 201)
    new_run = int(overview["run"]["plan_run_id"])
    row = await (await db.execute(
        "SELECT run.run_plan_id AS plan_id, "
        "(SELECT id FROM plans.plan_revisions WHERE plan_id = run.run_plan_id AND status = 'RELEASED') AS r1, "
        "(SELECT id FROM plans.plan_revisions WHERE plan_id = run.run_plan_id AND status = 'DRAFT') AS r2 "
        "FROM exec.plan_runs run WHERE run.id = %s", (new_run,))).fetchone()
    assert row and row["plan_id"] and row["r1"] and row["r2"], row
    assert await fingerprint(db, row["r1"]) == await fingerprint(db, library["revision_id"])
    print(f"created run {new_run}: run plan {row['plan_id']} (r1 {row['r1']} RELEASED, r2 {row['r2']} DRAFT), "
          f"header {overview['run']['plan']['code']}")

    async def seen(run_id: int) -> dict:
        base = f"{RUNS}/{run_id}"
        queue = expect(await client.get(f"{base}/analysis/queue"))
        traces = sorted({e["exercise_trace_id"] for w in queue["workouts"] for e in w["exercises"]})
        plan = await (await db.execute(
            "SELECT run_plan_id FROM exec.plan_runs WHERE id = %s", (run_id,))).fetchone()
        revisions = await (await db.execute(
            "SELECT id FROM plans.plan_revisions WHERE plan_id = %s ORDER BY id", (plan["run_plan_id"],))).fetchall()
        return {
            "fingerprints": [await fingerprint(db, r["id"]) for r in revisions],
            "plan": await plan_snapshot(db, plan["run_plan_id"]),
            "rows": await run_snapshot(db, run_id),
            "overview": expect(await client.get(f"{base}/overview")),
            "microcycles": expect(await client.get(f"{base}/microcycles")),
            "next": [expect(await client.get(f"{base}/exercise-traces/{t}/next")) for t in traces],
        }

    watched = [new_run, *converted]
    before = {run: await seen(run) for run in watched}

    # T-INT-RUN-04: swap an exercise, change sets, delete a training day; the library save succeeds.
    used = {v["exercise_slug"] for d in library["days"] if d.get("workout_unit")
            for s in d["workout_unit"]["exercise_slots"] for v in s["variants"]}
    spare = next(slug for slug in await exercise_slugs(db, 100) if slug not in used)
    edited = copy.deepcopy(library)
    unit = next(d["workout_unit"] for d in edited["days"] if d.get("workout_unit"))
    unit["exercise_slots"][1]["variants"][0]["exercise_slug"] = spare
    for item in unit["exercise_slots"][0]["variants"][0]["sets"]:
        item["reps"] = {"min": 1, "max": 3}
    edited["days"].pop()
    saved = expect(await client.put(f"/api/plans/{LIB}/draft", json=edited))
    assert len(saved["days"]) == len(library["days"]) - 1
    after_edit = {run: await seen(run) for run in watched}
    for run in watched:
        assert after_edit[run] == before[run], f"run {run} changed after the library edit"
    print(f"library draft saved (exercise -> {spare}, sets changed, {len(saved['days'])} days): "
          f"runs {watched} unchanged")

    # T-DEL-01: delete the library plan: 204; source links NULL; everything else unchanged.
    response = await client.delete(f"/api/plans/{LIB}")
    assert response.status_code == 204, (response.status_code, response.text)
    assert (await client.get(f"/api/plans/{LIB}")).status_code == 404
    for run in watched:
        links = await (await db.execute(
            "SELECT p.source_plan_id, r1.based_on_revision_id FROM exec.plan_runs r "
            "JOIN plans.workout_plans p ON p.id = r.run_plan_id "
            "JOIN plans.plan_revisions r1 ON r1.plan_id = p.id AND r1.revision_no = 1 WHERE r.id = %s",
            (run,))).fetchone()
        assert links == {"source_plan_id": None, "based_on_revision_id": None}, (run, links)
        now = await seen(run)
        assert now["fingerprints"] == before[run]["fingerprints"], run
        assert now["rows"] == before[run]["rows"], run
        assert now["overview"] == before[run]["overview"], run
        assert now["microcycles"] == before[run]["microcycles"], run
        assert now["next"] == before[run]["next"], run
        changed = sorted(k for k in now["plan"] if now["plan"][k] != before[run]["plan"][k])
        assert changed == ["plans.plan_revisions", "plans.workout_plans"], (run, changed)
    print(f"DELETE /api/plans/{LIB} -> 204; runs {watched}: source_plan_id and r1.based_on_revision_id NULL, "
          "fingerprints, exec rows, overview, timeline and /next unchanged")
    print("RB-05 passed; smoke run id", new_run)
    await client.aclose(); await db.close()

asyncio.run(main())
