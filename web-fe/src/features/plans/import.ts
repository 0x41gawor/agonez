import type {
  PlanAIExportDay,
  PlanAIExportExercise,
  PlanAIExportResult,
  PlanAIExportSet,
} from '@/api/plan-export-types'
import type { PlanResolutionContext } from '@/api/plan-analysis-types'

export const PLAN_IMPORT_FORMAT = 'agonez-plan-sanity-v1'
export const PLAN_IMPORT_MAX_BYTES = 1024 * 1024

const WEEKDAYS = new Set([
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
])

export class PlanImportValidationError extends Error {
  constructor(public readonly issues: string[]) {
    super(issues[0] ?? 'The JSON document is not a valid Agonez plan.')
    this.name = 'PlanImportValidationError'
  }
}

function objectValue(
  value: unknown,
  path: string,
  issues: string[],
): Record<string, unknown> | null {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    issues.push(`${path} must be an object.`)
    return null
  }
  return value as Record<string, unknown>
}

function rejectUnknownKeys(
  value: Record<string, unknown>,
  allowed: readonly string[],
  path: string,
  issues: string[],
): void {
  const accepted = new Set(allowed)
  for (const key of Object.keys(value)) {
    if (!accepted.has(key)) issues.push(`${path}.${key} is not a supported field.`)
  }
}

function stringValue(
  value: unknown,
  path: string,
  issues: string[],
  maxLength: number,
): string {
  if (typeof value !== 'string' || !value.trim()) {
    issues.push(`${path} must be a non-empty string.`)
    return ''
  }
  const normalized = value.trim()
  if (normalized.length > maxLength) issues.push(`${path} must be at most ${maxLength} characters.`)
  return normalized
}

function integerValue(
  value: unknown,
  path: string,
  issues: string[],
  minimum: number,
  maximum: number,
): number {
  if (!Number.isInteger(value) || (value as number) < minimum || (value as number) > maximum) {
    issues.push(`${path} must be a whole number from ${minimum} to ${maximum}.`)
    return minimum
  }
  return value as number
}

function arrayValue(value: unknown, path: string, issues: string[], maximum: number): unknown[] {
  if (!Array.isArray(value)) {
    issues.push(`${path} must be an array.`)
    return []
  }
  if (value.length > maximum) issues.push(`${path} may contain at most ${maximum} items.`)
  return value
}

function parseResolutionContext(value: unknown, issues: string[]): PlanResolutionContext {
  const path = '$.resolution_context'
  const source = objectValue(value, path, issues)
  if (!source) return { global_volume_level: 0, focus_area: null, axis_overrides: {} }
  rejectUnknownKeys(source, ['global_volume_level', 'focus_area', 'axis_overrides'], path, issues)

  const globalVolumeLevel = integerValue(
    source.global_volume_level,
    `${path}.global_volume_level`,
    issues,
    0,
    32767,
  )
  let focusArea: string | null = null
  if (source.focus_area !== null) {
    if (typeof source.focus_area !== 'string') {
      issues.push(`${path}.focus_area must be a string or null.`)
    } else if (source.focus_area.length > 100) {
      issues.push(`${path}.focus_area must be at most 100 characters.`)
    } else {
      focusArea = source.focus_area
    }
  }

  const overridesSource = objectValue(source.axis_overrides, `${path}.axis_overrides`, issues)
  const overrideEntries: Array<[string, number]> = []
  if (overridesSource) {
    for (const [axis, level] of Object.entries(overridesSource)) {
      if (!axis.trim() || axis.length > 100) {
        issues.push(`${path}.axis_overrides keys must contain 1 to 100 characters.`)
        continue
      }
      overrideEntries.push([
        axis,
        integerValue(level, `${path}.axis_overrides.${axis}`, issues, 0, 32767),
      ])
    }
  }

  return {
    global_volume_level: globalVolumeLevel,
    focus_area: focusArea,
    axis_overrides: Object.fromEntries(overrideEntries),
  }
}

function parseSet(value: unknown, path: string, issues: string[]): PlanAIExportSet {
  const source = objectValue(value, path, issues)
  if (!source) return { reps: { min: 1, max: 1 }, rir: 0 }
  rejectUnknownKeys(source, ['reps', 'rir'], path, issues)
  const reps = objectValue(source.reps, `${path}.reps`, issues)
  if (reps) rejectUnknownKeys(reps, ['min', 'max'], `${path}.reps`, issues)
  const minimum = integerValue(reps?.min, `${path}.reps.min`, issues, 1, 32767)
  const maximum = integerValue(reps?.max, `${path}.reps.max`, issues, 1, 32767)
  if (maximum < minimum) issues.push(`${path}.reps.max must be greater than or equal to reps.min.`)
  return {
    reps: { min: minimum, max: maximum },
    rir: integerValue(source.rir, `${path}.rir`, issues, 0, 4),
  }
}

function parseExercise(value: unknown, path: string, issues: string[]): PlanAIExportExercise {
  const source = objectValue(value, path, issues)
  if (!source) return { name: '', slug: '', sets: [] }
  rejectUnknownKeys(source, ['name', 'slug', 'sets'], path, issues)
  const slug = stringValue(source.slug, `${path}.slug`, issues, 200)
  if (slug && !/^[a-z0-9_]+$/.test(slug)) {
    issues.push(`${path}.slug must use lowercase letters, numbers, and underscores only.`)
  }
  return {
    name: stringValue(source.name, `${path}.name`, issues, 200),
    slug,
    sets: arrayValue(source.sets, `${path}.sets`, issues, 100).map((item, index) =>
      parseSet(item, `${path}.sets[${index}]`, issues),
    ),
  }
}

function parseDay(value: unknown, index: number, issues: string[]): PlanAIExportDay {
  const path = `$.days[${index}]`
  const source = objectValue(value, path, issues)
  if (!source) return { day: index + 1, name: '', weekday: null, rest: true, exercises: [] }
  rejectUnknownKeys(source, ['day', 'name', 'weekday', 'rest', 'exercises'], path, issues)
  const day = integerValue(source.day, `${path}.day`, issues, 1, 365)
  if (day !== index + 1) issues.push(`${path}.day must be ${index + 1} to match its array position.`)

  let weekday: string | null = null
  if (source.weekday !== null) {
    if (typeof source.weekday !== 'string' || !WEEKDAYS.has(source.weekday)) {
      issues.push(`${path}.weekday must be a full English weekday name or null.`)
    } else {
      weekday = source.weekday
    }
  }
  const rest = typeof source.rest === 'boolean' ? source.rest : false
  if (typeof source.rest !== 'boolean') issues.push(`${path}.rest must be true or false.`)
  const exercises = arrayValue(source.exercises, `${path}.exercises`, issues, 100).map(
    (item, exerciseIndex) => parseExercise(item, `${path}.exercises[${exerciseIndex}]`, issues),
  )
  if (rest && exercises.length) issues.push(`${path}.exercises must be empty when rest is true.`)

  return {
    day,
    name: stringValue(source.name, `${path}.name`, issues, 200),
    weekday,
    rest,
    exercises,
  }
}

export function parsePlanImportJson(json: string): PlanAIExportResult {
  let value: unknown
  try {
    value = JSON.parse(json) as unknown
  } catch {
    throw new PlanImportValidationError(['The selected file is not valid JSON.'])
  }

  const issues: string[] = []
  const source = objectValue(value, '$', issues)
  if (!source) throw new PlanImportValidationError(issues)
  rejectUnknownKeys(source, ['format', 'plan_name', 'resolution_context', 'days'], '$', issues)

  if (source.format !== PLAN_IMPORT_FORMAT) {
    issues.push(`$.format must be "${PLAN_IMPORT_FORMAT}".`)
  }
  const result: PlanAIExportResult = {
    format: PLAN_IMPORT_FORMAT,
    plan_name: stringValue(source.plan_name, '$.plan_name', issues, 200),
    resolution_context: parseResolutionContext(source.resolution_context, issues),
    days: arrayValue(source.days, '$.days', issues, 365).map((day, index) =>
      parseDay(day, index, issues),
    ),
  }
  if (issues.length) throw new PlanImportValidationError(issues)
  return result
}
