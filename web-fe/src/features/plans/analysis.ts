import type {
  AnalysisDiagnostic,
  JointContribution,
  MuscleContribution,
} from '@/api/plan-analysis-types'
import type { ExerciseCatalogItem, MuscleListItem } from '@/api/types'
import { i18n } from '@/i18n'
import { formatNumber, prettyToken } from '@/utils/format'

export type AnalysisPhase = 'BEFORE' | 'AFTER'
export type EtuDisplayMode = 'ABSOLUTE' | 'NORMALIZED'
export type EtuTimeBasis = 'MICROCYCLE' | 'WEEKLY'
export type MuscleSort = 'ETU' | 'NORMALIZED' | 'RECOVERY'

export interface MuscleStimulusPresentation {
  slug: string
  absoluteEtu: number
  normalizedEtu: number | null
  fcsaCm2: number | null
  intentionalEtu: number
  incidentalEtu: number
  unclassifiedEtu: number
  recoveryConverged: boolean
}

export function weekdayLabel(weekday: number | null, ordinal: number): string {
  if (weekday != null) {
    const key = `analysis.labels.weekdays.${weekday - 1}`
    return i18n.global.te(key) ? i18n.global.t(key) : `D${ordinal + 1}`
  }
  return `D${String(ordinal + 1).padStart(2, '0')}`
}

export function jointLabel(slug: string): string {
  const key = `analysis.labels.joints.${slug}`
  return i18n.global.te(key) ? i18n.global.t(key) : prettyToken(slug)
}

export function muscleLabel(slug: string, muscles: MuscleListItem[]): string {
  const muscle = muscles.find((item) => item.slug === slug)
  return muscle?.display_name || muscle?.name || prettyToken(slug)
}

export function exerciseLabel(slug: string, exercises: ExerciseCatalogItem[]): string {
  const exercise = exercises.find((item) => item.slug === slug)
  return exercise?.name_full || exercise?.name || prettyToken(slug)
}

export function diagnosticTitle(diagnostic: AnalysisDiagnostic): string {
  if (diagnostic.code.startsWith('MALFORMED_')) return i18n.global.t('analysis.labels.malformed')
  const key = `analysis.labels.diagnostics.${diagnostic.code}`
  return i18n.global.te(key) ? i18n.global.t(key) : prettyToken(diagnostic.code)
}

export function formatHours(value: number): string {
  if (value <= 0.005) return i18n.global.t('analysis.labels.fresh')
  if (value >= 1000) return i18n.global.t('analysis.labels.modeledDebt', { value: formatNumber(value, 0) })
  return i18n.global.t('analysis.labels.toFresh', { value: formatNumber(value, value < 10 ? 1 : 0) })
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
  slot_role: MuscleContribution['slot_role']
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
    const key = `${item.day_id}:${item.exercise_slug}:${item.slot_role}:${item.intent_classification}`
    const group = groups.get(key) ?? {
      key,
      exercise_slug: item.exercise_slug,
      slot_role: item.slot_role,
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
