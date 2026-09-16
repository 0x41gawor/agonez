<script setup lang="ts">
defineProps<{ title?: string; message?: string }>()
defineEmits<{ retry: [] }>()
</script>

<template>
  <div class="inline-state" role="alert">
    <h2>{{ title ?? $t('errors.atlasLoadTitle') }}</h2>
    <p>{{ message ?? $t('errors.atlasLoadMessage') }}</p>
    <button class="button" type="button" @click="$emit('retry')">{{ $t('common.retry') }}</button>
  </div>
</template>
