<script setup lang="ts">
import { computed, inject, onMounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'

import { executionApi } from '@/api/execution'
import type { WorkoutTraceListItem, WorkoutTraceResponse } from '@/api/execution-types'
import ErrorState from '@/components/common/ErrorState.vue'
import ClassificationTag from '@/components/execution/ClassificationTag.vue'
import ExecutionSkeleton from '@/components/execution/ExecutionSkeleton.vue'
import { executionContextKey } from '@/features/execution/context'
import { useExecutionCycleLabels } from '@/features/execution/cycle-labels'
import { executionDate, loadValue } from '@/features/execution/format'

const props = defineProps<{ workoutTraceId: string }>()
const context = inject(executionContextKey)!
const cycle = useExecutionCycleLabels()
const router = useRouter()
const { t } = useI18n()
const list = ref<WorkoutTraceListItem[]>([])
const trace = ref<WorkoutTraceResponse | null>(null)
const loading = ref(true)
const error = ref<string | null>(null)
const numericId = computed(() => Number(props.workoutTraceId))

async function load(): Promise<void> {
  loading.value = true; error.value = null
  try { const [tabs, result] = await Promise.all([executionApi.workoutTraces(context.runId.value), executionApi.workoutTrace(context.runId.value, numericId.value)]); list.value = tabs.items; trace.value = result }
  catch (caught) { error.value = caught instanceof Error ? caught.message : null }
  finally { loading.value = false }
}
function openExercise(id: number): void { void router.push({ name: 'execution-analysis', params: { runId: context.runId.value }, query: { trace: id } }) }
function cellLabel(cell: WorkoutTraceResponse['rows'][number]['cells'][number]): string {
  if (cell.kind === 'performed') return cell.execution_mode === 'skipped' ? t('execution.workout.skipped') : `${loadValue(cell.performed_top_load_kg)} kg · ${cell.reps.map((rep) => rep ?? '—').join('/')}`
  if (cell.kind === 'prescribed') return `${loadValue(cell.prescribed_top_load_kg)} kg · ${t('execution.workout.prescribed')}`
  return t('execution.workout.empty')
}
function flagLabel(flag: string): string { const key = `execution.analysis.flags.${flag}`; return t(key) === key ? flag : t(key) }

onMounted(() => void load())
watch(numericId, () => void load())
</script>

<template>
  <div class="workout-trace-view page-wrap exec-page">
    <ExecutionSkeleton v-if="loading" mode="analysis" :rows="10" />
    <ErrorState v-else-if="error || !trace" :title="$t('execution.workout.loadError')" :message="error || $t('execution.workout.loadError')" @retry="load" />
    <template v-else>
      <header class="exec-view-header"><div><span class="eyebrow">{{ $t('execution.workout.breadcrumb') }}</span><h1>{{ $t('execution.workout.title', { workout: trace.workout.workout_name }) }}</h1><p>{{ $t(cycle.routeCopy('execution.workout.subtitle'), { day: trace.workout.day_ordinal + 1, count: trace.columns.length }) }}</p></div></header>
      <nav class="workout-unit-tabs" :aria-label="$t('execution.workout.breadcrumb')"><RouterLink v-for="item in list" :key="item.workout_trace_id" :to="{ name: 'execution-workout-trace', params: { runId: context.runId.value, workoutTraceId: item.workout_trace_id } }" :aria-current="item.workout_trace_id === numericId ? 'page' : undefined">{{ item.workout_name }}</RouterLink></nav>
      <p class="exec-help">{{ $t('execution.workout.help') }}</p>
      <div class="workout-matrix-scroll panel">
        <table class="workout-matrix">
          <thead><tr><th>{{ $t('execution.workout.occurrence') }}</th><th v-for="column in trace.columns" :key="column.exercise_trace_id"><button type="button" @click="openExercise(column.exercise_trace_id)"><b>{{ column.display_name }}</b><span class="mono">{{ column.scheme.set_count }} × {{ column.scheme.rep_min }}–{{ column.scheme.rep_max }} @{{ column.scheme.target_rir }}</span><span class="sparkbars"><i v-for="(value, index) in column.top_load_series" :key="index" :style="{ height: `${value == null ? 2 : 4 + ((value - Math.min(...column.top_load_series.filter((item): item is number => item != null))) / Math.max(1, Math.max(...column.top_load_series.filter((item): item is number => item != null)) - Math.min(...column.top_load_series.filter((item): item is number => item != null)))) * 16}px` }" /></span><em v-if="column.delta_pct_first_to_latest != null" class="mono">{{ column.delta_pct_first_to_latest > 0 ? '+' : '' }}{{ column.delta_pct_first_to_latest }}%</em></button></th><th>{{ $t('execution.workout.volume') }}</th><th>{{ $t('execution.common.marker') }}<small>{{ $t('execution.common.reserved') }}</small></th><th>{{ $t('execution.workout.comment') }}</th></tr></thead>
          <tbody>
            <template v-for="row in trace.rows" :key="row.session.session_id">
              <tr v-if="trace.revision_transitions.some((transition) => transition.before_microcycle_ordinal === row.microcycle.ordinal)" class="matrix-revision"><td :colspan="trace.columns.length + 4"><span v-for="transition in trace.revision_transitions.filter((item) => item.before_microcycle_ordinal === row.microcycle.ordinal)" :key="transition.to_revision_no"><b>r{{ transition.from_revision_no }} → r{{ transition.to_revision_no }}</b> · {{ transition.summary }}</span></td></tr>
              <tr><th><span><b class="mono">{{ cycle.shortLabel(row.microcycle.ordinal) }}</b><ClassificationTag :classification="row.microcycle.classification" /></span><small>{{ executionDate(row.session.scheduled_date) }} · {{ $t(`execution.status.${row.session.status}`) }}</small></th><td v-for="cell in row.cells" :key="cell.exercise_trace_id"><button type="button" :class="[`kind-${cell.kind}`, `mode-${cell.execution_mode ?? 'none'}`]" @click="openExercise(cell.exercise_trace_id)"><span class="mono">{{ cellLabel(cell) }}</span><small v-if="cell.actual_exercise_name">⇄ {{ cell.actual_exercise_name }}</small><small v-if="cell.flags.length">{{ cell.flags.map(flagLabel).join(' · ') }}</small></button></td><td class="mono">{{ loadValue(row.volume_load_kg) }}</td><td class="mono">—</td><td>{{ row.performance_comment ?? '—' }}</td></tr>
            </template>
          </tbody>
        </table>
      </div>
    </template>
  </div>
</template>
