"""Run plans: the private copy of a plan that a plan run executes (``02`` §3.2, §3.3; D1-D4).

Every function here works inside the caller's transaction. Run creation
(``ExecutionRepository.create_plan_run``) first locks and checks its source with
``lock_library_source``, then copies it with ``create_run_plan``; the run itself is inserted
afterwards and points at the copy (``plan_runs.run_plan_id``).
"""

from collections.abc import Sequence
from dataclasses import dataclass
from typing import Any, cast

from agonez_api.core.database import DatabasePool
from agonez_api.modules.execution.errors import ExecutionAPIError, invalid, not_found
from agonez_api.modules.plans.executability import (
    ExecutabilityIssue,
    summarize_issues,
    validate_executable,
)
from agonez_api.modules.plans.repository import RevisionCopyMap, copy_revision, load_revision_rows

Row = dict[str, Any]


@dataclass(frozen=True)
class CreatedRunPlan:
    plan_id: int
    released_revision_id: int  # r1, what the new run executes
    draft_revision_id: int  # r2, the working copy
    released_copy: RevisionCopyMap  # source revision row id -> r1 row id


class RunPlanRepository:
    def __init__(self, pool: DatabasePool) -> None:
        self._pool = pool

    async def lock_library_source(self, connection: Any, revision_id: int) -> Row:
        """Lock the source plan ``FOR SHARE`` and check that a run may be created from it.

        The lock keeps a concurrent draft save (which locks the plan ``FOR UPDATE``) out
        until the copy is taken, so the copy is one consistent snapshot. Raises 404
        ``plan_revision_not_found``, 422 ``plan_revision_not_library`` for a run plan's
        revision, and 422 ``plan_not_executable`` with the issues of ``validate_executable``
        (``03`` §3 without the day-count rule; Q1).
        """
        source = await _fetch_optional(
            connection,
            """
            SELECT revision.id AS revision_id, plan.id AS plan_id, plan.name,
                   plan.description, plan.accent::text AS accent, plan.scope::text AS scope
            FROM plans.plan_revisions AS revision
            JOIN plans.workout_plans AS plan ON plan.id = revision.plan_id
            WHERE revision.id = %s
            FOR SHARE OF plan
            """,
            (revision_id,),
        )
        if source is None:
            raise not_found("plan_revision_not_found", "Plan revision was not found")
        if source["scope"] != "library":
            raise invalid(
                "plan_revision_not_library",
                "Runs are created from a plan in My Plans, not from another run's plan",
                {"plan_revision_id": revision_id, "plan_id": source["plan_id"]},
            )
        issues = validate_executable(await load_revision_rows(connection, revision_id))
        if issues:
            raise not_executable("plan_not_executable", issues)
        return source

    async def create_run_plan(self, connection: Any, *, source: Row) -> CreatedRunPlan:
        """Copy a locked library revision into a new run plan: r1 RELEASED and r2 DRAFT.

        ``source`` is the row ``lock_library_source`` returned. Name, description, accent
        and cover image are copied; progression ids and lineage keys are kept
        (``regenerate_progression_ids = false``), so the run's progression loops and track
        identities match the source.
        """
        plan = await _fetch_one(
            connection,
            """
            INSERT INTO plans.workout_plans (name, description, accent, scope, source_plan_id)
            VALUES (%s, %s, %s, 'run', %s)
            RETURNING id
            """,
            (source["name"], source["description"], source["accent"], source["plan_id"]),
        )
        plan_id = cast(int, plan["id"])
        async with connection.cursor() as cursor:
            await cursor.execute(
                """
                INSERT INTO plans.plan_images (plan_id, content_type, byte_size, checksum, data)
                SELECT %s, content_type, byte_size, checksum, data
                FROM plans.plan_images
                WHERE plan_id = %s
                """,
                (plan_id, source["plan_id"]),
            )
        released = await _fetch_one(
            connection,
            """
            INSERT INTO plans.plan_revisions
                (plan_id, revision_no, status, based_on_revision_id, released_at)
            VALUES (%s, 1, 'RELEASED', %s, now())
            RETURNING id
            """,
            (plan_id, source["revision_id"]),
        )
        released_id = cast(int, released["id"])
        released_copy = await copy_revision(
            connection,
            cast(int, source["revision_id"]),
            released_id,
            regenerate_progression_ids=False,
        )
        draft = await _fetch_one(
            connection,
            """
            INSERT INTO plans.plan_revisions (plan_id, revision_no, status, based_on_revision_id)
            VALUES (%s, 2, 'DRAFT', %s)
            RETURNING id
            """,
            (plan_id, released_id),
        )
        draft_id = cast(int, draft["id"])
        await copy_revision(connection, released_id, draft_id, regenerate_progression_ids=False)
        return CreatedRunPlan(plan_id, released_id, draft_id, released_copy)


def not_executable(code: str, issues: Sequence[ExecutabilityIssue]) -> ExecutionAPIError:
    """422 with a readable summary as the message and every issue in ``details.issues``.

    ``code`` is ``plan_not_executable`` (run creation) or ``run_plan_not_executable``
    (Apply, T3.3); both carry the same issue list (``03`` §3, ``04`` §2).
    """
    return ExecutionAPIError(
        422,
        code,
        summarize_issues(issues),
        {"issues": [issue.as_dict() for issue in issues]},
    )


async def _fetch_optional(
    connection: Any,
    query: str,
    params: tuple[Any, ...],
) -> Row | None:
    async with connection.cursor() as cursor:
        await cursor.execute(query, params)
        return cast(Row | None, await cursor.fetchone())


async def _fetch_one(connection: Any, query: str, params: tuple[Any, ...]) -> Row:
    row = await _fetch_optional(connection, query, params)
    if row is None:
        raise RuntimeError("Database query unexpectedly returned no rows")
    return row
