<script setup lang="ts">
import type { LoadingMode } from '@/api/plan-types'
import { useI18n } from 'vue-i18n'
import {
  LOADING_MODES,
  loadingModeShortLabel,
} from '@/features/plans/editor'

const model = defineModel<LoadingMode[] | null>({ required: true })
const props = withDefaults(defineProps<{
  fallbackMode: LoadingMode
  compact?: boolean
}>(), { compact: false })
const { t } = useI18n()

function loadingModeLabel(mode: LoadingMode): string {
  return t(`plans.loadingModes.${mode}`)
}

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
      ↻ {{ compact ? $t('plans.loadingCycle.cycle') : $t('plans.loadingCycle.add') }}
    </button>
    <template v-else>
      <div class="loading-cycle-heading">
        <span>
          {{ $t('plans.loadingCycle.cycle') }}
          <b class="mono">{{ model.map(loadingModeShortLabel).join('·') }}</b>
        </span>
        <button type="button" :title="compact ? $t('plans.loadingCycle.useStaticTitle') : undefined" @click="disable">
          {{ compact ? '×' : $t('plans.loadingCycle.useStatic') }}
        </button>
      </div>
      <div class="loading-cycle-steps">
        <label v-for="(mode, index) in model" :key="index">
          <span class="mono">µ{{ index + 1 }}</span>
          <select :value="mode" :aria-label="$t('plans.loadingCycle.microcycleMode', { number: index + 1 })" @change="updateStep(index, $event)">
            <option v-for="option in LOADING_MODES" :key="option" :value="option">
              {{ compact ? loadingModeShortLabel(option) : loadingModeLabel(option) }}
            </option>
          </select>
          <button
            type="button"
            :disabled="model.length <= 2"
            :aria-label="$t('plans.loadingCycle.removeStep', { number: index + 1 })"
            @click="removeStep(index)"
          >×</button>
        </label>
        <button
          class="loading-cycle-add"
          type="button"
          :disabled="model.length >= 52"
          @click="addStep"
        >
          {{ $t('plans.loadingCycle.addStep') }}
        </button>
      </div>
      <small v-if="!compact">{{ $t('plans.loadingCycle.repeats', { count: model.length }) }}</small>
    </template>
  </div>
</template>
