from typing import Any, cast

from agonez_api.modules.plans.repository import DraftRows, PlanRepository
from agonez_api.modules.plans.schemas import (
    DayArtifact,
    ExerciseSlotArtifact,
    ExerciseVariantArtifact,
    PlanCreate,
    PlanDetail,
    PlanDraftArtifact,
    PlanDraftUpdate,
    PlanListResponse,
    PlanSummary,
    RevisionSummary,
    SetInfraArtifact,
    WorkoutUnitArtifact,
)


class PlanService:
    def __init__(self, repository: PlanRepository) -> None:
        self._repository = repository

    async def create_plan(self, payload: PlanCreate) -> PlanDraftArtifact:
        return self.assemble_draft(await self._repository.create_plan(payload))

    async def list_plans(self) -> PlanListResponse:
        rows = await self._repository.list_plans()
        return PlanListResponse(items=[PlanSummary.model_validate(row) for row in rows])

    async def get_plan(self, plan_id: int) -> PlanDetail:
        plan, revisions = await self._repository.get_plan(plan_id)
        return PlanDetail(
            **plan,
            revisions=[RevisionSummary.model_validate(row) for row in revisions],
        )

    async def delete_plan(self, plan_id: int) -> None:
        await self._repository.delete_plan(plan_id)

    async def get_draft(self, plan_id: int) -> PlanDraftArtifact:
        return self.assemble_draft(await self._repository.get_draft(plan_id))

    async def save_draft(
        self,
        plan_id: int,
        payload: PlanDraftUpdate,
    ) -> PlanDraftArtifact:
        return self.assemble_draft(await self._repository.save_draft(plan_id, payload))

    @staticmethod
    def assemble_draft(rows: DraftRows) -> PlanDraftArtifact:
        sets_by_variant: dict[int, list[SetInfraArtifact]] = {}
        for item in rows.sets:
            variant_id = cast(int, item["exercise_variant_id"])
            sets_by_variant.setdefault(variant_id, []).append(
                SetInfraArtifact(
                    id=item["id"],
                    ordinal=item["ordinal"],
                    reps={"min": item["rep_min"], "max": item["rep_max"]},
                    rir=item["rir"],
                    min_volume_level=item["min_volume_level"],
                )
            )

        variants_by_slot: dict[int, list[ExerciseVariantArtifact]] = {}
        for variant in rows.variants:
            variant_id = cast(int, variant["id"])
            slot_id = cast(int, variant["slot_id"])
            variants_by_slot.setdefault(slot_id, []).append(
                ExerciseVariantArtifact(
                    id=variant_id,
                    ordinal=variant["ordinal"],
                    variant_type=variant["variant_type"],
                    exercise_slug=variant["exercise_slug"],
                    sets=sets_by_variant.get(variant_id, []),
                )
            )

        targets_by_slot: dict[int, list[str]] = {}
        for target in rows.target_muscles:
            targets_by_slot.setdefault(cast(int, target["slot_id"]), []).append(
                cast(str, target["slug"])
            )

        slots_by_unit: dict[int, list[ExerciseSlotArtifact]] = {}
        for slot in rows.slots:
            slot_id = cast(int, slot["id"])
            unit_id = cast(int, slot["workout_unit_id"])
            slots_by_unit.setdefault(unit_id, []).append(
                ExerciseSlotArtifact(
                    id=slot_id,
                    ordinal=slot["ordinal"],
                    name=slot["name"],
                    description=slot["description"],
                    goal=slot["goal"],
                    role=slot["role"],
                    volume_axis=slot["volume_axis"],
                    target_muscle_slugs=targets_by_slot.get(slot_id, []),
                    variants=variants_by_slot.get(slot_id, []),
                )
            )

        units_by_day: dict[int, WorkoutUnitArtifact] = {}
        for unit in rows.workout_units:
            unit_id = cast(int, unit["id"])
            units_by_day[cast(int, unit["day_id"])] = WorkoutUnitArtifact(
                id=unit_id,
                name=unit["name"],
                description=unit["description"],
                warmup_notes=unit["warmup_notes"],
                stretch_notes=unit["stretch_notes"],
                exercise_slots=slots_by_unit.get(unit_id, []),
            )

        days = [
            DayArtifact(
                id=day["id"],
                ordinal=day["ordinal"],
                weekday=day["weekday"],
                name=day["name"],
                description=day["description"],
                workout_unit=units_by_day.get(cast(int, day["id"])),
            )
            for day in rows.days
        ]
        header: dict[str, Any] = rows.header
        return PlanDraftArtifact(
            id=header["id"],
            revision_id=header["revision_id"],
            revision_no=header["revision_no"],
            lock_version=header["lock_version"],
            name=header["name"],
            description=header["description"],
            days=days,
        )
