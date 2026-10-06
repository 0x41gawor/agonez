<script setup lang="ts">
import { computed, ref } from 'vue'

import type { EditorVariant, ExerciseUnitOption } from '@/features/plans/editor'
import { newProgressionId } from '@/features/plans/editor'

const model = defineModel<EditorVariant>({ required: true })
const props = defineProps<{ exerciseUnits: ExerciseUnitOption[] }>()
const open = ref(false)

const choices = computed(() => props.exerciseUnits.filter((item) => item.clientKey !== model.value.clientKey))
const sharedChoice = computed(() => choices.value.find(
  (item) => item.progressionId === model.value.progression_id,
))
const workingCount = computed(() => model.value.sets.filter((item) => item.role !== 'rampup').length)

function useOwnProgression(): void {
  if (!sharedChoice.value) return
  model.value.progression_id = newProgressionId()
}

function useSharedProgression(): void {
  const first = choices.value[0]
  if (first) model.value.progression_id = first.progressionId
}

function toggleVariableSets(enabled: boolean): void {
  if (!enabled) {
    model.value.active_working_sets = null
    return
  }
  model.value.active_working_sets = { min: workingCount.value, max: workingCount.value }
}
</script>

<template>
  <section class="exercise-unit-metadata" :class="{ open }">
    <button class="exercise-unit-metadata-toggle" type="button" :aria-expanded="open" @click="open = !open">
      <span>
        <small>{{ $t('plans.exerciseMetadata.eyebrow') }}</small>
        <strong>{{ $t('plans.exerciseMetadata.title') }}</strong>
      </span>
      <span class="exercise-unit-metadata-summary">
        {{ sharedChoice ? $t('plans.exerciseMetadata.shared') : $t('plans.exerciseMetadata.own') }}
        <template v-if="model.active_working_sets"> · {{ model.active_working_sets.min }}–{{ model.active_working_sets.max }} {{ $t('plans.exerciseMetadata.activeSets') }}</template>
      </span>
      <span aria-hidden="true">{{ open ? '−' : '+' }}</span>
    </button>

    <div v-if="open" class="exercise-unit-metadata-body">
      <div class="metadata-field">
        <span class="field-label">{{ $t('plans.exerciseMetadata.progressionLoop') }}</span>
        <div class="metadata-mode-switch">
          <button type="button" :class="{ active: !sharedChoice }" @click="useOwnProgression">
            {{ $t('plans.exerciseMetadata.own') }}
          </button>
          <button type="button" :class="{ active: sharedChoice }" :disabled="!choices.length" @click="useSharedProgression">
            {{ $t('plans.exerciseMetadata.shared') }}
          </button>
        </div>
        <select
          v-if="sharedChoice"
          v-model="model.progression_id"
          class="select-input"
          :aria-label="$t('plans.exerciseMetadata.shareWith')"
        >
          <option v-for="item in choices" :key="item.clientKey" :value="item.progressionId">
            {{ item.label }}
          </option>
        </select>
        <small>{{ $t('plans.exerciseMetadata.progressionLoopHelp') }}</small>
      </div>

      <div class="metadata-field active-working-sets-field">
        <label class="metadata-checkbox">
          <input
            type="checkbox"
            :checked="model.active_working_sets !== null"
            @change="toggleVariableSets(($event.target as HTMLInputElement).checked)"
          />
          <span>
            <strong>{{ $t('plans.exerciseMetadata.variableSets') }}</strong>
            <small>{{ $t('plans.exerciseMetadata.variableSetsHelp') }}</small>
          </span>
        </label>
        <div v-if="model.active_working_sets" class="active-set-range">
          <label>
            <span>{{ $t('plans.exerciseMetadata.minimum') }}</span>
            <input v-model.number="model.active_working_sets.min" type="number" min="0" :max="workingCount" />
          </label>
          <span aria-hidden="true">–</span>
          <label>
            <span>{{ $t('plans.exerciseMetadata.maximum') }}</span>
            <input v-model.number="model.active_working_sets.max" type="number" min="0" :max="workingCount" />
          </label>
          <small>{{ $t('plans.exerciseMetadata.workingAvailable', { count: workingCount }) }}</small>
        </div>
      </div>
    </div>
  </section>
</template>
