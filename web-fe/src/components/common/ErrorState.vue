<script setup lang="ts">
withDefaults(defineProps<{ title?: string; message?: string }>(), {
  title: 'The Atlas could not be loaded',
  message: 'Check that the API is running, then try again.',
})
defineEmits<{ retry: [] }>()
</script>

<template>
  <div class="inline-state" role="alert">
    <h2>{{ title }}</h2>
    <p>{{ message }}</p>
    <button class="button" type="button" @click="$emit('retry')">Try again</button>
  </div>
</template>
