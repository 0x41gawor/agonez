import type { PlanDraftArtifact } from '@/api/plan-types'
import type { ExerciseListItem, MuscleListItem } from '@/api/types'

export const exercise: ExerciseListItem = {
  slug: 'barbell_bench_press',
  name: 'Bench Press',
  name_full: 'Barbell Bench Press',
  body_part: 'Upper',
  target_category: 'Chest_Sternal',
  mechanics_tier: 'Heavy_Compound',
  resistance_source: 'Barbell',
  execution_pattern: 'Bilateral',
  load_capacity: 72,
  systemic_propulsive_fcsa_demand: 175,
  has_engine_vectors: true,
  image_url: '/media/exercises/barbell_bench_press.png',
}

export const fallbackExercise: ExerciseListItem = {
  ...exercise,
  slug: 'barbell_california_press',
  name: 'California Press',
  name_full: 'Barbell California Press',
}

export const muscle: MuscleListItem = {
  slug: 'pectoralis_major_sternal',
  name: 'Pectoralis major sternal',
  display_name: 'Pectoralis major — sternal',
  body_part: 'Upper',
  complex: 'Chest',
  mass_g: 500,
  mv_cm3: 480,
  fiber_bias_type_i: 0.45,
  fiber_bias_type_ii: 0.55,
  pcsa_projected_fcsa_cm2: 53,
  image_url: null,
}

export function planArtifact(lockVersion = 4): PlanDraftArtifact {
  return {
    id: 11,
    revision_id: 21,
    revision_no: 1,
    lock_version: lockVersion,
    name: 'PPLPP',
    description: 'Five-day microcycle',
    days: [
      {
        id: 31,
        ordinal: 0,
        weekday: 1,
        name: 'Push A',
        description: null,
        workout_unit: {
          id: 41,
          name: 'Push A workout',
          description: null,
          warmup_notes: null,
          stretch_notes: null,
          exercise_slots: [
            {
              id: 51,
              ordinal: 0,
              name: 'Primary chest press',
              description: null,
              goal: 'Main progressive chest stimulus',
              role: 'PRIMARY_PROGRESSIVE',
              volume_axis: null,
              target_muscle_slugs: [muscle.slug],
              variants: [
                {
                  id: 61,
                  ordinal: 0,
                  variant_type: 'DEFAULT',
                  exercise_slug: exercise.slug,
                  sets: [
                    {
                      id: 71,
                      ordinal: 0,
                      reps: { min: 5, max: 7 },
                      rir: 2,
                      min_volume_level: 0,
                    },
                  ],
                },
              ],
            },
          ],
        },
      },
    ],
  }
}
