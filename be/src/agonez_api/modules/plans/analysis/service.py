from decimal import Decimal
from typing import Any, cast

from agonez_api.modules.plans.analysis.domain import (
    AnalysisCatalog,
    ExerciseEngineData,
    MuscleCatalogData,
)
from agonez_api.modules.plans.analysis.evaluator import evaluate_plan
from agonez_api.modules.plans.analysis.resolver import resolve_plan
from agonez_api.modules.plans.analysis.schemas import (
    PlanAnalysisRequest,
    PlanAnalysisResult,
)
from agonez_api.modules.plans.repository import AnalysisSourceRows, PlanRepository
from agonez_api.modules.plans.service import PlanService


class PlanAnalysisService:
    def __init__(self, repository: PlanRepository) -> None:
        self._repository = repository

    async def analyze_draft(
        self,
        plan_id: int,
        request: PlanAnalysisRequest,
    ) -> PlanAnalysisResult:
        source = await self._repository.get_analysis_source(plan_id)
        draft = PlanService.assemble_draft(source.draft)
        resolved, timing_assumptions, diagnostics = resolve_plan(
            draft,
            request.resolution_context,
        )
        return evaluate_plan(
            resolved,
            self._catalog(source),
            timing_assumptions=timing_assumptions,
            initial_diagnostics=diagnostics,
        )

    @staticmethod
    def _catalog(source: AnalysisSourceRows) -> AnalysisCatalog:
        exercises = {
            cast(str, row["exercise_slug"]): ExerciseEngineData(
                exercise_id=cast(int, row["exercise_id"]),
                exercise_slug=cast(str, row["exercise_slug"]),
                etu_vector=_mapping_or_none(row["etu_vector"]),
                active_tension_vector=_mapping_or_none(row["active_tension_exposure_vector"]),
                recovery_modifier_vector=_mapping_or_none(
                    row["muscle_recovery_cost_modifier_vector"]
                ),
                joint_load_vector=_mapping_or_none(row["joint_load_exposure_vector"]),
            )
            for row in source.exercises
        }
        muscles = {
            cast(str, row["slug"]): MuscleCatalogData(
                slug=cast(str, row["slug"]),
                fcsa_cm2=_number_or_none(row["pcsa_projected_fcsa_cm2"]),
            )
            for row in source.muscles
        }
        return AnalysisCatalog(exercises=exercises, muscles=muscles)


def _mapping_or_none(value: Any) -> dict[str, Any] | None:
    if value is None:
        return None
    if not isinstance(value, dict):
        return None
    return cast(dict[str, Any], value)


def _number_or_none(value: Any) -> float | None:
    if value is None:
        return None
    if isinstance(value, (int, float, Decimal)) and not isinstance(value, bool):
        return float(value)
    return None
