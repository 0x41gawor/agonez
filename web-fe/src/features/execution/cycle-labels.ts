import { computed, inject, toValue, type MaybeRefOrGetter } from 'vue'
import { useI18n } from 'vue-i18n'

import { executionContextKey } from '@/features/execution/context'

type CycleOrdinal = number | string

export function useExecutionCycleLabels(durationDays?: MaybeRefOrGetter<number | null | undefined>) {
  const context = inject(executionContextKey, null)
  const { t } = useI18n()
  const resolvedDuration = computed(() => durationDays === undefined
    ? context?.overview.value?.run.microcycle_duration_days
    : toValue(durationDays))
  const isWeekly = computed(() => resolvedDuration.value === 7)

  function label(ordinal: CycleOrdinal): string {
    return t(`execution.cycle.${isWeekly.value ? 'week' : 'microcycle'}.label`, { ordinal })
  }

  function shortLabel(ordinal: CycleOrdinal): string {
    return t(`execution.cycle.${isWeekly.value ? 'week' : 'microcycle'}.short`, { ordinal })
  }

  function routeCopy(baseKey: string): string {
    return isWeekly.value ? `${baseKey}Week` : baseKey
  }

  function text(key: string, ordinal: CycleOrdinal, values: Record<string, unknown> = {}): string {
    const rendered = t(key, { ...values, mc: ordinal })
    if (!isWeekly.value) return rendered
    const source = t('execution.cycle.microcycle.short', { ordinal })
    return rendered.replace(source, shortLabel(ordinal))
  }

  return { isWeekly, label, shortLabel, routeCopy, text }
}
