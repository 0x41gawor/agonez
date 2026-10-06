import type { PlanResolutionContext } from './plan-analysis-types'
import type { LoadSpec, RIRPrescription, RepRangeSemantics, SetRole } from './plan-types'

export interface PlanExportRequest {
  resolution_context: PlanResolutionContext
}

export interface PlanAIExportSet {
  reps: { min: number; max: number; semantics: RepRangeSemantics }
  rir: RIRPrescription
  role: SetRole
  load_spec: LoadSpec
}

export interface PlanAIExportExercise {
  name: string
  slug: string
  progression_model: string | null
  progression_id: string
  active_working_sets: { min: number; max: number } | null
  sets: PlanAIExportSet[]
}

export interface PlanAIExportDay {
  day: number
  name: string
  weekday: string | null
  rest: boolean
  exercises: PlanAIExportExercise[]
}

export interface PlanAIExportResult {
  format: 'agonez-plan-sanity-v4'
  plan_name: string
  resolution_context: PlanResolutionContext
  days: PlanAIExportDay[]
}

export interface PlanAIImportProgressionModel {
  slug: string
  name?: string | null
  name_full?: string | null
  when_to_use?: string | null
  how_to_apply?: string | null
}

export interface PlanAIImportExercise {
  name: string
  slug: string
  progression_model?: PlanAIImportProgressionModel | string | null
  progression_id?: string
  active_working_sets?: { min: number; max: number } | null
  sets: PlanAIExportSet[]
}

export interface PlanAIImportDay {
  day: number
  name: string
  weekday: string | null
  rest: boolean
  exercises: PlanAIImportExercise[]
}

export interface PlanAIImportDocument {
  format: 'agonez-plan-sanity-v1' | 'agonez-plan-sanity-v2' | 'agonez-plan-sanity-v3' | 'agonez-plan-sanity-v4'
  plan_name: string
  resolution_context: PlanResolutionContext
  days: PlanAIImportDay[]
}
