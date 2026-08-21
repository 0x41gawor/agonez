<script setup lang="ts">
import { computed, ref } from 'vue'

import type {
  AnalysisTimelineDay,
  JointContribution,
  MuscleContribution,
  PlanAnalysisResult,
} from '@/api/plan-analysis-types'
import type { ExerciseListItem, MuscleListItem } from '@/api/types'
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
  exercises: ExerciseListItem[]
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
    <div v-if="loading && !result" class="analysis-loading" aria-label="Analyzing saved plan">
      <div class="analysis-loading-copy">
        <span class="section-label">Authoritative model</span>
        <h2>Analyzing the saved plan…</h2>
        <p>Resolving stimulus, recovery, timing, and source provenance.</p>
      </div>
      <div class="analysis-loading-grid">
        <div class="skeleton" />
        <div class="skeleton" />
        <div class="skeleton wide" />
      </div>
    </div>

    <ErrorState
      v-else-if="error && !result"
      title="The saved plan could not be analyzed"
      :message="error"
      @retry="$emit('refresh')"
    />

    <div v-else-if="!result" class="analysis-empty panel">
      <span class="analysis-empty-mark" aria-hidden="true">∑</span>
      <h2>No Analysis snapshot yet</h2>
      <p>Run the backend model against the currently saved plan draft.</p>
      <button class="button primary" type="button" @click="$emit('refresh')">Run Analysis</button>
    </div>

    <template v-else>
      <div v-if="loading" class="analysis-refreshing" role="status">
        <span class="status-dot" /> Refreshing from the saved draft…
      </div>
      <div v-if="error" class="analysis-inline-error" role="alert">
        <span><strong>Refresh failed.</strong> The previous snapshot remains visible. {{ error }}</span>
        <button class="button" type="button" @click="$emit('refresh')">Try again</button>
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
        v-model:selected-muscle-slug="selectedMuscleSlug"
        :day="selectedDay"
        :muscles="muscles"
        :summaries="result.plan_summary.muscles"
      />
      <section v-else class="analysis-empty panel">
        <span class="analysis-empty-mark" aria-hidden="true">○</span>
        <h2>No timeline boundary is available</h2>
        <p>Add at least one day in PLAN, save it, then refresh Analysis.</p>
        <button class="button" type="button" @click="$emit('showPlan')">Open PLAN</button>
      </section>

      <MuscleSummary
        v-if="hasTrainingSessions && result.plan_summary.muscles.length"
        v-model:mode="etuMode"
        v-model:selected-slug="selectedMuscleSlug"
        :etu-basis="etuTimeBasis"
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
