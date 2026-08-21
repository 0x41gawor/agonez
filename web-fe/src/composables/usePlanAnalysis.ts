import { computed, ref, watch, type Ref } from 'vue'

import type {
  JointContribution,
  MuscleContribution,
  PlanAnalysisRequest,
  PlanAnalysisResult,
} from '@/api/plan-analysis-types'
import { plansApi } from '@/api/plans'
import type {
  AnalysisPhase,
  EtuDisplayMode,
  EtuTimeBasis,
} from '@/features/plans/analysis'

export const DEFAULT_ANALYSIS_REQUEST: Readonly<PlanAnalysisRequest> = {
  resolution_context: {
    global_volume_level: 0,
    focus_area: null,
    axis_overrides: {},
  },
}

export function usePlanAnalysis(
  planId: Ref<number>,
  persistedLockVersion: Ref<number | null>,
  draftDirty: Ref<boolean>,
) {
  const result = ref<PlanAnalysisResult | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)
  const explicitlyStale = ref(false)
  const selectedDayId = ref<number | null>(null)
  const selectedPhase = ref<AnalysisPhase>('BEFORE')
  const etuMode = ref<EtuDisplayMode>('ABSOLUTE')
  const etuTimeBasis = ref<EtuTimeBasis>('MICROCYCLE')
  let requestSequence = 0

  const lockVersionMismatch = computed(
    () =>
      result.value != null &&
      persistedLockVersion.value != null &&
      result.value.lock_version !== persistedLockVersion.value,
  )
  const stale = computed(
    () => explicitlyStale.value || draftDirty.value || lockVersionMismatch.value,
  )
  const selectedDay = computed(() => {
    const analysis = result.value
    if (!analysis) return null
    return (
      analysis.timeline.find((day) => day.day_id === selectedDayId.value) ??
      analysis.timeline[0] ??
      null
    )
  })
  const muscleContributionsBySlug = computed(() => {
    const index = new Map<string, MuscleContribution[]>()
    for (const item of result.value?.contributions ?? []) {
      if (item.type !== 'MUSCLE') continue
      const list = index.get(item.muscle_slug) ?? []
      list.push(item)
      index.set(item.muscle_slug, list)
    }
    return index
  })
  const jointContributionsBySlug = computed(() => {
    const index = new Map<string, JointContribution[]>()
    for (const item of result.value?.contributions ?? []) {
      if (item.type !== 'JOINT') continue
      const list = index.get(item.joint_slug) ?? []
      list.push(item)
      index.set(item.joint_slug, list)
    }
    return index
  })

  function chooseInitialDay(analysis: PlanAnalysisResult): void {
    const currentStillExists = analysis.timeline.some(
      (day) => day.day_id === selectedDayId.value,
    )
    if (currentStillExists) return
    selectedDayId.value =
      analysis.timeline.find((day) => day.workout != null)?.day_id ??
      analysis.timeline[0]?.day_id ??
      null
  }

  async function refresh(): Promise<boolean> {
    if (!Number.isInteger(planId.value) || planId.value < 1) return false
    const sequence = ++requestSequence
    loading.value = true
    error.value = null
    try {
      const analysis = await plansApi.analyzeDraft(planId.value, {
        resolution_context: {
          ...DEFAULT_ANALYSIS_REQUEST.resolution_context,
          axis_overrides: {},
        },
      })
      if (sequence !== requestSequence) return false
      result.value = analysis
      explicitlyStale.value = false
      chooseInitialDay(analysis)
      return true
    } catch (caught) {
      if (sequence !== requestSequence) return false
      error.value =
        caught instanceof Error ? caught.message : 'The persisted plan could not be analyzed.'
      return false
    } finally {
      if (sequence === requestSequence) loading.value = false
    }
  }

  async function activate(): Promise<void> {
    if (!result.value || (explicitlyStale.value && !draftDirty.value)) await refresh()
  }

  function markStale(): void {
    if (result.value) explicitlyStale.value = true
  }

  function selectDay(dayId: number): void {
    selectedDayId.value = dayId
    selectedPhase.value = 'BEFORE'
  }

  watch(planId, () => {
    requestSequence += 1
    result.value = null
    error.value = null
    explicitlyStale.value = false
    selectedDayId.value = null
    selectedPhase.value = 'BEFORE'
  })

  return {
    result,
    loading,
    error,
    selectedDayId,
    selectedDay,
    selectedPhase,
    etuMode,
    etuTimeBasis,
    stale,
    lockVersionMismatch,
    muscleContributionsBySlug,
    jointContributionsBySlug,
    refresh,
    activate,
    markStale,
    selectDay,
  }
}
