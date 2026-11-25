import type { DayIcon, SetRole } from '@/api/plan-types'
import type { ExerciseCatalogItem } from '@/api/types'
import type { EditorSet, PlanEditorState } from '@/features/plans/editor'

export type GlanceLens = 'bodyPart' | 'targetCategory' | 'mechanicsTier'

export interface GlanceEditorTarget {
  dayKey: string
  dayId: number | null
  workoutKey: string | null
  workoutId: number | null
  slotKey?: string
  slotId?: number | null
}

export interface GlanceClassification {
  key: string
  label: string
  code: string
  dark: string
  light: string
  order: number
  unclassified?: boolean
  unknown?: boolean
}

export interface GlanceRepSummary {
  workingSets: number
  warmupSets: number
  main: string
  warmup: string
  perSet: string[]
}

export interface GlanceSlot {
  key: string
  id: number | null
  position: number
  name: string
  role: string
  variantCount: number
  exerciseName: string
  classes: Record<GlanceLens, string | null>
  reps: GlanceRepSummary
  target: GlanceEditorTarget
}

export interface GlanceDay {
  key: string
  id: number | null
  index: number
  position: number
  label: string
  weekday: number | null
  name: string
  icon: DayIcon | null
  kind: 'rest' | 'empty' | 'train'
  workoutName: string | null
  slots: GlanceSlot[]
  workingSets: number
  warmupSets: number
  target: GlanceEditorTarget
}

export interface GlanceOccurrence {
  day: GlanceDay
  slot: GlanceSlot
}

export interface GlanceGroup {
  name: string
  first: number
  occurrences: GlanceOccurrence[]
  workingSets: number
  dayCount: number
  gaps: string
}

export interface GlanceModel {
  days: GlanceDay[]
  groups: GlanceGroup[]
  totals: {
    days: number
    workouts: number
    rest: number
    slots: number
    uniqueNames: number
    workingSets: number
  }
}

type TaxonomyRow = Omit<GlanceClassification, 'order'>

const TARGET_ROWS = [
  ['Chest_Sternal', 'Chest Sternal', 'CH·S', '#E5786C', '#C24B3E'],
  ['Chest_Clav_AD', 'Chest Clav AD', 'CH·C', '#F2B0A3', '#B85A4A'],
  ['Anterior_Delt', 'Anterior Delt', 'A·DL', '#D4C6FB', '#8A73D6'],
  ['Lateral_Delt', 'Lateral Delt', 'L·DL', '#A891F5', '#6A4ED3'],
  ['Posterior_Delt', 'Posterior Delt', 'P·DL', '#7E66DB', '#4A31A8'],
  ['Back_V', 'Back V', 'BK·V', '#62AAF2', '#2C6FBE'],
  ['Back_3D', 'Back 3D', 'BK3D', '#A3CDF8', '#5A93D4'],
  ['Upper_Traps', 'Upper Traps', 'TRAP', '#3F7CCB', '#1D4A8C'],
  ['Biceps', 'Biceps', 'BIC', '#57C7B4', '#1C8473'],
  ['Triceps', 'Triceps', 'TRI', '#A6E4D8', '#46A493'],
  ['Forearms', 'Forearms', 'FORE', '#2E9686', '#11604F'],
  ['Quads', 'Quads', 'QUAD', '#E9B24E', '#A8700F'],
  ['Calves', 'Calves', 'CALF', '#F4D59F', '#C28F3A'],
  ['Hamstrings', 'Hamstrings', 'HAM', '#8FC66C', '#4A8527'],
  ['Glutes', 'Glutes', 'GLU', '#C6E4A9', '#74A84C'],
  ['Hip_AF', 'Hip AF', 'HIP', '#5E9A45', '#2F621B'],
  ['Global_P', 'Global P', 'GL·P', '#D3D67E', '#858920'],
  ['Lower_P', 'Lower P', 'LO·P', '#A9A36A', '#666030'],
  ['Core', 'Core', 'CORE', '#C9BFAE', '#7A6F5E'],
  ['Neck', 'Neck', 'NECK', '#958C7F', '#544C41'],
] as const
const TARGET: TaxonomyRow[] = TARGET_ROWS.map(([key, label, code, dark, light]) => ({ key, label, code, dark, light }))

const BODY: TaxonomyRow[] = [
  { key: 'Upper', label: 'Upper', code: 'UP', dark: '#6EA8EF', light: '#2C6FBE' },
  { key: 'Lower', label: 'Lower', code: 'LO', dark: '#E6AE52', light: '#A8700F' },
  { key: 'Core', label: 'Core', code: 'CO', dark: '#C9BFAE', light: '#7A6F5E' },
]

const MECHANICS: TaxonomyRow[] = [
  { key: 'Heavy_Compound', label: 'Heavy Compound', code: 'HC', dark: '#E5786C', light: '#C24B3E' },
  { key: 'Secondary_Compound', label: 'Secondary Compound', code: 'SC', dark: '#E6AE52', light: '#A8700F' },
  { key: 'Isolation', label: 'Isolation', code: 'IS', dark: '#6EA8EF', light: '#2C6FBE' },
  { key: 'Stability_Isometric', label: 'Stability Isometric', code: 'SI', dark: '#A891F5', light: '#6A4ED3' },
]

const TAXONOMY: Record<GlanceLens, TaxonomyRow[]> = {
  bodyPart: BODY,
  targetCategory: TARGET,
  mechanicsTier: MECHANICS,
}

const UNCLASSIFIED: GlanceClassification = {
  key: '__unclassified', label: 'Unclassified', code: '—', dark: '#70747C', light: '#777B82',
  order: 999, unclassified: true,
}
const GREYS = ['#7D8189', '#8E9299', '#6C7078', '#9FA3AA', '#5E626A', '#747880']
const WARMUP_ROLES = new Set<SetRole>(['rampup'])

function normalizeEnum(value: string): string {
  return value.trim().replaceAll('-', '_').toLocaleLowerCase()
}

function hashIndex(value: string, length: number): number {
  let hash = 0
  for (const character of value) hash = (hash * 31 + character.charCodeAt(0)) >>> 0
  return hash % length
}

export function resolveClassification(
  lens: GlanceLens,
  value: string | null | undefined,
): GlanceClassification {
  if (!value?.trim()) return { ...UNCLASSIFIED }
  const normalized = normalizeEnum(value)
  const index = TAXONOMY[lens].findIndex((row) => normalizeEnum(row.key) === normalized)
  if (index >= 0) return { ...TAXONOMY[lens][index]!, order: index }

  if (import.meta.env.DEV) console.warn(`[glance] unmapped ${lens} value: ${value}`)
  const grey = GREYS[hashIndex(value, GREYS.length)]!
  return {
    key: value,
    label: value.replaceAll('_', ' '),
    code: value.slice(0, 4).toLocaleUpperCase(),
    dark: grey,
    light: grey,
    order: 500,
    unknown: true,
  }
}

function rangeLabel(set: Pick<EditorSet, 'reps'>): string {
  const minimum = set.reps?.min == null ? '?' : String(set.reps.min)
  const maximum = set.reps?.max == null ? '?' : String(set.reps.max)
  return minimum === maximum ? minimum : `${minimum}–${maximum}`
}

export function formatRepRanges(sets: readonly EditorSet[] | null | undefined): GlanceRepSummary {
  const ordered = [...(sets ?? [])].sort((left, right) => left.ordinal - right.ordinal)
  const warmup = ordered.filter((set) => WARMUP_ROLES.has(set.role))
  const working = ordered.filter((set) => !WARMUP_ROLES.has(set.role))
  const workRanges = working.map(rangeLabel)
  const uniform = workRanges.length > 0 && workRanges.every((range) => range === workRanges[0])

  return {
    workingSets: working.length,
    warmupSets: warmup.length,
    main: working.length ? (uniform ? `${working.length} × ${workRanges[0]}` : workRanges.join(' / ')) : '',
    warmup: warmup.length ? `wu ${warmup.map(rangeLabel).join(' / ')}` : '',
    perSet: ordered.map((set) => `${rangeLabel(set)}${set.role === 'working' ? '' : ` (${set.role.replaceAll('_', '-')})`}`),
  }
}

export function gapsLabel(dayIndices: readonly number[], cycleLength: number): string {
  const unique = [...new Set(dayIndices)].sort((left, right) => left - right)
  if (unique.length < 2) return 'once'
  return `${unique.map((day, index) => {
    const next = unique[index + 1] ?? unique[0]! + cycleLength
    return next - day
  }).join(' · ')} d`
}

export function buildGlanceModel(
  plan: PlanEditorState,
  exercises: readonly ExerciseCatalogItem[],
): GlanceModel {
  const exerciseBySlug = new Map(exercises.map((exercise) => [exercise.slug, exercise]))
  const sourceDays = [...plan.days].sort((left, right) => left.ordinal - right.ordinal)
  const days: GlanceDay[] = sourceDays.map((day, index) => {
    const workout = day.workout_unit
    const dayTarget: GlanceEditorTarget = {
      dayKey: day.clientKey,
      dayId: day.id,
      workoutKey: workout?.clientKey ?? null,
      workoutId: workout?.id ?? null,
    }
    const slots: GlanceSlot[] = [...(workout?.exercise_slots ?? [])]
      .sort((left, right) => left.ordinal - right.ordinal)
      .map((slot, slotIndex) => {
        const defaultVariant = slot.variants.find((variant) => variant.variant_type === 'DEFAULT') ?? null
        const exercise = defaultVariant ? exerciseBySlug.get(defaultVariant.exercise_slug) : undefined
        return {
          key: slot.clientKey,
          id: slot.id,
          position: slotIndex + 1,
          name: slot.name?.trim() || 'Untitled slot',
          role: slot.role,
          variantCount: slot.variants.length,
          exerciseName: exercise?.name_full || exercise?.name || defaultVariant?.exercise_slug || 'No default exercise',
          classes: {
            bodyPart: exercise?.body_part ?? null,
            targetCategory: exercise?.target_category ?? null,
            mechanicsTier: exercise?.mechanics_tier ?? null,
          },
          reps: formatRepRanges(defaultVariant?.sets),
          target: {
            ...dayTarget,
            slotKey: slot.clientKey,
            slotId: slot.id,
          },
        }
      })
    return {
      key: day.clientKey,
      id: day.id,
      index,
      position: index + 1,
      label: day.weekday == null ? `DAY ${index + 1}` : `D${index + 1}`,
      weekday: day.weekday,
      name: day.name,
      icon: day.icon,
      kind: !workout ? 'rest' : slots.length ? 'train' : 'empty',
      workoutName: workout?.name ?? null,
      slots,
      workingSets: slots.reduce((total, slot) => total + slot.reps.workingSets, 0),
      warmupSets: slots.reduce((total, slot) => total + slot.reps.warmupSets, 0),
      target: dayTarget,
    }
  })

  const groupMap = new Map<string, GlanceGroup>()
  for (const day of days) {
    for (const slot of day.slots) {
      const existing = groupMap.get(slot.name)
      if (existing) existing.occurrences.push({ day, slot })
      else groupMap.set(slot.name, {
        name: slot.name,
        first: groupMap.size,
        occurrences: [{ day, slot }],
        workingSets: 0,
        dayCount: 0,
        gaps: '',
      })
    }
  }
  const groups = [...groupMap.values()].map((group) => ({
    ...group,
    workingSets: group.occurrences.reduce((total, occurrence) => total + occurrence.slot.reps.workingSets, 0),
    dayCount: new Set(group.occurrences.map((occurrence) => occurrence.day.index)).size,
    gaps: gapsLabel(group.occurrences.map((occurrence) => occurrence.day.index), days.length),
  }))
  const workouts = days.filter((day) => day.kind !== 'rest')

  return {
    days,
    groups,
    totals: {
      days: days.length,
      workouts: workouts.length,
      rest: days.length - workouts.length,
      slots: workouts.reduce((total, day) => total + day.slots.length, 0),
      uniqueNames: groups.length,
      workingSets: workouts.reduce((total, day) => total + day.workingSets, 0),
    },
  }
}

export function buildLegend(model: GlanceModel, lens: GlanceLens): Array<GlanceClassification & { sets: number; slots: number }> {
  const items = new Map<string, GlanceClassification & { sets: number; slots: number }>()
  for (const day of model.days) {
    for (const slot of day.slots) {
      const classification = resolveClassification(lens, slot.classes[lens])
      const current = items.get(classification.key) ?? { ...classification, sets: 0, slots: 0 }
      current.sets += slot.reps.workingSets
      current.slots += 1
      items.set(classification.key, current)
    }
  }
  return [...items.values()].sort((left, right) => left.order - right.order)
}
