import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import ExerciseSlotEditor from '@/components/plans/ExerciseSlotEditor.vue'
import ExerciseVariantEditor from '@/components/plans/ExerciseVariantEditor.vue'
import PlanEditor from '@/components/plans/PlanEditor.vue'
import {
  createSlot,
  createVariant,
  duplicateDay,
  duplicateSlot,
  moveOrdered,
  removeOrdered,
  toPlanDraftUpdate,
  toPlanEditorState,
  validatePlanEditor,
} from '@/features/plans/editor'
import { exercise, fallbackExercise, muscle, planArtifact } from './fixtures/plans'

describe('PlanEditor', () => {
  it('starts with all loaded days collapsed, then renders the slot-first hierarchy', async () => {
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
    expect(wrapper.find('.day-body').exists()).toBe(false)

    await wrapper.get('.day-toggle').trigger('click')
    expect(wrapper.text()).toContain('Primary chest press')
    expect(wrapper.text()).toContain('Barbell Bench Press')
    expect(wrapper.get('.slot-editor').classes()).toContain('role-primary-progressive')
    expect(wrapper.get('.slot-role-badge').text()).toContain('Primary progressive')
    expect(wrapper.get('.slot-exercise-thumb img').attributes('src')).toBe(
      '/media/exercises/barbell_bench_press.png',
    )
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

  it('deep-copies a day with fresh nested identities and an independent name', async () => {
    const editor = toPlanEditorState(planArtifact())
    const source = editor.days[0]!
    const wrapper = mount(PlanEditor, {
      props: { modelValue: editor, exercises: [exercise], muscles: [muscle], issues: [] },
    })

    await wrapper.get('button[title="Duplicate day"]').trigger('click')
    expect(editor.days).toHaveLength(2)
    const duplicate = editor.days[1]!
    expect(duplicate.name).toBe('Push A copy')
    expect(duplicate.ordinal).toBe(1)
    expect(duplicate.id).toBeNull()
    expect(duplicate.clientKey).not.toBe(source.clientKey)
    expect(duplicate.workout_unit?.id).toBeNull()
    expect(duplicate.workout_unit?.name).toBe('Push A workout')
    expect(duplicate.workout_unit?.exercise_slots[0]?.id).toBeNull()
    expect(duplicate.workout_unit?.exercise_slots[0]?.variants[0]?.id).toBeNull()
    expect(duplicate.workout_unit?.exercise_slots[0]?.variants[0]?.sets[0]?.id).toBeNull()

    duplicate.workout_unit!.exercise_slots[0]!.target_muscle_slugs.push('another_muscle')
    duplicate.workout_unit!.exercise_slots[0]!.variants[0]!.sets[0]!.reps.min = 99
    expect(source.workout_unit?.exercise_slots[0]?.target_muscle_slugs).toEqual([muscle.slug])
    expect(source.workout_unit?.exercise_slots[0]?.variants[0]?.sets[0]?.reps.min).toBe(5)

    const payload = toPlanDraftUpdate(editor)
    expect(payload.days[1]?.workout_unit?.exercise_slots[0]?.variants[0]?.sets[0]?.id).toBeNull()
  })

  it('gives repeated copies deterministic unique names', () => {
    const editor = toPlanEditorState(planArtifact())
    duplicateDay(editor.days, 0)
    duplicateDay(editor.days, 0)

    expect(editor.days.map((day) => day.name)).toEqual(['Push A', 'Push A copy 2', 'Push A copy'])
    expect(editor.days.map((day) => day.ordinal)).toEqual([0, 1, 2])
  })

  it('adds exercise slots from the bottom control and the focused-day shortcut', async () => {
    const editor = toPlanEditorState(planArtifact())
    const wrapper = mount(PlanEditor, {
      props: { modelValue: editor, exercises: [exercise], muscles: [muscle], issues: [] },
    })

    await wrapper.get('.day-toggle').trigger('click')
    expect(wrapper.findAll('.add-slot-bottom')).toHaveLength(1)

    await wrapper.get('.add-slot-bottom').trigger('click')
    expect(editor.days[0]?.workout_unit?.exercise_slots).toHaveLength(2)

    await wrapper.get('.day-editor').trigger('keydown', {
      key: 'e',
      ctrlKey: true,
      shiftKey: true,
    })
    expect(editor.days[0]?.workout_unit?.exercise_slots).toHaveLength(3)
  })

  it('shows a compact anatomy intent map only when slot details with targets are open', async () => {
    const editor = toPlanEditorState(planArtifact())
    const wrapper = mount(PlanEditor, {
      props: { modelValue: editor, exercises: [exercise], muscles: [muscle], issues: [] },
    })

    await wrapper.get('.day-toggle').trigger('click')
    expect(wrapper.find('.slot-muscle-map').exists()).toBe(false)
    await wrapper.get('.slot-disclosure').trigger('click')
    expect(wrapper.find('.slot-muscle-map').exists()).toBe(true)
    expect(wrapper.get('.slot-muscle-map').text()).toContain('1 targets')
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

  it('deep-copies an exercise slot with fresh nested identities and independent values', async () => {
    const editor = toPlanEditorState(planArtifact())
    const slots = editor.days[0]!.workout_unit!.exercise_slots
    const source = slots[0]!
    source.variants.push(createVariant('FALLBACK', 1, fallbackExercise.slug))
    source.variants[1]!.sets.push({
      id: 72,
      clientKey: 'set-72',
      ordinal: 0,
      reps: { min: 8, max: 10 },
      rir: 2,
      min_volume_level: 0,
    })

    const wrapper = mount(PlanEditor, {
      props: {
        modelValue: editor,
        exercises: [exercise, fallbackExercise],
        muscles: [muscle],
        issues: [],
      },
    })
    await wrapper.get('.day-toggle').trigger('click')
    await wrapper.get('button[title="Duplicate exercise slot"]').trigger('click')

    expect(slots).toHaveLength(2)
    const duplicate = slots[1]!
    expect(duplicate.name).toBe('Primary chest press copy')
    expect(duplicate.ordinal).toBe(1)
    expect(duplicate.id).toBeNull()
    expect(duplicate.clientKey).not.toBe(source.clientKey)
    expect(duplicate.target_muscle_slugs).toEqual(source.target_muscle_slugs)
    expect(duplicate.target_muscle_slugs).not.toBe(source.target_muscle_slugs)
    expect(duplicate.variants).toHaveLength(2)
    duplicate.variants.forEach((variant, index) => {
      expect(variant.id).toBeNull()
      expect(variant.clientKey).not.toBe(source.variants[index]!.clientKey)
      variant.sets.forEach((set, setIndex) => {
        expect(set.id).toBeNull()
        expect(set.clientKey).not.toBe(source.variants[index]!.sets[setIndex]!.clientKey)
        expect(set.reps).not.toBe(source.variants[index]!.sets[setIndex]!.reps)
      })
    })

    duplicate.target_muscle_slugs.push('another_muscle')
    duplicate.variants[0]!.sets[0]!.reps.min = 99
    expect(source.target_muscle_slugs).toEqual([muscle.slug])
    expect(source.variants[0]!.sets[0]!.reps.min).toBe(5)

    const payload = toPlanDraftUpdate(editor)
    expect(payload.days[0]?.workout_unit?.exercise_slots[1]?.id).toBeNull()
    expect(payload.days[0]?.workout_unit?.exercise_slots[1]?.variants[0]?.id).toBeNull()
    expect(payload.days[0]?.workout_unit?.exercise_slots[1]?.variants[0]?.sets[0]?.id).toBeNull()
  })

  it('gives repeated slot copies deterministic unique names', () => {
    const editor = toPlanEditorState(planArtifact())
    const slots = editor.days[0]!.workout_unit!.exercise_slots
    duplicateSlot(slots, 0)
    duplicateSlot(slots, 0)

    expect(slots.map((slot) => slot.name)).toEqual([
      'Primary chest press',
      'Primary chest press copy 2',
      'Primary chest press copy',
    ])
    expect(slots.map((slot) => slot.ordinal)).toEqual([0, 1, 2])
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

  it('keeps a plain selector click in the editor and exposes native modified-click navigation', async () => {
    const slot = createSlot(0)
    slot.variants.push(createVariant('DEFAULT', 0, exercise.slug))
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

    const trigger = wrapper.get('.catalog-selector-trigger')
    expect(trigger.element.tagName).toBe('A')
    expect(trigger.attributes('href')).toBe('/atlas/exercises/barbell_bench_press')

    const modifiedClick = new MouseEvent('click', {
      bubbles: true,
      cancelable: true,
      ctrlKey: true,
    })
    modifiedClick.preventDefault()
    trigger.element.dispatchEvent(modifiedClick)
    expect(wrapper.find('.catalog-selector-panel').exists()).toBe(false)

    await trigger.trigger('click')
    expect(wrapper.find('.catalog-selector-panel').exists()).toBe(true)
  })

  it('shows mechanics class and systemic FCSA demand in the selected exercise and picker', async () => {
    const slot = createSlot(0)
    slot.variants.push(createVariant('DEFAULT', 0, exercise.slug))
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

    expect(wrapper.get('.exercise-selector-facts').text()).toContain('Heavy Compound')
    expect(wrapper.get('.exercise-demand-tag').text()).toContain('175 cm² systemic FCSA')
    await wrapper.get('.catalog-selector-trigger').trigger('click')
    expect(wrapper.get('.exercise-option-facts').text()).toContain('Heavy Compound')
    expect(wrapper.get('.exercise-option-demand').text()).toContain('175 cm² FCSA')
    await wrapper.get('input[type="search"]').setValue('chest sternal')
    expect(wrapper.find('.catalog-option').exists()).toBe(true)
    await wrapper.get('input[type="search"]').setValue('hamstrings')
    expect(wrapper.find('.catalog-option').exists()).toBe(false)
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
