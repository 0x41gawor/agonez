import { flushPromises, mount } from '@vue/test-utils'
import { afterEach, describe, expect, it, vi } from 'vitest'

import HomeCoaches from '@/components/home/HomeCoaches.vue'
import HomeClosing from '@/components/home/HomeClosing.vue'
import HomeHero from '@/components/home/HomeHero.vue'
import HomeImage from '@/components/home/HomeImage.vue'
import HomeModel from '@/components/home/HomeModel.vue'
import HomeShowcases from '@/components/home/HomeShowcases.vue'
import { useTheme } from '@/composables/useTheme'
import { setActiveLocale } from '@/i18n'
import router from '@/router'

afterEach(() => {
  vi.unstubAllGlobals()
})

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

  it('uses the cinematic hero artwork and distinct Agonez poses while keeping the primary logo in the footer', async () => {
    await setActiveLocale('en', { persist: false })
    const global = {
      stubs: {
        RouterLink: { template: '<a><slot /></a>' },
      },
    }
    const hero = mount(HomeHero, { global })
    const model = mount(HomeModel)
    const closing = mount(HomeClosing, { global })

    expect(hero.get('.home-hero-mark').attributes('src')).toBe('/img/home/brand/agonez-mark-hero.png')
    expect(hero.findAll('.home-hero-art source').map((source) => source.attributes('srcset'))).toEqual([
      '/img/home/hero-image-wide.webp',
      '/media/hero-image-wide.png',
      '/img/home/hero-image.webp',
    ])
    expect(hero.get('.home-hero-art source').attributes('media')).toBe('(min-width: 861px)')
    expect(hero.get('.home-hero-art img').attributes('src')).toBe('/media/hero-image.png')
    expect(hero.find('.home-browser').exists()).toBe(false)
    expect(model.get('.home-model-detail.is-reference img').attributes('src')).toBe('/img/home/brand/agonez-mark-athlete.png')
    expect(closing.get('.home-final-mark').attributes('src')).toBe('/img/home/brand/agonez-mark-final.png')
    expect(closing.get('.home-footer-brand img').attributes('src')).toBe('/img/home/brand/agonez-mark.png')
  })

  it('presents the beta waitlist and collaboration invitations', async () => {
    await setActiveLocale('en', { persist: false })
    const global = {
      stubs: {
        RouterLink: { template: '<a><slot /></a>' },
      },
    }
    const hero = mount(HomeHero, { global })
    const closing = mount(HomeClosing, { global })

    expect(hero.get('.home-beta-badge').text()).toBe('PRIVATE BETA · FALL 2026')
    expect(hero.get('input[type="email"]').attributes()).toMatchObject({
      autocomplete: 'email',
      placeholder: 'you@example.com',
      required: '',
    })
    expect(hero.get('.home-waitlist-note').text()).toBe('No spam. Just one email when your invitation is ready.')
    expect(closing.get('.home-final-content h2').text()).toBe('Help the humanity to obtain excellence in training')
    expect(closing.findAll('.home-collaboration-body')).toHaveLength(2)
    expect(closing.findAll('.home-collaboration-roles li')).toHaveLength(8)
    expect(closing.get('.home-collaboration-roles').text()).toContain('Marketing')
    expect(closing.find('.home-collaboration-note').exists()).toBe(false)
    expect(closing.get('.home-collaboration-action').attributes('href')).toMatch(/^mailto:/)

    await setActiveLocale('pl', { persist: false })
    expect(hero.get('.home-waitlist-row button').text()).toBe('Zapisz się')
  })

  it('submits a waitlist address directly and presents a localized confirmation', async () => {
    await setActiveLocale('pl', { persist: false })
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ accepted: true }), {
        status: 202,
        headers: { 'Content-Type': 'application/json' },
      }),
    )
    vi.stubGlobal('fetch', fetchMock)
    const wrapper = mount(HomeHero, {
      global: {
        stubs: {
          RouterLink: { template: '<a><slot /></a>' },
        },
      },
    })

    await wrapper.get('input[type="email"]').setValue('athlete@example.com')
    await wrapper.get('form').trigger('submit')
    await flushPromises()

    expect(fetchMock).toHaveBeenCalledOnce()
    const [path, request] = fetchMock.mock.calls[0] as [string, RequestInit]
    expect(path).toBe('/api/waitlist')
    expect(request.method).toBe('POST')
    expect(new Headers(request.headers).get('Accept-Language')).toBe('pl')
    expect(JSON.parse(String(request.body))).toEqual({
      email: 'athlete@example.com',
      website: '',
    })
    expect(wrapper.get('.home-waitlist-row button').text()).toBe('Zapisano')
    expect(wrapper.get('.home-waitlist-note').text()).toContain('Jesteś na liście')
    expect(wrapper.get('.home-waitlist-note').classes()).toContain('is-success')
    expect(wrapper.get('input[type="email"]').attributes('disabled')).toBeDefined()
  })

  it('uses percent-encoded Polish collaboration copy only for Polish', async () => {
    const global = {
      stubs: {
        RouterLink: { template: '<a><slot /></a>' },
      },
    }
    await setActiveLocale('pl', { persist: false })
    const closing = mount(HomeClosing, { global })
    const polishHref = closing.get('.home-collaboration-action').attributes('href') ?? ''

    expect(polishHref).not.toContain('+')
    expect(new URL(polishHref).searchParams.get('body')).toContain('Cześć')

    await setActiveLocale('tr', { persist: false })
    const englishHref = closing.get('.home-collaboration-action').attributes('href') ?? ''
    expect(englishHref).not.toContain('+')
    expect(new URL(englishHref).searchParams.get('subject')).toBe('Building Agonez together')
    expect(new URL(englishHref).searchParams.get('body')).toContain('Hi,')
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
