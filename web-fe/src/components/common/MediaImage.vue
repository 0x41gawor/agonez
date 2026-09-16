<script setup lang="ts">
import { computed, ref, watch } from 'vue'

import { mediaUrl } from '@/api/url'

const props = withDefaults(
  defineProps<{ src: string | null | undefined; alt: string; label?: string; loading?: 'eager' | 'lazy' }>(),
  { loading: 'lazy' },
)

const failed = ref(false)
const resolved = computed(() => mediaUrl(props.src))
watch(resolved, () => { failed.value = false })
</script>

<template>
  <img v-if="resolved && !failed" :src="resolved" :alt="alt" :loading="loading" @error="failed = true" />
  <div v-else class="placeholder-media" role="img" :aria-label="`${alt}: ${label ?? $t('common.visualUnavailable')}`">
    <span>{{ label ?? $t('common.visualUnavailable') }}</span>
  </div>
</template>
