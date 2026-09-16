<script setup lang="ts">
import { computed, ref } from 'vue'

import type {
  AnalysisTimelineDay,
  JointContribution,
  MuscleContribution,
  PlanAnalysisResult,
} from '@/api/plan-analysis-types'
import type { ExerciseCatalogItem, MuscleListItem } from '@/api/types'
import ErrorState from '@/components/common/ErrorState.vue'
import type {
  AnalysisPhase,
  EtuDisplayMode,
  EtuTimeBasis,
} from '@/features/plans/analysis'
import AnalysisDiagnostics from './AnalysisDiagnostics.vue'
import AnalysisModelDetails from './AnalysisModelDetails.vue'
import AnalysisSnapshot from './AnalysisSnapshot.vue'
import JointSummary from './JointSummary.vue'
import MicrocycleTimeline from './MicrocycleTimeline.vue'
import MuscleSummary from './MuscleSummary.vue'
import WorkoutAnalysis from './WorkoutAnalysis.vue'

const phase = defineModel<AnalysisPhase>('phase', { required: true })
const etuMode = defineModel<EtuDisplayMode>('etuMode', { required: true })
const etuTimeBasis = defineModel<EtuTimeBasis>('etuTimeBasis', { required: true })
const props = defineProps<{
  result: PlanAnalysisResult | null
  loading: boolean
  error: string | null
  stale: boolean
  dirty: boolean
  lockMismatch: boolean
  selectedDay: AnalysisTimelineDay | null
  selectedDayId: number | null
  muscleContributionsBySlug: Map<string, MuscleContribution[]>
  jointContributionsBySlug: Map<string, JointContribution[]>
  muscles: MuscleListItem[]
  exercises: ExerciseCatalogItem[]
}>()

defineEmits<{
  refresh: []
  save: []
  showPlan: []
  selectDay: [dayId: number]
}>()

const selectedMuscleSlug = ref<string | null>(null)
const hasTrainingSessions = computed(
  () => props.result?.timeline.some((day) => day.workout != null) ?? false,
)
</script>

<template>
  <div class="analysis-page">
    <div v-if="loading && !result" class="analysis-loading" :aria-label="$t('analysis.page.analyzingAria')">
      <div class="analysis-loading-copy">
        <span class="section-label">{{ $t('analysis.page.authoritative') }}</span>
        <h2>{{ $t('analysis.page.analyzing') }}</h2>
        <p>{{ $t('analysis.page.resolving') }}</p>
      </div>
      <div class="analysis-loading-grid">
        <div class="skeleton" />
        <div class="skeleton" />
        <div class="skeleton wide" />
      </div>
    </div>

    <ErrorState
      v-else-if="error && !result"
      :title="$t('analysis.page.loadError')"
      :message="error"
      @retry="$emit('refresh')"
    />

    <div v-else-if="!result" class="analysis-empty panel">
      <span class="analysis-empty-mark" aria-hidden="true">∑</span>
      <h2>{{ $t('analysis.page.noSnapshot') }}</h2>
      <p>{{ $t('analysis.page.noSnapshotHelp') }}</p>
      <button class="button primary" type="button" @click="$emit('refresh')">{{ $t('analysis.page.run') }}</button>
    </div>

    <template v-else>
      <div v-if="loading" class="analysis-refreshing" role="status">
        <span class="status-dot" /> {{ $t('analysis.page.refreshing') }}
      </div>
      <div v-if="error" class="analysis-inline-error" role="alert">
        <span><strong>{{ $t('analysis.page.refreshFailed') }}</strong> {{ $t('analysis.page.previousVisible') }} {{ error }}</span>
        <button class="button" type="button" @click="$emit('refresh')">{{ $t('common.retry') }}</button>
      </div>

      <AnalysisSnapshot
        v-model:etu-basis="etuTimeBasis"
        :result="result"
        :stale="stale"
        :dirty="dirty"
        :lock-mismatch="lockMismatch"
        @refresh="$emit('refresh')"
        @save="$emit('save')"
        @show-plan="$emit('showPlan')"
      />

      <MicrocycleTimeline
        :days="result.timeline"
        :selected-day-id="selectedDayId"
        @select="$emit('selectDay', $event)"
      />

      <WorkoutAnalysis
        v-if="selectedDay && hasTrainingSessions"
        v-model:phase="phase"
        v-model:etu-mode="etuMode"
        v-model:selected-muscle-slug="selectedMuscleSlug"
        :day="selectedDay"
        :timeline="result.timeline"
        :contributions-by-slug="muscleContributionsBySlug"
        :muscles="muscles"
        :exercises="exercises"
        :summaries="result.plan_summary.muscles"
      />
      <section v-else class="analysis-empty panel">
        <span class="analysis-empty-mark" aria-hidden="true">○</span>
        <h2>{{ $t('analysis.page.noBoundary') }}</h2>
        <p>{{ $t('analysis.page.noBoundaryHelp') }}</p>
        <button class="button" type="button" @click="$emit('showPlan')">{{ $t('analysis.page.openPlan') }}</button>
      </section>

      <MuscleSummary
        v-if="hasTrainingSessions && result.plan_summary.muscles.length"
        v-model:mode="etuMode"
        v-model:selected-slug="selectedMuscleSlug"
        :etu-basis="etuTimeBasis"
        :weekly-normalization-factor="result.model_parameters.weekly_normalization_factor"
        :timeline="result.timeline"
        :summaries="result.plan_summary.muscles"
        :contributions-by-slug="muscleContributionsBySlug"
        :muscles="muscles"
        :exercises="exercises"
      />

      <JointSummary
        v-if="hasTrainingSessions && result.plan_summary.joints.length"
        :summaries="result.plan_summary.joints"
        :contributions-by-slug="jointContributionsBySlug"
        :muscles="muscles"
        :exercises="exercises"
      />

      <AnalysisDiagnostics :diagnostics="result.diagnostics" :muscles="muscles" />
      <AnalysisModelDetails :result="result" />
    </template>
  </div>
</template>
