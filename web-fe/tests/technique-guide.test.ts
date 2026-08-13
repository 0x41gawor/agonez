import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'

import TechniqueGuide from '@/components/detail/TechniqueGuide.vue'

describe('TechniqueGuide', () => {
  it('uses the canonical order regardless of JSON key order and renders nested TLDR values', () => {
    const wrapper = mount(TechniqueGuide, {
      props: {
        data: {
          safety_notes: ['Use safety arms.', 'Use a competent spotter.'],
          rir_0_definition: 'No further valid repetition is possible.',
          grip: 'Use a closed grip.',
          overview: 'A horizontal bilateral press.',
          tldr: {
            stop_when: { primary: 'Bar path changes.', secondary: 'The pelvis lifts.' },
            focus: 'Repeat the same path.',
            execution: 'Lower, then press.',
            setup: 'Build a stable base.',
          },
        },
      },
    })

    const text = wrapper.text()
    expect(text.indexOf('Setup')).toBeLessThan(text.indexOf('Execution'))
    expect(text.indexOf('Execution')).toBeLessThan(text.indexOf('Focus'))
    expect(text.indexOf('Focus')).toBeLessThan(text.indexOf('Stop when'))
    expect(text.indexOf('Movement overview')).toBeLessThan(text.indexOf('Preparation'))
    expect(text.indexOf('Preparation')).toBeLessThan(text.indexOf('Effort and failure'))
    expect(text.indexOf('Effort and failure')).toBeLessThan(text.indexOf('Troubleshooting'))
    expect(text).toContain('primary')
    expect(text).toContain('The pelvis lifts.')
    expect(wrapper.findAll('.tone-danger')).toHaveLength(1)
    expect(wrapper.findAll('.technique-value-list li')).toHaveLength(2)
  })

  it('keeps unknown future fields after the canonical sections', () => {
    const wrapper = mount(TechniqueGuide, {
      props: { data: { overview: 'Known', coach_note: 'Future field' } },
    })

    expect(wrapper.text().indexOf('Movement overview')).toBeLessThan(wrapper.text().indexOf('Additional notes'))
    expect(wrapper.text()).toContain('Coach note')
  })
})
