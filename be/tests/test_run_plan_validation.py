"""``validate_executable`` (T-UNIT-VAL-01…06 in ``07`` §1; ``03`` §3, Q1)."""

import copy
from typing import Any
from uuid import UUID, uuid4

import pytest

from agonez_api.modules.plans.executability import (
    ExecutabilityIssue,
    summarize_issues,
    validate_executable,
)
from agonez_api.modules.plans.repository import DraftRows

UPPER = UUID("00000000-0000-4000-8000-000000000001")
LOWER = UUID("00000000-0000-4000-8000-000000000002")


def executable() -> DraftRows:
    """Upper (press, fly) / rest / Lower (squat); every DEFAULT variant has sets.

    Row order is deliberately not the plan order, as rows may come from the database.
    """
    return DraftRows(
        header={"id": 1, "revision_id": 2, "revision_status": "DRAFT"},
        days=[
            {"id": 12, "revision_id": 2, "ordinal": 2, "name": "Lower"},
            {"id": 10, "revision_id": 2, "ordinal": 0, "name": "Upper day"},
            {"id": 11, "revision_id": 2, "ordinal": 1, "name": "Rest"},
        ],
        workout_units=[
            {"id": 22, "day_id": 12, "lineage_key": LOWER, "name": "Lower"},
            {"id": 20, "day_id": 10, "lineage_key": UPPER, "name": "Upper"},
        ],
        slots=[
            slot(32, 22, 0, name=None),
            slot(31, 20, 1, name=None),
            slot(30, 20, 0, name="Press"),
        ],
        target_muscles=[],
        variants=[
            variant(50, 30, "DEFAULT", "bench_press"),
            variant(51, 30, "FALLBACK", "dumbbell_press"),
            variant(52, 31, "DEFAULT", "cable_fly"),
            variant(53, 32, "DEFAULT", "back_squat"),
        ],
        sets=[set_row(70, 50), set_row(71, 50), set_row(72, 51), set_row(73, 52), set_row(74, 53)],
    )


def slot(ident: int, unit: int, ordinal: int, *, name: str | None) -> dict[str, Any]:
    return {
        "id": ident,
        "workout_unit_id": unit,
        "lineage_key": uuid4(),
        "ordinal": ordinal,
        "name": name,
    }


def variant(ident: int, slot_id: int, variant_type: str, slug: str) -> dict[str, Any]:
    return {
        "id": ident,
        "slot_id": slot_id,
        "ordinal": 0 if variant_type == "DEFAULT" else 1,
        "variant_type": variant_type,
        "exercise_slug": slug,
    }


def set_row(ident: int, variant_id: int) -> dict[str, Any]:
    return {"id": ident, "exercise_variant_id": variant_id, "ordinal": ident % 10}


def without(rows: DraftRows, entity: str, *ids: int) -> DraftRows:
    copied = copy.deepcopy(rows)
    kept = [row for row in getattr(copied, entity) if row["id"] not in ids]
    getattr(copied, entity)[:] = kept
    return copied


def summary(issues: list[ExecutabilityIssue]) -> list[tuple[Any, ...]]:
    return [
        (issue.code, issue.path, issue.day_ordinal, issue.slot_ordinal) for issue in issues
    ]


def test_an_executable_revision_has_no_issues() -> None:
    assert validate_executable(executable()) == []
    assert validate_executable(executable(), expected_day_count=3) == []


def test_val_01_day_count_changed_only_with_an_expected_count() -> None:
    issues = validate_executable(executable(), expected_day_count=4)

    assert summary(issues) == [("day_count_changed", "days", None, None)]
    assert issues[0].message == "The plan has 3 days; this run needs exactly 4 days."
    # Run creation passes no day count: the rule never fires.
    assert validate_executable(without(executable(), "days", 11)) == []


def test_val_02_no_workouts() -> None:
    rows = without(executable(), "workout_units", 20, 22)
    rows = without(rows, "slots", 30, 31, 32)

    issues = validate_executable(rows)

    assert summary(issues) == [("no_workouts", "days", None, None)]
    assert "no workout" in issues[0].message
    # A revision without days is not executable either.
    empty = DraftRows(executable().header, [], [], [], [], [], [])
    assert summary(validate_executable(empty)) == [("no_workouts", "days", None, None)]


def test_val_03_workout_without_exercises() -> None:
    rows = without(executable(), "slots", 32)

    issues = validate_executable(rows)

    assert summary(issues) == [
        ("workout_without_exercises", "days.2.workout_unit", 2, None),
    ]
    assert issues[0].message == 'Day 3 "Lower": the workout has no exercises.'


def test_val_04_slot_without_exercise() -> None:
    # No variant at all, and only a FALLBACK: neither has the DEFAULT a track is built from.
    rows = without(executable(), "variants", 50, 52)

    issues = validate_executable(rows)

    assert summary(issues) == [
        ("slot_without_exercise", "days.0.workout_unit.exercise_slots.0", 0, 0),
        ("slot_without_exercise", "days.0.workout_unit.exercise_slots.1", 0, 1),
    ]
    assert issues[0].message == 'Day 1 "Upper", exercise 1 "Press": choose the exercise to perform.'
    assert issues[1].message == 'Day 1 "Upper", exercise 2: choose the exercise to perform.'


def test_val_05_exercise_without_sets() -> None:
    # Only the DEFAULT variant counts: a FALLBACK without sets is fine.
    rows = without(executable(), "sets", 73, 72)

    issues = validate_executable(rows)

    assert summary(issues) == [
        ("exercise_without_sets", "days.0.workout_unit.exercise_slots.1", 0, 1),
    ]
    assert issues[0].message == 'Day 1 "Upper", exercise 2 "cable_fly": the exercise has no sets.'


def test_val_06_duplicate_lineage() -> None:
    rows = copy.deepcopy(executable())
    rows.workout_units[0]["lineage_key"] = UPPER
    rows.slots[1]["lineage_key"] = rows.slots[2]["lineage_key"]

    issues = validate_executable(rows)

    assert summary(issues) == [
        ("duplicate_lineage", "days.0.workout_unit", 0, None),
        ("duplicate_lineage", "days.0.workout_unit.exercise_slots.0", 0, 0),
        ("duplicate_lineage", "days.0.workout_unit.exercise_slots.1", 0, 1),
        ("duplicate_lineage", "days.2.workout_unit", 2, None),
    ]
    assert all("internal error" in issue.message for issue in issues)


def test_every_problem_is_reported_in_plan_order() -> None:
    rows = without(executable(), "slots", 32)
    rows = without(rows, "variants", 52)

    issues = validate_executable(rows, expected_day_count=2)

    assert [issue.code for issue in issues] == [
        "day_count_changed",
        "slot_without_exercise",
        "workout_without_exercises",
    ]
    assert issues[1].as_dict() == {
        "code": "slot_without_exercise",
        "path": "days.0.workout_unit.exercise_slots.1",
        "day_ordinal": 0,
        "slot_ordinal": 1,
        "message": 'Day 1 "Upper", exercise 2: choose the exercise to perform.',
    }


@pytest.mark.parametrize(
    ("count", "suffix"),
    [(1, ""), (3, ""), (4, " And 1 more problem."), (6, " And 3 more problems.")],
)
def test_summary_names_the_first_problems_and_counts_the_rest(count: int, suffix: str) -> None:
    issues = [
        ExecutabilityIssue("workout_without_exercises", f"days.{n}", n, None, f"Problem {n}.")
        for n in range(count)
    ]

    named = " ".join(f"Problem {n}." for n in range(min(count, 3)))
    assert summarize_issues(issues) == f"This plan cannot be started yet. {named}{suffix}"
