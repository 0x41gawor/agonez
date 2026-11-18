<script setup lang="ts">
import { useI18n } from 'vue-i18n'

import { PLAN_ACCENTS, type PlanAccent } from '@/api/plan-types'

const model = defineModel<PlanAccent | null>({ required: true })
const { t } = useI18n()

const accentLabel = (accent: PlanAccent): string => t(`plans.accents.${accent}`)

function choose(accent: PlanAccent): void {
  model.value = model.value === accent ? null : accent
}
</script>

<template>
  <div class="accent-picker" role="radiogroup" :aria-label="$t('plans.editor.accent')">
    <button
      v-for="accent in PLAN_ACCENTS"
      :key="accent"
      type="button"
      class="accent-swatch"
      role="radio"
      :class="{ chosen: model === accent }"
      :data-accent="accent"
      :aria-checked="model === accent"
      :title="accentLabel(accent)"
      :aria-label="accentLabel(accent)"
      @click="choose(accent)"
    />
    <button
      type="button"
      class="accent-swatch accent-none"
      role="radio"
      :class="{ chosen: model === null }"
      :aria-checked="model === null"
      :title="$t('plans.editor.accentNone')"
      :aria-label="$t('plans.editor.accentNone')"
      @click="model = null"
    >
      <span aria-hidden="true">×</span>
    </button>
  </div>
</template>

<style scoped>
.accent-picker { display: flex; flex-wrap: wrap; gap: 6px; }
.accent-swatch {
  width: 22px;
  height: 22px;
  padding: 0;
  border: 1px solid var(--border2);
  border-radius: 50%;
  background: var(--planAccent, var(--accent));
  cursor: pointer;
  transition: transform 120ms ease, box-shadow 120ms ease;
}
.accent-swatch:hover { transform: scale(1.1); }
.accent-swatch:focus-visible { outline: 2px solid var(--focus); outline-offset: 2px; }
.accent-swatch.chosen {
  box-shadow: 0 0 0 2px var(--panel), 0 0 0 3.5px var(--planAccent, var(--text2));
}
.accent-none {
  display: grid;
  place-items: center;
  background: var(--inputBg);
  color: var(--text3);
  font-size: 13px;
  line-height: 1;
}
</style>
