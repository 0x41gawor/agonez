import { describe, expect, it } from 'vitest'

import type { ExerciseCatalogItem } from '@/api/types'
import { ExerciseSearch, normalizeExerciseSearch } from '@/features/plans/exercise-search'
import { exercise } from './fixtures/plans'

function catalogExercise(
  slug: string,
  nameFull: string,
  overrides: Partial<ExerciseCatalogItem> = {},
): ExerciseCatalogItem {
  return {
    ...exercise,
    slug,
    name: nameFull,
    name_full: nameFull,
    ...overrides,
  }
}

const catalog = [
  catalogExercise('barbell_bent_over_row', 'Barbell Bent-Over Row', {
    target_category: 'Back_3D',
    resistance_source: 'Barbell',
    mechanics_tier: 'Heavy_Compound',
  }),
  catalogExercise('seated_cable_row', 'Seated Cable Row', {
    target_category: 'Back_V',
    resistance_source: 'Cable',
    mechanics_tier: 'Secondary_Compound',
  }),
  catalogExercise('dumbbell_lateral_raise', 'Dumbbell Lateral Raise', {
    target_category: 'Lateral_Delt',
    resistance_source: 'Dumbbell',
    mechanics_tier: 'Isolation',
  }),
]

describe('ExerciseSearch', () => {
  it('normalizes punctuation, separators, casing, and diacritics', () => {
    expect(normalizeExerciseSearch('  BÁRBELL_Bent-Over!! ')).toBe('barbell bent over')
  })

  it('searches every selector field with direct matches ranked first', () => {
    const search = new ExerciseSearch(catalog)

    expect(search.search('barbell')[0]?.slug).toBe('barbell_bent_over_row')
    expect(search.search('back 3d')[0]?.slug).toBe('barbell_bent_over_row')
    expect(search.search('isolation')[0]?.slug).toBe('dumbbell_lateral_raise')
    expect(search.search('cable')[0]?.slug).toBe('seated_cable_row')
  })

  it('accepts realistic misspellings without flooding results', () => {
    const search = new ExerciseSearch(catalog)

    expect(search.search('barbel bent ovr')[0]?.slug).toBe('barbell_bent_over_row')
    expect(search.search('laterl rase')[0]?.slug).toBe('dumbbell_lateral_raise')
    expect(search.search('completely unrelated phrase')).toEqual([])
  })
})
