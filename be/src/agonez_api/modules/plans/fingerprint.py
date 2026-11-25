"""Structural fingerprint of a plan revision's definition (``02`` §3.1, ``01`` D14).

Two revisions have the same fingerprint exactly when they define the same training: the same
days, workouts, exercise slots, variants, sets and day icons, in the same order, with the same
lineage keys. It ignores

- row ids, parent references and revision ids, lock versions and revision numbers, so a copy
  of a revision fingerprints like its source;
- the plan's identity fields (name, description, accent, cover image), which live on the plan
  and are not revision-scoped;
- values derived from the catalog by joins (exercise and muscle slugs; the stored ids count).

Lineage keys count, so deleting a slot and adding an identical one is a change. Every other
column the loader returns counts as well; a column added to ``load_revision_rows`` later is
part of the fingerprint without a change here. The tree is serialised as canonical JSON
(sorted keys, children in ordinal order, numbers as normalised decimal strings) and hashed with
SHA-256.
"""

import hashlib
import json
from collections.abc import Iterable, Mapping
from datetime import date, datetime
from decimal import Decimal
from typing import Any
from uuid import UUID

from agonez_api.modules.plans.repository import DraftRows, Row

# Row keys that identify rows or point at parents, or that the loader derives by joins.
_EXCLUDED_KEYS: dict[str, frozenset[str]] = {
    "day": frozenset({"id", "revision_id"}),
    "workout_unit": frozenset({"id", "day_id"}),
    "exercise_slot": frozenset({"id", "workout_unit_id"}),
    "target_muscle": frozenset({"slot_id", "slug"}),
    "exercise_variant": frozenset({"id", "slot_id", "exercise_slug"}),
    "set_infra": frozenset({"id", "exercise_variant_id"}),
}


def definition_fingerprint(rows: DraftRows, *, include_progression_ids: bool = True) -> str:
    """Return the hex SHA-256 of the revision's definition tree.

    ``include_progression_ids=False`` compares a revision with a copy that drew fresh
    progression ids (library duplicate, promotion).
    """
    variant_excluded = _EXCLUDED_KEYS["exercise_variant"]
    if not include_progression_ids:
        variant_excluded = variant_excluded | {"progression_id"}

    sets_by_variant = _group(rows.sets, "exercise_variant_id", "set_infra")
    targets_by_slot = _group(rows.target_muscles, "slot_id", "target_muscle")

    variants_by_slot: dict[Any, list[dict[str, Any]]] = {}
    for variant in rows.variants:
        node = _body(variant, variant_excluded)
        node["sets"] = _ordered(sets_by_variant.get(variant["id"], []))
        variants_by_slot.setdefault(variant["slot_id"], []).append(node)

    slots_by_unit: dict[Any, list[dict[str, Any]]] = {}
    for slot in rows.slots:
        node = _body(slot, _EXCLUDED_KEYS["exercise_slot"])
        node["target_muscles"] = _ordered(targets_by_slot.get(slot["id"], []))
        node["variants"] = _ordered(variants_by_slot.get(slot["id"], []))
        slots_by_unit.setdefault(slot["workout_unit_id"], []).append(node)

    units_by_day: dict[Any, list[dict[str, Any]]] = {}
    for unit in rows.workout_units:
        node = _body(unit, _EXCLUDED_KEYS["workout_unit"])
        node["exercise_slots"] = _ordered(slots_by_unit.get(unit["id"], []))
        units_by_day.setdefault(unit["day_id"], []).append(node)

    days = []
    for day in rows.days:
        node = _body(day, _EXCLUDED_KEYS["day"])
        # One workout per day in practice; a list keeps the function total.
        node["workout_units"] = _ordered(units_by_day.get(day["id"], []))
        days.append(node)

    document = {"days": _ordered(days)}
    return hashlib.sha256(_canonical_json(document).encode("utf-8")).hexdigest()


def _group(items: Iterable[Row], parent_key: str, entity: str) -> dict[Any, list[dict[str, Any]]]:
    grouped: dict[Any, list[dict[str, Any]]] = {}
    for item in items:
        grouped.setdefault(item[parent_key], []).append(_body(item, _EXCLUDED_KEYS[entity]))
    return grouped


def _body(row: Row, excluded: frozenset[str]) -> dict[str, Any]:
    return {key: _canonical_value(value) for key, value in row.items() if key not in excluded}


def _ordered(nodes: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Children in ordinal order; ties (and rows without an ordinal) by their content."""
    return sorted(nodes, key=lambda node: (_ordinal_key(node), _canonical_json(node)))


def _ordinal_key(node: Mapping[str, Any]) -> tuple[int, Decimal]:
    ordinal = node.get("ordinal")
    if ordinal is None:
        return (0, Decimal(0))
    return (1, Decimal(ordinal))


def _canonical_value(value: Any) -> Any:
    if value is None or isinstance(value, (bool, str)):
        return value
    if isinstance(value, (int, float, Decimal)):
        # 2.5, 2.50 and Decimal("2.500") are one value; so are 5 and 5.0.
        return _decimal_text(Decimal(str(value)))
    if isinstance(value, UUID):
        return str(value)
    if isinstance(value, (datetime, date)):
        return value.isoformat()
    if isinstance(value, Mapping):
        return {str(key): _canonical_value(item) for key, item in value.items()}
    if isinstance(value, (list, tuple)):
        return [_canonical_value(item) for item in value]
    if hasattr(value, "value"):  # enums
        return _canonical_value(value.value)
    raise TypeError(f"Cannot fingerprint a value of type {type(value).__name__}")


def _decimal_text(value: Decimal) -> str:
    normalized = value.normalize()
    if normalized == 0:
        return "0"
    return format(normalized, "f")


def _canonical_json(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
