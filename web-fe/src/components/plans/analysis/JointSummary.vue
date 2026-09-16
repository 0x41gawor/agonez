<script setup lang="ts">
import { computed, ref } from 'vue'

import type { JointAnalysisSummary, JointContribution } from '@/api/plan-analysis-types'
import type { ExerciseCatalogItem, MuscleListItem } from '@/api/types'
import { formatHours, jointLabel } from '@/features/plans/analysis'
import { formatNumber } from '@/utils/format'
import ProvenanceInspector from './ProvenanceInspector.vue'

const props = defineProps<{
  summaries: JointAnalysisSummary[]
  contributionsBySlug: Map<string, JointContribution[]>
  exercises: ExerciseCatalogItem[]
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
        <span class="section-label">{{ $t('analysis.joints.label') }}</span>
        <h2>{{ $t('analysis.joints.title') }}</h2>
        <p>{{ $t('analysis.joints.subtitle') }}</p>
      </div>
      <span class="mono analysis-count">{{ $t('analysis.common.joints', { count: summaries.length }) }}</span>
    </header>
    <div class="analysis-table-wrap panel">
      <table class="analysis-table joint-analysis-table">
        <thead><tr><th>{{ $t('analysis.joints.joint') }}</th><th>{{ $t('analysis.joints.exposure') }}</th><th>JRU</th><th>{{ $t('analysis.joints.worst') }}</th><th>{{ $t('analysis.joints.max') }}</th><th><span class="sr-only">{{ $t('analysis.joints.inspect') }}</span></th></tr></thead>
        <tbody>
          <tr v-for="item in sorted" :key="item.slug" :class="{ selected: selectedSlug === item.slug }">
            <td><strong>{{ jointLabel(item.slug) }}</strong><small>{{ $t(item.recovery_converged ? 'analysis.joints.converged' : 'analysis.joints.divergent') }}</small></td>
            <td class="mono">{{ formatNumber(item.total_joint_load_exposure, 2) }}</td>
            <td class="mono">{{ formatNumber(item.total_jru, 2) }}</td>
            <td>{{ formatHours(item.worst_pre_workout_hours_to_fresh) }}</td>
            <td>{{ formatHours(item.maximum_post_workout_hours_to_fresh) }}</td>
            <td><button class="text-action" type="button" @click="selectedSlug = item.slug">{{ $t('analysis.common.explain') }}</button></td>
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
