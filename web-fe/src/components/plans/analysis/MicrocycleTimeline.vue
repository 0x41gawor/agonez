<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'

import type { AnalysisTimelineDay } from '@/api/plan-analysis-types'
import { weekdayLabel } from '@/features/plans/analysis'
import { formatNumber } from '@/utils/format'

const props = defineProps<{
  days: AnalysisTimelineDay[]
  selectedDayId: number | null
}>()
const { t } = useI18n()

defineEmits<{ select: [dayId: number] }>()

const weeks = computed(() =>
  Array.from({ length: Math.ceil(props.days.length / 7) }, (_, index) => ({
    number: index + 1,
    days: props.days.slice(index * 7, index * 7 + 7),
  })),
)

const cycleLength = computed(() => {
  const dayCount = props.days.length
  const weekCount = dayCount / 7
  return dayCount > 7
    ? t('analysis.timeline.lengthWeeks', { days: dayCount, weeks: formatNumber(weekCount, Number.isInteger(weekCount) ? 0 : 2) })
    : t('analysis.timeline.lengthDays', { days: dayCount })
})

function debtCount(day: AnalysisTimelineDay): number {
  return (
    day.muscle_recovery_before.filter((item) => item.hours_to_fresh > 0.005).length +
    day.joint_recovery_before.filter((item) => item.hours_to_fresh > 0.005).length
  )
}
</script>

<template>
  <section class="analysis-section timeline-section">
    <header class="analysis-section-heading">
      <div>
        <span class="section-label">{{ $t('analysis.timeline.label') }}</span>
        <h2>{{ $t('analysis.timeline.title') }}</h2>
        <p>{{ $t('analysis.timeline.subtitle') }}</p>
      </div>
      <span class="mono analysis-count">{{ cycleLength }}</span>
    </header>
    <div class="microcycle-week-list">
      <section v-for="week in weeks" :key="week.number" class="timeline-week-group">
        <header v-if="weeks.length > 1" class="timeline-week-heading">
          <strong>{{ $t('analysis.timeline.week', { number: week.number }) }}</strong>
          <span class="mono">
            {{ $t('analysis.timeline.range', { start: (week.number - 1) * 7 + 1, end: (week.number - 1) * 7 + week.days.length }) }}
          </span>
        </header>
        <div class="microcycle-timeline" role="list" :aria-label="$t('analysis.timeline.aria', { number: week.number })">
          <button
            v-for="day in week.days"
            :key="day.day_id"
            class="timeline-day panel"
            :class="{ selected: day.day_id === selectedDayId, rest: !day.workout }"
            type="button"
            role="listitem"
            :aria-pressed="day.day_id === selectedDayId"
            @click="$emit('select', day.day_id)"
          >
            <span class="timeline-weekday mono">{{ weekdayLabel(day.weekday, day.day_ordinal) }}</span>
            <strong>{{ day.workout?.name || day.day_name }}</strong>
            <small v-if="day.workout">{{ formatNumber(day.workout.stimulus.total_etu_scalar, 0) }} ETU</small>
            <small v-else>{{ $t('analysis.timeline.recoveryBoundary', { hours: formatNumber(day.elapsed_hours_since_previous_entry, 0) }) }}</small>
            <span v-if="day.workout && debtCount(day)" class="timeline-warning">
              {{ $t('analysis.timeline.debts', { count: debtCount(day) }) }}
            </span>
            <span v-else class="timeline-rest-label">{{ $t(day.workout ? 'analysis.timeline.fresh' : 'analysis.timeline.rest') }}</span>
          </button>
        </div>
      </section>
    </div>
  </section>
</template>
