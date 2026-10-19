<script setup lang="ts">
import { computed, watch } from 'vue'

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

const exerciseSlug = computed({
  get: () => model.value.exercise_slug,
  set: (slug: string) => {
    const previousDefault = selectedExercise.value?.default_load_step_kg ?? null
    const inheritsCatalogDefault = model.value.load_step_kg === null
      || model.value.load_step_kg === previousDefault
    model.value.exercise_slug = slug
    if (inheritsCatalogDefault) {
      model.value.load_step_kg = props.exercises.find(
        (exercise) => exercise.slug === slug,
      )?.default_load_step_kg ?? null
    }
  },
})

watch(selectedExercise, (exercise) => {
  if (model.value.load_step_kg === null && exercise) {
    model.value.load_step_kg = exercise.default_load_step_kg
  }
}, { immediate: true })

const loadStep = computed<string | number>({
  get: () => model.value.load_step_kg ?? '',
  set: (value) => {
    if (value === '') {
      model.value.load_step_kg = null
      return
    }
    const parsed = Number(value)
    model.value.load_step_kg = Number.isFinite(parsed) ? parsed : null
  },
})

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
      v-model="exerciseSlug"
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

    <label class="field variant-load-step">
      <span class="field-label">{{ $t('plans.variant.loadStep') }}</span>
      <span class="load-step-control">
        <input
          v-model="loadStep"
          class="text-input mono"
          type="number"
          inputmode="decimal"
          min="0.01"
          max="1000"
          step="0.01"
          :placeholder="$t('plans.variant.loadStepPlaceholder')"
        />
        <span class="mono">kg</span>
      </span>
      <small>{{ $t('plans.variant.loadStepHelp') }}</small>
      <span v-if="issues.some((issue) => issue.path === `${path}.loadStep`)" class="field-error">
        {{ issues.find((issue) => issue.path === `${path}.loadStep`)?.message }}
      </span>
    </label>

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
