<script setup lang="ts">
import { computed } from 'vue'

import type {
  AnalysisTimelineDay,
  MuscleAnalysisSummary,
  MuscleContribution,
} from '@/api/plan-analysis-types'
import type { ExerciseCatalogItem, MuscleListItem } from '@/api/types'
import type {
  EtuDisplayMode,
  EtuTimeBasis,
  MuscleStimulusPresentation,
} from '@/features/plans/analysis'
import MuscleStimulusExplorer from './MuscleStimulusExplorer.vue'

const mode = defineModel<EtuDisplayMode>('mode', { required: true })
const selectedSlug = defineModel<string | null>('selectedSlug', { default: null })
const props = defineProps<{
  summaries: MuscleAnalysisSummary[]
  etuBasis: EtuTimeBasis
  weeklyNormalizationFactor: number
  timeline: AnalysisTimelineDay[]
  contributionsBySlug: Map<string, MuscleContribution[]>
  muscles: MuscleListItem[]
  exercises: ExerciseCatalogItem[]
}>()

const items = computed<MuscleStimulusPresentation[]>(() =>
  props.summaries.map((item) => ({
    slug: item.slug,
    absoluteEtu: props.etuBasis === 'WEEKLY' ? item.weekly_etu : item.total_etu,
    normalizedEtu:
      props.etuBasis === 'WEEKLY'
        ? item.weekly_etu_per_fcsa_cm2
        : item.etu_per_fcsa_cm2,
    fcsaCm2: item.fcsa_cm2,
    intentionalEtu:
      props.etuBasis === 'WEEKLY'
        ? item.weekly_intentional_etu
        : item.intentional_etu,
    incidentalEtu:
      props.etuBasis === 'WEEKLY'
        ? item.weekly_incidental_etu
        : item.incidental_etu,
    unclassifiedEtu:
      props.etuBasis === 'WEEKLY'
        ? item.weekly_unclassified_etu
        : item.unclassified_etu,
    recoveryConverged: item.recovery_converged,
  })),
)
const sourceEtuFactor = computed(() =>
  props.etuBasis === 'WEEKLY' ? props.weeklyNormalizationFactor : 1,
)
</script>

<template>
  <section class="analysis-section muscle-summary-section">
    <header class="analysis-section-heading summary-heading">
      <div>
        <span class="section-label">{{ $t('analysis.muscleSummary.label') }}</span>
        <h2>{{ $t(etuBasis === 'WEEKLY' ? 'analysis.muscleSummary.weeklyTitle' : 'analysis.muscleSummary.cycleTitle') }}</h2>
        <p>{{ $t('analysis.muscleSummary.subtitle') }}</p>
      </div>
      <div class="summary-controls">
        <div class="metric-switch" :aria-label="$t('analysis.muscleSummary.metricAria')">
          <button type="button" :class="{ active: mode === 'ABSOLUTE' }" @click="mode = 'ABSOLUTE'">
            {{ $t('analysis.common.absoluteEtu') }}
          </button>
          <button type="button" :class="{ active: mode === 'NORMALIZED' }" @click="mode = 'NORMALIZED'">
            {{ $t('analysis.common.normalizedEtu') }}
          </button>
        </div>
      </div>
    </header>

    <MuscleStimulusExplorer
      v-model:mode="mode"
      v-model:selected-slug="selectedSlug"
      :items="items"
      :etu-basis="etuBasis"
      :source-etu-factor="sourceEtuFactor"
      :metric-unit-suffix="etuBasis === 'WEEKLY' ? '/7d' : '/cycle'"
      :scope-label="$t(etuBasis === 'WEEKLY' ? 'analysis.muscleSummary.weeklyScope' : 'analysis.muscleSummary.cycleScope')"
      :anatomy-title="$t('analysis.muscleSummary.anatomyTitle')"
      :ranking-title="$t('analysis.muscleSummary.rankingTitle')"
      :timeline="timeline"
      :contributions-by-slug="contributionsBySlug"
      :muscles="muscles"
      :exercises="exercises"
    />
  </section>
</template>
