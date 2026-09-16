<script setup lang="ts">
import type { PlanAnalysisResult } from '@/api/plan-analysis-types'
import { formatNumber } from '@/utils/format'

defineProps<{ result: PlanAnalysisResult }>()
</script>

<template>
  <details class="analysis-model-details panel">
    <summary><span><span class="section-label">{{ $t('analysis.model.label') }}</span><strong>{{ $t('analysis.model.title') }}</strong></span><span class="mono">{{ result.model_version }}</span></summary>
    <div class="model-detail-grid">
      <div><span>{{ $t('analysis.model.model') }}</span><strong>{{ result.model_version }}</strong></div>
      <div><span>{{ $t('analysis.model.microcycle') }}</span><strong>{{ $t('analysis.model.daysHours', { days: result.model_parameters.microcycle_days, hours: formatNumber(result.model_parameters.microcycle_hours, 0) }) }}</strong></div>
      <div><span>{{ $t('analysis.model.cycleLength') }}</span><strong>{{ $t('analysis.model.weeks', { count: formatNumber(result.model_parameters.microcycle_weeks, 2) }) }}</strong></div>
      <div><span>{{ $t('analysis.model.factor') }}</span><strong>×{{ formatNumber(result.model_parameters.weekly_normalization_factor, 3) }}</strong></div>
      <div><span>{{ $t('analysis.model.cycles') }}</span><strong>{{ result.simulation_cycles }}</strong></div>
      <div><span>{{ $t('analysis.model.recoveryModel') }}</span><strong>{{ $t('analysis.model.recoveryValue') }}</strong></div>
      <div><span>{{ $t('analysis.model.muscleVelocity') }}</span><strong>{{ formatNumber(result.model_parameters.muscle_recovery_velocity_v1, 9) }} MRU/cm²/h</strong></div>
      <div><span>{{ $t('analysis.model.jointVelocity') }}</span><strong>{{ formatNumber(result.model_parameters.joint_recovery_velocity_v1, 6) }} JRU/h</strong></div>
      <div><span>{{ $t('analysis.model.penalty') }}</span><strong>+{{ formatNumber(result.model_parameters.cumulative_set_penalty_step * 100, 0) }}% · cap ×{{ formatNumber(result.model_parameters.cumulative_set_penalty_cap, 2) }}</strong></div>
      <div><span>{{ $t('analysis.model.epsilon') }}</span><strong>{{ result.model_parameters.recovery_convergence_epsilon_hours }} h</strong></div>
    </div>
    <div class="effective-reps-row">
      <span>{{ $t('analysis.model.effectiveReps') }}</span>
      <code v-for="rir in ['0', '1', '2', '3', '4']" :key="rir">RIR{{ rir }} → {{ result.model_parameters.effective_reps_by_rir[rir] }}</code>
    </div>
    <div v-if="result.timing_assumptions.length" class="timing-assumptions">
      <strong>{{ $t('analysis.model.assumptions') }}</strong>
      <p v-for="item in result.timing_assumptions" :key="item.day_id">{{ $t('analysis.model.day', { number: item.day_ordinal + 1 }) }} · {{ item.detail }}</p>
    </div>
  </details>
</template>
