import { ref } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import { ApiError } from '@/api/client'
import { atlasApi } from '@/api/atlas'
import { plansApi } from '@/api/plans'
import { usePlanDraft } from '@/composables/usePlanDraft'
import { exercise, muscle, planArtifact } from './fixtures/plans'

vi.mock('@/api/plans', () => ({
  plansApi: {
    draft: vi.fn(),
    saveDraft: vi.fn(),
  },
}))

vi.mock('@/api/atlas', () => ({
  atlasApi: {
    exercises: vi.fn(),
    muscles: vi.fn(),
  },
}))

describe('usePlanDraft save orchestration', () => {
  beforeEach(() => {
    vi.mocked(plansApi.draft).mockReset()
    vi.mocked(plansApi.saveDraft).mockReset()
    vi.mocked(atlasApi.exercises).mockReset()
    vi.mocked(atlasApi.muscles).mockReset()
    vi.mocked(plansApi.draft).mockResolvedValue(planArtifact())
    vi.mocked(atlasApi.exercises).mockResolvedValue({
      items: [exercise], total: 1, page: 1, per_page: 100,
      facets: { body_part: {}, target_category: {}, mechanics_tier: {}, resistance_source: {} },
    })
    vi.mocked(atlasApi.muscles).mockResolvedValue({
      items: [muscle], total: 1, page: 1, per_page: 100,
      facets: { body_part: {}, complex: {} },
    })
  })

  it('replaces editor state with the successful server response and new lock version', async () => {
    const state = usePlanDraft(ref(11))
    await state.load()
    state.draft.value!.name = 'Edited plan'
    vi.mocked(plansApi.saveDraft).mockImplementation(async (_planId, payload) => ({
      ...payload,
      lock_version: payload.lock_version + 1,
    }))

    expect(state.dirty.value).toBe(true)
    expect(await state.save()).toBe(true)
    expect(state.draft.value?.lock_version).toBe(5)
    expect(state.draft.value?.name).toBe('Edited plan')
    expect(state.dirty.value).toBe(false)
  })

  it('keeps local edits and exposes a conflict instead of silently overwriting', async () => {
    const state = usePlanDraft(ref(11))
    await state.load()
    state.draft.value!.name = 'Unsaved local name'
    vi.mocked(plansApi.saveDraft).mockRejectedValue(
      new ApiError('Draft changed', 409, { current_lock_version: 5 }),
    )

    expect(await state.save()).toBe(false)
    expect(state.conflict.value).toBe(true)
    expect(state.draft.value?.name).toBe('Unsaved local name')
    expect(state.draft.value?.lock_version).toBe(4)
    expect(state.dirty.value).toBe(true)
  })
})
