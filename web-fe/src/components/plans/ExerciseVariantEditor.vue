<script setup lang="ts">
import { computed } from 'vue'

import type { LoadingMode } from '@/api/plan-types'
import type { ExerciseCatalogItem } from '@/api/types'
import ExerciseSelector from '@/components/plans/ExerciseSelector.vue'
import SetPrescriptionEditor from '@/components/plans/SetPrescriptionEditor.vue'
import {
  createSet,
  effectiveLoadingPattern,
  moveOrdered,
  removeOrdered,
  type EditorVariant,
  type PlanValidationIssue,
} from '@/features/plans/editor'

const model = defineModel<EditorVariant>({ required: true })
const props = withDefaults(defineProps<{
  exercises: ExerciseCatalogItem[]
  path: string
  issues: PlanValidationIssue[]
  fallbackIndex?: number
  fallbackCount?: number
  slotLoadingMode?: LoadingMode
  slotLoadingCycle?: LoadingMode[] | null
}>(), {
  slotLoadingMode: 'moderate_load',
  slotLoadingCycle: null,
})
defineEmits<{
  remove: []
  move: [direction: -1 | 1]
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
  const source = model.value.sets[index]
  if (!source) return
  model.value.sets.splice(index + 1, 0, createSet(index + 1, source))
  model.value.sets.forEach((item, ordinal) => {
    item.ordinal = ordinal
  })
}
</script>

<template>
  <section class="variant-editor" :class="model.variant_type.toLowerCase()">
    <header class="variant-header">
      <span class="variant-type" :class="model.variant_type.toLowerCase()">
        {{ model.variant_type === 'DEFAULT' ? 'Default exercise' : `Fallback ${(fallbackIndex ?? 0) + 1}` }}
      </span>
      <div v-if="model.variant_type === 'FALLBACK'" class="ordered-actions">
        <button type="button" :disabled="fallbackIndex === 0" title="Move fallback up" @click="$emit('move', -1)">↑</button>
        <button type="button" :disabled="fallbackIndex === (fallbackCount ?? 1) - 1" title="Move fallback down" @click="$emit('move', 1)">↓</button>
        <button class="danger-action" type="button" title="Remove fallback" @click="$emit('remove')">×</button>
      </div>
    </header>

    <ExerciseSelector
      v-model="model.exercise_slug"
      :exercises="exercises"
      :label="model.variant_type === 'DEFAULT' ? 'Default exercise' : 'Fallback exercise'"
    />
    <p v-if="issues.some((issue) => issue.path === path)" class="field-error">
      {{ issues.find((issue) => issue.path === path)?.message }}
    </p>

    <div class="sets-heading">
      <span class="section-label">Set prescription</span>
      <span class="mono set-summary">
        {{ model.sets.length }} {{ model.sets.length === 1 ? 'set' : 'sets' }}
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
        @move="moveOrdered(model.sets, index, $event)"
        @remove="removeOrdered(model.sets, index)"
        @duplicate="duplicateSet(index)"
      />
    </div>
    <button class="button ghost add-set" type="button" @click="addSet">+ Add set</button>
  </section>
</template>
