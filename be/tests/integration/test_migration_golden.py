"""T-MIG-10: migration 0019 changes no Execution read model (T2.3, ``06``).

Every run of the newest dump without 0019 is read through the API, 0019 runs through the real
runner, and everything is read again by the same code. ``golden.py`` documents what is read, the
normaliser and the allow-list of expected differences. Nothing here depends on particular ids,
so the module also checks a fresh dump (``AGONEZ_TEST_DB_DUMP``, T6.2). ``pytest -s`` prints how
many ids were translated and how often each allowed difference occurred.

``AGONEZ_GOLDEN_SAVE`` / ``AGONEZ_GOLDEN_BASELINE`` re-run the comparison with later code
(``golden.py``, "Re-running with later code").
"""

import os
from collections import Counter
from pathlib import Path

import httpx
import pytest
from conftest import RUN_PLAN_CONVERSION, FrozenClock, apply_migrations
from golden import (
    ADDITIVE_FIELDS,
    EXPECTED_AFTER_CONVERSION,
    Capture,
    Scope,
    capture,
    compare,
    load,
    mask_lineage_keys,
    observation_scope,
    save,
    settle,
    unanswered,
)
from psycopg import AsyncConnection
from test_migration_0019 import legacy_run_ids, reference_map, whole_database

from agonez_api.core.config import Settings

pytestmark = pytest.mark.before_migration(RUN_PLAN_CONVERSION)

SAVE_ENV = "AGONEZ_GOLDEN_SAVE"
BASELINE_ENV = "AGONEZ_GOLDEN_BASELINE"


def _require_meaningful(reads: Capture, scope: Scope) -> None:
    """The comparison is about something: the reads answer, and answer with content."""
    assert unanswered(reads) == []
    statuses = Counter((read.kind, document["status"]) for read, document in reads.items())
    print(f"HTTP answers: {sorted((kind, str(code), n) for (kind, code), n in statuses.items())}")
    for kind in ("mobile prescription", "mobile fallback preview"):
        assert statuses[(kind, 200)] > 0, kind
    assert any(run.workouts for run in scope.runs), "no workout in the dump"
    previews = {(read.run_id, read.at) for read in reads if read.kind == "mobile fallback preview"}
    pending = {(run.run_id, f"session {session}") for run in scope.runs for session in run.pending}
    assert pending and pending <= previews


async def test_mig_10_conversion_changes_no_execution_read_model(
    db: AsyncConnection,
    client: httpx.AsyncClient,
    settings: Settings,
    clock: FrozenClock,
    tmp_path: Path,
) -> None:
    legacy = await legacy_run_ids(db)
    assert legacy, "the dump holds no legacy run"
    scope = await observation_scope(db)
    assert set(legacy) <= {run.run_id for run in scope.runs}

    baseline = os.environ.get(BASELINE_ENV)
    if baseline:
        # Later code, which cannot read an unconverted database: compare with the saved capture.
        await apply_migrations(settings, tmp_path / "versions", through=RUN_PLAN_CONVERSION)
        await settle(client, clock, scope)
        current = mask_lineage_keys(await capture(client, db, clock, scope))
        result = compare(load(Path(baseline)), current, allowed=ADDITIVE_FIELDS)
        print(result.summary())
        result.require_clean(f"the reads differ from {baseline}")
        return

    # The capture before 0019 is stable: reconciling reads settle first, then two captures
    # are equal and nothing in the database moves between them.
    await settle(client, clock, scope)
    first = await capture(client, db, clock, scope)
    database = await whole_database(db)
    before = await capture(client, db, clock, scope)
    compare(first, before).require_clean("the capture before 0019 is not stable")
    assert await whole_database(db) == database, "a read wrote to the database"
    _require_meaningful(before, scope)

    await apply_migrations(settings, tmp_path / "versions", through=RUN_PLAN_CONVERSION)
    after = await capture(client, db, clock, scope)

    mapping = await reference_map(db)
    assert sorted({run_id for run_id, _, _ in mapping}) == legacy
    result = compare(before, after, allowed=EXPECTED_AFTER_CONVERSION, mapping=mapping)
    print(result.summary())
    result.require_clean("migration 0019 changed a read model")

    # Not vacuous: ids of every kind went through the map, and every legacy run really is
    # read from its run plan now.
    assert set(result.translated) == {
        "plan_revision",
        "day",
        "workout_unit",
        "exercise_slot",
        "exercise_variant",
        "set_infra",
    }, result.translated
    assert result.allowed[("stored rows", "$.plan_runs.*.run_plan_id")] == len(legacy)
    assert result.allowed[("exec plan-runs", "$.items[*].plan.plan_id")] == len(legacy)

    target = os.environ.get(SAVE_ENV)
    if target:
        save(after, Path(target))


async def test_the_golden_comparison_reports_a_wrong_conversion(
    db: AsyncConnection,
    client: httpx.AsyncClient,
    settings: Settings,
    clock: FrozenClock,
    tmp_path: Path,
) -> None:
    """The normaliser and the allow-list are not blind: three faults, each reported."""
    legacy = await legacy_run_ids(db)
    everything = await observation_scope(db, legacy)
    run_id = next(run.run_id for run in everything.runs if run.pending)
    scope = await observation_scope(db, [run_id])
    session = min(scope.runs[0].pending)

    await settle(client, clock, scope)
    before = await capture(client, db, clock, scope)
    await apply_migrations(settings, tmp_path / "versions", through=RUN_PLAN_CONVERSION)
    mapping = await reference_map(db)

    # 1. A valid but wrong target: the run starts from its working copy.
    await db.execute(
        """
        UPDATE exec.plan_runs AS pr
        SET initial_plan_revision_id = rev.id
        FROM plans.plan_revisions AS rev
        WHERE pr.id = %s AND rev.plan_id = pr.run_plan_id AND rev.status = 'DRAFT'
        """,
        (run_id,),
    )
    # 2. A pending session bound to another day of the same revision.
    await db.execute(
        """
        UPDATE exec.workout_sessions AS ws
        SET source_plan_day_id = (
            SELECT other.id FROM plans.day_prescriptions AS own
            JOIN plans.day_prescriptions AS other
              ON other.revision_id = own.revision_id AND other.id <> own.id
            WHERE own.id = ws.source_plan_day_id
            ORDER BY other.ordinal LIMIT 1
        )
        WHERE ws.id = %s
        """,
        (session,),
    )
    # 3. A copy that is not equal to its source.
    await db.execute(
        """
        UPDATE plans.set_infra_prescriptions AS item
        SET rep_max = item.rep_max + 1
        FROM plans.exercise_variants AS ev
        JOIN plans.exercise_slots AS es ON es.id = ev.slot_id
        JOIN plans.workout_unit_prescriptions AS wu ON wu.id = es.workout_unit_id
        JOIN plans.day_prescriptions AS dp ON dp.id = wu.day_id
        JOIN plans.plan_revisions AS rev ON rev.id = dp.revision_id
        JOIN exec.plan_runs AS pr ON pr.run_plan_id = rev.plan_id
        WHERE item.exercise_variant_id = ev.id AND pr.id = %s
        """,
        (run_id,),
    )

    result = compare(
        before,
        await capture(client, db, clock, scope),
        allowed=EXPECTED_AFTER_CONVERSION,
        mapping=mapping,
    )
    found = {(item.read.kind, item.generic_path) for item in result.unexpected}
    assert {
        ("exec overview", "$.run.initial_revision.plan_revision_id"),
        ("exec overview", "$.run.initial_revision.revision_no"),
        ("stored rows", "$.plan_runs.*.initial_plan_revision_id"),
        ("stored rows", "$.workout_sessions.*.source_plan_day_id"),
        ("exec calendar", "$.sessions[*].day_ordinal"),
        ("exec exercise-trace", "$.trace.current_plan.sets[*].rep_max"),
        ("mobile fallback preview", "$.exercises[*].sets[*].rep_max"),
    } <= found, result.report()
    with pytest.raises(AssertionError, match="unexpected difference"):
        result.require_clean("the faults must fail the comparison")
