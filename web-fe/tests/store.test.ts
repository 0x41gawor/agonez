import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, describe, expect, it } from 'vitest'

import { useAtlasStore } from '@/stores/atlas'

describe('Atlas browse state', () => {
  beforeEach(() => setActivePinia(createPinia()))

  it('keeps exercise and muscle browsing state independent', () => {
    const store = useAtlasStore()
    store.exerciseBrowse.search = 'press'
    store.exerciseBrowse.filters.body_part.push('Upper')
    store.muscleBrowse.search = 'soleus'

    expect(store.exerciseBrowse.search).toBe('press')
    expect(store.exerciseBrowse.filters.body_part).toEqual(['Upper'])
    expect(store.muscleBrowse.search).toBe('soleus')
    expect(store.muscleBrowse.filters.body_part).toEqual([])
  })
})
