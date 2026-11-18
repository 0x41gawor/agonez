<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'

import type { DayIcon } from '@/api/plan-types'
import DayIconMark from '@/components/plans/DayIconMark.vue'
import { DAY_ICON_ORDER } from '@/features/plans/day-icons'

const model = defineModel<DayIcon | null>({ required: true })
const { t } = useI18n()

const iconLabel = (icon: DayIcon): string => t(`plans.day.icons.${icon}`)
const selectedLabel = computed(() =>
  model.value ? iconLabel(model.value) : t('plans.day.iconNone'),
)

function choose(icon: DayIcon): void {
  // Clicking the chosen icon again clears it, so the day can go back to no icon
  // without hunting for a separate control.
  model.value = model.value === icon ? null : icon
}
</script>

<template>
  <div class="day-icon-picker">
    <div class="day-icon-grid" role="radiogroup" :aria-label="$t('plans.day.icon')">
      <button
        v-for="icon in DAY_ICON_ORDER"
        :key="icon"
        type="button"
        class="day-icon-option"
        role="radio"
        :class="{ chosen: model === icon }"
        :aria-checked="model === icon"
        :title="iconLabel(icon)"
        :aria-label="iconLabel(icon)"
        @click="choose(icon)"
      >
        <DayIconMark :icon="icon" :size="20" />
      </button>
    </div>
    <p class="day-icon-chosen">
      {{ selectedLabel }}
      <button
        v-if="model"
        type="button"
        class="day-icon-clear"
        @click="model = null"
      >{{ $t('plans.day.iconClear') }}</button>
    </p>
  </div>
</template>

<style scoped>
.day-icon-picker { display: grid; gap: 6px; }
.day-icon-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
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
.day-icon-chosen {
  margin: 0;
  display: flex;
  align-items: baseline;
  gap: 8px;
  font-size: 12px;
  color: var(--text2);
}
.day-icon-clear {
  padding: 0;
  border: 0;
  background: none;
  color: var(--text3);
  font-size: 11.5px;
  text-decoration: underline;
  cursor: pointer;
}
.day-icon-clear:hover { color: var(--text2); }
</style>
