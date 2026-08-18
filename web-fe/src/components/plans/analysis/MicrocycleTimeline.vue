<script setup lang="ts">
import type { AnalysisTimelineDay } from '@/api/plan-analysis-types'
import { weekdayLabel } from '@/features/plans/analysis'
import { formatNumber } from '@/utils/format'

defineProps<{
  days: AnalysisTimelineDay[]
  selectedDayId: number | null
}>()

defineEmits<{ select: [dayId: number] }>()

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
        <span class="section-label">Microcycle timeline</span>
        <h2>Select a day boundary</h2>
        <p>Backend chronology · rest days preserve recovery intervals.</p>
      </div>
      <span class="mono analysis-count">{{ days.length }} days</span>
    </header>
    <div class="microcycle-timeline" role="list" aria-label="Analyzed microcycle days">
      <button
        v-for="day in days"
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
        <small v-else>{{ formatNumber(day.elapsed_hours_since_previous_entry, 0) }} h recovery boundary</small>
        <span v-if="day.workout && debtCount(day)" class="timeline-warning">
          {{ debtCount(day) }} active debts
        </span>
        <span v-else class="timeline-rest-label">{{ day.workout ? 'Fresh entry' : 'Rest' }}</span>
      </button>
    </div>
  </section>
</template>
