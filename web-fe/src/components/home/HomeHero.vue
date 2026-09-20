<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'

const { tm } = useI18n()
const proof = computed(() => tm('home.hero.proof') as string[])
const heroImageWebpUrl = '/img/home/hero-image.webp'
const heroImageFallbackUrl = '/media/hero-image.png'
</script>

<template>
  <section id="hero" class="home-section home-hero">
    <img class="home-watermark home-hero-mark" src="/img/home/brand/agonez-mark-hero.png" alt="" aria-hidden="true" />
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
      <figure class="home-hero-art" aria-hidden="true">
        <picture>
          <source :srcset="heroImageWebpUrl" type="image/webp" />
          <img
            :src="heroImageFallbackUrl"
            alt=""
            width="1536"
            height="1024"
            fetchpriority="high"
            decoding="async"
          />
        </picture>
      </figure>
    </div>
  </section>
</template>
