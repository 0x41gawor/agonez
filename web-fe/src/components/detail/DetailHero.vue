<script setup lang="ts">
import MediaImage from '@/components/common/MediaImage.vue'

defineProps<{
  imageUrl: string | null
  title: string
  subtitle: string
  slug: string
  chips: string[]
  stats: Array<{ label: string; value: string; unit?: string }>
}>()
</script>

<template>
  <header class="detail-hero panel">
    <MediaImage :src="imageUrl" :alt="title" label="signature visual unavailable" loading="eager" />
    <div class="detail-identity">
      <div class="detail-title-row"><h1>{{ title }}</h1><span class="chip mono">{{ slug }}</span></div>
      <p>{{ subtitle }}</p>
      <div class="detail-chips"><span v-for="chip in chips" :key="chip" class="chip">{{ chip }}</span></div>
      <div class="hero-stats">
        <div v-for="stat in stats" :key="stat.label">
          <strong class="mono">{{ stat.value }}<small v-if="stat.unit"> {{ stat.unit }}</small></strong>
          <span>{{ stat.label }}</span>
        </div>
      </div>
    </div>
  </header>
</template>
