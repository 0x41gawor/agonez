<script setup lang="ts">
import { computed, ref, watch } from 'vue'

import type {
  AnalysisTimelineDay,
  MuscleAnalysisSummary,
  MuscleContribution,
  RecoveryState,
} from '@/api/plan-analysis-types'
import type { ExerciseCatalogItem, MuscleListItem } from '@/api/types'
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
  exercises: ExerciseCatalogItem[]
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
        <span class="section-label">{{ $t('analysis.workout.label') }}</span>
        <h2>{{ day.workout?.name || day.day_name }}</h2>
        <p>
          {{ $t(day.workout ? 'analysis.workout.workoutHelp' : 'analysis.workout.restHelp') }}
        </p>
      </div>
    </header>

    <div class="selected-day-toolbar">
      <div class="selected-day-tabs" role="tablist" :aria-label="$t('analysis.workout.modeAria')">
        <button
          type="button"
          role="tab"
          :aria-selected="activeView === 'RECOVERY'"
          :class="{ active: activeView === 'RECOVERY' }"
          @click="activeView = 'RECOVERY'"
        >
          {{ $t('analysis.workout.localRecovery') }}
        </button>
        <button
          type="button"
          role="tab"
          :aria-selected="activeView === 'STIMULUS'"
          :class="{ active: activeView === 'STIMULUS' }"
          :disabled="!day.workout"
          @click="activeView = 'STIMULUS'"
        >
          {{ $t('analysis.workout.stimulus') }}
        </button>
      </div>
      <div v-if="activeView === 'RECOVERY'" class="phase-switch" :aria-label="$t('analysis.workout.recoveryStateAria')">
        <button type="button" :class="{ active: phase === 'BEFORE' }" @click="phase = 'BEFORE'">
          {{ $t('analysis.common.rightBefore') }}
        </button>
        <button type="button" :class="{ active: phase === 'AFTER' }" @click="phase = 'AFTER'">
          {{ $t('analysis.common.rightAfter') }}
        </button>
      </div>
      <div v-else class="metric-switch" :aria-label="$t('analysis.workout.metricAria')">
        <button type="button" :class="{ active: etuMode === 'ABSOLUTE' }" @click="etuMode = 'ABSOLUTE'">
          {{ $t('analysis.common.absoluteEtu') }}
        </button>
        <button type="button" :class="{ active: etuMode === 'NORMALIZED' }" @click="etuMode = 'NORMALIZED'">
          {{ $t('analysis.common.normalizedEtu') }}
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
            <div><span class="section-label">{{ $t('analysis.workout.jointRecovery') }}</span><strong>{{ $t(phase === 'BEFORE' ? 'analysis.workout.entryReadiness' : 'analysis.workout.postWorkout') }}</strong></div>
            <span class="mono">JRU → hours_to_fresh</span>
          </header>
          <div class="compact-metric-list">
            <div v-for="item in rankedJointStates" :key="item.slug">
              <span>{{ jointLabel(item.slug) }}</span>
              <strong>{{ formatHours(item.hours_to_fresh) }}</strong>
            </div>
          </div>
          <p class="analysis-footnote">{{ $t('analysis.workout.jointFootnote') }}</p>
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
      :scope-label="$t('analysis.workout.scope')"
      :anatomy-title="$t('analysis.workout.anatomyTitle')"
      :anatomy-meta="$t('analysis.workout.totalEtu', { value: formatNumber(day.workout.stimulus.total_etu_scalar, 1) })"
      :ranking-title="$t('analysis.workout.rankingTitle')"
      :timeline="timeline"
      :contributions-by-slug="dayContributionsBySlug"
      :muscles="muscles"
      :exercises="exercises"
    />
  </section>
</template>
