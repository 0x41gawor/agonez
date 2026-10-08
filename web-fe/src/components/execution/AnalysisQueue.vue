<script setup lang="ts">
import { computed, ref } from 'vue'

import type { AnalysisQueue } from '@/api/execution-types'
import type { PrescriptionDraft } from '@/stores/executionDrafts'
import { executionDate, loadValue } from '@/features/execution/format'

const props = defineProps<{ queue: AnalysisQueue; selectedTraceId: number | null; drafts: Record<number, PrescriptionDraft> }>()
const emit = defineEmits<{ select: [traceId: number]; workout: [workoutTraceId: number] }>()
const open = ref<Set<number>>(new Set(props.queue.workouts.filter((workout) => workout.state === 'editable').map((workout) => workout.workout_trace_id)))
const totals = computed(() => props.queue.workouts.reduce((result, workout) => ({ total: result.total + workout.exercises.length, saved: result.saved + workout.exercises.filter((item) => item.prescription_saved).length, locked: result.locked + (workout.state === 'editable' ? 0 : workout.exercises.length) }), { total: 0, saved: 0, locked: 0 }))

function toggle(id: number): void {
  const next = new Set(open.value)
  if (next.has(id)) next.delete(id)
  else next.add(id)
  open.value = next
}
</script>

<template>
  <aside class="analysis-queue">
    <header>
      <span class="eyebrow">{{ $t('execution.analysis.queue', { mc: queue.target_microcycle?.ordinal ?? '—' }) }}</span>
      <p>{{ $t('execution.analysis.progress', totals) }} <kbd class="mono">{{ $t('execution.analysis.keyboard') }}</kbd></p>
      <span class="exec-progress"><i :style="{ width: `${totals.total ? (totals.saved / totals.total) * 100 : 0}%` }" /></span>
    </header>
    <section v-for="workout in queue.workouts" :key="workout.workout_trace_id" class="queue-group">
      <button type="button" class="queue-group-button" :aria-expanded="open.has(workout.workout_trace_id)" @click="toggle(workout.workout_trace_id)">
        <span><i>{{ open.has(workout.workout_trace_id) ? '▾' : '▸' }}</i><b>{{ workout.workout_name }}</b></span>
        <em class="mono" :class="workout.state">{{ workout.state === 'editable' ? $t('execution.analysis.ready') : $t('execution.common.locked') }}</em>
      </button>
      <div class="queue-group-meta">
        <span v-if="workout.basis_session">{{ $t('execution.analysis.basedOn', { mc: workout.basis_session.microcycle_ordinal, date: executionDate(workout.basis_session.scheduled_date) }) }}</span>
        <span v-else>{{ $t(`execution.blocked.${workout.blocked_reason ?? 'unknown'}`) }}</span>
        <button type="button" @click="emit('workout', workout.workout_trace_id)">{{ $t('execution.analysis.workoutTrace') }} →</button>
      </div>
      <div v-if="open.has(workout.workout_trace_id)">
        <button v-for="exercise in workout.exercises" :key="exercise.exercise_trace_id" type="button" class="queue-item" :aria-current="selectedTraceId === exercise.exercise_trace_id ? 'true' : undefined" @click="emit('select', exercise.exercise_trace_id)">
          <span class="queue-state" :class="{ dirty: drafts[exercise.exercise_trace_id]?.dirty, saved: exercise.prescription_saved, locked: workout.state !== 'editable' }">
            {{ workout.state !== 'editable' ? '–' : drafts[exercise.exercise_trace_id]?.dirty ? '●' : exercise.prescription_saved ? '✓' : '○' }}
          </span>
          <span><b>{{ exercise.slot_ordinal + 1 }} · {{ exercise.name }}</b><small class="mono" v-if="exercise.last_summary">MC{{ exercise.last_summary.microcycle_ordinal }} · {{ loadValue(exercise.last_summary.top_load_kg) }} kg · {{ exercise.last_summary.reps.join('/') }}</small><small v-else>{{ $t('execution.analysis.noSummary') }}</small></span>
        </button>
      </div>
    </section>
  </aside>
</template>
