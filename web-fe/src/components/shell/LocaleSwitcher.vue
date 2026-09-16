<script setup lang="ts">
import type { SupportedLocale } from '@/i18n'
import { useLocaleStore } from '@/stores/locale'

const locale = useLocaleStore()

function change(event: Event): void {
  void locale.change((event.target as HTMLSelectElement).value as SupportedLocale)
}
</script>

<template>
  <label class="locale-switcher" :title="$t('locale.label')">
    <span class="sr-only">{{ $t('locale.label') }}</span>
    <select :value="locale.current" :disabled="locale.switching" @change="change">
      <option v-for="option in locale.supported" :key="option" :value="option">
        {{ option.toUpperCase() }}
      </option>
    </select>
  </label>
</template>
