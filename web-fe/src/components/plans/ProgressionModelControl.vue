<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'

import type { ProgressionModelCatalogItem } from '@/api/plan-types'
import ProgressionModelInfo from '@/components/plans/ProgressionModelInfo.vue'

const model = defineModel<string | null>({ required: true })
const props = defineProps<{ models: ProgressionModelCatalogItem[] }>()
const emit = defineEmits<{ opened: [] }>()

const root = ref<HTMLElement | null>(null)
const menuOpen = ref(false)
const infoOpen = ref(false)
const previewSlug = ref<string | null>(null)

const selected = computed(() => props.models.find((item) => item.slug === model.value) ?? null)
const selectedLabel = computed(() => selected.value?.name ?? model.value)

function toggleMenu(): void {
  menuOpen.value = !menuOpen.value
  if (!menuOpen.value) return
  emit('opened')
  infoOpen.value = false
  previewSlug.value = null
}

function selectProgression(slug: string | null): void {
  model.value = slug
  menuOpen.value = false
  infoOpen.value = false
  previewSlug.value = null
}

function togglePreview(slug: string): void {
  previewSlug.value = previewSlug.value === slug ? null : slug
}

function closeFromOutside(event: PointerEvent): void {
  if (!root.value?.contains(event.target as Node)) {
    menuOpen.value = false
    previewSlug.value = null
  }
}

function handleKeydown(event: KeyboardEvent): void {
  if (event.key !== 'Escape') return
  if (menuOpen.value) {
    menuOpen.value = false
    previewSlug.value = null
    event.preventDefault()
  } else if (infoOpen.value) {
    infoOpen.value = false
    event.preventDefault()
  }
}

onMounted(() => {
  document.addEventListener('pointerdown', closeFromOutside)
  document.addEventListener('keydown', handleKeydown)
})
onBeforeUnmount(() => {
  document.removeEventListener('pointerdown', closeFromOutside)
  document.removeEventListener('keydown', handleKeydown)
})
</script>

<template>
  <div ref="root" class="progression-model-control">
    <div class="progression-model-row">
      <span class="progression-mark" aria-hidden="true">
        <svg viewBox="0 0 36 28" fill="none">
          <path class="axis" d="M1.5 26.5H34.5" />
          <rect class="bar" x="4.5" y="21" width="4" height="5.5" rx="1" />
          <rect class="bar" x="12.5" y="17" width="4" height="9.5" rx="1" />
          <rect class="bar" x="20.5" y="13" width="4" height="13.5" rx="1" />
          <rect class="bar" x="28.5" y="9" width="4" height="17.5" rx="1" />
          <path class="trend" d="M2.5 15L32.5 2.5" />
          <path class="arrow" d="M27.8 1.5L32.5 2.5L29.9 6.6" />
        </svg>
      </span>
      <button
        class="progression-model-trigger"
        type="button"
        aria-haspopup="listbox"
        :aria-expanded="menuOpen"
        :title="$t('plans.progression.choose')"
        @click="toggleMenu"
      >
        <span>
          <small>{{ $t('plans.progression.label') }}</small>
          <strong>{{ selectedLabel || $t('plans.progression.none') }}</strong>
        </span>
        <span class="progression-chevron" aria-hidden="true">⌄</span>
      </button>
      <button
        v-if="selected"
        class="progression-info-button"
        type="button"
        :class="{ active: infoOpen }"
        :aria-expanded="infoOpen"
        :aria-label="$t('plans.progression.info')"
        :title="$t('plans.progression.info')"
        @click="infoOpen = !infoOpen; menuOpen = false"
      >i</button>
    </div>

    <Transition name="progression-menu">
      <div v-if="menuOpen" class="progression-model-menu" role="listbox" :aria-label="$t('plans.progression.choose')">
        <div class="progression-options">
          <div class="progression-option-shell none-shell" :class="{ selected: model === null }">
            <button
              class="progression-option none"
              type="button"
              role="option"
              :aria-selected="model === null"
              @click="selectProgression(null)"
            >
              <span>{{ $t('plans.progression.none') }}</span>
              <small>{{ $t('plans.progression.noneHelp') }}</small>
              <i v-if="model === null" aria-hidden="true">✓</i>
            </button>
          </div>
          <div
            v-for="item in models"
            :key="item.slug"
            class="progression-option-shell"
            :class="{ selected: model === item.slug, previewed: previewSlug === item.slug }"
          >
            <button
              class="progression-option"
              type="button"
              role="option"
              :aria-selected="model === item.slug"
              @click="selectProgression(item.slug)"
            >
              <span>{{ item.name }}</span>
              <small>{{ item.name_full }}</small>
              <i v-if="model === item.slug" aria-hidden="true">✓</i>
            </button>
            <button
              class="progression-option-info"
              type="button"
              :class="{ active: previewSlug === item.slug }"
              :aria-expanded="previewSlug === item.slug"
              :aria-label="`${$t('plans.progression.info')}: ${item.name}`"
              @click.stop="togglePreview(item.slug)"
            >i</button>
            <ProgressionModelInfo
              v-if="previewSlug === item.slug"
              :model="item"
              compact
            />
          </div>
        </div>
      </div>
    </Transition>

    <Transition name="progression-info">
      <ProgressionModelInfo
        v-if="infoOpen && selected"
        :model="selected"
        closable
        @close="infoOpen = false"
      />
    </Transition>
  </div>
</template>

<style scoped>
.progression-model-control {
  position: relative;
  margin: 10px 0 2px;
}

.progression-model-row {
  display: flex;
  min-height: 50px;
  align-items: center;
  gap: 8px;
  padding: 5px 6px;
  border: 1px solid var(--border);
  border-radius: 7px;
  background: color-mix(in srgb, var(--panel2) 45%, transparent);
}

.progression-mark {
  display: grid;
  width: 46px;
  height: 38px;
  flex: 0 0 auto;
  place-items: center;
  border: 1px solid var(--border);
  border-radius: 7px;
  background: color-mix(in srgb, var(--accent) 4%, transparent);
  color: color-mix(in srgb, var(--accent2) 45%, var(--text3));
}

.progression-mark svg {
  width: 38px;
  height: 30px;
  stroke: currentColor;
  stroke-linecap: round;
  stroke-linejoin: round;
  stroke-width: 1.1;
}

.progression-mark .axis {
  opacity: 0.35;
  stroke-width: 1;
}

.progression-mark .bar {
  fill: currentColor;
  fill-opacity: 0.08;
  stroke-width: 1;
}

.progression-mark .trend,
.progression-mark .arrow {
  stroke-width: 1.3;
}

.progression-model-trigger {
  display: flex;
  min-width: 0;
  flex: 1;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 2px 5px;
  border: 0;
  background: transparent;
  color: var(--text);
  text-align: left;
}

.progression-model-trigger > span:first-child {
  display: grid;
  min-width: 0;
}

.progression-model-trigger small {
  color: var(--text3);
  font-size: 9px;
  font-weight: 600;
  letter-spacing: 0.7px;
  text-transform: uppercase;
}

.progression-model-trigger strong {
  overflow: hidden;
  font-size: 11.5px;
  font-weight: 550;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.progression-chevron {
  color: var(--text3);
  font-size: 14px;
  transition: transform 120ms ease;
}

.progression-model-trigger[aria-expanded='true'] .progression-chevron {
  transform: rotate(180deg);
}

.progression-info-button {
  width: 30px;
  height: 30px;
  flex: 0 0 auto;
  border: 1px solid var(--border);
  border-radius: 6px;
  background: var(--panel);
  color: var(--text3);
  font-family: Georgia, serif;
  font-size: 13px;
  font-style: italic;
  font-weight: 700;
}

.progression-info-button:hover,
.progression-info-button.active {
  border-color: var(--border2);
  background: var(--panel2);
  color: var(--text);
}

.progression-model-menu {
  position: absolute;
  z-index: 35;
  top: calc(100% + 6px);
  right: 0;
  left: 0;
  padding: 7px;
  border: 1px solid var(--border2);
  border-radius: 9px;
  background: color-mix(in srgb, var(--panel) 98%, transparent);
  box-shadow: var(--shadow);
  backdrop-filter: blur(14px);
}

.progression-options {
  display: grid;
  max-height: min(600px, 65vh);
  gap: 2px;
  overflow-y: auto;
}

.progression-option-shell {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 32px;
  align-items: center;
  border-radius: 6px;
}

.progression-option-shell.none-shell .progression-option,
.progression-option-shell :deep(.progression-model-info) {
  grid-column: 1 / -1;
}

.progression-option-shell:hover,
.progression-option-shell:focus-within,
.progression-option-shell.previewed,
.progression-option-shell.selected {
  background: var(--rowHover);
}

.progression-option-shell.selected {
  box-shadow: inset 2px 0 var(--accent);
}

.progression-option {
  display: grid;
  min-height: 45px;
  grid-template-columns: minmax(0, 1fr) 18px;
  align-content: center;
  padding: 6px 8px;
  border: 0;
  border-radius: 6px;
  background: transparent;
  color: var(--text2);
  text-align: left;
}

.progression-option:hover,
.progression-option:focus-visible {
  color: var(--text);
  outline: none;
}

.progression-option span,
.progression-option small {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.progression-option span {
  font-size: 11.5px;
  font-weight: 600;
}

.progression-option small {
  color: var(--text3);
  font-size: 9.5px;
}

.progression-option i {
  grid-column: 2;
  grid-row: 1 / span 2;
  align-self: center;
  color: var(--accent2);
  font-style: normal;
  text-align: center;
}

.progression-option-info {
  display: grid;
  width: 26px;
  height: 26px;
  place-items: center;
  border: 1px solid transparent;
  border-radius: 6px;
  background: transparent;
  color: var(--text3);
  font-family: Georgia, serif;
  font-size: 12px;
  font-style: italic;
  font-weight: 700;
}

.progression-option-info:hover,
.progression-option-info:focus-visible,
.progression-option-info.active {
  border-color: var(--border2);
  background: var(--panel);
  color: var(--text);
  outline: none;
}

.progression-menu-enter-active,
.progression-menu-leave-active,
.progression-info-enter-active,
.progression-info-leave-active {
  transition: opacity 100ms ease, transform 100ms ease;
}

.progression-menu-enter-from,
.progression-menu-leave-to,
.progression-info-enter-from,
.progression-info-leave-to {
  opacity: 0;
  transform: translateY(-3px);
}

@media (max-width: 700px) {
  .progression-model-row {
    min-height: 50px;
  }

  .progression-model-menu {
    right: -6px;
    left: -6px;
  }
}
</style>
