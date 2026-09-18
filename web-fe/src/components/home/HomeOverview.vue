<script setup lang="ts">
type AudienceCard = {
  key: 'beginner' | 'advanced' | 'coach'
  tone: 'brand' | 'etu' | 'joint'
  route?: string
  href?: string
}

const audienceCards: AudienceCard[] = [
  { key: 'beginner', tone: 'brand', route: '/atlas/exercises' },
  { key: 'advanced', tone: 'etu', href: '#analiza' },
  { key: 'coach', tone: 'joint', href: '#trenerzy' },
]

const steps = ['s1', 's2', 's3', 's4'] as const
</script>

<template>
  <section class="home-section home-section-compact">
    <div class="home-container">
      <header class="home-inline-heading">
        <span class="home-eyebrow">{{ $t('home.audiences.eyebrow') }}</span>
        <h2>{{ $t('home.audiences.title') }}</h2>
      </header>
      <div class="home-audience-grid">
        <article v-for="card in audienceCards" :key="card.key" class="home-audience-card" :class="`is-${card.tone}`">
          <div class="home-audience-tag"><span class="home-audience-icon" />{{ $t(`home.audiences.${card.key}.tag`) }}</div>
          <h3>{{ $t(`home.audiences.${card.key}.title`) }}</h3>
          <p>{{ $t(`home.audiences.${card.key}.body`) }}</p>
          <RouterLink v-if="card.route" :to="card.route">{{ $t(`home.audiences.${card.key}.link`) }} <span aria-hidden="true">→</span></RouterLink>
          <a v-else :href="card.href ?? '#hero'">{{ $t(`home.audiences.${card.key}.link`) }} <span aria-hidden="true">→</span></a>
        </article>
      </div>
    </div>
  </section>

  <section class="home-section home-loop-section">
    <div class="home-container home-loop-grid">
      <article v-for="(step, index) in steps" :key="step" class="home-loop-card" :class="{ 'is-planned': step === 's4' }">
        <div class="home-loop-meta">
          <span>{{ String(index + 1).padStart(2, '0') }}</span>
          <span v-if="step === 's4'" class="home-badge home-badge-planned">{{ $t('home.badges.comingSoon') }}</span>
        </div>
        <h3>{{ $t(`home.loop.${step}.title`) }}</h3>
        <p>{{ $t(`home.loop.${step}.body`) }}</p>
      </article>
    </div>
  </section>
</template>
