export type Vector = Record<string, number>
export type SortOrder = 'asc' | 'desc'
export type ExerciseSort =
  | 'name'
  | 'name_full'
  | 'load_capacity'
  | 'systemic_propulsive_fcsa_demand'
  | 'created_at'
  | 'updated_at'

export interface ExerciseListItem {
  slug: string
  name: string
  name_full: string
  body_part: string
  target_category: string
  mechanics_tier: string
  resistance_source: string
  execution_pattern: string
  load_capacity: number | null
  systemic_propulsive_fcsa_demand: number | null
  created_at: string
  updated_at: string
  has_engine_vectors: boolean
  image_url: string | null
}

export interface ExerciseFacets {
  body_part: Record<string, number>
  target_category: Record<string, number>
  mechanics_tier: Record<string, number>
  resistance_source: Record<string, number>
}

export interface ExerciseListResponse {
  items: ExerciseListItem[]
  total: number
  page: number
  per_page: number
  facets: ExerciseFacets
}

export interface ExerciseEngine {
  propulsive_fcsa_contribution_vector: Vector | null
  active_tension_exposure_vector: Vector | null
  etu_vector: Vector | null
  muscle_recovery_cost_modifier_vector: Vector | null
  joint_load_exposure_vector: Vector | null
}

export interface ExerciseDetail extends Omit<ExerciseListItem, 'has_engine_vectors'> {
  propulsive_fcsa_contribution_vector: Vector | null
  technique: Record<string, unknown>
  comments: Record<string, unknown>
  video_links: string[]
  engine: ExerciseEngine | null
}

export interface ExerciseVideoLinks {
  video_links: string[]
}

export interface MuscleListItem {
  slug: string
  name: string
  display_name: string
  body_part: string
  complex: string
  mass_g: number
  mv_cm3: number
  fiber_bias_type_i: number
  fiber_bias_type_ii: number
  pcsa_projected_fcsa_cm2: number | null
  image_url: string | null
}

export interface MuscleFacets {
  body_part: Record<string, number>
  complex: Record<string, number>
}

export interface MuscleListResponse {
  items: MuscleListItem[]
  total: number
  page: number
  per_page: number
  facets: MuscleFacets
}

export interface MuscleDetail extends MuscleListItem {
  mass_reference: string
  architecture: string
  optimal_fiber_length_cm: number | null
  pennation_angle_deg: number | null
  pennation_cos: number | null
  pcsa: number
  pcsa_fiber_cm2: number | null
  smh_factor: string
  strength_curve: string
  leverage_peak: string
  bible_markdown: string
  article_links: string[]
  video_links: string[]
  gallery: string[]
}

export interface RelatedExercise {
  slug: string
  name: string
  name_full: string
  target_category: string
  mechanics_tier: string
  relation: 'measured' | 'by_target'
  etu_cm2: number | null
  normalized_etu: number | null
}

export interface RelatedExerciseResponse {
  items: RelatedExercise[]
}

export interface AtlasMeta {
  body_part: string[]
  target_category: string[]
  mechanics_tier: string[]
  resistance_source: string[]
  muscle_complex: string[]
  counts: { exercises: number; muscles: number }
}

export interface ExerciseListQuery {
  q?: string
  body_part?: string[]
  target_category?: string[]
  mechanics_tier?: string[]
  resistance_source?: string[]
  sort?: ExerciseSort
  order?: SortOrder
  page?: number
  per_page?: number
}

export interface MuscleListQuery {
  q?: string
  body_part?: string[]
  complex?: string[]
  sort?: 'name' | 'mass_g' | 'mv_cm3' | 'fiber_bias_type_ii' | 'pcsa_fiber_cm2' | 'pcsa_projected_fcsa_cm2'
  order?: SortOrder
  page?: number
  per_page?: number
}

export type QueryValue = string | number | boolean | null | undefined | readonly string[]
export type QueryRecord = Record<string, QueryValue>
