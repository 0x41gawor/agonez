"""T-IMM-03: the static write allow-list for ``plans.*`` (``01`` D16, ``02`` §1.4).

RELEASED revisions are immutable by construction, not by triggers: every statement that can
change or remove existing ``plans`` rows lives in a known function whose reason for never
touching a RELEASED revision is written down here. The test reads every Python source file
under ``src/agonez_api`` and fails on

- an ``UPDATE`` / ``DELETE FROM`` / ``TRUNCATE`` of a ``plans`` table (schema-qualified or
  not), or with a dynamic target such as the f-string in ``_delete_omitted``, in a function
  that is not listed, or with a target the entry does not list;
- an entry that no longer matches the code (a stale allow-list hides nothing).

A task that adds a writer adds it here with its justification (definition of done, ``06``).
Inserts are not listed: inserting rows never alters a RELEASED revision, and
``plans.copy_revision_tree`` refuses a non-empty target. SQL migrations are outside this test;
each data migration states how it treats RELEASED revisions.
"""

import ast
import re
from collections.abc import Iterator
from pathlib import Path

SOURCE_ROOT = Path(__file__).resolve().parents[1] / "src" / "agonez_api"

PLAN_TABLES = (
    "workout_plans",
    "plan_revisions",
    "plan_images",
    "day_prescriptions",
    "workout_unit_prescriptions",
    "exercise_slots",
    "exercise_slot_target_muscles",
    "exercise_variants",
    "set_infra_prescriptions",
)

WRITE = re.compile(
    r"\b(?P<verb>UPDATE|DELETE\s+FROM|TRUNCATE(?:\s+TABLE)?)\s+(?:ONLY\s+)?"
    r"(?P<target>plans\.\w+|\{[^}]*\}|(?:" + "|".join(PLAN_TABLES) + r")\b)",
    re.IGNORECASE,
)

REPOSITORY = "modules/plans/repository.py"
DRAFT_SCOPED = (
    "save_draft locks the plan and its DRAFT revision (status = 'DRAFT' FOR UPDATE); "
    "_validate_nested_ids rejects any submitted id that is not a row of that draft (422)"
)

# "<file relative to src/agonez_api>::<qualified function>" -> {statement: why it is safe}
ALLOWED: dict[str, dict[str, str]] = {
    f"{REPOSITORY}::PlanRepository.save_draft": {
        "UPDATE plans.workout_plans": (
            "plan identity fields (name, description, accent): plan-level, not "
            "revision-scoped (D14)"
        ),
        "UPDATE plans.exercise_variants": (
            "WHERE id = ANY(ids of the locked DRAFT's variants); " + DRAFT_SCOPED
        ),
        "UPDATE plans.plan_revisions": "lock_version of the locked DRAFT revision only",
    },
    f"{REPOSITORY}::PlanRepository._delete_omitted": {
        "DELETE FROM {table}": (
            "table from a fixed tuple of plans child tables; ids are rows of the locked DRAFT "
            "loaded in the same transaction; " + DRAFT_SCOPED
        ),
    },
    f"{REPOSITORY}::PlanRepository._upsert_day": {"UPDATE plans.day_prescriptions": DRAFT_SCOPED},
    f"{REPOSITORY}::PlanRepository._upsert_workout_unit": {
        "UPDATE plans.workout_unit_prescriptions": DRAFT_SCOPED
    },
    f"{REPOSITORY}::PlanRepository._upsert_slot": {"UPDATE plans.exercise_slots": DRAFT_SCOPED},
    f"{REPOSITORY}::PlanRepository._replace_target_muscles": {
        "DELETE FROM plans.exercise_slot_target_muscles": (
            "slot_id is a slot of the locked DRAFT (submitted and validated, or just inserted); "
            + DRAFT_SCOPED
        ),
    },
    f"{REPOSITORY}::PlanRepository._upsert_variant": {
        "UPDATE plans.exercise_variants": DRAFT_SCOPED
    },
    f"{REPOSITORY}::PlanRepository._upsert_set": {
        "UPDATE plans.set_infra_prescriptions": DRAFT_SCOPED
    },
    f"{REPOSITORY}::PlanRepository.delete_plan": {
        "DELETE FROM plans.workout_plans": (
            "whole library plans only (scope = 'library', run plans raise PlanScopeError); "
            "RESTRICT FKs from exec refuse plans a run still uses"
        ),
    },
    f"{REPOSITORY}::PlanRepository.delete_plan_image": {
        "DELETE FROM plans.plan_images": "cover image: plan-level, not revision-scoped (D14)",
    },
    "modules/execution/repository.py::ExecutionRepository.delete_plan_run": {
        "DELETE FROM plans.workout_plans": (
            "the deleted run's own run plan only (id = its run_plan_id AND scope = 'run'), "
            "after the run and its sessions are gone in the same transaction; its RELEASED "
            "revisions go with their run, never one by one (02 §3.6); RESTRICT FKs refuse it "
            "while any exec row still references the plan"
        ),
    },
}


def _text(node: ast.expr) -> str | None:
    """The SQL text of a string literal; f-string placeholders become ``{expression}``."""
    if isinstance(node, ast.Constant) and isinstance(node.value, str):
        return node.value
    if isinstance(node, ast.JoinedStr):
        parts = []
        for value in node.values:
            if isinstance(value, ast.Constant):
                parts.append(str(value.value))
            elif isinstance(value, ast.FormattedValue):
                parts.append("{" + ast.unparse(value.value) + "}")
        return "".join(parts)
    return None


def _statement(match: re.Match[str]) -> str:
    verb = " ".join(match["verb"].upper().split())
    target = match["target"]
    if not target.startswith("{"):
        target = target.lower()
        if not target.startswith("plans."):
            target = f"plans.{target}"
    return f"{verb} {target}"


def _writes(source: str) -> Iterator[tuple[str, str, int]]:
    """(qualified function, statement, line) for every plans write in one module."""
    tree = ast.parse(source)
    scopes: list[str] = []

    def visit(node: ast.AST) -> Iterator[tuple[str, str, int]]:
        named = isinstance(node, (ast.ClassDef, ast.FunctionDef, ast.AsyncFunctionDef))
        if named:
            scopes.append(node.name)  # type: ignore[attr-defined]
        if isinstance(node, ast.JoinedStr):
            children: list[ast.AST] = []  # its constant parts are read through _text
        else:
            children = list(ast.iter_child_nodes(node))
        if isinstance(node, ast.expr):
            text = _text(node)
            if text is not None:
                for match in WRITE.finditer(text):
                    yield ".".join(scopes) or "<module>", _statement(match), node.lineno
        for child in children:
            yield from visit(child)
        if named:
            scopes.pop()

    yield from visit(tree)


def _found() -> dict[str, dict[str, list[int]]]:
    found: dict[str, dict[str, list[int]]] = {}
    for path in sorted(SOURCE_ROOT.rglob("*.py")):
        module = path.relative_to(SOURCE_ROOT).as_posix()
        for function, statement, line in _writes(path.read_text(encoding="utf-8")):
            found.setdefault(f"{module}::{function}", {}).setdefault(statement, []).append(line)
    return found


def test_imm_03_every_plans_write_is_allow_listed() -> None:
    found = _found()

    unexpected = {
        f"{where}: {statement} (line {', '.join(map(str, lines))})"
        for where, statements in found.items()
        for statement, lines in statements.items()
        if statement not in ALLOWED.get(where, {})
    }
    assert not unexpected, (
        "New UPDATE/DELETE on plans.* outside the allow-list. Make sure it can never touch a "
        "RELEASED revision (01 D16), then add it to ALLOWED with the reason:\n"
        + "\n".join(sorted(unexpected))
    )

    stale = {
        f"{where}: {statement}"
        for where, statements in ALLOWED.items()
        for statement in statements
        if statement not in found.get(where, {})
    }
    assert not stale, "Allow-list entries without a matching statement:\n" + "\n".join(
        sorted(stale)
    )


def test_imm_03_scanner_sees_every_form_of_write() -> None:
    """The scanner itself: qualified, unqualified, dynamic and lower-case targets."""
    source = """
class Repo:
    async def a(self):
        await run("UPDATE plans.exercise_slots SET name = %s")
    async def b(self, table):
        await run(f"DELETE FROM {table} WHERE id = ANY(%s)")
    def c(self):
        return "delete from day_prescriptions where id = 1"
    def d(self):
        return "INSERT INTO plans.x VALUES (1) ON CONFLICT (id) DO UPDATE SET y = 2"
    def e(self):
        return "UPDATE exec.plan_runs SET status = 'active'"
"""
    writes = {(function, statement) for function, statement, _ in _writes(source)}

    assert writes == {
        ("Repo.a", "UPDATE plans.exercise_slots"),
        ("Repo.b", "DELETE FROM {table}"),
        ("Repo.c", "DELETE FROM plans.day_prescriptions"),
    }
