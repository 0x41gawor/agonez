import type { ExerciseSlotRole } from './plan-types'

export interface PlanResolutionContext {
  global_volume_level: number
  focus_area: string | null
  axis_overrides: Record<string, number>
}

export interface PlanAnalysisRequest {
  resolution_context: PlanResolutionContext
}

export type DiagnosticSeverity = 'INFO' | 'WARNING' | 'ERROR'
export type IntentClassification = 'INTENTIONAL' | 'INCIDENTAL' | 'UNCLASSIFIED'

export interface AnalysisDiagnostic {
  code: string
  severity: DiagnosticSeverity
  message: string
  exercise_slug: string | null
  affected_muscle_slugs: string[]
  affected_joint_slugs: string[]
}

export interface TimingAssumption {
  day_id: number
  day_ordinal: number
  timing_source: 'MICROCYCLE_ORDINAL' | 'WEEKDAY' | 'ORDINAL_ASSUMPTION'
  hour_offset: number
  detail: string
}

export interface AnalysisModelParameters {
  microcycle_days: number
  microcycle_hours: number
  microcycle_weeks: number
  weekly_normalization_factor: number
  effective_reps_by_rir: Record<string, number>
  rir_recovery_multiplier: Record<string, number>
  cumulative_set_penalty_step: number
  cumulative_set_penalty_cap: number
  meaningful_contribution_epsilon: number
  recovery_convergence_epsilon_hours: number
  recovery_max_cycles: number
  muscle_recovery_velocity_v1: number
  joint_recovery_velocity_v1: number
}

export interface MuscleAnalysisSummary {
  slug: string
  fcsa_cm2: number | null
  total_etu: number
  weekly_etu: number
  etu_per_fcsa_cm2: number | null
  weekly_etu_per_fcsa_cm2: number | null
  intentional_etu: number
  weekly_intentional_etu: number
  incidental_etu: number
  weekly_incidental_etu: number
  unclassified_etu: number
  weekly_unclassified_etu: number
  total_mru: number
  maximum_post_workout_hours_to_fresh: number
  worst_pre_workout_hours_to_fresh: number
  recovery_converged: boolean
}

export interface JointAnalysisSummary {
  slug: string
  total_joint_load_exposure: number
  total_jru: number
  maximum_post_workout_hours_to_fresh: number
  worst_pre_workout_hours_to_fresh: number
  recovery_converged: boolean
}

export interface PlanAnalysisSummary {
  total_etu_scalar: number
  weekly_etu_scalar: number
  muscles: MuscleAnalysisSummary[]
  joints: JointAnalysisSummary[]
}

export interface MuscleStimulus {
  slug: string
  etu_absolute: number
  mru: number
  recovery_hours_added: number
}

export interface JointStimulus {
  slug: string
  joint_load_exposure: number
  jru: number
  recovery_hours_added: number
}

export interface WorkoutStimulus {
  total_etu_scalar: number
  muscles: MuscleStimulus[]
  joints: JointStimulus[]
}

export interface RecoveryState {
  slug: string
  hours_to_fresh: number
}

export interface TimelineWorkout {
  workout_unit_id: number
  name: string
  stimulus: WorkoutStimulus
}

export interface AnalysisTimelineDay {
  day_id: number
  day_ordinal: number
  day_name: string
  weekday: number | null
  hour_offset: number
  elapsed_hours_since_previous_entry: number
  workout: TimelineWorkout | null
  muscle_recovery_before: RecoveryState[]
  muscle_recovery_after: RecoveryState[]
  joint_recovery_before: RecoveryState[]
  joint_recovery_after: RecoveryState[]
}

interface ContributionBase {
  day_id: number
  workout_unit_id: number
  slot_id: number
  slot_role: ExerciseSlotRole
  variant_id: number
  exercise_id: number
  exercise_slug: string
  set_id: number
  effective_reps: number
  rir_recovery_multiplier: number
  cumulative_recovery_multiplier: number
}

export interface MuscleContribution extends ContributionBase {
  type: 'MUSCLE'
  muscle_slug: string
  intent_classification: IntentClassification
  etu_vector_value: number | null
  etu_contribution: number | null
  active_tension_value: number | null
  recovery_modifier_value: number | null
  base_mru: number | null
  mru_contribution: number | null
}

export interface JointContribution extends ContributionBase {
  type: 'JOINT'
  joint_slug: string
  joint_load_vector_value: number
  joint_load_exposure: number
  jru_contribution: number
}

export type AnalysisContribution = MuscleContribution | JointContribution

export interface PlanAnalysisResult {
  model_version: string
  plan_id: number
  revision_id: number
  revision_no: number
  lock_version: number
  resolution_context: PlanResolutionContext
  timing_assumptions: TimingAssumption[]
  model_parameters: AnalysisModelParameters
  recovery_converged: boolean
  simulation_cycles: number
  plan_summary: PlanAnalysisSummary
  timeline: AnalysisTimelineDay[]
  contributions: AnalysisContribution[]
  diagnostics: AnalysisDiagnostic[]
}
