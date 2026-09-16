import { describe, expect, it, vi } from 'vitest'

import { atlasApi } from '@/api/atlas'
import { setActiveLocale } from '@/i18n'
import { useAtlasCatalogStore } from '@/stores/atlasCatalog'
import { exercise, muscle } from './fixtures/plans'

vi.mock('@/api/atlas', () => ({
  atlasApi: {
    exerciseCatalog: vi.fn(),
    muscles: vi.fn(),
  },
}))

describe('locale-aware Atlas catalog', () => {
  it('refetches translated catalog content without involving plan draft state', async () => {
    vi.mocked(atlasApi.exerciseCatalog)
      .mockResolvedValueOnce({ items: [exercise], total: 1 })
      .mockResolvedValueOnce({ items: [{ ...exercise, name: 'Wyciskanie' }], total: 1 })
    vi.mocked(atlasApi.muscles).mockResolvedValue({
      items: [muscle], total: 1, page: 1, per_page: 100,
      facets: { body_part: {}, complex: {} },
    })
    const store = useAtlasCatalogStore()

    await setActiveLocale('en', { persist: false })
    await store.load()
    expect(store.exercises[0]?.name).toBe(exercise.name)

    await setActiveLocale('pl', { persist: false })
    await store.load()
    expect(store.exercises[0]?.name).toBe('Wyciskanie')
    expect(atlasApi.exerciseCatalog).toHaveBeenCalledTimes(2)
  })
})
