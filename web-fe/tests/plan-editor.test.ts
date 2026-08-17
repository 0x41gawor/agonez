import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import ExerciseSlotEditor from '@/components/plans/ExerciseSlotEditor.vue'
import ExerciseVariantEditor from '@/components/plans/ExerciseVariantEditor.vue'
import PlanEditor from '@/components/plans/PlanEditor.vue'
import {
  createSlot,
  createVariant,
  moveOrdered,
  removeOrdered,
  toPlanDraftUpdate,
  toPlanEditorState,
  validatePlanEditor,
} from '@/features/plans/editor'
import { exercise, fallbackExercise, muscle, planArtifact } from './fixtures/plans'

describe('PlanEditor', () => {
  it('renders a loaded plan and its slot-first visible hierarchy', () => {
    const editor = toPlanEditorState(planArtifact())
    const wrapper = mount(PlanEditor, {
      props: {
        modelValue: editor,
        exercises: [exercise, fallbackExercise],
        muscles: [muscle],
        issues: [],
      },
    })

    expect(wrapper.get('.plan-name-input').element).toHaveProperty('value', 'PPLPP')
    expect(wrapper.text()).toContain('Push A')
    expect(wrapper.text()).toContain('Primary chest press')
    expect(wrapper.text()).toContain('Barbell Bench Press')
    expect(
      wrapper
        .findAll('.set-editor input')
        .map((input) => (input.element as HTMLInputElement).value),
    ).toEqual(['5', '7'])
    expect(wrapper.text()).toContain('RIR')
  })

  it('adds and removes a day while restoring deterministic ordinals', async () => {
    const editor = toPlanEditorState(planArtifact())
    const wrapper = mount(PlanEditor, {
      props: { modelValue: editor, exercises: [exercise], muscles: [muscle], issues: [] },
    })

    await wrapper.findAll('button').find((button) => button.text().includes('Add training day'))?.trigger('click')
    expect(editor.days).toHaveLength(2)
    expect(editor.days.map((day) => day.ordinal)).toEqual([0, 1])

    await wrapper.findAll('.day-header .danger-action')[0]?.trigger('click')
    expect(editor.days).toHaveLength(1)
    expect(editor.days[0]?.ordinal).toBe(0)
  })

  it('adds, removes, and reorders slots without changing their stable IDs', () => {
    const editor = toPlanEditorState(planArtifact())
    const slots = editor.days[0]!.workout_unit!.exercise_slots
    const second = createSlot(1)
    second.id = 52
    second.name = 'Secondary press'
    slots.push(second)
    const ids = slots.map((slot) => slot.id)

    moveOrdered(slots, 1, -1)
    expect(slots.map((slot) => slot.id)).toEqual([52, 51])
    expect(slots.map((slot) => slot.ordinal)).toEqual([0, 1])

    removeOrdered(slots, 1)
    expect(slots.map((slot) => slot.id)).toEqual([52])
    expect(ids).toEqual([51, 52])
  })

  it('selects a live-catalog exercise as the DEFAULT variant', async () => {
    const slot = createSlot(0)
    const wrapper = mount(ExerciseSlotEditor, {
      props: {
        modelValue: slot,
        index: 0,
        count: 1,
        exercises: [exercise],
        muscles: [muscle],
        path: `days/day-new.slots.${slot.clientKey}`,
        issues: [],
      },
    })

    await wrapper.get('.catalog-selector-trigger').trigger('click')
    await wrapper.get('.catalog-option').trigger('click')
    expect(slot.variants).toHaveLength(1)
    expect(slot.variants[0]?.variant_type).toBe('DEFAULT')
    expect(slot.variants[0]?.exercise_slug).toBe(exercise.slug)
  })

  it('adds and removes a FALLBACK inside the slot details', async () => {
    const slot = createSlot(0)
    slot.variants.push(createVariant('DEFAULT', 0, exercise.slug))
    const wrapper = mount(ExerciseSlotEditor, {
      props: {
        modelValue: slot,
        index: 0,
        count: 1,
        exercises: [exercise, fallbackExercise],
        muscles: [muscle],
        path: `days/day-new.slots.${slot.clientKey}`,
        issues: [],
      },
    })

    await wrapper.get('.slot-disclosure').trigger('click')
    await wrapper.findAll('button').find((button) => button.text().includes('Add fallback'))?.trigger('click')
    expect(slot.variants.map((variant) => variant.variant_type)).toEqual(['DEFAULT', 'FALLBACK'])
    await wrapper.get('.variant-editor.fallback .danger-action').trigger('click')
    expect(slot.variants.map((variant) => variant.variant_type)).toEqual(['DEFAULT'])
  })

  it('adds, edits, duplicates, reorders, and removes set prescriptions', async () => {
    const variant = createVariant('DEFAULT', 0, exercise.slug)
    const wrapper = mount(ExerciseVariantEditor, {
      props: {
        modelValue: variant,
        exercises: [exercise],
        path: `variant.${variant.clientKey}`,
        issues: [],
      },
    })

    await wrapper.get('.add-set').trigger('click')
    expect(variant.sets).toHaveLength(1)
    await wrapper.get('input[type="number"]').setValue('6')
    expect(variant.sets[0]?.reps.min).toBe(6)
    await wrapper.get('button[title="Duplicate set"]').trigger('click')
    expect(variant.sets).toHaveLength(2)
    expect(variant.sets[1]?.id).toBeNull()
    await wrapper.findAll('button[title="Move set up"]')[1]?.trigger('click')
    expect(variant.sets.map((item) => item.ordinal)).toEqual([0, 1])
    await wrapper.findAll('button[title="Remove set"]')[0]?.trigger('click')
    expect(variant.sets).toHaveLength(1)
  })

  it('preserves server IDs through edits and round-trip conversion', () => {
    const editor = toPlanEditorState(planArtifact())
    const set = editor.days[0]!.workout_unit!.exercise_slots[0]!.variants[0]!.sets[0]!
    set.reps = { min: 6, max: 8 }
    const payload = toPlanDraftUpdate(editor)

    expect(payload.days[0]?.id).toBe(31)
    expect(payload.days[0]?.workout_unit?.id).toBe(41)
    expect(payload.days[0]?.workout_unit?.exercise_slots[0]?.id).toBe(51)
    expect(payload.days[0]?.workout_unit?.exercise_slots[0]?.variants[0]?.id).toBe(61)
    expect(payload.days[0]?.workout_unit?.exercise_slots[0]?.variants[0]?.sets[0]?.id).toBe(71)
    expect(payload.days[0]?.workout_unit?.exercise_slots[0]?.variants[0]?.sets[0]?.reps).toEqual({ min: 6, max: 8 })

    const roundTripped = toPlanDraftUpdate(toPlanEditorState(payload))
    expect(roundTripped).toEqual(payload)
  })

  it('validates rep ranges and required exercise selection before save', () => {
    const editor = toPlanEditorState(planArtifact())
    const variant = editor.days[0]!.workout_unit!.exercise_slots[0]!.variants[0]!
    variant.exercise_slug = ''
    variant.sets[0]!.reps = { min: 10, max: 8 }
    const messages = validatePlanEditor(editor).map((issue) => issue.message)

    expect(messages).toContain('Choose an exercise before saving.')
    expect(messages).toContain('Maximum reps must be at least the minimum.')
  })
})
