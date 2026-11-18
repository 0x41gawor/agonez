<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'

import type { LoadingMode } from '@/api/plan-types'
import { useDismissablePopover } from '@/composables/useDismissablePopover'
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
const { open, setRoot, toggle, close } = useDismissablePopover()

const pattern = computed(() => (model.value ?? []).map(loadingModeShortLabel).join('·'))

function loadingModeLabel(mode: LoadingMode): string {
  return t(`plans.loadingModes.${mode}`)
}

function enable(): void {
  model.value = [props.fallbackMode, props.fallbackMode]
  if (props.compact) open.value = true
}

function disable(): void {
  model.value = null
  close()
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
  <div :ref="setRoot" class="loading-cycle-editor" :class="{ compact }">
    <button
      v-if="!model"
      class="loading-cycle-toggle"
      type="button"
      @click="enable"
    >
      ↻ {{ compact ? $t('plans.loadingCycle.cycle') : $t('plans.loadingCycle.add') }}
    </button>

    <!--
      A cycle may hold up to 52 microcycles. Beside a set there is no room to lay that
      out, and laying it out anyway is what made every set row grow with its cycle, so
      the steps live behind the pattern they produce.
    -->
    <template v-else-if="compact">
      <button
        class="loading-cycle-trigger"
        type="button"
        :aria-expanded="open"
        :aria-haspopup="true"
        :aria-label="$t('plans.loadingCycle.cycle')"
        :title="$t('plans.loadingCycle.repeats', { count: model.length })"
        @click="toggle"
      >
        <span aria-hidden="true">↻</span>
        <b class="mono">{{ pattern }}</b>
      </button>

      <div v-if="open" class="loading-cycle-popover" role="dialog" :aria-label="$t('plans.loadingCycle.cycle')">
        <div class="loading-cycle-heading">
          <span>{{ $t('plans.loadingCycle.repeats', { count: model.length }) }}</span>
          <button type="button" @click="disable">{{ $t('plans.loadingCycle.useStatic') }}</button>
        </div>
        <div class="loading-cycle-steps">
          <label v-for="(mode, index) in model" :key="index">
            <span class="mono">µ{{ index + 1 }}</span>
            <select :value="mode" :aria-label="$t('plans.loadingCycle.microcycleMode', { number: index + 1 })" @change="updateStep(index, $event)">
              <option v-for="option in LOADING_MODES" :key="option" :value="option">
                {{ loadingModeLabel(option) }}
              </option>
            </select>
            <button
              type="button"
              :disabled="model.length <= 2"
              :aria-label="$t('plans.loadingCycle.removeStep', { number: index + 1 })"
              @click="removeStep(index)"
            >×</button>
          </label>
        </div>
        <button
          class="loading-cycle-add"
          type="button"
          :disabled="model.length >= 52"
          @click="addStep"
        >
          {{ $t('plans.loadingCycle.addStep') }}
        </button>
      </div>
    </template>

    <template v-else>
      <div class="loading-cycle-heading">
        <span>
          {{ $t('plans.loadingCycle.cycle') }}
          <b class="mono">{{ pattern }}</b>
        </span>
        <button type="button" @click="disable">{{ $t('plans.loadingCycle.useStatic') }}</button>
      </div>
      <div class="loading-cycle-steps">
        <label v-for="(mode, index) in model" :key="index">
          <span class="mono">µ{{ index + 1 }}</span>
          <select :value="mode" :aria-label="$t('plans.loadingCycle.microcycleMode', { number: index + 1 })" @change="updateStep(index, $event)">
            <option v-for="option in LOADING_MODES" :key="option" :value="option">
              {{ loadingModeLabel(option) }}
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
      <small>{{ $t('plans.loadingCycle.repeats', { count: model.length }) }}</small>
    </template>
  </div>
</template>
