import type { PlanResolutionContext } from './plan-analysis-types'

export interface PlanExportRequest {
  resolution_context: PlanResolutionContext
}

export interface PlanAIExportSet {
  reps: { min: number; max: number }
  rir: number
}

export interface PlanAIExportExercise {
  name: string
  slug: string
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
  format: 'agonez-plan-sanity-v1'
  plan_name: string
  resolution_context: PlanResolutionContext
  days: PlanAIExportDay[]
}
