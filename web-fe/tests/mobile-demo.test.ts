import { mount } from '@vue/test-utils'
import { createMemoryHistory, createRouter } from 'vue-router'
import { describe, expect, it } from 'vitest'
import { nextTick } from 'vue'

import AppShell from '@/components/shell/AppShell.vue'
import { useTheme } from '@/composables/useTheme'
import MobileDemoView from '@/views/MobileDemoView.vue'
import router from '@/router'

describe('Mobile Demo integration', () => {
  it('registers the bookmarkable Mobile Demo route', () => {
    const route = router.getRoutes().find((candidate) => candidate.name === 'mobile-demo')
    expect(route?.path).toBe('/mobile-demo')
  })

  it('switches the unrestricted standalone prototype with the application theme', async () => {
    const { setTheme } = useTheme()
    setTheme('dark')
    const wrapper = mount(MobileDemoView)
    const frame = wrapper.get('iframe')

    expect(frame.attributes('src')).toBe('/static/mobile-demo/index-dark.html')
    expect(frame.attributes('title')).toBe('Mobile Demo')
    expect(frame.attributes('sandbox')).toBeUndefined()

    setTheme('light')
    await nextTick()
    expect(frame.attributes('src')).toBe('/static/mobile-demo/index-light.html')

    setTheme('dark')
  })

  it('shows Mobile Demo as the active first-class shell destination', async () => {
    const shellRouter = createRouter({
      history: createMemoryHistory(),
      routes: [
        { path: '/home', component: { template: '<div />' } },
        { path: '/atlas/exercises', component: { template: '<div />' } },
        { path: '/plans', component: { template: '<div />' } },
        { path: '/execution', component: { template: '<div />' } },
        { path: '/mobile-demo', component: { template: '<div />' } },
      ],
    })
    await shellRouter.push('/mobile-demo')
    await shellRouter.isReady()

    const wrapper = mount(AppShell, {
      slots: { default: '<div />' },
      global: { plugins: [shellRouter] },
    })
    const link = wrapper.get('.main-nav a[href="/mobile-demo"]')

    expect(link.text()).toBe('Mobile Demo')
    expect(link.classes()).toContain('active')
  })
})
