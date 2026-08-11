import { beforeEach, describe, expect, it, vi } from 'vitest'

describe('theme persistence and deterministic query override', () => {
  beforeEach(() => {
    vi.resetModules()
    history.replaceState({}, '', '/')
  })

  it('restores the saved light theme and applies it immediately', async () => {
    localStorage.setItem('agonez-theme', 'light')
    const { useTheme } = await import('@/composables/useTheme')
    expect(useTheme().theme.value).toBe('light')
    expect(document.documentElement.dataset.theme).toBe('light')
  })

  it('lets a theme query override the saved value for visual testing', async () => {
    localStorage.setItem('agonez-theme', 'light')
    history.replaceState({}, '', '/atlas/exercises?theme=dark')
    const { useTheme } = await import('@/composables/useTheme')
    expect(useTheme().theme.value).toBe('dark')
    expect(document.documentElement.dataset.theme).toBe('dark')
  })
})
