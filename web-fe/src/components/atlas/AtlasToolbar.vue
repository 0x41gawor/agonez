<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'

export interface FilterGroup {
  key: string
  label: string
  options: Array<{ value: string; count: number }>
}

const props = defineProps<{
  kind: 'exercises' | 'muscles'
  exerciseCount: number
  muscleCount: number
  search: string
  filters: Record<string, string[]>
  filterGroups: FilterGroup[]
  sort: string
  sortOptions: Array<{ value: string; label: string }>
  order: 'asc' | 'desc'
  view: 'list' | 'grid'
}>()

const emit = defineEmits<{
  'update:search': [value: string]
  'update:filters': [value: Record<string, string[]>]
  'update:sort': [value: string]
  'update:order': [value: 'asc' | 'desc']
  'update:view': [value: 'list' | 'grid']
}>()

const router = useRouter()
const open = ref(false)
const filterRoot = ref<HTMLElement | null>(null)
const activeFilters = computed(() => Object.values(props.filters).flat())

function toggleFilter(key: string, value: string): void {
  const next = Object.fromEntries(Object.entries(props.filters).map(([field, values]) => [field, [...values]]))
  const values = next[key] ?? []
  next[key] = values.includes(value) ? values.filter((entry) => entry !== value) : [...values, value]
  emit('update:filters', next)
}

function clearFilters(): void {
  emit('update:filters', Object.fromEntries(Object.keys(props.filters).map((key) => [key, []])))
  emit('update:search', '')
}

function removeFilter(value: string): void {
  const next = Object.fromEntries(
    Object.entries(props.filters).map(([key, values]) => [key, values.filter((entry) => entry !== value)]),
  )
  emit('update:filters', next)
}

function onDocumentClick(event: MouseEvent): void {
  if (open.value && !filterRoot.value?.contains(event.target as Node)) open.value = false
}

function onDocumentKey(event: KeyboardEvent): void {
  if (event.key === 'Escape') open.value = false
}

onMounted(() => {
  document.addEventListener('click', onDocumentClick)
  document.addEventListener('keydown', onDocumentKey)
})
onBeforeUnmount(() => {
  document.removeEventListener('click', onDocumentClick)
  document.removeEventListener('keydown', onDocumentKey)
})
</script>

<template>
  <div class="atlas-toolbar">
    <div class="atlas-tabs" role="tablist" :aria-label="$t('atlas.collection')">
      <button
        type="button"
        role="tab"
        :aria-selected="kind === 'exercises'"
        :class="{ active: kind === 'exercises' }"
        @click="router.push({ name: 'exercises' })"
      >
        {{ $t('atlas.exercises') }} <span class="mono">{{ exerciseCount }}</span>
      </button>
      <button
        type="button"
        role="tab"
        :aria-selected="kind === 'muscles'"
        :class="{ active: kind === 'muscles' }"
        @click="router.push({ name: 'muscles' })"
      >
        {{ $t('atlas.muscles') }} <span class="mono">{{ muscleCount }}</span>
      </button>
    </div>

    <label class="search-field">
      <span class="sr-only">{{ $t('atlas.search', { kind: $t(`atlas.${kind}`) }) }}</span>
      <input
        type="search"
        :value="search"
        :placeholder="$t('atlas.searchPlaceholder', { kind: $t(`atlas.${kind}`).toLowerCase() })"
        @input="emit('update:search', ($event.target as HTMLInputElement).value)"
      />
    </label>

    <div ref="filterRoot" class="filter-root">
      <button class="button" :class="{ active: open }" type="button" :aria-expanded="open" @click.stop="open = !open">
        {{ $t('atlas.filter') }} <span v-if="activeFilters.length" class="filter-count mono">{{ activeFilters.length }}</span>
      </button>
      <div v-if="open" class="filter-popover panel">
        <section v-for="group in filterGroups" :key="group.key">
          <h3>{{ group.label }}</h3>
          <label v-for="option in group.options" :key="option.value">
            <input
              type="checkbox"
              :checked="filters[group.key]?.includes(option.value)"
              @change="toggleFilter(group.key, option.value)"
            />
            <span>{{ $te(`tokens.${option.value}`) ? $t(`tokens.${option.value}`) : option.value.replaceAll('_', ' ') }}</span>
            <small class="mono">{{ option.count }}</small>
          </label>
        </section>
        <button class="filter-close" type="button" :aria-label="$t('atlas.closeFilters')" @click="open = false">×</button>
      </div>
    </div>

    <div class="sort-control">
      <span>{{ $t('atlas.sort') }}</span>
      <select :value="sort" :aria-label="$t('atlas.sortBy')" @change="emit('update:sort', ($event.target as HTMLSelectElement).value)">
        <option v-for="option in sortOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
      </select>
      <button class="icon-button mono" type="button" :aria-label="$t('atlas.reverseSort')" @click="emit('update:order', order === 'asc' ? 'desc' : 'asc')">
        {{ order === 'asc' ? '↑' : '↓' }}
      </button>
    </div>

    <div class="toolbar-spacer" />
    <div class="view-control" :aria-label="$t('atlas.displayStyle')">
      <button type="button" :class="{ active: view === 'list' }" :aria-pressed="view === 'list'" @click="emit('update:view', 'list')">{{ $t('atlas.list') }}</button>
      <button type="button" :class="{ active: view === 'grid' }" :aria-pressed="view === 'grid'" @click="emit('update:view', 'grid')">{{ $t('atlas.grid') }}</button>
    </div>
  </div>

  <div v-if="activeFilters.length" class="active-chips">
    <button v-for="value in activeFilters" :key="value" class="chip" type="button" @click="removeFilter(value)">
      {{ $te(`tokens.${value}`) ? $t(`tokens.${value}`) : value.replaceAll('_', ' ') }} <span>×</span>
    </button>
    <button class="button ghost" type="button" @click="clearFilters">{{ $t('atlas.clearAll') }}</button>
  </div>
</template>
