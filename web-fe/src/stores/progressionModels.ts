import { ref } from 'vue'
import { defineStore } from 'pinia'

import { plansApi } from '@/api/plans'
import type { ProgressionModelCatalogItem } from '@/api/plan-types'
import { activeLocale, type SupportedLocale } from '@/i18n'

export const useProgressionModelStore = defineStore('progression-models', () => {
  const items = ref<ProgressionModelCatalogItem[]>([])
  const loading = ref(false)
  const error = ref<Error | null>(null)
  const loadedLocale = ref<SupportedLocale | null>(null)
  let pending: Promise<void> | null = null
  let pendingLocale: SupportedLocale | null = null

  async function load(force = false): Promise<void> {
    const requestedLocale = activeLocale()
    if (!force && loadedLocale.value === requestedLocale) return
    if (pending && pendingLocale === requestedLocale) return pending

    pendingLocale = requestedLocale
    loading.value = true
    error.value = null
    pending = (async () => {
      try {
        const result = await plansApi.progressionModels()
        if (activeLocale() !== requestedLocale) return
        items.value = result.items
        loadedLocale.value = requestedLocale
      } catch (caught) {
        if (activeLocale() === requestedLocale) {
          error.value = caught instanceof Error ? caught : new Error('Progression catalog unavailable')
        }
      } finally {
        if (pendingLocale === requestedLocale) {
          loading.value = false
          pending = null
          pendingLocale = null
        }
      }
    })()
    return pending
  }

  return { items, loading, error, loadedLocale, load }
})
