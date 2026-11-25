import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

import PlanEditor from '@/components/plans/PlanEditor.vue'
import {
  createSet,
  createSlot,
  createVariant,
  duplicateDay,
  toPlanEditorState,
} from '@/features/plans/editor'
import type { GlanceEditorTarget } from '@/features/plans/glance'
import { exercise, muscle, planArtifact } from './fixtures/plans'

function addSlot(
  editor: ReturnType<typeof toPlanEditorState>,
  name: string,
  slug: string,
): void {
  const slot = createSlot(editor.days[0]!.workout_unit!.exercise_slots.length)
  slot.name = name
  const variant = createVariant('DEFAULT', 0, slug)
  variant.sets = [createSet(0)]
  slot.variants = [variant]
  editor.days[0]!.workout_unit!.exercise_slots.push(slot)
}

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

  it('offers first-appearance and alphabetical recurrence ordering', async () => {
    const editor = toPlanEditorState(planArtifact())
    editor.days[0]!.workout_unit!.exercise_slots[0]!.name = 'Zulu press'
    addSlot(editor, 'Alpha press', exercise.slug)

    const wrapper = mount(PlanEditor, {
      props: {
        modelValue: editor,
        exercises: [exercise],
        muscles: [muscle],
        issues: [],
        planView: 'glance',
      },
    })

    await wrapper.findAll('.glance-segmented button')[1]!.trigger('click')
    expect(wrapper.findAll('.glance-matrix tbody th strong').map((item) => item.text()))
      .toEqual(['Zulu press', 'Alpha press'])

    const nameOrder = wrapper.findAll('button').find((button) => button.text() === 'Name A–Z')
    await nameOrder!.trigger('click')
    expect(wrapper.findAll('.glance-matrix tbody th strong').map((item) => item.text()))
      .toEqual(['Alpha press', 'Zulu press'])
  })

  it('orders recurrence rows by body part and the stored target-size sequence', async () => {
    const editor = toPlanEditorState(planArtifact())
    editor.days[0]!.workout_unit!.exercise_slots[0]!.name = 'Upper chest'
    const gluteExercise = {
      ...exercise,
      slug: 'hip_thrust',
      name: 'Hip Thrust',
      name_full: 'Barbell Hip Thrust',
      body_part: 'Lower',
      target_category: 'Glutes',
    }
    const coreExercise = {
      ...exercise,
      slug: 'cable_crunch',
      name: 'Cable Crunch',
      name_full: 'Kneeling Cable Crunch',
      body_part: 'Core',
      target_category: 'Core',
    }
    const backExercise = {
      ...exercise,
      slug: 'chest_supported_row',
      name: 'Chest-Supported Row',
      name_full: 'Chest-Supported Barbell Row',
      body_part: 'Upper',
      target_category: 'Back_3D',
    }
    addSlot(editor, 'Lower glute', gluteExercise.slug)
    addSlot(editor, 'Core flexion', coreExercise.slug)
    addSlot(editor, 'Upper back', backExercise.slug)

    const wrapper = mount(PlanEditor, {
      props: {
        modelValue: editor,
        exercises: [exercise, gluteExercise, coreExercise, backExercise],
        muscles: [muscle],
        issues: [],
        planView: 'glance',
      },
    })

    await wrapper.findAll('.glance-segmented button')[1]!.trigger('click')
    const anatomicalOrder = wrapper.findAll('button').find((button) => button.text() === 'Target anatomy')
    await anatomicalOrder!.trigger('click')
    expect(wrapper.findAll('.glance-matrix tbody th strong').map((item) => item.text()))
      .toEqual(['Upper back', 'Upper chest', 'Lower glute', 'Core flexion'])
  })

  it('highlights any combination of classification categories', async () => {
    const editor = toPlanEditorState(planArtifact())
    const clavExercise = {
      ...exercise,
      slug: 'incline_bench_press',
      name: 'Incline Bench Press',
      name_full: 'Incline Barbell Bench Press',
      target_category: 'Chest_Clav_AD',
    }
    const deltExercise = {
      ...exercise,
      slug: 'front_raise',
      name: 'Front Raise',
      name_full: 'Cable Front Raise',
      target_category: 'Anterior_Delt',
    }
    addSlot(editor, 'Clavicular press', clavExercise.slug)
    addSlot(editor, 'Front raise', deltExercise.slug)

    const wrapper = mount(PlanEditor, {
      props: {
        modelValue: editor,
        exercises: [exercise, clavExercise, deltExercise],
        muscles: [muscle],
        issues: [],
        planView: 'glance',
      },
    })

    const chips = wrapper.findAll('.glance-legend-chip')
    await chips[0]!.trigger('click')
    await chips[1]!.trigger('click', { ctrlKey: true })

    expect(wrapper.findAll('.glance-legend-chip.active')).toHaveLength(2)
    expect(wrapper.findAll('.glance-slot.selected')).toHaveLength(2)
    expect(wrapper.findAll('.glance-slot.dimmed')).toHaveLength(1)
    expect(wrapper.get('.glance-focus strong').text()).toBe('Chest Sternal + Chest Clav AD')

    await wrapper.findAll('.glance-segmented button')[1]!.trigger('click')
    expect(wrapper.findAll('.matrix-occurrence.selected')).toHaveLength(2)
    expect(wrapper.findAll('.matrix-occurrence.dimmed')).toHaveLength(1)
    expect(wrapper.findAll('.glance-matrix tbody tr.dimmed')).toHaveLength(1)
  })

  it('composes exact slot-name selections with Ctrl or Command in recurrence view', async () => {
    const editor = toPlanEditorState(planArtifact())
    editor.days[0]!.workout_unit!.exercise_slots[0]!.name = 'Alpha slot'
    addSlot(editor, 'Beta slot', exercise.slug)
    const wrapper = mount(PlanEditor, {
      props: {
        modelValue: editor,
        exercises: [exercise],
        muscles: [muscle],
        issues: [],
        planView: 'glance',
      },
    })

    await wrapper.findAll('.glance-segmented button')[1]!.trigger('click')
    const rowSelectors = wrapper.findAll('.glance-matrix-row-select')
    await rowSelectors[0]!.trigger('click')
    await rowSelectors[1]!.trigger('click', { ctrlKey: true })

    expect(wrapper.findAll('.glance-matrix-row-select[aria-pressed="true"]')).toHaveLength(2)
    expect(wrapper.findAll('.matrix-occurrence.selected')).toHaveLength(2)
    expect(wrapper.findAll('.glance-matrix tbody tr.dimmed')).toHaveLength(0)
    expect(wrapper.get('.glance-focus strong').text()).toBe('Alpha slot + Beta slot')

    await rowSelectors[1]!.trigger('click')
    expect(wrapper.findAll('.glance-matrix-row-select[aria-pressed="true"]')).toHaveLength(1)
    expect(wrapper.findAll('.glance-matrix tbody tr.dimmed')).toHaveLength(1)
  })

  it('renames and reorders slots directly in the live draft', async () => {
    const editor = toPlanEditorState(planArtifact())
    addSlot(editor, 'Second slot', exercise.slug)
    const firstSlot = editor.days[0]!.workout_unit!.exercise_slots[0]!
    const secondSlot = editor.days[0]!.workout_unit!.exercise_slots[1]!

    const wrapper = mount(PlanEditor, {
      props: {
        modelValue: editor,
        exercises: [exercise],
        muscles: [muscle],
        issues: [],
        planView: 'glance',
      },
    })

    await wrapper.find('button[aria-label="Rename Primary chest press"]').trigger('click')
    await wrapper.get('.glance-slot-rename input').setValue('Renamed press')
    await wrapper.get('.glance-slot-rename').trigger('submit')
    expect(firstSlot.name).toBe('Renamed press')
    expect(wrapper.findAll('.glance-slot-copy strong')[0]!.text()).toBe('Renamed press')

    await wrapper.findAll('button[aria-label="Move slot up"]')[1]!.trigger('click')
    expect(editor.days[0]!.workout_unit!.exercise_slots).toEqual([secondSlot, firstSlot])
    expect(editor.days[0]!.workout_unit!.exercise_slots.map((slot) => slot.ordinal)).toEqual([0, 1])
    expect(wrapper.findAll('.glance-slot-copy strong').map((item) => item.text()))
      .toEqual(['Second slot', 'Renamed press'])
  })

  it('publishes content-driven size variables for the board and matrix', async () => {
    const editor = toPlanEditorState(planArtifact())
    addSlot(editor, 'Second slot', exercise.slug)
    const wrapper = mount(PlanEditor, {
      props: {
        modelValue: editor,
        exercises: [exercise],
        muscles: [muscle],
        issues: [],
        planView: 'glance',
      },
    })

    expect(wrapper.get('.glance-board').attributes('style')).toContain('--glance-max-slots: 2')
    await wrapper.findAll('.glance-segmented button')[1]!.trigger('click')
    expect(wrapper.get('.glance-matrix-wrap').attributes('style')).toContain('--glance-matrix-rows: 2')
  })
})
