<script setup lang="ts">
import { computed } from 'vue'

import { useTheme } from '@/composables/useTheme'

const { theme } = useTheme()
const demoUrl = computed(
  () => `${import.meta.env.BASE_URL}static/mobile-demo/index-${theme.value}.html`,
)
</script>

<template>
  <section class="mobile-demo-page">
    <h1 class="sr-only">{{ $t('app.mobileDemo') }}</h1>
    <iframe
      class="mobile-demo-frame"
      :src="demoUrl"
      :title="$t('app.mobileDemo')"
    />
  </section>
</template>

<style scoped>
.mobile-demo-page {
  height: calc(100vh - 52px);
  height: calc(100dvh - 52px);
  background: var(--bg);
}

.mobile-demo-frame {
  display: block;
  width: 100%;
  height: 100%;
  border: 0;
  background: var(--bg);
}
</style>
