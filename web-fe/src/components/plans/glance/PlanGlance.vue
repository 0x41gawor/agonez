<script setup lang="ts">
import {
  computed,
  nextTick,
  onBeforeUnmount,
  onMounted,
  ref,
  watch,
  type ComponentPublicInstance,
  type CSSProperties,
} from 'vue'
import { useI18n } from 'vue-i18n'

import type { ExerciseCatalogItem } from '@/api/types'
import DayIconMark from '@/components/plans/DayIconMark.vue'
import {
  buildGlanceModel,
  buildLegend,
  resolveClassification,
  type GlanceClassification,
  type GlanceEditorTarget,
  type GlanceLens,
  type GlanceSlot,
} from '@/features/plans/glance'
import type { PlanEditorState } from '@/features/plans/editor'

const props = defineProps<{
  plan: PlanEditorState
  exercises: ExerciseCatalogItem[]
  active: boolean
}>()
const emit = defineEmits<{
  openEditor: [target: GlanceEditorTarget]
  renameSlot: [target: GlanceEditorTarget, name: string]
  moveSlot: [target: GlanceEditorTarget, direction: -1 | 1]
}>()
const { t } = useI18n()

type GlanceMode = 'days' | 'matrix'

const mode = ref<GlanceMode>('days')
const lens = ref<GlanceLens>('targetCategory')
const showReps = ref(false)
const rowOrder = ref<'alphabetical' | 'frequency'>('alphabetical')
const tracedSlotName = ref<string | null>(null)
const selectedCategoryKeys = ref<string[]>([])
const editingSlotKey = ref<string | null>(null)
const editingSlotName = ref('')
const renameInput = ref<HTMLInputElement | null>(null)

const model = computed(() => buildGlanceModel(props.plan, props.exercises))
const legend = computed(() => buildLegend(model.value, lens.value))
const matrixRows = computed(() => {
  const rows = [...model.value.groups]
  const alphabetical = (left: { name: string }, right: { name: string }) =>
    left.name.localeCompare(right.name, undefined, { numeric: true, sensitivity: 'base' })
  rows.sort(rowOrder.value === 'frequency'
    ? (left, right) => right.occurrences.length - left.occurrences.length || alphabetical(left, right)
    : alphabetical)
  return rows
})
const selectedGroup = computed(() => {
  return tracedSlotName.value
    ? model.value.groups.find((group) => group.name === tracedSlotName.value) ?? null
    : null
})
const selectedCategories = computed(() => legend.value.filter((item) => selectedCategoryKeys.value.includes(item.key)))
const selectedCategorySummary = computed(() => ({
  labels: selectedCategories.value.map((item) => item.label).join(' + '),
  slots: selectedCategories.value.reduce((total, item) => total + item.slots, 0),
  sets: selectedCategories.value.reduce((total, item) => total + item.sets, 0),
}))
const maxSlotCount = computed(() => Math.max(1, ...model.value.days.map((day) => day.slots.length)))
const boardStyle = computed(() => ({
  '--glance-max-slots': maxSlotCount.value,
  '--glance-slot-row-height': showReps.value ? '58px' : '47px',
}) as CSSProperties)
const matrixStyle = computed(() => ({
  '--glance-matrix-rows': Math.max(1, model.value.groups.length),
}) as CSSProperties)

function setRenameInput(element: Element | ComponentPublicInstance | null): void {
  renameInput.value = element instanceof HTMLInputElement ? element : null
}

function startRenaming(slot: GlanceSlot): void {
  editingSlotKey.value = slot.key
  editingSlotName.value = slot.name === 'Untitled slot' ? '' : slot.name
  void nextTick(() => {
    renameInput.value?.focus()
    renameInput.value?.select()
  })
}

function commitRename(slot: GlanceSlot): void {
  if (editingSlotKey.value !== slot.key) return
  emit('renameSlot', slot.target, editingSlotName.value)
  editingSlotKey.value = null
}

function cancelRename(): void {
  editingSlotKey.value = null
  editingSlotName.value = ''
}

function classification(slot: GlanceSlot): GlanceClassification {
  return resolveClassification(lens.value, slot.classes[lens.value])
}

function classificationStyle(slot: GlanceSlot): CSSProperties {
  const item = classification(slot)
  return {
    '--glance-color-dark': item.dark,
    '--glance-color-light': item.light,
  } as CSSProperties
}

function categoryStyle(item: GlanceClassification): CSSProperties {
  return {
    '--glance-color-dark': item.dark,
    '--glance-color-light': item.light,
  } as CSSProperties
}

function weekdayName(value: number | null): string | null {
  if (value == null) return null
  return t(`plans.day.weekdays.${value - 1}`)
}

function weekdayShort(value: number | null): string | null {
  return weekdayName(value)?.slice(0, 3).toLocaleUpperCase() ?? null
}

function dayLabel(index: number, weekday: number | null): string {
  return weekday == null ? t('plans.glance.dayNumber', { number: index + 1 }) : `D${index + 1} · ${weekdayShort(weekday)}`
}

function traceSlot(name: string): void {
  tracedSlotName.value = tracedSlotName.value === name ? null : name
  selectedCategoryKeys.value = []
}

function toggleCategory(key: string): void {
  tracedSlotName.value = null
  selectedCategoryKeys.value = selectedCategoryKeys.value.includes(key)
    ? selectedCategoryKeys.value.filter((item) => item !== key)
    : [...selectedCategoryKeys.value, key]
}

function slotState(slot: GlanceSlot): { selected: boolean; dimmed: boolean; unclassified: boolean } {
  const category = classification(slot)
  const hasSelection = tracedSlotName.value != null || selectedCategoryKeys.value.length > 0
  const selected = tracedSlotName.value != null
    ? tracedSlotName.value === slot.name
    : selectedCategoryKeys.value.includes(category.key)
  return {
    selected,
    dimmed: hasSelection && !selected,
    unclassified: Boolean(category.unclassified),
  }
}

function tooltip(slot: GlanceSlot, dayName: string): string {
  const body = resolveClassification('bodyPart', slot.classes.bodyPart).label
  const target = resolveClassification('targetCategory', slot.classes.targetCategory).label
  const mechanics = resolveClassification('mechanicsTier', slot.classes.mechanicsTier).label
  const fallbackCount = Math.max(0, slot.variantCount - 1)
  const sets = slot.reps.perSet.length ? slot.reps.perSet.join(' · ') : t('plans.glance.noSets')
  return [
    `${slot.name} · #${slot.position} · ${dayName}`,
    `${slot.exerciseName}${fallbackCount ? ` (+${fallbackCount} ${t('plans.glance.fallbacks')})` : ''}`,
    `${body} · ${target} · ${mechanics}`,
    sets,
  ].join('\n')
}

function clearSelection(event?: KeyboardEvent): void {
  if (event && (!props.active || event.key !== 'Escape')) return
  tracedSlotName.value = null
  selectedCategoryKeys.value = []
  cancelRename()
}

watch(lens, () => {
  selectedCategoryKeys.value = []
})
watch(model, (next) => {
  if (tracedSlotName.value && !next.groups.some((group) => group.name === tracedSlotName.value)) {
    tracedSlotName.value = null
  }
  const presentCategories = new Set(legend.value.map((item) => item.key))
  selectedCategoryKeys.value = selectedCategoryKeys.value.filter((key) => presentCategories.has(key))
})
onMounted(() => window.addEventListener('keydown', clearSelection))
onBeforeUnmount(() => window.removeEventListener('keydown', clearSelection))
</script>

<template>
  <section class="plan-glance" aria-labelledby="plan-glance-title">
    <header class="glance-heading">
      <div>
        <span class="eyebrow">{{ $t('plans.glance.eyebrow') }}</span>
        <h2 id="plan-glance-title">{{ $t('plans.glance.title') }}</h2>
        <p>
          {{ $t('plans.glance.summary', {
            days: model.totals.days,
            workouts: model.totals.workouts,
            rest: model.totals.rest,
            slots: model.totals.slots,
            sets: model.totals.workingSets,
          }) }}
        </p>
      </div>
      <span class="glance-readonly mono">{{ $t('plans.glance.structuralEditing') }}</span>
    </header>

    <div class="glance-toolbar" :aria-label="$t('plans.glance.controls')">
      <div class="glance-control-group">
        <span class="field-label">{{ $t('plans.glance.layout') }}</span>
        <div class="glance-segmented">
          <button type="button" :class="{ active: mode === 'days' }" @click="mode = 'days'">{{ $t('plans.glance.days') }}</button>
          <button type="button" :class="{ active: mode === 'matrix' }" @click="mode = 'matrix'">{{ $t('plans.glance.recurrence') }}</button>
        </div>
      </div>
      <div class="glance-control-group">
        <span class="field-label">{{ $t('plans.glance.classification') }}</span>
        <div class="glance-segmented">
          <button type="button" :class="{ active: lens === 'bodyPart' }" @click="lens = 'bodyPart'">{{ $t('plans.glance.bodyPart') }}</button>
          <button type="button" :class="{ active: lens === 'targetCategory' }" @click="lens = 'targetCategory'">{{ $t('plans.glance.targetCategory') }}</button>
          <button type="button" :class="{ active: lens === 'mechanicsTier' }" @click="lens = 'mechanicsTier'">{{ $t('plans.glance.mechanicsTier') }}</button>
        </div>
      </div>
      <label class="glance-reps-toggle">
        <input v-model="showReps" type="checkbox" />
        <span>{{ $t('plans.glance.showReps') }}</span>
      </label>
      <div v-if="mode === 'matrix'" class="glance-control-group">
        <span class="field-label">{{ $t('plans.glance.rowOrder') }}</span>
        <div class="glance-segmented">
          <button type="button" :class="{ active: rowOrder === 'alphabetical' }" @click="rowOrder = 'alphabetical'">{{ $t('plans.glance.alphabetical') }}</button>
          <button type="button" :class="{ active: rowOrder === 'frequency' }" @click="rowOrder = 'frequency'">{{ $t('plans.glance.frequency') }}</button>
        </div>
      </div>
    </div>

    <div class="glance-legend" :aria-label="$t('plans.glance.legend')">
      <button
        v-for="item in legend"
        :key="item.key"
        type="button"
        class="glance-legend-chip"
        :class="{ active: selectedCategoryKeys.includes(item.key), unclassified: item.unclassified }"
        :style="categoryStyle(item)"
        :aria-pressed="selectedCategoryKeys.includes(item.key)"
        @click="toggleCategory(item.key)"
      >
        <i aria-hidden="true" />
        <span class="mono">{{ item.code }}</span>
        <strong>{{ item.label }}</strong>
        <small>{{ item.sets }} {{ $t('plans.glance.setsShort') }}</small>
      </button>
    </div>

    <div v-if="selectedGroup || selectedCategories.length" class="glance-focus" aria-live="polite">
      <div v-if="selectedGroup">
        <span class="eyebrow">{{ $t('plans.glance.tracing') }}</span>
        <strong>{{ selectedGroup.name }}</strong>
        <span>{{ $t('plans.glance.traceSummary', {
          occurrences: selectedGroup.occurrences.length,
          days: selectedGroup.dayCount,
          sets: selectedGroup.workingSets,
          gaps: selectedGroup.gaps,
        }) }}</span>
      </div>
      <div v-else>
        <span class="eyebrow">{{ $t('plans.glance.highlighted') }}</span>
        <strong>{{ selectedCategorySummary.labels }}</strong>
        <span>{{ $t('plans.glance.categorySummary', { slots: selectedCategorySummary.slots, sets: selectedCategorySummary.sets }) }}</span>
      </div>
      <button type="button" class="glance-clear" @click="clearSelection()">{{ $t('plans.glance.clear') }} <kbd>Esc</kbd></button>
    </div>

    <div v-if="mode === 'days'" class="glance-board" :style="boardStyle" :aria-label="$t('plans.glance.daysBoard')">
      <section
        v-for="day in model.days"
        :key="day.key"
        class="glance-day"
        :class="day.kind"
        :aria-labelledby="`glance-day-${day.key}`"
      >
        <header class="glance-day-header">
          <button type="button" class="glance-day-open" @click="emit('openEditor', day.target)">
            <span class="glance-day-mark">
              <DayIconMark v-if="day.icon" :icon="day.icon" :size="18" />
              <span v-else class="mono">{{ String(day.position).padStart(2, '0') }}</span>
            </span>
            <span>
              <small class="mono">{{ dayLabel(day.index, day.weekday) }}</small>
              <strong :id="`glance-day-${day.key}`">{{ day.name }}</strong>
              <span>{{ day.workoutName || $t('plans.glance.restDay') }}</span>
            </span>
            <span aria-hidden="true">↗</span>
          </button>
          <div v-if="day.kind !== 'rest'" class="glance-day-totals mono">
            <span>{{ day.slots.length }} {{ $t('plans.glance.slotsShort') }}</span>
            <span>{{ day.workingSets }} {{ $t('plans.glance.setsShort') }}</span>
            <span v-if="day.warmupSets">+{{ day.warmupSets }}w</span>
          </div>
        </header>

        <div v-if="day.kind === 'rest'" class="glance-rest-state">
          <span>{{ $t('plans.glance.restDay') }}</span>
        </div>
        <div v-else-if="day.kind === 'empty'" class="glance-empty-state">
          <strong>{{ $t('plans.glance.emptyWorkout') }}</strong>
          <span>{{ $t('plans.glance.emptyWorkoutHelp') }}</span>
        </div>
        <div v-else class="glance-slot-list">
          <article
            v-for="slot in day.slots"
            :key="slot.key"
            class="glance-slot"
            :class="slotState(slot)"
            :style="classificationStyle(slot)"
          >
            <i class="glance-slot-strip" aria-hidden="true" />
            <form
              v-if="editingSlotKey === slot.key"
              class="glance-slot-rename"
              @submit.prevent="commitRename(slot)"
            >
              <span class="glance-slot-order mono">{{ String(slot.position).padStart(2, '0') }}</span>
              <input
                :ref="setRenameInput"
                v-model="editingSlotName"
                class="text-input"
                maxlength="200"
                :aria-label="$t('plans.glance.renameSlot', { name: slot.name })"
                @keydown.esc.prevent.stop="cancelRename"
              />
              <button type="submit" :title="$t('plans.glance.applyRename')" :aria-label="$t('plans.glance.applyRename')">✓</button>
              <button type="button" :title="$t('plans.glance.cancelRename')" :aria-label="$t('plans.glance.cancelRename')" @click="cancelRename">×</button>
            </form>
            <button
              v-else
              type="button"
              class="glance-slot-open"
              :title="tooltip(slot, day.name)"
              @click="emit('openEditor', slot.target)"
            >
              <span class="glance-slot-order mono">{{ String(slot.position).padStart(2, '0') }}</span>
              <span class="glance-slot-copy">
                <strong>{{ slot.name }}</strong>
                <small>{{ slot.exerciseName }}</small>
                <span v-if="showReps" class="glance-rep-line mono" :class="{ empty: !slot.reps.perSet.length }">
                  <template v-if="slot.reps.perSet.length">
                    <em v-if="slot.reps.warmup">{{ slot.reps.warmup }} · </em>{{ slot.reps.main || $t('plans.glance.noWorkingSets') }}
                  </template>
                  <template v-else>{{ $t('plans.glance.noSets') }}</template>
                </span>
              </span>
              <span class="glance-code mono">{{ classification(slot).code }}</span>
              <span class="glance-set-count mono">
                {{ slot.reps.workingSets || '—' }}
                <small v-if="slot.reps.warmupSets">+{{ slot.reps.warmupSets }}w</small>
              </span>
            </button>
            <div v-if="editingSlotKey !== slot.key" class="glance-slot-actions">
              <button
                type="button"
                :disabled="slot.position === 1"
                :title="$t('plans.glance.moveSlotUp')"
                :aria-label="$t('plans.glance.moveSlotUp')"
                @click="emit('moveSlot', slot.target, -1)"
              >↑</button>
              <button
                type="button"
                :disabled="slot.position === day.slots.length"
                :title="$t('plans.glance.moveSlotDown')"
                :aria-label="$t('plans.glance.moveSlotDown')"
                @click="emit('moveSlot', slot.target, 1)"
              >↓</button>
              <button
                type="button"
                :title="$t('plans.glance.renameSlot', { name: slot.name })"
                :aria-label="$t('plans.glance.renameSlot', { name: slot.name })"
                @click="startRenaming(slot)"
              >✎</button>
              <button
                type="button"
                class="glance-trace"
                :title="$t('plans.glance.traceName', { name: slot.name })"
                :aria-label="$t('plans.glance.traceName', { name: slot.name })"
                :aria-pressed="tracedSlotName === slot.name"
                @click="traceSlot(slot.name)"
              >⌁</button>
            </div>
          </article>
        </div>
      </section>
    </div>

    <div v-else class="glance-matrix-wrap" :style="matrixStyle">
      <table class="glance-matrix">
        <thead>
          <tr>
            <th scope="col">{{ $t('plans.glance.slotName') }}</th>
            <th v-for="day in model.days" :key="day.key" scope="col">
              <button type="button" @click="emit('openEditor', day.target)">
                <span class="mono">{{ dayLabel(day.index, day.weekday) }}</span>
                <strong>{{ day.name }}</strong>
              </button>
            </th>
            <th scope="col">{{ $t('plans.glance.total') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="group in matrixRows" :key="group.name" :class="{ dimmed: tracedSlotName != null && tracedSlotName !== group.name }">
            <th scope="row">
              <button type="button" :aria-pressed="tracedSlotName === group.name" @click="traceSlot(group.name)">
                <strong>{{ group.name }}</strong>
                <span>{{ group.occurrences.length }}× · {{ group.gaps }}</span>
              </button>
            </th>
            <td v-for="day in model.days" :key="day.key">
              <div class="matrix-occurrences">
                <button
                  v-for="occurrence in group.occurrences.filter((item) => item.day.key === day.key)"
                  :key="occurrence.slot.key"
                  type="button"
                  class="matrix-occurrence"
                  :class="slotState(occurrence.slot)"
                  :style="classificationStyle(occurrence.slot)"
                  :title="tooltip(occurrence.slot, day.name)"
                  @click="emit('openEditor', occurrence.slot.target)"
                >
                  <span>{{ occurrence.slot.reps.workingSets || '—' }}</span>
                  <small v-if="occurrence.slot.reps.warmupSets">+{{ occurrence.slot.reps.warmupSets }}w</small>
                </button>
              </div>
            </td>
            <td class="matrix-total mono">
              <strong>{{ group.workingSets }}</strong>
              <span>{{ group.dayCount }}d · {{ group.occurrences.length }}×</span>
            </td>
          </tr>
        </tbody>
        <tfoot>
          <tr>
            <th scope="row">{{ $t('plans.glance.workingSets') }}</th>
            <td v-for="day in model.days" :key="day.key" class="mono">{{ day.workingSets }}</td>
            <td class="mono">{{ model.totals.workingSets }}</td>
          </tr>
        </tfoot>
      </table>
    </div>
  </section>
</template>
