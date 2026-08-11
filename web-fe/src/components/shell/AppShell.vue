<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'

import { useTheme } from '@/composables/useTheme'
import { useAtlasStore } from '@/stores/atlas'

const route = useRoute()
const atlas = useAtlasStore()
const { theme, label, toggleTheme } = useTheme()
const atlasActive = computed(() => route.path.startsWith('/atlas'))
</script>

<template>
  <div class="app-shell">
    <header class="app-bar">
      <RouterLink class="brand" to="/atlas/exercises" aria-label="Agonez Atlas home">
        <img src="/logo-mark.png" alt="" />
        <span>AGONEZ</span>
      </RouterLink>

      <nav class="main-nav" aria-label="Primary navigation">
        <RouterLink :class="{ active: atlasActive }" to="/atlas/exercises">Atlas</RouterLink>
        <span class="planned-nav" title="Planned module" aria-disabled="true">My Plans</span>
        <span class="planned-nav" title="Planned module" aria-disabled="true">Dashboard</span>
      </nav>

      <div class="app-bar-spacer" />
      <span class="atlas-version">
        ATLAS v0.1
        <template v-if="atlas.meta">· {{ atlas.meta.counts.exercises }} exercises · {{ atlas.meta.counts.muscles }} muscles</template>
      </span>
      <button class="theme-toggle" type="button" :title="`Switch to ${theme === 'dark' ? 'light' : 'dark'} theme`" @click="toggleTheme">
        <span class="theme-dot" :class="theme" />
        {{ label }}
      </button>
    </header>
    <main id="main-content"><slot /></main>
  </div>
</template>
