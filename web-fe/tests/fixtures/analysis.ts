import type {
  AnalysisContribution,
  PlanAnalysisResult,
} from '@/api/plan-analysis-types'
import type { PlanAIExportResult } from '@/api/plan-export-types'

function muscleContribution(setId: number): AnalysisContribution {
  return {
    type: 'MUSCLE',
    day_id: 31,
    workout_unit_id: 41,
    slot_id: 51,
    slot_role: 'PRIMARY_PROGRESSIVE',
    variant_id: 61,
    exercise_id: 1,
    exercise_slug: 'barbell_bench_press',
    set_id: setId,
    effective_reps: 4,
    rir_recovery_multiplier: 1.1,
    cumulative_recovery_multiplier: 1,
    muscle_slug: 'pectoralis_major_sternal',
    intent_classification: setId % 3 === 0 ? 'UNCLASSIFIED' : setId % 2 === 0 ? 'INCIDENTAL' : 'INTENTIONAL',
    etu_vector_value: 0.8,
    etu_contribution: 2.5,
    active_tension_value: 0.75,
    recovery_modifier_value: 1.2,
    base_mru: 1.4,
    mru_contribution: 1.54,
  }
}

export function analysisResult(
  overrides: Partial<PlanAnalysisResult> = {},
): PlanAnalysisResult {
  return {
    model_version: 'plan-analysis-v1',
    plan_id: 11,
    revision_id: 21,
    revision_no: 1,
    lock_version: 4,
    resolution_context: {
      global_volume_level: 0,
      focus_area: null,
      axis_overrides: {},
    },
    timing_assumptions: [
      {
        day_id: 32,
        day_ordinal: 1,
        timing_source: 'ORDINAL_ASSUMPTION',
        hour_offset: 24,
        detail: 'No weekday; used plan ordinal.',
      },
    ],
    model_parameters: {
      microcycle_hours: 168,
      effective_reps_by_rir: { '0': 5, '1': 4, '2': 3, '3': 2, '4': 1 },
      rir_recovery_multiplier: { '0': 1.2, '1': 1.1, '2': 1, '3': 0.9, '4': 0.8 },
      cumulative_set_penalty_step: 0.05,
      cumulative_set_penalty_cap: 1.25,
      meaningful_contribution_epsilon: 0.0001,
      recovery_convergence_epsilon_hours: 0.01,
      recovery_max_cycles: 100,
      muscle_recovery_velocity_v1: 0.289425511,
      joint_recovery_velocity_v1: 0.312,
    },
    recovery_converged: false,
    simulation_cycles: 100,
    plan_summary: {
      total_etu_scalar: 31.5,
      muscles: [
        {
          slug: 'pectoralis_major_sternal',
          fcsa_cm2: 53,
          total_etu: 24.5,
          etu_per_fcsa_cm2: 0.462,
          intentional_etu: 12,
          incidental_etu: 8,
          unclassified_etu: 4.5,
          total_mru: 14,
          maximum_post_workout_hours_to_fresh: 80,
          worst_pre_workout_hours_to_fresh: 18,
          recovery_converged: false,
        },
      ],
      joints: [
        {
          slug: 'glenohumeral_joint',
          total_joint_load_exposure: 9.25,
          total_jru: 4.2,
          maximum_post_workout_hours_to_fresh: 23,
          worst_pre_workout_hours_to_fresh: 7,
          recovery_converged: true,
        },
      ],
    },
    timeline: [
      {
        day_id: 31,
        day_ordinal: 0,
        day_name: 'Push A',
        weekday: 1,
        hour_offset: 0,
        elapsed_hours_since_previous_entry: 0,
        workout: {
          workout_unit_id: 41,
          name: 'Push A workout',
          stimulus: {
            total_etu_scalar: 31.5,
            muscles: [
              {
                slug: 'pectoralis_major_sternal',
                etu_absolute: 24.5,
                mru: 14,
                recovery_hours_added: 48,
              },
            ],
            joints: [
              {
                slug: 'glenohumeral_joint',
                joint_load_exposure: 9.25,
                jru: 4.2,
                recovery_hours_added: 13.5,
              },
            ],
          },
        },
        muscle_recovery_before: [
          { slug: 'pectoralis_major_sternal', hours_to_fresh: 18 },
        ],
        muscle_recovery_after: [
          { slug: 'pectoralis_major_sternal', hours_to_fresh: 80 },
        ],
        joint_recovery_before: [
          { slug: 'glenohumeral_joint', hours_to_fresh: 7 },
        ],
        joint_recovery_after: [
          { slug: 'glenohumeral_joint', hours_to_fresh: 23 },
        ],
      },
      {
        day_id: 32,
        day_ordinal: 1,
        day_name: 'Rest',
        weekday: 2,
        hour_offset: 24,
        elapsed_hours_since_previous_entry: 24,
        workout: null,
        muscle_recovery_before: [
          { slug: 'pectoralis_major_sternal', hours_to_fresh: 56 },
        ],
        muscle_recovery_after: [
          { slug: 'pectoralis_major_sternal', hours_to_fresh: 56 },
        ],
        joint_recovery_before: [
          { slug: 'glenohumeral_joint', hours_to_fresh: 0 },
        ],
        joint_recovery_after: [
          { slug: 'glenohumeral_joint', hours_to_fresh: 0 },
        ],
      },
    ],
    contributions: [
      muscleContribution(71),
      muscleContribution(72),
      muscleContribution(73),
      {
        type: 'JOINT',
        day_id: 31,
        workout_unit_id: 41,
        slot_id: 51,
        slot_role: 'PRIMARY_PROGRESSIVE',
        variant_id: 61,
        exercise_id: 1,
        exercise_slug: 'barbell_bench_press',
        set_id: 71,
        effective_reps: 4,
        rir_recovery_multiplier: 1.1,
        cumulative_recovery_multiplier: 1,
        joint_slug: 'glenohumeral_joint',
        joint_load_vector_value: 0.8,
        joint_load_exposure: 3.1,
        jru_contribution: 1.4,
      },
    ],
    diagnostics: [
      {
        code: 'RECOVERY_DIVERGENCE',
        severity: 'WARNING',
        message: 'Repeated microcycle did not converge.',
        exercise_slug: null,
        affected_muscle_slugs: ['pectoralis_major_sternal'],
        affected_joint_slugs: ['glenohumeral_joint'],
      },
      {
        code: 'MISSING_ETU_VECTOR',
        severity: 'WARNING',
        message: 'An exercise has no ETU vector.',
        exercise_slug: 'barbell_bench_press',
        affected_muscle_slugs: [],
        affected_joint_slugs: [],
      },
    ],
    ...overrides,
  }
}

export function largeMuscleProvenance(count = 2000): AnalysisContribution[] {
  return Array.from({ length: count }, (_, index) => muscleContribution(1000 + index))
}

export function planExportResult(): PlanAIExportResult {
  return {
    format: 'agonez-plan-sanity-v1',
    plan_name: 'PPLPP',
    resolution_context: {
      global_volume_level: 0,
      focus_area: null,
      axis_overrides: {},
    },
    days: [
      {
        day: 1,
        name: 'Push A',
        weekday: 'Monday',
        rest: false,
        exercises: [
          {
            name: 'Barbell Bench Press',
            slug: 'barbell_bench_press',
            sets: [{ reps: { min: 5, max: 7 }, rir: 2 }],
          },
        ],
      },
      {
        day: 2,
        name: 'Rest',
        weekday: 'Tuesday',
        rest: true,
        exercises: [],
      },
    ],
  }
}
