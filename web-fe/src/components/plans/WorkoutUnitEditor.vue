<script setup lang="ts">
import { ref } from 'vue'

import type { ExerciseListItem, MuscleListItem } from '@/api/types'
import ExerciseSlotEditor from '@/components/plans/ExerciseSlotEditor.vue'
import {
  createSlot,
  moveOrdered,
  removeOrdered,
  type EditorWorkoutUnit,
  type PlanValidationIssue,
} from '@/features/plans/editor'

const model = defineModel<EditorWorkoutUnit>({ required: true })
defineProps<{
  exercises: ExerciseListItem[]
  muscles: MuscleListItem[]
  path: string
  issues: PlanValidationIssue[]
}>()
defineEmits<{ remove: [] }>()

const notesOpen = ref(false)

function addSlot(): void {
  model.value.exercise_slots.push(createSlot(model.value.exercise_slots.length))
}
</script>

<template>
  <section class="workout-editor">
    <header class="workout-header">
      <div>
        <span class="eyebrow">Workout unit</span>
        <h3>{{ model.name || 'Training session' }}</h3>
      </div>
      <button class="button ghost danger-text" type="button" @click="$emit('remove')">
        Make rest day
      </button>
    </header>

    <div class="form-grid two-columns">
      <label class="field">
        <span class="field-label">Workout name</span>
        <input v-model="model.name" class="text-input" maxlength="200" />
        <span v-if="issues.some((issue) => issue.path === `${path}.name`)" class="field-error">
          {{ issues.find((issue) => issue.path === `${path}.name`)?.message }}
        </span>
      </label>
      <label class="field">
        <span class="field-label">Description</span>
        <input v-model="model.description" class="text-input" placeholder="Optional session focus" />
      </label>
    </div>

    <button class="notes-disclosure" type="button" @click="notesOpen = !notesOpen">
      {{ notesOpen ? 'Hide preparation notes' : 'Warm-up and stretch notes' }}
      <span aria-hidden="true">{{ notesOpen ? '↑' : '↓' }}</span>
    </button>
    <div v-if="notesOpen" class="form-grid two-columns workout-notes">
      <label class="field">
        <span class="field-label">Warm-up notes</span>
        <textarea v-model="model.warmup_notes" class="text-area" rows="3" placeholder="Text only for this version" />
      </label>
      <label class="field">
        <span class="field-label">Stretch notes</span>
        <textarea v-model="model.stretch_notes" class="text-area" rows="3" placeholder="Text only for this version" />
      </label>
    </div>

    <div class="slot-list-heading">
      <div>
        <span class="eyebrow">Exercise slots</span>
        <h3>{{ model.exercise_slots.length ? `${model.exercise_slots.length} planned roles` : 'Build this workout' }}</h3>
      </div>
      <button class="button primary" type="button" @click="addSlot">+ Add exercise slot</button>
    </div>

    <div v-if="model.exercise_slots.length" class="slot-list">
      <ExerciseSlotEditor
        v-for="(slot, index) in model.exercise_slots"
        :key="slot.clientKey"
        v-model="model.exercise_slots[index]!"
        :index="index"
        :count="model.exercise_slots.length"
        :exercises="exercises"
        :muscles="muscles"
        :path="`${path.replace('.workout', '')}.slots.${slot.clientKey}`"
        :issues="issues"
        @move="moveOrdered(model.exercise_slots, index, $event)"
        @remove="removeOrdered(model.exercise_slots, index)"
      />
    </div>
    <div v-else class="workout-empty">
      <p>No exercise slots yet. Add a slot for each stable role in this workout.</p>
      <button class="button" type="button" @click="addSlot">Add first exercise slot</button>
    </div>
  </section>
</template>
