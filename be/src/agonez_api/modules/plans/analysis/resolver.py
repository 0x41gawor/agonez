from agonez_api.modules.plans.analysis.domain import (
    ResolutionContext,
    ResolvedDay,
    ResolvedExercise,
    ResolvedPlan,
    ResolvedSet,
    ResolvedSlot,
    ResolvedWorkout,
)
from agonez_api.modules.plans.analysis.parameters import HOURS_PER_DAY
from agonez_api.modules.plans.analysis.schemas import (
    AnalysisDiagnostic,
    DiagnosticSeverity,
    PlanResolutionContext,
    TimingAssumption,
)
from agonez_api.modules.plans.schemas import (
    ExerciseVariantType,
    PlanDraftArtifact,
)


def resolve_plan(
    draft: PlanDraftArtifact,
    context_input: PlanResolutionContext,
) -> tuple[ResolvedPlan, list[TimingAssumption], list[AnalysisDiagnostic]]:
    context = ResolutionContext(
        global_volume_level=context_input.global_volume_level,
        focus_area=context_input.focus_area,
        axis_overrides=dict(context_input.axis_overrides),
    )
    assumptions: list[TimingAssumption] = []
    diagnostics: list[AnalysisDiagnostic] = []
    resolved_days: list[ResolvedDay] = []

    for index, day in enumerate(draft.days):
        hour_offset = float(day.ordinal) * HOURS_PER_DAY
        timing_source = "MICROCYCLE_ORDINAL"
        weekday_detail = (
            f" Saved weekday {day.weekday} is display metadata only."
            if day.weekday is not None
            else " No weekday metadata is stored."
        )
        detail = (
            f"Microcycle day {day.ordinal + 1} fixes this boundary at "
            f"hour {hour_offset:g}.{weekday_detail}"
        )
        if index > 0:
            previous = draft.days[index - 1]
            if previous.weekday is not None and day.weekday is not None:
                expected_weekday = previous.weekday % 7 + 1
                if day.weekday != expected_weekday:
                    diagnostics.append(
                        AnalysisDiagnostic(
                            code="WEEKDAY_SEQUENCE_MISMATCH",
                            severity=DiagnosticSeverity.INFO,
                            message=(
                                f"Day {day.id} stores ISO weekday {day.weekday} after day "
                                f"{previous.id} weekday {previous.weekday}; ordered microcycle "
                                "timing remains authoritative."
                            ),
                        )
                    )
        assumptions.append(
            TimingAssumption(
                day_id=day.id,
                day_ordinal=day.ordinal,
                timing_source=timing_source,
                hour_offset=hour_offset,
                detail=detail,
            )
        )

        resolved_workout: ResolvedWorkout | None = None
        if day.workout_unit is not None:
            slots: list[ResolvedSlot] = []
            for slot in day.workout_unit.exercise_slots:
                effective_volume_level = context.global_volume_level
                if slot.volume_axis is not None:
                    effective_volume_level = context.axis_overrides.get(
                        slot.volume_axis,
                        context.global_volume_level,
                    )
                default_variant = next(
                    (
                        variant
                        for variant in slot.variants
                        if variant.variant_type == ExerciseVariantType.DEFAULT
                    ),
                    None,
                )
                selected_exercise = None
                if default_variant is not None:
                    selected_exercise = ResolvedExercise(
                        variant_id=default_variant.id,
                        exercise_slug=default_variant.exercise_slug,
                        sets=tuple(
                            ResolvedSet(
                                id=item.id,
                                ordinal=item.ordinal,
                                rep_min=item.reps.min,
                                rep_max=item.reps.max,
                                rir=item.rir,
                                min_volume_level=item.min_volume_level,
                            )
                            for item in default_variant.sets
                            if item.min_volume_level <= effective_volume_level
                        ),
                    )
                slots.append(
                    ResolvedSlot(
                        id=slot.id,
                        ordinal=slot.ordinal,
                        name=slot.name,
                        goal=slot.goal,
                        role=slot.role,
                        volume_axis=slot.volume_axis,
                        effective_volume_level=effective_volume_level,
                        target_muscle_slugs=frozenset(slot.target_muscle_slugs),
                        selected_exercise=selected_exercise,
                    )
                )
            resolved_workout = ResolvedWorkout(
                id=day.workout_unit.id,
                name=day.workout_unit.name,
                slots=tuple(slots),
            )
        resolved_days.append(
            ResolvedDay(
                id=day.id,
                ordinal=day.ordinal,
                weekday=day.weekday,
                name=day.name,
                hour_offset=hour_offset,
                timing_source=timing_source,
                workout=resolved_workout,
            )
        )

    return (
        ResolvedPlan(
            plan_id=draft.id,
            revision_id=draft.revision_id,
            revision_no=draft.revision_no,
            lock_version=draft.lock_version,
            resolution_context=context,
            days=tuple(resolved_days),
        ),
        assumptions,
        diagnostics,
    )
