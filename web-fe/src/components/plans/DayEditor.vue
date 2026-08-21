<script setup lang="ts">
import { computed, ref } from 'vue'

import type { ExerciseListItem, MuscleListItem } from '@/api/types'
import WorkoutUnitEditor from '@/components/plans/WorkoutUnitEditor.vue'
import {
  createWorkout,
  type EditorDay,
  type PlanValidationIssue,
} from '@/features/plans/editor'

const model = defineModel<EditorDay>({ required: true })
defineProps<{
  index: number
  count: number
  exercises: ExerciseListItem[]
  muscles: MuscleListItem[]
  path: string
  issues: PlanValidationIssue[]
}>()
defineEmits<{
  move: [direction: -1 | 1]
  remove: []
}>()

const expanded = ref(false)
const workoutEditor = ref<{ addSlot: () => void } | null>(null)
const weekdayLabel = computed(() =>
  model.value.weekday == null
    ? 'Flexible day'
    : ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][
        model.value.weekday - 1
      ],
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
          <strong>{{ model.name || `Day ${index + 1}` }}</strong>
          <small>{{ weekdayLabel }} · {{ model.workout_unit ? `${model.workout_unit.exercise_slots.length} slots` : 'Rest day' }}</small>
        </span>
        <span aria-hidden="true">{{ expanded ? '−' : '+' }}</span>
      </button>
      <div class="ordered-actions">
        <button type="button" :disabled="index === 0" title="Move day up" @click="$emit('move', -1)">↑</button>
        <button type="button" :disabled="index === count - 1" title="Move day down" @click="$emit('move', 1)">↓</button>
        <button class="danger-action" type="button" title="Remove day" @click="$emit('remove')">×</button>
      </div>
    </header>

    <div v-if="expanded" class="day-body">
      <div class="form-grid day-fields">
        <label class="field">
          <span class="field-label">Day name</span>
          <input v-model="model.name" class="text-input" maxlength="200" placeholder="Push A" />
          <span v-if="issues.some((issue) => issue.path === `${path}.name`)" class="field-error">
            {{ issues.find((issue) => issue.path === `${path}.name`)?.message }}
          </span>
        </label>
        <label class="field">
          <span class="field-label">Weekday</span>
          <select v-model="model.weekday" class="select-input">
            <option :value="null">Flexible / unassigned</option>
            <option v-for="(day, weekday) in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']" :key="day" :value="weekday + 1">
              {{ day }}
            </option>
          </select>
        </label>
        <label class="field day-description">
          <span class="field-label">Description</span>
          <input v-model="model.description" class="text-input" placeholder="Optional day focus" />
        </label>
      </div>

      <WorkoutUnitEditor
        v-if="model.workout_unit"
        ref="workoutEditor"
        v-model="model.workout_unit"
        :exercises="exercises"
        :muscles="muscles"
        :path="`${path}.workout`"
        :issues="issues"
        @remove="model.workout_unit = null"
      />
      <div v-else class="rest-day-state">
        <div>
          <span class="eyebrow">Rest day</span>
          <h3>No workout unit</h3>
          <p>This day remains part of the microcycle without containing a training session.</p>
        </div>
        <button class="button primary" type="button" @click="addWorkout">+ Add workout unit</button>
      </div>
    </div>
  </article>
</template>
