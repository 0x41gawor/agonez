import Fuse from 'fuse.js'

import type { ExerciseCatalogItem } from '@/api/types'

interface ExerciseSearchDocument {
  exercise: ExerciseCatalogItem
  name: string
  nameFull: string
  slug: string
  targetCategory: string
  resistanceSource: string
  mechanicsTier: string
}

const SEARCH_LIMIT = 24

export function normalizeExerciseSearch(value: string): string {
  return value
    .normalize('NFKD')
    .replace(/\p{Diacritic}/gu, '')
    .toLocaleLowerCase()
    .replaceAll('_', ' ')
    .replaceAll('-', ' ')
    .replace(/[^\p{L}\p{N}\s]+/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim()
}

function documentFor(exercise: ExerciseCatalogItem): ExerciseSearchDocument {
  return {
    exercise,
    name: normalizeExerciseSearch(exercise.name),
    nameFull: normalizeExerciseSearch(exercise.name_full),
    slug: normalizeExerciseSearch(exercise.slug),
    targetCategory: normalizeExerciseSearch(exercise.target_category),
    resistanceSource: normalizeExerciseSearch(exercise.resistance_source),
    mechanicsTier: normalizeExerciseSearch(exercise.mechanics_tier),
  }
}

function searchableValues(document: ExerciseSearchDocument): string[] {
  return [
    document.nameFull,
    document.name,
    document.slug,
    document.targetCategory,
    document.resistanceSource,
    document.mechanicsTier,
  ]
}

function directMatchRank(document: ExerciseSearchDocument, query: string): number | null {
  const values = searchableValues(document)
  if (values.some((value) => value === query)) return 0
  if (values.some((value) => value.startsWith(query))) return 1
  if (values.some((value) => value.includes(query))) return 2
  return null
}

export class ExerciseSearch {
  private readonly documents: ExerciseSearchDocument[]
  private readonly fuse: Fuse<ExerciseSearchDocument>

  constructor(exercises: ExerciseCatalogItem[]) {
    this.documents = exercises.map(documentFor)
    this.fuse = new Fuse(this.documents, {
      includeScore: true,
      ignoreLocation: true,
      minMatchCharLength: 2,
      threshold: 0.34,
      keys: [
        { name: 'nameFull', weight: 0.32 },
        { name: 'name', weight: 0.25 },
        { name: 'slug', weight: 0.18 },
        { name: 'targetCategory', weight: 0.1 },
        { name: 'resistanceSource', weight: 0.08 },
        { name: 'mechanicsTier', weight: 0.07 },
      ],
    })
  }

  search(rawQuery: string, limit = SEARCH_LIMIT): ExerciseCatalogItem[] {
    const query = normalizeExerciseSearch(rawQuery)
    if (!query) return this.documents.slice(0, limit).map(({ exercise }) => exercise)

    const direct = this.documents
      .map((document, index) => ({ document, index, rank: directMatchRank(document, query) }))
      .filter(
        (match): match is { document: ExerciseSearchDocument; index: number; rank: number } =>
          match.rank !== null,
      )
      .sort((left, right) => left.rank - right.rank || left.index - right.index)

    const seen = new Set(direct.map(({ document }) => document.exercise.slug))
    const matches = direct.map(({ document }) => document.exercise)

    if (query.length >= 2 && matches.length < limit) {
      for (const result of this.fuse.search(query)) {
        if (seen.has(result.item.exercise.slug)) continue
        matches.push(result.item.exercise)
        seen.add(result.item.exercise.slug)
        if (matches.length >= limit) break
      }
    }

    return matches.slice(0, limit)
  }
}
