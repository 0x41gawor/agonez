<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'

import BodyViewer from './BodyViewer.vue'
import type { VisualizationMode } from '@/utils/vectors'

const props = withDefaults(
  defineProps<{
    selectedSlug?: string | null
    vector?: Record<string, number> | null
    mode?: VisualizationMode
    joints?: Record<string, number> | null
    showJoints?: boolean
    status?: string
    legendTitle?: string
  }>(),
  { selectedSlug: null, vector: null, mode: 'etu', joints: null, showJoints: false },
)

const emit = defineEmits<{ hover: [slug: string | null] }>()
const router = useRouter()
const open = ref(false)
const gradient = computed(() => {
  const color = props.mode === 'recovery' ? 'var(--rec)' : props.mode === 'propulsive' ? 'var(--accent)' : 'var(--etu)'
  return `linear-gradient(to right, var(--anatMuscle), ${color})`
})

function select(slug: string): void {
  open.value = false
  void router.push({ name: 'muscle-detail', params: { slug } })
}
</script>

<template>
  <aside class="anatomy-rail" :class="{ open }" :aria-label="$t('atlas.anatomy.interactive')">
    <div class="anatomy-panel panel">
      <header>
        <span class="section-label">{{ $t('atlas.anatomy.label') }}</span>
        <span class="anatomy-views mono">{{ $t('atlas.anatomy.views') }} <span>{{ $t('atlas.anatomy.sideLater') }}</span></span>
        <button class="anatomy-close" type="button" :aria-label="$t('atlas.anatomy.close')" @click="open = false">×</button>
      </header>
      <BodyViewer
        :selected-slug="selectedSlug"
        :vector="vector"
        :mode="mode"
        :joints="joints"
        :show-joints="showJoints"
        @hover="emit('hover', $event)"
        @select="select"
      />
      <footer>
        <div v-if="vector" class="anatomy-legend">
          <strong>{{ legendTitle ?? $t('atlas.anatomy.relativeExposure') }}</strong>
          <span :style="{ background: gradient }" />
          <small class="mono">{{ $t('atlas.anatomy.lowHigh') }}</small>
        </div>
        <p>{{ status ?? $t('atlas.anatomy.hoverPrompt') }}</p>
      </footer>
    </div>
  </aside>
  <button class="anatomy-fab" type="button" @click="open = !open">
    <span /> {{ $t('atlas.anatomy.label') }}
  </button>
</template>
