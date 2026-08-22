<script setup lang="ts">
import { computed, ref } from 'vue'

import type { ExerciseListItem } from '@/api/types'

const props = defineProps<{
  modelValue: string
  exercises: ExerciseListItem[]
  label?: string
}>()
const emit = defineEmits<{ 'update:modelValue': [slug: string] }>()

const open = ref(false)
const query = ref('')
const current = computed(() => props.exercises.find((item) => item.slug === props.modelValue))
const filtered = computed(() => {
  const needle = query.value.trim().toLowerCase()
  if (!needle) return props.exercises.slice(0, 24)
  return props.exercises
    .filter((item) =>
      `${item.name} ${item.name_full} ${item.slug} ${item.resistance_source}`
        .toLowerCase()
        .includes(needle),
    )
    .slice(0, 24)
})
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
      :title="currentExerciseHref ? 'Click to choose an exercise · Ctrl/Cmd+click to open in Atlas' : 'Click to choose an exercise'"
      @click="handleTriggerClick"
    >
      <span class="exercise-selector-copy">
        <span class="exercise-selector-label">{{ label ?? 'Exercise' }}</span>
        <strong>{{ current?.name_full || current?.name || (modelValue ? modelValue.replaceAll('_', ' ') : 'Choose exercise') }}</strong>
        <small v-if="current">{{ current.resistance_source }} · {{ current.slug }}</small>
      </span>
      <span aria-hidden="true">{{ open ? '−' : '⌄' }}</span>
    </a>

    <div v-if="open" class="catalog-selector-panel">
      <label class="field-label" :for="`exercise-search-${label ?? 'exercise'}`">Find exercise</label>
      <input
        :id="`exercise-search-${label ?? 'exercise'}`"
        v-model="query"
        class="text-input"
        type="search"
        placeholder="Name, slug, or resistance…"
        autocomplete="off"
      />
      <div class="catalog-options" role="listbox" :aria-label="label ?? 'Exercise options'">
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
          <span>
            <strong>{{ exercise.name_full || exercise.name }}</strong>
            <small>{{ exercise.slug }}</small>
          </span>
          <span class="chip">{{ exercise.resistance_source }}</span>
        </button>
        <p v-if="!filtered.length" class="selector-empty">No catalog exercises match this search.</p>
      </div>
    </div>
  </div>
</template>
