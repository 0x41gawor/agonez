<script setup lang="ts">
withDefaults(defineProps<{ rows?: number; mode?: 'page' | 'analysis' }>(), { rows: 6, mode: 'page' })
</script>

<template>
  <div class="exec-skeleton" :class="`is-${mode}`" aria-busy="true" :aria-label="$t('execution.common.loading')">
    <div v-for="row in rows" :key="row" class="skeleton" />
  </div>
</template>
