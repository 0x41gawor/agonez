import { i18n, intlLocale } from '@/i18n'

export function formatNumber(value: number | null | undefined, digits = 2): string {
  if (value == null || !Number.isFinite(value)) return '—'
  return new Intl.NumberFormat(intlLocale(), { maximumFractionDigits: digits }).format(value)
}

export function prettyToken(value: string | null | undefined): string {
  if (!value) return '—'
  const key = `tokens.${value.toLowerCase()}`
  if (!i18n.global.te(key)) return value.replaceAll('_', ' ')
  const label = i18n.global.t(key)
  return label.charAt(0).toLocaleUpperCase(intlLocale()) + label.slice(1)
}

export function percentage(value: number | null | undefined): string {
  if (value == null || !Number.isFinite(value)) return '—'
  return new Intl.NumberFormat(intlLocale(), {
    style: 'percent',
    maximumFractionDigits: 0,
  }).format(value)
}

export function formatDateTime(value: string | Date): string {
  return new Intl.DateTimeFormat(intlLocale(), {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value))
}

export function domainLabel(value: string): string {
  try {
    return new URL(value).hostname.replace(/^www\./, '')
  } catch {
    return i18n.global.t('common.externalLink')
  }
}
