from datetime import datetime
from enum import Enum
from typing import Any

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


class APIModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class PlanRevisionStatus(str, Enum):
    DRAFT = "DRAFT"
    RELEASED = "RELEASED"
    ARCHIVED = "ARCHIVED"


class ExerciseSlotRole(str, Enum):
    PRIMARY_PROGRESSIVE = "PRIMARY_PROGRESSIVE"
    SECONDARY_PROGRESSIVE = "SECONDARY_PROGRESSIVE"
    VOLUME_ACCUMULATION = "VOLUME_ACCUMULATION"
    ACCESSORY = "ACCESSORY"


class ExerciseVariantType(str, Enum):
    DEFAULT = "DEFAULT"
    FALLBACK = "FALLBACK"


def _require_deterministic_ordinals(items: list[Any], label: str) -> None:
    ordinals = [item.ordinal for item in items]
    if ordinals != list(range(len(items))):
        raise ValueError(f"{label} ordinals must be consecutive, ordered, and start at 0")


def _require_non_blank(value: str) -> str:
    if not value.strip():
        raise ValueError("Value must not be blank")
    return value


class RepRange(APIModel):
    min: int = Field(ge=1, le=32767)
    max: int = Field(ge=1, le=32767)

    @model_validator(mode="after")
    def validate_range(self) -> "RepRange":
        if self.max < self.min:
            raise ValueError("reps.max must be greater than or equal to reps.min")
        return self


class SetInfraDraft(APIModel):
    id: int | None = Field(default=None, ge=1)
    ordinal: int = Field(ge=0)
    reps: RepRange
    rir: int = Field(ge=0, le=4)
    min_volume_level: int = Field(default=0, ge=0, le=32767)


class ExerciseVariantDraft(APIModel):
    id: int | None = Field(default=None, ge=1)
    ordinal: int = Field(ge=0)
    variant_type: ExerciseVariantType
    exercise_slug: str = Field(min_length=1, max_length=200, pattern=r"^[a-z0-9_]+$")
    sets: list[SetInfraDraft] = Field(default_factory=list)

    @model_validator(mode="after")
    def validate_set_ordinals(self) -> "ExerciseVariantDraft":
        _require_deterministic_ordinals(self.sets, "Set")
        return self


class ExerciseSlotDraft(APIModel):
    id: int | None = Field(default=None, ge=1)
    ordinal: int = Field(ge=0)
    name: str | None = Field(default=None, max_length=200)
    description: str | None = None
    goal: str | None = None
    role: ExerciseSlotRole
    volume_axis: str | None = Field(default=None, max_length=100)
    target_muscle_slugs: list[str] = Field(default_factory=list)
    variants: list[ExerciseVariantDraft] = Field(default_factory=list)

    @field_validator("target_muscle_slugs")
    @classmethod
    def validate_target_muscles(cls, value: list[str]) -> list[str]:
        if any(not slug or len(slug) > 200 for slug in value):
            raise ValueError("Target muscle slugs must contain 1 to 200 characters")
        if len(value) != len(set(value)):
            raise ValueError("Duplicate target muscle slugs are not allowed")
        return value

    @model_validator(mode="after")
    def validate_variants(self) -> "ExerciseSlotDraft":
        _require_deterministic_ordinals(self.variants, "Variant")
        default_count = sum(
            variant.variant_type == ExerciseVariantType.DEFAULT for variant in self.variants
        )
        if self.variants and default_count != 1:
            raise ValueError("A populated slot must contain exactly one DEFAULT variant")
        return self


class WorkoutUnitDraft(APIModel):
    id: int | None = Field(default=None, ge=1)
    name: str = Field(min_length=1, max_length=200)
    description: str | None = None
    warmup_notes: str | None = None
    stretch_notes: str | None = None
    exercise_slots: list[ExerciseSlotDraft] = Field(default_factory=list)

    @field_validator("name")
    @classmethod
    def validate_name(cls, value: str) -> str:
        return _require_non_blank(value)

    @model_validator(mode="after")
    def validate_slot_ordinals(self) -> "WorkoutUnitDraft":
        _require_deterministic_ordinals(self.exercise_slots, "Slot")
        return self


class DayDraft(APIModel):
    id: int | None = Field(default=None, ge=1)
    ordinal: int = Field(ge=0)
    weekday: int | None = Field(default=None, ge=1, le=7)
    name: str = Field(min_length=1, max_length=200)
    description: str | None = None
    workout_unit: WorkoutUnitDraft | None = None

    @field_validator("name")
    @classmethod
    def validate_name(cls, value: str) -> str:
        return _require_non_blank(value)


class PlanDraftUpdate(APIModel):
    id: int = Field(ge=1)
    revision_id: int = Field(ge=1)
    revision_no: int = Field(ge=1)
    lock_version: int = Field(ge=1)
    name: str = Field(min_length=1, max_length=200)
    description: str | None = None
    days: list[DayDraft] = Field(default_factory=list)

    @field_validator("name")
    @classmethod
    def validate_name(cls, value: str) -> str:
        return _require_non_blank(value)

    @model_validator(mode="after")
    def validate_day_ordinals(self) -> "PlanDraftUpdate":
        _require_deterministic_ordinals(self.days, "Day")
        return self


class SetInfraArtifact(APIModel):
    id: int
    ordinal: int
    reps: RepRange
    rir: int
    min_volume_level: int


class ExerciseVariantArtifact(APIModel):
    id: int
    ordinal: int
    variant_type: ExerciseVariantType
    exercise_slug: str
    sets: list[SetInfraArtifact]


class ExerciseSlotArtifact(APIModel):
    id: int
    ordinal: int
    name: str | None
    description: str | None
    goal: str | None
    role: ExerciseSlotRole
    volume_axis: str | None
    target_muscle_slugs: list[str]
    variants: list[ExerciseVariantArtifact]


class WorkoutUnitArtifact(APIModel):
    id: int
    name: str
    description: str | None
    warmup_notes: str | None
    stretch_notes: str | None
    exercise_slots: list[ExerciseSlotArtifact]


class DayArtifact(APIModel):
    id: int
    ordinal: int
    weekday: int | None
    name: str
    description: str | None
    workout_unit: WorkoutUnitArtifact | None


class PlanDraftArtifact(APIModel):
    id: int
    revision_id: int
    revision_no: int
    lock_version: int
    name: str
    description: str | None
    days: list[DayArtifact]


class PlanCreate(APIModel):
    name: str = Field(min_length=1, max_length=200)
    description: str | None = None

    @field_validator("name")
    @classmethod
    def validate_name(cls, value: str) -> str:
        return _require_non_blank(value)


class PlanSummary(APIModel):
    id: int
    name: str
    description: str | None
    created_at: datetime
    updated_at: datetime
    draft_revision_id: int | None
    draft_lock_version: int | None


class PlanListResponse(APIModel):
    items: list[PlanSummary]


class RevisionSummary(APIModel):
    id: int
    revision_no: int
    status: PlanRevisionStatus
    lock_version: int
    based_on_revision_id: int | None
    created_at: datetime
    updated_at: datetime
    released_at: datetime | None


class PlanDetail(APIModel):
    id: int
    name: str
    description: str | None
    created_at: datetime
    updated_at: datetime
    revisions: list[RevisionSummary]
