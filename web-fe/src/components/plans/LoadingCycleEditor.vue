<script setup lang="ts">
import type { LoadingMode } from '@/api/plan-types'
import {
  LOADING_MODES,
  loadingModeLabel,
  loadingModeShortLabel,
} from '@/features/plans/editor'

const model = defineModel<LoadingMode[] | null>({ required: true })
const props = withDefaults(defineProps<{
  fallbackMode: LoadingMode
  compact?: boolean
}>(), { compact: false })

function enable(): void {
  model.value = [props.fallbackMode, props.fallbackMode]
}

function disable(): void {
  model.value = null
}

function addStep(): void {
  if (!model.value || model.value.length >= 52) return
  model.value = [...model.value, model.value.at(-1) ?? props.fallbackMode]
}

function removeStep(index: number): void {
  if (!model.value || model.value.length <= 2) return
  model.value = model.value.filter((_, itemIndex) => itemIndex !== index)
}

function updateStep(index: number, event: Event): void {
  if (!model.value) return
  const next = [...model.value]
  next[index] = (event.target as HTMLSelectElement).value as LoadingMode
  model.value = next
}
</script>

<template>
  <div class="loading-cycle-editor" :class="{ compact }">
    <button
      v-if="!model"
      class="loading-cycle-toggle"
      type="button"
      @click="enable"
    >
      ↻ {{ compact ? 'Cycle' : 'Add cycle' }}
    </button>
    <template v-else>
      <div class="loading-cycle-heading">
        <span>
          Cycle
          <b class="mono">{{ model.map(loadingModeShortLabel).join('·') }}</b>
        </span>
        <button type="button" :title="compact ? 'Use static loading' : undefined" @click="disable">
          {{ compact ? '×' : 'Use static' }}
        </button>
      </div>
      <div class="loading-cycle-steps">
        <label v-for="(mode, index) in model" :key="index">
          <span class="mono">µ{{ index + 1 }}</span>
          <select :value="mode" :aria-label="`Microcycle ${index + 1} loading mode`" @change="updateStep(index, $event)">
            <option v-for="option in LOADING_MODES" :key="option" :value="option">
              {{ compact ? loadingModeShortLabel(option) : loadingModeLabel(option) }}
            </option>
          </select>
          <button
            type="button"
            :disabled="model.length <= 2"
            :aria-label="`Remove microcycle ${index + 1}`"
            @click="removeStep(index)"
          >×</button>
        </label>
        <button
          class="loading-cycle-add"
          type="button"
          :disabled="model.length >= 52"
          @click="addStep"
        >
          + Step
        </button>
      </div>
      <small v-if="!compact">Repeats every {{ model.length }} microcycles.</small>
    </template>
  </div>
</template>
