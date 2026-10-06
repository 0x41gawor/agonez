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

function convertToLegacy(
  source: Record<string, unknown>,
  format: 'agonez-plan-sanity-v1' | 'agonez-plan-sanity-v2' | 'agonez-plan-sanity-v3',
): void {
  source.format = format
  const days = source.days as Array<{ exercises: Array<Record<string, unknown>> }>
  for (const day of days) {
    for (const exercise of day.exercises) {
      delete exercise.progression_id
      delete exercise.active_working_sets
      if (format === 'agonez-plan-sanity-v1') delete exercise.progression_model
      const sets = exercise.sets as Array<Record<string, unknown>>
      for (const set of sets) {
        const reps = set.reps as Record<string, unknown>
        delete reps.semantics
        set.rir = Number(String(set.rir).replace('RIR', ''))
        delete set.role
        delete set.load_spec
      }
    }
  }
}

describe('Plan JSON import', () => {
  beforeEach(() => {
    vi.resetAllMocks()
  })

  it('accepts the exact compact document produced by plan export', () => {
    const source = planExportResult()

    expect(parsePlanImportJson(JSON.stringify(source))).toEqual(source)
  })

  it('keeps accepting legacy V1 documents without progression metadata', () => {
    const source = planExportResult() as unknown as Record<string, unknown>
    convertToLegacy(source, 'agonez-plan-sanity-v1')

    const parsed = parsePlanImportJson(JSON.stringify(source))
    expect(parsed.format).toBe('agonez-plan-sanity-v1')
    expect(parsed.days[0]?.exercises[0]?.progression_model).toBeUndefined()
    expect(parsed.days[0]?.exercises[0]?.sets[0]).toMatchObject({
      reps: { min: 5, max: 7, semantics: 'undefined' },
      rir: 'RIR2',
      role: 'working',
      load_spec: { kind: 'absolute' },
    })
  })

  it('requires an explicit progression model or null in V3', () => {
    const source = planExportResult() as unknown as Record<string, unknown>
    convertToLegacy(source, 'agonez-plan-sanity-v3')
    const days = source.days as Array<{ exercises: Array<Record<string, unknown>> }>
    delete days[0]!.exercises[0]!.progression_model

    expect(() => parsePlanImportJson(JSON.stringify(source))).toThrow(
      /progression_model is required/,
    )
  })

  it('keeps accepting V2 documents with rich progression metadata', () => {
    const source = planExportResult() as unknown as Record<string, unknown>
    convertToLegacy(source, 'agonez-plan-sanity-v2')
    const days = source.days as Array<{ exercises: Array<Record<string, unknown>> }>
    days[0]!.exercises[0]!.progression_model = {
      slug: 'double_progression',
      name: 'Double progression',
      when_to_use: 'Use for stable ranges.',
    }

    const parsed = parsePlanImportJson(JSON.stringify(source))
    expect(parsed.days[0]?.exercises[0]?.progression_model).toEqual(
      days[0]!.exercises[0]!.progression_model,
    )
    expect(parsed.days[0]?.exercises[0]?.sets[0]?.rir).toBe('RIR2')
  })

  it('does not accept rich progression metadata in compact V3', () => {
    const source = planExportResult() as unknown as Record<string, unknown>
    convertToLegacy(source, 'agonez-plan-sanity-v3')
    const days = source.days as Array<{ exercises: Array<Record<string, unknown>> }>
    days[0]!.exercises[0]!.progression_model = { slug: 'double_progression' }

    expect(() => parsePlanImportJson(JSON.stringify(source))).toThrow(
      /progression_model must be a non-empty string/,
    )
  })

  it('rejects invalid V4 set references and active working-set bounds', () => {
    const source = planExportResult() as unknown as Record<string, unknown>
    const exercises = (source.days as Array<{ exercises: Array<Record<string, unknown>> }>)[0]!.exercises
    const exercise = exercises[0]!
    exercise.active_working_sets = { min: 1, max: 2 }
    const sets = exercise.sets as Array<Record<string, unknown>>
    sets[0]!.load_spec = { kind: 'relative_to_set', ref_set_idx: 0, pct: 92 }

    try {
      parsePlanImportJson(JSON.stringify(source))
      throw new Error('Expected V4 metadata validation to fail')
    } catch (caught) {
      expect(caught).toBeInstanceOf(PlanImportValidationError)
      const issues = (caught as PlanImportValidationError).issues.join(' ')
      expect(issues).toContain('active_working_sets.max must not exceed 1 working sets')
      expect(issues).toContain('must not reference itself')
    }
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
