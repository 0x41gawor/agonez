import type {
  AnalysisDiagnostic,
  JointContribution,
  MuscleContribution,
} from '@/api/plan-analysis-types'
import type { ExerciseListItem, MuscleListItem } from '@/api/types'
import { formatNumber, prettyToken } from '@/utils/format'

export type AnalysisPhase = 'BEFORE' | 'AFTER'
export type EtuDisplayMode = 'ABSOLUTE' | 'NORMALIZED'
export type MuscleSort = 'ETU' | 'NORMALIZED' | 'RECOVERY'

const WEEKDAYS = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'] as const

export const JOINT_LABELS: Record<string, string> = {
  acromioclavicular_joint: 'Acromioclavicular joint',
  cervical_spine: 'Cervical spine',
  elbow_joint: 'Elbow joint',
  glenohumeral_joint: 'Glenohumeral joint',
  hip_joint: 'Hip joint',
  lumbar_spine: 'Lumbar spine',
  patellofemoral_joint: 'Patellofemoral joint',
  radiocarpal_joint: 'Radiocarpal joint',
  scapulothoracic_articulation: 'Scapulothoracic articulation',
  talocrural_joint: 'Talocrural joint',
  tibiofemoral_joint: 'Tibiofemoral joint',
}

const DIAGNOSTIC_TITLES: Record<string, string> = {
  RECOVERY_DIVERGENCE: 'Recovery model did not reach steady state',
  ORDINAL_TIMING_ASSUMPTION: 'Timing assumption',
  ORDINAL_TIMING_WRAPPED: 'Weekly timing wrapped',
  MISSING_ETU_VECTOR: 'ETU data unavailable',
  MISSING_ACTIVE_TENSION_VECTOR: 'Active-tension data unavailable',
  MISSING_RECOVERY_MODIFIER_VECTOR: 'Recovery-modifier data unavailable',
  MISSING_JOINT_LOAD_VECTOR: 'Joint-load data unavailable',
  MISSING_FCSA: 'FCSA normalization unavailable',
}

export function weekdayLabel(weekday: number | null, ordinal: number): string {
  if (weekday != null) return WEEKDAYS[weekday - 1] ?? `D${ordinal + 1}`
  return `D${String(ordinal + 1).padStart(2, '0')}`
}

export function jointLabel(slug: string): string {
  return JOINT_LABELS[slug] ?? prettyToken(slug)
}

export function muscleLabel(slug: string, muscles: MuscleListItem[]): string {
  const muscle = muscles.find((item) => item.slug === slug)
  return muscle?.display_name || muscle?.name || prettyToken(slug)
}

export function exerciseLabel(slug: string, exercises: ExerciseListItem[]): string {
  const exercise = exercises.find((item) => item.slug === slug)
  return exercise?.name_full || exercise?.name || prettyToken(slug)
}

export function diagnosticTitle(diagnostic: AnalysisDiagnostic): string {
  if (diagnostic.code.startsWith('MALFORMED_')) return 'Malformed engine data'
  return DIAGNOSTIC_TITLES[diagnostic.code] ?? prettyToken(diagnostic.code)
}

export function formatHours(value: number): string {
  if (value <= 0.005) return 'Fresh · 0 h'
  if (value >= 1000) return `${formatNumber(value, 0)} h modeled debt`
  return `${formatNumber(value, value < 10 ? 1 : 0)} h to fresh`
}

/** Fixed, transparent display bands. The source hours remain untouched elsewhere. */
export function recoveryBandIntensity(hoursToFresh: number): number {
  if (hoursToFresh <= 0.005) return 0
  if (hoursToFresh <= 24) return 0.25
  if (hoursToFresh <= 48) return 0.5
  if (hoursToFresh <= 72) return 0.75
  return 1
}

export interface MuscleSourceGroup {
  key: string
  exercise_slug: string
  intent_classification: MuscleContribution['intent_classification']
  etu: number
  mru: number
  sets: MuscleContribution[]
}

export function groupMuscleSources(
  contributions: MuscleContribution[],
): MuscleSourceGroup[] {
  const groups = new Map<string, MuscleSourceGroup>()
  for (const item of contributions) {
    const key = `${item.exercise_slug}:${item.intent_classification}`
    const group = groups.get(key) ?? {
      key,
      exercise_slug: item.exercise_slug,
      intent_classification: item.intent_classification,
      etu: 0,
      mru: 0,
      sets: [],
    }
    group.etu += item.etu_contribution ?? 0
    group.mru += item.mru_contribution ?? 0
    group.sets.push(item)
    groups.set(key, group)
  }
  return [...groups.values()].sort((a, b) => b.etu - a.etu)
}

export interface JointSourceGroup {
  exercise_slug: string
  joint_load: number
  jru: number
  sets: JointContribution[]
}

export function groupJointSources(contributions: JointContribution[]): JointSourceGroup[] {
  const groups = new Map<string, JointSourceGroup>()
  for (const item of contributions) {
    const group = groups.get(item.exercise_slug) ?? {
      exercise_slug: item.exercise_slug,
      joint_load: 0,
      jru: 0,
      sets: [],
    }
    group.joint_load += item.joint_load_exposure
    group.jru += item.jru_contribution
    group.sets.push(item)
    groups.set(item.exercise_slug, group)
  }
  return [...groups.values()].sort((a, b) => b.jru - a.jru)
}
