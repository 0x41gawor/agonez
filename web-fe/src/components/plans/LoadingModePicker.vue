<script setup lang="ts">
import type { LoadingMode } from '@/api/plan-types'
import {
  LOADING_MODES,
  loadingModeLabel,
  loadingModeShortLabel,
} from '@/features/plans/editor'

defineProps<{ compact?: boolean }>()
const model = defineModel<LoadingMode>({ required: true })
const emit = defineEmits<{ select: [mode: LoadingMode] }>()

function select(mode: LoadingMode): void {
  model.value = mode
  emit('select', mode)
}
</script>

<template>
  <div class="loading-mode-picker" :class="{ compact }" role="radiogroup" aria-label="Loading mode">
    <button
      v-for="mode in LOADING_MODES"
      :key="mode"
      type="button"
      role="radio"
      :aria-checked="model === mode"
      :aria-label="loadingModeLabel(mode)"
      :title="loadingModeLabel(mode)"
      :class="[`loading-${mode}`, { active: model === mode }]"
      @click="select(mode)"
    >
      <i aria-hidden="true" />
      {{ compact ? loadingModeShortLabel(mode) : loadingModeLabel(mode).replace(' load', '') }}
    </button>
  </div>
</template>
