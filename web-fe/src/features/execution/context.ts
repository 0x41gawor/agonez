import type { InjectionKey, Ref } from 'vue'

import type { PlanRunListItem, PlanRunOverview } from '@/api/execution-types'

export interface ExecutionContext {
  runId: Ref<number>
  overview: Ref<PlanRunOverview | null>
  runs: Ref<PlanRunListItem[]>
  loading: Ref<boolean>
  error: Ref<string | null>
  reload: () => Promise<void>
}

export const executionContextKey: InjectionKey<ExecutionContext> = Symbol('execution-context')
