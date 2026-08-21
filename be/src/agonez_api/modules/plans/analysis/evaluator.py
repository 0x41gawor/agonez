import math
from collections.abc import Mapping
from dataclasses import dataclass, field
from typing import Any

from agonez_api.modules.plans.analysis.domain import (
    AnalysisCatalog,
    ExerciseEngineData,
    ResolvedDay,
    ResolvedPlan,
)
from agonez_api.modules.plans.analysis.parameters import (
    CUMULATIVE_SET_PENALTY_CAP,
    CUMULATIVE_SET_PENALTY_STEP,
    DAYS_PER_WEEK,
    EFFECTIVE_REPS_BY_RIR,
    HOURS_PER_DAY,
    JOINT_RECOVERY_VELOCITY_V1,
    MEANINGFUL_CONTRIBUTION_EPSILON,
    MODEL_VERSION,
    MUSCLE_RECOVERY_VELOCITY_V1,
    RECOVERY_CONVERGENCE_EPSILON_HOURS,
    RECOVERY_MAX_CYCLES,
    RIR_RECOVERY_MULTIPLIER,
    cumulative_set_multiplier,
)
from agonez_api.modules.plans.analysis.schemas import (
    AnalysisContribution,
    AnalysisDiagnostic,
    AnalysisModelParameters,
    AnalysisTimelineDay,
    DiagnosticSeverity,
    IntentClassification,
    JointAnalysisSummary,
    JointContribution,
    JointStimulus,
    MuscleAnalysisSummary,
    MuscleContribution,
    MuscleStimulus,
    PlanAnalysisResult,
    PlanAnalysisSummary,
    PlanResolutionContext,
    RecoveryState,
    TimelineWorkout,
    TimingAssumption,
    WorkoutStimulus,
)


@dataclass
class _WorkoutAggregate:
    muscle_etu: dict[str, float] = field(default_factory=dict)
    muscle_mru: dict[str, float] = field(default_factory=dict)
    muscle_recovery_hours: dict[str, float] = field(default_factory=dict)
    joint_load: dict[str, float] = field(default_factory=dict)
    joint_jru: dict[str, float] = field(default_factory=dict)
    joint_recovery_hours: dict[str, float] = field(default_factory=dict)


@dataclass(frozen=True)
class _ValidatedEngine:
    source: ExerciseEngineData
    etu: dict[str, float] | None
    active_tension: dict[str, float] | None
    recovery_modifier: dict[str, float] | None
    joint_load: dict[str, float] | None


@dataclass(frozen=True)
class _DayRecoverySnapshot:
    muscle_before: dict[str, float]
    muscle_after: dict[str, float]
    joint_before: dict[str, float]
    joint_after: dict[str, float]


@dataclass(frozen=True)
class _SimulationResult:
    converged: bool
    cycles: int
    snapshots: dict[int, _DayRecoverySnapshot]
    divergent_muscles: frozenset[str]
    divergent_joints: frozenset[str]


def evaluate_plan(
    plan: ResolvedPlan,
    catalog: AnalysisCatalog,
    *,
    timing_assumptions: list[TimingAssumption] | None = None,
    initial_diagnostics: list[AnalysisDiagnostic] | None = None,
) -> PlanAnalysisResult:
    microcycle_days = len(plan.days)
    microcycle_hours = float(microcycle_days) * HOURS_PER_DAY
    microcycle_weeks = float(microcycle_days) / DAYS_PER_WEEK
    weekly_normalization_factor = (
        DAYS_PER_WEEK / float(microcycle_days) if microcycle_days else 0.0
    )
    diagnostics = list(initial_diagnostics or [])
    diagnostic_keys = {
        (
            item.code,
            item.exercise_slug,
            tuple(item.affected_muscle_slugs),
            tuple(item.affected_joint_slugs),
        )
        for item in diagnostics
    }
    contributions: list[AnalysisContribution] = []
    workouts: dict[int, _WorkoutAggregate] = {}
    validated_engines: dict[str, _ValidatedEngine | None] = {}

    for day in plan.days:
        if day.workout is None:
            continue
        aggregate = _WorkoutAggregate()
        workouts[day.workout.id] = aggregate
        prior_muscle_sets: dict[str, int] = {}
        prior_joint_sets: dict[str, int] = {}
        for slot in day.workout.slots:
            selected = slot.selected_exercise
            if selected is None:
                continue
            if selected.exercise_slug not in validated_engines:
                source = catalog.exercises.get(selected.exercise_slug)
                if source is None:
                    _add_diagnostic(
                        diagnostics,
                        diagnostic_keys,
                        AnalysisDiagnostic(
                            code="MISSING_ENGINE_EXERCISE",
                            severity=DiagnosticSeverity.WARNING,
                            message=(
                                f"Exercise '{selected.exercise_slug}' has no catalog "
                                "enrichment row; its active sets were skipped."
                            ),
                            exercise_slug=selected.exercise_slug,
                        ),
                    )
                    validated_engines[selected.exercise_slug] = None
                else:
                    validated_engines[selected.exercise_slug] = _validate_engine(
                        source,
                        diagnostics,
                        diagnostic_keys,
                    )
            engine = validated_engines[selected.exercise_slug]
            if engine is None:
                continue
            for item in selected.sets:
                effective_reps = EFFECTIVE_REPS_BY_RIR[item.rir]
                rir_multiplier = RIR_RECOVERY_MULTIPLIER[item.rir]
                muscle_keys: set[str] = set()
                for vector in (
                    engine.etu,
                    engine.active_tension,
                    engine.recovery_modifier,
                ):
                    if vector is not None:
                        muscle_keys.update(vector)

                for muscle_slug in sorted(muscle_keys):
                    etu_value = (
                        engine.etu.get(muscle_slug, 0.0)
                        if engine.etu is not None
                        else None
                    )
                    etu_contribution = (
                        effective_reps * etu_value if etu_value is not None else None
                    )
                    active_value: float | None = None
                    modifier_value: float | None = None
                    base_mru: float | None = None
                    mru_contribution: float | None = None
                    cumulative_multiplier = 1.0
                    if (
                        engine.active_tension is not None
                        and engine.recovery_modifier is not None
                    ):
                        active_present = muscle_slug in engine.active_tension
                        modifier_present = muscle_slug in engine.recovery_modifier
                        if active_present != modifier_present:
                            active_value = engine.active_tension.get(muscle_slug)
                            modifier_value = engine.recovery_modifier.get(muscle_slug)
                            _add_diagnostic(
                                diagnostics,
                                diagnostic_keys,
                                AnalysisDiagnostic(
                                    code="MALFORMED_RECOVERY_VECTOR_KEYS",
                                    severity=DiagnosticSeverity.WARNING,
                                    message=(
                                        f"Exercise '{engine.source.exercise_slug}' has "
                                        "unmatched active-tension/recovery-modifier data "
                                        f"for '{muscle_slug}'."
                                    ),
                                    exercise_slug=engine.source.exercise_slug,
                                    affected_muscle_slugs=[muscle_slug],
                                ),
                            )
                        else:
                            # Engine muscle vectors are sparse: absence from both aligned
                            # maps means zero exposure for that muscle.
                            active_value = engine.active_tension.get(muscle_slug, 0.0)
                            modifier_value = engine.recovery_modifier.get(
                                muscle_slug, 0.0
                            )
                            base_mru = effective_reps * active_value * modifier_value
                            if base_mru > MEANINGFUL_CONTRIBUTION_EPSILON:
                                prior_count = prior_muscle_sets.get(muscle_slug, 0)
                                cumulative_multiplier = cumulative_set_multiplier(
                                    prior_count
                                )
                                prior_muscle_sets[muscle_slug] = prior_count + 1
                            mru_contribution = (
                                base_mru * rir_multiplier * cumulative_multiplier
                            )

                    if etu_contribution is not None:
                        _increment(aggregate.muscle_etu, muscle_slug, etu_contribution)
                    if mru_contribution is not None:
                        _increment(aggregate.muscle_mru, muscle_slug, mru_contribution)
                    contributions.append(
                        MuscleContribution(
                            day_id=day.id,
                            workout_unit_id=day.workout.id,
                            slot_id=slot.id,
                            slot_role=slot.role,
                            variant_id=selected.variant_id,
                            exercise_id=engine.source.exercise_id,
                            exercise_slug=selected.exercise_slug,
                            set_id=item.id,
                            muscle_slug=muscle_slug,
                            intent_classification=_classify_intent(
                                muscle_slug,
                                slot.target_muscle_slugs,
                            ),
                            effective_reps=effective_reps,
                            etu_vector_value=etu_value,
                            etu_contribution=etu_contribution,
                            active_tension_value=active_value,
                            recovery_modifier_value=modifier_value,
                            base_mru=base_mru,
                            rir_recovery_multiplier=rir_multiplier,
                            cumulative_recovery_multiplier=cumulative_multiplier,
                            mru_contribution=mru_contribution,
                        )
                    )

                if engine.joint_load is not None:
                    for joint_slug, joint_value in sorted(engine.joint_load.items()):
                        joint_load_exposure = effective_reps * joint_value
                        prior_count = prior_joint_sets.get(joint_slug, 0)
                        cumulative_multiplier = 1.0
                        if joint_load_exposure > MEANINGFUL_CONTRIBUTION_EPSILON:
                            cumulative_multiplier = cumulative_set_multiplier(prior_count)
                            prior_joint_sets[joint_slug] = prior_count + 1
                        jru = joint_load_exposure * rir_multiplier * cumulative_multiplier
                        _increment(aggregate.joint_load, joint_slug, joint_load_exposure)
                        _increment(aggregate.joint_jru, joint_slug, jru)
                        contributions.append(
                            JointContribution(
                                day_id=day.id,
                                workout_unit_id=day.workout.id,
                                slot_id=slot.id,
                                slot_role=slot.role,
                                variant_id=selected.variant_id,
                                exercise_id=engine.source.exercise_id,
                                exercise_slug=selected.exercise_slug,
                                set_id=item.id,
                                joint_slug=joint_slug,
                                effective_reps=effective_reps,
                                joint_load_vector_value=joint_value,
                                joint_load_exposure=joint_load_exposure,
                                rir_recovery_multiplier=rir_multiplier,
                                cumulative_recovery_multiplier=cumulative_multiplier,
                                jru_contribution=jru,
                            )
                        )

        for muscle_slug in set(aggregate.muscle_etu) | set(aggregate.muscle_mru):
            mru = aggregate.muscle_mru.get(muscle_slug, 0.0)
            muscle = catalog.muscles.get(muscle_slug)
            fcsa = muscle.fcsa_cm2 if muscle is not None else None
            if fcsa is None or fcsa <= MEANINGFUL_CONTRIBUTION_EPSILON:
                _add_diagnostic(
                    diagnostics,
                    diagnostic_keys,
                    AnalysisDiagnostic(
                        code="MISSING_FCSA",
                        severity=DiagnosticSeverity.WARNING,
                        message=(
                            f"Muscle '{muscle_slug}' has no positive projected FCSA; "
                            "normalized ETU and recovery time are unavailable."
                        ),
                        affected_muscle_slugs=[muscle_slug],
                    ),
                )
                continue
            aggregate.muscle_recovery_hours[muscle_slug] = (
                mru / fcsa
            ) / MUSCLE_RECOVERY_VELOCITY_V1
        for joint_slug, jru in aggregate.joint_jru.items():
            aggregate.joint_recovery_hours[joint_slug] = jru / JOINT_RECOVERY_VELOCITY_V1

    simulation = _simulate_recovery(plan.days, workouts, microcycle_hours)
    if not simulation.converged:
        _add_diagnostic(
            diagnostics,
            diagnostic_keys,
            AnalysisDiagnostic(
                code="RECOVERY_DIVERGENCE",
                severity=DiagnosticSeverity.ERROR,
                message=(
                    f"The repeating {microcycle_hours:g}-hour microcycle did not reach a "
                    "periodic recovery "
                    f"state within {RECOVERY_MAX_CYCLES} cycles."
                ),
                affected_muscle_slugs=sorted(simulation.divergent_muscles),
                affected_joint_slugs=sorted(simulation.divergent_joints),
            ),
        )

    plan_summary = _build_summary(
        contributions,
        catalog,
        plan.days,
        simulation,
        weekly_normalization_factor,
    )
    timeline = _build_timeline(plan.days, workouts, simulation, microcycle_hours)
    context = plan.resolution_context
    return PlanAnalysisResult(
        model_version=MODEL_VERSION,
        plan_id=plan.plan_id,
        revision_id=plan.revision_id,
        revision_no=plan.revision_no,
        lock_version=plan.lock_version,
        resolution_context=PlanResolutionContext(
            global_volume_level=context.global_volume_level,
            focus_area=context.focus_area,
            axis_overrides=dict(context.axis_overrides),
        ),
        timing_assumptions=list(timing_assumptions or []),
        model_parameters=AnalysisModelParameters(
            microcycle_days=microcycle_days,
            microcycle_hours=microcycle_hours,
            microcycle_weeks=microcycle_weeks,
            weekly_normalization_factor=weekly_normalization_factor,
            effective_reps_by_rir=dict(EFFECTIVE_REPS_BY_RIR),
            rir_recovery_multiplier=dict(RIR_RECOVERY_MULTIPLIER),
            cumulative_set_penalty_step=CUMULATIVE_SET_PENALTY_STEP,
            cumulative_set_penalty_cap=CUMULATIVE_SET_PENALTY_CAP,
            meaningful_contribution_epsilon=MEANINGFUL_CONTRIBUTION_EPSILON,
            recovery_convergence_epsilon_hours=(RECOVERY_CONVERGENCE_EPSILON_HOURS),
            recovery_max_cycles=RECOVERY_MAX_CYCLES,
            muscle_recovery_velocity_v1=MUSCLE_RECOVERY_VELOCITY_V1,
            joint_recovery_velocity_v1=JOINT_RECOVERY_VELOCITY_V1,
        ),
        recovery_converged=simulation.converged,
        simulation_cycles=simulation.cycles,
        plan_summary=plan_summary,
        timeline=timeline,
        contributions=contributions,
        diagnostics=diagnostics,
    )


def _validate_engine(
    source: ExerciseEngineData,
    diagnostics: list[AnalysisDiagnostic],
    diagnostic_keys: set[tuple[str, str | None, tuple[str, ...], tuple[str, ...]]],
) -> _ValidatedEngine:
    return _ValidatedEngine(
        source=source,
        etu=_validate_vector(
            source.etu_vector,
            source.exercise_slug,
            "ETU",
            diagnostics,
            diagnostic_keys,
        ),
        active_tension=_validate_vector(
            source.active_tension_vector,
            source.exercise_slug,
            "ACTIVE_TENSION",
            diagnostics,
            diagnostic_keys,
        ),
        recovery_modifier=_validate_vector(
            source.recovery_modifier_vector,
            source.exercise_slug,
            "RECOVERY_MODIFIER",
            diagnostics,
            diagnostic_keys,
        ),
        joint_load=_validate_vector(
            source.joint_load_vector,
            source.exercise_slug,
            "JOINT_LOAD",
            diagnostics,
            diagnostic_keys,
        ),
    )


def _validate_vector(
    value: Mapping[str, Any] | None,
    exercise_slug: str,
    label: str,
    diagnostics: list[AnalysisDiagnostic],
    diagnostic_keys: set[tuple[str, str | None, tuple[str, ...], tuple[str, ...]]],
) -> dict[str, float] | None:
    if value is None:
        code = f"MISSING_{label}_VECTOR"
        _add_diagnostic(
            diagnostics,
            diagnostic_keys,
            AnalysisDiagnostic(
                code=code,
                severity=DiagnosticSeverity.WARNING,
                message=f"Exercise '{exercise_slug}' has no {label.lower()} vector.",
                exercise_slug=exercise_slug,
            ),
        )
        return None
    result: dict[str, float] = {}
    malformed_keys: list[str] = []
    for key, raw in value.items():
        if (
            not isinstance(key, str)
            or not key
            or isinstance(raw, bool)
            or not isinstance(raw, (int, float))
        ):
            malformed_keys.append(str(key))
            continue
        numeric = float(raw)
        if not math.isfinite(numeric) or numeric < 0:
            malformed_keys.append(key)
            continue
        result[key] = numeric
    if malformed_keys:
        _add_diagnostic(
            diagnostics,
            diagnostic_keys,
            AnalysisDiagnostic(
                code=f"MALFORMED_{label}_VECTOR",
                severity=DiagnosticSeverity.WARNING,
                message=(
                    f"Exercise '{exercise_slug}' has invalid {label.lower()} entries: "
                    + ", ".join(sorted(malformed_keys))
                ),
                exercise_slug=exercise_slug,
            ),
        )
    return result


def _classify_intent(
    muscle_slug: str,
    target_muscle_slugs: frozenset[str],
) -> IntentClassification:
    if not target_muscle_slugs:
        return IntentClassification.UNCLASSIFIED
    if muscle_slug in target_muscle_slugs:
        return IntentClassification.INTENTIONAL
    return IntentClassification.INCIDENTAL


def _simulate_recovery(
    days: tuple[ResolvedDay, ...],
    workouts: Mapping[int, _WorkoutAggregate],
    microcycle_hours: float,
) -> _SimulationResult:
    muscle_keys = sorted(
        {
            slug
            for aggregate in workouts.values()
            for slug, value in aggregate.muscle_recovery_hours.items()
            if value > MEANINGFUL_CONTRIBUTION_EPSILON
        }
    )
    joint_keys = sorted(
        {
            slug
            for aggregate in workouts.values()
            for slug, value in aggregate.joint_recovery_hours.items()
            if value > MEANINGFUL_CONTRIBUTION_EPSILON
        }
    )
    muscle_state = {slug: 0.0 for slug in muscle_keys}
    joint_state = {slug: 0.0 for slug in joint_keys}
    snapshots: dict[int, _DayRecoverySnapshot] = {}
    last_muscle_delta = {slug: 0.0 for slug in muscle_keys}
    last_joint_delta = {slug: 0.0 for slug in joint_keys}

    for cycle in range(1, RECOVERY_MAX_CYCLES + 1):
        start_muscle = dict(muscle_state)
        start_joint = dict(joint_state)
        muscle_state, joint_state, snapshots = _run_cycle(
            days,
            workouts,
            start_muscle,
            start_joint,
            microcycle_hours,
        )
        last_muscle_delta = {
            slug: abs(muscle_state[slug] - start_muscle[slug]) for slug in muscle_keys
        }
        last_joint_delta = {slug: abs(joint_state[slug] - start_joint[slug]) for slug in joint_keys}
        largest_delta = max([0.0, *last_muscle_delta.values(), *last_joint_delta.values()])
        if largest_delta <= RECOVERY_CONVERGENCE_EPSILON_HOURS:
            _, _, final_snapshots = _run_cycle(
                days,
                workouts,
                muscle_state,
                joint_state,
                microcycle_hours,
            )
            return _SimulationResult(
                converged=True,
                cycles=cycle,
                snapshots=final_snapshots,
                divergent_muscles=frozenset(),
                divergent_joints=frozenset(),
            )

    _, _, final_snapshots = _run_cycle(
        days,
        workouts,
        muscle_state,
        joint_state,
        microcycle_hours,
    )
    return _SimulationResult(
        converged=False,
        cycles=RECOVERY_MAX_CYCLES,
        snapshots=final_snapshots,
        divergent_muscles=frozenset(
            slug
            for slug, delta in last_muscle_delta.items()
            if delta > RECOVERY_CONVERGENCE_EPSILON_HOURS
        ),
        divergent_joints=frozenset(
            slug
            for slug, delta in last_joint_delta.items()
            if delta > RECOVERY_CONVERGENCE_EPSILON_HOURS
        ),
    )


def _run_cycle(
    days: tuple[ResolvedDay, ...],
    workouts: Mapping[int, _WorkoutAggregate],
    start_muscle: Mapping[str, float],
    start_joint: Mapping[str, float],
    microcycle_hours: float,
) -> tuple[dict[str, float], dict[str, float], dict[int, _DayRecoverySnapshot]]:
    muscle_state = dict(start_muscle)
    joint_state = dict(start_joint)
    snapshots: dict[int, _DayRecoverySnapshot] = {}
    previous_offset = 0.0
    ordered_days = sorted(days, key=lambda day: (day.hour_offset, day.ordinal, day.id))
    for day in ordered_days:
        elapsed = day.hour_offset - previous_offset
        _decay(muscle_state, elapsed)
        _decay(joint_state, elapsed)
        muscle_before = dict(muscle_state)
        joint_before = dict(joint_state)
        if day.workout is not None:
            aggregate = workouts.get(day.workout.id)
            if aggregate is not None:
                _apply_additions(muscle_state, aggregate.muscle_recovery_hours)
                _apply_additions(joint_state, aggregate.joint_recovery_hours)
        snapshots[day.id] = _DayRecoverySnapshot(
            muscle_before=muscle_before,
            muscle_after=dict(muscle_state),
            joint_before=joint_before,
            joint_after=dict(joint_state),
        )
        previous_offset = day.hour_offset
    _decay(muscle_state, microcycle_hours - previous_offset)
    _decay(joint_state, microcycle_hours - previous_offset)
    return muscle_state, joint_state, snapshots


def _build_summary(
    contributions: list[AnalysisContribution],
    catalog: AnalysisCatalog,
    days: tuple[ResolvedDay, ...],
    simulation: _SimulationResult,
    weekly_normalization_factor: float,
) -> PlanAnalysisSummary:
    muscle_values: dict[str, dict[str, float]] = {}
    joint_values: dict[str, dict[str, float]] = {}
    for contribution in contributions:
        if isinstance(contribution, MuscleContribution):
            values = muscle_values.setdefault(
                contribution.muscle_slug,
                {
                    "etu": 0.0,
                    "intentional": 0.0,
                    "incidental": 0.0,
                    "unclassified": 0.0,
                    "mru": 0.0,
                },
            )
            etu = contribution.etu_contribution or 0.0
            mru = contribution.mru_contribution or 0.0
            values["etu"] += etu
            values["mru"] += mru
            if contribution.intent_classification == IntentClassification.INTENTIONAL:
                values["intentional"] += etu
            elif contribution.intent_classification == IntentClassification.INCIDENTAL:
                values["incidental"] += etu
            else:
                values["unclassified"] += etu
        else:
            values = joint_values.setdefault(
                contribution.joint_slug,
                {"load": 0.0, "jru": 0.0},
            )
            values["load"] += contribution.joint_load_exposure
            values["jru"] += contribution.jru_contribution

    workout_days = [day for day in days if day.workout is not None]
    muscles = []
    for slug, values in sorted(muscle_values.items()):
        muscle = catalog.muscles.get(slug)
        fcsa = muscle.fcsa_cm2 if muscle is not None else None
        pre_values = [
            simulation.snapshots[day.id].muscle_before.get(slug, 0.0) for day in workout_days
        ]
        post_values = [
            simulation.snapshots[day.id].muscle_after.get(slug, 0.0) for day in workout_days
        ]
        muscles.append(
            MuscleAnalysisSummary(
                slug=slug,
                fcsa_cm2=fcsa,
                total_etu=values["etu"],
                weekly_etu=values["etu"] * weekly_normalization_factor,
                etu_per_fcsa_cm2=(
                    values["etu"] / fcsa
                    if fcsa is not None and fcsa > MEANINGFUL_CONTRIBUTION_EPSILON
                    else None
                ),
                weekly_etu_per_fcsa_cm2=(
                    values["etu"] * weekly_normalization_factor / fcsa
                    if fcsa is not None and fcsa > MEANINGFUL_CONTRIBUTION_EPSILON
                    else None
                ),
                intentional_etu=values["intentional"],
                weekly_intentional_etu=(
                    values["intentional"] * weekly_normalization_factor
                ),
                incidental_etu=values["incidental"],
                weekly_incidental_etu=(
                    values["incidental"] * weekly_normalization_factor
                ),
                unclassified_etu=values["unclassified"],
                weekly_unclassified_etu=(
                    values["unclassified"] * weekly_normalization_factor
                ),
                total_mru=values["mru"],
                maximum_post_workout_hours_to_fresh=max(post_values, default=0.0),
                worst_pre_workout_hours_to_fresh=max(pre_values, default=0.0),
                recovery_converged=slug not in simulation.divergent_muscles,
            )
        )
    joints = []
    for slug, values in sorted(joint_values.items()):
        pre_values = [
            simulation.snapshots[day.id].joint_before.get(slug, 0.0) for day in workout_days
        ]
        post_values = [
            simulation.snapshots[day.id].joint_after.get(slug, 0.0) for day in workout_days
        ]
        joints.append(
            JointAnalysisSummary(
                slug=slug,
                total_joint_load_exposure=values["load"],
                total_jru=values["jru"],
                maximum_post_workout_hours_to_fresh=max(post_values, default=0.0),
                worst_pre_workout_hours_to_fresh=max(pre_values, default=0.0),
                recovery_converged=slug not in simulation.divergent_joints,
            )
        )
    total_etu_scalar = sum(values["etu"] for values in muscle_values.values())
    return PlanAnalysisSummary(
        total_etu_scalar=total_etu_scalar,
        weekly_etu_scalar=total_etu_scalar * weekly_normalization_factor,
        muscles=muscles,
        joints=joints,
    )


def _build_timeline(
    days: tuple[ResolvedDay, ...],
    workouts: Mapping[int, _WorkoutAggregate],
    simulation: _SimulationResult,
    microcycle_hours: float,
) -> list[AnalysisTimelineDay]:
    ordered_days = sorted(days, key=lambda day: (day.hour_offset, day.ordinal, day.id))
    if not ordered_days:
        return []
    previous_offset = ordered_days[-1].hour_offset - microcycle_hours
    timeline: list[AnalysisTimelineDay] = []
    for day in ordered_days:
        snapshot = simulation.snapshots[day.id]
        workout_artifact = None
        if day.workout is not None:
            aggregate = workouts.get(day.workout.id, _WorkoutAggregate())
            muscle_slugs = sorted(
                set(aggregate.muscle_etu)
                | set(aggregate.muscle_mru)
                | set(aggregate.muscle_recovery_hours)
            )
            joint_slugs = sorted(
                set(aggregate.joint_load)
                | set(aggregate.joint_jru)
                | set(aggregate.joint_recovery_hours)
            )
            workout_artifact = TimelineWorkout(
                workout_unit_id=day.workout.id,
                name=day.workout.name,
                stimulus=WorkoutStimulus(
                    total_etu_scalar=sum(aggregate.muscle_etu.values()),
                    muscles=[
                        MuscleStimulus(
                            slug=slug,
                            etu_absolute=aggregate.muscle_etu.get(slug, 0.0),
                            mru=aggregate.muscle_mru.get(slug, 0.0),
                            recovery_hours_added=aggregate.muscle_recovery_hours.get(slug, 0.0),
                        )
                        for slug in muscle_slugs
                    ],
                    joints=[
                        JointStimulus(
                            slug=slug,
                            joint_load_exposure=aggregate.joint_load.get(slug, 0.0),
                            jru=aggregate.joint_jru.get(slug, 0.0),
                            recovery_hours_added=aggregate.joint_recovery_hours.get(slug, 0.0),
                        )
                        for slug in joint_slugs
                    ],
                ),
            )
        timeline.append(
            AnalysisTimelineDay(
                day_id=day.id,
                day_ordinal=day.ordinal,
                day_name=day.name,
                weekday=day.weekday,
                hour_offset=day.hour_offset,
                elapsed_hours_since_previous_entry=day.hour_offset - previous_offset,
                workout=workout_artifact,
                muscle_recovery_before=_state_items(snapshot.muscle_before),
                muscle_recovery_after=_state_items(snapshot.muscle_after),
                joint_recovery_before=_state_items(snapshot.joint_before),
                joint_recovery_after=_state_items(snapshot.joint_after),
            )
        )
        previous_offset = day.hour_offset
    return timeline


def _state_items(values: Mapping[str, float]) -> list[RecoveryState]:
    return [
        RecoveryState(slug=slug, hours_to_fresh=value) for slug, value in sorted(values.items())
    ]


def _increment(values: dict[str, float], key: str, amount: float) -> None:
    values[key] = values.get(key, 0.0) + amount


def _decay(values: dict[str, float], elapsed_hours: float) -> None:
    for key in values:
        values[key] = max(0.0, values[key] - elapsed_hours)


def _apply_additions(values: dict[str, float], additions: Mapping[str, float]) -> None:
    for key, amount in additions.items():
        values[key] = values.get(key, 0.0) + amount


def _add_diagnostic(
    diagnostics: list[AnalysisDiagnostic],
    keys: set[tuple[str, str | None, tuple[str, ...], tuple[str, ...]]],
    diagnostic: AnalysisDiagnostic,
) -> None:
    key = (
        diagnostic.code,
        diagnostic.exercise_slug,
        tuple(diagnostic.affected_muscle_slugs),
        tuple(diagnostic.affected_joint_slugs),
    )
    if key not in keys:
        keys.add(key)
        diagnostics.append(diagnostic)
