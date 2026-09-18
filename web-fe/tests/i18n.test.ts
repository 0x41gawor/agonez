import { describe, expect, it, vi } from 'vitest'

import { getJson } from '@/api/client'
import {
  activeLocale,
  detectInitialLocale,
  i18n,
  intlLocale,
  loadLocale,
  LOCALE_STORAGE_KEY,
  normalizeLocale,
  setActiveLocale,
  SUPPORTED_LOCALES,
} from '@/i18n'
import { formatNumber } from '@/utils/format'

function messageLeaves(value: unknown, prefix = ''): string[] {
  if (Array.isArray(value)) return [prefix]
  if (value && typeof value === 'object') {
    return Object.entries(value).flatMap(([key, child]) =>
      messageLeaves(child, prefix ? `${prefix}.${key}` : key),
    )
  }
  return [prefix]
}

describe('frontend locale runtime', () => {
  it('normalizes every supported regional tag and rejects unsupported languages', () => {
    expect(normalizeLocale('pl-PL')).toBe('pl')
    expect(normalizeLocale('EN-us')).toBe('en')
    expect(normalizeLocale('fr-CA')).toBe('fr')
    expect(normalizeLocale('es-MX')).toBe('es')
    expect(normalizeLocale('de-DE')).toBe('de')
    expect(normalizeLocale('it-IT')).toBe('it')
    expect(normalizeLocale('pt-PT')).toBe('pt-BR')
    expect(normalizeLocale('sv-SE')).toBe('sv')
    expect(normalizeLocale('nl-BE')).toBe('nl')
    expect(normalizeLocale('uk-UA')).toBe('uk')
    expect(normalizeLocale('ja-JP')).toBeNull()
  })

  it('keeps established application namespaces structurally complete against English', async () => {
    await Promise.all(SUPPORTED_LOCALES.map((locale) => loadLocale(locale)))
    const english = messageLeaves(i18n.global.getLocaleMessage('en'))
      .filter((key) => !key.startsWith('home.'))
      .sort()

    for (const locale of SUPPORTED_LOCALES.filter((value) => value !== 'en')) {
      const localized = messageLeaves(i18n.global.getLocaleMessage(locale))
        .filter((key) => !key.startsWith('home.'))
        .sort()
      expect(localized, locale).toEqual(english)
    }
  })

  it('localizes the Home entry point in every locale and uses the configured English fallback', async () => {
    await Promise.all(SUPPORTED_LOCALES.map((locale) => loadLocale(locale)))
    type HomeEntryMessages = { home: { hero: { title: string } } }
    const englishTitle = (i18n.global.getLocaleMessage('en') as HomeEntryMessages).home.hero.title

    for (const locale of SUPPORTED_LOCALES.filter((value) => value !== 'en')) {
      const messages = i18n.global.getLocaleMessage(locale) as HomeEntryMessages
      expect(messages.home.hero.title, locale).toBeTypeOf('string')
      expect(messages.home.hero.title, locale).not.toBe(englishTitle)
    }

    await setActiveLocale('fr', { persist: false })
    expect(i18n.global.t('home.images.atlasGrid')).toBe(
      'Exercise Atlas card grid with filters and a persistent anatomy view',
    )
  })

  it.each([
    ['fr', 'fr-FR'],
    ['es', 'es-ES'],
    ['de', 'de-DE'],
    ['it', 'it-IT'],
    ['pt-BR', 'pt-BR'],
    ['sv', 'sv-SE'],
    ['nl', 'nl-NL'],
    ['uk', 'uk-UA'],
  ] as const)('activates %s with its regional formatting locale', async (locale, expectedIntl) => {
    await setActiveLocale(locale, { persist: false })

    expect(activeLocale()).toBe(locale)
    expect(document.documentElement.lang).toBe(locale)
    expect(intlLocale()).toBe(expectedIntl)
    expect(i18n.global.t('plans.title')).not.toBe('plans.title')
  })

  it('prefers a saved locale and persists an explicit change', async () => {
    localStorage.setItem(LOCALE_STORAGE_KEY, 'pl-PL')
    expect(detectInitialLocale()).toBe('pl')

    await setActiveLocale('pl')
    expect(activeLocale()).toBe('pl')
    expect(document.documentElement.lang).toBe('pl')
    expect(localStorage.getItem(LOCALE_STORAGE_KEY)).toBe('pl')
    expect(formatNumber(1234.5, 1)).toContain(',5')
  })

  it('sends the selected language with API requests', async () => {
    await setActiveLocale('pl', { persist: false })
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ ok: true }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }),
    )
    vi.stubGlobal('fetch', fetchMock)

    await getJson('/api/example')

    const request = fetchMock.mock.calls[0]?.[1] as RequestInit
    expect(new Headers(request.headers).get('Accept-Language')).toBe('pl')
    vi.unstubAllGlobals()
  })
})
