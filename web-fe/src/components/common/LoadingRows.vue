<script setup lang="ts">
withDefaults(defineProps<{ count?: number }>(), { count: 7 })
</script>

<template>
  <div class="loading-rows panel" aria-busy="true" aria-label="Loading Atlas data">
    <div v-for="index in count" :key="index" class="loading-row">
      <div class="skeleton" />
      <div class="skeleton" />
      <div class="skeleton" />
    </div>
  </div>
</template>

<style scoped>
.loading-rows { overflow: hidden; }
.loading-row { display: grid; grid-template-columns: minmax(180px, 1.7fr) 1fr 0.8fr; gap: 24px; padding: 12px 14px; border-bottom: 1px solid var(--border); }
.loading-row:last-child { border-bottom: 0; }
.skeleton { height: 15px; }
.skeleton:nth-child(2) { width: 72%; }
.skeleton:nth-child(3) { width: 65%; justify-self: end; }
</style>
