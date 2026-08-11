<script setup lang="ts">
import { onMounted } from 'vue'

import AppShell from '@/components/shell/AppShell.vue'
import { useAtlasStore } from '@/stores/atlas'

const atlas = useAtlasStore()
onMounted(() => void atlas.loadMeta())
</script>

<template>
  <AppShell>
    <RouterView v-slot="{ Component }">
      <Transition name="page" mode="out-in">
        <component :is="Component" />
      </Transition>
    </RouterView>
  </AppShell>
</template>
