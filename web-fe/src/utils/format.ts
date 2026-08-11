export function formatNumber(value: number | null | undefined, digits = 2): string {
  if (value == null || !Number.isFinite(value)) return '—'
  return new Intl.NumberFormat('en-US', { maximumFractionDigits: digits }).format(value)
}

export function prettyToken(value: string | null | undefined): string {
  if (!value) return '—'
  return value.replaceAll('_', ' ')
}

export function percentage(value: number | null | undefined): string {
  if (value == null || !Number.isFinite(value)) return '—'
  return `${Math.round(value * 100)}%`
}

export function domainLabel(value: string): string {
  try {
    return new URL(value).hostname.replace(/^www\./, '')
  } catch {
    return 'external link'
  }
}
