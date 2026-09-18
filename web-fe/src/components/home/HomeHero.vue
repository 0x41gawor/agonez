<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'

import HomeImage from '@/components/home/HomeImage.vue'

const { tm } = useI18n()
const proof = computed(() => tm('home.hero.proof') as string[])
</script>

<template>
  <section id="hero" class="home-section home-hero">
    <img class="home-watermark home-hero-mark" src="/img/home/brand/agonez-mark.png" alt="" aria-hidden="true" />
    <div class="home-glow" aria-hidden="true" />
    <div class="home-container home-hero-grid">
      <div class="home-hero-copy">
        <p class="home-hero-eyebrow">{{ $t('home.hero.eyebrow') }}</p>
        <h1>{{ $t('home.hero.title') }}</h1>
        <p class="home-lead">{{ $t('home.hero.lead') }}</p>
        <div class="home-actions">
          <RouterLink class="home-button home-button-primary" to="/atlas/exercises">{{ $t('home.hero.ctaPrimary') }}</RouterLink>
          <a class="home-button home-button-secondary" href="#analiza">{{ $t('home.hero.ctaSecondary') }}</a>
        </div>
        <ul class="home-proof" role="list">
          <li v-for="item in proof" :key="item">{{ item }}</li>
        </ul>
      </div>
      <div class="home-hero-visual">
        <div class="home-browser home-browser-elevated">
          <div class="home-browser-bar">
            <span class="home-window-dot home-window-dot-red" />
            <span class="home-window-dot home-window-dot-amber" />
            <span class="home-window-dot home-window-dot-green" />
            <span class="home-browser-label">{{ $t('home.hero.frameLabel') }}</span>
          </div>
          <HomeImage
            class="home-product-image"
            path="hero/hero-stimulus-anatomy.png"
            :alt="$t('home.images.heroAnatomy')"
            :width="592"
            :height="575"
            eager
          />
        </div>
      </div>
    </div>
  </section>
</template>
