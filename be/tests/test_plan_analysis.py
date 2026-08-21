import copy
from typing import Any

import pytest

from agonez_api.modules.plans.analysis.domain import (
    AnalysisCatalog,
    ExerciseEngineData,
    MuscleCatalogData,
)
from agonez_api.modules.plans.analysis.evaluator import evaluate_plan
from agonez_api.modules.plans.analysis.parameters import (
    JOINT_RECOVERY_VELOCITY_V1,
    MUSCLE_RECOVERY_VELOCITY_V1,
)
from agonez_api.modules.plans.analysis.resolver import resolve_plan
from agonez_api.modules.plans.analysis.schemas import (
    IntentClassification,
    JointContribution,
    MuscleContribution,
    PlanResolutionContext,
)
from agonez_api.modules.plans.schemas import PlanDraftArtifact


def _set(
    set_id: int,
    ordinal: int,
    rir: int,
    *,
    min_volume_level: int = 0,
) -> dict[str, Any]:
    return {
        "id": set_id,
        "ordinal": ordinal,
        "reps": {"min": 8, "max": 12},
        "rir": rir,
        "min_volume_level": min_volume_level,
    }


def _slot(
    slot_id: int,
    sets: list[dict[str, Any]],
    *,
    ordinal: int = 0,
    targets: list[str] | None = None,
    volume_axis: str | None = None,
    exercise_slug: str = "default_press",
    include_fallback: bool = True,
) -> dict[str, Any]:
    variants: list[dict[str, Any]] = [
        {
            "id": slot_id * 10,
            "ordinal": 0,
            "variant_type": "DEFAULT",
            "exercise_slug": exercise_slug,
            "sets": sets,
        }
    ]
    if include_fallback:
        variants.append(
            {
                "id": slot_id * 10 + 1,
                "ordinal": 1,
                "variant_type": "FALLBACK",
                "exercise_slug": "fallback_press",
                "sets": [_set(slot_id * 1000 + 99, 0, 0)],
            }
        )
    return {
        "id": slot_id,
        "ordinal": ordinal,
        "name": f"Slot {slot_id}",
        "description": None,
        "goal": "Hypertrophy",
        "role": "PRIMARY_PROGRESSIVE",
        "volume_axis": volume_axis,
        "target_muscle_slugs": targets or [],
        "variants": variants,
    }


def _draft(
    slots_by_day: list[list[dict[str, Any]] | None],
    *,
    weekdays: list[int | None] | None = None,
) -> PlanDraftArtifact:
    weekdays = weekdays or [index + 1 for index in range(len(slots_by_day))]
    days: list[dict[str, Any]] = []
    for index, slots in enumerate(slots_by_day):
        days.append(
            {
                "id": 100 + index,
                "ordinal": index,
                "weekday": weekdays[index],
                "name": "Rest" if slots is None else f"Day {index + 1}",
                "description": None,
                "workout_unit": (
                    None
                    if slots is None
                    else {
                        "id": 200 + index,
                        "name": f"Workout {index + 1}",
                        "description": None,
                        "warmup_notes": None,
                        "stretch_notes": None,
                        "exercise_slots": slots,
                    }
                ),
            }
        )
    return PlanDraftArtifact.model_validate(
        {
            "id": 6,
            "revision_id": 9,
            "revision_no": 1,
            "lock_version": 55,
            "name": "Analysis test",
            "description": None,
            "days": days,
        }
    )


def _catalog(
    *,
    etu: dict[str, Any] | None = None,
    active: dict[str, Any] | None = None,
    modifier: dict[str, Any] | None = None,
    joint: dict[str, Any] | None = None,
    fcsa: dict[str, float | None] | None = None,
) -> AnalysisCatalog:
    etu = {"chest": 2.0} if etu is None else etu
    active = {"chest": 3.0} if active is None else active
    modifier = {"chest": 1.1} if modifier is None else modifier
    joint = {"elbow_joint": 0.5} if joint is None else joint
    fcsa = {"chest": 10.0} if fcsa is None else fcsa
    return AnalysisCatalog(
        exercises={
            "default_press": ExerciseEngineData(
                exercise_id=501,
                exercise_slug="default_press",
                etu_vector=etu,
                active_tension_vector=active,
                recovery_modifier_vector=modifier,
                joint_load_vector=joint,
            ),
            "fallback_press": ExerciseEngineData(
                exercise_id=502,
                exercise_slug="fallback_press",
                etu_vector={"chest": 999.0},
                active_tension_vector={"chest": 999.0},
                recovery_modifier_vector={"chest": 1.0},
                joint_load_vector={"elbow_joint": 999.0},
            ),
        },
        muscles={
            slug: MuscleCatalogData(slug=slug, fcsa_cm2=value) for slug, value in fcsa.items()
        },
    )


def _analyze(
    draft: PlanDraftArtifact,
    catalog: AnalysisCatalog,
    context: PlanResolutionContext | None = None,
):
    resolved, assumptions, diagnostics = resolve_plan(
        draft,
        context or PlanResolutionContext(),
    )
    return resolved, evaluate_plan(
        resolved,
        catalog,
        timing_assumptions=assumptions,
        initial_diagnostics=diagnostics,
    )


def test_resolver_uses_default_variant_volume_gate_and_preserves_rest_days() -> None:
    draft = _draft(
        [
            [
                _slot(
                    1,
                    [_set(1, 0, 2), _set(2, 1, 1, min_volume_level=2)],
                    volume_axis="upper",
                )
            ],
            None,
        ],
        weekdays=[1, None],
    )
    original = copy.deepcopy(draft.model_dump())
    resolved, result = _analyze(draft, _catalog())

    selected = resolved.days[0].workout.slots[0].selected_exercise  # type: ignore[union-attr]
    assert selected is not None
    assert selected.exercise_slug == "default_press"
    assert [item.id for item in selected.sets] == [1]
    assert resolved.days[1].workout is None
    assert result.timeline[1].workout is None
    assert "fallback_press" not in {item.exercise_slug for item in result.contributions}
    assert [day.hour_offset for day in resolved.days] == [0.0, 24.0]
    assert {item.timing_source for item in result.timing_assumptions} == {
        "MICROCYCLE_ORDINAL"
    }
    assert draft.model_dump() == original

    resolved_override, _ = _analyze(
        draft,
        _catalog(),
        PlanResolutionContext(axis_overrides={"upper": 2}),
    )
    selected_override = resolved_override.days[0].workout.slots[0].selected_exercise  # type: ignore[union-attr]
    assert selected_override is not None
    assert [item.id for item in selected_override.sets] == [1, 2]


def test_etu_mru_jru_formulas_effective_reps_and_provenance() -> None:
    draft = _draft([[_slot(1, [_set(1, 0, 0), _set(2, 1, 4)], targets=["chest"])]])
    _, result = _analyze(draft, _catalog())
    muscles = [item for item in result.contributions if isinstance(item, MuscleContribution)]
    joints = [item for item in result.contributions if isinstance(item, JointContribution)]

    assert [item.effective_reps for item in muscles] == [5.0, 1.0]
    assert muscles[0].etu_contribution == pytest.approx(5 * 2.0)
    assert muscles[1].etu_contribution == pytest.approx(1 * 2.0)
    assert muscles[0].base_mru == pytest.approx(5 * 3.0 * 1.1)
    assert muscles[0].mru_contribution == pytest.approx(5 * 3.0 * 1.1 * 1.15)
    assert muscles[1].cumulative_recovery_multiplier == pytest.approx(1.05)
    assert muscles[1].mru_contribution == pytest.approx(1 * 3.0 * 1.1 * 1.05)
    assert joints[0].joint_load_exposure == pytest.approx(5 * 0.5)
    assert joints[0].jru_contribution == pytest.approx(5 * 0.5 * 1.15)
    assert joints[1].cumulative_recovery_multiplier == pytest.approx(1.05)
    assert {item.day_id for item in muscles} == {100}
    assert {item.workout_unit_id for item in muscles} == {200}
    assert {item.slot_id for item in muscles} == {1}
    assert {item.variant_id for item in muscles} == {10}
    assert {item.exercise_id for item in muscles} == {501}
    assert {item.set_id for item in muscles} == {1, 2}
    joint_summary = result.plan_summary.joints[0]
    assert joint_summary.total_joint_load_exposure == pytest.approx(
        sum(item.joint_load_exposure for item in joints)
    )
    assert joint_summary.total_jru == pytest.approx(
        sum(item.jru_contribution for item in joints)
    )


def test_intent_classification_aggregation_fcsa_and_provenance_sums() -> None:
    slots = [
        _slot(1, [_set(1, 0, 2)], targets=["chest"], ordinal=0),
        _slot(2, [_set(2, 0, 2)], targets=["other"], ordinal=1),
        _slot(3, [_set(3, 0, 2)], ordinal=2),
    ]
    _, result = _analyze(_draft([slots]), _catalog())
    contributions = [item for item in result.contributions if isinstance(item, MuscleContribution)]
    assert [item.intent_classification for item in contributions] == [
        IntentClassification.INTENTIONAL,
        IntentClassification.INCIDENTAL,
        IntentClassification.UNCLASSIFIED,
    ]
    summary = result.plan_summary.muscles[0]
    assert summary.total_etu == pytest.approx(18.0)
    assert summary.etu_per_fcsa_cm2 == pytest.approx(1.8)
    assert summary.intentional_etu == pytest.approx(6.0)
    assert summary.incidental_etu == pytest.approx(6.0)
    assert summary.unclassified_etu == pytest.approx(6.0)
    assert result.plan_summary.total_etu_scalar == pytest.approx(
        sum(item.etu_contribution or 0.0 for item in contributions)
    )
    assert summary.total_mru == pytest.approx(
        sum(item.mru_contribution or 0.0 for item in contributions)
    )


def test_cumulative_penalty_reaches_cap() -> None:
    sets = [_set(index + 1, index, 2) for index in range(8)]
    _, result = _analyze(_draft([[_slot(1, sets)]]), _catalog())
    muscle_contributions = [
        item for item in result.contributions if isinstance(item, MuscleContribution)
    ]
    joint_contributions = [
        item for item in result.contributions if isinstance(item, JointContribution)
    ]
    assert muscle_contributions[-1].cumulative_recovery_multiplier == 1.30
    assert joint_contributions[-1].cumulative_recovery_multiplier == 1.30


def test_recovery_conversion_linear_decay_rest_and_before_after_snapshots() -> None:
    draft = _draft(
        [[_slot(1, [_set(1, 0, 2)])], None, [_slot(2, [_set(2, 0, 2)])]],
        weekdays=[1, 2, 3],
    )
    _, result = _analyze(draft, _catalog())
    expected_mru = 3 * 3.0 * 1.1
    expected_hours = (expected_mru / 10.0) / MUSCLE_RECOVERY_VELOCITY_V1
    expected_joint_hours = (3 * 0.5) / JOINT_RECOVERY_VELOCITY_V1

    first = result.timeline[0]
    rest = result.timeline[1]
    second = result.timeline[2]
    assert first.muscle_recovery_after[0].hours_to_fresh == pytest.approx(expected_hours)
    assert first.joint_recovery_after[0].hours_to_fresh == pytest.approx(expected_joint_hours)
    assert rest.muscle_recovery_before[0].hours_to_fresh == pytest.approx(
        max(0.0, expected_hours - 24.0)
    )
    assert rest.muscle_recovery_before == rest.muscle_recovery_after
    assert second.muscle_recovery_after[0].hours_to_fresh == pytest.approx(
        second.muscle_recovery_before[0].hours_to_fresh + expected_hours
    )
    assert result.recovery_converged is True
    assert result.plan_summary.muscles[0].maximum_post_workout_hours_to_fresh > 0


def test_periodic_simulation_carries_sunday_debt_into_monday() -> None:
    high_active_catalog = _catalog(active={"chest": 30.0})
    draft = _draft(
        [
            [_slot(1, [_set(1, 0, 2)])],
            None,
            None,
            None,
            None,
            None,
            [_slot(2, [_set(2, 0, 2)])],
        ],
        weekdays=[1, 2, 3, 4, 5, 6, 7],
    )
    _, result = _analyze(draft, high_active_catalog)

    monday = next(item for item in result.timeline if item.weekday == 1)
    assert result.simulation_cycles > 1
    assert monday.muscle_recovery_before[0].hours_to_fresh > 0
    assert result.recovery_converged is True
    assert result.model_parameters.microcycle_days == 7
    assert result.model_parameters.microcycle_hours == 168
    assert result.model_parameters.weekly_normalization_factor == 1


def test_fourteen_day_microcycle_uses_full_chronology_and_weekly_etu_normalization() -> None:
    days: list[list[dict[str, Any]] | None] = [None] * 14
    days[0] = [_slot(1, [_set(1, 0, 2)], targets=["chest"])]
    days[7] = [_slot(2, [_set(2, 0, 2)], targets=["chest"])]
    weekdays = [1, 2, 3, 4, 5, 6, 7, 1, 2, 3, 4, 5, 6, 7]

    resolved, result = _analyze(_draft(days, weekdays=weekdays), _catalog())
    muscle = result.plan_summary.muscles[0]

    assert [day.hour_offset for day in resolved.days] == [index * 24 for index in range(14)]
    assert [day.elapsed_hours_since_previous_entry for day in result.timeline] == [24] * 14
    assert result.model_parameters.microcycle_days == 14
    assert result.model_parameters.microcycle_hours == 336
    assert result.model_parameters.microcycle_weeks == 2
    assert result.model_parameters.weekly_normalization_factor == pytest.approx(0.5)
    assert result.plan_summary.total_etu_scalar == pytest.approx(12.0)
    assert result.plan_summary.weekly_etu_scalar == pytest.approx(6.0)
    assert muscle.total_etu == pytest.approx(12.0)
    assert muscle.weekly_etu == pytest.approx(6.0)
    assert muscle.etu_per_fcsa_cm2 == pytest.approx(1.2)
    assert muscle.weekly_etu_per_fcsa_cm2 == pytest.approx(0.6)
    assert muscle.weekly_intentional_etu == pytest.approx(6.0)


def test_repeated_weekday_metadata_does_not_collapse_day_boundaries() -> None:
    draft = _draft([None, None], weekdays=[1, 1])
    resolved, result = _analyze(draft, _catalog())

    assert [day.hour_offset for day in resolved.days] == [0.0, 24.0]
    assert any(item.code == "WEEKDAY_SEQUENCE_MISMATCH" for item in result.diagnostics)


def test_overloaded_periodic_recovery_returns_divergence_diagnostic() -> None:
    overloaded = _catalog(active={"chest": 1000.0}, fcsa={"chest": 1.0})
    draft = _draft([[_slot(1, [_set(1, 0, 0)])]])
    _, result = _analyze(draft, overloaded)

    assert result.recovery_converged is False
    assert result.simulation_cycles == 256
    diagnostic = next(item for item in result.diagnostics if item.code == "RECOVERY_DIVERGENCE")
    assert diagnostic.affected_muscle_slugs == ["chest"]
    assert result.plan_summary.muscles[0].recovery_converged is False


def test_missing_and_malformed_vectors_are_partial_and_explicit() -> None:
    catalog = _catalog(
        etu=None,
        active={"chest": "bad"},
        modifier={"chest": 1.1},
        joint=None,
    )
    # Explicitly replace defaults because _catalog treats None as its default fixture.
    source = catalog.exercises["default_press"]
    catalog = AnalysisCatalog(
        exercises={
            **catalog.exercises,
            "default_press": ExerciseEngineData(
                exercise_id=source.exercise_id,
                exercise_slug=source.exercise_slug,
                etu_vector=None,
                active_tension_vector={"chest": "bad"},
                recovery_modifier_vector={"chest": 1.1},
                joint_load_vector=None,
            ),
        },
        muscles=catalog.muscles,
    )
    _, result = _analyze(_draft([[_slot(1, [_set(1, 0, 2)])]]), catalog)
    codes = {item.code for item in result.diagnostics}

    assert {
        "MISSING_ETU_VECTOR",
        "MALFORMED_ACTIVE_TENSION_VECTOR",
        "MISSING_JOINT_LOAD_VECTOR",
        "MALFORMED_RECOVERY_VECTOR_KEYS",
    } <= codes
    assert result.model_version == "plan-analysis-v2"
    assert result.plan_id == 6
    assert result.revision_id == 9
    assert result.lock_version == 55
