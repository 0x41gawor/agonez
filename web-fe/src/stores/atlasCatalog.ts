import { ref } from 'vue'
import { defineStore } from 'pinia'

import { atlasApi } from '@/api/atlas'
import type { ExerciseCatalogItem, MuscleListItem } from '@/api/types'
import { activeLocale, i18n, type SupportedLocale } from '@/i18n'

export const useAtlasCatalogStore = defineStore('atlas-catalog', () => {
  const exercises = ref<ExerciseCatalogItem[]>([])
  const muscles = ref<MuscleListItem[]>([])
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
        const [exerciseResult, muscleResult] = await Promise.all([
          atlasApi.exerciseCatalog(),
          atlasApi.muscles({ page: 1, per_page: 100, sort: 'name', order: 'asc' }),
        ])
        if (activeLocale() !== requestedLocale) return
        exercises.value = exerciseResult.items
        muscles.value = muscleResult.items
        loadedLocale.value = requestedLocale
      } catch (caught) {
        if (activeLocale() === requestedLocale) {
          error.value = caught instanceof Error ? caught : new Error(i18n.global.t('errors.catalogUnavailable'))
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

  return { exercises, muscles, loading, error, loadedLocale, load }
})
