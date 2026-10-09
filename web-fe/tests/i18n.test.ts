import { describe, expect, it, vi } from 'vitest'

import { getJson } from '@/api/client'
import dePlans from '@/i18n/locales/de/plans'
import deExecution from '@/i18n/locales/de/execution'
import enExecution from '@/i18n/locales/en/execution'
import enPlans from '@/i18n/locales/en/plans'
import esExecution from '@/i18n/locales/es/execution'
import esPlans from '@/i18n/locales/es/plans'
import frExecution from '@/i18n/locales/fr/execution'
import frPlans from '@/i18n/locales/fr/plans'
import itExecution from '@/i18n/locales/it/execution'
import itPlans from '@/i18n/locales/it/plans'
import nlExecution from '@/i18n/locales/nl/execution'
import nlPlans from '@/i18n/locales/nl/plans'
import plExecution from '@/i18n/locales/pl/execution'
import plPlans from '@/i18n/locales/pl/plans'
import ptBRExecution from '@/i18n/locales/pt-BR/execution'
import ptBRPlans from '@/i18n/locales/pt-BR/plans'
import svExecution from '@/i18n/locales/sv/execution'
import svPlans from '@/i18n/locales/sv/plans'
import trExecution from '@/i18n/locales/tr/execution'
import trPlans from '@/i18n/locales/tr/plans'
import ukExecution from '@/i18n/locales/uk/execution'
import ukPlans from '@/i18n/locales/uk/plans'
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

function stringMessages(value: unknown, prefix = ''): Array<[string, string]> {
  if (typeof value === 'string') return [[prefix, value]]
  if (Array.isArray(value)) {
    return value.flatMap((child, index) => stringMessages(child, `${prefix}.${index}`))
  }
  if (value && typeof value === 'object') {
    return Object.entries(value).flatMap(([key, child]) =>
      stringMessages(child, prefix ? `${prefix}.${key}` : key),
    )
  }
  return []
}

function interpolationTokens(value: string): string[] {
  return [...value.matchAll(/\{[A-Za-z_][A-Za-z0-9_]*\}/g)].map((match) => match[0]).sort()
}

describe('frontend locale runtime', () => {
  it('provides complete native Execution copy with aligned placeholders in every locale', async () => {
    const rawExecution = {
      en: enExecution, pl: plExecution, fr: frExecution, es: esExecution, de: deExecution,
      it: itExecution, 'pt-BR': ptBRExecution, sv: svExecution, nl: nlExecution,
      uk: ukExecution, tr: trExecution,
    }
    const englishPaths = messageLeaves(rawExecution.en).sort()
    const englishStrings = new Map(stringMessages(rawExecution.en))
    const representativeNativePaths = [
      'execution.tabs.overview',
      'execution.common.today',
      'execution.run.emptyBody',
      'execution.overview.didPlanHappen',
      'execution.analysis.confirmLeave',
      'execution.editor.saveNext',
      'execution.timeline.journal',
      'execution.loads.title',
      'execution.newRun.title',
    ]
    const interpolationValues = {
      plan: 'Plan', count: 3, start: '2026-10-01', end: '2026-11-01', days: 7,
      current: 2, total: 8, day: 3, runDay: 10, runDays: 56, left: 46, mc: 4,
      workout: 'Push A', saved: 2, locked: 1, date: '2026-10-09', slot: 1,
      sets: 3, min: 5, max: 7, rir: 1, from: 1, revisions: '1–2', set: 1,
      exercise: 'Bench Press', changes: 'Changed', reps: '7/6/5', loads: '70/70/70',
      top: 1, floor: 1, deeper: 0, step: 2.5, load: 70, revision: 2,
      state: 'ready', shown: 3, reason: 'skipped',
    }

    for (const locale of SUPPORTED_LOCALES) {
      const raw = rawExecution[locale]
      expect(messageLeaves(raw).sort(), locale).toEqual(englishPaths)

      for (const [path, englishMessage] of englishStrings) {
        const localized = messageAt(raw, path)
        expect(localized, `${locale}: ${path}`).toBeTypeOf('string')
        expect(interpolationTokens(String(localized)), `${locale}: ${path}`)
          .toEqual(interpolationTokens(englishMessage))
      }

      if (locale !== 'en') {
        for (const path of representativeNativePaths) {
          expect(messageAt(raw, path), `${locale}: ${path}`)
            .not.toBe(messageAt(rawExecution.en, path))
        }
      }

      await setActiveLocale(locale, { persist: false })
      for (const [path] of englishStrings) {
        expect(() => i18n.global.t(path, interpolationValues), `${locale}: ${path}`).not.toThrow()
      }
    }
  })

  it('defines native PlanCreator prescription-metadata copy in every locale pack', () => {
    const rawPlans = {
      en: enPlans, pl: plPlans, fr: frPlans, es: esPlans, de: dePlans, it: itPlans,
      'pt-BR': ptBRPlans, sv: svPlans, nl: nlPlans, uk: ukPlans, tr: trPlans,
    }
    const featurePaths = [
      'plans.editor.validation.activeWorkingSets',
      'plans.editor.validation.setReference',
      'plans.setEditor.role',
      'plans.setEditor.metadataHelp',
      'plans.setRoles.rampup',
      'plans.rir.undefined',
      'plans.repSemantics.gating',
      'plans.loadSpecs.athlete_selected',
      'plans.exerciseMetadata.title',
      'plans.exerciseMetadata.progressionLoopHelp',
      'plans.exerciseMetadata.workingAvailable',
    ]
    const distinctFromEnglish = [
      'plans.editor.validation.setReference',
      'plans.setEditor.metadataHelp',
      'plans.loadSpecs.athlete_selected',
      'plans.exerciseMetadata.title',
      'plans.exerciseMetadata.progressionLoopHelp',
    ]

    for (const locale of SUPPORTED_LOCALES.filter((value) => value !== 'en')) {
      for (const path of featurePaths) {
        const localized = messageAt(rawPlans[locale], path)
        expect(localized, `${locale}: ${path}`).toBeTypeOf('string')
      }
      for (const path of distinctFromEnglish) {
        const localized = messageAt(rawPlans[locale], path)
        expect(localized, `${locale}: ${path}`).not.toBe(messageAt(rawPlans.en, path))
      }
    }
  })

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
    expect(normalizeLocale('tr-TR')).toBe('tr')
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

  it('keeps every Turkish interpolation placeholder aligned with English', async () => {
    await Promise.all([loadLocale('en'), loadLocale('tr')])
    const english = new Map(stringMessages(i18n.global.getLocaleMessage('en')))
    const turkish = new Map(stringMessages(i18n.global.getLocaleMessage('tr')))

    for (const [path, englishMessage] of english) {
      expect(interpolationTokens(turkish.get(path) ?? ''), path).toEqual(interpolationTokens(englishMessage))
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
      'home.hero.waitlist.submitting',
      'home.hero.waitlist.joined',
      'home.hero.waitlist.success',
      'home.hero.waitlist.error',
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
    ['tr', 'tr-TR'],
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
    await setActiveLocale('tr', { persist: false })
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ ok: true }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }),
    )
    vi.stubGlobal('fetch', fetchMock)

    await getJson('/api/example')

    const request = fetchMock.mock.calls[0]?.[1] as RequestInit
    expect(new Headers(request.headers).get('Accept-Language')).toBe('tr')
    vi.unstubAllGlobals()
  })
})
