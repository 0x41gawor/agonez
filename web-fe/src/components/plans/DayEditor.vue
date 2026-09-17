<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'

import type { ProgressionModelCatalogItem } from '@/api/plan-types'
import type { ExerciseCatalogItem, MuscleListItem } from '@/api/types'
import WorkoutUnitEditor from '@/components/plans/WorkoutUnitEditor.vue'
import {
  createWorkout,
  type EditorDay,
  type PlanValidationIssue,
} from '@/features/plans/editor'

const model = defineModel<EditorDay>({ required: true })
const { t } = useI18n()
withDefaults(defineProps<{
  index: number
  count: number
  exercises: ExerciseCatalogItem[]
  muscles: MuscleListItem[]
  progressionModels?: ProgressionModelCatalogItem[]
  path: string
  issues: PlanValidationIssue[]
}>(), {
  progressionModels: () => [],
})
defineEmits<{
  move: [direction: -1 | 1]
  duplicate: []
  remove: []
}>()

const expanded = ref(false)
const workoutEditor = ref<{ addSlot: () => void } | null>(null)
const weekdays = computed(() => Array.from({ length: 7 }, (_, index) => t(`plans.day.weekdays.${index}`)))
const weekdayLabel = computed(() =>
  model.value.weekday == null
    ? t('plans.day.flexible')
    : weekdays.value[model.value.weekday - 1],
)

function addWorkout(): void {
  model.value.workout_unit = createWorkout(model.value.name)
}

function handleShortcut(event: KeyboardEvent): void {
  if (
    !expanded.value
    || !model.value.workout_unit
    || !(event.ctrlKey || event.metaKey)
    || !event.shiftKey
    || event.altKey
    || event.key.toLowerCase() !== 'e'
  ) return

  event.preventDefault()
  workoutEditor.value?.addSlot()
}
</script>

<template>
  <article class="day-editor panel" @keydown="handleShortcut">
    <header class="day-header">
      <button class="day-toggle" type="button" :aria-expanded="expanded" @click="expanded = !expanded">
        <span class="day-number mono">D{{ String(index + 1).padStart(2, '0') }}</span>
        <span>
          <strong>{{ model.name || $t('plans.day.dayNumber', { number: index + 1 }) }}</strong>
          <small>{{ weekdayLabel }} · {{ model.workout_unit ? $t('plans.day.slots', { count: model.workout_unit.exercise_slots.length }) : $t('plans.day.rest') }}</small>
        </span>
        <span aria-hidden="true">{{ expanded ? '−' : '+' }}</span>
      </button>
      <div class="ordered-actions">
        <button type="button" :title="$t('plans.day.duplicate')" :aria-label="$t('plans.day.duplicate')" @click="$emit('duplicate')">⧉</button>
        <button type="button" :disabled="index === 0" :title="$t('plans.day.moveUp')" @click="$emit('move', -1)">↑</button>
        <button type="button" :disabled="index === count - 1" :title="$t('plans.day.moveDown')" @click="$emit('move', 1)">↓</button>
        <button class="danger-action" type="button" :title="$t('plans.day.remove')" @click="$emit('remove')">×</button>
      </div>
    </header>

    <div v-if="expanded" class="day-body">
      <div class="form-grid day-fields">
        <label class="field">
          <span class="field-label">{{ $t('plans.day.name') }}</span>
          <input v-model="model.name" class="text-input" maxlength="200" :placeholder="$t('plans.day.namePlaceholder')" />
          <span v-if="issues.some((issue) => issue.path === `${path}.name`)" class="field-error">
            {{ issues.find((issue) => issue.path === `${path}.name`)?.message }}
          </span>
        </label>
        <label class="field">
          <span class="field-label">{{ $t('plans.day.weekday') }}</span>
          <select v-model="model.weekday" class="select-input">
            <option :value="null">{{ $t('plans.day.flexibleUnassigned') }}</option>
            <option v-for="(day, weekday) in weekdays" :key="day" :value="weekday + 1">
              {{ day }}
            </option>
          </select>
        </label>
        <label class="field day-description">
          <span class="field-label">{{ $t('plans.day.description') }}</span>
          <input v-model="model.description" class="text-input" :placeholder="$t('plans.day.descriptionPlaceholder')" />
        </label>
      </div>

      <WorkoutUnitEditor
        v-if="model.workout_unit"
        ref="workoutEditor"
        v-model="model.workout_unit"
        :exercises="exercises"
        :muscles="muscles"
        :progression-models="progressionModels"
        :path="`${path}.workout`"
        :issues="issues"
        @remove="model.workout_unit = null"
      />
      <div v-else class="rest-day-state">
        <div>
          <span class="eyebrow">{{ $t('plans.day.rest') }}</span>
          <h3>{{ $t('plans.day.noWorkout') }}</h3>
          <p>{{ $t('plans.day.restHelp') }}</p>
        </div>
        <button class="button primary" type="button" @click="addWorkout">{{ $t('plans.day.addWorkout') }}</button>
      </div>
    </div>
  </article>
</template>
