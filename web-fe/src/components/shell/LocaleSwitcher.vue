<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'

import type { SupportedLocale } from '@/i18n'
import { useLocaleStore } from '@/stores/locale'

const locale = useLocaleStore()
const { t } = useI18n()

const root = ref<HTMLElement | null>(null)
const trigger = ref<HTMLButtonElement | null>(null)
const menu = ref<HTMLElement | null>(null)
const expanded = ref(false)
const activeIndex = ref(0)

const nativeNameKeys: Record<SupportedLocale, string> = {
  en: 'locale.english',
  pl: 'locale.polish',
  fr: 'locale.french',
  es: 'locale.spanish',
  de: 'locale.german',
  it: 'locale.italian',
  'pt-BR': 'locale.portugueseBrazil',
  sv: 'locale.swedish',
  nl: 'locale.dutch',
  uk: 'locale.ukrainian',
}

function localeCode(value: SupportedLocale): string {
  return value.toUpperCase()
}

const options = computed(() =>
  locale.supported.map((value) => ({
    value,
    code: localeCode(value),
    name: t(nativeNameKeys[value]),
  })),
)
const currentCode = computed(() => localeCode(locale.current))

function optionElements(): HTMLButtonElement[] {
  return Array.from(menu.value?.querySelectorAll<HTMLButtonElement>('[role="menuitemradio"]') ?? [])
}

async function focusOption(index: number): Promise<void> {
  const count = options.value.length
  activeIndex.value = (index + count) % count
  await nextTick()
  optionElements()[activeIndex.value]?.focus()
}

function openMenu(focusCurrent = true): void {
  if (locale.switching || expanded.value) return
  expanded.value = true
  const currentIndex = options.value.findIndex((option) => option.value === locale.current)
  void focusOption(focusCurrent ? Math.max(0, currentIndex) : 0)
}

function closeMenu(returnFocus = false): void {
  if (!expanded.value) return
  expanded.value = false
  if (returnFocus) void nextTick(() => trigger.value?.focus())
}

function toggleMenu(): void {
  if (expanded.value) closeMenu()
  else openMenu()
}

async function choose(value: SupportedLocale): Promise<void> {
  await locale.change(value)
  closeMenu(true)
}

function onTriggerKeydown(event: KeyboardEvent): void {
  if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
    event.preventDefault()
    openMenu()
  }
}

function onMenuKeydown(event: KeyboardEvent): void {
  if (event.key === 'ArrowDown') {
    event.preventDefault()
    void focusOption(activeIndex.value + 1)
  } else if (event.key === 'ArrowUp') {
    event.preventDefault()
    void focusOption(activeIndex.value - 1)
  } else if (event.key === 'Home') {
    event.preventDefault()
    void focusOption(0)
  } else if (event.key === 'End') {
    event.preventDefault()
    void focusOption(options.value.length - 1)
  } else if (event.key === 'Escape') {
    event.preventDefault()
    closeMenu(true)
  } else if (event.key === 'Tab') {
    closeMenu()
  }
}

function closeFromOutside(event: PointerEvent): void {
  if (expanded.value && !root.value?.contains(event.target as Node)) closeMenu()
}

onMounted(() => document.addEventListener('pointerdown', closeFromOutside))
onBeforeUnmount(() => document.removeEventListener('pointerdown', closeFromOutside))
</script>

<template>
  <div ref="root" class="locale-switcher">
    <button
      ref="trigger"
      class="locale-trigger"
      type="button"
      aria-haspopup="menu"
      :aria-expanded="expanded"
      :aria-label="$t('locale.label')"
      :title="$t('locale.label')"
      :disabled="locale.switching"
      @click="toggleMenu"
      @keydown="onTriggerKeydown"
    >
      <svg class="locale-globe" viewBox="0 0 24 24" fill="none" aria-hidden="true">
        <circle cx="12" cy="12" r="8.5" />
        <path d="M3.8 12h16.4M12 3.5c2.2 2.3 3.4 5.1 3.4 8.5S14.2 18.2 12 20.5C9.8 18.2 8.6 15.4 8.6 12S9.8 5.8 12 3.5Z" />
      </svg>
      <span class="locale-current-code">{{ currentCode }}</span>
      <svg class="locale-chevron" viewBox="0 0 12 12" fill="none" aria-hidden="true">
        <path d="m3 4.5 3 3 3-3" />
      </svg>
    </button>

    <Transition name="locale-popover">
      <div
        v-if="expanded"
        ref="menu"
        class="locale-menu"
        role="menu"
        :aria-label="$t('locale.label')"
        @keydown="onMenuKeydown"
      >
        <div class="locale-menu-label">{{ $t('locale.label') }}</div>
        <button
          v-for="(option, index) in options"
          :key="option.value"
          class="locale-option"
          :class="{ active: option.value === locale.current }"
          type="button"
          role="menuitemradio"
          :aria-checked="option.value === locale.current"
          :aria-label="$t('locale.changeTo', { language: option.name })"
          :disabled="locale.switching"
          tabindex="-1"
          @focus="activeIndex = index"
          @click="choose(option.value)"
        >
          <span class="locale-option-name">{{ option.name }}</span>
          <span class="locale-option-code">{{ option.code }}</span>
          <svg class="locale-option-check" viewBox="0 0 14 14" fill="none" aria-hidden="true">
            <path d="m3 7.2 2.5 2.5L11 4.5" />
          </svg>
        </button>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.locale-switcher {
  position: relative;
  display: inline-flex;
  flex: 0 0 auto;
}

.locale-trigger {
  display: inline-flex;
  min-height: 30px;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 4px 8px;
  border: 1px solid var(--border);
  border-radius: 7px;
  background: var(--panel);
  color: var(--text2);
}

.locale-trigger:hover,
.locale-trigger[aria-expanded='true'] {
  border-color: var(--border2);
  background: var(--panel2);
  color: var(--text);
}

.locale-trigger:focus-visible {
  border-color: var(--accent);
  outline: 2px solid var(--accentDim);
  outline-offset: 1px;
}

.locale-globe {
  width: 14px;
  height: 14px;
  flex: 0 0 auto;
  stroke: currentColor;
  stroke-linecap: round;
  stroke-linejoin: round;
  stroke-width: 1.45;
}

.locale-current-code,
.locale-option-code,
.locale-menu-label {
  font-family: 'Geist Mono', monospace;
}

.locale-current-code {
  min-width: 18px;
  color: var(--text);
  font-size: 10.5px;
  font-weight: 600;
  letter-spacing: 0.35px;
  text-align: center;
}

.locale-chevron {
  width: 10px;
  height: 10px;
  flex: 0 0 auto;
  stroke: var(--text3);
  stroke-linecap: round;
  stroke-linejoin: round;
  stroke-width: 1.5;
  transition: transform 140ms ease;
}

.locale-trigger[aria-expanded='true'] .locale-chevron {
  transform: rotate(180deg);
}

.locale-menu {
  position: absolute;
  z-index: 140;
  top: calc(100% + 8px);
  right: 0;
  width: 226px;
  max-height: min(472px, calc(100vh - 72px));
  overflow-y: auto;
  padding: 6px;
  border: 1px solid var(--border2);
  border-radius: 10px;
  background: color-mix(in srgb, var(--panel) 97%, transparent);
  box-shadow: var(--shadow);
  backdrop-filter: blur(16px);
}

.locale-menu-label {
  padding: 6px 9px 7px;
  color: var(--text3);
  font-size: 9px;
  font-weight: 600;
  letter-spacing: 1px;
  text-transform: uppercase;
}

.locale-option {
  display: grid;
  width: 100%;
  min-height: 37px;
  grid-template-columns: minmax(0, 1fr) auto 16px;
  align-items: center;
  gap: 9px;
  padding: 7px 8px 7px 10px;
  border: 0;
  border-radius: 6px;
  background: transparent;
  color: var(--text2);
  text-align: left;
}

.locale-option:hover,
.locale-option:focus-visible {
  background: var(--rowHover);
  color: var(--text);
  outline: none;
}

.locale-option.active {
  background: var(--accentDim);
  color: var(--text);
}

.locale-option-name {
  overflow: hidden;
  font-size: 12px;
  font-weight: 500;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.locale-option-code {
  color: var(--text3);
  font-size: 9px;
  letter-spacing: 0.35px;
}

.locale-option-check {
  width: 14px;
  height: 14px;
  opacity: 0;
  stroke: var(--accent2);
  stroke-linecap: round;
  stroke-linejoin: round;
  stroke-width: 1.8;
}

.locale-option.active .locale-option-check {
  opacity: 1;
}

.locale-popover-enter-active,
.locale-popover-leave-active {
  transition: opacity 100ms ease, transform 100ms ease;
  transform-origin: top right;
}

.locale-popover-enter-from,
.locale-popover-leave-to {
  opacity: 0;
  transform: translateY(-3px) scale(0.985);
}

@media (max-width: 700px) {
  .locale-trigger {
    min-height: 40px;
    padding-inline: 9px;
  }
}

@media (max-width: 480px) {
  .locale-menu {
    position: fixed;
    top: 58px;
    right: 12px;
    left: 12px;
    width: auto;
    max-height: calc(100vh - 70px);
  }
}
</style>
