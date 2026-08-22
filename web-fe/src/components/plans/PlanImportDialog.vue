<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted } from 'vue'

import type { PlanAIImportDocument } from '@/api/plan-export-types'

const props = defineProps<{
  document: PlanAIImportDocument
  filename: string
  importing: boolean
  error: string | null
}>()
const emit = defineEmits<{ close: []; confirm: [] }>()

const exerciseCount = computed(() =>
  props.document.days.reduce((total, day) => total + day.exercises.length, 0),
)
const setCount = computed(() =>
  props.document.days.reduce(
    (dayTotal, day) =>
      dayTotal + day.exercises.reduce((exerciseTotal, exercise) => exerciseTotal + exercise.sets.length, 0),
    0,
  ),
)

function handleKeydown(event: KeyboardEvent): void {
  if (event.key === 'Escape' && !props.importing) emit('close')
}

onMounted(() => window.addEventListener('keydown', handleKeydown))
onBeforeUnmount(() => window.removeEventListener('keydown', handleKeydown))
</script>

<template>
  <div class="plan-export-backdrop" @click.self="!importing && $emit('close')">
    <section
      class="plan-export-dialog plan-import-dialog panel"
      role="dialog"
      aria-modal="true"
      aria-labelledby="plan-import-title"
    >
      <header>
        <div>
          <span class="eyebrow">JSON import</span>
          <h2 id="plan-import-title">Create “{{ document.plan_name }}”</h2>
          <p>{{ filename }} · validated locally</p>
        </div>
        <button
          class="plan-export-close"
          type="button"
          aria-label="Close import"
          :disabled="importing"
          @click="$emit('close')"
        >×</button>
      </header>

      <div class="plan-import-summary" aria-label="Import summary">
        <div><span>Days</span><strong class="mono">{{ document.days.length }}</strong></div>
        <div><span>Exercises</span><strong class="mono">{{ exerciseCount }}</strong></div>
        <div><span>Sets</span><strong class="mono">{{ setCount }}</strong></div>
        <div><span>Volume level</span><strong class="mono">{{ document.resolution_context.global_volume_level }}</strong></div>
      </div>

      <div class="plan-export-warning">
        <strong>Editor defaults are derived.</strong>
        <span>Per workout: exercise 1 becomes primary progressive, exercise 2 secondary progressive, and later exercises accessory.</span>
      </div>

      <div class="plan-import-days">
        <article v-for="day in document.days" :key="day.day">
          <span class="mono">D{{ String(day.day).padStart(2, '0') }}</span>
          <div>
            <strong>{{ day.name }}</strong>
            <small>{{ day.weekday ?? 'No weekday' }} · {{ day.rest ? 'Rest day' : `${day.exercises.length} exercises` }}</small>
          </div>
          <span class="mono">{{ day.exercises.reduce((total, exercise) => total + exercise.sets.length, 0) }} sets</span>
        </article>
        <p v-if="!document.days.length" class="selector-empty">This file creates an empty plan.</p>
      </div>

      <footer>
        <p v-if="error" role="alert">{{ error }}</p>
        <span v-else>The server will verify every exercise slug before creating anything.</span>
        <div>
          <button class="button" type="button" :disabled="importing" @click="$emit('close')">Cancel</button>
          <button class="button primary" type="button" :disabled="importing" @click="$emit('confirm')">
            {{ importing ? 'Importing…' : 'Import and open' }}
          </button>
        </div>
      </footer>
    </section>
  </div>
</template>
