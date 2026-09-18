<script setup lang="ts">
import { computed, ref, watch } from 'vue'

import { useTheme } from '@/composables/useTheme'
import { useLocaleStore } from '@/stores/locale'

const props = withDefaults(
  defineProps<{
    path: string
    alt: string
    width: number
    height: number
    eager?: boolean
  }>(),
  { eager: false },
)

const locale = useLocaleStore()
const { theme } = useTheme()
const candidateIndex = ref(0)

const candidates = computed(() => {
  const requested = `/img/home/${locale.current}-${theme.value}/${props.path}`
  const englishTheme = `/img/home/en-${theme.value}/${props.path}`
  const englishDefault = `/img/home/en-light/${props.path}`
  return [...new Set([requested, englishTheme, englishDefault])]
})

const source = computed(() => candidates.value[candidateIndex.value] ?? candidates.value.at(-1)!)

watch(
  () => [locale.current, theme.value, props.path],
  () => {
    candidateIndex.value = 0
  },
  { flush: 'sync' },
)

function useFallback(): void {
  if (candidateIndex.value < candidates.value.length - 1) candidateIndex.value += 1
}
</script>

<template>
  <img
    :src="source"
    :alt="alt"
    :width="width"
    :height="height"
    :loading="eager ? 'eager' : 'lazy'"
    :fetchpriority="eager ? 'high' : 'auto'"
    decoding="async"
    @error="useFallback"
  />
</template>
