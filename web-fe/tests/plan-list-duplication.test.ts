import { flushPromises, mount } from '@vue/test-utils'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createMemoryHistory, createRouter } from 'vue-router'

import { plansApi } from '@/api/plans'
import type { PlanSummary } from '@/api/plan-types'
import PlanListView from '@/views/PlanListView.vue'
import { planArtifact } from './fixtures/plans'

vi.mock('@/api/plans', () => ({
  plansApi: {
    list: vi.fn(),
    create: vi.fn(),
    duplicate: vi.fn(),
    delete: vi.fn(),
  },
}))

const source: PlanSummary = {
  id: 11,
  name: 'PPLPP',
  description: 'Five-day microcycle',
  created_at: '2026-08-20T10:00:00Z',
  updated_at: '2026-08-21T10:00:00Z',
  draft_revision_id: 21,
  draft_lock_version: 4,
}

const duplicate: PlanSummary = {
  ...source,
  id: 12,
  name: 'PPLPP copy',
  draft_revision_id: 22,
  draft_lock_version: 1,
}

function testRouter() {
  return createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/plans', name: 'plans', component: PlanListView },
      { path: '/plans/:planId', name: 'plan-editor', component: { template: '<div />' } },
    ],
  })
}

describe('My Plans deep-copy interaction', () => {
  beforeEach(() => {
    vi.resetAllMocks()
  })

  it('duplicates from a card, refreshes the list, and offers the independent copy', async () => {
    vi.mocked(plansApi.list)
      .mockResolvedValueOnce({ items: [source] })
      .mockResolvedValueOnce({ items: [duplicate, source] })
    vi.mocked(plansApi.duplicate).mockResolvedValue({
      ...planArtifact(),
      id: duplicate.id,
      revision_id: duplicate.draft_revision_id!,
      lock_version: 1,
      name: duplicate.name,
    })
    const router = testRouter()
    await router.push('/plans')
    const wrapper = mount(PlanListView, { global: { plugins: [router] } })
    await flushPromises()

    const action = wrapper.get('button[aria-label="Duplicate PPLPP"]')
    expect(action.element.closest('a')).toBeNull()
    await action.trigger('click')
    await flushPromises()

    expect(plansApi.duplicate).toHaveBeenCalledWith(11)
    expect(plansApi.list).toHaveBeenCalledTimes(2)
    expect(wrapper.text()).toContain('PPLPP copy')
    expect(wrapper.get('[role="status"]').text()).toContain('independent deep copy')
    expect(wrapper.get('[role="status"] a').attributes('href')).toBe('/plans/12')
  })
})
