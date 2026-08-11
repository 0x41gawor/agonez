import { computed, ref } from 'vue'

export type Theme = 'dark' | 'light'

const STORAGE_KEY = 'agonez-theme'
const params = new URLSearchParams(window.location.search)
const queryTheme = params.get('theme')
const forcedTheme: Theme | null = queryTheme === 'dark' || queryTheme === 'light' ? queryTheme : null
const savedTheme = localStorage.getItem(STORAGE_KEY)
const theme = ref<Theme>(forcedTheme ?? (savedTheme === 'light' ? 'light' : 'dark'))

function applyTheme(value: Theme): void {
  document.documentElement.dataset.theme = value
  document.querySelector('meta[name="theme-color"]')?.setAttribute('content', value === 'dark' ? '#0e1013' : '#f7f6f3')
}

applyTheme(theme.value)

export function useTheme() {
  const label = computed(() => (theme.value === 'dark' ? 'Dark' : 'Light'))

  function setTheme(value: Theme): void {
    theme.value = value
    localStorage.setItem(STORAGE_KEY, value)
    applyTheme(value)
  }

  function toggleTheme(): void {
    setTheme(theme.value === 'dark' ? 'light' : 'dark')
  }

  return { theme, label, forcedTheme, setTheme, toggleTheme }
}
