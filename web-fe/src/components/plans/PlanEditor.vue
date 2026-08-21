<script setup lang="ts">
import type { ExerciseListItem, MuscleListItem } from '@/api/types'
import DayEditor from '@/components/plans/DayEditor.vue'
import {
  createDay,
  duplicateDay,
  moveOrdered,
  removeOrdered,
  type PlanEditorState,
  type PlanValidationIssue,
} from '@/features/plans/editor'

const model = defineModel<PlanEditorState>({ required: true })
defineProps<{
  exercises: ExerciseListItem[]
  muscles: MuscleListItem[]
  issues: PlanValidationIssue[]
}>()

function addDay(): void {
  model.value.days.push(createDay(model.value.days.length))
}
</script>

<template>
  <div class="plan-editor">
    <section class="plan-overview panel">
      <div class="plan-overview-heading">
        <div>
          <span class="eyebrow">Plan definition</span>
          <h2>Microcycle identity</h2>
        </div>
        <span class="mono revision-chip">Draft r{{ model.revision_no }} · v{{ model.lock_version }}</span>
      </div>
      <div class="form-grid plan-fields">
        <label class="field">
          <span class="field-label">Plan name</span>
          <input v-model="model.name" class="text-input plan-name-input" maxlength="200" placeholder="PPLPP" />
          <span v-if="issues.some((issue) => issue.path === 'name')" class="field-error">
            {{ issues.find((issue) => issue.path === 'name')?.message }}
          </span>
        </label>
        <label class="field plan-description">
          <span class="field-label">Description</span>
          <textarea v-model="model.description" class="text-area" rows="2" placeholder="Training intent and plan context" />
        </label>
      </div>
    </section>

    <section class="days-section">
      <header class="days-heading">
        <div>
          <span class="eyebrow">Ordered microcycle</span>
          <h2>{{ model.days.length ? `${model.days.length} training days` : 'Start the plan structure' }}</h2>
          <p>Days may contain one workout unit or remain explicit rest days.</p>
        </div>
        <button class="button primary" type="button" @click="addDay">+ Add training day</button>
      </header>

      <div v-if="model.days.length" class="day-list">
        <DayEditor
          v-for="(day, index) in model.days"
          :key="day.clientKey"
          v-model="model.days[index]!"
          :index="index"
          :count="model.days.length"
          :exercises="exercises"
          :muscles="muscles"
          :path="`days.${day.clientKey}`"
          :issues="issues"
          @duplicate="duplicateDay(model.days, index)"
          @move="moveOrdered(model.days, index, $event)"
          @remove="removeOrdered(model.days, index)"
        />
      </div>
      <div v-else class="new-plan-empty panel">
        <span class="empty-plan-mark mono">01</span>
        <h2>Your plan has no days yet</h2>
        <p>Add a training day, then decide whether it contains a workout or represents recovery.</p>
        <button class="button primary" type="button" @click="addDay">Add training day</button>
      </div>
    </section>
  </div>
</template>
