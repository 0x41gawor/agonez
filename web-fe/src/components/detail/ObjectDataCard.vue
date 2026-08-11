<script setup lang="ts">
import { computed } from 'vue'
import { prettyToken } from '@/utils/format'

const props = defineProps<{ title: string; data: Record<string, unknown>; emptyMessage: string }>()
const rows = computed(() => Object.entries(props.data).map(([key, value]) => ({
  key,
  label: prettyToken(key),
  value: typeof value === 'string' ? value : JSON.stringify(value),
})))
</script>

<template>
  <section class="object-card panel">
    <h2>{{ title }}</h2>
    <dl v-if="rows.length">
      <div v-for="row in rows" :key="row.key"><dt>{{ row.label }}</dt><dd>{{ row.value }}</dd></div>
    </dl>
    <p v-else class="honest-empty">{{ emptyMessage }}</p>
  </section>
</template>
