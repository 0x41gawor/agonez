<script setup lang="ts">
import { computed, onBeforeUnmount, watch, shallowRef, ref } from 'vue'
import { storeToRefs } from 'pinia'
import { useRoute, useRouter, type LocationQueryRaw } from 'vue-router'

import { atlasApi } from '@/api/atlas'
import type { ExerciseDetail, ExerciseListQuery, ExerciseListResponse, MuscleListQuery, MuscleListResponse } from '@/api/types'
import AnatomyPanel from '@/components/anatomy/AnatomyPanel.vue'
import AtlasCardGrid from '@/components/atlas/AtlasCardGrid.vue'
import AtlasPagination from '@/components/atlas/AtlasPagination.vue'
import AtlasToolbar, { type FilterGroup } from '@/components/atlas/AtlasToolbar.vue'
import ExerciseTable from '@/components/atlas/ExerciseTable.vue'
import MuscleTable from '@/components/atlas/MuscleTable.vue'
import ErrorState from '@/components/common/ErrorState.vue'
import LoadingRows from '@/components/common/LoadingRows.vue'
import { useDebouncedValue } from '@/composables/useDebouncedValue'
import { useAtlasStore } from '@/stores/atlas'
import { exerciseVector, normalizeVector, type VisualizationMode } from '@/utils/vectors'

const props = defineProps<{ kind: 'exercises' | 'muscles' }>()
const route = useRoute()
const router = useRouter()
const atlas = useAtlasStore()
const { hoverExercise, hoverMuscle } = storeToRefs(atlas)

const response = shallowRef<ExerciseListResponse | MuscleListResponse | null>(null)
const loading = ref(true)
const error = ref<Error | null>(null)
const hoverVector = ref<Record<string, number> | null>(null)
const hoverMode = ref<VisualizationMode>('etu')
const hoverVectorLoading = ref(false)
const exerciseCache = new Map<string, ExerciseDetail>()
let listController: AbortController | null = null
let hoverTimer: ReturnType<typeof setTimeout> | undefined

const exerciseBrowse = atlas.exerciseBrowse
const muscleBrowse = atlas.muscleBrowse
const browse = computed(() => (props.kind === 'exercises' ? exerciseBrowse : muscleBrowse))
const searchSource = computed({ get: () => browse.value.search, set: (value: string) => { browse.value.search = value } })
const debouncedSearch = useDebouncedValue(searchSource, 250)

function routeValues(value: unknown): string[] {
  if (Array.isArray(value)) return value.filter((entry): entry is string => typeof entry === 'string')
  return typeof value === 'string' ? [value] : []
}

function hydrateFromRoute(): void {
  const target = browse.value
  if (typeof route.query.q === 'string') target.search = route.query.q
  if (typeof route.query.sort === 'string') target.sort = route.query.sort as typeof target.sort
  if (route.query.order === 'desc' || route.query.order === 'asc') target.order = route.query.order
  if (route.query.view === 'grid' || route.query.view === 'list') target.view = route.query.view
  const page = Number(route.query.page)
  if (Number.isInteger(page) && page > 0) target.page = page
  for (const key of Object.keys(target.filters)) {
    const values = routeValues(route.query[key])
    if (values.length) (target.filters as Record<string, string[]>)[key] = values
  }
}

hydrateFromRoute()

const requestKey = computed(() => JSON.stringify({
  kind: props.kind,
  search: debouncedSearch.value,
  filters: browse.value.filters,
  sort: browse.value.sort,
  order: browse.value.order,
  page: browse.value.page,
}))

async function loadList(): Promise<void> {
  listController?.abort()
  listController = new AbortController()
  loading.value = true
  error.value = null
  try {
    if (props.kind === 'exercises') {
      const query: ExerciseListQuery = {
        ...exerciseBrowse.filters,
        sort: exerciseBrowse.sort,
        order: exerciseBrowse.order,
        page: exerciseBrowse.page,
        per_page: 50,
      }
      if (debouncedSearch.value) query.q = debouncedSearch.value
      response.value = await atlasApi.exercises(query, listController.signal)
    } else {
      const query: MuscleListQuery = {
        ...muscleBrowse.filters,
        sort: muscleBrowse.sort,
        order: muscleBrowse.order,
        page: muscleBrowse.page,
        per_page: 50,
      }
      if (debouncedSearch.value) query.q = debouncedSearch.value
      response.value = await atlasApi.muscles(query, listController.signal)
    }
  } catch (caught) {
    if ((caught as Error).name !== 'AbortError') error.value = caught instanceof Error ? caught : new Error('Atlas data is unavailable.')
  } finally {
    if (!listController.signal.aborted) loading.value = false
  }
}

watch(requestKey, () => void loadList(), { immediate: true })

watch(
  () => [browse.value.search, browse.value.filters, browse.value.sort, browse.value.order, browse.value.view, browse.value.page] as const,
  () => {
    const target = browse.value
    const query: LocationQueryRaw = {}
    if (target.search) query.q = target.search
    for (const [key, values] of Object.entries(target.filters)) if (values.length) query[key] = values
    if (target.sort !== 'name') query.sort = target.sort
    if (target.order !== 'asc') query.order = target.order
    if (target.view !== 'list') query.view = target.view
    if (target.page > 1) query.page = String(target.page)
    if (route.query.theme === 'dark' || route.query.theme === 'light') query.theme = route.query.theme
    void router.replace({ query })
  },
  { deep: true },
)

watch(() => props.kind, () => {
  atlas.clearHover()
  hoverVector.value = null
  hydrateFromRoute()
})

watch(hoverExercise, (slug) => {
  clearTimeout(hoverTimer)
  hoverVector.value = null
  if (!slug || props.kind !== 'exercises') return
  hoverVectorLoading.value = true
  hoverTimer = setTimeout(async () => {
    try {
      await atlas.loadCapacities()
      let detail = exerciseCache.get(slug)
      if (!detail) {
        detail = await atlasApi.exercise(slug)
        exerciseCache.set(slug, detail)
      }
      const etu = exerciseVector(detail, 'etu')
      const raw = etu ?? exerciseVector(detail, 'propulsive')
      hoverMode.value = etu ? 'etu' : 'propulsive'
      hoverVector.value = raw ? normalizeVector(raw, atlas.capacities) : null
    } catch {
      hoverVector.value = null
    } finally {
      hoverVectorLoading.value = false
    }
  }, 120)
})

onBeforeUnmount(() => {
  listController?.abort()
  clearTimeout(hoverTimer)
  atlas.clearHover()
})

const exerciseResponse = computed(() => props.kind === 'exercises' ? response.value as ExerciseListResponse | null : null)
const muscleResponse = computed(() => props.kind === 'muscles' ? response.value as MuscleListResponse | null : null)
const total = computed(() => response.value?.total ?? 0)
const exerciseCount = computed(() => atlas.meta?.counts.exercises ?? (props.kind === 'exercises' ? total.value : 0))
const muscleCount = computed(() => atlas.meta?.counts.muscles ?? (props.kind === 'muscles' ? total.value : 0))
const maximumDemand = computed(() => Math.max(1, ...(exerciseResponse.value?.items.map((item) => item.systemic_propulsive_fcsa_demand ?? 0) ?? [])))
const maximumMass = computed(() => Math.max(1, ...(muscleResponse.value?.items.map((item) => item.mass_g) ?? [])))
const maximumCapacity = computed(() => Math.max(1, ...(muscleResponse.value?.items.map((item) => item.pcsa_projected_fcsa_cm2 ?? 0) ?? [])))

const filterGroups = computed<FilterGroup[]>(() => {
  if (props.kind === 'exercises') {
    const facets = exerciseResponse.value?.facets
    return [
      { key: 'body_part', label: 'Body part', options: Object.entries(facets?.body_part ?? {}).map(([value, count]) => ({ value, count })) },
      { key: 'target_category', label: 'Target category', options: Object.entries(facets?.target_category ?? {}).map(([value, count]) => ({ value, count })) },
      { key: 'mechanics_tier', label: 'Mechanics tier', options: Object.entries(facets?.mechanics_tier ?? {}).map(([value, count]) => ({ value, count })) },
      { key: 'resistance_source', label: 'Resistance', options: Object.entries(facets?.resistance_source ?? {}).map(([value, count]) => ({ value, count })) },
    ]
  }
  const facets = muscleResponse.value?.facets
  return [
    { key: 'body_part', label: 'Body part', options: Object.entries(facets?.body_part ?? {}).map(([value, count]) => ({ value, count })) },
    { key: 'complex', label: 'Complex', options: Object.entries(facets?.complex ?? {}).map(([value, count]) => ({ value, count })) },
  ]
})

const sortOptions = computed(() => props.kind === 'exercises' ? [
  { value: 'name', label: 'Name' }, { value: 'name_full', label: 'Full name' },
  { value: 'load_capacity', label: 'Load capacity' }, { value: 'systemic_propulsive_fcsa_demand', label: 'FCSA demand' },
  { value: 'created_at', label: 'Date added' }, { value: 'updated_at', label: 'Date modified' },
] : [
  { value: 'name', label: 'Name' }, { value: 'mass_g', label: 'Mass' }, { value: 'mv_cm3', label: 'Volume' },
  { value: 'fiber_bias_type_ii', label: 'Type II bias' }, { value: 'pcsa_fiber_cm2', label: 'PCSA (fiber)' },
  { value: 'pcsa_projected_fcsa_cm2', label: 'Projected FCSA' },
])

const anatomyStatus = computed(() => {
  if (props.kind === 'exercises' && hoverExercise.value) {
    const item = exerciseResponse.value?.items.find((entry) => entry.slug === hoverExercise.value)
    if (hoverVectorLoading.value) return `${item?.name ?? hoverExercise.value} — loading modeled exposure…`
    if (hoverVector.value) return `${item?.name ?? hoverExercise.value} — ${hoverMode.value === 'etu' ? 'modeled training-stimulus exposure' : 'propulsive contribution (ETU pending)'}, normalized per muscle capacity.`
    return `${item?.name ?? hoverExercise.value} — no muscle vector evaluated yet.`
  }
  if (props.kind === 'muscles' && hoverMuscle.value) {
    const item = muscleResponse.value?.items.find((entry) => entry.slug === hoverMuscle.value)
    return item ? `${item.display_name} — ${item.body_part} body · ${item.complex.replaceAll('_', ' ')} complex` : hoverMuscle.value
  }
  return 'Hover an entry to preview it on the body. Select any muscle to open it.'
})

function updateSearch(value: string): void { browse.value.search = value; browse.value.page = 1 }
function updateFilters(value: Record<string, string[]>): void { Object.assign(browse.value.filters, value); browse.value.page = 1 }
function updateSort(value: string): void { browse.value.sort = value as typeof browse.value.sort; browse.value.page = 1 }
function updateView(value: 'list' | 'grid'): void {
  browse.value.view = value
  localStorage.setItem(props.kind === 'exercises' ? 'agonez-exercise-view' : 'agonez-muscle-view', value)
}
</script>

<template>
  <div class="page-wrap atlas-index">
    <AtlasToolbar
      :kind="kind"
      :exercise-count="exerciseCount"
      :muscle-count="muscleCount"
      :search="browse.search"
      :filters="browse.filters"
      :filter-groups="filterGroups"
      :sort="browse.sort"
      :sort-options="sortOptions"
      :order="browse.order"
      :view="browse.view"
      @update:search="updateSearch"
      @update:filters="updateFilters"
      @update:sort="updateSort"
      @update:order="browse.order = $event; browse.page = 1"
      @update:view="updateView"
    />

    <div class="atlas-split">
      <section class="atlas-results" :aria-label="kind">
        <LoadingRows v-if="loading && !response" />
        <ErrorState v-else-if="error" :message="error.message" @retry="loadList" />
        <div v-else-if="response && !response.items.length" class="inline-state">
          <h2>No entries match</h2><p>Adjust the search or remove one or more filters.</p>
          <button class="button" type="button" @click="updateSearch(''); updateFilters(Object.fromEntries(Object.keys(browse.filters).map((key) => [key, []])))">Clear filters</button>
        </div>
        <template v-else-if="response">
          <ExerciseTable
            v-if="kind === 'exercises' && browse.view === 'list'"
            :items="exerciseResponse?.items ?? []"
            :maximum-demand="maximumDemand"
            :hovered="hoverExercise"
            @hover="hoverExercise = $event"
          />
          <MuscleTable
            v-else-if="kind === 'muscles' && browse.view === 'list'"
            :items="muscleResponse?.items ?? []"
            :maximum-mass="maximumMass"
            :maximum-capacity="maximumCapacity"
            :hovered="hoverMuscle"
            @hover="hoverMuscle = $event"
          />
          <AtlasCardGrid
            v-else
            :kind="kind"
            :exercise-items="exerciseResponse?.items ?? []"
            :muscle-items="muscleResponse?.items ?? []"
            :hovered="kind === 'exercises' ? hoverExercise : hoverMuscle"
            @hover="kind === 'exercises' ? hoverExercise = $event : hoverMuscle = $event"
          />
          <AtlasPagination :page="response.page" :per-page="response.per_page" :total="response.total" @change="browse.page = $event" />
        </template>
      </section>

      <AnatomyPanel
        :selected-slug="kind === 'muscles' ? hoverMuscle : null"
        :vector="kind === 'exercises' ? hoverVector : null"
        :mode="hoverMode"
        :status="anatomyStatus"
        :legend-title="hoverMode === 'etu' ? 'ETU exposure' : 'Propulsive contribution'"
        @hover="kind === 'muscles' ? hoverMuscle = $event : undefined"
      />
    </div>
  </div>
</template>
