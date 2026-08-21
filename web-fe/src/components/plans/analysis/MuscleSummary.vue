<script setup lang="ts">
import { computed, ref } from 'vue'

import type {
  AnalysisTimelineDay,
  MuscleAnalysisSummary,
  MuscleContribution,
} from '@/api/plan-analysis-types'
import type { ExerciseListItem, MuscleListItem } from '@/api/types'
import BodyViewer from '@/components/anatomy/BodyViewer.vue'
import {
  muscleLabel,
  type EtuDisplayMode,
  type EtuTimeBasis,
} from '@/features/plans/analysis'
import { formatNumber } from '@/utils/format'
import ProvenanceInspector from './ProvenanceInspector.vue'

const mode = defineModel<EtuDisplayMode>('mode', { required: true })
const selectedSlug = defineModel<string | null>('selectedSlug', { default: null })
const props = defineProps<{
  summaries: MuscleAnalysisSummary[]
  etuBasis: EtuTimeBasis
  weeklyNormalizationFactor: number
  timeline: AnalysisTimelineDay[]
  contributionsBySlug: Map<string, MuscleContribution[]>
  muscles: MuscleListItem[]
  exercises: ExerciseListItem[]
}>()

const hoveredSlug = ref<string | null>(null)
const ranked = computed(() =>
  [...props.summaries]
    .filter((item) => (primaryValue(item) ?? 0) > 0.0001)
    .sort((a, b) => (primaryValue(b) ?? -1) - (primaryValue(a) ?? -1)),
)
const maximumValue = computed(() =>
  Math.max(0, ...ranked.value.map((item) => primaryValue(item) ?? 0)),
)
const displayVector = computed<Record<string, number>>(() =>
  Object.fromEntries(
    ranked.value.map((item) => [
      item.slug,
      maximumValue.value > 0 ? (primaryValue(item) ?? 0) / maximumValue.value : 0,
    ]),
  ),
)
const tooltipValues = computed<Record<string, number>>(() =>
  Object.fromEntries(ranked.value.map((item) => [item.slug, primaryValue(item) ?? 0])),
)
const activeBodySlug = computed(() => hoveredSlug.value ?? selectedSlug.value)
const selectedSummary = computed(() =>
  props.summaries.find((item) => item.slug === selectedSlug.value),
)
const selectedContributions = computed(() =>
  selectedSlug.value ? props.contributionsBySlug.get(selectedSlug.value) ?? [] : [],
)
const metricUnit = computed(() => {
  const base = mode.value === 'NORMALIZED' ? 'ETU/cm²' : 'ETU'
  return props.etuBasis === 'WEEKLY' ? `${base}/7d` : `${base}/cycle`
})
const metricLabel = computed(() => {
  const base = mode.value === 'NORMALIZED' ? 'ETU / FCSA' : 'Absolute ETU'
  return props.etuBasis === 'WEEKLY' ? `${base} · 7 days` : `${base} · full cycle`
})

function primaryValue(item: MuscleAnalysisSummary): number | null {
  if (mode.value === 'ABSOLUTE') return totalEtu(item)
  return props.etuBasis === 'WEEKLY'
    ? item.weekly_etu_per_fcsa_cm2
    : item.etu_per_fcsa_cm2
}

function totalEtu(item: MuscleAnalysisSummary): number {
  return props.etuBasis === 'WEEKLY' ? item.weekly_etu : item.total_etu
}

function intentionalEtu(item: MuscleAnalysisSummary): number {
  return props.etuBasis === 'WEEKLY'
    ? item.weekly_intentional_etu
    : item.intentional_etu
}

function incidentalEtu(item: MuscleAnalysisSummary): number {
  return props.etuBasis === 'WEEKLY'
    ? item.weekly_incidental_etu
    : item.incidental_etu
}

function unclassifiedEtu(item: MuscleAnalysisSummary): number {
  return props.etuBasis === 'WEEKLY'
    ? item.weekly_unclassified_etu
    : item.unclassified_etu
}

function intentWidth(item: MuscleAnalysisSummary, value: number): string {
  const total = totalEtu(item)
  return `${total > 0 ? Math.max(0, (value / total) * 100) : 0}%`
}

function relativeWidth(item: MuscleAnalysisSummary): string {
  return `${maximumValue.value > 0 ? ((primaryValue(item) ?? 0) / maximumValue.value) * 100 : 0}%`
}

function inspectMuscle(slug: string): void {
  if (props.summaries.some((item) => item.slug === slug)) selectedSlug.value = slug
}
</script>

<template>
  <section class="analysis-section muscle-summary-section">
    <header class="analysis-section-heading summary-heading">
      <div>
        <span class="section-label">Muscle summary</span>
        <h2>{{ etuBasis === 'WEEKLY' ? 'Weekly stimulus distribution' : 'Complete microcycle stimulus' }}</h2>
        <p>
          Anatomy and ranking show what the plan targets. Recovery is analyzed separately above.
        </p>
      </div>
      <div class="summary-controls">
        <div class="metric-switch" aria-label="Stimulus metric">
          <button type="button" :class="{ active: mode === 'ABSOLUTE' }" @click="mode = 'ABSOLUTE'">
            Absolute ETU
          </button>
          <button type="button" :class="{ active: mode === 'NORMALIZED' }" @click="mode = 'NORMALIZED'">
            ETU / FCSA
          </button>
        </div>
      </div>
    </header>

    <div class="stimulus-explorer">
      <div class="stimulus-anatomy panel">
        <header>
          <div>
            <span class="section-label">Stimulus anatomy</span>
            <strong>Plan target bias</strong>
          </div>
          <span class="mono">{{ metricUnit }}</span>
        </header>
        <BodyViewer
          :selected-slug="activeBodySlug"
          :vector="displayVector"
          :tooltip-values="tooltipValues"
          :tooltip-value-label="metricLabel"
          :tooltip-value-unit="metricUnit"
          :tooltip-value-digits="2"
          mode="etu"
          @hover="hoveredSlug = $event"
          @select="inspectMuscle"
        />
        <footer>
          <div class="stimulus-heat-legend">
            <span>0</span>
            <i aria-hidden="true" />
            <span>{{ formatNumber(maximumValue, 2) }} max</span>
          </div>
          <p>Relative color reveals plan bias; hover preserves exact {{ metricUnit }} values.</p>
        </footer>
      </div>

      <aside v-if="!selectedSummary" class="stimulus-ranking panel">
        <header>
          <div>
            <span class="section-label">Muscle ranking</span>
            <strong>Strongest plan biases</strong>
          </div>
          <span class="mono">{{ ranked.length }} stimulated</span>
        </header>
        <div class="stimulus-ranking-meta">
          <span>Sorted by {{ metricLabel }}</span>
          <span>Click a muscle to explain</span>
        </div>
        <div class="stimulus-ranking-list" role="list" aria-label="Muscles ranked by plan stimulus">
          <button
            v-for="(item, index) in ranked"
            :key="item.slug"
            class="stimulus-ranking-row"
            :class="{ hovered: hoveredSlug === item.slug }"
            type="button"
            role="listitem"
            :aria-label="`Explain ${muscleLabel(item.slug, muscles)}, ${formatNumber(primaryValue(item), 2)} ${metricUnit}`"
            @mouseenter="hoveredSlug = item.slug"
            @mouseleave="hoveredSlug = null"
            @focus="hoveredSlug = item.slug"
            @blur="hoveredSlug = null"
            @click="selectedSlug = item.slug"
          >
            <span class="stimulus-rank mono">{{ String(index + 1).padStart(2, '0') }}</span>
            <span class="stimulus-muscle-name">
              <strong>{{ muscleLabel(item.slug, muscles) }}</strong>
              <small v-if="!item.recovery_converged" class="stimulus-diagnostic">Recovery diagnostic</small>
              <small v-else>{{ formatNumber(item.fcsa_cm2, 1) }} cm² projected FCSA</small>
            </span>
            <span class="stimulus-row-visual">
              <i class="stimulus-strength-track"><b :style="{ width: relativeWidth(item) }" /></i>
              <i class="intent-stack" :aria-label="`${formatNumber(intentionalEtu(item), 2)} intentional, ${formatNumber(incidentalEtu(item), 2)} incidental, ${formatNumber(unclassifiedEtu(item), 2)} unclassified ETU`">
                <span class="intentional" :style="{ width: intentWidth(item, intentionalEtu(item)) }" />
                <span class="incidental" :style="{ width: intentWidth(item, incidentalEtu(item)) }" />
                <span class="unclassified" :style="{ width: intentWidth(item, unclassifiedEtu(item)) }" />
              </i>
            </span>
            <span class="primary-analysis-metric mono">
              <strong>{{ formatNumber(primaryValue(item), 2) }}</strong>
              <small>{{ metricUnit }}</small>
            </span>
            <span class="stimulus-row-arrow" aria-hidden="true">›</span>
          </button>
        </div>
        <div class="intent-legend">
          <span><i class="intentional" />Intentional</span>
          <span><i class="incidental" />Incidental</span>
          <span><i class="unclassified" />Unclassified</span>
        </div>
      </aside>

      <ProvenanceInspector
        v-else
        auxiliary
        :muscle-slug="selectedSummary.slug"
        :muscle-summary="selectedSummary"
        :muscle-contributions="selectedContributions"
        :timeline="timeline"
        :mode="mode"
        :etu-basis="etuBasis"
        :weekly-normalization-factor="weeklyNormalizationFactor"
        :muscles="muscles"
        :exercises="exercises"
        @close="selectedSlug = null"
      />
    </div>
  </section>
</template>
