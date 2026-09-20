<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'

import { createMailto } from '@/utils/contact'

const { t, tm } = useI18n()
const roles = computed(() => tm('home.cta.roles') as string[])
const contactHref = computed(() => createMailto(t('home.cta.emailSubject'), t('home.cta.emailBody')))
</script>

<template>
  <section id="collaborate" class="home-section home-final-cta">
    <img class="home-watermark home-final-mark" src="/img/home/brand/agonez-mark-final.png" alt="" aria-hidden="true" />
    <div class="home-glow" aria-hidden="true" />
    <div class="home-final-content">
      <p class="home-eyebrow">{{ $t('home.cta.eyebrow') }}</p>
      <h2>{{ $t('home.cta.title') }}</h2>
      <p class="home-collaboration-body">{{ $t('home.cta.body') }}</p>
      <p class="home-collaboration-body">{{ $t('home.cta.bodySecondary') }}</p>
      <ul class="home-collaboration-roles" :aria-label="$t('home.cta.rolesLabel')">
        <li v-for="role in roles" :key="role">{{ role }}</li>
      </ul>
      <a class="home-button home-button-secondary home-collaboration-action" :href="contactHref">
        {{ $t('home.cta.action') }} <span aria-hidden="true">→</span>
      </a>
    </div>
  </section>

  <footer class="home-footer">
    <div class="home-container home-footer-inner">
      <RouterLink class="home-footer-brand" to="/home" :aria-label="$t('app.home')">
        <img src="/img/home/brand/agonez-mark.png" alt="" />
        <span>{{ $t('home.brand.name') }}</span>
      </RouterLink>
      <nav class="home-footer-nav" :aria-label="$t('home.footer.navigation')">
        <RouterLink to="/atlas/exercises">{{ $t('home.footer.links.exerciseAtlas') }}</RouterLink>
        <RouterLink to="/atlas/muscles">{{ $t('home.footer.links.muscleAtlas') }}</RouterLink>
        <RouterLink to="/plans">{{ $t('home.footer.links.planBuilder') }}</RouterLink>
        <a href="#analiza">{{ $t('home.footer.links.analysis') }}</a>
        <a href="#model">{{ $t('home.footer.links.model') }}</a>
      </nav>
      <p class="home-footer-disclaimer">{{ $t('home.footer.disclaimer') }}</p>
    </div>
  </footer>
</template>
