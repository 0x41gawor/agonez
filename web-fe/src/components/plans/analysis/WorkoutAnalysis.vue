<script setup lang="ts">
import { computed, ref } from 'vue'

import type {
  AnalysisTimelineDay,
  MuscleAnalysisSummary,
  RecoveryState,
} from '@/api/plan-analysis-types'
import type { MuscleListItem } from '@/api/types'
import {
  formatHours,
  jointLabel,
  muscleLabel,
  type AnalysisPhase,
} from '@/features/plans/analysis'
import { formatNumber } from '@/utils/format'
import MuscleRecoveryMap from './MuscleRecoveryMap.vue'

const phase = defineModel<AnalysisPhase>('phase', { required: true })
const selectedMuscleSlug = defineModel<string | null>('selectedMuscleSlug', {
  default: null,
})
const props = defineProps<{
  day: AnalysisTimelineDay
  muscles: MuscleListItem[]
  summaries: MuscleAnalysisSummary[]
}>()

const showAllMuscles = ref(false)
const showAllJoints = ref(false)
const jointStates = computed<RecoveryState[]>(() =>
  phase.value === 'BEFORE'
    ? props.day.joint_recovery_before
    : props.day.joint_recovery_after,
)
const rankedJointStates = computed(() =>
  [...jointStates.value].sort((a, b) => b.hours_to_fresh - a.hours_to_fresh),
)
const muscleStimulus = computed(() => {
  const items = [...(props.day.workout?.stimulus.muscles ?? [])].sort(
    (a, b) => b.etu_absolute - a.etu_absolute,
  )
  return showAllMuscles.value ? items : items.slice(0, 8)
})
const jointStimulus = computed(() => {
  const items = [...(props.day.workout?.stimulus.joints ?? [])].sort(
    (a, b) => b.jru - a.jru,
  )
  return showAllJoints.value ? items : items.slice(0, 6)
})
</script>

<template>
  <section class="analysis-section selected-workout-section">
    <header class="analysis-section-heading selected-workout-heading">
      <div>
        <span class="section-label">Selected day analysis</span>
        <h2>{{ day.workout?.name || day.day_name }}</h2>
        <p>
          {{ day.workout ? 'Inspect entry state and the workload applied at this boundary.' : 'Rest boundary · no workout stimulus is added.' }}
        </p>
      </div>
      <div class="phase-switch" aria-label="Recovery snapshot state">
        <button type="button" :class="{ active: phase === 'BEFORE' }" @click="phase = 'BEFORE'">
          Right before
        </button>
        <button type="button" :class="{ active: phase === 'AFTER' }" @click="phase = 'AFTER'">
          Right after
        </button>
      </div>
    </header>

    <div class="selected-workout-layout">
      <MuscleRecoveryMap
        v-model:selected-slug="selectedMuscleSlug"
        :day="day"
        :phase="phase"
        :muscles="muscles"
        :summaries="summaries"
      />
    </div>

    <div class="workout-analysis-data">
      <section class="analysis-data-card panel">
        <header>
          <div><span class="section-label">Joint-load recovery</span><strong>{{ phase === 'BEFORE' ? 'Entry readiness' : 'Post-workout state' }}</strong></div>
          <span class="mono">JRU → hours_to_fresh</span>
        </header>
        <div class="compact-metric-list">
          <div v-for="item in rankedJointStates" :key="item.slug">
            <span>{{ jointLabel(item.slug) }}</span>
            <strong>{{ formatHours(item.hours_to_fresh) }}</strong>
          </div>
        </div>
        <p class="analysis-footnote">Modeled joint-load readiness cost—not literal biological healing.</p>
      </section>

      <section v-if="day.workout" class="analysis-data-card panel">
        <header>
          <div><span class="section-label">Workout stimulus</span><strong>{{ formatNumber(day.workout.stimulus.total_etu_scalar, 1) }} total ETU</strong></div>
          <span class="mono">returned workload</span>
        </header>
        <div class="stimulus-columns">
          <div>
            <h3>Muscles</h3>
            <button
              v-for="item in muscleStimulus"
              :key="item.slug"
              class="stimulus-row"
              type="button"
              @click="selectedMuscleSlug = item.slug"
            >
              <span>{{ muscleLabel(item.slug, muscles) }}</span>
              <strong>{{ formatNumber(item.etu_absolute, 1) }} <small>ETU</small></strong>
              <em>{{ formatNumber(item.mru, 1) }} MRU</em>
            </button>
            <button
              v-if="day.workout.stimulus.muscles.length > 8"
              class="text-action"
              type="button"
              @click="showAllMuscles = !showAllMuscles"
            >
              {{ showAllMuscles ? 'Show strongest only' : `View all ${day.workout.stimulus.muscles.length}` }}
            </button>
          </div>
          <div>
            <h3>Joints</h3>
            <div v-for="item in jointStimulus" :key="item.slug" class="stimulus-row static">
              <span>{{ jointLabel(item.slug) }}</span>
              <strong>{{ formatNumber(item.joint_load_exposure, 2) }} <small>load</small></strong>
              <em>{{ formatNumber(item.jru, 2) }} JRU</em>
            </div>
            <button
              v-if="day.workout.stimulus.joints.length > 6"
              class="text-action"
              type="button"
              @click="showAllJoints = !showAllJoints"
            >
              {{ showAllJoints ? 'Show strongest only' : `View all ${day.workout.stimulus.joints.length}` }}
            </button>
          </div>
        </div>
      </section>
    </div>
  </section>
</template>
