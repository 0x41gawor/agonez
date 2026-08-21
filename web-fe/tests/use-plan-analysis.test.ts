import { nextTick, ref } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import { plansApi } from '@/api/plans'
import {
  DEFAULT_ANALYSIS_REQUEST,
  usePlanAnalysis,
} from '@/composables/usePlanAnalysis'
import { analysisResult } from './fixtures/analysis'

vi.mock('@/api/plans', () => ({
  plansApi: {
    analyzeDraft: vi.fn(),
  },
}))

describe('usePlanAnalysis', () => {
  beforeEach(() => {
    vi.mocked(plansApi.analyzeDraft).mockReset()
    vi.mocked(plansApi.analyzeDraft).mockResolvedValue(analysisResult())
  })

  it('loads persisted Analysis once on first activation with the frozen context', async () => {
    const state = usePlanAnalysis(ref(11), ref(4), ref(false))

    await state.activate()
    await state.activate()

    expect(plansApi.analyzeDraft).toHaveBeenCalledTimes(1)
    expect(plansApi.analyzeDraft).toHaveBeenCalledWith(11, DEFAULT_ANALYSIS_REQUEST)
    expect(state.result.value?.model_version).toBe('plan-analysis-v2')
    expect(state.selectedDay.value?.day_id).toBe(31)
    expect(state.etuTimeBasis.value).toBe('WEEKLY')
    expect(state.etuMode.value).toBe('NORMALIZED')
  })

  it('keeps BEFORE/AFTER and day selection local without another request', async () => {
    const state = usePlanAnalysis(ref(11), ref(4), ref(false))
    await state.activate()

    state.selectedPhase.value = 'AFTER'
    state.selectDay(32)

    expect(state.selectedPhase.value).toBe('BEFORE')
    expect(state.selectedDay.value?.day_name).toBe('Rest')
    expect(plansApi.analyzeDraft).toHaveBeenCalledTimes(1)
  })

  it('recognizes dirty, explicitly invalidated, and lock-mismatched snapshots', async () => {
    const persistedLock = ref<number | null>(4)
    const dirty = ref(false)
    const state = usePlanAnalysis(ref(11), persistedLock, dirty)
    await state.activate()

    expect(state.stale.value).toBe(false)
    dirty.value = true
    expect(state.stale.value).toBe(true)
    dirty.value = false
    state.markStale()
    expect(state.stale.value).toBe(true)

    vi.mocked(plansApi.analyzeDraft).mockResolvedValue(analysisResult({ lock_version: 5 }))
    await state.refresh()
    expect(state.lockVersionMismatch.value).toBe(true)
    expect(state.stale.value).toBe(true)
  })

  it('refreshes a saved stale snapshot but never auto-refreshes unsaved edits', async () => {
    const dirty = ref(false)
    const state = usePlanAnalysis(ref(11), ref(4), dirty)
    await state.activate()
    state.markStale()
    dirty.value = true

    await state.activate()
    expect(plansApi.analyzeDraft).toHaveBeenCalledTimes(1)

    dirty.value = false
    await state.activate()
    expect(plansApi.analyzeDraft).toHaveBeenCalledTimes(2)
    expect(state.stale.value).toBe(false)
  })

  it('distinguishes transport failure from diagnostics and retains prior data', async () => {
    const state = usePlanAnalysis(ref(11), ref(4), ref(false))
    await state.activate()
    expect(state.result.value?.diagnostics[0]?.code).toBe('RECOVERY_DIVERGENCE')

    vi.mocked(plansApi.analyzeDraft).mockRejectedValue(new Error('503 unavailable'))
    expect(await state.refresh()).toBe(false)

    expect(state.error.value).toBe('503 unavailable')
    expect(state.result.value?.timeline).toHaveLength(2)
  })

  it('drops stale Analysis when navigating to another plan', async () => {
    const planId = ref(11)
    const state = usePlanAnalysis(planId, ref(4), ref(false))
    await state.activate()

    planId.value = 12
    await nextTick()

    expect(state.result.value).toBeNull()
    expect(state.selectedDayId.value).toBeNull()
  })
})
