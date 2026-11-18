<script setup lang="ts">
import { computed } from 'vue'

import type { DayIcon } from '@/api/plan-types'
import { DAY_ICON_GLYPHS } from '@/features/plans/day-icons'

const props = withDefaults(
  defineProps<{ icon: DayIcon | null; size?: number; title?: string }>(),
  { size: 20 },
)

const glyph = computed(() => (props.icon ? DAY_ICON_GLYPHS[props.icon] : null))
</script>

<template>
  <svg
    v-if="glyph"
    class="day-icon-mark"
    :width="size"
    :height="size"
    viewBox="0 0 24 24"
    fill="currentColor"
    stroke="none"
    :role="title ? 'img' : undefined"
    :aria-label="title"
    :aria-hidden="title ? undefined : 'true'"
  >
    <title v-if="title">{{ title }}</title>
    <!-- Glyphs are constants from day-icons.ts; nothing user-supplied reaches here. -->
    <g v-html="glyph" />
  </svg>
</template>

<style scoped>
.day-icon-mark { display: block; }
</style>
