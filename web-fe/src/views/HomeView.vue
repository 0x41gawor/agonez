<script setup lang="ts">
import { onBeforeUnmount, onMounted, useTemplateRef } from 'vue'

import HomeClosing from '@/components/home/HomeClosing.vue'
import HomeCoaches from '@/components/home/HomeCoaches.vue'
import HomeHero from '@/components/home/HomeHero.vue'
import HomeModel from '@/components/home/HomeModel.vue'
import HomeOverview from '@/components/home/HomeOverview.vue'
import HomeShowcases from '@/components/home/HomeShowcases.vue'
import { installHomeScrollReveal } from '@/utils/scrollReveal'

const page = useTemplateRef<HTMLElement>('page')
let removeScrollReveal: () => void = () => undefined

onMounted(() => {
  if (page.value) removeScrollReveal = installHomeScrollReveal(page.value)
})

onBeforeUnmount(() => removeScrollReveal())
</script>

<template>
  <div ref="page" class="home-page">
    <HomeHero />
    <HomeOverview />
    <HomeShowcases />
    <HomeModel />
    <HomeCoaches />
    <HomeClosing />
  </div>
</template>

<style src="../styles/home.css"></style>
