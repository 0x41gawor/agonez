<script setup lang="ts">
import { computed, ref } from 'vue'

import type { ExerciseCatalogItem } from '@/api/types'
import { ExerciseSearch } from '@/features/plans/exercise-search'
import { formatNumber, prettyToken } from '@/utils/format'

const props = defineProps<{
  modelValue: string
  exercises: ExerciseCatalogItem[]
  label?: string
}>()
const emit = defineEmits<{ 'update:modelValue': [slug: string] }>()

const open = ref(false)
const query = ref('')
const current = computed(() => props.exercises.find((item) => item.slug === props.modelValue))
const search = computed(() => new ExerciseSearch(props.exercises))
const filtered = computed(() => search.value.search(query.value))
const currentExerciseHref = computed(() =>
  current.value ? `/atlas/exercises/${encodeURIComponent(current.value.slug)}` : undefined,
)

function handleTriggerClick(event: MouseEvent): void {
  const modifiedClick =
    event.ctrlKey || event.metaKey || event.shiftKey || event.altKey || event.button !== 0
  if (currentExerciseHref.value && modifiedClick) return

  event.preventDefault()
  open.value = !open.value
}

function select(slug: string): void {
  emit('update:modelValue', slug)
  open.value = false
  query.value = ''
}
</script>

<template>
  <div class="catalog-selector exercise-selector">
    <a
      class="catalog-selector-trigger"
      :href="currentExerciseHref"
      role="button"
      :aria-expanded="open"
      :title="$t(currentExerciseHref ? 'plans.selector.triggerTitle' : 'plans.selector.emptyTriggerTitle')"
      @click="handleTriggerClick"
    >
      <span class="exercise-selector-copy">
        <span class="exercise-selector-label">{{ label ?? $t('plans.slot.exercise') }}</span>
        <strong>{{ current?.name_full || current?.name || (modelValue ? modelValue.replaceAll('_', ' ') : $t('plans.slot.chooseExercise')) }}</strong>
        <small v-if="current">{{ current.resistance_source }} · {{ current.slug }}</small>
      </span>
      <span class="exercise-selector-side">
        <span v-if="current" class="exercise-selector-facts">
          <span class="exercise-mechanics-tag">{{ prettyToken(current.mechanics_tier) }}</span>
          <span class="exercise-demand-tag mono">
            {{ $t('plans.selector.systemicFcsa', { value: formatNumber(current.systemic_propulsive_fcsa_demand, 0) }) }}
          </span>
        </span>
        <span class="exercise-selector-chevron" aria-hidden="true">{{ open ? '−' : '⌄' }}</span>
      </span>
    </a>

    <div v-if="open" class="catalog-selector-panel">
      <label class="field-label" :for="`exercise-search-${label ?? 'exercise'}`">{{ $t('plans.selector.find') }}</label>
      <input
        :id="`exercise-search-${label ?? 'exercise'}`"
        v-model="query"
        class="text-input"
        type="search"
        :placeholder="$t('plans.selector.placeholder')"
        autocomplete="off"
      />
      <div class="catalog-options" role="listbox" :aria-label="label ?? $t('plans.selector.options')">
        <button
          v-for="exercise in filtered"
          :key="exercise.slug"
          class="catalog-option"
          :class="{ selected: exercise.slug === modelValue }"
          type="button"
          role="option"
          :aria-selected="exercise.slug === modelValue"
          @click="select(exercise.slug)"
        >
          <span class="exercise-option-copy">
            <strong>{{ exercise.name_full || exercise.name }}</strong>
            <small>{{ exercise.resistance_source }} · {{ exercise.slug }}</small>
          </span>
          <span class="exercise-option-facts">
            <span class="exercise-mechanics-tag">{{ prettyToken(exercise.mechanics_tier) }}</span>
            <span class="exercise-option-demand mono">
              {{ $t('plans.selector.fcsa', { value: formatNumber(exercise.systemic_propulsive_fcsa_demand, 0) }) }}
            </span>
          </span>
        </button>
        <p v-if="!filtered.length" class="selector-empty">{{ $t('plans.selector.noMatches') }}</p>
      </div>
    </div>
  </div>
</template>
