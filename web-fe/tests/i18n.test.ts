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

function messageAt(value: unknown, path: string): unknown {
  return path.split('.').reduce<unknown>((current, key) => {
    if (!current || typeof current !== 'object') return undefined
    return (current as Record<string, unknown>)[key]
  }, value)
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
    type HomeEntryMessages = {
      home: {
        hero: { title: string; proof: string[]; betaBadge: string; waitlist: { button: string } }
        coaches: { adaptation: { title: string; body: string } }
        cta: { roles: string[] }
      }
    }
    const englishHome = (i18n.global.getLocaleMessage('en') as HomeEntryMessages).home
    const revisedCopyPaths = [
      'home.hero.eyebrow',
      'home.hero.lead',
      'home.hero.betaBadge',
      'home.hero.waitlist.label',
      'home.hero.waitlist.placeholder',
      'home.hero.waitlist.button',
      'home.hero.waitlist.note',
      'home.hero.waitlist.emailSubject',
      'home.hero.waitlist.emailBody',
      'home.audiences.beginner.body',
      'home.audiences.advanced.body',
      'home.audiences.coach.body',
      'home.loop.s2.body',
      'home.loop.s3.body',
      'home.planAnalysis.body',
      'home.planAnalysis.recovery.title',
      'home.planAnalysis.ranking.title',
      'home.planAnalysis.debts.body',
      'home.muscleAtlas.body',
      'home.features.io.body',
      'home.features.mobile.body',
      'home.features.knowledge.body',
      'home.model.etu.body',
      'home.model.recovery.body',
      'home.model.reference.caveat',
      'home.coaches.title',
      'home.coaches.audit.body',
      'home.coaches.argument.body',
      'home.roadmap.title',
      'home.cta.eyebrow',
      'home.cta.title',
      'home.cta.body',
      'home.cta.bodySecondary',
      'home.cta.rolesLabel',
      'home.cta.action',
      'home.cta.note',
      'home.cta.emailSubject',
      'home.cta.emailBody',
    ]
    const englishMessages = i18n.global.getLocaleMessage('en')

    for (const locale of SUPPORTED_LOCALES.filter((value) => value !== 'en')) {
      const localeMessages = i18n.global.getLocaleMessage(locale)
      const messages = localeMessages as HomeEntryMessages
      expect(messages.home.hero.title, locale).toBeTypeOf('string')
      expect(messages.home.hero.title, locale).not.toBe(englishHome.hero.title)
      expect(messages.home.hero.proof, locale).toHaveLength(englishHome.hero.proof.length)
      expect(messages.home.hero.proof, locale).not.toEqual(englishHome.hero.proof)
      expect(messages.home.coaches.adaptation.title, locale).toBeTypeOf('string')
      expect(messages.home.coaches.adaptation.body, locale).toBeTypeOf('string')
      expect(messages.home.coaches.adaptation.title, locale).not.toBe(englishHome.coaches.adaptation.title)
      expect(messages.home.cta.roles, locale).toHaveLength(englishHome.cta.roles.length)
      expect(messages.home.cta.roles, locale).not.toEqual(englishHome.cta.roles)

      for (const path of revisedCopyPaths) {
        expect(messageAt(localeMessages, path), `${locale}: ${path}`).toBeTypeOf('string')
        expect(messageAt(localeMessages, path), `${locale}: ${path}`).not.toBe(messageAt(englishMessages, path))
      }
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
