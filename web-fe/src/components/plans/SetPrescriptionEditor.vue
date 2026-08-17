<script setup lang="ts">
import { computed } from 'vue'

import type { PlanValidationIssue } from '@/features/plans/editor'
import type { EditorSet } from '@/features/plans/editor'

const model = defineModel<EditorSet>({ required: true })
const props = defineProps<{
  index: number
  count: number
  path: string
  issues: PlanValidationIssue[]
}>()
defineEmits<{
  move: [direction: -1 | 1]
  remove: []
  duplicate: []
}>()

const error = computed(() => props.issues.find((issue) => issue.path === props.path)?.message)
</script>

<template>
  <div class="set-editor" :class="{ invalid: error }">
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
    <div class="ordered-actions" aria-label="Set actions">
      <button type="button" :disabled="index === 0" title="Move set up" @click="$emit('move', -1)">↑</button>
      <button type="button" :disabled="index === count - 1" title="Move set down" @click="$emit('move', 1)">↓</button>
      <button type="button" title="Duplicate set" @click="$emit('duplicate')">⧉</button>
      <button class="danger-action" type="button" title="Remove set" @click="$emit('remove')">×</button>
    </div>
    <p v-if="error" class="field-error">{{ error }}</p>
  </div>
</template>
