<script setup lang="ts">
import { computed, ref, watch } from 'vue'

import type {
  AnalysisTimelineDay,
  MuscleAnalysisSummary,
  MuscleContribution,
  RecoveryState,
} from '@/api/plan-analysis-types'
import type { ExerciseListItem, MuscleListItem } from '@/api/types'
import {
  formatHours,
  jointLabel,
  type AnalysisPhase,
  type EtuDisplayMode,
  type MuscleStimulusPresentation,
} from '@/features/plans/analysis'
import { formatNumber } from '@/utils/format'
import MuscleRecoveryMap from './MuscleRecoveryMap.vue'
import MuscleStimulusExplorer from './MuscleStimulusExplorer.vue'

type SelectedDayView = 'RECOVERY' | 'STIMULUS'

const phase = defineModel<AnalysisPhase>('phase', { required: true })
const etuMode = defineModel<EtuDisplayMode>('etuMode', { required: true })
const selectedMuscleSlug = defineModel<string | null>('selectedMuscleSlug', {
  default: null,
})
const props = defineProps<{
  day: AnalysisTimelineDay
  timeline: AnalysisTimelineDay[]
  contributionsBySlug: Map<string, MuscleContribution[]>
  muscles: MuscleListItem[]
  exercises: ExerciseListItem[]
  summaries: MuscleAnalysisSummary[]
}>()

const activeView = ref<SelectedDayView>('RECOVERY')
const jointStates = computed<RecoveryState[]>(() =>
  phase.value === 'BEFORE'
    ? props.day.joint_recovery_before
    : props.day.joint_recovery_after,
)
const rankedJointStates = computed(() =>
  [...jointStates.value].sort((a, b) => b.hours_to_fresh - a.hours_to_fresh),
)
const dayContributionsBySlug = computed(() => {
  const result = new Map<string, MuscleContribution[]>()
  for (const [slug, contributions] of props.contributionsBySlug) {
    const matching = contributions.filter((item) => item.day_id === props.day.day_id)
    if (matching.length) result.set(slug, matching)
  }
  return result
})
const workoutItems = computed<MuscleStimulusPresentation[]>(() =>
  (props.day.workout?.stimulus.muscles ?? []).map((stimulus) => {
    const summary = props.summaries.find((item) => item.slug === stimulus.slug)
    const contributions = dayContributionsBySlug.value.get(stimulus.slug) ?? []
    const intentEtu = (intent: MuscleContribution['intent_classification']) =>
      contributions
        .filter((item) => item.intent_classification === intent)
        .reduce((total, item) => total + (item.etu_contribution ?? 0), 0)
    const fcsa = summary?.fcsa_cm2 ?? null
    return {
      slug: stimulus.slug,
      absoluteEtu: stimulus.etu_absolute,
      normalizedEtu: fcsa != null && fcsa > 0 ? stimulus.etu_absolute / fcsa : null,
      fcsaCm2: fcsa,
      intentionalEtu: intentEtu('INTENTIONAL'),
      incidentalEtu: intentEtu('INCIDENTAL'),
      unclassifiedEtu: intentEtu('UNCLASSIFIED'),
      recoveryConverged: summary?.recovery_converged ?? true,
    }
  }),
)

watch(
  () => [props.day.day_id, activeView.value] as const,
  () => {
    if (!props.day.workout) activeView.value = 'RECOVERY'
    if (
      activeView.value === 'STIMULUS' &&
      selectedMuscleSlug.value &&
      !workoutItems.value.some((item) => item.slug === selectedMuscleSlug.value)
    ) {
      selectedMuscleSlug.value = null
    }
  },
)
</script>

<template>
  <section class="analysis-section selected-workout-section">
    <header class="analysis-section-heading selected-workout-heading">
      <div>
        <span class="section-label">Selected day analysis</span>
        <h2>{{ day.workout?.name || day.day_name }}</h2>
        <p>
          {{ day.workout ? 'Inspect recovery state or the stimulus applied at this boundary.' : 'Rest boundary · no workout stimulus is added.' }}
        </p>
      </div>
    </header>

    <div class="selected-day-toolbar">
      <div class="selected-day-tabs" role="tablist" aria-label="Selected day analysis mode">
        <button
          type="button"
          role="tab"
          :aria-selected="activeView === 'RECOVERY'"
          :class="{ active: activeView === 'RECOVERY' }"
          @click="activeView = 'RECOVERY'"
        >
          Local recovery
        </button>
        <button
          type="button"
          role="tab"
          :aria-selected="activeView === 'STIMULUS'"
          :class="{ active: activeView === 'STIMULUS' }"
          :disabled="!day.workout"
          @click="activeView = 'STIMULUS'"
        >
          Workout stimulus
        </button>
      </div>
      <div v-if="activeView === 'RECOVERY'" class="phase-switch" aria-label="Recovery snapshot state">
        <button type="button" :class="{ active: phase === 'BEFORE' }" @click="phase = 'BEFORE'">
          Right before
        </button>
        <button type="button" :class="{ active: phase === 'AFTER' }" @click="phase = 'AFTER'">
          Right after
        </button>
      </div>
      <div v-else class="metric-switch" aria-label="Workout stimulus metric">
        <button type="button" :class="{ active: etuMode === 'ABSOLUTE' }" @click="etuMode = 'ABSOLUTE'">
          Absolute ETU
        </button>
        <button type="button" :class="{ active: etuMode === 'NORMALIZED' }" @click="etuMode = 'NORMALIZED'">
          ETU / FCSA
        </button>
      </div>
    </div>

    <template v-if="activeView === 'RECOVERY'">
      <div class="selected-workout-layout">
        <MuscleRecoveryMap
          v-model:selected-slug="selectedMuscleSlug"
          :day="day"
          :phase="phase"
          :muscles="muscles"
          :summaries="summaries"
        />
      </div>

      <div class="workout-analysis-data single-card">
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
      </div>
    </template>

    <MuscleStimulusExplorer
      v-else-if="day.workout"
      v-model:mode="etuMode"
      v-model:selected-slug="selectedMuscleSlug"
      layout="anatomy-wide"
      :items="workoutItems"
      etu-basis="MICROCYCLE"
      :source-etu-factor="1"
      metric-unit-suffix="/workout"
      scope-label="selected workout"
      anatomy-title="Workout target bias"
      :anatomy-meta="`${formatNumber(day.workout.stimulus.total_etu_scalar, 1)} total ETU`"
      ranking-title="Strongest workout biases"
      :timeline="timeline"
      :contributions-by-slug="dayContributionsBySlug"
      :muscles="muscles"
      :exercises="exercises"
    />
  </section>
</template>
