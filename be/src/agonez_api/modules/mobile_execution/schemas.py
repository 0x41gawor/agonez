from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from typing import Annotated, Any, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator


class APIModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class ExerciseIdentity(APIModel):
    id: int
    slug: str
    name: str
    full_name: str | None = None


class TechniqueTLDR(APIModel):
    setup: str | None = None
    execution: str | None = None
    focus: str | None = None
    stop_when: str | None = None


class AtlasMuscle(APIModel):
    muscle_id: int
    slug: str
    name: str
    etu_cm2: float
    capacity_share: float | None


class BodyMapRegion(APIModel):
    region_id: str
    intensity: float = Field(ge=0, le=1)


class BodyMap(APIModel):
    asset: str
    asset_version: str
    regions: list[BodyMapRegion]


class AtlasPeek(APIModel):
    exercise: ExerciseIdentity
    tags: list[str]
    technique_tldr: TechniqueTLDR
    muscles_top: list[AtlasMuscle]
    body_map: BodyMap
    content_locale: str
    atlas_version: str


class PrescriptionSet(APIModel):
    set_prescription_id: int
    ordinal: int
    role: str
    prescribed_load_kg: float | None
    rep_min: int
    rep_max: int
    target_rir: int | None
    comment: str | None


class PrescriptionSlot(APIModel):
    goal: str | None
    role: str


class PrescriptionAlternative(APIModel):
    exercise: ExerciseIdentity
    source: Literal["plan_variant"] = "plan_variant"
    variant_ordinal: int
    atlas_peek: AtlasPeek


class PreviousSet(APIModel):
    ordinal: int
    status: Literal["performed", "skipped", "not_performed"]
    load_kg: float | None
    repetitions: int | None
    rir: int | None


class PreviousExposure(APIModel):
    microcycle_ordinal: int
    performed_on: date
    exercise: ExerciseIdentity
    sets: list[PreviousSet]


class ExerciseHistory(APIModel):
    previous_exposure: PreviousExposure | None


class PrescriptionExercise(APIModel):
    exercise_prescription_id: int
    ordinal: int
    exercise_track_id: int
    slot: PrescriptionSlot
    exercise: ExerciseIdentity
    variant_label: str | None
    plan_comment: str | None
    prescription_comment: str | None
    load_step_kg: float
    default_rest_s: int
    sets: list[PrescriptionSet]
    alternatives: list[PrescriptionAlternative]
    history: ExerciseHistory
    atlas_peek: AtlasPeek


class PrescriptionMicrocycle(APIModel):
    ordinal: int
    classification: Literal["normal", "deload", "reload"]


class WorkoutPrescription(APIModel):
    session_id: int
    prescription_id: int
    prescription_version: str
    workout_unit_name: str
    workout_track_id: int
    microcycle: PrescriptionMicrocycle
    plan_comment: str | None
    prescription_comment: str | None
    exercises: list[PrescriptionExercise]


class Lease(APIModel):
    device_id: UUID
    epoch: int
    is_this_device: bool


class PositionHint(APIModel):
    exercise_performance_id: UUID
    set_ordinal: int
    phase: Literal["set", "exercise_complete"]


class WorkoutCounts(APIModel):
    prescribed_sets: int
    performed_sets: int
    skipped_sets: int


class ActiveWorkoutSummary(APIModel):
    workout_id: UUID
    session_id: int
    workout_unit_name: str
    started_at: datetime
    lease: Lease
    applied_seq: int
    revision: int
    position_hint: PositionHint | None
    counts: WorkoutCounts


class SetPerformance(APIModel):
    set_performance_id: UUID
    prescribed_set_id: int | None
    ordinal: int
    status: Literal["performed", "skipped", "not_performed"]
    load_kg: float | None
    repetitions: int | None
    rir: int | None
    comment: str | None
    heart_rate_bpm: int | None
    performed_at: datetime | None
    received_at: datetime
    rev: int


class ExercisePerformance(APIModel):
    exercise_performance_id: UUID
    exercise_prescription_id: int | None
    performed_ordinal: int
    mode: Literal["as_prescribed", "substituted", "skipped", "not_performed", "added"]
    actual_exercise: ExerciseIdentity | None
    comment: str | None
    rev: int
    sets: list[SetPerformance]


class PerformanceTree(APIModel):
    comment: str | None
    exercises: list[ExercisePerformance]


class WorkoutSnapshot(APIModel):
    workout_id: UUID
    session_id: int
    status: Literal["in_progress", "completed"]
    started_at: datetime
    finished_at: datetime | None
    lease: Lease
    applied_seq: int
    revision: int
    position_hint: PositionHint | None
    prescription: WorkoutPrescription
    performance: PerformanceTree


class PlanRunCompact(APIModel):
    id: int
    name: str
    status: str
    starts_on: date
    ends_on: date
    microcycle_count: int
    current_microcycle_ordinal: int | None


class ContextPlanRun(PlanRunCompact):
    plan_name: str
    microcycle_duration_days: int


class TodayMicrocycle(APIModel):
    id: int
    ordinal: int
    day_ordinal: int
    classification: str


class TodayPosition(APIModel):
    date: date
    microcycle: TodayMicrocycle | None


class MicrocycleDay(APIModel):
    date: date
    day_ordinal: int
    session_id: int | None
    workout_unit_name: str | None
    status: str


class PrescriptionReadiness(APIModel):
    readiness: Literal["ready", "missing", "not_applicable"]
    prescription_version: str | None = None
    updated_at: datetime | None = None
    exercise_count: int | None = None
    set_count: int | None = None
    estimated_duration_min: int | None = None


class SessionSummary(APIModel):
    session_id: int
    workout_unit_name: str
    workout_track_id: int
    scheduled_on: date
    status: str
    prescription: PrescriptionReadiness
    relation: Literal["earlier_missed", "later_in_microcycle"] | None = None


class RecentWorkout(APIModel):
    session_id: int
    workout_unit_name: str
    completed_at: datetime
    performed_sets: int
    prescribed_sets: int
    skipped_sets: int


class MobileContext(APIModel):
    generated_at: datetime
    context_version: str
    plan_run: ContextPlanRun | None
    selection_required: bool
    today: TodayPosition | None
    microcycle_days: list[MicrocycleDay]
    expected_session: SessionSummary | None
    alternatives: list[SessionSummary]
    fallbacks: list[dict[str, Any]]
    active_workout: ActiveWorkoutSummary | None
    recent: list[RecentWorkout]


class OffSchedule(APIModel):
    acknowledged: bool
    selected_from: str
    expected_session_id: int | None = None


class StartWorkout(APIModel):
    workout_id: UUID
    session_id: int = Field(ge=1)
    prescription_version: str
    started_at: datetime
    allow_missing_loads: bool = False
    off_schedule: OffSchedule | None = None


class ClaimWorkout(APIModel):
    device_id: UUID
    observed_applied_seq: int = Field(ge=0)


class FinalizeWorkout(APIModel):
    lease_epoch: int = Field(ge=1)
    final_seq: int = Field(ge=0)
    finished_at: datetime
    unrecorded: Literal["mark_not_performed"] = "mark_not_performed"
    acknowledged_incomplete: bool = False


class CompletionSummary(APIModel):
    prescribed_sets: int
    performed_sets: int
    skipped_sets: int
    not_performed_sets: int
    additional_sets: int
    substitutions: int
    skipped_exercises: int
    added_exercises: int
    reordered: bool


class FinalizeResponse(APIModel):
    workout_id: UUID
    status: Literal["completed"]
    finished_at: datetime
    summary: CompletionSummary


class OpData(APIModel):
    if_rev: int | None = Field(default=None, ge=0)


class UpsertSetData(OpData):
    set_performance_id: UUID
    exercise_performance_id: UUID
    exercise_prescription_id: int | None = Field(default=None, ge=1)
    prescribed_set_id: int | None = Field(default=None, ge=1)
    ordinal: int = Field(ge=0)
    status: Literal["performed"] = "performed"
    load_kg: Decimal | None = None
    repetitions: int
    rir: int | None = None
    comment: str | None = None
    heart_rate_bpm: int | None = None
    performed_at: datetime


class SkipSetData(OpData):
    set_performance_id: UUID
    exercise_performance_id: UUID
    exercise_prescription_id: int | None = Field(default=None, ge=1)
    prescribed_set_id: int = Field(ge=1)
    ordinal: int = Field(ge=0)
    comment: str | None = None


class ClearSetData(OpData):
    set_performance_id: UUID


class SetExerciseCommentData(OpData):
    exercise_performance_id: UUID
    exercise_prescription_id: int | None = Field(default=None, ge=1)
    comment: str | None


class SkipExerciseData(OpData):
    exercise_performance_id: UUID
    exercise_prescription_id: int = Field(ge=1)
    comment: str | None = None


class SubstituteExerciseData(OpData):
    exercise_performance_id: UUID
    exercise_prescription_id: int = Field(ge=1)
    actual_exercise_id: int = Field(ge=1)
    source: Literal["plan_variant", "atlas"]
    variant_ordinal: int | None = Field(default=None, ge=0)


class AddUnplannedExerciseData(OpData):
    exercise_performance_id: UUID
    actual_exercise_id: int = Field(ge=1)
    performed_ordinal: int = Field(ge=0)


class ReorderExercisesData(OpData):
    order: list[UUID] = Field(min_length=1)

    @model_validator(mode="after")
    def unique_order(self) -> ReorderExercisesData:
        if len(set(self.order)) != len(self.order):
            raise ValueError("order must not contain duplicate exercise ids")
        return self


class SetCursorData(OpData):
    exercise_performance_id: UUID
    set_ordinal: int = Field(ge=0)
    phase: Literal["set", "exercise_complete"] = "set"


class SetWorkoutCommentData(OpData):
    comment: str | None


class BaseOperation(APIModel):
    op_id: UUID
    seq: int = Field(ge=1)
    at: datetime


class UpsertSetOperation(BaseOperation):
    type: Literal["upsert_set"]
    data: UpsertSetData


class SkipSetOperation(BaseOperation):
    type: Literal["skip_set"]
    data: SkipSetData


class ClearSetOperation(BaseOperation):
    type: Literal["clear_set"]
    data: ClearSetData


class SetExerciseCommentOperation(BaseOperation):
    type: Literal["set_exercise_comment"]
    data: SetExerciseCommentData


class SkipExerciseOperation(BaseOperation):
    type: Literal["skip_exercise"]
    data: SkipExerciseData


class SubstituteExerciseOperation(BaseOperation):
    type: Literal["substitute_exercise"]
    data: SubstituteExerciseData


class AddUnplannedExerciseOperation(BaseOperation):
    type: Literal["add_unplanned_exercise"]
    data: AddUnplannedExerciseData


class ReorderExercisesOperation(BaseOperation):
    type: Literal["reorder_exercises"]
    data: ReorderExercisesData


class SetCursorOperation(BaseOperation):
    type: Literal["set_cursor"]
    data: SetCursorData


class SetWorkoutCommentOperation(BaseOperation):
    type: Literal["set_workout_comment"]
    data: SetWorkoutCommentData


MobileOperation = Annotated[
    UpsertSetOperation
    | SkipSetOperation
    | ClearSetOperation
    | SetExerciseCommentOperation
    | SkipExerciseOperation
    | SubstituteExerciseOperation
    | AddUnplannedExerciseOperation
    | ReorderExercisesOperation
    | SetCursorOperation
    | SetWorkoutCommentOperation,
    Field(discriminator="type"),
]


class OperationBatch(APIModel):
    lease_epoch: int = Field(ge=1)
    base_seq: int = Field(ge=0)
    ops: list[MobileOperation] = Field(min_length=1, max_length=200)

    @model_validator(mode="after")
    def contiguous(self) -> OperationBatch:
        expected = list(range(self.base_seq + 1, self.base_seq + 1 + len(self.ops)))
        if [item.seq for item in self.ops] != expected:
            raise ValueError("ops must be contiguous and ordered from base_seq + 1")
        return self


class OperationError(APIModel):
    code: str
    message: str


class OperationResult(APIModel):
    seq: int
    op_id: UUID
    status: Literal["applied", "duplicate", "conflict", "rejected"]
    entity_rev: int | None = None
    server_state: dict[str, Any] | None = None
    error: OperationError | None = None


class OperationBatchResponse(APIModel):
    applied_seq: int
    revision: int
    results: list[OperationResult]
    unsupported_fields: list[str] = Field(default_factory=list)
    server_time: datetime


class LastPerformedSet(APIModel):
    load_kg: float | None
    repetitions: int
    rir: int | None


class LastPerformedInRun(APIModel):
    microcycle_ordinal: int
    sets: list[LastPerformedSet]


class AtlasSearchItem(APIModel):
    id: int
    slug: str
    name: str
    full_name: str
    mechanics_tier: str
    target_category: str
    last_performed_in_run: LastPerformedInRun | None


class AtlasSearchResponse(APIModel):
    items: list[AtlasSearchItem]
