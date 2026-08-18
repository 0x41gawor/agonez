<script setup lang="ts">
import { computed, ref } from 'vue'

import type { JointAnalysisSummary, JointContribution } from '@/api/plan-analysis-types'
import type { ExerciseListItem, MuscleListItem } from '@/api/types'
import { formatHours, jointLabel } from '@/features/plans/analysis'
import { formatNumber } from '@/utils/format'
import ProvenanceInspector from './ProvenanceInspector.vue'

const props = defineProps<{
  summaries: JointAnalysisSummary[]
  contributionsBySlug: Map<string, JointContribution[]>
  exercises: ExerciseListItem[]
  muscles: MuscleListItem[]
}>()

const selectedSlug = ref<string | null>(null)
const sorted = computed(() =>
  [...props.summaries].sort(
    (a, b) => b.worst_pre_workout_hours_to_fresh - a.worst_pre_workout_hours_to_fresh,
  ),
)
const selectedContributions = computed(() =>
  selectedSlug.value ? props.contributionsBySlug.get(selectedSlug.value) ?? [] : [],
)
</script>

<template>
  <section class="analysis-section joint-summary-section">
    <header class="analysis-section-heading">
      <div>
        <span class="section-label">Joint load recovery</span>
        <h2>Modeled joint readiness cost</h2>
        <p>JRU and hours-to-fresh do not represent literal tissue-healing time.</p>
      </div>
      <span class="mono analysis-count">{{ summaries.length }} joints</span>
    </header>
    <div class="analysis-table-wrap panel">
      <table class="analysis-table joint-analysis-table">
        <thead><tr><th>Joint</th><th>Load exposure</th><th>JRU</th><th>Worst before</th><th>Max after</th><th><span class="sr-only">Inspect</span></th></tr></thead>
        <tbody>
          <tr v-for="item in sorted" :key="item.slug" :class="{ selected: selectedSlug === item.slug }">
            <td><strong>{{ jointLabel(item.slug) }}</strong><small>{{ item.recovery_converged ? 'Periodic state converged' : 'Divergent under V1' }}</small></td>
            <td class="mono">{{ formatNumber(item.total_joint_load_exposure, 2) }}</td>
            <td class="mono">{{ formatNumber(item.total_jru, 2) }}</td>
            <td>{{ formatHours(item.worst_pre_workout_hours_to_fresh) }}</td>
            <td>{{ formatHours(item.maximum_post_workout_hours_to_fresh) }}</td>
            <td><button class="text-action" type="button" @click="selectedSlug = item.slug">Explain</button></td>
          </tr>
        </tbody>
      </table>
    </div>
    <ProvenanceInspector
      v-if="selectedSlug"
      :joint-slug="selectedSlug"
      :joint-contributions="selectedContributions"
      :muscles="muscles"
      :exercises="exercises"
    />
  </section>
</template>
