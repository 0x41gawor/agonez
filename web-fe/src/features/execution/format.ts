import { intlLocale } from '@/i18n'

export function executionDate(value: string, options: Intl.DateTimeFormatOptions = { day: '2-digit', month: 'short' }): string {
  return new Intl.DateTimeFormat(intlLocale(), { ...options, timeZone: 'UTC' }).format(new Date(`${value}T12:00:00Z`))
}

export function executionDateTime(value: string | null): string {
  if (!value) return '—'
  return new Intl.DateTimeFormat(intlLocale(), { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' }).format(new Date(value))
}

export function weekdayShort(index: number): string {
  const date = new Date('2026-10-05T12:00:00Z')
  date.setUTCDate(date.getUTCDate() + index)
  return new Intl.DateTimeFormat(intlLocale(), { weekday: 'short', timeZone: 'UTC' }).format(date)
}

export function loadValue(value: number | null): string {
  if (value == null) return '—'
  return new Intl.NumberFormat(intlLocale(), { maximumFractionDigits: 2 }).format(value)
}

export function parseLoad(value: string): number | null | undefined {
  if (!value.trim()) return null
  const normalized = value.trim().replace(',', '.')
  if (!/^\d+(?:\.\d{1,2})?$/.test(normalized)) return undefined
  const number = Number(normalized)
  return Number.isFinite(number) && number >= 0 && number <= 1000 ? number : undefined
}
