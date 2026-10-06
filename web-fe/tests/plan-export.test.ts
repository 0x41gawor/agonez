import { mount } from '@vue/test-utils'
import { afterEach, describe, expect, it, vi } from 'vitest'

import PlanExportDialog from '@/components/plans/PlanExportDialog.vue'
import { planExportFilename } from '@/features/plans/export'
import { planExportResult } from './fixtures/analysis'

describe('Plan AI export', () => {
  afterEach(() => vi.restoreAllMocks())

  it('presents a compact saved-plan document without slot infrastructure', () => {
    const wrapper = mount(PlanExportDialog, {
      props: { document: planExportResult(), editorDirty: true },
    })
    const json = wrapper.get('.plan-export-preview').text()

    expect(json).toContain('"format": "agonez-plan-sanity-v4"')
    expect(json).toContain('"progression_model": "double_progression"')
    expect(json).toContain('"progression_id": "11111111-1111-4111-8111-111111111111"')
    expect(json).toContain('"role": "working"')
    expect(json).toContain('"kind": "absolute"')
    expect(json).not.toContain('when_to_use')
    expect(json).toContain('"reps"')
    expect(json).toContain('"semantics": "undefined"')
    expect(json).toContain('"rir": "RIR2"')
    expect(json).not.toContain('slot')
    expect(json).not.toContain('variant')
    expect(json).not.toContain('min_volume_level')
    expect(wrapper.text()).toContain('Unsaved PLAN changes are not included')
  })

  it('copies the exact JSON document for pasting into an external model', async () => {
    const writeText = vi.fn().mockResolvedValue(undefined)
    Object.defineProperty(navigator, 'clipboard', {
      configurable: true,
      value: { writeText },
    })
    const document = planExportResult()
    const wrapper = mount(PlanExportDialog, {
      props: { document, editorDirty: false },
    })

    await wrapper.findAll('button').find((button) => button.text() === 'Copy JSON')!.trigger('click')

    expect(writeText).toHaveBeenCalledWith(JSON.stringify(document, null, 2))
    expect(wrapper.text()).toContain('Copied')
  })

  it('creates a stable, filesystem-safe basic-plan filename', () => {
    expect(planExportFilename('5x Week, Push–Pull / Upper Focus')).toBe(
      '5x-week-push-pull-upper-focus-basic.json',
    )
  })
})
