import { describe, expect, it, vi } from 'vitest'

import { atlasApi } from '@/api/atlas'
import type { MuscleListItem, MuscleListResponse } from '@/api/types'
import { setActiveLocale } from '@/i18n'
import { useAtlasStore } from '@/stores/atlas'

vi.mock('@/api/atlas', () => ({
  atlasApi: {
    meta: vi.fn(),
    muscles: vi.fn(),
  },
}))

function muscle(displayName: string): MuscleListItem {
  return {
    slug: 'deltoid_posterior',
    name: 'Deltoid posterior',
    display_name: displayName,
    body_part: 'Upper',
    complex: 'Shoulder',
    mass_g: 1,
    mv_cm3: 1,
    fiber_bias_type_i: 0.5,
    fiber_bias_type_ii: 0.5,
    pcsa_projected_fcsa_cm2: 24.5,
    image_url: null,
  }
}

function response(item: MuscleListItem): MuscleListResponse {
  return {
    items: [item],
    total: 1,
    page: 1,
    per_page: 100,
    facets: { body_part: {}, complex: {} },
  }
}

describe('locale-aware Atlas muscle capacities', () => {
  it('reloads the translated muscle records when the active locale changes', async () => {
    vi.mocked(atlasApi.muscles)
      .mockResolvedValueOnce(response(muscle('Posterior deltoid')))
      .mockResolvedValueOnce(response(muscle('Mięsień naramienny — akton tylny')))
    const store = useAtlasStore()

    await setActiveLocale('en', { persist: false })
    await store.loadCapacities()
    expect(store.capacityMuscles[0]?.display_name).toBe('Posterior deltoid')

    await setActiveLocale('pl', { persist: false })
    await store.loadCapacities()
    expect(store.capacityMuscles[0]?.display_name).toBe('Mięsień naramienny — akton tylny')
    expect(atlasApi.muscles).toHaveBeenCalledTimes(2)
    expect(atlasApi.muscles).toHaveBeenLastCalledWith({
      sort: 'name',
      order: 'asc',
      page: 1,
      per_page: 100,
    })
  })
})
