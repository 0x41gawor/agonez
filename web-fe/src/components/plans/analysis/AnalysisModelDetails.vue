<script setup lang="ts">
import type { PlanAnalysisResult } from '@/api/plan-analysis-types'
import { formatNumber } from '@/utils/format'

defineProps<{ result: PlanAnalysisResult }>()
</script>

<template>
  <details class="analysis-model-details panel">
    <summary><span><span class="section-label">Analysis model</span><strong>Parameters and inspectability</strong></span><span class="mono">{{ result.model_version }}</span></summary>
    <div class="model-detail-grid">
      <div><span>Model</span><strong>{{ result.model_version }}</strong></div>
      <div><span>Microcycle</span><strong>{{ result.model_parameters.microcycle_days }} days · {{ formatNumber(result.model_parameters.microcycle_hours, 0) }} h</strong></div>
      <div><span>Cycle length</span><strong>{{ formatNumber(result.model_parameters.microcycle_weeks, 2) }} weeks</strong></div>
      <div><span>Seven-day ETU factor</span><strong>×{{ formatNumber(result.model_parameters.weekly_normalization_factor, 3) }}</strong></div>
      <div><span>Cycles simulated</span><strong>{{ result.simulation_cycles }}</strong></div>
      <div><span>Recovery model</span><strong>Linear hours-to-fresh debt</strong></div>
      <div><span>Muscle recovery velocity</span><strong>{{ formatNumber(result.model_parameters.muscle_recovery_velocity_v1, 9) }} MRU/cm²/h</strong></div>
      <div><span>Joint recovery velocity</span><strong>{{ formatNumber(result.model_parameters.joint_recovery_velocity_v1, 6) }} JRU/h</strong></div>
      <div><span>Cumulative set penalty</span><strong>+{{ formatNumber(result.model_parameters.cumulative_set_penalty_step * 100, 0) }}% · cap ×{{ formatNumber(result.model_parameters.cumulative_set_penalty_cap, 2) }}</strong></div>
      <div><span>Convergence epsilon</span><strong>{{ result.model_parameters.recovery_convergence_epsilon_hours }} h</strong></div>
    </div>
    <div class="effective-reps-row">
      <span>Effective reps metadata</span>
      <code v-for="rir in ['0', '1', '2', '3', '4']" :key="rir">RIR{{ rir }} → {{ result.model_parameters.effective_reps_by_rir[rir] }}</code>
    </div>
    <div v-if="result.timing_assumptions.length" class="timing-assumptions">
      <strong>Timing assumptions</strong>
      <p v-for="item in result.timing_assumptions" :key="item.day_id">Day {{ item.day_ordinal + 1 }} · {{ item.detail }}</p>
    </div>
  </details>
</template>
