<script setup lang="ts">
import { computed } from 'vue'

import type { PlanAnalysisResult } from '@/api/plan-analysis-types'
import type { EtuTimeBasis } from '@/features/plans/analysis'
import { formatNumber } from '@/utils/format'

const etuBasis = defineModel<EtuTimeBasis>('etuBasis', { required: true })
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
const displayedTotalEtu = computed(() =>
  etuBasis.value === 'WEEKLY'
    ? props.result.plan_summary.weekly_etu_scalar
    : props.result.plan_summary.total_etu_scalar,
)
</script>

<template>
  <section class="analysis-snapshot panel">
    <header class="analysis-section-heading">
      <div>
        <span class="section-label">{{ $t('analysis.snapshot.label') }}</span>
        <h2>{{ $t('analysis.snapshot.title') }}</h2>
        <p>{{ $t('analysis.snapshot.subtitle') }}</p>
      </div>
      <span class="revision-chip mono">{{ $t('analysis.snapshot.revision', { revision: result.revision_no, version: result.lock_version }) }}</span>
    </header>

    <div class="snapshot-controls">
      <div class="snapshot-control" aria-disabled="true">
        <span>{{ $t('analysis.snapshot.volume') }}</span>
        <strong>{{ $t('analysis.snapshot.defaultLevel', { level: result.resolution_context.global_volume_level }) }}</strong>
        <small class="mono">{{ $t('analysis.snapshot.modulationLater') }}</small>
      </div>
      <div class="snapshot-control snapshot-control-basis">
        <span>{{ $t('analysis.snapshot.basis') }}</span>
        <div class="metric-switch" :aria-label="$t('analysis.snapshot.basisAria')">
          <button type="button" :class="{ active: etuBasis === 'MICROCYCLE' }" @click="etuBasis = 'MICROCYCLE'">
            {{ $t('analysis.snapshot.fullCycle') }}
          </button>
          <button type="button" :class="{ active: etuBasis === 'WEEKLY' }" @click="etuBasis = 'WEEKLY'">
            {{ $t('analysis.snapshot.perWeek') }}
          </button>
        </div>
        <small class="mono">
          {{ result.model_parameters.microcycle_days }}d · {{ formatNumber(result.model_parameters.microcycle_weeks, 2) }}w
        </small>
      </div>
      <div class="snapshot-control" aria-disabled="true">
        <span>{{ $t('analysis.snapshot.focus') }}</span>
        <strong>{{ result.resolution_context.focus_area || $t('analysis.snapshot.none') }}</strong>
        <small class="mono">{{ $t('analysis.snapshot.modulationLater') }}</small>
      </div>
    </div>

    <div v-if="stale" class="analysis-stale" role="status">
      <div>
        <span class="status-chip">{{ $t('analysis.snapshot.outOfDate') }}</span>
        <strong v-if="dirty">{{ $t('analysis.snapshot.unsaved') }}</strong>
        <strong v-else-if="lockMismatch">{{ $t('analysis.snapshot.lockMismatch') }}</strong>
        <strong v-else>{{ $t('analysis.snapshot.changed') }}</strong>
        <p>{{ $t('analysis.snapshot.versionNote', { version: result.lock_version }) }}</p>
      </div>
      <div class="analysis-banner-actions">
        <button v-if="dirty" class="button" type="button" @click="$emit('save')">{{ $t('analysis.snapshot.savePlan') }}</button>
        <button v-if="dirty" class="button subtle" type="button" @click="$emit('showPlan')">{{ $t('analysis.snapshot.reviewPlan') }}</button>
        <button v-else class="button primary" type="button" @click="$emit('refresh')">{{ $t('analysis.snapshot.refresh') }}</button>
      </div>
    </div>

    <div
      class="analysis-model-state"
      :class="{ divergent: !result.recovery_converged }"
      role="status"
    >
      <div class="analysis-model-mark" aria-hidden="true">{{ result.recovery_converged ? '✓' : '↗' }}</div>
      <div>
        <span class="section-label">{{ $t('analysis.snapshot.recoveryModel') }}</span>
        <strong>{{ $t(result.recovery_converged ? 'analysis.snapshot.converged' : 'analysis.snapshot.divergent') }}</strong>
        <p v-if="divergence">
          {{ $t('analysis.snapshot.divergenceHelp', { version: result.model_version }) }}
        </p>
        <p v-else>{{ $t('analysis.snapshot.convergedHelp', { count: result.simulation_cycles }) }}</p>
      </div>
      <div v-if="divergence" class="divergence-counts mono">
        <span>{{ $t('analysis.common.muscles', { count: divergence.affected_muscle_slugs.length }) }}</span>
        <span>{{ $t('analysis.common.joints', { count: divergence.affected_joint_slugs.length }) }}</span>
      </div>
    </div>

    <div class="analysis-overview-grid" :aria-label="$t('analysis.snapshot.overview')">
      <div>
        <span>{{ $t(etuBasis === 'WEEKLY' ? 'analysis.snapshot.weeklyEtu' : 'analysis.snapshot.cycleEtu') }}</span>
        <strong>{{ formatNumber(displayedTotalEtu, 1) }}</strong>
        <small>{{ $t(etuBasis === 'WEEKLY' ? 'analysis.snapshot.normalizedFrom' : 'analysis.snapshot.dayAggregate', { count: result.model_parameters.microcycle_days }) }}</small>
      </div>
      <div><span>{{ $t('analysis.snapshot.stimulated') }}</span><strong>{{ stimulatedMuscles }}</strong><small>{{ $t('analysis.snapshot.nonZero') }}</small></div>
      <div><span>{{ $t('analysis.snapshot.musclesNotFresh') }}</span><strong>{{ musclesNotFresh }}</strong><small>{{ $t('analysis.snapshot.beforeWorkout') }}</small></div>
      <div><span>{{ $t('analysis.snapshot.jointsNotFresh') }}</span><strong>{{ jointsNotFresh }}</strong><small>{{ $t('analysis.snapshot.beforeWorkout') }}</small></div>
      <div><span>{{ $t('analysis.snapshot.simulation') }}</span><strong>{{ result.simulation_cycles }}</strong><small>{{ $t('analysis.snapshot.cycles') }}</small></div>
    </div>
  </section>
</template>
