<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'

import type { AnalysisTimelineDay, MuscleContribution } from '@/api/plan-analysis-types'
import type { ExerciseCatalogItem, MuscleListItem } from '@/api/types'
import BodyViewer from '@/components/anatomy/BodyViewer.vue'
import {
  muscleLabel,
  type EtuDisplayMode,
  type EtuTimeBasis,
  type MuscleStimulusPresentation,
} from '@/features/plans/analysis'
import { formatNumber } from '@/utils/format'
import ProvenanceInspector from './ProvenanceInspector.vue'

const mode = defineModel<EtuDisplayMode>('mode', { required: true })
const selectedSlug = defineModel<string | null>('selectedSlug', { default: null })
const { t } = useI18n()
const props = withDefaults(
  defineProps<{
    items: MuscleStimulusPresentation[]
    etuBasis: EtuTimeBasis
    sourceEtuFactor: number
    metricUnitSuffix: string
    scopeLabel: string
    anatomyTitle: string
    anatomyMeta?: string | null
    rankingTitle: string
    layout?: 'balanced' | 'anatomy-wide'
    timeline: AnalysisTimelineDay[]
    contributionsBySlug: Map<string, MuscleContribution[]>
    muscles: MuscleListItem[]
    exercises: ExerciseCatalogItem[]
  }>(),
  {
    anatomyMeta: null,
    layout: 'balanced',
  },
)

const hoveredSlug = ref<string | null>(null)
const ranked = computed(() =>
  [...props.items]
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
const selectedItem = computed(() =>
  props.items.find((item) => item.slug === selectedSlug.value),
)
const selectedContributions = computed(() =>
  selectedSlug.value ? props.contributionsBySlug.get(selectedSlug.value) ?? [] : [],
)
const metricUnit = computed(() => {
  const base = mode.value === 'NORMALIZED' ? 'ETU/cm²' : 'ETU'
  return `${base}${props.metricUnitSuffix}`
})
const metricLabel = computed(() => {
  const base = t(mode.value === 'NORMALIZED' ? 'analysis.common.normalizedEtu' : 'analysis.common.absoluteEtu')
  return `${base} · ${props.scopeLabel}`
})

function primaryValue(item: MuscleStimulusPresentation): number | null {
  return mode.value === 'NORMALIZED' ? item.normalizedEtu : item.absoluteEtu
}

function intentWidth(item: MuscleStimulusPresentation, value: number): string {
  return `${item.absoluteEtu > 0 ? Math.max(0, (value / item.absoluteEtu) * 100) : 0}%`
}

function relativeWidth(item: MuscleStimulusPresentation): string {
  return `${maximumValue.value > 0 ? ((primaryValue(item) ?? 0) / maximumValue.value) * 100 : 0}%`
}

function inspectMuscle(slug: string): void {
  if (props.items.some((item) => item.slug === slug)) selectedSlug.value = slug
}
</script>

<template>
  <div class="stimulus-explorer" :class="`layout-${layout}`">
    <div class="stimulus-anatomy panel">
      <header>
        <div>
          <span class="section-label">{{ $t('analysis.stimulus.anatomy') }}</span>
          <strong>{{ anatomyTitle }}</strong>
        </div>
        <span class="mono">{{ anatomyMeta || metricUnit }}</span>
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
          <span>{{ $t('analysis.stimulus.max', { value: formatNumber(maximumValue, 2) }) }}</span>
        </div>
        <p>{{ $t('analysis.stimulus.legend', { unit: metricUnit }) }}</p>
      </footer>
    </div>

    <aside v-if="!selectedItem" class="stimulus-ranking panel">
      <header>
        <div>
          <span class="section-label">{{ $t('analysis.stimulus.ranking') }}</span>
          <strong>{{ rankingTitle }}</strong>
        </div>
        <span class="mono">{{ $t('analysis.stimulus.stimulated', { count: ranked.length }) }}</span>
      </header>
      <div class="stimulus-ranking-meta">
        <span>{{ $t('analysis.stimulus.sortedBy', { metric: metricLabel }) }}</span>
        <span>{{ $t('analysis.stimulus.clickExplain') }}</span>
      </div>
      <div class="stimulus-ranking-list" role="list" :aria-label="$t('analysis.stimulus.rankingAria')">
        <button
          v-for="(item, index) in ranked"
          :key="item.slug"
          class="stimulus-ranking-row"
          :class="{ hovered: hoveredSlug === item.slug }"
          type="button"
          role="listitem"
          :aria-label="$t('analysis.stimulus.explainAria', { name: muscleLabel(item.slug, muscles), value: formatNumber(primaryValue(item), 2), unit: metricUnit })"
          @mouseenter="hoveredSlug = item.slug"
          @mouseleave="hoveredSlug = null"
          @focus="hoveredSlug = item.slug"
          @blur="hoveredSlug = null"
          @click="selectedSlug = item.slug"
        >
          <span class="stimulus-rank mono">{{ String(index + 1).padStart(2, '0') }}</span>
          <span class="stimulus-muscle-name">
            <strong>{{ muscleLabel(item.slug, muscles) }}</strong>
            <small v-if="!item.recoveryConverged" class="stimulus-diagnostic">{{ $t('analysis.common.recoveryDiagnostic') }}</small>
            <small v-else>{{ $t('analysis.common.projectedFcsa', { value: formatNumber(item.fcsaCm2, 1) }) }}</small>
          </span>
          <span class="stimulus-row-visual">
            <i class="stimulus-strength-track"><b :style="{ width: relativeWidth(item) }" /></i>
            <i class="intent-stack" :aria-label="$t('analysis.stimulus.intentAria', { intentional: formatNumber(item.intentionalEtu, 2), incidental: formatNumber(item.incidentalEtu, 2), unclassified: formatNumber(item.unclassifiedEtu, 2) })">
              <span class="intentional" :style="{ width: intentWidth(item, item.intentionalEtu) }" />
              <span class="incidental" :style="{ width: intentWidth(item, item.incidentalEtu) }" />
              <span class="unclassified" :style="{ width: intentWidth(item, item.unclassifiedEtu) }" />
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
        <span><i class="intentional" />{{ $t('analysis.common.intentional') }}</span>
        <span><i class="incidental" />{{ $t('analysis.common.incidental') }}</span>
        <span><i class="unclassified" />{{ $t('analysis.common.unclassified') }}</span>
      </div>
    </aside>

    <ProvenanceInspector
      v-else
      auxiliary
      :muscle-slug="selectedItem.slug"
      :muscle-presentation="selectedItem"
      :muscle-contributions="selectedContributions"
      :timeline="timeline"
      :mode="mode"
      :etu-basis="etuBasis"
      :source-etu-factor="sourceEtuFactor"
      :metric-unit-suffix="metricUnitSuffix"
      :muscles="muscles"
      :exercises="exercises"
      @close="selectedSlug = null"
    />
  </div>
</template>
