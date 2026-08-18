import type { PlanExportRequest } from '@/api/plan-export-types'

export const DEFAULT_PLAN_EXPORT_REQUEST: Readonly<PlanExportRequest> = {
  resolution_context: {
    global_volume_level: 0,
    focus_area: null,
    axis_overrides: {},
  },
}

export function planExportFilename(planName: string): string {
  const safeName = planName
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
  return `${safeName || 'agonez-plan'}-basic.json`
}
