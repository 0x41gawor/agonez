<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'

import { useTheme } from '@/composables/useTheme'
import LocaleSwitcher from '@/components/shell/LocaleSwitcher.vue'
import { useAtlasStore } from '@/stores/atlas'

const route = useRoute()
const atlas = useAtlasStore()
const { theme, toggleTheme } = useTheme()
const atlasActive = computed(() => route.path.startsWith('/atlas'))
const plansActive = computed(() => route.path.startsWith('/plans'))
</script>

<template>
  <div class="app-shell">
    <header class="app-bar">
      <RouterLink class="brand" to="/home" :aria-label="$t('app.home')">
        <img src="/logo-mark.png" alt="" />
        <span>AGONEZ</span>
      </RouterLink>

      <nav class="main-nav" :aria-label="$t('app.primaryNavigation')">
        <RouterLink :class="{ active: atlasActive }" to="/atlas/exercises">{{ $t('app.atlas') }}</RouterLink>
        <RouterLink :class="{ active: plansActive }" to="/plans">{{ $t('app.myPlans') }}</RouterLink>
        <span class="planned-nav" :title="$t('app.plannedModule')" aria-disabled="true">{{ $t('app.dashboard') }}</span>
      </nav>

      <div class="app-bar-spacer" />
      <span class="atlas-version">
        <template v-if="plansActive">{{ $t('app.planCreatorDraft') }}</template>
        <template v-else>
          ATLAS v0.1
          <template v-if="atlas.meta">· {{ $t('app.exercisesCount', { count: atlas.meta.counts.exercises }) }} · {{ $t('app.musclesCount', { count: atlas.meta.counts.muscles }) }}</template>
        </template>
      </span>
      <LocaleSwitcher />
      <button class="theme-toggle" type="button" :title="$t('theme.switchTo', { theme: $t(theme === 'dark' ? 'theme.light' : 'theme.dark').toLowerCase() })" @click="toggleTheme">
        <span class="theme-dot" :class="theme" />
        {{ $t(`theme.${theme}`) }}
      </button>
    </header>
    <main id="main-content"><slot /></main>
  </div>
</template>
