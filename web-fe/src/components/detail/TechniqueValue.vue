<script setup lang="ts">
import { computed } from 'vue'

import { prettyToken } from '@/utils/format'

defineOptions({ name: 'TechniqueValue' })

const props = defineProps<{ value: unknown }>()

const objectEntries = computed(() => {
  if (!props.value || typeof props.value !== 'object' || Array.isArray(props.value)) return []
  return Object.entries(props.value as Record<string, unknown>)
})
</script>

<template>
  <ul v-if="Array.isArray(value)" class="technique-value-list">
    <li v-for="(item, index) in value" :key="index"><TechniqueValue :value="item" /></li>
  </ul>
  <dl v-else-if="objectEntries.length" class="technique-value-nested">
    <div v-for="[key, nestedValue] in objectEntries" :key="key">
      <dt>{{ prettyToken(key) }}</dt>
      <dd><TechniqueValue :value="nestedValue" /></dd>
    </div>
  </dl>
  <p v-else>{{ value == null || value === '' ? '—' : String(value) }}</p>
</template>
