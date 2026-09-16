import { nextTick } from 'vue'
import { createI18n } from 'vue-i18n'

export const SUPPORTED_LOCALES = ['en', 'pl', 'fr', 'es', 'de'] as const
export type SupportedLocale = (typeof SUPPORTED_LOCALES)[number]

export const DEFAULT_LOCALE: SupportedLocale = 'en'
export const LOCALE_STORAGE_KEY = 'agonez-locale'

const loaders: Record<SupportedLocale, () => Promise<{ default: Record<string, unknown> }>> = {
  en: () => import('./locales/en'),
  pl: () => import('./locales/pl'),
  fr: () => import('./locales/fr'),
  es: () => import('./locales/es'),
  de: () => import('./locales/de'),
}
const loaded = new Set<SupportedLocale>()

export const i18n = createI18n({
  legacy: false,
  locale: DEFAULT_LOCALE,
  fallbackLocale: DEFAULT_LOCALE,
  messages: {},
  missingWarn: import.meta.env.DEV,
  fallbackWarn: import.meta.env.DEV,
})

export function normalizeLocale(value: string | null | undefined): SupportedLocale | null {
  if (!value) return null
  const language = value.trim().toLowerCase().split('-')[0]
  return SUPPORTED_LOCALES.find((locale) => locale === language) ?? null
}

export function detectInitialLocale(): SupportedLocale {
  const saved = normalizeLocale(localStorage.getItem(LOCALE_STORAGE_KEY))
  if (saved) return saved
  for (const candidate of navigator.languages ?? [navigator.language]) {
    const locale = normalizeLocale(candidate)
    if (locale) return locale
  }
  return DEFAULT_LOCALE
}

export function activeLocale(): SupportedLocale {
  return normalizeLocale(i18n.global.locale.value) ?? DEFAULT_LOCALE
}

export function intlLocale(locale: SupportedLocale = activeLocale()): string {
  return {
    en: 'en-US',
    pl: 'pl-PL',
    fr: 'fr-FR',
    es: 'es-ES',
    de: 'de-DE',
  }[locale]
}

export async function loadLocale(locale: SupportedLocale): Promise<void> {
  if (loaded.has(locale)) return
  const messages = await loaders[locale]()
  i18n.global.setLocaleMessage(locale, messages.default)
  loaded.add(locale)
}

export async function setActiveLocale(
  locale: SupportedLocale,
  options: { persist?: boolean } = {},
): Promise<void> {
  await loadLocale(locale)
  i18n.global.locale.value = locale
  document.documentElement.lang = locale
  if (options.persist !== false) localStorage.setItem(LOCALE_STORAGE_KEY, locale)
  await nextTick()
}

export async function initializeI18n(): Promise<typeof i18n> {
  const locale = detectInitialLocale()
  await loadLocale(DEFAULT_LOCALE)
  await setActiveLocale(locale, { persist: false })
  return i18n
}

export async function initializeTestI18n(): Promise<void> {
  await setActiveLocale(DEFAULT_LOCALE, { persist: false })
}
