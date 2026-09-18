<script setup lang="ts">
import HomeClosing from '@/components/home/HomeClosing.vue'
import HomeCoaches from '@/components/home/HomeCoaches.vue'
import HomeHero from '@/components/home/HomeHero.vue'
import HomeModel from '@/components/home/HomeModel.vue'
import HomeOverview from '@/components/home/HomeOverview.vue'
import HomeShowcases from '@/components/home/HomeShowcases.vue'
</script>

<template>
  <div class="home-page">
    <HomeHero />
    <HomeOverview />
    <HomeShowcases />
    <HomeModel />
    <HomeCoaches />
    <HomeClosing />
  </div>
</template>

<style src="../styles/home.css"></style>
