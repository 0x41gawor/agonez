import { nextTick } from 'vue'
import { createI18n } from 'vue-i18n'

export const SUPPORTED_LOCALES = [
  'en',
  'pl',
  'fr',
  'es',
  'de',
  'it',
  'pt-BR',
  'sv',
  'nl',
  'uk',
  'tr',
] as const
export type SupportedLocale = (typeof SUPPORTED_LOCALES)[number]

export const DEFAULT_LOCALE: SupportedLocale = 'en'
export const LOCALE_STORAGE_KEY = 'agonez-locale'

const loaders: Record<SupportedLocale, () => Promise<{ default: Record<string, unknown> }>> = {
  en: () => import('./locales/en'),
  pl: () => import('./locales/pl'),
  fr: () => import('./locales/fr'),
  es: () => import('./locales/es'),
  de: () => import('./locales/de'),
  it: () => import('./locales/it'),
  'pt-BR': () => import('./locales/pt-BR'),
  sv: () => import('./locales/sv'),
  nl: () => import('./locales/nl'),
  uk: () => import('./locales/uk'),
  tr: () => import('./locales/tr'),
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
  const candidate = value.trim().replace('_', '-').toLowerCase()
  const exact = SUPPORTED_LOCALES.find((locale) => locale.toLowerCase() === candidate)
  if (exact) return exact

  const language = candidate.split('-')[0]
  if (language === 'pt') return 'pt-BR'
  return SUPPORTED_LOCALES.find((locale) => locale.split('-')[0] === language) ?? null
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
    it: 'it-IT',
    'pt-BR': 'pt-BR',
    sv: 'sv-SE',
    nl: 'nl-NL',
    uk: 'uk-UA',
    tr: 'tr-TR',
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
