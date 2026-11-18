<script setup lang="ts">
import { useI18n } from 'vue-i18n'

import { PLAN_ACCENTS, type PlanAccent } from '@/api/plan-types'
import { useDismissablePopover } from '@/composables/useDismissablePopover'

const model = defineModel<PlanAccent | null>({ required: true })
const { t } = useI18n()
const { open, setRoot, toggle } = useDismissablePopover()

const accentLabel = (accent: PlanAccent): string => t(`plans.accents.${accent}`)

function choose(accent: PlanAccent | null): void {
  model.value = accent
  open.value = false
}
</script>

<template>
  <div :ref="setRoot" class="accent-picker">
    <button
      type="button"
      class="accent-trigger"
      :data-accent="model ?? undefined"
      :class="{ unset: model === null }"
      :aria-expanded="open"
      :aria-haspopup="true"
      :title="model ? accentLabel(model) : $t('plans.editor.accentNone')"
      :aria-label="$t('plans.editor.accent')"
      @click="toggle"
    >
      <span class="accent-trigger-dot" aria-hidden="true" />
      <span class="accent-trigger-name">{{ model ? accentLabel(model) : $t('plans.editor.accentNone') }}</span>
    </button>

    <div v-if="open" class="accent-popover" role="dialog" :aria-label="$t('plans.editor.accent')">
      <button
        v-for="accent in PLAN_ACCENTS"
        :key="accent"
        type="button"
        class="accent-swatch"
        :data-accent="accent"
        :class="{ chosen: model === accent }"
        :title="accentLabel(accent)"
        :aria-label="accentLabel(accent)"
        @click="choose(accent)"
      />
      <button
        type="button"
        class="accent-swatch accent-none"
        :class="{ chosen: model === null }"
        :title="$t('plans.editor.accentNone')"
        :aria-label="$t('plans.editor.accentNone')"
        @click="choose(null)"
      ><span aria-hidden="true">×</span></button>
    </div>
  </div>
</template>

<style scoped>
.accent-picker { position: relative; display: inline-block; }

.accent-trigger {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  height: 32px;
  padding: 0 11px 0 9px;
  border: 1px solid var(--border);
  border-radius: 8px;
  background: var(--inputBg);
  color: var(--text2);
  font-size: 12px;
  cursor: pointer;
}
.accent-trigger:hover { border-color: var(--border2); color: var(--text); }
.accent-trigger:focus-visible { outline: 2px solid var(--focus); outline-offset: 1px; }
.accent-trigger-dot {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  background: var(--planAccent, var(--accent));
}
.accent-trigger.unset .accent-trigger-dot {
  background: repeating-linear-gradient(
    -45deg,
    var(--border2) 0 3px,
    transparent 3px 6px
  );
  border: 1px solid var(--border2);
}

.accent-popover {
  position: absolute;
  z-index: 20;
  top: calc(100% + 6px);
  left: 0;
  display: grid;
  grid-template-columns: repeat(7, 22px);
  gap: 7px;
  padding: 10px;
  border: 1px solid var(--border2);
  border-radius: 10px;
  background: var(--panel2);
  box-shadow: var(--shadow);
}

.accent-swatch {
  width: 22px;
  height: 22px;
  padding: 0;
  border: 1px solid var(--border2);
  border-radius: 50%;
  background: var(--planAccent, var(--accent));
  cursor: pointer;
  transition: transform 120ms ease;
}
.accent-swatch:hover { transform: scale(1.12); }
.accent-swatch:focus-visible { outline: 2px solid var(--focus); outline-offset: 2px; }
.accent-swatch.chosen {
  box-shadow: 0 0 0 2px var(--panel2), 0 0 0 3.5px var(--planAccent, var(--text2));
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
