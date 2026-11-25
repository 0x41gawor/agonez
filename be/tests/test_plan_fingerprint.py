"""``definition_fingerprint`` (T-UNIT-FP-01…05 in ``07`` §1)."""

import copy
import re
from decimal import Decimal
from typing import Any
from uuid import UUID

from agonez_api.modules.plans.fingerprint import definition_fingerprint
from agonez_api.modules.plans.repository import DraftRows

PUSH_UNIT = UUID("00000000-0000-4000-8000-000000000001")
PRESS_SLOT = UUID("00000000-0000-4000-8000-000000000011")
FLY_SLOT = UUID("00000000-0000-4000-8000-000000000012")
LOOP = UUID("00000000-0000-4000-8000-000000000101")
FLY_LOOP = UUID("00000000-0000-4000-8000-000000000102")


def revision(offset: int = 0, **header: Any) -> DraftRows:
    """A push day, a rest day; two slots, one with a fallback; ids shifted by ``offset``."""

    def ident(value: int) -> int:
        return value + offset

    return DraftRows(
        header={
            "id": ident(1),
            "name": "Push",
            "description": "Heavy pressing",
            "accent": "teal",
            "image_checksum": "abc",
            "scope": "library",
            "source_plan_id": None,
            "plan_run_id": None,
            "revision_id": ident(2),
            "revision_no": 1,
            "lock_version": 3,
            "revision_status": "DRAFT",
            **header,
        },
        days=[
            {
                "id": ident(10),
                "revision_id": ident(2),
                "ordinal": 0,
                "weekday": 1,
                "name": "Push A",
                "description": None,
                "icon": "push",
            },
            {
                "id": ident(11),
                "revision_id": ident(2),
                "ordinal": 1,
                "weekday": None,
                "name": "Rest",
                "description": None,
                "icon": "rest",
            },
        ],
        workout_units=[
            {
                "id": ident(20),
                "day_id": ident(10),
                "lineage_key": PUSH_UNIT,
                "name": "Push A",
                "description": None,
                "warmup_notes": "Bands",
                "stretch_notes": None,
            }
        ],
        slots=[
            {
                "id": ident(30),
                "workout_unit_id": ident(20),
                "lineage_key": PRESS_SLOT,
                "ordinal": 0,
                "name": "Press",
                "description": None,
                "goal": "Strength",
                "role": "PRIMARY_PROGRESSIVE",
                "volume_axis": None,
                "loading_mode": "high_load",
                "loading_cycle": ["high_load", "low_load"],
            },
            {
                "id": ident(31),
                "workout_unit_id": ident(20),
                "lineage_key": FLY_SLOT,
                "ordinal": 1,
                "name": "Fly",
                "description": None,
                "goal": None,
                "role": "ACCESSORY",
                "volume_axis": None,
                "loading_mode": "moderate_load",
                "loading_cycle": None,
            },
        ],
        target_muscles=[
            {"slot_id": ident(30), "muscle_id": 7, "slug": "triceps"},
            {"slot_id": ident(30), "muscle_id": 4, "slug": "pectoralis"},
        ],
        variants=[
            {
                "id": ident(50),
                "slot_id": ident(30),
                "ordinal": 0,
                "variant_type": "DEFAULT",
                "exercise_id": 60,
                "exercise_slug": "bench_press",
                "progression_model_slug": "double_progression",
                "progression_id": LOOP,
                "load_step_kg": Decimal("2.50"),
                "active_working_set_min": 1,
                "active_working_set_max": 2,
            },
            {
                "id": ident(51),
                "slot_id": ident(30),
                "ordinal": 1,
                "variant_type": "FALLBACK",
                "exercise_id": 61,
                "exercise_slug": "dumbbell_press",
                "progression_model_slug": None,
                "progression_id": LOOP,
                "load_step_kg": Decimal("2.000"),
                "active_working_set_min": None,
                "active_working_set_max": None,
            },
            {
                "id": ident(52),
                "slot_id": ident(31),
                "ordinal": 0,
                "variant_type": "DEFAULT",
                "exercise_id": 62,
                "exercise_slug": "cable_fly",
                "progression_model_slug": None,
                "progression_id": FLY_LOOP,
                "load_step_kg": Decimal("1.25"),
                "active_working_set_min": None,
                "active_working_set_max": None,
            },
        ],
        sets=[
            {
                "id": ident(70 + index),
                "exercise_variant_id": ident(variant),
                "ordinal": ordinal,
                "rep_min": 5,
                "rep_max": 8,
                "rep_range_semantics": "gating",
                "rir": "RIR2",
                "role": role,
                "load_spec": {"kind": "absolute"},
                "min_volume_level": 0,
                "loading_mode": None,
                "loading_cycle": None,
            }
            for index, (variant, ordinal, role) in enumerate(
                [
                    (50, 0, "rampup"),
                    (50, 1, "working"),
                    (50, 2, "working"),
                    (51, 0, "working"),
                    (52, 0, "working"),
                    (52, 1, "working"),
                ]
            )
        ],
    )


def changed(rows: DraftRows, entity: str, index: int, **values: Any) -> DraftRows:
    """A deep copy of ``rows`` with one row of ``entity`` updated."""
    copied = copy.deepcopy(rows)
    getattr(copied, entity)[index].update(values)
    return copied


def reversed_rows(rows: DraftRows) -> DraftRows:
    return DraftRows(
        header=rows.header,
        days=rows.days[::-1],
        workout_units=rows.workout_units[::-1],
        slots=rows.slots[::-1],
        target_muscles=rows.target_muscles[::-1],
        variants=rows.variants[::-1],
        sets=rows.sets[::-1],
    )


def test_fingerprint_is_a_stable_sha256() -> None:
    fingerprint = definition_fingerprint(revision())

    assert re.fullmatch(r"[0-9a-f]{64}", fingerprint)
    assert definition_fingerprint(revision()) == fingerprint
    # Row order from the database does not matter; ordinals do.
    assert definition_fingerprint(reversed_rows(revision())) == fingerprint


def test_fp_01_same_tree_with_different_row_ids_is_equal() -> None:
    """T-UNIT-FP-01: ids, parent ids, revision id, number and lock version are ignored."""
    source = revision()
    copy_ = revision(offset=1000, revision_no=7, lock_version=42, revision_status="RELEASED")

    assert definition_fingerprint(copy_) == definition_fingerprint(source)


def test_fp_02_changing_one_set_rep_max_is_a_change() -> None:
    """T-UNIT-FP-02."""
    source = revision()

    assert definition_fingerprint(changed(source, "sets", 4, rep_max=9)) != (
        definition_fingerprint(source)
    )


def test_fp_03_changing_a_slot_lineage_key_is_a_change() -> None:
    """T-UNIT-FP-03: deleting a slot and adding an identical one is a change."""
    source = revision()
    readded = changed(source, "slots", 1, lineage_key=UUID(int=99))
    new_unit = changed(source, "workout_units", 0, lineage_key=UUID(int=98))

    assert definition_fingerprint(readded) != definition_fingerprint(source)
    assert definition_fingerprint(new_unit) != definition_fingerprint(source)


def test_fp_04_plan_identity_fields_are_ignored() -> None:
    """T-UNIT-FP-04: name, description, accent and cover are not revision-scoped (D14)."""
    source = revision()
    renamed = revision(
        name="Push (renamed)",
        description=None,
        accent="rose",
        image_checksum=None,
        scope="run",
        source_plan_id=1,
        plan_run_id=5,
    )

    assert definition_fingerprint(renamed) == definition_fingerprint(source)


def test_fp_05_reordering_exercises_is_a_change() -> None:
    """T-UNIT-FP-05: swapping two slots' ordinals."""
    source = revision()
    swapped = changed(changed(source, "slots", 0, ordinal=1), "slots", 1, ordinal=0)

    assert definition_fingerprint(swapped) != definition_fingerprint(source)


def test_every_definition_field_counts() -> None:
    source = definition_fingerprint(revision())
    edits: list[tuple[str, int, dict[str, Any]]] = [
        ("days", 0, {"weekday": 2}),
        ("days", 0, {"icon": "upper"}),
        ("days", 1, {"name": "Recovery"}),
        ("workout_units", 0, {"warmup_notes": None}),
        ("slots", 0, {"loading_cycle": ["low_load", "high_load"]}),
        ("slots", 1, {"role": "VOLUME_ACCUMULATION"}),
        ("target_muscles", 0, {"muscle_id": 8}),
        ("variants", 0, {"exercise_id": 63}),
        ("variants", 0, {"load_step_kg": Decimal("5")}),
        ("variants", 1, {"variant_type": "DEFAULT"}),
        ("variants", 2, {"progression_id": LOOP}),
        ("sets", 0, {"role": "working"}),
        ("sets", 1, {"load_spec": {"kind": "athlete_selected"}}),
        ("sets", 2, {"loading_mode": "low_load"}),
    ]
    for entity, index, values in edits:
        assert definition_fingerprint(changed(revision(), entity, index, **values)) != source, (
            entity,
            values,
        )


def test_catalog_slugs_and_number_formatting_are_ignored() -> None:
    source = definition_fingerprint(revision())
    renamed_slugs = changed(
        changed(revision(), "variants", 0, exercise_slug="renamed"),
        "target_muscles",
        0,
        slug="renamed",
    )
    # The same step as stored (numeric scale) or as a float from another reader.
    rescaled = changed(revision(), "variants", 0, load_step_kg=2.5)

    assert definition_fingerprint(renamed_slugs) == source
    assert definition_fingerprint(rescaled) == source


def test_progression_ids_can_be_ignored_for_copies_with_fresh_ids() -> None:
    source = revision()
    fresh = changed(
        changed(changed(source, "variants", 0, progression_id=UUID(int=1)), "variants", 1),
        "variants",
        2,
        progression_id=UUID(int=2),
    )
    fresh.variants[1]["progression_id"] = UUID(int=1)

    assert definition_fingerprint(fresh) != definition_fingerprint(source)
    assert definition_fingerprint(fresh, include_progression_ids=False) == (
        definition_fingerprint(source, include_progression_ids=False)
    )
