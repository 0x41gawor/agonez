import type { QueryRecord } from './types'
import { apiUrl } from './url'
import { activeLocale, i18n } from '@/i18n'

export class ApiError extends Error {
  constructor(
    message: string,
    public readonly status: number,
    public readonly details: unknown,
  ) {
    super(message)
    this.name = 'ApiError'
  }

  get code(): string | null {
    if (!this.details || typeof this.details !== 'object' || !('error' in this.details)) return null
    const error = (this.details as { error?: unknown }).error
    if (!error || typeof error !== 'object' || !('code' in error)) return null
    return typeof (error as { code?: unknown }).code === 'string'
      ? (error as { code: string }).code
      : null
  }
}

export function buildQuery(params: QueryRecord = {}): string {
  const search = new URLSearchParams()
  for (const [key, value] of Object.entries(params)) {
    if (value == null || value === '') continue
    if (Array.isArray(value)) {
      value.forEach((entry) => search.append(key, entry))
    } else {
      search.set(key, String(value))
    }
  }
  const encoded = search.toString()
  return encoded ? `?${encoded}` : ''
}

async function requestJson<T>(path: string, request: RequestInit): Promise<T> {
  const headers = new Headers(request.headers)
  headers.set('Accept-Language', activeLocale())
  request.headers = headers
  const response = await fetch(apiUrl(path), request)

  if (!response.ok) {
    const raw = await response.text()
    let details: unknown = raw
    try {
      details = JSON.parse(raw) as unknown
    } catch {
      // Keep a non-JSON proxy error as readable text.
    }
    const detail = apiErrorMessage(details) ?? response.statusText
    throw new ApiError(detail || i18n.global.t('errors.requestFailed'), response.status, details)
  }
  return response.json() as Promise<T>
}

function apiErrorMessage(details: unknown): string | null {
  if (!details || typeof details !== 'object') return null
  if ('error' in details) {
    const error = (details as { error?: unknown }).error
    if (error && typeof error === 'object' && 'message' in error) {
      return String((error as { message: unknown }).message)
    }
  }
  return 'detail' in details ? String((details as { detail: unknown }).detail) : null
}

export async function getJson<T>(path: string, params?: QueryRecord, signal?: AbortSignal): Promise<T> {
  const request: RequestInit = {
    headers: { Accept: 'application/json' },
  }
  if (signal) request.signal = signal
  return requestJson<T>(`${path}${buildQuery(params)}`, request)
}

export async function postJson<T>(path: string, body: unknown, signal?: AbortSignal): Promise<T> {
  const request: RequestInit = {
    method: 'POST',
    headers: { Accept: 'application/json', 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  }
  if (signal) request.signal = signal
  return requestJson<T>(path, request)
}

export async function putJson<T>(path: string, body: unknown, signal?: AbortSignal): Promise<T> {
  const request: RequestInit = {
    method: 'PUT',
    headers: { Accept: 'application/json', 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  }
  if (signal) request.signal = signal
  return requestJson<T>(path, request)
}

export async function patchJson<T>(path: string, body: unknown, signal?: AbortSignal): Promise<T> {
  const request: RequestInit = {
    method: 'PATCH',
    headers: { Accept: 'application/json', 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  }
  if (signal) request.signal = signal
  return requestJson<T>(path, request)
}

export async function deleteRequest(path: string, signal?: AbortSignal): Promise<void> {
  const request: RequestInit = {
    method: 'DELETE',
    headers: { Accept: 'application/json', 'Accept-Language': activeLocale() },
  }
  if (signal) request.signal = signal
  const response = await fetch(apiUrl(path), request)
  if (response.ok) return

  const raw = await response.text()
  let details: unknown = raw
  try {
    details = JSON.parse(raw) as unknown
  } catch {
    // Keep a non-JSON proxy error as readable text.
  }
  const detail = apiErrorMessage(details) ?? response.statusText
  throw new ApiError(detail || i18n.global.t('errors.requestFailed'), response.status, details)
}
