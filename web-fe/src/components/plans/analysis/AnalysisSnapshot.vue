<script setup lang="ts">
import { computed } from 'vue'

import type { PlanAnalysisResult } from '@/api/plan-analysis-types'
import { formatNumber } from '@/utils/format'

const props = defineProps<{
  result: PlanAnalysisResult
  stale: boolean
  dirty: boolean
  lockMismatch: boolean
}>()

defineEmits<{
  refresh: []
  save: []
  showPlan: []
}>()

const divergence = computed(() =>
  props.result.diagnostics.find((item) => item.code === 'RECOVERY_DIVERGENCE'),
)
const stimulatedMuscles = computed(
  () => props.result.plan_summary.muscles.filter((item) => item.total_etu > 0).length,
)
const musclesNotFresh = computed(
  () =>
    props.result.plan_summary.muscles.filter(
      (item) => item.worst_pre_workout_hours_to_fresh > 0.005,
    ).length,
)
const jointsNotFresh = computed(
  () =>
    props.result.plan_summary.joints.filter(
      (item) => item.worst_pre_workout_hours_to_fresh > 0.005,
    ).length,
)
</script>

<template>
  <section class="analysis-snapshot panel">
    <header class="analysis-section-heading">
      <div>
        <span class="section-label">Analysis snapshot</span>
        <h2>Resolved plan state</h2>
        <p>Analysis inspects one persisted volume × focus-area snapshot.</p>
      </div>
      <span class="revision-chip mono">Draft r{{ result.revision_no }} · v{{ result.lock_version }}</span>
    </header>

    <div class="snapshot-controls">
      <div class="snapshot-control" aria-disabled="true">
        <span>Volume</span>
        <strong>Default · Level {{ result.resolution_context.global_volume_level }}</strong>
        <small class="mono">Modulation later</small>
      </div>
      <div class="snapshot-control" aria-disabled="true">
        <span>Focus</span>
        <strong>{{ result.resolution_context.focus_area || 'None' }}</strong>
        <small class="mono">Modulation later</small>
      </div>
    </div>

    <div v-if="stale" class="analysis-stale" role="status">
      <div>
        <span class="status-chip">Out of date</span>
        <strong v-if="dirty">Plan has unsaved changes.</strong>
        <strong v-else-if="lockMismatch">Analysis lock version differs from the loaded plan.</strong>
        <strong v-else>Saved plan changed after this Analysis was loaded.</strong>
        <p>Displayed values remain based on saved draft version {{ result.lock_version }}.</p>
      </div>
      <div class="analysis-banner-actions">
        <button v-if="dirty" class="button" type="button" @click="$emit('save')">Save PLAN</button>
        <button v-if="dirty" class="button subtle" type="button" @click="$emit('showPlan')">Review PLAN</button>
        <button v-else class="button primary" type="button" @click="$emit('refresh')">Refresh Analysis</button>
      </div>
    </div>

    <div
      class="analysis-model-state"
      :class="{ divergent: !result.recovery_converged }"
      role="status"
    >
      <div class="analysis-model-mark" aria-hidden="true">{{ result.recovery_converged ? '✓' : '↗' }}</div>
      <div>
        <span class="section-label">Recovery model</span>
        <strong>{{ result.recovery_converged ? 'Steady state reached' : 'Recovery debt diverges' }}</strong>
        <p v-if="divergence">
          Repeated microcycles did not settle under {{ result.model_version }}. This is a model diagnostic, not a physiological diagnosis.
        </p>
        <p v-else>Periodic recovery state converged after {{ result.simulation_cycles }} simulated cycles.</p>
      </div>
      <div v-if="divergence" class="divergence-counts mono">
        <span><strong>{{ divergence.affected_muscle_slugs.length }}</strong> muscles</span>
        <span><strong>{{ divergence.affected_joint_slugs.length }}</strong> joints</span>
      </div>
    </div>

    <div class="analysis-overview-grid" aria-label="Plan Analysis overview">
      <div><span>Total ETU</span><strong>{{ formatNumber(result.plan_summary.total_etu_scalar, 1) }}</strong><small>descriptive aggregate</small></div>
      <div><span>Stimulated muscles</span><strong>{{ stimulatedMuscles }}</strong><small>non-zero ETU</small></div>
      <div><span>Muscles not fresh</span><strong>{{ musclesNotFresh }}</strong><small>before ≥1 workout</small></div>
      <div><span>Joints not fresh</span><strong>{{ jointsNotFresh }}</strong><small>before ≥1 workout</small></div>
      <div><span>Simulation</span><strong>{{ result.simulation_cycles }}</strong><small>cycles evaluated</small></div>
    </div>
  </section>
</template>
