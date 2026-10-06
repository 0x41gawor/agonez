from datetime import datetime
from enum import Enum
from typing import Annotated, Any, Literal
from uuid import UUID, uuid4

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


class LoadingMode(str, Enum):
    HIGH_LOAD = "high_load"
    MODERATE_LOAD = "moderate_load"
    LOW_LOAD = "low_load"


class SetRole(str, Enum):
    RAMPUP = "rampup"
    WORKING = "working"
    WORKING_TOPSET = "working_topset"
    WORKING_BACKOFF = "working_backoff"
    WORKING_AMRAP = "working_amrap"


WORKING_SET_ROLES = frozenset(SetRole) - {SetRole.RAMPUP}


class RepRangeSemantics(str, Enum):
    GATING = "gating"
    ESTIMATE = "estimate"
    UNDEFINED = "undefined"


class RIRPrescription(str, Enum):
    RIR0 = "RIR0"
    RIR1 = "RIR1"
    RIR2 = "RIR2"
    RIR3 = "RIR3"
    RIR4 = "RIR4"
    NOT_APPLICABLE = "NOT_APPLICABLE"
    UNDEFINED = "UNDEFINED"

    @property
    def numeric_value(self) -> int | None:
        return int(self.value[-1]) if self.value.startswith("RIR") else None


class AbsoluteLoadSpec(APIModel):
    kind: Literal["absolute"] = "absolute"


class AthleteSelectedLoadSpec(APIModel):
    kind: Literal["athlete_selected"]


class RelativeToSetLoadSpec(APIModel):
    kind: Literal["relative_to_set"]
    ref_set_idx: int = Field(ge=0, le=32767)
    pct: float = Field(gt=0)


class RelativeToWorkingLoadSpec(APIModel):
    kind: Literal["relative_to_working"]
    pct: float = Field(gt=0)


class TableDerivedLoadSpec(APIModel):
    kind: Literal["table_derived"]
    ref_set_idx: int = Field(ge=0, le=32767)
    table: str = Field(min_length=1, max_length=100, pattern=r"^[a-z0-9_]+$")


class OrdinalVariantLoadSpec(APIModel):
    kind: Literal["ordinal_variant"]
    level: int = Field(ge=1, le=32767)


LoadSpec = Annotated[
    AbsoluteLoadSpec
    | AthleteSelectedLoadSpec
    | RelativeToSetLoadSpec
    | RelativeToWorkingLoadSpec
    | TableDerivedLoadSpec
    | OrdinalVariantLoadSpec,
    Field(discriminator="kind"),
]


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
    semantics: RepRangeSemantics = RepRangeSemantics.UNDEFINED

    @model_validator(mode="after")
    def validate_range(self) -> "RepRange":
        if self.max < self.min:
            raise ValueError("reps.max must be greater than or equal to reps.min")
        return self


class SetInfraDraft(APIModel):
    id: int | None = Field(default=None, ge=1)
    ordinal: int = Field(ge=0)
    reps: RepRange
    rir: RIRPrescription = RIRPrescription.RIR2
    role: SetRole = SetRole.WORKING
    load_spec: LoadSpec = Field(default_factory=AbsoluteLoadSpec)
    min_volume_level: int = Field(default=0, ge=0, le=32767)
    loading_mode: LoadingMode | None = None
    loading_cycle: list[LoadingMode] | None = Field(default=None, min_length=2, max_length=52)

    @field_validator("rir", mode="before")
    @classmethod
    def normalize_legacy_rir(cls, value: Any) -> Any:
        if isinstance(value, int) and not isinstance(value, bool) and 0 <= value <= 4:
            return f"RIR{value}"
        return value


class ActiveWorkingSets(APIModel):
    min: int = Field(ge=0, le=32767)
    max: int = Field(ge=0, le=32767)

    @model_validator(mode="after")
    def validate_range(self) -> "ActiveWorkingSets":
        if self.max < self.min:
            raise ValueError("active_working_sets.max must be at least min")
        return self


class ExerciseVariantDraft(APIModel):
    id: int | None = Field(default=None, ge=1)
    ordinal: int = Field(ge=0)
    variant_type: ExerciseVariantType
    exercise_slug: str = Field(min_length=1, max_length=200, pattern=r"^[a-z0-9_]+$")
    progression_model_slug: str | None = Field(
        default=None,
        min_length=1,
        max_length=200,
        pattern=r"^[a-z0-9_]+$",
    )
    progression_id: UUID = Field(default_factory=uuid4)
    active_working_sets: ActiveWorkingSets | None = None
    sets: list[SetInfraDraft] = Field(default_factory=list)

    @model_validator(mode="after")
    def validate_set_ordinals(self) -> "ExerciseVariantDraft":
        _require_deterministic_ordinals(self.sets, "Set")
        ordinals = {item.ordinal for item in self.sets}
        for item in self.sets:
            load_spec = item.load_spec
            if isinstance(load_spec, (RelativeToSetLoadSpec, TableDerivedLoadSpec)):
                if load_spec.ref_set_idx not in ordinals:
                    raise ValueError(
                        f"Set {item.ordinal} references missing set {load_spec.ref_set_idx}"
                    )
            if (
                isinstance(load_spec, RelativeToSetLoadSpec)
                and load_spec.ref_set_idx == item.ordinal
            ):
                raise ValueError("A set must not reference itself")
        if self.active_working_sets is not None:
            working_count = sum(item.role in WORKING_SET_ROLES for item in self.sets)
            if self.active_working_sets.max > working_count:
                raise ValueError(
                    "active_working_sets.max must not exceed prescribed working sets"
                )
        return self


class ExerciseSlotDraft(APIModel):
    id: int | None = Field(default=None, ge=1)
    ordinal: int = Field(ge=0)
    name: str | None = Field(default=None, max_length=200)
    description: str | None = None
    goal: str | None = None
    role: ExerciseSlotRole
    volume_axis: str | None = Field(default=None, max_length=100)
    loading_mode: LoadingMode = LoadingMode.MODERATE_LOAD
    loading_cycle: list[LoadingMode] | None = Field(default=None, min_length=2, max_length=52)
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
    rir: RIRPrescription
    role: SetRole = SetRole.WORKING
    load_spec: LoadSpec = Field(default_factory=AbsoluteLoadSpec)
    min_volume_level: int
    loading_mode: LoadingMode | None = None
    loading_cycle: list[LoadingMode] | None = Field(default=None, min_length=2, max_length=52)

    @field_validator("rir", mode="before")
    @classmethod
    def normalize_legacy_rir(cls, value: Any) -> Any:
        if isinstance(value, int) and not isinstance(value, bool) and 0 <= value <= 4:
            return f"RIR{value}"
        return value


class ExerciseVariantArtifact(APIModel):
    id: int
    ordinal: int
    variant_type: ExerciseVariantType
    exercise_slug: str
    progression_model_slug: str | None = None
    progression_id: UUID = Field(default_factory=uuid4)
    active_working_sets: ActiveWorkingSets | None = None
    sets: list[SetInfraArtifact]


class ExerciseSlotArtifact(APIModel):
    id: int
    ordinal: int
    name: str | None
    description: str | None
    goal: str | None
    role: ExerciseSlotRole
    volume_axis: str | None
    loading_mode: LoadingMode = LoadingMode.MODERATE_LOAD
    loading_cycle: list[LoadingMode] | None = Field(default=None, min_length=2, max_length=52)
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


class ProgressionModelCatalogItem(APIModel):
    slug: str
    display_order: int = Field(ge=1)
    name: str
    name_full: str
    when_to_use: str
    how_to_apply: str


class ProgressionModelCatalogResponse(APIModel):
    items: list[ProgressionModelCatalogItem]
    total: int


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
