<script setup lang="ts">
import type { MicrocycleClassification } from '@/api/execution-types'
defineProps<{ classification: MicrocycleClassification }>()
</script>

<template>
  <span v-if="classification !== 'normal'" class="exec-tag mono" :class="classification">
    {{ $t(`execution.classification.${classification}`) }}
  </span>
</template>
