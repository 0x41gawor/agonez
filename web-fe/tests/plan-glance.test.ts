import { describe, expect, it } from 'vitest'

import type { ExerciseCatalogItem } from '@/api/types'
import {
  buildGlanceModel,
  buildLegend,
  formatRepRanges,
  resolveClassification,
} from '@/features/plans/glance'
import { createDay, createSet, createSlot, createVariant, createWorkout, toPlanEditorState } from '@/features/plans/editor'
import { exercise, planArtifact } from './fixtures/plans'

const catalogExercise: ExerciseCatalogItem = exercise

describe('Plan at a glance model', () => {
  it('uses the default variant only and separates ramp-up from every working-set role', () => {
    const plan = toPlanEditorState(planArtifact())
    const slot = plan.days[0]!.workout_unit!.exercise_slots[0]!
    const defaultVariant = slot.variants[0]!
    defaultVariant.sets = [
      { ...createSet(0), role: 'rampup', reps: { min: 8, max: 10, semantics: 'undefined' } },
      { ...createSet(1), role: 'working_topset', reps: { min: 5, max: 7, semantics: 'undefined' } },
      { ...createSet(2), role: 'working_backoff', reps: { min: 6, max: 8, semantics: 'undefined' } },
    ]
    const fallback = createVariant('FALLBACK', 1, exercise.slug)
    fallback.sets = Array.from({ length: 7 }, (_, index) => createSet(index))
    slot.variants.push(fallback)

    const model = buildGlanceModel(plan, [catalogExercise])
    expect(model.days[0]?.slots[0]?.reps).toMatchObject({
      workingSets: 2,
      warmupSets: 1,
      main: '5–7 / 6–8',
      warmup: 'wu 8–10',
    })
    expect(model.totals.workingSets).toBe(2)
  })

  it('preserves independent ranges, uniform ranges, missing bounds, and empty prescriptions', () => {
    expect(formatRepRanges([
      { ...createSet(0), reps: { min: 8, max: 12, semantics: 'undefined' } },
      { ...createSet(1), reps: { min: 8, max: 12, semantics: 'undefined' } },
    ]).main).toBe('2 × 8–12')

    const incomplete = createSet(0)
    incomplete.reps = { min: 8, max: null, semantics: 'undefined' } as never
    expect(formatRepRanges([incomplete]).main).toBe('1 × 8–?')
    expect(formatRepRanges([])).toEqual({ workingSets: 0, warmupSets: 0, main: '', warmup: '', perSet: [] })
  })

  it('supports arbitrary ordered days, rest and empty workouts, and exact trimmed recurrence groups', () => {
    const plan = toPlanEditorState(planArtifact())
    const firstDay = plan.days[0]!
    const firstSlot = firstDay.workout_unit!.exercise_slots[0]!
    firstSlot.name = ' Vertical Pull 1 '

    const repeated = createSlot(1)
    repeated.name = 'Vertical Pull 1'
    repeated.variants = [createVariant('DEFAULT', 0, exercise.slug)]
    repeated.variants[0]!.sets = [createSet(0), createSet(1)]
    firstDay.workout_unit!.exercise_slots.push(repeated)

    const rest = createDay(1)
    rest.name = 'Recovery'
    const empty = createDay(2)
    empty.name = 'Technique'
    empty.workout_unit = createWorkout('Technique workout')
    const neutral = createDay(3)
    neutral.name = 'Pull B'
    neutral.workout_unit = createWorkout('Pull B')
    const neutralSlot = createSlot(0)
    neutralSlot.name = 'Vertical Pull 1 (neutral)'
    neutral.workout_unit.exercise_slots.push(neutralSlot)
    plan.days.push(rest, empty, neutral)

    const model = buildGlanceModel(plan, [catalogExercise])
    expect(model.days.map((day) => day.kind)).toEqual(['train', 'rest', 'empty', 'train'])
    expect(model.groups).toHaveLength(2)
    expect(model.groups[0]).toMatchObject({ name: 'Vertical Pull 1', dayCount: 1, gaps: 'once' })
    expect(model.groups[0]?.occurrences).toHaveLength(2)
    expect(model.groups[1]?.name).toBe('Vertical Pull 1 (neutral)')
  })

  it('maps actual Atlas enum values, lists only present categories, and safely identifies unknown values', () => {
    const plan = toPlanEditorState(planArtifact())
    const model = buildGlanceModel(plan, [catalogExercise])
    expect(resolveClassification('targetCategory', 'Chest_Sternal')).toMatchObject({ code: 'CH·S', label: 'Chest Sternal' })
    expect(resolveClassification('targetCategory', 'CHEST_STERNAL')).toMatchObject({ code: 'CH·S' })
    expect(resolveClassification('mechanicsTier', null)).toMatchObject({ code: '—', unclassified: true })
    expect(resolveClassification('bodyPart', 'Future_Region')).toMatchObject({ key: 'Future_Region', unknown: true })
    expect(buildLegend(model, 'bodyPart').map((item) => item.key)).toEqual(['Upper'])
  })

  it('derives fresh output from unsaved editor mutations without another plan model', () => {
    const plan = toPlanEditorState(planArtifact())
    expect(buildGlanceModel(plan, [catalogExercise]).days[0]?.slots[0]?.name).toBe('Primary chest press')
    plan.days[0]!.workout_unit!.exercise_slots[0]!.name = 'Unsaved local name'
    plan.days[0]!.workout_unit!.exercise_slots[0]!.variants[0]!.sets.push(createSet(1))
    const updated = buildGlanceModel(plan, [catalogExercise])
    expect(updated.days[0]?.slots[0]).toMatchObject({ name: 'Unsaved local name' })
    expect(updated.totals.workingSets).toBe(2)
  })
})
