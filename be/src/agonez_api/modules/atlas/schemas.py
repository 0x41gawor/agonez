from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from agonez_api.modules.atlas.youtube import normalize_youtube_url

JsonObject = dict[str, Any]
Vector = dict[str, float]


class APIModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class ExerciseListItem(APIModel):
    slug: str
    name: str
    name_full: str
    body_part: str
    target_category: str
    mechanics_tier: str
    resistance_source: str
    execution_pattern: str
    load_capacity: float
    systemic_propulsive_fcsa_demand: float
    has_engine_vectors: bool
    image_url: str | None


class ExerciseFacets(APIModel):
    body_part: dict[str, int] = Field(default_factory=dict)
    target_category: dict[str, int] = Field(default_factory=dict)
    mechanics_tier: dict[str, int] = Field(default_factory=dict)
    resistance_source: dict[str, int] = Field(default_factory=dict)


class ExerciseListResponse(APIModel):
    items: list[ExerciseListItem]
    total: int
    page: int
    per_page: int
    facets: ExerciseFacets


class ExerciseEngine(APIModel):
    propulsive_fcsa_contribution_vector: Vector | None
    active_tension_exposure_vector: Vector | None
    etu_vector: Vector | None
    muscle_recovery_cost_modifier_vector: Vector | None
    joint_load_exposure_vector: Vector | None


class ExerciseDetail(APIModel):
    slug: str
    name: str
    name_full: str
    body_part: str
    target_category: str
    mechanics_tier: str
    resistance_source: str
    execution_pattern: str
    load_capacity: float
    systemic_propulsive_fcsa_demand: float
    propulsive_fcsa_contribution_vector: Vector
    technique: JsonObject
    comments: JsonObject
    video_links: list[str]
    image_url: str | None
    engine: ExerciseEngine | None


class ExerciseVideoCreate(APIModel):
    url: str = Field(min_length=1, max_length=2048)

    @field_validator("url")
    @classmethod
    def validate_youtube_url(cls, value: str) -> str:
        return normalize_youtube_url(value)


class ExerciseVideoLinks(APIModel):
    video_links: list[str]


class MuscleListItem(APIModel):
    slug: str
    name: str
    display_name: str
    body_part: str
    complex: str
    mass_g: float
    mv_cm3: float
    fiber_bias_type_i: float
    fiber_bias_type_ii: float
    pcsa_projected_fcsa_cm2: float | None
    image_url: str | None


class MuscleFacets(APIModel):
    body_part: dict[str, int] = Field(default_factory=dict)
    complex: dict[str, int] = Field(default_factory=dict)


class MuscleListResponse(APIModel):
    items: list[MuscleListItem]
    total: int
    page: int
    per_page: int
    facets: MuscleFacets


class MuscleDetail(APIModel):
    slug: str
    name: str
    display_name: str
    body_part: str
    complex: str
    mass_g: float
    mv_cm3: float
    mass_reference: str
    architecture: str
    fiber_bias_type_i: float
    fiber_bias_type_ii: float
    optimal_fiber_length_cm: float | None
    pennation_angle_deg: float | None
    pennation_cos: float | None
    pcsa: float
    pcsa_fiber_cm2: float | None
    pcsa_projected_fcsa_cm2: float | None
    smh_factor: str
    strength_curve: str
    leverage_peak: str
    bible_markdown: str
    article_links: list[str]
    video_links: list[str]
    image_url: str | None
    gallery: list[str]


class RelatedExercise(APIModel):
    slug: str
    name: str
    name_full: str
    target_category: str
    mechanics_tier: str
    relation: Literal["measured", "by_target"]
    etu_cm2: float | None
    normalized_etu: float | None


class RelatedExerciseResponse(APIModel):
    items: list[RelatedExercise]


class AtlasCounts(APIModel):
    exercises: int
    muscles: int


class AtlasMeta(APIModel):
    body_part: list[str]
    target_category: list[str]
    mechanics_tier: list[str]
    resistance_source: list[str]
    muscle_complex: list[str]
    counts: AtlasCounts
