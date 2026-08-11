<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{ page: number; perPage: number; total: number }>()
const emit = defineEmits<{ change: [page: number] }>()
const pageCount = computed(() => Math.max(1, Math.ceil(props.total / props.perPage)))
const range = computed(() => {
  if (!props.total) return '0 entries'
  const first = (props.page - 1) * props.perPage + 1
  const last = Math.min(props.total, props.page * props.perPage)
  return `${first}–${last} of ${props.total}`
})
</script>

<template>
  <nav v-if="total > perPage" class="pagination" aria-label="Atlas pages">
    <span class="mono">{{ range }}</span>
    <button class="button" type="button" :disabled="page <= 1" @click="emit('change', page - 1)">Previous</button>
    <span>Page <strong>{{ page }}</strong> of {{ pageCount }}</span>
    <button class="button" type="button" :disabled="page >= pageCount" @click="emit('change', page + 1)">Next</button>
  </nav>
</template>
