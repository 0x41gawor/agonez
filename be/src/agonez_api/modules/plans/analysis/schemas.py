from enum import Enum
from typing import Annotated, Literal

from pydantic import Field, field_validator

from agonez_api.modules.plans.schemas import APIModel, ExerciseSlotRole


class PlanResolutionContext(APIModel):
    global_volume_level: int = Field(default=0, ge=0, le=32767)
    focus_area: str | None = Field(default=None, max_length=100)
    axis_overrides: dict[str, int] = Field(default_factory=dict)

    @field_validator("axis_overrides")
    @classmethod
    def validate_axis_overrides(cls, value: dict[str, int]) -> dict[str, int]:
        if any(not key.strip() or len(key) > 100 for key in value):
            raise ValueError("Volume-axis override names must contain 1 to 100 characters")
        if any(level < 0 or level > 32767 for level in value.values()):
            raise ValueError("Volume-axis override levels must be between 0 and 32767")
        return value


class PlanAnalysisRequest(APIModel):
    resolution_context: PlanResolutionContext = Field(default_factory=PlanResolutionContext)


class DiagnosticSeverity(str, Enum):
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"


class AnalysisDiagnostic(APIModel):
    code: str
    severity: DiagnosticSeverity
    message: str
    exercise_slug: str | None = None
    affected_muscle_slugs: list[str] = Field(default_factory=list)
    affected_joint_slugs: list[str] = Field(default_factory=list)


class TimingAssumption(APIModel):
    day_id: int
    day_ordinal: int
    timing_source: Literal["WEEKDAY", "ORDINAL_ASSUMPTION"]
    hour_offset: float
    detail: str


class AnalysisModelParameters(APIModel):
    microcycle_hours: float
    effective_reps_by_rir: dict[int, float]
    rir_recovery_multiplier: dict[int, float]
    cumulative_set_penalty_step: float
    cumulative_set_penalty_cap: float
    meaningful_contribution_epsilon: float
    recovery_convergence_epsilon_hours: float
    recovery_max_cycles: int
    muscle_recovery_velocity_v1: float
    joint_recovery_velocity_v1: float


class MuscleAnalysisSummary(APIModel):
    slug: str
    fcsa_cm2: float | None
    total_etu: float
    etu_per_fcsa_cm2: float | None
    intentional_etu: float
    incidental_etu: float
    unclassified_etu: float
    total_mru: float
    maximum_post_workout_hours_to_fresh: float
    worst_pre_workout_hours_to_fresh: float
    recovery_converged: bool


class JointAnalysisSummary(APIModel):
    slug: str
    total_joint_load_exposure: float
    total_jru: float
    maximum_post_workout_hours_to_fresh: float
    worst_pre_workout_hours_to_fresh: float
    recovery_converged: bool


class PlanAnalysisSummary(APIModel):
    total_etu_scalar: float
    muscles: list[MuscleAnalysisSummary]
    joints: list[JointAnalysisSummary]


class MuscleStimulus(APIModel):
    slug: str
    etu_absolute: float
    mru: float
    recovery_hours_added: float


class JointStimulus(APIModel):
    slug: str
    joint_load_exposure: float
    jru: float
    recovery_hours_added: float


class WorkoutStimulus(APIModel):
    total_etu_scalar: float
    muscles: list[MuscleStimulus]
    joints: list[JointStimulus]


class RecoveryState(APIModel):
    slug: str
    hours_to_fresh: float


class TimelineWorkout(APIModel):
    workout_unit_id: int
    name: str
    stimulus: WorkoutStimulus


class AnalysisTimelineDay(APIModel):
    day_id: int
    day_ordinal: int
    day_name: str
    weekday: int | None
    hour_offset: float
    elapsed_hours_since_previous_entry: float
    workout: TimelineWorkout | None
    muscle_recovery_before: list[RecoveryState]
    muscle_recovery_after: list[RecoveryState]
    joint_recovery_before: list[RecoveryState]
    joint_recovery_after: list[RecoveryState]


class IntentClassification(str, Enum):
    INTENTIONAL = "INTENTIONAL"
    INCIDENTAL = "INCIDENTAL"
    UNCLASSIFIED = "UNCLASSIFIED"


class MuscleContribution(APIModel):
    type: Literal["MUSCLE"] = "MUSCLE"
    day_id: int
    workout_unit_id: int
    slot_id: int
    slot_role: ExerciseSlotRole
    variant_id: int
    exercise_id: int
    exercise_slug: str
    set_id: int
    muscle_slug: str
    intent_classification: IntentClassification
    effective_reps: float
    etu_vector_value: float | None
    etu_contribution: float | None
    active_tension_value: float | None
    recovery_modifier_value: float | None
    base_mru: float | None
    rir_recovery_multiplier: float
    cumulative_recovery_multiplier: float
    mru_contribution: float | None


class JointContribution(APIModel):
    type: Literal["JOINT"] = "JOINT"
    day_id: int
    workout_unit_id: int
    slot_id: int
    slot_role: ExerciseSlotRole
    variant_id: int
    exercise_id: int
    exercise_slug: str
    set_id: int
    joint_slug: str
    effective_reps: float
    joint_load_vector_value: float
    joint_load_exposure: float
    rir_recovery_multiplier: float
    cumulative_recovery_multiplier: float
    jru_contribution: float


AnalysisContribution = Annotated[
    MuscleContribution | JointContribution,
    Field(discriminator="type"),
]


class PlanAnalysisResult(APIModel):
    model_version: str
    plan_id: int
    revision_id: int
    revision_no: int
    lock_version: int
    resolution_context: PlanResolutionContext
    timing_assumptions: list[TimingAssumption]
    model_parameters: AnalysisModelParameters
    recovery_converged: bool
    simulation_cycles: int
    plan_summary: PlanAnalysisSummary
    timeline: list[AnalysisTimelineDay]
    contributions: list[AnalysisContribution]
    diagnostics: list[AnalysisDiagnostic]
