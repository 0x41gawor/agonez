import type { PlanEditorState } from '@/features/plans/editor'

export type PlanGuidanceTarget = 'days'

export interface PlanGuidanceItem {
  id: 'missing-rest-day'
  label: string
  title: string
  message: string
  rationale: string
  actionLabel: string
  target: PlanGuidanceTarget
}

export function evaluatePlanGuidance(plan: PlanEditorState): PlanGuidanceItem[] {
  if (!plan.days.length || plan.days.some((day) => day.workout_unit === null)) return []

  return [
    {
      id: 'missing-rest-day',
      label: 'Recovery structure',
      title: 'No rest day is modeled',
      message: plan.days.length === 1
        ? 'The only modeled day contains a workout. Rest days belong in the ordered microcycle too.'
        : `All ${plan.days.length} days contain a workout. Rest days belong in the ordered microcycle too.`,
      rationale: 'Explicit rest days let Analysis preserve the recovery intervals you intended.',
      actionLabel: 'Review days',
      target: 'days',
    },
  ]
}
