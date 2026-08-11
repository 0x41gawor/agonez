import type { ExerciseDetail, Vector } from '@/api/types'

export type VisualizationMode = 'etu' | 'recovery' | 'propulsive'

export const SVG_TO_DB: Record<string, string> = {
  anterior_deltoid: 'deltoid_anterior',
  lateral_deltoid: 'deltoid_lateral',
  posterior_deltoid: 'deltoid_posterior',
  rotator_cuff: 'rotator_cuffs',
}

export const DB_TO_SVG: Record<string, string> = Object.fromEntries(
  Object.entries(SVG_TO_DB).map(([svg, db]) => [db, svg]),
)

export function exerciseVector(exercise: ExerciseDetail, mode: VisualizationMode): Vector | null {
  if (mode === 'propulsive') return exercise.engine?.propulsive_fcsa_contribution_vector ?? exercise.propulsive_fcsa_contribution_vector
  if (mode === 'etu') return exercise.engine?.etu_vector ?? null
  const active = exercise.engine?.active_tension_exposure_vector
  const cost = exercise.engine?.muscle_recovery_cost_modifier_vector
  if (!active || !cost) return null
  const recovery: Vector = {}
  for (const [slug, exposure] of Object.entries(active)) recovery[slug] = exposure * (cost[slug] ?? 0)
  return recovery
}

export function normalizeVector(vector: Vector, capacities: Record<string, number | null | undefined>): Vector {
  const ratios: Vector = {}
  let maximum = 0
  for (const [slug, raw] of Object.entries(vector)) {
    const capacity = capacities[slug]
    const ratio = capacity && capacity > 0 ? Math.max(0, raw) / capacity : 0
    ratios[slug] = ratio
    maximum = Math.max(maximum, ratio)
  }
  if (maximum <= 0) return Object.fromEntries(Object.keys(vector).map((slug) => [slug, 0]))
  return Object.fromEntries(Object.entries(ratios).map(([slug, ratio]) => [slug, ratio / maximum]))
}

export function heatmapMix(intensity: number): number {
  const value = Math.min(1, Math.max(0, intensity))
  return 12 + 88 * value ** 0.75
}

export function jointStyle(value: number): { opacity: number; strokeWidth: number } {
  const normalized = Math.min(1, Math.max(0, value))
  return { opacity: 0.35 + 0.65 * normalized, strokeWidth: 1.5 + 4 * normalized }
}
