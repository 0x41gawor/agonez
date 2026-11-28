"""Golden comparison of the Execution read models (T2.3, T-MIG-10 of ``07``).

Capture everything the API (and the database views) say about every plan run, change the
database, capture again, and report every JSON path that differs. Used by
``test_migration_golden.py`` around migration 0019.

What is captured
----------------
Run ids, dates, sessions, tracks and workouts come from the database (``observation_scope``),
so any restored dump works. For every run:

* at each observation date: desktop ``overview``, ``analysis/queue``, ``microcycles`` (the
  timeline) and the mobile ``context`` (body and ETag);
* at the live date: ``calendar``, ``events``, ``workout-traces`` and each trace,
  ``load-series`` (default, and volume load with drafts), every exercise trace and its ``/next``;
* for every session, whatever its status: the saved prescription and the fallback preview
  (an error answer is a document like any other);
* for every workout: the mobile workout snapshot;
* the rows of every ``exec`` table, and of the six ``exec`` views, that belong to the run.

Plus, across runs: the desktop and mobile run lists and the mobile context without a run id.

The **live date** of a run is the date of its earliest ``scheduled`` session (its ``ends_on``
when none is left). The observation dates are the live date and every earlier microcycle start,
so no read marks a further session as missed. The one write a read can still cause (a
``scheduled`` run becoming ``active``) happens in ``settle``, before the first capture. The
cross-run reads use the earliest scheduled date of all runs.

Normaliser
----------
Applied to every capture, on both sides (nothing else is removed, and no id is dropped):

1. mobile context ``generated_at`` (the server's clock) -> ``"<generated_at>"``;
2. ``prescription_id`` of a fallback preview of a session **without** a saved workout
   prescription -> ``"<unsaved preview prescription_id>"``. The preview builds the row in a
   transaction it rolls back, so each call takes a new number from the sequence. It must not
   be the id of a saved prescription. With a saved prescription the id is compared exactly.

Applied to the "before" side only, when a reference map is given (``compare(mapping=...)``):

3. every plan-row id under a key of ``PLAN_ROW_ID_KEYS`` (revision, day, workout unit, slot,
   variant, set) is replaced by its copy from ``public.agonez_0019_reference_map``, looked up
   per run and entity. The result must equal the "after" value exactly, which proves the remap.
   A converted run's id without a map entry is reported. Runs that are not in the map (they
   owned a run plan already) are not translated, so their ids must be identical.

Everything else (exec ids, revision numbers, versions, dates, texts, order of lists, JSON
types, HTTP statuses) must be equal.

Allow-list across migration 0019 (``EXPECTED_AFTER_CONVERSION``)
----------------------------------------------------------------
Each entry names the read, the path and the **only** change it accepts, for converted runs:

=========================  ========================================  ===========================
Read                       Path                                      Accepted change, reason
=========================  ========================================  ===========================
exec overview              ``$.run.plan.plan_id``                    library plan -> the run's
                                                                     run plan (its map entry
                                                                     ``workout_plan``): the
                                                                     header names the plan of
                                                                     ``initial_revision``
exec overview              ``$.run.plan.code``                       ``P<library>`` ->
                                                                     ``P<run plan>``
exec overview              ``$.run.initial_revision.status``         ``draft`` -> ``released``:
                                                                     the copy of a library
                                                                     draft is an applied
                                                                     revision
exec plan-runs             ``$.items[*].plan.plan_id``               as ``run.plan.plan_id``
exec plan-runs             ``$.items[*].plan.code``                  as ``run.plan.code``
stored rows                ``$.plan_runs.*.run_plan_id``             NULL -> the run's run plan
                                                                     (filled by 0019)
stored rows                ``$.workout_unit_tracks.*.``              NULL -> a UUID (0019's
                           ``plan_lineage_key``                      lineage backfill)
stored rows                ``$.exercise_unit_tracks.*.``             as above
                           ``plan_lineage_key``
=========================  ========================================  ===========================

No read model exposes ``released_at``, and every applied revision keeps the revision number of
its library source on today's data. 0019 numbers the applied revisions 1..n in order of first
use, so a run whose library revisions are numbered differently would show a ``revision_no``
difference; that is reported, not allowed.

Re-running with later code (T3.1)
---------------------------------
Code that reads ``plan_lineage_key`` cannot capture the "before" side on a database without
0019, so the comparison is against a file instead:

1. on the old code: ``AGONEZ_GOLDEN_SAVE=<file>`` makes the golden test write the capture it
   took after 0019 (``save``);
2. on the new code, same dump: ``AGONEZ_GOLDEN_BASELINE=<file>`` makes it convert, capture and
   compare with that file, with ``ADDITIVE_FIELDS`` as the only allow-list.

Plan ids come from sequences and repeat for the same dump; lineage keys are random and are
masked in saved files (``mask_lineage_keys``). ``ADDITIVE_FIELDS`` is empty: add one entry per
additive field of ``04`` §2 (``added(kind, path, reason)`` accepts a key that the baseline does
not have, never a changed one). If ``settle`` writes on a dump (a run that was still
``scheduled``), the two runs stamp different ``updated_at`` values (``run.version``).
"""

import json
from collections import Counter
from collections.abc import Callable, Iterable, Iterator
from dataclasses import dataclass, field
from datetime import date, datetime
from pathlib import Path
from typing import Any, NamedTuple

import httpx
from builders import DEVICE_ID
from conftest import FrozenClock
from psycopg import AsyncConnection, sql
from test_migration_0019 import OWNED_BY_RUN

DEVICE_HEADERS = {"X-Agonez-Device-Id": str(DEVICE_ID)}
ALL_RUNS = 0  # ``Read.run_id`` of the reads that span runs
GENERATED_AT = "<generated_at>"
EPHEMERAL_ID = "<unsaved preview prescription_id>"
LINEAGE_KEY = "<lineage key>"
PENDING_STATUSES = frozenset({"scheduled", "missed"})  # what the fallback preview serves

EXEC_VIEWS = (
    "exercise_unit_trace",
    "microcycle_trace",
    "performed_load_time_series",
    "plan_run_event_history",
    "workout_session_calendar",
    "workout_unit_trace",
)
# Column of each exec table that holds its row id; mobile_sync_ops has a composite key.
ROW_KEY: dict[str, tuple[str, ...]] = {
    "exec.mobile_sync_ops": ("workout_unit_performance_id", "lease_epoch", "seq"),
}
# Reads that must answer 200, so that the comparison cannot pass on two equal error answers.
# Prescription reads may refuse (no saved prescription, session already executed).
MAY_REFUSE = frozenset({"mobile prescription", "mobile fallback preview"})

# JSON keys (API payloads and column names) that hold plan-row ids -> reference-map entity.
PLAN_ROW_ID_KEYS: dict[str, str] = {
    "plan_revision_id": "plan_revision",
    "initial_plan_revision_id": "plan_revision",
    "source_plan_revision_id": "plan_revision",
    "from_plan_revision_id": "plan_revision",
    "to_plan_revision_id": "plan_revision",
    "source_plan_day_id": "day",
    "source_plan_workout_unit_id": "workout_unit",
    "fallback_source_plan_workout_unit_id": "workout_unit",
    "source_plan_exercise_slot_id": "exercise_slot",
    "source_plan_exercise_variant_id": "exercise_variant",
    "actual_plan_exercise_variant_id": "exercise_variant",
    "prescribed_plan_exercise_variant_id": "exercise_variant",
    "performed_plan_exercise_variant_id": "exercise_variant",
    "source_plan_set_infra_id": "set_infra",
}

ReferenceMap = dict[tuple[int, str, int], int]


class Read(NamedTuple):
    run_id: int
    kind: str
    at: str = ""

    def __str__(self) -> str:
        run = "all runs" if self.run_id == ALL_RUNS else f"run {self.run_id}"
        return " ".join(part for part in (f"{run} · {self.kind}", self.at) if part)


# A document is {"status": int | None, "etag": str | None, "body": Any}.
Capture = dict[Read, dict[str, Any]]


# --- What to capture ------------------------------------------------------------------------


@dataclass(frozen=True)
class RunScope:
    run_id: int
    live: date
    dates: tuple[date, ...]
    workout_tracks: tuple[int, ...]
    exercise_tracks: tuple[int, ...]
    sessions: tuple[int, ...]
    pending: frozenset[int]
    saved: frozenset[int]  # sessions with a saved workout prescription
    workouts: tuple[str, ...]


@dataclass(frozen=True)
class Scope:
    runs: tuple[RunScope, ...]
    global_date: date
    prescription_ids: frozenset[int]


async def _rows(db: AsyncConnection, query: str, *params: Any) -> list[dict[str, Any]]:
    return await (await db.execute(query, params or None)).fetchall()


async def observation_scope(db: AsyncConnection, only: Iterable[int] | None = None) -> Scope:
    """Every run of the database (or those in ``only``) with what to read about it."""
    wanted = None if only is None else set(only)
    runs = []
    for run in await _rows(db, "SELECT id, ends_on FROM exec.plan_runs ORDER BY id"):
        run_id = run["id"]
        if wanted is not None and run_id not in wanted:
            continue
        sessions = await _rows(
            db,
            """
            SELECT ws.id, ws.status::text AS status, ws.scheduled_date,
                   wup.id IS NOT NULL AS saved, perf.client_uuid
            FROM exec.workout_sessions AS ws
            LEFT JOIN exec.workout_unit_prescriptions AS wup ON wup.workout_session_id = ws.id
            LEFT JOIN exec.workout_unit_performances AS perf
              ON perf.workout_unit_prescription_id = wup.id
            WHERE ws.plan_run_id = %s
            ORDER BY ws.id
            """,
            run_id,
        )
        live = min(
            (row["scheduled_date"] for row in sessions if row["status"] == "scheduled"),
            default=run["ends_on"],
        )
        starts = await _rows(
            db,
            "SELECT starts_on FROM exec.microcycles WHERE plan_run_id = %s AND starts_on <= %s",
            run_id,
            live,
        )
        tracks = {
            table: tuple(
                row["id"]
                for row in await _rows(
                    db, f"SELECT id FROM exec.{table} WHERE plan_run_id = %s ORDER BY id", run_id
                )
            )
            for table in ("workout_unit_tracks", "exercise_unit_tracks")
        }
        runs.append(
            RunScope(
                run_id=run_id,
                live=live,
                dates=tuple(sorted({live, *(row["starts_on"] for row in starts)})),
                workout_tracks=tracks["workout_unit_tracks"],
                exercise_tracks=tracks["exercise_unit_tracks"],
                sessions=tuple(row["id"] for row in sessions),
                pending=frozenset(
                    row["id"] for row in sessions if row["status"] in PENDING_STATUSES
                ),
                saved=frozenset(row["id"] for row in sessions if row["saved"]),
                workouts=tuple(str(row["client_uuid"]) for row in sessions if row["client_uuid"]),
            )
        )
    assert runs, "the database holds no plan run"
    scheduled = (
        await _rows(
            db,
            "SELECT min(scheduled_date) AS first FROM exec.workout_sessions"
            " WHERE status = 'scheduled'",
        )
    )[0]["first"]
    prescriptions = await _rows(db, "SELECT id FROM exec.workout_unit_prescriptions")
    return Scope(
        runs=tuple(runs),
        global_date=scheduled or max(run.live for run in runs),
        prescription_ids=frozenset(row["id"] for row in prescriptions),
    )


# --- Capturing ------------------------------------------------------------------------------


async def _get(
    client: httpx.AsyncClient, path: str, params: dict[str, Any] | None = None
) -> dict[str, Any]:
    response = await client.get(path, params=params, headers=DEVICE_HEADERS)
    return {
        "status": response.status_code,
        "etag": response.headers.get("etag"),
        "body": response.json() if response.content else None,
    }


def _mask_generated_at(document: dict[str, Any]) -> dict[str, Any]:
    if document["status"] == 200:
        value = document["body"]["generated_at"]
        datetime.fromisoformat(value.replace("Z", "+00:00"))
        document["body"]["generated_at"] = GENERATED_AT
    return document


def _mask_ephemeral_id(document: dict[str, Any], scope: Scope) -> dict[str, Any]:
    if document["status"] == 200:
        value = document["body"]["prescription_id"]
        assert isinstance(value, int) and value not in scope.prescription_ids, value
        document["body"]["prescription_id"] = EPHEMERAL_ID
    return document


async def settle(client: httpx.AsyncClient, clock: FrozenClock, scope: Scope) -> None:
    """Let the reads make their lifecycle transitions before anything is compared."""
    for run in scope.runs:
        clock.today = run.live
        await _get(client, f"/api/v1/exec/plan-runs/{run.run_id}/overview")
    clock.today = scope.global_date
    await _get(client, "/api/v1/exec/plan-runs", {"limit": 200})
    await _get(client, "/api/v1/mobile/plan-runs", {"date": scope.global_date.isoformat()})


async def _stored_rows(db: AsyncConnection, run_id: int) -> dict[str, dict[str, Any]]:
    """``{table: {row id: row}}`` for the run's rows of every exec table."""
    tables: dict[str, dict[str, Any]] = {}
    for table, run_of in OWNED_BY_RUN.items():
        query = sql.SQL(
            "SELECT to_jsonb(row_) AS row FROM {table} AS row_ WHERE {run} = %s"
        ).format(table=sql.Identifier(*table.split(".")), run=sql.SQL(run_of))
        fetched = await (await db.execute(query, (run_id,))).fetchall()
        key = ROW_KEY.get(table, ("id",))
        rows = {":".join(str(item["row"][part]) for part in key): item["row"] for item in fetched}
        assert len(rows) == len(fetched), table
        tables[table.removeprefix("exec.")] = rows
    return tables


def _without_plan_ids(row: dict[str, Any]) -> str:
    return json.dumps(
        {key: value for key, value in row.items() if key not in PLAN_ROW_ID_KEYS}, sort_keys=True
    )


async def _view_rows(db: AsyncConnection, view: str, run_id: int) -> list[dict[str, Any]]:
    query = sql.SQL(
        "SELECT to_jsonb(row_) AS row FROM {view} AS row_ WHERE row_.plan_run_id = %s"
    ).format(view=sql.Identifier("exec", view))
    fetched = await (await db.execute(query, (run_id,))).fetchall()
    # An order that does not depend on the ids 0019 rewrites.
    return sorted((item["row"] for item in fetched), key=_without_plan_ids)


async def _check_coverage(db: AsyncConnection) -> None:
    tables = await _rows(
        db,
        "SELECT table_name, table_type FROM information_schema.tables WHERE table_schema = 'exec'",
    )
    names = {
        kind: {row["table_name"] for row in tables if row["table_type"] == kind}
        for kind in ("BASE TABLE", "VIEW")
    }
    assert names["BASE TABLE"] == {table.removeprefix("exec.") for table in OWNED_BY_RUN}
    assert names["VIEW"] == set(EXEC_VIEWS)


async def capture(
    client: httpx.AsyncClient, db: AsyncConnection, clock: FrozenClock, scope: Scope
) -> Capture:
    """Every read of the module docstring, normalised (rules 1 and 2)."""
    await _check_coverage(db)
    reads: Capture = {}

    clock.today = scope.global_date
    at_global = {"date": scope.global_date.isoformat()}
    reads[Read(ALL_RUNS, "exec plan-runs")] = await _get(
        client, "/api/v1/exec/plan-runs", {"limit": 200}
    )
    reads[Read(ALL_RUNS, "mobile plan-runs")] = await _get(
        client, "/api/v1/mobile/plan-runs", at_global
    )
    reads[Read(ALL_RUNS, "mobile context")] = _mask_generated_at(
        await _get(client, "/api/v1/mobile/context", at_global)
    )

    for run in scope.runs:
        run_id = run.run_id
        base = f"/api/v1/exec/plan-runs/{run_id}"
        for day in run.dates:
            clock.today = day
            at = f"@ {day.isoformat()}"
            for kind, path in (
                ("exec overview", "overview"),
                ("exec analysis/queue", "analysis/queue"),
                ("exec timeline", "microcycles"),
            ):
                reads[Read(run_id, kind, at)] = await _get(client, f"{base}/{path}")
            reads[Read(run_id, "mobile context", at)] = _mask_generated_at(
                await _get(
                    client,
                    "/api/v1/mobile/context",
                    {"plan_run_id": run_id, "date": day.isoformat()},
                )
            )

        clock.today = run.live
        for name in ("calendar", "workout-traces"):
            reads[Read(run_id, f"exec {name}")] = await _get(client, f"{base}/{name}")
        reads[Read(run_id, "exec events")] = await _get(client, f"{base}/events", {"limit": 200})
        for at, params in (
            ("default", None),
            ("volume with drafts", {"metric": "volume_load", "include_draft": True}),
        ):
            reads[Read(run_id, "exec load-series", at)] = await _get(
                client, f"{base}/load-series", params
            )
        for trace in run.workout_tracks:
            reads[Read(run_id, "exec workout-trace", f"trace {trace}")] = await _get(
                client, f"{base}/workout-traces/{trace}"
            )
        for trace in run.exercise_tracks:
            path = f"{base}/exercise-traces/{trace}"
            reads[Read(run_id, "exec exercise-trace", f"trace {trace}")] = await _get(client, path)
            reads[Read(run_id, "exec exercise-next", f"trace {trace}")] = await _get(
                client, f"{path}/next"
            )

        for session in run.sessions:
            path = f"/api/v1/mobile/sessions/{session}/prescription"
            at = f"session {session}"
            reads[Read(run_id, "mobile prescription", at)] = await _get(client, path)
            preview = await _get(client, f"{path}/fallback")
            if session not in run.saved:
                preview = _mask_ephemeral_id(preview, scope)
            reads[Read(run_id, "mobile fallback preview", at)] = preview
        for workout in run.workouts:
            reads[Read(run_id, "mobile workout", workout)] = await _get(
                client, f"/api/v1/mobile/workouts/{workout}"
            )

        reads[Read(run_id, "stored rows")] = {
            "status": None,
            "etag": None,
            "body": await _stored_rows(db, run_id),
        }
        for view in EXEC_VIEWS:
            reads[Read(run_id, "database view", view)] = {
                "status": None,
                "etag": None,
                "body": await _view_rows(db, view, run_id),
            }
    return reads


def unanswered(reads: Capture) -> list[str]:
    """Reads that had to answer 200 and did not."""
    return [
        f"{read}: {document['status']} {document['body']}"
        for read, document in reads.items()
        if document["status"] not in (None, 200) and read.kind not in MAY_REFUSE
    ]


# --- Allow-lists ----------------------------------------------------------------------------


class _Missing:
    def __repr__(self) -> str:
        return "<absent>"


MISSING = _Missing()  # a key or a list item that only one side has


@dataclass(frozen=True)
class AllowedDifference:
    kind: str  # ``Read.kind``
    path: str  # generic path: list indices as ``[*]``, row ids as ``*``
    reason: str
    accepts: Callable[[Any, Any, int, ReferenceMap], bool]  # before, after, run id, map


def _run_plans(mapping: ReferenceMap, run_id: int) -> dict[int, int]:
    """``{library plan id: run plan id}`` of a converted run; empty for any other run."""
    return {
        library: copy
        for (run, entity, library), copy in mapping.items()
        if run == run_id and entity == "workout_plan"
    }


def _plan_code(plan_id: int) -> str:
    return "P" + str(plan_id).rjust(3, "0")[:3]  # SQL: 'P' || lpad(id::text, 3, '0')


def _is_run_plan_id(before: Any, after: Any, run_id: int, mapping: ReferenceMap) -> bool:
    return (before, after) in _run_plans(mapping, run_id).items()


def _is_run_plan_code(before: Any, after: Any, run_id: int, mapping: ReferenceMap) -> bool:
    return (before, after) in {
        (_plan_code(library), _plan_code(copy))
        for library, copy in _run_plans(mapping, run_id).items()
    }


def _is_release(before: Any, after: Any, run_id: int, mapping: ReferenceMap) -> bool:
    return bool(_run_plans(mapping, run_id)) and (before, after) == ("draft", "released")


def _is_filled_run_plan(before: Any, after: Any, run_id: int, mapping: ReferenceMap) -> bool:
    return before is None and after in _run_plans(mapping, run_id).values()


def _is_filled_lineage(before: Any, after: Any, run_id: int, mapping: ReferenceMap) -> bool:
    return bool(_run_plans(mapping, run_id)) and before is None and isinstance(after, str)


_HEADER_PLAN = "the header names the plan of initial_revision, now the run's own run plan"

EXPECTED_AFTER_CONVERSION: tuple[AllowedDifference, ...] = (
    AllowedDifference("exec overview", "$.run.plan.plan_id", _HEADER_PLAN, _is_run_plan_id),
    AllowedDifference("exec overview", "$.run.plan.code", _HEADER_PLAN, _is_run_plan_code),
    AllowedDifference(
        "exec overview",
        "$.run.initial_revision.status",
        "the copy of a library draft is an applied (released) revision",
        _is_release,
    ),
    AllowedDifference("exec plan-runs", "$.items[*].plan.plan_id", _HEADER_PLAN, _is_run_plan_id),
    AllowedDifference("exec plan-runs", "$.items[*].plan.code", _HEADER_PLAN, _is_run_plan_code),
    AllowedDifference(
        "stored rows",
        "$.plan_runs.*.run_plan_id",
        "filled by 0019 with the run's run plan",
        _is_filled_run_plan,
    ),
    AllowedDifference(
        "stored rows",
        "$.workout_unit_tracks.*.plan_lineage_key",
        "0019's lineage backfill",
        _is_filled_lineage,
    ),
    AllowedDifference(
        "stored rows",
        "$.exercise_unit_tracks.*.plan_lineage_key",
        "0019's lineage backfill",
        _is_filled_lineage,
    ),
)


def added(kind: str, path: str, reason: str) -> AllowedDifference:
    """A field that is new compared with the baseline; a changed value is still reported."""
    return AllowedDifference(kind, path, reason, lambda before, *_: before is MISSING)


# T3.1 and later: the additive fields of ``04`` §2, e.g.
# added("exec overview", "$.run.source_plan", "04 §2: run header")
ADDITIVE_FIELDS: tuple[AllowedDifference, ...] = ()


# --- Comparing ------------------------------------------------------------------------------


@dataclass(frozen=True)
class Difference:
    read: Read
    path: str
    generic_path: str
    before: Any
    after: Any

    def __str__(self) -> str:
        change = f"before {_short(self.before)}, after {_short(self.after)}"
        return f"{self.read} · {self.path}: {change}"


def _short(value: Any, limit: int = 160) -> str:
    text = repr(value)
    return text if len(text) <= limit else f"{text[:limit]}…"


@dataclass
class Comparison:
    reads: int = 0
    unexpected: list[Difference] = field(default_factory=list)
    untranslated: list[str] = field(default_factory=list)
    allowed: Counter[tuple[str, str]] = field(default_factory=Counter)
    translated: Counter[str] = field(default_factory=Counter)

    def summary(self) -> str:
        lines = [f"{self.reads} reads compared"]
        if self.translated:
            lines.append(f"plan-row ids translated through the map: {dict(self.translated)}")
        lines += [
            f"allowed: {kind} {path} x {count}"
            for (kind, path), count in sorted(self.allowed.items())
        ]
        return "\n".join(lines)

    def report(self, limit: int = 40) -> str:
        groups = Counter((item.read.kind, item.generic_path) for item in self.unexpected)
        lines = [f"{len(self.unexpected)} unexpected difference(s):"]
        lines += [f"  {count:>5} x {kind} {path}" for (kind, path), count in sorted(groups.items())]
        lines += [f"{item}" for item in self.unexpected[:limit]]
        if len(self.unexpected) > limit:
            lines.append(f"… and {len(self.unexpected) - limit} more")
        if self.untranslated:
            lines.append(f"{len(self.untranslated)} plan-row id(s) without a reference-map entry:")
            lines += self.untranslated[:limit]
        return "\n".join(lines)

    def require_clean(self, claim: str) -> None:
        if self.unexpected or self.untranslated:
            raise AssertionError(f"{claim}\n{self.report()}")


def _translate(
    value: Any, run_id: int, mapping: ReferenceMap, read: Read, result: Comparison
) -> Any:
    """Normaliser rule 3: plan-row ids of converted runs become the ids of their copies."""
    if isinstance(value, list):
        return [_translate(item, run_id, mapping, read, result) for item in value]
    if not isinstance(value, dict):
        return value
    run_id = value.get("plan_run_id", run_id)
    converted = bool(_run_plans(mapping, run_id))
    output = {}
    for key, item in value.items():
        entity = PLAN_ROW_ID_KEYS.get(key)
        if entity is None or item is None or not converted:
            output[key] = _translate(item, run_id, mapping, read, result)
        elif (run_id, entity, item) in mapping:
            output[key] = mapping[(run_id, entity, item)]
            result.translated[entity] += 1
        else:
            output[key] = item
            result.untranslated.append(f"{read} · {key}: run {run_id} has no {entity} {item}")
    return output


Change = tuple[tuple[str | int, ...], Any, Any, int]  # path, before, after, run id


def _changes(before: Any, after: Any, path: tuple[str | int, ...], run_id: int) -> Iterator[Change]:
    if isinstance(before, dict) and isinstance(after, dict):
        run_id = before.get("plan_run_id", run_id)
        for key in sorted(before.keys() | after.keys()):
            yield from _changes(
                before.get(key, MISSING), after.get(key, MISSING), (*path, key), run_id
            )
    elif isinstance(before, list) and isinstance(after, list):
        for index in range(max(len(before), len(after))):
            yield from _changes(
                before[index] if index < len(before) else MISSING,
                after[index] if index < len(after) else MISSING,
                (*path, index),
                run_id,
            )
    elif type(before) is not type(after) or before != after:
        yield path, before, after, run_id


def _path(segments: tuple[str | int, ...], *, generic: bool) -> str:
    text = "$"
    for segment in segments:
        if isinstance(segment, int):
            text += "[*]" if generic else f"[{segment}]"
        elif generic and segment.replace(":", "").isdigit():
            text += ".*"
        else:
            text += f".{segment}"
    return text


def compare(
    before: Capture,
    after: Capture,
    *,
    allowed: tuple[AllowedDifference, ...] = (),
    mapping: ReferenceMap | None = None,
) -> Comparison:
    """Every difference between two captures that the allow-list does not accept."""
    mapping = mapping or {}
    rules = {(rule.kind, rule.path): rule for rule in allowed}
    result = Comparison()
    for read in sorted(before.keys() | after.keys()):
        old, new = before.get(read), after.get(read)
        if old is None or new is None:
            result.unexpected.append(
                Difference(
                    read,
                    "(whole read)",
                    "(whole read)",
                    MISSING if old is None else "captured",
                    MISSING if new is None else "captured",
                )
            )
            continue
        result.reads += 1
        for part in ("status", "etag"):
            if old[part] != new[part]:
                result.unexpected.append(Difference(read, part, part, old[part], new[part]))
        body = old["body"]
        if mapping:
            body = _translate(body, read.run_id, mapping, read, result)
        for segments, was, now, run_id in _changes(body, new["body"], (), read.run_id):
            generic = _path(segments, generic=True)
            rule = rules.get((read.kind, generic))
            if rule is not None and rule.accepts(was, now, run_id, mapping):
                result.allowed[(read.kind, generic)] += 1
            else:
                result.unexpected.append(
                    Difference(read, _path(segments, generic=False), generic, was, now)
                )
    return result


# --- Baseline files -------------------------------------------------------------------------


def mask_lineage_keys(reads: Capture) -> Capture:
    """Replace the random lineage keys, for comparing captures of two conversions."""
    masked = json.loads(json.dumps(list(reads.values())))
    output = dict(zip(reads, masked, strict=True))
    for read, document in output.items():
        if read.kind != "stored rows":
            continue
        for table in ("workout_unit_tracks", "exercise_unit_tracks"):
            for row in document["body"][table].values():
                if row.get("plan_lineage_key") is not None:
                    row["plan_lineage_key"] = LINEAGE_KEY
    return output


def save(reads: Capture, path: Path) -> None:
    items = [
        {**read._asdict(), "document": document}
        for read, document in mask_lineage_keys(reads).items()
    ]
    path.write_text(json.dumps(items, sort_keys=True, indent=1), "utf-8")


def load(path: Path) -> Capture:
    return {
        Read(item["run_id"], item["kind"], item["at"]): item["document"]
        for item in json.loads(path.read_text("utf-8"))
    }
