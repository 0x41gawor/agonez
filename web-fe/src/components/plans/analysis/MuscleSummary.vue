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
  type MuscleSort,
} from '@/features/plans/analysis'
import { formatNumber } from '@/utils/format'
import ProvenanceInspector from './ProvenanceInspector.vue'

const mode = defineModel<EtuDisplayMode>('mode', { required: true })
const selectedSlug = defineModel<string | null>('selectedSlug', { default: null })
const props = defineProps<{
  summaries: MuscleAnalysisSummary[]
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
      return (b.etu_per_fcsa_cm2 ?? -1) - (a.etu_per_fcsa_cm2 ?? -1)
    if (sort.value === 'RECOVERY')
      return b.worst_pre_workout_hours_to_fresh - a.worst_pre_workout_hours_to_fresh
    return b.total_etu - a.total_etu
  })
  return items
})
const visible = computed(() => (expanded.value ? sorted.value : sorted.value.slice(0, 14)))
const selectedContributions = computed(() =>
  selectedSlug.value ? props.contributionsBySlug.get(selectedSlug.value) ?? [] : [],
)

function primaryValue(item: MuscleAnalysisSummary): number | null {
  return mode.value === 'ABSOLUTE' ? item.total_etu : item.etu_per_fcsa_cm2
}

function intentWidth(item: MuscleAnalysisSummary, value: number): string {
  return `${item.total_etu > 0 ? Math.max(0, (value / item.total_etu) * 100) : 0}%`
}
</script>

<template>
  <section class="analysis-section muscle-summary-section">
    <header class="analysis-section-heading summary-heading">
      <div>
        <span class="section-label">Muscle summary</span>
        <h2>Complete microcycle stimulus</h2>
        <p>ETU is modeled hypertrophic stimulus; recovery debt is shown separately.</p>
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
            <th>{{ mode === 'ABSOLUTE' ? 'ETU' : 'ETU / FCSA' }}</th>
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
              <small>{{ formatNumber(item.total_mru, 1) }} MRU · {{ item.recovery_converged ? 'converged' : 'divergent' }}</small>
            </td>
            <td class="primary-analysis-metric mono">
              {{ formatNumber(primaryValue(item), 2) }}
              <small>{{ mode === 'ABSOLUTE' ? 'ETU' : 'ETU/cm²' }}</small>
            </td>
            <td>
              <div class="intent-stack" :aria-label="`${formatNumber(item.intentional_etu, 2)} intentional, ${formatNumber(item.incidental_etu, 2)} incidental, ${formatNumber(item.unclassified_etu, 2)} unclassified ETU`">
                <span class="intentional" :style="{ width: intentWidth(item, item.intentional_etu) }" />
                <span class="incidental" :style="{ width: intentWidth(item, item.incidental_etu) }" />
                <span class="unclassified" :style="{ width: intentWidth(item, item.unclassified_etu) }" />
              </div>
              <small class="intent-numbers mono">
                I {{ formatNumber(item.intentional_etu, 1) }} · Inc {{ formatNumber(item.incidental_etu, 1) }} · U {{ formatNumber(item.unclassified_etu, 1) }}
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
