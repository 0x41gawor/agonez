"""Executability of a plan revision: can a plan run train it? (``03`` §3, decision Q1).

My Plans stays permissive: a library draft may be unfinished. A run, however, builds one
workout track per workout unit and one exercise track per slot from the slot's DEFAULT
variant, and prescribes that variant's sets, so it needs a complete definition. Two callers
use this one pure function:

- run creation (T2.2) checks the source revision, without a day count; any issue → 422
  ``plan_not_executable``, nothing is created;
- Apply (T3.3) checks the run plan's working copy with the run's
  ``microcycle_duration_days``; any issue → 422 ``run_plan_not_executable``.

Issues are ordered by day, then slot. ``path`` follows the PlanCreator convention
(``days.<ordinal>.workout_unit.exercise_slots.<ordinal>``) with the stored, zero-based
ordinals; messages count days and exercises from 1, as the editor shows them.
"""

from collections import Counter
from collections.abc import Iterable, Sequence
from dataclasses import dataclass
from typing import Any

from agonez_api.modules.plans.repository import DraftRows, Row

DAY_COUNT_CHANGED = "day_count_changed"
NO_WORKOUTS = "no_workouts"
WORKOUT_WITHOUT_EXERCISES = "workout_without_exercises"
SLOT_WITHOUT_EXERCISE = "slot_without_exercise"
EXERCISE_WITHOUT_SETS = "exercise_without_sets"
DUPLICATE_LINEAGE = "duplicate_lineage"

# How many issues a one-line summary names before it only counts the rest.
SUMMARY_LIMIT = 3


@dataclass(frozen=True)
class ExecutabilityIssue:
    code: str
    path: str
    day_ordinal: int | None
    slot_ordinal: int | None
    message: str

    def as_dict(self) -> dict[str, Any]:
        return {
            "code": self.code,
            "path": self.path,
            "day_ordinal": self.day_ordinal,
            "slot_ordinal": self.slot_ordinal,
            "message": self.message,
        }


def validate_executable(
    rows: DraftRows,
    *,
    expected_day_count: int | None = None,
) -> list[ExecutabilityIssue]:
    """Return every reason why ``rows`` cannot be executed; an empty list means executable.

    ``expected_day_count`` is the run's microcycle length (Apply only, D13); ``None`` skips
    the ``day_count_changed`` rule.
    """
    issues: list[ExecutabilityIssue] = []
    if expected_day_count is not None and len(rows.days) != expected_day_count:
        issues.append(
            ExecutabilityIssue(
                DAY_COUNT_CHANGED,
                "days",
                None,
                None,
                f"The plan has {_count(len(rows.days), 'day')}; this run needs exactly "
                f"{_count(expected_day_count, 'day')}.",
            )
        )

    days = sorted(rows.days, key=lambda day: (day["ordinal"], day["id"]))
    units_by_day = _group(rows.workout_units, "day_id")
    slots_by_unit = _group(rows.slots, "workout_unit_id")
    variants_by_slot = _group(rows.variants, "slot_id")
    sets_by_variant = Counter(item["exercise_variant_id"] for item in rows.sets)
    unit_keys = Counter(unit["lineage_key"] for unit in rows.workout_units)
    slot_keys = Counter(slot["lineage_key"] for slot in rows.slots)

    if not any(units_by_day.get(day["id"]) for day in days):
        issues.append(
            ExecutabilityIssue(
                NO_WORKOUTS,
                "days",
                None,
                None,
                "The plan has no workout: add exercises to at least one day.",
            )
        )

    for day in days:
        day_ordinal = int(day["ordinal"])
        for unit in units_by_day.get(day["id"], []):
            unit_path = f"days.{day_ordinal}.workout_unit"
            where = _day_label(day_ordinal, unit, day)
            if unit_keys[unit["lineage_key"]] > 1:
                issues.append(
                    ExecutabilityIssue(
                        DUPLICATE_LINEAGE,
                        unit_path,
                        day_ordinal,
                        None,
                        f"{where}: the workout shares its identity with another workout "
                        "(internal error, please report it).",
                    )
                )
            slots = sorted(
                slots_by_unit.get(unit["id"], []),
                key=lambda slot: (slot["ordinal"], slot["id"]),
            )
            if not slots:
                issues.append(
                    ExecutabilityIssue(
                        WORKOUT_WITHOUT_EXERCISES,
                        unit_path,
                        day_ordinal,
                        None,
                        f"{where}: the workout has no exercises.",
                    )
                )
            for slot in slots:
                slot_ordinal = int(slot["ordinal"])
                slot_path = f"{unit_path}.exercise_slots.{slot_ordinal}"
                defaults = [
                    variant
                    for variant in variants_by_slot.get(slot["id"], [])
                    if variant["variant_type"] == "DEFAULT"
                ]
                slot_where = f"{where}, {_slot_label(slot_ordinal, slot, defaults)}"
                if slot_keys[slot["lineage_key"]] > 1:
                    issues.append(
                        ExecutabilityIssue(
                            DUPLICATE_LINEAGE,
                            slot_path,
                            day_ordinal,
                            slot_ordinal,
                            f"{slot_where}: the exercise shares its identity with another "
                            "exercise (internal error, please report it).",
                        )
                    )
                if len(defaults) != 1:
                    issues.append(
                        ExecutabilityIssue(
                            SLOT_WITHOUT_EXERCISE,
                            slot_path,
                            day_ordinal,
                            slot_ordinal,
                            f"{slot_where}: choose the exercise to perform.",
                        )
                    )
                    continue
                if not sets_by_variant[defaults[0]["id"]]:
                    issues.append(
                        ExecutabilityIssue(
                            EXERCISE_WITHOUT_SETS,
                            slot_path,
                            day_ordinal,
                            slot_ordinal,
                            f"{slot_where}: the exercise has no sets.",
                        )
                    )
    return issues


def summarize_issues(issues: Sequence[ExecutabilityIssue]) -> str:
    """One readable sentence for an error message (the New Run screen shows it as is)."""
    named = " ".join(issue.message for issue in issues[:SUMMARY_LIMIT])
    rest = len(issues) - SUMMARY_LIMIT
    more = f" And {_count(rest, 'more problem')}." if rest > 0 else ""
    return f"This plan cannot be started yet. {named}{more}"


def _group(rows: Iterable[Row], key: str) -> dict[Any, list[Row]]:
    grouped: dict[Any, list[Row]] = {}
    for row in rows:
        grouped.setdefault(row[key], []).append(row)
    return grouped


def _day_label(day_ordinal: int, unit: Row, day: Row) -> str:
    name = _text(unit.get("name")) or _text(day.get("name"))
    return f'Day {day_ordinal + 1} "{name}"' if name else f"Day {day_ordinal + 1}"


def _slot_label(slot_ordinal: int, slot: Row, defaults: list[Row]) -> str:
    name = _text(slot.get("name")) or (
        _text(defaults[0].get("exercise_slug")) if len(defaults) == 1 else None
    )
    label = f"exercise {slot_ordinal + 1}"
    return f'{label} "{name}"' if name else label


def _text(value: Any) -> str | None:
    return value.strip() or None if isinstance(value, str) else None


def _count(value: int, noun: str) -> str:
    return f"{value} {noun}" if value == 1 else f"{value} {noun}s"
