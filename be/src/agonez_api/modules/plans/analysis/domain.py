from collections.abc import Mapping
from dataclasses import dataclass
from typing import Any

from agonez_api.modules.plans.schemas import ExerciseSlotRole


@dataclass(frozen=True)
class ResolutionContext:
    global_volume_level: int
    focus_area: str | None
    axis_overrides: Mapping[str, int]


@dataclass(frozen=True)
class ResolvedSet:
    id: int
    ordinal: int
    rep_min: int
    rep_max: int
    rir: int
    min_volume_level: int


@dataclass(frozen=True)
class ResolvedExercise:
    variant_id: int
    exercise_slug: str
    sets: tuple[ResolvedSet, ...]


@dataclass(frozen=True)
class ResolvedSlot:
    id: int
    ordinal: int
    name: str | None
    goal: str | None
    role: ExerciseSlotRole
    volume_axis: str | None
    effective_volume_level: int
    target_muscle_slugs: frozenset[str]
    selected_exercise: ResolvedExercise | None


@dataclass(frozen=True)
class ResolvedWorkout:
    id: int
    name: str
    slots: tuple[ResolvedSlot, ...]


@dataclass(frozen=True)
class ResolvedDay:
    id: int
    ordinal: int
    weekday: int | None
    name: str
    hour_offset: float
    timing_source: str
    workout: ResolvedWorkout | None


@dataclass(frozen=True)
class ResolvedPlan:
    plan_id: int
    revision_id: int
    revision_no: int
    lock_version: int
    resolution_context: ResolutionContext
    days: tuple[ResolvedDay, ...]


@dataclass(frozen=True)
class ExerciseEngineData:
    exercise_id: int
    exercise_slug: str
    etu_vector: Mapping[str, Any] | None
    active_tension_vector: Mapping[str, Any] | None
    recovery_modifier_vector: Mapping[str, Any] | None
    joint_load_vector: Mapping[str, Any] | None


@dataclass(frozen=True)
class MuscleCatalogData:
    slug: str
    fcsa_cm2: float | None


@dataclass(frozen=True)
class AnalysisCatalog:
    exercises: Mapping[str, ExerciseEngineData]
    muscles: Mapping[str, MuscleCatalogData]
