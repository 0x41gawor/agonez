import { defineComponent } from 'vue'
import { flushPromises, mount } from '@vue/test-utils'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import { atlasApi } from '@/api/atlas'
import { plansApi } from '@/api/plans'
import PlanCreatorView from '@/views/PlanCreatorView.vue'
import { analysisResult, planExportResult } from './fixtures/analysis'
import { exercise, muscle, planArtifact } from './fixtures/plans'

vi.mock('vue-router', async (importOriginal) => ({
  ...(await importOriginal<typeof import('vue-router')>()),
  onBeforeRouteLeave: vi.fn(),
}))

vi.mock('@/api/plans', () => ({
  plansApi: {
    draft: vi.fn(),
    saveDraft: vi.fn(),
    analyzeDraft: vi.fn(),
    exportDraft: vi.fn(),
  },
}))

vi.mock('@/api/atlas', () => ({
  atlasApi: {
    exercises: vi.fn(),
    muscles: vi.fn(),
  },
}))

const BodyViewerStub = defineComponent({
  name: 'BodyViewer',
  props: ['vector', 'tooltipValues'],
  template: '<div class="body-viewer-stub" />',
})

function mountView() {
  return mount(PlanCreatorView, {
    props: { planId: '11' },
    global: {
      stubs: {
        RouterLink: { template: '<a><slot /></a>' },
        BodyViewer: BodyViewerStub,
      },
    },
  })
}

describe('PlanCreator Analysis tab integration', () => {
  beforeEach(() => {
    vi.mocked(plansApi.draft).mockReset()
    vi.mocked(plansApi.saveDraft).mockReset()
    vi.mocked(plansApi.analyzeDraft).mockReset()
    vi.mocked(plansApi.exportDraft).mockReset()
    vi.mocked(atlasApi.exercises).mockReset()
    vi.mocked(atlasApi.muscles).mockReset()

    vi.mocked(plansApi.draft).mockResolvedValue(planArtifact())
    vi.mocked(plansApi.saveDraft).mockResolvedValue(planArtifact(5))
    vi.mocked(plansApi.analyzeDraft).mockResolvedValue(analysisResult())
    vi.mocked(plansApi.exportDraft).mockResolvedValue(planExportResult())
    vi.mocked(atlasApi.exercises).mockResolvedValue({
      items: [exercise],
      total: 1,
      page: 1,
      per_page: 100,
      facets: {
        body_part: {},
        target_category: {},
        mechanics_tier: {},
        resistance_source: {},
      },
    })
    vi.mocked(atlasApi.muscles).mockResolvedValue({
      items: [muscle],
      total: 1,
      page: 1,
      per_page: 100,
      facets: { body_part: {}, complex: {} },
    })
  })

  it('enables ANALYSIS, keeps MODULATION disabled, and fetches only on first open', async () => {
    const wrapper = mountView()
    await flushPromises()
    const tabs = wrapper.findAll('.plan-tabs button')

    expect(tabs[1]?.attributes('disabled')).toBeUndefined()
    expect(tabs[2]?.attributes('disabled')).toBeDefined()

    await tabs[1]!.trigger('click')
    await flushPromises()
    expect(plansApi.analyzeDraft).toHaveBeenCalledTimes(1)
    expect(plansApi.analyzeDraft).toHaveBeenCalledWith(11, {
      resolution_context: {
        global_volume_level: 0,
        focus_area: null,
        axis_overrides: {},
      },
    })

    await tabs[0]!.trigger('click')
    await tabs[1]!.trigger('click')
    await flushPromises()
    expect(plansApi.analyzeDraft).toHaveBeenCalledTimes(1)
  })

  it('marks Analysis out of date for unsaved edits and after a successful save', async () => {
    const wrapper = mountView()
    await flushPromises()
    const tabs = wrapper.findAll('.plan-tabs button')
    await tabs[1]!.trigger('click')
    await flushPromises()
    await tabs[0]!.trigger('click')

    await wrapper.get('.plan-name-input').setValue('Locally edited plan')
    await tabs[1]!.trigger('click')
    expect(wrapper.text()).toContain('Plan has unsaved changes')

    await wrapper.get('.save-button').trigger('click')
    await flushPromises()
    expect(plansApi.saveDraft).toHaveBeenCalledTimes(1)
    expect(wrapper.text()).toContain('Out of date')
    expect(wrapper.text()).toContain('Analysis lock version differs from the loaded plan')
  })

  it('exports the saved basic resolution from the PLAN toolbar', async () => {
    const wrapper = mountView()
    await flushPromises()

    await wrapper.get('.export-plan-button').trigger('click')
    await flushPromises()

    expect(plansApi.exportDraft).toHaveBeenCalledWith(11, {
      resolution_context: {
        global_volume_level: 0,
        focus_area: null,
        axis_overrides: {},
      },
    })
    expect(wrapper.get('.plan-export-dialog').text()).toContain('Export plan for AI')
    expect(wrapper.get('.plan-export-preview').text()).toContain('Barbell Bench Press')
    expect(wrapper.get('.plan-export-preview').text()).toContain('"rir": 2')
  })
})
