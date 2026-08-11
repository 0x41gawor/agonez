function trimTrailingSlash(value: string): string {
  return value.replace(/\/+$/, '')
}

export const apiBaseUrl = trimTrailingSlash(import.meta.env.VITE_API_BASE_URL ?? '')

export function apiUrl(path: string): string {
  if (/^https?:\/\//i.test(path)) return path
  const normalized = path.startsWith('/') ? path : `/${path}`
  return `${apiBaseUrl}${normalized}`
}

export function mediaUrl(path: string | null | undefined): string | null {
  return path ? apiUrl(path) : null
}
