<script setup lang="ts">
import { computed, ref } from 'vue'

import type {
  MuscleAnalysisSummary,
  MuscleContribution,
} from '@/api/plan-analysis-types'
import type { ExerciseListItem, MuscleListItem } from '@/api/types'
import {
  formatHours,
  muscleLabel,
  type EtuDisplayMode,
  type EtuTimeBasis,
  type MuscleSort,
} from '@/features/plans/analysis'
import { formatNumber } from '@/utils/format'
import ProvenanceInspector from './ProvenanceInspector.vue'

const mode = defineModel<EtuDisplayMode>('mode', { required: true })
const selectedSlug = defineModel<string | null>('selectedSlug', { default: null })
const props = defineProps<{
  summaries: MuscleAnalysisSummary[]
  etuBasis: EtuTimeBasis
  contributionsBySlug: Map<string, MuscleContribution[]>
  muscles: MuscleListItem[]
  exercises: ExerciseListItem[]
}>()

const sort = ref<MuscleSort>('ETU')
const expanded = ref(false)
const sorted = computed(() => {
  const items = [...props.summaries]
  items.sort((a, b) => {
    if (sort.value === 'NORMALIZED')
      return (etuPerFcsa(b) ?? -1) - (etuPerFcsa(a) ?? -1)
    if (sort.value === 'RECOVERY')
      return b.worst_pre_workout_hours_to_fresh - a.worst_pre_workout_hours_to_fresh
    return totalEtu(b) - totalEtu(a)
  })
  return items
})
const visible = computed(() => (expanded.value ? sorted.value : sorted.value.slice(0, 14)))
const selectedContributions = computed(() =>
  selectedSlug.value ? props.contributionsBySlug.get(selectedSlug.value) ?? [] : [],
)

function primaryValue(item: MuscleAnalysisSummary): number | null {
  return mode.value === 'ABSOLUTE' ? totalEtu(item) : etuPerFcsa(item)
}

function totalEtu(item: MuscleAnalysisSummary): number {
  return props.etuBasis === 'WEEKLY' ? item.weekly_etu : item.total_etu
}

function etuPerFcsa(item: MuscleAnalysisSummary): number | null {
  return props.etuBasis === 'WEEKLY'
    ? item.weekly_etu_per_fcsa_cm2
    : item.etu_per_fcsa_cm2
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
</script>

<template>
  <section class="analysis-section muscle-summary-section">
    <header class="analysis-section-heading summary-heading">
      <div>
        <span class="section-label">Muscle summary</span>
        <h2>{{ etuBasis === 'WEEKLY' ? 'Seven-day-normalized stimulus' : 'Complete microcycle stimulus' }}</h2>
        <p>
          {{ etuBasis === 'WEEKLY' ? 'ETU is normalized to seven days for comparison; recovery still uses the complete cycle.' : 'ETU is modeled hypertrophic stimulus across the complete cycle; recovery debt is shown separately.' }}
        </p>
      </div>
      <div class="summary-controls">
        <div class="metric-switch" aria-label="ETU normalization">
          <button type="button" :class="{ active: mode === 'ABSOLUTE' }" @click="mode = 'ABSOLUTE'">Absolute ETU</button>
          <button type="button" :class="{ active: mode === 'NORMALIZED' }" @click="mode = 'NORMALIZED'">ETU / FCSA</button>
        </div>
        <label>
          <span class="sr-only">Sort muscles</span>
          <select v-model="sort" class="select-input compact-select">
            <option value="ETU">Sort: ETU</option>
            <option value="NORMALIZED">Sort: ETU / FCSA</option>
            <option value="RECOVERY">Sort: recovery debt</option>
          </select>
        </label>
      </div>
    </header>

    <div class="analysis-table-wrap panel">
      <table class="analysis-table muscle-analysis-table">
        <thead>
          <tr>
            <th>Muscle</th>
            <th>{{ mode === 'ABSOLUTE' ? (etuBasis === 'WEEKLY' ? 'ETU / 7d' : 'ETU') : (etuBasis === 'WEEKLY' ? 'ETU / FCSA / 7d' : 'ETU / FCSA') }}</th>
            <th>Intent composition</th>
            <th>Worst before</th>
            <th>Max after</th>
            <th><span class="sr-only">Inspect</span></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in visible" :key="item.slug" :class="{ selected: selectedSlug === item.slug }">
            <td>
              <strong>{{ muscleLabel(item.slug, muscles) }}</strong>
              <small>{{ formatNumber(item.total_mru, 1) }} MRU / cycle · {{ item.recovery_converged ? 'converged' : 'divergent' }}</small>
            </td>
            <td class="primary-analysis-metric mono">
              {{ formatNumber(primaryValue(item), 2) }}
              <small>{{ mode === 'ABSOLUTE' ? (etuBasis === 'WEEKLY' ? 'ETU/7d' : 'ETU') : (etuBasis === 'WEEKLY' ? 'ETU/cm²/7d' : 'ETU/cm²') }}</small>
            </td>
            <td>
              <div class="intent-stack" :aria-label="`${formatNumber(intentionalEtu(item), 2)} intentional, ${formatNumber(incidentalEtu(item), 2)} incidental, ${formatNumber(unclassifiedEtu(item), 2)} unclassified ETU`">
                <span class="intentional" :style="{ width: intentWidth(item, intentionalEtu(item)) }" />
                <span class="incidental" :style="{ width: intentWidth(item, incidentalEtu(item)) }" />
                <span class="unclassified" :style="{ width: intentWidth(item, unclassifiedEtu(item)) }" />
              </div>
              <small class="intent-numbers mono">
                I {{ formatNumber(intentionalEtu(item), 1) }} · Inc {{ formatNumber(incidentalEtu(item), 1) }} · U {{ formatNumber(unclassifiedEtu(item), 1) }}
              </small>
            </td>
            <td>{{ formatHours(item.worst_pre_workout_hours_to_fresh) }}</td>
            <td>{{ formatHours(item.maximum_post_workout_hours_to_fresh) }}</td>
            <td><button class="text-action" type="button" @click="selectedSlug = item.slug">Explain</button></td>
          </tr>
        </tbody>
      </table>
      <button
        v-if="sorted.length > 14"
        class="table-expander"
        type="button"
        @click="expanded = !expanded"
      >
        {{ expanded ? 'Show strongest 14 muscles' : `View all ${sorted.length} muscles` }}
      </button>
    </div>

    <div class="intent-legend">
      <span><i class="intentional" />Intentional</span>
      <span><i class="incidental" />Incidental</span>
      <span><i class="unclassified" />Unclassified · source slot had no declared targets</span>
    </div>

    <ProvenanceInspector
      v-if="selectedSlug"
      :muscle-slug="selectedSlug"
      :muscle-contributions="selectedContributions"
      :muscles="muscles"
      :exercises="exercises"
    />
  </section>
</template>
