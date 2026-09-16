<script setup lang="ts">
import { ref } from 'vue'

import type { ExerciseCatalogItem, MuscleListItem } from '@/api/types'
import ExerciseSlotEditor from '@/components/plans/ExerciseSlotEditor.vue'
import {
  createSlot,
  duplicateSlot,
  moveOrdered,
  removeOrdered,
  type EditorWorkoutUnit,
  type PlanValidationIssue,
} from '@/features/plans/editor'

const model = defineModel<EditorWorkoutUnit>({ required: true })
defineProps<{
  exercises: ExerciseCatalogItem[]
  muscles: MuscleListItem[]
  path: string
  issues: PlanValidationIssue[]
}>()
defineEmits<{ remove: [] }>()

const notesOpen = ref(false)

function addSlot(): void {
  model.value.exercise_slots.push(createSlot(model.value.exercise_slots.length))
}

defineExpose({ addSlot })
</script>

<template>
  <section class="workout-editor">
    <header class="workout-header">
      <div>
        <span class="eyebrow">{{ $t('plans.workout.unit') }}</span>
        <h3>{{ model.name || $t('plans.workout.session') }}</h3>
      </div>
      <button class="button ghost danger-text" type="button" @click="$emit('remove')">
        {{ $t('plans.workout.makeRest') }}
      </button>
    </header>

    <div class="form-grid two-columns">
      <label class="field">
        <span class="field-label">{{ $t('plans.workout.name') }}</span>
        <input v-model="model.name" class="text-input" maxlength="200" />
        <span v-if="issues.some((issue) => issue.path === `${path}.name`)" class="field-error">
          {{ issues.find((issue) => issue.path === `${path}.name`)?.message }}
        </span>
      </label>
      <label class="field">
        <span class="field-label">{{ $t('plans.workout.description') }}</span>
        <input v-model="model.description" class="text-input" :placeholder="$t('plans.workout.sessionFocus')" />
      </label>
    </div>

    <button class="notes-disclosure" type="button" @click="notesOpen = !notesOpen">
      {{ notesOpen ? $t('plans.workout.hideNotes') : $t('plans.workout.showNotes') }}
      <span aria-hidden="true">{{ notesOpen ? '↑' : '↓' }}</span>
    </button>
    <div v-if="notesOpen" class="form-grid two-columns workout-notes">
      <label class="field">
        <span class="field-label">{{ $t('plans.workout.warmup') }}</span>
        <textarea v-model="model.warmup_notes" class="text-area" rows="3" :placeholder="$t('plans.workout.textOnly')" />
      </label>
      <label class="field">
        <span class="field-label">{{ $t('plans.workout.stretch') }}</span>
        <textarea v-model="model.stretch_notes" class="text-area" rows="3" :placeholder="$t('plans.workout.textOnly')" />
      </label>
    </div>

    <div class="slot-list-heading">
      <div>
        <span class="eyebrow">{{ $t('plans.workout.slotsLabel') }}</span>
        <h3>{{ model.exercise_slots.length ? $t('plans.workout.plannedRoles', { count: model.exercise_slots.length }) : $t('plans.workout.build') }}</h3>
      </div>
      <button class="button primary" type="button" :title="$t('plans.workout.addSlotTitle')" aria-keyshortcuts="Control+Shift+E Meta+Shift+E" @click="addSlot">{{ $t('plans.workout.addSlot') }}</button>
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
        @duplicate="duplicateSlot(model.exercise_slots, index)"
        @remove="removeOrdered(model.exercise_slots, index)"
      />
      <div class="slot-list-footer">
        <button class="button add-slot-bottom" type="button" :title="$t('plans.workout.addSlotTitle')" aria-keyshortcuts="Control+Shift+E Meta+Shift+E" @click="addSlot">
          <span>{{ $t('plans.workout.addSlot') }}</span>
          <span class="slot-shortcut mono" aria-hidden="true">Ctrl ⇧ E</span>
        </button>
      </div>
    </div>
    <div v-else class="workout-empty">
      <p>{{ $t('plans.workout.noSlots') }}</p>
      <button class="button" type="button" @click="addSlot">{{ $t('plans.workout.addFirstSlot') }}</button>
    </div>
  </section>
</template>
