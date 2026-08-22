<script setup lang="ts">
import { computed } from 'vue'

import type {
  AnalysisTimelineDay,
  JointContribution,
  MuscleContribution,
} from '@/api/plan-analysis-types'
import type { ExerciseListItem, MuscleListItem } from '@/api/types'
import {
  exerciseLabel,
  groupJointSources,
  groupMuscleSources,
  jointLabel,
  muscleLabel,
  weekdayLabel,
  type EtuDisplayMode,
  type EtuTimeBasis,
  type MuscleSourceGroup,
  type MuscleStimulusPresentation,
} from '@/features/plans/analysis'
import { formatNumber } from '@/utils/format'

const props = withDefaults(
  defineProps<{
    muscleSlug?: string | null
    jointSlug?: string | null
    muscleContributions?: MuscleContribution[]
    jointContributions?: JointContribution[]
    musclePresentation?: MuscleStimulusPresentation | null
    timeline?: AnalysisTimelineDay[]
    mode?: EtuDisplayMode
    etuBasis?: EtuTimeBasis
    sourceEtuFactor?: number
    metricUnitSuffix?: string
    auxiliary?: boolean
    muscles: MuscleListItem[]
    exercises: ExerciseListItem[]
  }>(),
  {
    muscleSlug: null,
    jointSlug: null,
    muscleContributions: () => [],
    jointContributions: () => [],
    musclePresentation: null,
    timeline: () => [],
    mode: 'ABSOLUTE',
    etuBasis: 'MICROCYCLE',
    sourceEtuFactor: 1,
    metricUnitSuffix: '',
    auxiliary: false,
  },
)

defineEmits<{ close: [] }>()

interface MuscleDaySources {
  dayId: number
  day: AnalysisTimelineDay | null
  rawEtu: number
  groups: MuscleSourceGroup[]
}

const jointGroups = computed(() =>
  groupJointSources(props.jointContributions).slice(0, 12),
)
const timelineById = computed(
  () => new Map(props.timeline.map((day) => [day.day_id, day])),
)
const muscleDays = computed<MuscleDaySources[]>(() => {
  const byDay = new Map<number, MuscleContribution[]>()
  for (const contribution of props.muscleContributions) {
    const items = byDay.get(contribution.day_id) ?? []
    items.push(contribution)
    byDay.set(contribution.day_id, items)
  }
  return [...byDay.entries()]
    .map(([dayId, contributions]) => ({
      dayId,
      day: timelineById.value.get(dayId) ?? null,
      rawEtu: contributions.reduce((total, item) => total + (item.etu_contribution ?? 0), 0),
      groups: groupMuscleSources(contributions).slice(0, 12),
    }))
    .sort(
      (a, b) =>
        (a.day?.day_ordinal ?? Number.MAX_SAFE_INTEGER) -
          (b.day?.day_ordinal ?? Number.MAX_SAFE_INTEGER) || a.dayId - b.dayId,
    )
})
const rawTotal = computed(() =>
  props.muscleContributions.reduce(
    (total, item) => total + (item.etu_contribution ?? 0),
    0,
  ),
)
const metricUnit = computed(() => {
  const base = props.mode === 'NORMALIZED' ? 'ETU/cm²' : 'ETU'
  if (props.metricUnitSuffix) return `${base}${props.metricUnitSuffix}`
  return props.etuBasis === 'WEEKLY' ? `${base}/7d` : `${base}/cycle`
})
const selectedMetricValue = computed(() => {
  const item = props.musclePresentation
  if (!item) return null
  return props.mode === 'NORMALIZED' ? item.normalizedEtu : item.absoluteEtu
})
const intentionalShare = computed(() => {
  const item = props.musclePresentation
  if (!item || item.absoluteEtu <= 0) return 0
  return (item.intentionalEtu / item.absoluteEtu) * 100
})

function scaledEtu(rawEtu: number): number | null {
  const timeAdjusted = rawEtu * props.sourceEtuFactor
  if (props.mode === 'ABSOLUTE') return timeAdjusted
  const fcsa = props.musclePresentation?.fcsaCm2
  return fcsa != null && fcsa > 0 ? timeAdjusted / fcsa : null
}

function sourceShare(rawEtu: number): number {
  return rawTotal.value > 0 ? (rawEtu / rawTotal.value) * 100 : 0
}

function dayCode(day: AnalysisTimelineDay | null, dayId: number): string {
  return day ? `D${String(day.day_ordinal + 1).padStart(2, '0')}` : `Day #${dayId}`
}

function roleClass(role: string): string {
  return `role-${role.toLowerCase().replaceAll('_', '-')}`
}

function tokenLabel(value: string): string {
  const label = value.toLowerCase().replaceAll('_', ' ')
  return label.charAt(0).toUpperCase() + label.slice(1)
}
</script>

<template>
  <aside
    v-if="muscleSlug"
    class="provenance-inspector panel"
    :class="{ 'stimulus-provenance': auxiliary }"
  >
    <header>
      <div>
        <span class="section-label">Contribution provenance</span>
        <strong>{{ muscleLabel(muscleSlug, muscles) }}</strong>
        <p>Where this muscle's modeled stimulus comes from.</p>
      </div>
      <div v-if="auxiliary" class="provenance-header-actions">
        <span class="mono">{{ muscleContributions.length }} set records</span>
        <button class="text-action" type="button" @click="$emit('close')">← Muscle ranking</button>
      </div>
      <span v-else class="mono">{{ muscleContributions.length }} set records</span>
    </header>
    <div v-if="musclePresentation" class="stimulus-selected-facts">
      <div>
        <span>Displayed stimulus</span>
        <strong>{{ formatNumber(selectedMetricValue, 2) }}</strong>
        <small class="mono">{{ metricUnit }}</small>
      </div>
      <div>
        <span>Projected FCSA</span>
        <strong>{{ formatNumber(musclePresentation.fcsaCm2, 1) }}</strong>
        <small class="mono">cm²</small>
      </div>
      <div>
        <span>Intentional share</span>
        <strong>{{ formatNumber(intentionalShare, 0) }}%</strong>
        <small class="mono">of muscle ETU</small>
      </div>
    </div>
    <div v-if="muscleDays.length" class="provenance-days">
      <section v-for="(dayGroup, dayIndex) in muscleDays" :key="dayGroup.dayId" class="provenance-day">
        <header>
          <span class="provenance-day-code mono">{{ dayCode(dayGroup.day, dayGroup.dayId) }}</span>
          <span>
            <strong>{{ dayGroup.day?.day_name || 'Plan day' }}</strong>
            <small>
              {{ dayGroup.day ? weekdayLabel(dayGroup.day.weekday, dayGroup.day.day_ordinal) : 'Saved contribution' }}
              <template v-if="dayGroup.day?.workout"> · {{ dayGroup.day.workout.name }}</template>
            </small>
          </span>
          <span class="provenance-day-total mono">
            {{ formatNumber(scaledEtu(dayGroup.rawEtu), 2) }} {{ metricUnit }}
          </span>
        </header>
        <div class="provenance-groups">
          <details
            v-for="group in dayGroup.groups"
            :key="group.key"
            :open="dayIndex === 0 && dayGroup.groups.length === 1"
          >
            <summary>
              <span>
                <strong>{{ exerciseLabel(group.exercise_slug, exercises) }}</strong>
                <small>
                  <i class="source-role-dot" :class="roleClass(group.slot_role)" />
                  {{ tokenLabel(group.slot_role) }} ·
                  <span :class="`intent-${group.intent_classification.toLowerCase()}`">{{ tokenLabel(group.intent_classification) }}</span>
                </small>
              </span>
              <span class="provenance-totals mono">
                {{ formatNumber(scaledEtu(group.etu), 2) }} {{ metricUnit }}
                <small>{{ formatNumber(sourceShare(group.etu), 0) }}% of total</small>
              </span>
            </summary>
            <div class="provenance-set-list">
              <div v-for="(item, index) in group.sets.slice(0, 24)" :key="`${item.set_id}:${index}`">
                <span>Set {{ index + 1 }} <small class="mono">#{{ item.set_id }}</small></span>
                <strong>{{ formatNumber(scaledEtu(item.etu_contribution ?? 0), 3) }} {{ metricUnit }}</strong>
                <em>{{ formatNumber(item.effective_reps, 1) }} effective reps</em>
              </div>
              <p v-if="group.sets.length > 24">{{ group.sets.length - 24 }} additional set records omitted from this compact view.</p>
            </div>
          </details>
        </div>
      </section>
    </div>
    <p v-else class="analysis-footnote">No set-level ETU provenance was returned for this muscle.</p>
  </aside>

  <aside v-else-if="jointSlug" class="provenance-inspector panel">
    <header>
      <div>
        <span class="section-label">Contribution provenance</span>
        <strong>{{ jointLabel(jointSlug) }}</strong>
        <p>Backend-returned sources for joint-load exposure and JRU.</p>
      </div>
      <span class="mono">{{ jointContributions?.length || 0 }} set records</span>
    </header>
    <div class="provenance-groups">
      <details v-for="group in jointGroups" :key="group.exercise_slug">
        <summary>
          <strong>{{ exerciseLabel(group.exercise_slug, exercises) }}</strong>
          <span class="provenance-totals mono">
            {{ formatNumber(group.joint_load, 3) }} load · {{ formatNumber(group.jru, 3) }} JRU
          </span>
        </summary>
        <div class="provenance-set-list">
          <div v-for="(item, index) in group.sets.slice(0, 24)" :key="`${item.set_id}:${index}`">
            <span>Set {{ index + 1 }} <small class="mono">#{{ item.set_id }}</small></span>
            <strong>{{ formatNumber(item.joint_load_exposure, 3) }} load</strong>
            <em>{{ formatNumber(item.jru_contribution, 3) }} JRU</em>
          </div>
          <p v-if="group.sets.length > 24">{{ group.sets.length - 24 }} additional set records omitted from this compact view.</p>
        </div>
      </details>
    </div>
  </aside>
</template>
