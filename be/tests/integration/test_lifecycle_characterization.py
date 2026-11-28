"""Characterisation of the run lifecycle defects R1-R5 (T-REG-01..06).

Each test states the behaviour we want for one defect of
``docs/plan_modifications_during_plan_run/00-current-state-audit.md`` section 6. They were
strict xfails (T0.2) until T2.2 gave every new run its own copy of the plan: each edits the
library plan, so run isolation fixes all of them. They now guard against a regression.

Set-up runs inside ``setting_up()``, which turns its assertion errors into ``SetupFailed``,
so a broken precondition is told apart from the defect coming back.
"""

from collections.abc import AsyncIterator, Iterator
from contextlib import contextmanager
from dataclasses import dataclass
from typing import Any
from uuid import uuid4

import httpx
import pytest
from builders import (
    DEVICE_ID,
    PlanSpec,
    SetSpec,
    SlotSpec,
    exercise_slugs,
    expect,
    finalize_session,
    make_library_plan,
    make_run,
    rest,
    run_sessions,
    training,
)
from conftest import FrozenClock
from fastapi import FastAPI
from psycopg import AsyncConnection

DEVICE_HEADERS = {"X-Agonez-Device-Id": str(DEVICE_ID)}


class SetupFailed(Exception):
    """A precondition broke. Not an AssertionError, so it is told apart from the defect."""


@contextmanager
def setting_up() -> Iterator[None]:
    try:
        yield
    except AssertionError as error:
        raise SetupFailed(str(error)) from error


@dataclass(frozen=True)
class LibraryRun:
    """A library plan and a two-microcycle run created from it, starting today."""

    plan: dict[str, Any]  # the saved library draft; change it and PUT it back
    run_id: int
    sessions: list[dict[str, Any]]  # in calendar order; [0] is today's "Upper"
    spare_exercise: str  # a catalog slug the plan does not use

    @property
    def draft_url(self) -> str:
        return f"/api/plans/{self.plan['id']}/draft"

    @property
    def upper_slots(self) -> list[dict[str, Any]]:
        return self.plan["days"][0]["workout_unit"]["exercise_slots"]


@pytest.fixture
async def library_run(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    clock: FrozenClock,
) -> LibraryRun:
    with setting_up():
        press, fly, squat, spare = await exercise_slugs(db, 4)
        plan = await make_library_plan(
            client,
            PlanSpec(
                name="Characterisation plan",
                days=(
                    # Different set schemes, so exchanged structures are visible.
                    training(
                        "Upper",
                        SlotSpec(press, sets=(SetSpec(4, 6),) * 3),
                        SlotSpec(fly, sets=(SetSpec(10, 15),) * 2),
                    ),
                    rest(),
                    training("Lower", SlotSpec(squat)),
                ),
            ),
        )
        overview = await make_run(client, plan["revision_id"], clock.today, 2)
        return LibraryRun(
            plan=plan,
            run_id=overview["run"]["plan_run_id"],
            sessions=run_sessions(overview),
            spare_exercise=spare,
        )


@pytest.fixture
async def lenient_client(app: FastAPI) -> AsyncIterator[httpx.AsyncClient]:
    """Answers an unhandled server error with HTTP 500, as the deployed API does."""
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app, raise_app_exceptions=False),
        base_url="http://testserver",
    ) as http:
        yield http


async def _overview(client: httpx.AsyncClient, run_id: int) -> dict[str, Any]:
    return expect(await client.get(f"/api/v1/exec/plan-runs/{run_id}/overview"))


async def _analysis_queue(client: httpx.AsyncClient, run_id: int) -> dict[str, Any]:
    return expect(await client.get(f"/api/v1/exec/plan-runs/{run_id}/analysis/queue"))


async def _exercise_names(client: httpx.AsyncClient, run_id: int) -> dict[int, str]:
    """The exercise each of the run's exercise tracks is shown as."""
    queue = await _analysis_queue(client, run_id)
    return {
        item["exercise_trace_id"]: item["name"]
        for workout in queue["workouts"]
        for item in workout["exercises"]
    }


async def _trainable(client: httpx.AsyncClient, session_id: int) -> dict[int, tuple]:
    """Per exercise track, what the athlete would train: a read-only fallback preview."""
    preview = expect(
        await client.get(
            f"/api/v1/mobile/sessions/{session_id}/prescription/fallback",
            headers=DEVICE_HEADERS,
        )
    )
    return {
        exercise["exercise_track_id"]: (
            exercise["exercise"]["slug"],
            tuple(
                (item["ordinal"], item["role"], item["rep_min"], item["rep_max"])
                for item in exercise["sets"]
            ),
        )
        for exercise in preview["exercises"]
    }


async def _definition_seen_by_run(
    client: httpx.AsyncClient,
    run: LibraryRun,
) -> dict[str, Any]:
    """Every place where Execution shows the run's training definition."""
    base = f"/api/v1/exec/plan-runs/{run.run_id}"
    names = await _exercise_names(client, run.run_id)
    workout_traces = expect(await client.get(f"{base}/workout-traces"))["items"]
    return {
        "overview": await _overview(client, run.run_id),
        "analysis_queue": await _analysis_queue(client, run.run_id),
        # Current plan sets, next prescription and the plan context of completed exposures.
        "exercise_traces": {
            track_id: expect(await client.get(f"{base}/exercise-traces/{track_id}"))
            for track_id in names
        },
        "workout_traces": [
            expect(await client.get(f"{base}/workout-traces/{item['workout_trace_id']}"))
            for item in workout_traces
        ],
        # sessions[2] is the second "Upper"; sessions[0] is already completed.
        "next_upper_session": await _trainable(client, run.sessions[2]["session_id"]),
    }


async def test_reg_01_library_edit_leaves_run_definition_unchanged(
    client: httpx.AsyncClient,
    clock: FrozenClock,
    library_run: LibraryRun,
) -> None:
    """R1: a run's definition must not follow the library plan it was created from."""
    with setting_up():
        await finalize_session(client, library_run.sessions[0]["session_id"], clock.today)
        before = await _definition_seen_by_run(client, library_run)

        # Definition only: the plan's name and colour are identity, not part of a revision.
        first, second = library_run.upper_slots
        library_run.plan["days"][0]["workout_unit"]["name"] = "Upper, edited"
        sets = first["variants"][0]["sets"]
        for item in sets:
            item["reps"] = {"min": 12, "max": 15}
        sets.append({**sets[-1], "id": None, "ordinal": len(sets)})
        second["variants"][0]["exercise_slug"] = library_run.spare_exercise
        expect(await client.put(library_run.draft_url, json=library_run.plan))

    after = await _definition_seen_by_run(client, library_run)

    assert after == before


async def test_reg_02_library_training_day_can_be_removed(
    client: httpx.AsyncClient,
    lenient_client: httpx.AsyncClient,
    library_run: LibraryRun,
) -> None:
    """R2: removing a training day from a library plan with a run must save (500 today)."""
    with setting_up():
        before = await _overview(client, library_run.run_id)
        lower = library_run.plan["days"].pop()
        assert lower["workout_unit"]["name"] == "Lower"

    response = await lenient_client.put(library_run.draft_url, json=library_run.plan)

    assert response.is_success, f"{response.status_code}: {response.text}"
    assert len(response.json()["days"]) == 2
    assert await _overview(client, library_run.run_id) == before


async def test_reg_03_library_plan_with_runs_can_be_deleted(
    client: httpx.AsyncClient,
    lenient_client: httpx.AsyncClient,
    library_run: LibraryRun,
) -> None:
    """R2: deleting a library plan that has runs must succeed (500 today)."""
    with setting_up():
        before = await _overview(client, library_run.run_id)

    response = await lenient_client.delete(f"/api/plans/{library_run.plan['id']}")

    assert response.status_code == 204, f"{response.status_code}: {response.text}"
    after = await _overview(client, library_run.run_id)
    # The deleted plan may disappear from the run header; the training must stay.
    for key in ("microcycles", "current_microcycle_sessions", "analysis_readiness"):
        assert after[key] == before[key]


async def test_reg_04_library_slot_reorder_keeps_every_track_exercise(
    client: httpx.AsyncClient,
    library_run: LibraryRun,
) -> None:
    """R3: positional track identity must not hand one exercise's track to another."""
    today = library_run.sessions[0]["session_id"]
    with setting_up():
        names = await _exercise_names(client, library_run.run_id)
        trainable = await _trainable(client, today)

        slots = library_run.upper_slots
        slots.reverse()
        for ordinal, slot in enumerate(slots):
            slot["ordinal"] = ordinal
        expect(await client.put(library_run.draft_url, json=library_run.plan))

    assert await _exercise_names(client, library_run.run_id) == names
    assert await _trainable(client, today) == trainable


async def test_reg_05_added_library_slot_keeps_next_session_startable(
    client: httpx.AsyncClient,
    clock: FrozenClock,
    library_run: LibraryRun,
) -> None:
    """R4: an exercise added in My Plans must not block the run's next workout on mobile."""
    today = library_run.sessions[0]["session_id"]
    with setting_up():
        trainable = await _trainable(client, today)

        slots = library_run.upper_slots
        added = {**slots[-1], "id": None, "ordinal": len(slots)}
        added["variants"] = [
            {
                **variant,
                "id": None,
                "exercise_slug": library_run.spare_exercise,
                "sets": [{**item, "id": None} for item in variant["sets"]],
            }
            for variant in added["variants"]
        ]
        slots.append(added)
        expect(await client.put(library_run.draft_url, json=library_run.plan))

    prepared = expect(
        await client.post(
            f"/api/v1/mobile/sessions/{today}/prescription/fallback",
            headers=DEVICE_HEADERS,
        )
    )
    assert {item["exercise_track_id"] for item in prepared["exercises"]} == set(trainable)
    expect(
        await client.post(
            "/api/v1/mobile/workouts",
            headers=DEVICE_HEADERS,
            json={
                "workout_id": str(uuid4()),
                "session_id": today,
                "prescription_version": prepared["prescription_version"],
                "started_at": f"{clock.today.isoformat()}T17:00:00+00:00",
                "allow_missing_loads": True,
            },
        ),
        201,
    )


async def test_reg_06_deleted_unprescribed_slot_keeps_overview_readable(
    client: httpx.AsyncClient,
    db: AsyncConnection,
    library_run: LibraryRun,
) -> None:
    """R5: deleting a never-prescribed slot must not turn the run overview into a 404."""
    with setting_up():
        before = await _overview(client, library_run.run_id)
        prescribed = await (
            await db.execute(
                """
                SELECT count(*) AS total
                FROM exec.workout_unit_prescriptions AS prescription
                JOIN exec.workout_sessions AS session
                  ON session.id = prescription.workout_session_id
                WHERE session.plan_run_id = %s
                """,
                (library_run.run_id,),
            )
        ).fetchone()
        assert prescribed == {"total": 0}

        library_run.upper_slots.pop()
        expect(await client.put(library_run.draft_url, json=library_run.plan))

    assert await _overview(client, library_run.run_id) == before
