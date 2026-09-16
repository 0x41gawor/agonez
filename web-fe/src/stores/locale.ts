import { computed, ref } from 'vue'
import { defineStore } from 'pinia'

import {
  activeLocale,
  i18n,
  setActiveLocale,
  SUPPORTED_LOCALES,
  type SupportedLocale,
} from '@/i18n'

export const useLocaleStore = defineStore('locale', () => {
  const switching = ref(false)
  const current = computed(() => i18n.global.locale.value as SupportedLocale)

  async function change(locale: SupportedLocale): Promise<void> {
    if (locale === activeLocale() || switching.value) return
    switching.value = true
    try {
      await setActiveLocale(locale)
    } finally {
      switching.value = false
    }
  }

  return { current, switching, supported: SUPPORTED_LOCALES, change }
})
