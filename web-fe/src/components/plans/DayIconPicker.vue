<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'

import type { DayIcon } from '@/api/plan-types'
import DayIconMark from '@/components/plans/DayIconMark.vue'
import { useDismissablePopover } from '@/composables/useDismissablePopover'
import { DAY_ICON_ORDER } from '@/features/plans/day-icons'

const model = defineModel<DayIcon | null>({ required: true })
const { t } = useI18n()
const { open, setRoot, toggle } = useDismissablePopover()

const iconLabel = (icon: DayIcon): string => t(`plans.day.icons.${icon}`)
const chosenLabel = computed(() =>
  model.value ? iconLabel(model.value) : t('plans.day.iconNone'),
)

function choose(icon: DayIcon | null): void {
  // Pressing the chosen icon again clears it, so there is no separate way back.
  model.value = icon === model.value ? null : icon
  open.value = false
}
</script>

<template>
  <div :ref="setRoot" class="day-icon-picker">
    <button
      type="button"
      class="day-icon-trigger"
      :class="{ unset: model === null }"
      :aria-expanded="open"
      :aria-haspopup="true"
      :aria-label="$t('plans.day.icon')"
      :title="chosenLabel"
      @click="toggle"
    >
      <DayIconMark v-if="model" :icon="model" :size="18" />
      <span v-else class="day-icon-blank" aria-hidden="true" />
      <span class="day-icon-trigger-name">{{ chosenLabel }}</span>
    </button>

    <div v-if="open" class="day-icon-popover" role="dialog" :aria-label="$t('plans.day.icon')">
      <button
        v-for="icon in DAY_ICON_ORDER"
        :key="icon"
        type="button"
        class="day-icon-option"
        :class="{ chosen: model === icon }"
        :title="iconLabel(icon)"
        :aria-label="iconLabel(icon)"
        @click="choose(icon)"
      >
        <DayIconMark :icon="icon" :size="20" />
      </button>
      <button
        type="button"
        class="day-icon-option day-icon-clear"
        :class="{ chosen: model === null }"
        :title="$t('plans.day.iconNone')"
        :aria-label="$t('plans.day.iconNone')"
        @click="choose(null)"
      ><span aria-hidden="true">×</span></button>
    </div>
  </div>
</template>

<style scoped>
.day-icon-picker { position: relative; display: inline-block; }

.day-icon-trigger {
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
.day-icon-trigger:hover { border-color: var(--border2); color: var(--text); }
.day-icon-trigger:focus-visible { outline: 2px solid var(--focus); outline-offset: 1px; }
.day-icon-trigger :deep(.day-icon-mark) { color: var(--planAccent, var(--accent)); }
.day-icon-blank {
  width: 14px;
  height: 14px;
  border: 1px dashed var(--border2);
  border-radius: 4px;
}

.day-icon-popover {
  position: absolute;
  z-index: 20;
  top: calc(100% + 6px);
  left: 0;
  display: grid;
  grid-template-columns: repeat(7, 32px);
  gap: 5px;
  padding: 10px;
  border: 1px solid var(--border2);
  border-radius: 10px;
  background: var(--panel2);
  box-shadow: var(--shadow);
}

.day-icon-option {
  display: grid;
  place-items: center;
  width: 32px;
  height: 32px;
  padding: 0;
  border: 1px solid var(--border);
  border-radius: 8px;
  background: var(--inputBg);
  color: var(--text3);
  cursor: pointer;
  transition: color 120ms ease, border-color 120ms ease, background 120ms ease;
}
.day-icon-option:hover { color: var(--text2); border-color: var(--border2); }
.day-icon-option:focus-visible { outline: 2px solid var(--focus); outline-offset: 1px; }
.day-icon-option.chosen {
  color: var(--planAccent, var(--accent));
  border-color: color-mix(in srgb, var(--planAccent, var(--accent)) 45%, var(--border));
  background: color-mix(in srgb, var(--planAccent, var(--accent)) 9%, var(--inputBg));
}
.day-icon-clear { font-size: 15px; line-height: 1; }
</style>
