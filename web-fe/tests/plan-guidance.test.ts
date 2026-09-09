import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import PlanGuidanceCoach from '@/components/plans/PlanGuidanceCoach.vue'
import { toPlanEditorState } from '@/features/plans/editor'
import { evaluatePlanGuidance } from '@/features/plans/guidance'
import { planArtifact } from './fixtures/plans'

describe('PlanCreator contextual guidance', () => {
  it('suggests modeling recovery only when a non-empty plan has no rest day', () => {
    const plan = toPlanEditorState(planArtifact())

    expect(evaluatePlanGuidance(plan)).toMatchObject([
      {
        id: 'missing-rest-day',
        title: 'No rest day is modeled',
        target: 'days',
      },
    ])

    plan.days[0]!.workout_unit = null
    expect(evaluatePlanGuidance(plan)).toEqual([])

    plan.days = []
    expect(evaluatePlanGuidance(plan)).toEqual([])
  })

  it('opens proactively, minimizes to a compact check, and emits a review target', async () => {
    const plan = toPlanEditorState(planArtifact())
    const items = evaluatePlanGuidance(plan)
    const wrapper = mount(PlanGuidanceCoach, {
      props: { active: true, items },
    })

    expect(wrapper.get('.plan-guidance-panel').text()).toContain('No rest day is modeled')
    expect(wrapper.text()).toContain('Explicit rest days let Analysis preserve')

    await wrapper.get('button[aria-label="Minimize plan guidance"]').trigger('click')
    expect(wrapper.find('.plan-guidance-panel').exists()).toBe(false)
    expect(wrapper.get('.plan-guidance-trigger').text()).toContain('Plan check')

    await wrapper.get('.plan-guidance-trigger').trigger('click')
    await wrapper.get('.plan-guidance-panel article .button').trigger('click')
    expect(wrapper.emitted('review')).toEqual([['days']])
    expect(wrapper.find('.plan-guidance-panel').exists()).toBe(false)
  })

  it('stays mounted but hidden outside the plan tab or after the issue is resolved', async () => {
    const plan = toPlanEditorState(planArtifact())
    const wrapper = mount(PlanGuidanceCoach, {
      props: { active: false, items: evaluatePlanGuidance(plan) },
    })

    expect(wrapper.get('.plan-guidance').isVisible()).toBe(false)
    await wrapper.setProps({ active: true, items: [] })
    expect(wrapper.get('.plan-guidance').isVisible()).toBe(false)
  })
})
