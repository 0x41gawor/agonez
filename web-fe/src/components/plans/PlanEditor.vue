<script setup lang="ts">
import type { ProgressionModelCatalogItem } from '@/api/plan-types'
import type { ExerciseCatalogItem, MuscleListItem } from '@/api/types'
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
withDefaults(defineProps<{
  exercises: ExerciseCatalogItem[]
  muscles: MuscleListItem[]
  progressionModels?: ProgressionModelCatalogItem[]
  issues: PlanValidationIssue[]
}>(), {
  progressionModels: () => [],
})

function addDay(): void {
  model.value.days.push(createDay(model.value.days.length))
}
</script>

<template>
  <div class="plan-editor">
    <section class="plan-overview panel">
      <div class="plan-overview-heading">
        <div>
          <span class="eyebrow">{{ $t('plans.editor.definition') }}</span>
          <h2>{{ $t('plans.editor.identity') }}</h2>
        </div>
        <span class="mono revision-chip">{{ $t('plans.editor.revision', { revision: model.revision_no, version: model.lock_version }) }}</span>
      </div>
      <div class="form-grid plan-fields">
        <label class="field">
          <span class="field-label">{{ $t('plans.editor.planName') }}</span>
          <input v-model="model.name" class="text-input plan-name-input" maxlength="200" placeholder="PPLPP" />
          <span v-if="issues.some((issue) => issue.path === 'name')" class="field-error">
            {{ issues.find((issue) => issue.path === 'name')?.message }}
          </span>
        </label>
        <label class="field plan-description">
          <span class="field-label">{{ $t('plans.editor.description') }}</span>
          <textarea v-model="model.description" class="text-area" rows="2" :placeholder="$t('plans.editor.descriptionPlaceholder')" />
        </label>
      </div>
    </section>

    <section id="plan-days" class="days-section" tabindex="-1">
      <header class="days-heading">
        <div>
          <span class="eyebrow">{{ $t('plans.editor.orderedMicrocycle') }}</span>
          <h2>{{ model.days.length ? $t('plans.editor.trainingDays', { count: model.days.length }) : $t('plans.editor.startStructure') }}</h2>
          <p>{{ $t('plans.editor.daysHelp') }}</p>
        </div>
        <button class="button primary" type="button" @click="addDay">{{ $t('plans.editor.addDay') }}</button>
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
          :progression-models="progressionModels"
          :path="`days.${day.clientKey}`"
          :issues="issues"
          @duplicate="duplicateDay(model.days, index)"
          @move="moveOrdered(model.days, index, $event)"
          @remove="removeOrdered(model.days, index)"
        />
      </div>
      <div v-else class="new-plan-empty panel">
        <span class="empty-plan-mark mono">01</span>
        <h2>{{ $t('plans.editor.emptyDaysTitle') }}</h2>
        <p>{{ $t('plans.editor.emptyDaysMessage') }}</p>
        <button class="button primary" type="button" @click="addDay">{{ $t('plans.editor.addTrainingDay') }}</button>
      </div>
    </section>
  </div>
</template>
