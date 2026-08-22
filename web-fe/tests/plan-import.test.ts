import { flushPromises, mount } from '@vue/test-utils'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createMemoryHistory, createRouter } from 'vue-router'

import { plansApi } from '@/api/plans'
import {
  PlanImportValidationError,
  parsePlanImportJson,
} from '@/features/plans/import'
import PlanListView from '@/views/PlanListView.vue'
import { planExportResult } from './fixtures/analysis'
import { planArtifact } from './fixtures/plans'

vi.mock('@/api/plans', () => ({
  plansApi: {
    list: vi.fn(),
    create: vi.fn(),
    importPlan: vi.fn(),
    duplicate: vi.fn(),
    delete: vi.fn(),
  },
}))

function testRouter() {
  return createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/plans', name: 'plans', component: PlanListView },
      { path: '/plans/:planId', name: 'plan-editor', component: { template: '<div />' } },
    ],
  })
}

describe('Plan JSON import', () => {
  beforeEach(() => {
    vi.resetAllMocks()
  })

  it('accepts the exact compact document produced by plan export', () => {
    const source = planExportResult()

    expect(parsePlanImportJson(JSON.stringify(source))).toEqual(source)
  })

  it('reports precise paths for structural and semantic errors', () => {
    const source = planExportResult() as unknown as Record<string, unknown>
    const days = source.days as Array<Record<string, unknown>>
    days[0]!.day = 2
    days[1]!.exercises = days[0]!.exercises
    source.internal_id = 99

    try {
      parsePlanImportJson(JSON.stringify(source))
      throw new Error('Expected import validation to fail')
    } catch (caught) {
      expect(caught).toBeInstanceOf(PlanImportValidationError)
      const issues = (caught as PlanImportValidationError).issues.join(' ')
      expect(issues).toContain('$.internal_id')
      expect(issues).toContain('$.days[0].day')
      expect(issues).toContain('$.days[1].exercises')
    }
  })

  it('reviews a selected file and atomically imports it as a new editable plan', async () => {
    vi.mocked(plansApi.list).mockResolvedValue({ items: [] })
    vi.mocked(plansApi.importPlan).mockResolvedValue(planArtifact())
    const router = testRouter()
    await router.push('/plans')
    const wrapper = mount(PlanListView, { global: { plugins: [router] } })
    await flushPromises()

    const source = planExportResult()
    const input = wrapper.get('input[type="file"]')
    Object.defineProperty(input.element, 'files', {
      configurable: true,
      value: [
        {
          name: 'pplpp-basic.json',
          size: 512,
          text: async () => JSON.stringify(source),
        },
      ],
    })
    await input.trigger('change')
    await flushPromises()

    expect(wrapper.get('.plan-import-dialog').text()).toContain('Create “PPLPP”')
    expect(wrapper.get('.plan-import-summary').text()).toContain('2')
    await wrapper.findAll('button').find((button) => button.text() === 'Import and open')!.trigger('click')
    await flushPromises()

    expect(plansApi.importPlan).toHaveBeenCalledWith(source)
    expect(router.currentRoute.value.path).toBe('/plans/11')
  })
})
