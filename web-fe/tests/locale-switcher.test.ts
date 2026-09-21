import { flushPromises, mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

import LocaleSwitcher from '@/components/shell/LocaleSwitcher.vue'
import { activeLocale, LOCALE_STORAGE_KEY } from '@/i18n'

describe('LocaleSwitcher', () => {
  it('opens an accessible native-language menu for every supported locale', async () => {
    const wrapper = mount(LocaleSwitcher, { attachTo: document.body })
    const trigger = wrapper.get('.locale-trigger')

    expect(trigger.attributes('aria-expanded')).toBe('false')
    expect(trigger.text()).toContain('EN')

    await trigger.trigger('click')
    const options = wrapper.findAll('[role="menuitemradio"]')

    expect(trigger.attributes('aria-expanded')).toBe('true')
    expect(options).toHaveLength(11)
    expect(options.map((option) => option.text())).toEqual(
      expect.arrayContaining([
        expect.stringContaining('English'),
        expect.stringContaining('Italiano'),
        expect.stringContaining('Português (Brasil)'),
        expect.stringContaining('Українська'),
        expect.stringContaining('Türkçe'),
      ]),
    )
    expect(options[0]?.attributes('aria-checked')).toBe('true')

    wrapper.unmount()
  })

  it('changes and persists the selected locale, then closes the menu', async () => {
    const wrapper = mount(LocaleSwitcher, { attachTo: document.body })

    await wrapper.get('.locale-trigger').trigger('click')
    const italian = wrapper
      .findAll<HTMLButtonElement>('[role="menuitemradio"]')
      .find((option) => option.text().includes('Italiano'))
    expect(italian).toBeDefined()

    await italian!.trigger('click')
    await flushPromises()

    await vi.waitFor(() => expect(activeLocale()).toBe('it'))
    expect(localStorage.getItem(LOCALE_STORAGE_KEY)).toBe('it')
    expect(wrapper.get('.locale-trigger').text()).toContain('IT')
    expect(wrapper.find('[role="menu"]').exists()).toBe(false)

    wrapper.unmount()
  })

  it('supports arrow navigation and returns focus on Escape', async () => {
    const wrapper = mount(LocaleSwitcher, { attachTo: document.body })
    const trigger = wrapper.get<HTMLButtonElement>('.locale-trigger')

    await trigger.trigger('keydown', { key: 'ArrowDown' })
    await flushPromises()
    const options = wrapper.findAll<HTMLButtonElement>('[role="menuitemradio"]')

    expect(document.activeElement).toBe(options[0]?.element)
    await options[0]!.trigger('keydown', { key: 'ArrowDown' })
    expect(document.activeElement).toBe(options[1]?.element)

    await options[1]!.trigger('keydown', { key: 'Escape' })
    await flushPromises()
    expect(wrapper.find('[role="menu"]').exists()).toBe(false)
    expect(document.activeElement).toBe(trigger.element)

    wrapper.unmount()
  })

  it('closes when the user presses outside the selector', async () => {
    const wrapper = mount(LocaleSwitcher, { attachTo: document.body })

    await wrapper.get('.locale-trigger').trigger('click')
    document.body.dispatchEvent(new MouseEvent('pointerdown', { bubbles: true }))
    await flushPromises()

    expect(wrapper.find('[role="menu"]').exists()).toBe(false)
    wrapper.unmount()
  })
})
