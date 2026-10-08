<script setup lang="ts">
import { computed } from 'vue'
import type { CompletionMode, SessionStatus } from '@/api/execution-types'

const props = defineProps<{ status: SessionStatus; completionMode?: CompletionMode | null; today?: boolean; compact?: boolean }>()
const effective = computed(() => props.today && props.status === 'scheduled' ? 'today' : props.status)
const symbol = computed(() => ({ completed: '✓', in_progress: 'I', scheduled: 'S', today: 'T', missed: '×', cancelled: '—' })[effective.value])
</script>

<template>
  <span
    class="exec-status-mark mono"
    :class="[`is-${effective}`, { compact, fallback: completionMode === 'fallback' }]"
    :aria-label="$t(`execution.status.${effective}`)"
    :title="`${$t(`execution.status.${effective}`)}${completionMode === 'fallback' ? ` · ${$t('execution.completion.fallback')}` : ''}`"
  >{{ symbol }}</span>
</template>
