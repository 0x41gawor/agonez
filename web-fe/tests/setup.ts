import { afterEach, beforeEach } from 'vitest'
import { config } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'

import { i18n, initializeTestI18n, setActiveLocale } from '@/i18n'

await initializeTestI18n()

beforeEach(() => {
  const pinia = createPinia()
  setActivePinia(pinia)
  config.global.plugins = [i18n, pinia]
})

afterEach(async () => {
  document.documentElement.removeAttribute('data-theme')
  localStorage.clear()
  await setActiveLocale('en', { persist: false })
})
