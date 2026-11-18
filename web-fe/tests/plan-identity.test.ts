import { flushPromises, mount } from '@vue/test-utils'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createMemoryHistory, createRouter } from 'vue-router'

import { plansApi } from '@/api/plans'
import { DAY_ICONS, PLAN_ACCENTS, type DayIcon, type PlanAccent, type PlanSummary } from '@/api/plan-types'
import DayIconPicker from '@/components/plans/DayIconPicker.vue'
import PlanAccentPicker from '@/components/plans/PlanAccentPicker.vue'
import { COVER_MAX_EDGE, coverDimensions } from '@/features/plans/cover-image'
import { DAY_ICON_GLYPHS, DAY_ICON_ORDER } from '@/features/plans/day-icons'
import { i18n } from '@/i18n'
import PlanListView from '@/views/PlanListView.vue'

vi.mock('@/api/plans', () => ({
  plansApi: {
    list: vi.fn(),
    create: vi.fn(),
    duplicate: vi.fn(),
    delete: vi.fn(),
  },
}))

const plan: PlanSummary = {
  id: 15,
  name: 'PPLPP',
  description: 'Five-day microcycle',
  accent: 'teal',
  image_url: '/api/plans/15/image?v=abc123',
  created_at: '2026-08-20T10:00:00Z',
  updated_at: '2026-08-21T10:00:00Z',
  draft_revision_id: 21,
  draft_lock_version: 4,
}

describe('day icon set', () => {
  it('draws every icon the API accepts, and offers each one exactly once', () => {
    const drawn = Object.keys(DAY_ICON_GLYPHS).sort()
    expect(drawn).toEqual([...DAY_ICONS].sort())
    expect([...DAY_ICON_ORDER].sort()).toEqual(drawn)
    expect(new Set(DAY_ICON_ORDER).size).toBe(DAY_ICON_ORDER.length)
  })

  it('carves every glyph from the same two tones, so the set reads as a family', () => {
    for (const [icon, glyph] of Object.entries(DAY_ICON_GLYPHS)) {
      expect(glyph, icon).toMatch(/<(path|circle|rect|ellipse)\b/)
      // Nothing may pin a colour: a glyph has to take the plan's accent.
      expect(glyph, icon).not.toMatch(/(fill|stroke)="(?!none|currentColor)/)
    }
  })

  it('sets a solid muscle against a quieted body in every muscle icon', () => {
    const muscles = ['chest', 'back', 'shoulders', 'core', 'glutes', 'calves'] as const
    for (const icon of muscles) {
      const glyph = DAY_ICON_GLYPHS[icon]
      // The body is drawn back: inked as a contour, or carved as faint stone.
      expect(glyph, icon).toMatch(/stroke-opacity|fill-opacity/)
      // And the muscle itself is plainly filled, with nothing holding it back.
      const lit = glyph.replace(/<[^>]*(stroke-opacity|fill-opacity)[^>]*>/g, '')
      expect(lit, icon).toMatch(/<(path|rect|circle|ellipse)\b/)
    }
  })

  it('lights a whole-region day end to end, leaving no stone in it', () => {
    for (const icon of ['full_body', 'upper', 'lower'] as const) {
      const lit = DAY_ICON_GLYPHS[icon].replace(/<[^>]*fill-opacity[^>]*>/g, '')
      // Whatever the stone layer draws, the lit layer draws over all of it.
      expect(lit, icon).toMatch(/<(path|rect|circle|ellipse)\b/)
    }
  })

  it('names every icon and every accent in the active locale', () => {
    for (const icon of DAY_ICONS) {
      expect(i18n.global.te(`plans.day.icons.${icon}`), icon).toBe(true)
    }
    for (const accent of PLAN_ACCENTS) {
      expect(i18n.global.te(`plans.accents.${accent}`), accent).toBe(true)
    }
  })
})

describe('day icon picker', () => {
  it('chooses an icon, and clears it when the same one is pressed again', async () => {
    const wrapper = mount(DayIconPicker, { props: { modelValue: null as DayIcon | null } })

    await wrapper.get('button[aria-label="Push"]').trigger('click')
    expect(wrapper.props('modelValue')).toBe(null)
    expect(wrapper.emitted('update:modelValue')?.at(-1)).toEqual(['push'])

    await wrapper.setProps({ modelValue: 'push' })
    expect(wrapper.get('button[aria-label="Push"]').attributes('aria-checked')).toBe('true')

    await wrapper.get('button[aria-label="Push"]').trigger('click')
    expect(wrapper.emitted('update:modelValue')?.at(-1)).toEqual([null])
  })
})

describe('accent picker', () => {
  it('keeps the palette out of the way until the swatch is pressed', async () => {
    const wrapper = mount(PlanAccentPicker, { props: { modelValue: null as PlanAccent | null } })

    expect(wrapper.findAll('.accent-swatch')).toHaveLength(0)
    expect(wrapper.get('.accent-trigger').text()).toBe('No accent')

    await wrapper.get('.accent-trigger').trigger('click')
    // Twelve colours and the way back to no accent at all.
    expect(wrapper.findAll('.accent-swatch')).toHaveLength(PLAN_ACCENTS.length + 1)

    await wrapper.get('button[aria-label="Teal"]').trigger('click')
    expect(wrapper.emitted('update:modelValue')?.at(-1)).toEqual(['teal'])
    expect(wrapper.findAll('.accent-swatch')).toHaveLength(0)
  })
})

describe('cover preparation', () => {
  it('shrinks a large photo to the stored edge while keeping its proportions', () => {
    expect(coverDimensions(4000, 3000)).toEqual({ width: COVER_MAX_EDGE, height: 720 })
    expect(coverDimensions(1200, 2400)).toEqual({ width: 480, height: COVER_MAX_EDGE })
  })

  it('never enlarges a picture that is already small', () => {
    expect(coverDimensions(320, 200)).toEqual({ width: 320, height: 200 })
  })
})

describe('plan cards', () => {
  beforeEach(() => {
    vi.resetAllMocks()
  })

  it('shows the cover and the accent, and falls back to the plan mark without one', async () => {
    vi.mocked(plansApi.list).mockResolvedValue({
      items: [plan, { ...plan, id: 16, name: 'Bare', accent: null, image_url: null }],
    })
    const router = createRouter({
      history: createMemoryHistory(),
      routes: [
        { path: '/plans', name: 'plans', component: PlanListView },
        { path: '/plans/:planId', name: 'plan-editor', component: { template: '<div />' } },
      ],
    })
    await router.push('/plans')
    const wrapper = mount(PlanListView, { global: { plugins: [router] } })
    await flushPromises()

    const cards = wrapper.findAll('.plan-card')
    expect(cards[0]!.attributes('data-accent')).toBe('teal')
    const cover = cards[0]!.get('.plan-card-mark img')
    expect(cover.attributes('src')).toContain('/api/plans/15/image?v=abc123')
    expect(cover.attributes('alt')).toBe('Cover of PPLPP')

    expect(cards[1]!.attributes('data-accent')).toBeUndefined()
    expect(cards[1]!.find('.plan-card-mark img').exists()).toBe(false)
    expect(cards[1]!.get('.plan-card-mark').text()).toBe('P016')
  })
})
