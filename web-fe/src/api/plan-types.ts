export type PlanRevisionStatus = 'DRAFT' | 'RELEASED' | 'ARCHIVED'
export type ExerciseSlotRole =
  | 'PRIMARY_PROGRESSIVE'
  | 'SECONDARY_PROGRESSIVE'
  | 'VOLUME_ACCUMULATION'
  | 'ACCESSORY'
export type ExerciseVariantType = 'DEFAULT' | 'FALLBACK'
export type LoadingMode = 'high_load' | 'moderate_load' | 'low_load'
export type SetRole = 'rampup' | 'working' | 'working_topset' | 'working_backoff' | 'working_amrap'
export type RepRangeSemantics = 'gating' | 'estimate' | 'undefined'
export type RIRPrescription = 'RIR0' | 'RIR1' | 'RIR2' | 'RIR3' | 'RIR4' | 'NOT_APPLICABLE' | 'UNDEFINED'

export type LoadSpec =
  | { kind: 'absolute' }
  | { kind: 'athlete_selected' }
  | { kind: 'relative_to_set'; ref_set_idx: number; pct: number }
  | { kind: 'relative_to_working'; pct: number }
  | { kind: 'table_derived'; ref_set_idx: number; table: string }
  | { kind: 'ordinal_variant'; level: number }

export interface RepRange {
  min: number
  max: number
  semantics: RepRangeSemantics
}

export interface SetInfraDraft {
  id: number | null
  ordinal: number
  reps: RepRange
  rir: RIRPrescription
  role: SetRole
  load_spec: LoadSpec
  min_volume_level: number
  loading_mode: LoadingMode | null
  loading_cycle: LoadingMode[] | null
}

export interface ExerciseVariantDraft {
  id: number | null
  ordinal: number
  variant_type: ExerciseVariantType
  exercise_slug: string
  progression_model_slug: string | null
  progression_id: string
  active_working_sets: { min: number; max: number } | null
  sets: SetInfraDraft[]
}

export interface ProgressionModelCatalogItem {
  slug: string
  display_order: number
  name: string
  name_full: string
  when_to_use: string
  how_to_apply: string
}

export interface ProgressionModelCatalogResponse {
  items: ProgressionModelCatalogItem[]
  total: number
}

export interface ExerciseSlotDraft {
  id: number | null
  ordinal: number
  name: string | null
  description: string | null
  goal: string | null
  role: ExerciseSlotRole
  volume_axis: string | null
  loading_mode: LoadingMode
  loading_cycle: LoadingMode[] | null
  target_muscle_slugs: string[]
  variants: ExerciseVariantDraft[]
}

export interface WorkoutUnitDraft {
  id: number | null
  name: string
  description: string | null
  warmup_notes: string | null
  stretch_notes: string | null
  exercise_slots: ExerciseSlotDraft[]
}

export interface DayDraft {
  id: number | null
  ordinal: number
  weekday: number | null
  name: string
  description: string | null
  workout_unit: WorkoutUnitDraft | null
}

export interface PlanDraftUpdate {
  id: number
  revision_id: number
  revision_no: number
  lock_version: number
  name: string
  description: string | null
  days: DayDraft[]
}

export type PlanDraftArtifact = PlanDraftUpdate

export interface PlanCreate {
  name: string
  description: string | null
}

export interface PlanSummary {
  id: number
  name: string
  description: string | null
  created_at: string
  updated_at: string
  draft_revision_id: number | null
  draft_lock_version: number | null
}

export interface PlanListResponse {
  items: PlanSummary[]
}

export interface RevisionSummary {
  id: number
  revision_no: number
  status: PlanRevisionStatus
  lock_version: number
  based_on_revision_id: number | null
  created_at: string
  updated_at: string
  released_at: string | null
}

export interface PlanDetail {
  id: number
  name: string
  description: string | null
  created_at: string
  updated_at: string
  revisions: RevisionSummary[]
}
