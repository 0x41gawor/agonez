<script setup lang="ts">
import { computed, nextTick, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import type { ProgressionModelCatalogItem } from '@/api/plan-types'
import type { ExerciseCatalogItem, MuscleListItem } from '@/api/types'
import DayEditor from '@/components/plans/DayEditor.vue'
import PlanGlance from '@/components/plans/glance/PlanGlance.vue'
import PlanAccentPicker from '@/components/plans/PlanAccentPicker.vue'
import PlanCoverEditor from '@/components/plans/PlanCoverEditor.vue'
import {
  createDay,
  duplicateDay,
  moveOrdered,
  removeOrdered,
  type PlanEditorState,
  type PlanValidationIssue,
  type ExerciseUnitOption,
} from '@/features/plans/editor'
import type { GlanceEditorTarget } from '@/features/plans/glance'

const model = defineModel<PlanEditorState>({ required: true })
const { t } = useI18n()
const props = withDefaults(defineProps<{
  exercises: ExerciseCatalogItem[]
  muscles: MuscleListItem[]
  progressionModels?: ProgressionModelCatalogItem[]
  issues: PlanValidationIssue[]
  planView?: 'editor' | 'glance'
}>(), {
  progressionModels: () => [],
  planView: 'editor',
})
const emit = defineEmits<{
  'update:planView': [view: 'editor' | 'glance']
  openEditor: [target: GlanceEditorTarget]
}>()
const root = ref<HTMLElement | null>(null)
const openTarget = ref<GlanceEditorTarget | null>(null)

function addDay(): void {
  model.value.days.push(createDay(model.value.days.length))
}

const exerciseUnits = computed<ExerciseUnitOption[]>(() => model.value.days.flatMap((day) =>
  (day.workout_unit?.exercise_slots ?? []).flatMap((slot) =>
    slot.variants.map((variant) => {
      const exercise = props.exercises.find((item) => item.slug === variant.exercise_slug)
      return {
        clientKey: variant.clientKey,
        progressionId: variant.progression_id,
        label: `${day.name} / ${slot.name?.trim() || t('plans.slot.untitled')} / ${exercise?.name || variant.exercise_slug || t('plans.slot.noExercise')}`,
      }
    }),
  ),
))

async function focusEditorTarget(target: GlanceEditorTarget): Promise<void> {
  openTarget.value = null
  await nextTick()
  openTarget.value = target
  await nextTick()
  await nextTick()
  const attribute = target.slotKey ? 'editorSlotKey' : 'editorDayKey'
  const key = target.slotKey ?? target.dayKey
  const candidates = root.value?.querySelectorAll<HTMLElement>(target.slotKey ? '[data-editor-slot-key]' : '[data-editor-day-key]') ?? []
  const element = Array.from(candidates).find((candidate) => candidate.dataset[attribute] === key)
  if (!element) return
  const focusTarget = element.querySelector<HTMLElement>(target.slotKey ? '.slot-summary-main' : '.day-toggle') ?? element
  const reduceMotion = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches ?? false
  element.scrollIntoView?.({ behavior: reduceMotion ? 'auto' : 'smooth', block: 'center' })
  focusTarget.focus({ preventScroll: true })
}

function findTargetSlots(target: GlanceEditorTarget) {
  return model.value.days.find((day) => day.clientKey === target.dayKey)
    ?.workout_unit?.exercise_slots
}

function renameGlanceSlot(target: GlanceEditorTarget, name: string): void {
  const slot = findTargetSlots(target)?.find((item) => item.clientKey === target.slotKey)
  if (slot) slot.name = name.trim() || null
}

function moveGlanceSlot(target: GlanceEditorTarget, direction: -1 | 1): void {
  const slots = findTargetSlots(target)
  const index = slots?.findIndex((item) => item.clientKey === target.slotKey) ?? -1
  if (slots && index >= 0) moveOrdered(slots, index, direction)
}

defineExpose({ focusEditorTarget })
</script>

<template>
  <div ref="root" class="plan-editor" :data-accent="model.accent ?? undefined">
    <section class="plan-overview panel">
      <div class="plan-overview-heading">
        <div>
          <span class="eyebrow">{{ $t('plans.editor.definition') }}</span>
          <h2>{{ $t('plans.editor.identity') }}</h2>
        </div>
        <span class="mono revision-chip">{{ $t('plans.editor.revision', { revision: model.revision_no, version: model.lock_version }) }}</span>
      </div>
      <div class="plan-identity">
        <PlanCoverEditor
          v-model="model.image_url"
          :plan-id="model.id"
          :plan-name="model.name"
        />
        <div class="field plan-accent-field">
          <span class="field-label">{{ $t('plans.editor.accent') }}</span>
          <PlanAccentPicker v-model="model.accent" />
        </div>
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

    <div class="plan-view-switch-row">
      <div>
        <span class="eyebrow">{{ $t('plans.editor.orderedMicrocycle') }}</span>
        <p>{{ $t('plans.glance.viewHelp') }}</p>
      </div>
      <div class="plan-view-switch" role="group" :aria-label="$t('plans.glance.viewLabel')">
        <button type="button" :class="{ active: planView === 'editor' }" @click="emit('update:planView', 'editor')">
          {{ $t('plans.glance.editor') }}
        </button>
        <button type="button" :class="{ active: planView === 'glance' }" @click="emit('update:planView', 'glance')">
          {{ $t('plans.glance.atAGlance') }}
        </button>
      </div>
    </div>

    <section v-show="planView === 'editor'" id="plan-days" class="days-section" tabindex="-1">
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
          :exercise-units="exerciseUnits"
          :path="`days.${day.clientKey}`"
          :issues="issues"
          :open-target="openTarget"
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
    <PlanGlance
      v-show="planView === 'glance'"
      :plan="model"
      :exercises="exercises"
      :active="planView === 'glance'"
      @open-editor="emit('openEditor', $event)"
      @rename-slot="renameGlanceSlot"
      @move-slot="moveGlanceSlot"
    />
  </div>
</template>
