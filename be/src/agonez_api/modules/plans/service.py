from typing import Any, cast

from agonez_api.modules.plans.analysis.schemas import PlanAIImportDocument
from agonez_api.modules.plans.images import checksum, image_url, validate_image
from agonez_api.modules.plans.repository import DraftRows, PlanRepository, Row
from agonez_api.modules.plans.schemas import (
    DayArtifact,
    ExerciseSlotArtifact,
    ExerciseVariantArtifact,
    PlanCreate,
    PlanDetail,
    PlanDraftArtifact,
    PlanDraftUpdate,
    PlanDuplicateRequest,
    PlanImageWritten,
    PlanListResponse,
    PlanSummary,
    ProgressionModelCatalogItem,
    ProgressionModelCatalogResponse,
    RevisionSummary,
    SetInfraArtifact,
    WorkoutUnitArtifact,
)


class PlanService:
    def __init__(self, repository: PlanRepository) -> None:
        self._repository = repository

    async def create_plan(self, payload: PlanCreate) -> PlanDraftArtifact:
        return self.assemble_draft(await self._repository.create_plan(payload))

    async def import_plan(self, payload: PlanAIImportDocument) -> PlanDraftArtifact:
        return self.assemble_draft(await self._repository.import_plan(payload))

    async def duplicate_plan(
        self,
        plan_id: int,
        payload: PlanDuplicateRequest | None = None,
    ) -> PlanDraftArtifact:
        request = payload or PlanDuplicateRequest()
        return self.assemble_draft(
            await self._repository.duplicate_plan(
                plan_id,
                name=request.name,
                source_revision_id=request.source_revision_id,
            )
        )

    async def list_plans(self) -> PlanListResponse:
        rows = await self._repository.list_plans()
        return PlanListResponse(
            items=[PlanSummary.model_validate(self._with_image_url(row)) for row in rows]
        )

    async def list_progression_models(
        self,
        *,
        locale: str = "en",
    ) -> ProgressionModelCatalogResponse:
        rows = await self._repository.list_progression_models(locale=locale)
        items = [ProgressionModelCatalogItem.model_validate(row) for row in rows]
        return ProgressionModelCatalogResponse(items=items, total=len(items))

    async def get_plan(self, plan_id: int) -> PlanDetail:
        plan, revisions = await self._repository.get_plan(plan_id)
        return PlanDetail(
            **self._with_image_url(plan),
            revisions=[RevisionSummary.model_validate(row) for row in revisions],
        )

    async def get_plan_image(self, plan_id: int) -> Row:
        return await self._repository.get_plan_image(plan_id)

    async def save_plan_image(
        self,
        plan_id: int,
        *,
        content_type: str | None,
        data: bytes,
    ) -> PlanImageWritten:
        confirmed = validate_image(content_type, data)
        digest = checksum(data)
        written = await self._repository.save_plan_image(
            plan_id,
            content_type=confirmed,
            data=data,
            checksum=digest,
        )
        url = image_url(plan_id, digest)
        assert url is not None  # a freshly written image always has a checksum
        return PlanImageWritten(
            plan_id=plan_id,
            image_url=url,
            content_type=cast(str, written["content_type"]),
            byte_size=cast(int, written["byte_size"]),
            updated_at=written["updated_at"],
        )

    async def delete_plan_image(self, plan_id: int) -> None:
        await self._repository.delete_plan_image(plan_id)

    @staticmethod
    def _with_image_url(row: Row) -> Row:
        """Replace the stored checksum with the public URL clients should request."""
        plan = {key: value for key, value in row.items() if key != "image_checksum"}
        plan["image_url"] = image_url(
            cast(int, row["id"]),
            cast("str | None", row.get("image_checksum")),
        )
        return plan

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
                    reps={
                        "min": item["rep_min"],
                        "max": item["rep_max"],
                        "semantics": item.get("rep_range_semantics", "undefined"),
                    },
                    rir=item["rir"],
                    role=item.get("role", "working"),
                    load_spec=item.get("load_spec", {"kind": "absolute"}),
                    min_volume_level=item["min_volume_level"],
                    loading_mode=item.get("loading_mode"),
                    loading_cycle=item.get("loading_cycle"),
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
                    progression_model_slug=variant.get("progression_model_slug"),
                    progression_id=variant["progression_id"],
                    load_step_kg=variant.get("load_step_kg"),
                    active_working_sets=(
                        {
                            "min": variant["active_working_set_min"],
                            "max": variant["active_working_set_max"],
                        }
                        if variant.get("active_working_set_min") is not None
                        else None
                    ),
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
                    loading_mode=slot.get("loading_mode", "moderate_load"),
                    loading_cycle=slot.get("loading_cycle"),
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
                icon=day["icon"],
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
            accent=header["accent"],
            image_url=image_url(header["id"], header["image_checksum"]),
            scope=header["scope"],
            source_plan_id=header["source_plan_id"],
            plan_run_id=header["plan_run_id"],
            days=days,
        )
