<script setup lang="ts">
import { computed, ref, useTemplateRef } from 'vue'
import { useI18n } from 'vue-i18n'

import { createMailto } from '@/utils/contact'

const { t, tm } = useI18n()
const proof = computed(() => tm('home.hero.proof') as string[])
const heroImageWebpUrl = '/img/home/hero-image.webp'
const heroImageFallbackUrl = '/media/hero-image.png'
const waitlistEmail = ref('')
const waitlistInput = useTemplateRef<HTMLInputElement>('waitlistInput')

function openWaitlistEmail() {
  if (!waitlistInput.value?.reportValidity()) return

  window.location.href = createMailto(
    t('home.hero.waitlist.emailSubject'),
    t('home.hero.waitlist.emailBody', { email: waitlistEmail.value }),
  )
}
</script>

<template>
  <section id="hero" class="home-section home-hero">
    <img class="home-watermark home-hero-mark" src="/img/home/brand/agonez-mark-hero.png" alt="" aria-hidden="true" />
    <div class="home-glow" aria-hidden="true" />
    <div class="home-container home-hero-grid">
      <div class="home-hero-copy">
        <p class="home-beta-badge"><span aria-hidden="true" />{{ $t('home.hero.betaBadge') }}</p>
        <p class="home-hero-eyebrow">{{ $t('home.hero.eyebrow') }}</p>
        <h1>{{ $t('home.hero.title') }}</h1>
        <p class="home-lead">{{ $t('home.hero.lead') }}</p>
        <form class="home-waitlist" @submit.prevent="openWaitlistEmail">
          <label class="sr-only" for="home-waitlist-email">{{ $t('home.hero.waitlist.label') }}</label>
          <div class="home-waitlist-row">
            <input
              id="home-waitlist-email"
              ref="waitlistInput"
              v-model.trim="waitlistEmail"
              name="email"
              type="email"
              autocomplete="email"
              required
              :placeholder="$t('home.hero.waitlist.placeholder')"
              aria-describedby="home-waitlist-note"
            />
            <button class="home-button home-button-primary" type="submit">
              {{ $t('home.hero.waitlist.button') }}
            </button>
          </div>
          <p id="home-waitlist-note" class="home-waitlist-note">{{ $t('home.hero.waitlist.note') }}</p>
        </form>
        <div class="home-actions">
          <RouterLink class="home-button home-button-secondary" to="/atlas/exercises">{{ $t('home.hero.ctaPrimary') }}</RouterLink>
          <a class="home-button home-button-quiet" href="#analiza">{{ $t('home.hero.ctaSecondary') }}</a>
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
