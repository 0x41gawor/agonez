<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'

const { tm } = useI18n()
const coachCards = ['reuse', 'swap', 'audit', 'argument', 'adaptation'] as const
const athleteFlow = computed(() => tm('home.roadmap.athlete.flow') as string[])
const mobileFlow = computed(() => tm('home.roadmap.mobile.flow') as string[])
</script>

<template>
  <section id="trenerzy" class="home-section home-showcase home-alt-section">
    <div class="home-container">
      <header class="home-split-heading">
        <div><span class="home-eyebrow home-joint-text">{{ $t('home.coaches.eyebrow') }}</span><h2>{{ $t('home.coaches.title') }}</h2></div>
        <p>{{ $t('home.coaches.body') }}</p>
      </header>
      <div class="home-coach-grid">
        <article v-for="card in coachCards" :key="card"><h3>{{ $t(`home.coaches.${card}.title`) }}</h3><p>{{ $t(`home.coaches.${card}.body`) }}</p></article>
      </div>
      <div class="home-coach-action">
        <RouterLink class="home-button home-button-primary" to="/plans">{{ $t('home.coaches.cta') }}</RouterLink>
        <p>{{ $t('home.coaches.note') }}</p>
      </div>
    </div>
  </section>

  <section class="home-section home-section-compact">
    <div class="home-container">
      <header class="home-inline-heading home-roadmap-heading">
        <span class="home-eyebrow">{{ $t('home.roadmap.eyebrow') }}</span>
        <h2>{{ $t('home.roadmap.title') }}</h2>
      </header>
      <div class="home-roadmap-grid">
        <article>
          <div class="home-roadmap-title"><h3>{{ $t('home.roadmap.athlete.title') }}</h3><span class="home-badge home-badge-muted">{{ $t('home.badges.comingSoon') }}</span></div>
          <p>{{ $t('home.roadmap.athlete.body') }}</p>
          <div class="home-roadmap-flow"><template v-for="(item, index) in athleteFlow" :key="item"><span>{{ item }}</span><span v-if="index < athleteFlow.length - 1" aria-hidden="true">→</span></template></div>
        </article>
        <article>
          <div class="home-roadmap-title"><h3>{{ $t('home.roadmap.mobile.title') }}</h3><span class="home-badge home-badge-muted">{{ $t('home.badges.comingSoon') }}</span></div>
          <p>{{ $t('home.roadmap.mobile.body') }}</p>
          <div class="home-roadmap-flow"><template v-for="(item, index) in mobileFlow" :key="item"><span>{{ item }}</span><span v-if="index < mobileFlow.length - 1" aria-hidden="true">·</span></template></div>
        </article>
      </div>
    </div>
  </section>
</template>
