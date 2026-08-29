<script setup lang="ts">
import { computed } from 'vue'

import type { LoadingMode } from '@/api/plan-types'
import LoadingCycleEditor from '@/components/plans/LoadingCycleEditor.vue'
import LoadingModePicker from '@/components/plans/LoadingModePicker.vue'
import {
  effectiveLoadingPattern,
  type EditorSet,
  type PlanValidationIssue,
} from '@/features/plans/editor'

const model = defineModel<EditorSet>({ required: true })
const props = defineProps<{
  index: number
  count: number
  path: string
  issues: PlanValidationIssue[]
  slotLoadingMode: LoadingMode
  slotLoadingCycle: LoadingMode[] | null
}>()
defineEmits<{
  move: [direction: -1 | 1]
  remove: []
  duplicate: []
}>()

const error = computed(() => props.issues.find((issue) => issue.path === props.path)?.message)
const effectivePattern = computed(() => effectiveLoadingPattern(
  props.slotLoadingMode,
  props.slotLoadingCycle,
  model.value.loading_mode,
  model.value.loading_cycle,
))
const visibleLoadingMode = computed<LoadingMode>({
  get: () => effectivePattern.value[0]!,
  set: (value) => {
    model.value.loading_mode = value
    model.value.loading_cycle = null
  },
})
</script>

<template>
  <div class="set-editor" :class="[{ invalid: error }, `loading-${effectivePattern[0]}`]">
    <span class="set-number mono">{{ index + 1 }}</span>
    <label>
      <span>Min reps</span>
      <input v-model.number="model.reps.min" type="number" min="1" max="32767" inputmode="numeric" />
    </label>
    <span class="set-range-separator" aria-hidden="true">–</span>
    <label>
      <span>Max reps</span>
      <input v-model.number="model.reps.max" type="number" min="1" max="32767" inputmode="numeric" />
    </label>
    <label>
      <span>RIR</span>
      <select v-model.number="model.rir">
        <option v-for="rir in [0, 1, 2, 3, 4]" :key="rir" :value="rir">{{ rir }}</option>
      </select>
    </label>
    <div class="set-loading-control">
      <span class="set-loading-label">Load</span>
      <LoadingModePicker v-model="visibleLoadingMode" compact />
      <LoadingCycleEditor
        v-model="model.loading_cycle"
        :fallback-mode="effectivePattern[0]!"
        compact
      />
    </div>
    <div class="ordered-actions" aria-label="Set actions">
      <button type="button" :disabled="index === 0" title="Move set up" @click="$emit('move', -1)">↑</button>
      <button type="button" :disabled="index === count - 1" title="Move set down" @click="$emit('move', 1)">↓</button>
      <button type="button" title="Duplicate set" @click="$emit('duplicate')">⧉</button>
      <button class="danger-action" type="button" title="Remove set" @click="$emit('remove')">×</button>
    </div>
    <p v-if="error" class="field-error">{{ error }}</p>
  </div>
</template>
