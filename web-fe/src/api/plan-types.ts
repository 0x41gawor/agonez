export type PlanRevisionStatus = 'DRAFT' | 'RELEASED' | 'ARCHIVED'
export type ExerciseSlotRole =
  | 'PRIMARY_PROGRESSIVE'
  | 'SECONDARY_PROGRESSIVE'
  | 'VOLUME_ACCUMULATION'
  | 'ACCESSORY'
export type ExerciseVariantType = 'DEFAULT' | 'FALLBACK'

export interface RepRange {
  min: number
  max: number
}

export interface SetInfraDraft {
  id: number | null
  ordinal: number
  reps: RepRange
  rir: number
  min_volume_level: number
}

export interface ExerciseVariantDraft {
  id: number | null
  ordinal: number
  variant_type: ExerciseVariantType
  exercise_slug: string
  sets: SetInfraDraft[]
}

export interface ExerciseSlotDraft {
  id: number | null
  ordinal: number
  name: string | null
  description: string | null
  goal: string | null
  role: ExerciseSlotRole
  volume_axis: string | null
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
