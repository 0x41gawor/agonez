import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

import PlanEditor from '@/components/plans/PlanEditor.vue'
import { duplicateDay, toPlanEditorState } from '@/features/plans/editor'
import type { GlanceEditorTarget } from '@/features/plans/glance'
import { exercise, muscle, planArtifact } from './fixtures/plans'

describe('Plan at a glance editor navigation', () => {
  it('targets the clicked occurrence by stable identity, expands it, scrolls, and focuses it', async () => {
    const editor = toPlanEditorState(planArtifact())
    duplicateDay(editor.days, 0)
    const intendedDay = editor.days[1]!
    const intendedSlot = intendedDay.workout_unit!.exercise_slots[0]!
    intendedDay.name = 'Pull B'
    intendedSlot.name = editor.days[0]!.workout_unit!.exercise_slots[0]!.name

    Object.defineProperty(window, 'matchMedia', {
      configurable: true,
      value: vi.fn(() => ({ matches: true })),
    })
    Object.defineProperty(HTMLElement.prototype, 'scrollIntoView', {
      configurable: true,
      value: vi.fn(),
    })

    const wrapper = mount(PlanEditor, {
      attachTo: document.body,
      props: {
        modelValue: editor,
        exercises: [exercise],
        muscles: [muscle],
        issues: [],
        planView: 'glance',
      },
    })

    const occurrenceButtons = wrapper.findAll('.glance-slot-open')
    expect(occurrenceButtons).toHaveLength(2)
    await occurrenceButtons[1]!.trigger('click')
    const target = wrapper.emitted<GlanceEditorTarget[]>('openEditor')?.[0]?.[0]
    expect(target).toMatchObject({
      dayKey: intendedDay.clientKey,
      dayId: intendedDay.id,
      slotKey: intendedSlot.clientKey,
      slotId: intendedSlot.id,
    })
    expect(target?.dayKey).not.toBe(editor.days[0]!.clientKey)

    await wrapper.setProps({ planView: 'editor' })
    await (wrapper.vm as unknown as { focusEditorTarget: (value: GlanceEditorTarget) => Promise<void> })
      .focusEditorTarget(target!)

    const intendedElement = wrapper.find(`[data-editor-slot-key="${intendedSlot.clientKey}"]`)
    expect(intendedElement.classes()).toContain('editor-focus-target')
    expect(intendedElement.find('.slot-details').exists()).toBe(true)
    expect(document.activeElement).toBe(intendedElement.get('.slot-summary-main').element)
    expect(HTMLElement.prototype.scrollIntoView).toHaveBeenCalledTimes(1)

    wrapper.unmount()
  })

  it('uses a separate trace action without triggering editor navigation and clears it with Escape', async () => {
    const editor = toPlanEditorState(planArtifact())
    duplicateDay(editor.days, 0)
    const wrapper = mount(PlanEditor, {
      attachTo: document.body,
      props: {
        modelValue: editor,
        exercises: [exercise],
        muscles: [muscle],
        issues: [],
        planView: 'glance',
      },
    })

    await wrapper.findAll('.glance-trace')[0]!.trigger('click')
    expect(wrapper.emitted('openEditor')).toBeUndefined()
    expect(wrapper.findAll('.glance-slot.selected')).toHaveLength(2)

    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }))
    await wrapper.vm.$nextTick()
    expect(wrapper.findAll('.glance-slot.selected')).toHaveLength(0)
    wrapper.unmount()
  })
})
