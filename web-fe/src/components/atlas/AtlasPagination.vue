<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'

const props = defineProps<{ page: number; perPage: number; total: number }>()
const emit = defineEmits<{ change: [page: number] }>()
const { t } = useI18n()
const pageCount = computed(() => Math.max(1, Math.ceil(props.total / props.perPage)))
const range = computed(() => {
  if (!props.total) return t('common.entries', { count: 0 })
  const first = (props.page - 1) * props.perPage + 1
  const last = Math.min(props.total, props.page * props.perPage)
  return t('atlas.range', { first, last, total: props.total })
})
</script>

<template>
  <nav v-if="total > perPage" class="pagination" :aria-label="$t('atlas.pages')">
    <span class="mono">{{ range }}</span>
    <button class="button" type="button" :disabled="page <= 1" @click="emit('change', page - 1)">{{ $t('common.previous') }}</button>
    <span>{{ $t('common.page') }} <strong>{{ page }}</strong> {{ $t('common.of') }} {{ pageCount }}</span>
    <button class="button" type="button" :disabled="page >= pageCount" @click="emit('change', page + 1)">{{ $t('common.next') }}</button>
  </nav>
</template>
