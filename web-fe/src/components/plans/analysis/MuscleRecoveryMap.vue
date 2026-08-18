<script setup lang="ts">
import { computed } from 'vue'

import type {
  AnalysisTimelineDay,
  MuscleAnalysisSummary,
  RecoveryState,
} from '@/api/plan-analysis-types'
import type { MuscleListItem } from '@/api/types'
import BodyViewer from '@/components/anatomy/BodyViewer.vue'
import {
  formatHours,
  muscleLabel,
  recoveryBandIntensity,
  type AnalysisPhase,
} from '@/features/plans/analysis'
import { formatNumber } from '@/utils/format'

const selectedSlug = defineModel<string | null>('selectedSlug', { default: null })
const props = defineProps<{
  day: AnalysisTimelineDay
  phase: AnalysisPhase
  muscles: MuscleListItem[]
  summaries: MuscleAnalysisSummary[]
}>()

const states = computed<RecoveryState[]>(() =>
  props.phase === 'BEFORE'
    ? props.day.muscle_recovery_before
    : props.day.muscle_recovery_after,
)
const realValues = computed<Record<string, number>>(() =>
  Object.fromEntries(states.value.map((item) => [item.slug, item.hours_to_fresh])),
)
const displayVector = computed<Record<string, number>>(() =>
  Object.fromEntries(
    states.value.map((item) => [item.slug, recoveryBandIntensity(item.hours_to_fresh)]),
  ),
)
const strongest = computed(() =>
  [...states.value].sort((a, b) => b.hours_to_fresh - a.hours_to_fresh).slice(0, 8),
)
const selectedState = computed(() =>
  states.value.find((item) => item.slug === selectedSlug.value),
)
const selectedSummary = computed(() =>
  props.summaries.find((item) => item.slug === selectedSlug.value),
)
const selectedStimulus = computed(() =>
  props.day.workout?.stimulus.muscles.find((item) => item.slug === selectedSlug.value),
)
</script>

<template>
  <div class="recovery-map panel">
    <header>
      <div>
        <span class="section-label">Local muscle recovery</span>
        <strong>{{ phase === 'BEFORE' ? 'Right before' : 'Right after' }} {{ day.workout?.name || day.day_name }}</strong>
      </div>
      <span class="mono">hours_to_fresh</span>
    </header>
    <BodyViewer
      :selected-slug="selectedSlug"
      :vector="displayVector"
      :tooltip-values="realValues"
      tooltip-value-label="Modeled recovery debt"
      mode="recovery"
      @select="selectedSlug = $event"
    />
    <div class="recovery-band-legend" aria-label="Recovery display bands">
      <span><i class="fresh" />0 h</span>
      <span><i class="low" />0–24</span>
      <span><i class="medium" />24–48</span>
      <span><i class="high" />48–72</span>
      <span><i class="max" />72+ h</span>
    </div>
    <p class="recovery-map-note">Color is capped at 72 h for readability. Hover and details preserve the actual backend value.</p>
  </div>

  <aside class="recovery-inspector panel">
    <header>
      <div>
        <span class="section-label">Recovery state</span>
        <strong>{{ selectedSlug ? muscleLabel(selectedSlug, muscles) : 'Strongest modeled debts' }}</strong>
      </div>
      <button v-if="selectedSlug" class="text-action" type="button" @click="selectedSlug = null">Show ranking</button>
    </header>
    <div v-if="selectedSlug && selectedState" class="selected-muscle-facts">
      <div><span>Current state</span><strong>{{ formatHours(selectedState.hours_to_fresh) }}</strong></div>
      <div><span>Workout ETU</span><strong>{{ formatNumber(selectedStimulus?.etu_absolute, 2) }}</strong></div>
      <div><span>Weekly ETU</span><strong>{{ formatNumber(selectedSummary?.total_etu, 2) }}</strong></div>
      <div><span>ETU / FCSA</span><strong>{{ formatNumber(selectedSummary?.etu_per_fcsa_cm2, 2) }}</strong></div>
      <div><span>Workout MRU</span><strong>{{ formatNumber(selectedStimulus?.mru, 2) }}</strong></div>
      <p>Modeled local performance/recovery debt—not soreness, protein synthesis, injury, or literal healing.</p>
    </div>
    <div v-else class="recovery-ranking">
      <button
        v-for="item in strongest"
        :key="item.slug"
        type="button"
        @click="selectedSlug = item.slug"
      >
        <span>{{ muscleLabel(item.slug, muscles) }}</span>
        <strong>{{ formatHours(item.hours_to_fresh) }}</strong>
      </button>
    </div>
  </aside>
</template>
