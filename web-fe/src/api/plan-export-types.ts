import type { PlanResolutionContext } from './plan-analysis-types'

export interface PlanExportRequest {
  resolution_context: PlanResolutionContext
}

export interface PlanAIExportSet {
  reps: { min: number; max: number }
  rir: number
}

export interface PlanAIProgressionModel {
  slug: string
  name: string
  name_full: string
  when_to_use: string
  how_to_apply: string
}

export interface PlanAIExportExercise {
  name: string
  slug: string
  progression_model: PlanAIProgressionModel | null
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
  format: 'agonez-plan-sanity-v2'
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
  progression_model?: PlanAIImportProgressionModel | null
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
  format: 'agonez-plan-sanity-v1' | 'agonez-plan-sanity-v2'
  plan_name: string
  resolution_context: PlanResolutionContext
  days: PlanAIImportDay[]
}
