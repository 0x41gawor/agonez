import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import HomeCoaches from '@/components/home/HomeCoaches.vue'
import HomeImage from '@/components/home/HomeImage.vue'
import HomeShowcases from '@/components/home/HomeShowcases.vue'
import { useTheme } from '@/composables/useTheme'
import { setActiveLocale } from '@/i18n'
import router from '@/router'

describe('Home page integration', () => {
  it('registers /home and deliberately redirects / to it', () => {
    const routes = router.getRoutes()
    expect(routes.some((route) => route.path === '/home' && route.name === 'home')).toBe(true)
    expect(routes.find((route) => route.path === '/')?.redirect).toBe('/home')
  })

  it('falls back from locale and theme to English theme and then English light', async () => {
    await setActiveLocale('de', { persist: false })
    useTheme().setTheme('dark')
    const wrapper = mount(HomeImage, {
      props: {
        path: 'hero/hero-stimulus-anatomy.png',
        alt: 'Stimulus anatomy',
        width: 592,
        height: 575,
      },
    })

    const image = wrapper.get('img')
    expect(image.attributes('src')).toBe('/img/home/de-dark/hero/hero-stimulus-anatomy.png')
    await image.trigger('error')
    expect(image.attributes('src')).toBe('/img/home/en-dark/hero/hero-stimulus-anatomy.png')
    await image.trigger('error')
    expect(image.attributes('src')).toBe('/img/home/en-light/hero/hero-stimulus-anatomy.png')
    await image.trigger('error')
    expect(image.attributes('src')).toBe('/img/home/en-light/hero/hero-stimulus-anatomy.png')
  })

  it('renders the athlete adaptation coaching tile', async () => {
    await setActiveLocale('en', { persist: false })
    const wrapper = mount(HomeCoaches, {
      global: {
        stubs: {
          RouterLink: { template: '<a><slot /></a>' },
        },
      },
    })

    expect(wrapper.findAll('.home-coach-grid article')).toHaveLength(5)
    expect(wrapper.get('.home-coach-grid').text()).toContain('Every athlete is different')
  })

  it('renders the localized exercise identity inside the detail grid', async () => {
    await setActiveLocale('pl', { persist: false })
    useTheme().setTheme('dark')
    const wrapper = mount(HomeShowcases, {
      global: {
        stubs: {
          RouterLink: { template: '<a><slot /></a>' },
        },
      },
    })

    const grid = wrapper.get('.home-detail-grid')
    const identity = wrapper.get('.home-exercise-identity')
    const image = identity.get('img')
    expect(identity.element.parentElement).toBe(grid.element)
    expect(wrapper.get('.home-exercise-etu').element.parentElement).toBe(grid.element)
    expect(image.attributes('src')).toBe('/img/home/pl-dark/atlas-exercises/exercise-name.png')
    expect(image.attributes('alt')).toContain('brzuszki na maszynie siedząc')
    expect(wrapper.get('.home-copy-card.is-etu img').attributes('src')).toBe('/img/home/pl-dark/plan-analysis/incidental-sets.png')
    expect(wrapper.get('.home-copy-card:not(.is-etu) img').attributes('src')).toBe('/img/home/pl-dark/plan-analysis/stimulus-origin.png')
  })
})
