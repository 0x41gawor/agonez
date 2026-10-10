from __future__ import annotations

from datetime import date as Date
from datetime import datetime
from enum import Enum
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator


class APIModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class PlanRunStatus(str, Enum):
    SCHEDULED = "scheduled"
    ACTIVE = "active"
    CANCELLED = "cancelled"
    COMPLETED = "completed"


class MicrocycleClassification(str, Enum):
    NORMAL = "normal"
    DELOAD = "deload"
    RELOAD = "reload"


class WorkoutSessionStatus(str, Enum):
    SCHEDULED = "scheduled"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    MISSED = "missed"


class CompletionMode(str, Enum):
    AS_PRESCRIBED = "as_prescribed"
    FALLBACK = "fallback"


class PerformanceStatus(str, Enum):
    DRAFT = "draft"
    FINALIZED = "finalized"


class ExerciseExecutionMode(str, Enum):
    AS_PRESCRIBED = "as_prescribed"
    SUBSTITUTED = "substituted"
    SKIPPED = "skipped"
    ADDITIONAL = "additional"
    NOT_PERFORMED = "not_performed"


class PerformedSetStatus(str, Enum):
    PERFORMED = "performed"
    SKIPPED = "skipped"
    NOT_PERFORMED = "not_performed"


class PlanRunEventType(str, Enum):
    PLAN_REVISION_CHANGED = "plan_revision_changed"
    PERSONAL_RECORD = "personal_record"
    DELOAD_STARTED = "deload_started"
    RELOAD_STARTED = "reload_started"
    VACATION = "vacation"
    TRAINING_BREAK = "training_break"
    OBSERVATION = "observation"


class LoadDivergence(str, Enum):
    BELOW = "below"
    EQUAL = "equal"
    ABOVE = "above"


class RepsPosition(str, Enum):
    BELOW_RANGE = "below_range"
    AT_FLOOR = "at_floor"
    IN_RANGE = "in_range"
    TOP_OF_RANGE = "top_of_range"
    ABOVE_RANGE = "above_range"


class RIRDivergence(str, Enum):
    DEEPER = "deeper"
    ON_TARGET = "on_target"
    SHALLOWER = "shallower"


class NextPrescriptionState(str, Enum):
    EDITABLE = "editable"
    BLOCKED = "blocked"
    LOCKED = "locked"
    NONE = "none"


class BlockedReason(str, Enum):
    PREVIOUS_EXPOSURE_IN_PROGRESS = "previous_exposure_in_progress"
    PREVIOUS_EXPOSURE_NOT_PERFORMED = "previous_exposure_not_performed"
    SESSION_STARTED = "session_started"
    NO_FUTURE_SESSION = "no_future_session"
    RUN_NOT_ACTIVE = "run_not_active"


class PrescriptionCompleteness(str, Enum):
    NONE = "none"
    PARTIAL = "partial"
    COMPLETE = "complete"


class ErrorBody(APIModel):
    code: str
    message: str
    details: dict[str, Any]


class ErrorEnvelope(APIModel):
    error: ErrorBody


class PlanRef(APIModel):
    plan_id: int
    code: str
    name: str


class RevisionRef(APIModel):
    plan_revision_id: int
    revision_no: int
    status: str


class MicrocycleRef(APIModel):
    ordinal: int
    starts_on: Date
    ends_on: Date
    classification: MicrocycleClassification
    plan_revision_no: int


class ExerciseRef(APIModel):
    exercise_id: int
    slug: str
    name: str
    variant_label: str


class SetPlan(APIModel):
    ordinal: int
    role: str
    rep_min: int
    rep_max: int
    target_rir: int | None


class SetPrescription(SetPlan):
    load_kg: float | None
    comment: str | None


class Divergence(APIModel):
    load: LoadDivergence | None
    reps: RepsPosition | None
    rir: RIRDivergence | None


class SetPerformance(APIModel):
    ordinal: int
    prescribed_set_ordinal: int | None
    status: PerformedSetStatus
    load_kg: float | None
    repetitions: int | None
    rir: int | None
    comment: str | None
    recorded_at: datetime
    is_additional: bool
    divergence: Divergence


class PlanRunListItem(APIModel):
    plan_run_id: int
    name: str
    status: PlanRunStatus
    plan: PlanRef
    starts_on: Date
    ends_on: Date
    microcycle_count: int
    microcycle_duration_days: int
    current_microcycle_ordinal: int | None


class PlanRunListResponse(APIModel):
    as_of: Date
    items: list[PlanRunListItem]


class PreviewDay(APIModel):
    day_ordinal: int
    date: Date
    workout_unit_name: str | None


class OverlappingRun(APIModel):
    plan_run_id: int
    name: str
    starts_on: Date
    ends_on: Date


class PlanRunPreview(APIModel):
    revision: RevisionRef
    microcycle_duration_days: int
    ends_on: Date
    session_count: int
    workout_track_count: int
    exercise_track_count: int
    first_microcycle: list[PreviewDay]
    overlapping_runs: list[OverlappingRun]


class PlanRunCreate(APIModel):
    plan_revision_id: int = Field(ge=1)
    name: str = Field(min_length=1, max_length=200)
    starts_on: Date
    microcycle_count: int

    @field_validator("name")
    @classmethod
    def name_not_blank(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("name must not be blank")
        return value


class PlanRunPatch(APIModel):
    name: str | None = Field(default=None, min_length=1, max_length=200)
    status: PlanRunStatus | None = None
    expected_version: str


class RunHeader(APIModel):
    plan_run_id: int
    name: str
    status: PlanRunStatus
    plan: PlanRef
    initial_revision: RevisionRef
    starts_on: Date
    ends_on: Date
    microcycle_count: int
    microcycle_duration_days: int
    version: str


class RunPosition(APIModel):
    microcycle_ordinal: int | None
    day_in_microcycle: int | None
    run_day: int | None
    run_days_total: int
    days_left: int


class SessionBrief(APIModel):
    session_id: int
    workout_trace_id: int
    workout_name: str
    scheduled_date: Date
    status: WorkoutSessionStatus
    completion_mode: CompletionMode | None


class OverviewMicrocycle(APIModel):
    ordinal: int
    starts_on: Date
    ends_on: Date
    classification: MicrocycleClassification
    plan_revision_no: int
    revision_changed_here: bool
    is_current: bool
    sessions: list[SessionBrief]


class PerformanceBrief(APIModel):
    status: PerformanceStatus
    synced_exercise_count: int


class CurrentMicrocycleSession(APIModel):
    session_id: int
    workout_name: str
    scheduled_date: Date
    status: WorkoutSessionStatus
    started_at: datetime | None
    completed_at: datetime | None
    prescription_completeness: PrescriptionCompleteness
    exercise_count: int
    performance: PerformanceBrief | None


class AnalysisReadinessItem(APIModel):
    workout_trace_id: int
    workout_name: str
    state: NextPrescriptionState
    blocked_reason: BlockedReason | None
    basis_date: Date | None
    exercises_total: int
    exercises_prescribed: int


class AnalysisReadiness(APIModel):
    target_microcycle_ordinal: int | None
    workouts: list[AnalysisReadinessItem]


class PrescribedSummary(APIModel):
    set_count: int
    top_load_kg: float | None
    rep_min: int | None
    rep_max: int | None
    target_rir: int | None


class LatestExposureExercise(APIModel):
    exercise_trace_id: int
    name: str
    execution_mode: ExerciseExecutionMode | None
    prescribed_summary: PrescribedSummary
    performed_reps: list[int | None]
    performed_rir: list[int | None]
    flags: list[str]


class LatestExposure(APIModel):
    session_id: int
    workout_trace_id: int
    workout_name: str
    scheduled_date: Date
    exercises: list[LatestExposureExercise]


class Attendance(APIModel):
    microcycle_ordinal: int
    due: int
    completed: int
    missed: int
    cancelled: int
    in_progress: int
    ratio: float | None


class EventSessionRef(APIModel):
    session_id: int
    workout_name: str


class EventExerciseRef(APIModel):
    exercise_trace_id: int
    display_name: str


class EventDTO(APIModel):
    event_id: int
    event_type: PlanRunEventType
    title: str
    occurred_at: datetime
    date: Date
    microcycle_ordinal: int | None
    day_in_microcycle: int | None
    session: EventSessionRef | None
    exercise_trace: EventExerciseRef | None
    from_revision_no: int | None
    to_revision_no: int | None
    body: str | None
    source: Literal["system", "user"]
    metadata: dict[str, Any]


class PlanRunOverview(APIModel):
    as_of: Date
    run: RunHeader
    position: RunPosition
    microcycles: list[OverviewMicrocycle]
    current_microcycle_sessions: list[CurrentMicrocycleSession]
    analysis_readiness: AnalysisReadiness
    latest_exposure: LatestExposure | None
    attendance: list[Attendance]
    latest_events: list[EventDTO]


class TargetSession(APIModel):
    session_id: int
    scheduled_date: Date
    status: WorkoutSessionStatus


class BasisSession(APIModel):
    session_id: int
    scheduled_date: Date
    microcycle_ordinal: int


class LastSummary(APIModel):
    microcycle_ordinal: int
    execution_mode: ExerciseExecutionMode
    top_load_kg: float | None
    reps: list[int | None]


class QueueExercise(APIModel):
    exercise_trace_id: int
    slot_ordinal: int
    name: str
    prescription_saved: bool
    last_summary: LastSummary | None


class BlockedDetail(APIModel):
    session_id: int
    scheduled_date: Date
    started_at: datetime | None
    synced_exercise_count: int
    exercise_count: int


class QueueWorkout(APIModel):
    workout_trace_id: int
    workout_name: str
    day_ordinal: int
    target_session: TargetSession | None
    basis_session: BasisSession | None
    state: NextPrescriptionState
    blocked_reason: BlockedReason | None
    blocked_detail: BlockedDetail | None
    prescription_completeness: PrescriptionCompleteness
    exercises: list[QueueExercise]


class AnalysisQueue(APIModel):
    as_of: Date
    target_microcycle: MicrocycleRef | None
    workouts: list[QueueWorkout]


class WorkoutTraceRef(APIModel):
    workout_trace_id: int
    workout_name: str


class CurrentPlan(APIModel):
    plan_revision_no: int
    slot_role: str
    exercise: ExerciseRef
    sets: list[SetPlan]
    plan_comment: str | None
    progression_model: str | None
    load_step_kg: float | None


class ContinuityLink(APIModel):
    exercise_trace_id: int
    display_name: str
    from_microcycle_ordinal: int


class Continuity(APIModel):
    first_microcycle_ordinal: int
    revisions_spanned: list[int]
    continues_from: ContinuityLink | None
    continued_by: ContinuityLink | None


class TraceHeader(APIModel):
    exercise_trace_id: int
    workout_trace: WorkoutTraceRef
    slot_ordinal: int
    display_name: str
    current_plan: CurrentPlan
    continuity: Continuity


class RevisionTransition(APIModel):
    before_microcycle_ordinal: int
    from_revision_no: int
    to_revision_no: int
    effective_on: Date
    slot_changes: list[str]
    event_id: int | None


class ExposureSession(APIModel):
    session_id: int
    scheduled_date: Date
    status: WorkoutSessionStatus
    completion_mode: CompletionMode | None


class ExposurePrescription(APIModel):
    exercise_prescription_id: int
    exercise: ExerciseRef
    plan_comment: str | None
    prescription_comment: str | None
    based_on_performance_microcycle_ordinal: int | None
    sets: list[SetPrescription]


class PerformanceSummary(APIModel):
    total_reps: int
    volume_load_kg: float
    top_load_kg: float | None


class ExposurePerformance(APIModel):
    status: PerformanceStatus
    execution_mode: ExerciseExecutionMode
    actual_exercise: ExerciseRef | None
    comment: str | None
    sets: list[SetPerformance]
    summary: PerformanceSummary


class ExerciseExposure(APIModel):
    microcycle: MicrocycleRef
    session: ExposureSession
    prescription: ExposurePrescription
    performance: ExposurePerformance | None


class NextTarget(APIModel):
    session_id: int
    workout_trace_id: int
    scheduled_date: Date
    microcycle: MicrocycleRef
    session_status: WorkoutSessionStatus


class NextBasis(APIModel):
    exercise_performance_id: int
    microcycle_ordinal: int
    scheduled_date: Date
    status: PerformanceStatus
    execution_mode: ExerciseExecutionMode


class NextDefaults(APIModel):
    from_previous_prescription: list[float | None]
    from_previous_performance: list[float | None]
    from_seed_run: list[float | None] | None


class SavedPrescriptionSet(APIModel):
    ordinal: int
    load_kg: float | None
    comment: str | None


class SavedPrescription(APIModel):
    exercise_prescription_id: int
    version: str
    workout_prescription_version: str
    sets: list[SavedPrescriptionSet]
    prescription_comment: str | None
    updated_at: datetime


class NextPrescription(APIModel):
    state: NextPrescriptionState
    blocked_reason: BlockedReason | None
    target: NextTarget | None
    basis: NextBasis | None
    plan_sets: list[SetPlan]
    plan_comment: str | None
    defaults: NextDefaults
    prescription: SavedPrescription | None
    suggestion: None = None


class ExerciseTraceResponse(APIModel):
    as_of: Date
    trace: TraceHeader
    revision_transitions: list[RevisionTransition]
    exposures: list[ExerciseExposure]
    next: NextPrescription | None


class PrescriptionSetInput(APIModel):
    ordinal: int
    load_kg: float | None
    comment: str | None = None


class ExercisePrescriptionPut(APIModel):
    based_on_exercise_performance_id: int | None
    sets: list[PrescriptionSetInput]
    prescription_comment: str | None = None
    expected_version: str | None = None


class PrescriptionWriteResponse(APIModel):
    next: NextPrescription
    workout_prescription_completeness: PrescriptionCompleteness


class WorkoutPrescriptionPatch(APIModel):
    prescription_comment: str | None
    expected_version: str


class WorkoutPrescriptionResponse(APIModel):
    session_id: int
    prescription_comment: str | None
    version: str
    updated_at: datetime


class WorkoutTraceListItem(APIModel):
    workout_trace_id: int
    workout_name: str
    day_ordinal: int
    exercise_trace_count: int


class WorkoutTraceList(APIModel):
    items: list[WorkoutTraceListItem]


class Scheme(APIModel):
    set_count: int
    rep_min: int | None
    rep_max: int | None
    target_rir: int | None


class WorkoutTraceColumn(APIModel):
    exercise_trace_id: int
    slot_ordinal: int
    display_name: str
    scheme: Scheme
    top_load_series: list[float | None]
    delta_pct_first_to_latest: float | None
    first_microcycle_ordinal: int
    last_microcycle_ordinal: int | None


class WorkoutRevisionTransition(APIModel):
    before_microcycle_ordinal: int
    from_revision_no: int
    to_revision_no: int
    summary: str


class MatrixSession(APIModel):
    session_id: int
    scheduled_date: Date
    status: WorkoutSessionStatus
    completion_mode: CompletionMode | None
    started_at: datetime | None
    completed_at: datetime | None


class WorkoutTraceCell(APIModel):
    exercise_trace_id: int
    kind: Literal["performed", "prescribed", "empty", "not_in_trace"]
    execution_mode: ExerciseExecutionMode | None
    actual_exercise_name: str | None
    prescribed_top_load_kg: float | None
    performed_top_load_kg: float | None
    reps: list[int | None]
    flags: list[str]
    next_prescription_saved: bool | None


class WorkoutTraceRow(APIModel):
    microcycle: MicrocycleRef
    session: MatrixSession
    prescription_completeness: PrescriptionCompleteness
    performance_comment: str | None
    volume_load_kg: float | None
    progress_marker: None = None
    cells: list[WorkoutTraceCell]


class WorkoutTraceHeader(APIModel):
    workout_trace_id: int
    workout_name: str
    day_ordinal: int


class WorkoutTraceResponse(APIModel):
    as_of: Date
    workout: WorkoutTraceHeader
    columns: list[WorkoutTraceColumn]
    revision_transitions: list[WorkoutRevisionTransition]
    rows: list[WorkoutTraceRow]


class DayColumn(APIModel):
    day_ordinal: int
    workout_trace_id: int | None
    workout_name: str | None


class TimelineDaySession(APIModel):
    session_id: int
    workout_name: str
    status: WorkoutSessionStatus
    completion_mode: CompletionMode | None


class TimelineDay(APIModel):
    day_ordinal: int
    date: Date
    session: TimelineDaySession | None


class EventBrief(APIModel):
    event_id: int
    event_type: PlanRunEventType
    title: str
    occurred_at: datetime


class TimelineMicrocycle(APIModel):
    ordinal: int
    starts_on: Date
    ends_on: Date
    classification: MicrocycleClassification
    plan_revision_no: int
    revision_changed_here: bool
    is_current: bool
    notes: str | None
    version: str
    days: list[TimelineDay]
    attendance: Attendance
    volume_load_kg: float | None
    progress_marker: None = None
    events: list[EventBrief]


class MicrocycleTimeline(APIModel):
    as_of: Date
    day_columns: list[DayColumn]
    microcycles: list[TimelineMicrocycle]


class MicrocyclePatch(APIModel):
    notes: str | None = None
    classification: MicrocycleClassification | None = None
    expected_version: str


class CalendarSession(APIModel):
    session_id: int
    scheduled_date: Date
    microcycle_ordinal: int
    day_ordinal: int
    workout_trace_id: int
    workout_name: str
    status: WorkoutSessionStatus
    completion_mode: CompletionMode | None
    prescription_completeness: PrescriptionCompleteness
    performance_status: PerformanceStatus | None
    fallback_workout_name: str | None


class MicrocycleBound(APIModel):
    ordinal: int
    starts_on: Date
    ends_on: Date
    classification: MicrocycleClassification


class CalendarResponse(APIModel):
    as_of: Date
    sessions: list[CalendarSession]
    microcycle_bounds: list[MicrocycleBound]


class SessionPatch(APIModel):
    status: WorkoutSessionStatus
    reason: str | None = None
    log_event: bool = False
    details: dict[str, Any] = Field(default_factory=dict)


class SessionStatusResponse(APIModel):
    session_id: int
    status: WorkoutSessionStatus
    notes: str | None


class EventListResponse(APIModel):
    items: list[EventDTO]
    next_cursor: str | None


class EventCreate(APIModel):
    event_type: PlanRunEventType
    date: Date
    body: str | None = None
    session_id: int | None = Field(default=None, ge=1)
    exercise_trace_id: int | None = Field(default=None, ge=1)
    metadata: dict[str, Any] = Field(default_factory=dict)


class EventPatch(APIModel):
    date: Date | None = None
    body: str | None = None
    session_id: int | None = Field(default=None, ge=1)
    exercise_trace_id: int | None = Field(default=None, ge=1)
    metadata: dict[str, Any] | None = None


class LoadPoint(APIModel):
    microcycle_ordinal: int
    date: Date
    value: float | None
    set_count: int
    reps: list[int | None]
    status: PerformanceStatus
    execution_mode: ExerciseExecutionMode


class LoadSeries(APIModel):
    exercise_trace_id: int
    display_name: str
    workout_trace_id: int
    workout_name: str
    points: list[LoadPoint]
    first_value: float | None
    latest_value: float | None
    delta_pct: float | None


class XDomainItem(APIModel):
    microcycle_ordinal: int
    starts_on: Date
    classification: MicrocycleClassification
    plan_revision_no: int


class WorkoutLoadSummary(APIModel):
    workout_trace_id: int
    workout_name: str
    mean_delta_pct: float | None
    series_count: int


class LoadSeriesResponse(APIModel):
    as_of: Date
    metric: Literal["top_set_load", "mean_set_load", "volume_load"]
    x_domain: list[XDomainItem]
    series: list[LoadSeries]
    workout_summaries: list[WorkoutLoadSummary]
