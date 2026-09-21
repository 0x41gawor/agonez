<script setup lang="ts">
import { computed, ref, useTemplateRef } from 'vue'
import { useI18n } from 'vue-i18n'

import { joinWaitlist } from '@/api/waitlist'

const { t, tm } = useI18n()
const proof = computed(() => tm('home.hero.proof') as string[])
const heroImageWideWebpUrl = '/img/home/hero-image-wide.webp'
const heroImageWideFallbackUrl = '/media/hero-image-wide.png'
const heroImageWebpUrl = '/img/home/hero-image.webp'
const heroImageFallbackUrl = '/media/hero-image.png'
const waitlistEmail = ref('')
const waitlistWebsite = ref('')
const waitlistState = ref<'idle' | 'submitting' | 'success' | 'error'>('idle')
const waitlistInput = useTemplateRef<HTMLInputElement>('waitlistInput')
const waitlistMessage = computed(() => {
  if (waitlistState.value === 'success') return t('home.hero.waitlist.success')
  if (waitlistState.value === 'error') return t('home.hero.waitlist.error')
  return t('home.hero.waitlist.note')
})
const waitlistButton = computed(() => {
  if (waitlistState.value === 'submitting') return t('home.hero.waitlist.submitting')
  if (waitlistState.value === 'success') return t('home.hero.waitlist.joined')
  return t('home.hero.waitlist.button')
})

async function submitWaitlist() {
  if (waitlistState.value === 'submitting' || waitlistState.value === 'success') return
  if (!waitlistInput.value?.reportValidity()) return

  waitlistState.value = 'submitting'
  try {
    await joinWaitlist(waitlistEmail.value, waitlistWebsite.value)
    waitlistState.value = 'success'
    waitlistEmail.value = ''
  } catch {
    waitlistState.value = 'error'
  }
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
        <form class="home-waitlist" @submit.prevent="submitWaitlist">
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
              :disabled="waitlistState === 'submitting' || waitlistState === 'success'"
              :placeholder="$t('home.hero.waitlist.placeholder')"
              aria-describedby="home-waitlist-note"
            />
            <div class="home-waitlist-trap" aria-hidden="true">
              <label for="home-waitlist-website">Website</label>
              <input
                id="home-waitlist-website"
                v-model="waitlistWebsite"
                name="website"
                type="text"
                autocomplete="off"
                tabindex="-1"
              />
            </div>
            <button
              class="home-button home-button-primary"
              type="submit"
              :disabled="waitlistState === 'submitting' || waitlistState === 'success'"
            >
              {{ waitlistButton }}
            </button>
          </div>
          <p
            id="home-waitlist-note"
            class="home-waitlist-note"
            :class="{ 'is-success': waitlistState === 'success', 'is-error': waitlistState === 'error' }"
            aria-live="polite"
          >
            {{ waitlistMessage }}
          </p>
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
          <source
            media="(min-width: 861px)"
            :srcset="heroImageWideWebpUrl"
            type="image/webp"
            width="2560"
            height="1080"
          />
          <source
            media="(min-width: 861px)"
            :srcset="heroImageWideFallbackUrl"
            type="image/png"
            width="2560"
            height="1080"
          />
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
