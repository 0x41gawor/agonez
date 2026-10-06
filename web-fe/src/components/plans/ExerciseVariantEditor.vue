<script setup lang="ts">
import { computed } from 'vue'

import type { LoadingMode, ProgressionModelCatalogItem } from '@/api/plan-types'
import type { ExerciseCatalogItem } from '@/api/types'
import ExerciseSelector from '@/components/plans/ExerciseSelector.vue'
import ExerciseUnitMetadataEditor from '@/components/plans/ExerciseUnitMetadataEditor.vue'
import ProgressionModelControl from '@/components/plans/ProgressionModelControl.vue'
import SetPrescriptionEditor from '@/components/plans/SetPrescriptionEditor.vue'
import {
  createSet,
  duplicateSetPrescription,
  effectiveLoadingPattern,
  moveSetPrescription,
  removeSetPrescription,
  type EditorVariant,
  type ExerciseUnitOption,
  type PlanValidationIssue,
} from '@/features/plans/editor'

const model = defineModel<EditorVariant>({ required: true })
const props = withDefaults(defineProps<{
  exercises: ExerciseCatalogItem[]
  progressionModels?: ProgressionModelCatalogItem[]
  path: string
  issues: PlanValidationIssue[]
  fallbackIndex?: number
  fallbackCount?: number
  slotLoadingMode?: LoadingMode
  slotLoadingCycle?: LoadingMode[] | null
  exerciseUnits?: ExerciseUnitOption[]
}>(), {
  slotLoadingMode: 'moderate_load',
  slotLoadingCycle: null,
  progressionModels: () => [],
  exerciseUnits: () => [],
})
defineEmits<{
  remove: []
  move: [direction: -1 | 1]
  progressionOpen: []
}>()

function addSet(): void {
  model.value.sets.push(createSet(
    model.value.sets.length,
    undefined,
    effectiveLoadingPattern(props.slotLoadingMode, props.slotLoadingCycle)[0]!,
    selectedExercise.value?.recommended_rep_profile,
  ))
}

const selectedExercise = computed(() =>
  props.exercises.find((exercise) => exercise.slug === model.value.exercise_slug),
)

function duplicateSet(index: number): void {
  duplicateSetPrescription(model.value.sets, index)
}
</script>

<template>
  <section class="variant-editor" :class="model.variant_type.toLowerCase()">
    <header class="variant-header">
      <span class="variant-type" :class="model.variant_type.toLowerCase()">
        {{ model.variant_type === 'DEFAULT' ? $t('plans.variant.default') : $t('plans.variant.fallback', { number: (fallbackIndex ?? 0) + 1 }) }}
      </span>
      <div v-if="model.variant_type === 'FALLBACK'" class="ordered-actions">
        <button type="button" :disabled="fallbackIndex === 0" :title="$t('plans.variant.moveUp')" @click="$emit('move', -1)">↑</button>
        <button type="button" :disabled="fallbackIndex === (fallbackCount ?? 1) - 1" :title="$t('plans.variant.moveDown')" @click="$emit('move', 1)">↓</button>
        <button class="danger-action" type="button" :title="$t('plans.variant.remove')" @click="$emit('remove')">×</button>
      </div>
    </header>

    <ExerciseSelector
      v-model="model.exercise_slug"
      :exercises="exercises"
      :label="model.variant_type === 'DEFAULT' ? $t('plans.variant.default') : $t('plans.variant.fallbackExercise')"
    />
    <p v-if="issues.some((issue) => issue.path === path)" class="field-error">
      {{ issues.find((issue) => issue.path === path)?.message }}
    </p>

    <ProgressionModelControl
      v-model="model.progression_model_slug"
      :models="progressionModels"
      @opened="$emit('progressionOpen')"
    />

    <ExerciseUnitMetadataEditor v-model="model" :exercise-units="exerciseUnits" />

    <div class="sets-heading">
      <span class="section-label">{{ $t('plans.variant.prescription') }}</span>
      <span class="mono set-summary">
        {{ model.sets.length }} {{ $t(model.sets.length === 1 ? 'plans.slot.set' : 'plans.slot.sets') }}
      </span>
    </div>
    <div v-if="model.sets.length" class="set-list">
      <SetPrescriptionEditor
        v-for="(item, index) in model.sets"
        :key="item.clientKey"
        v-model="model.sets[index]!"
        :index="index"
        :count="model.sets.length"
        :path="`${path}.sets.${item.clientKey}`"
        :issues="issues"
        :slot-loading-mode="slotLoadingMode"
        :slot-loading-cycle="slotLoadingCycle"
        @move="moveSetPrescription(model.sets, index, $event)"
        @remove="removeSetPrescription(model.sets, index)"
        @duplicate="duplicateSet(index)"
      />
    </div>
    <button class="button ghost add-set" type="button" @click="addSet">{{ $t('plans.variant.addSet') }}</button>
  </section>
</template>
