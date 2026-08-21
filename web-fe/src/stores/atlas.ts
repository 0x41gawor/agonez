import { computed, reactive, ref } from 'vue'
import { defineStore } from 'pinia'

import { atlasApi } from '@/api/atlas'
import type { AtlasMeta, ExerciseSort, MuscleListItem } from '@/api/types'

let metaRequest: Promise<AtlasMeta> | null = null
let capacityRequest: Promise<MuscleListItem[]> | null = null

export const useAtlasStore = defineStore('atlas', () => {
  const meta = ref<AtlasMeta | null>(null)
  const metaError = ref<Error | null>(null)
  const capacityMuscles = ref<MuscleListItem[]>([])
  const hoverExercise = ref<string | null>(null)
  const hoverMuscle = ref<string | null>(null)
  const exerciseBrowse = reactive({
    search: '',
    filters: { body_part: [] as string[], target_category: [] as string[], mechanics_tier: [] as string[], resistance_source: [] as string[] },
    sort: 'name' as ExerciseSort,
    order: 'asc' as 'asc' | 'desc',
    view: (localStorage.getItem('agonez-exercise-view') === 'grid' ? 'grid' : 'list') as 'list' | 'grid',
    page: 1,
  })
  const muscleBrowse = reactive({
    search: '',
    filters: { body_part: [] as string[], complex: [] as string[] },
    sort: 'name' as const as 'name' | 'mass_g' | 'mv_cm3' | 'fiber_bias_type_ii' | 'pcsa_fiber_cm2' | 'pcsa_projected_fcsa_cm2',
    order: 'asc' as 'asc' | 'desc',
    view: (localStorage.getItem('agonez-muscle-view') === 'grid' ? 'grid' : 'list') as 'list' | 'grid',
    page: 1,
  })

  const capacities = computed<Record<string, number | null>>(() =>
    Object.fromEntries(capacityMuscles.value.map((muscle) => [muscle.slug, muscle.pcsa_projected_fcsa_cm2])),
  )

  async function loadMeta(): Promise<void> {
    if (meta.value) return
    metaRequest ??= atlasApi.meta()
    try {
      meta.value = await metaRequest
      metaError.value = null
    } catch (error) {
      metaRequest = null
      metaError.value = error instanceof Error ? error : new Error('Atlas metadata is unavailable.')
    }
  }

  async function loadCapacities(): Promise<void> {
    if (capacityMuscles.value.length) return
    capacityRequest ??= atlasApi.muscles({ sort: 'name', order: 'asc', page: 1, per_page: 100 }).then((result) => result.items)
    try {
      capacityMuscles.value = await capacityRequest
    } catch (error) {
      capacityRequest = null
      throw error
    }
  }

  function clearHover(): void {
    hoverExercise.value = null
    hoverMuscle.value = null
  }

  return {
    meta,
    metaError,
    capacityMuscles,
    capacities,
    hoverExercise,
    hoverMuscle,
    exerciseBrowse,
    muscleBrowse,
    loadMeta,
    loadCapacities,
    clearHover,
  }
})
