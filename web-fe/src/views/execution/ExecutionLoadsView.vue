<script setup lang="ts">
import { computed, inject, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import { executionApi } from '@/api/execution'
import type { LoadSeriesResponse } from '@/api/execution-types'
import ErrorState from '@/components/common/ErrorState.vue'
import ExecutionSkeleton from '@/components/execution/ExecutionSkeleton.vue'
import LoadsChart from '@/components/execution/LoadsChart.vue'
import { executionContextKey } from '@/features/execution/context'

const context = inject(executionContextKey)!
const route = useRoute()
const router = useRouter()
const data = ref<LoadSeriesResponse | null>(null)
const loading = ref(true)
const error = ref<string | null>(null)
const focused = ref<number | null>(null)
const metric = computed(() => ['top_set_load', 'mean_set_load', 'volume_load'].includes(String(route.query.metric)) ? String(route.query.metric) : 'top_set_load')
const scale = computed<'relative' | 'kg'>(() => route.query.scale === 'kg' ? 'kg' : 'relative')
const selected = computed(() => String(route.query.traces ?? '').split(',').map(Number).filter((id) => Number.isFinite(id) && id > 0))
const groups = computed(() => {
  const map = new Map<number, { id: number; name: string; series: LoadSeriesResponse['series'] }>()
  data.value?.series.forEach((series) => { const group = map.get(series.workout_trace_id) ?? { id: series.workout_trace_id, name: series.workout_name, series: [] }; group.series.push(series); map.set(series.workout_trace_id, group) })
  return [...map.values()]
})

function updateQuery(patch: Record<string, string | undefined>): void { void router.replace({ query: { ...route.query, ...patch } }) }
function setSelected(ids: number[]): void { updateQuery({ traces: ids.length ? ids.join(',') : 'none' }) }
function toggle(id: number): void { const ids = new Set(selected.value); if (ids.has(id)) ids.delete(id); else ids.add(id); setSelected([...ids]) }
function toggleGroup(ids: number[]): void { const next = new Set(selected.value); const all = ids.every((id) => next.has(id)); ids.forEach((id) => all ? next.delete(id) : next.add(id)); setSelected([...next]) }
function primary(): void { setSelected(groups.value.map((group) => group.series[0]?.exercise_trace_id).filter((id): id is number => id != null)) }

async function load(): Promise<void> {
  loading.value = true; error.value = null
  try {
    data.value = await executionApi.loadSeries(context.runId.value, metric.value)
    if (!route.query.traces) setSelected(data.value.series.slice(0, 7).map((series) => series.exercise_trace_id))
  } catch (caught) { error.value = caught instanceof Error ? caught.message : null }
  finally { loading.value = false }
}

onMounted(() => void load())
watch(metric, () => void load())
</script>

<template>
  <div class="loads-view exec-page">
    <ExecutionSkeleton v-if="loading" :rows="8" />
    <ErrorState v-else-if="error || !data" :title="$t('execution.loads.loadError')" :message="error || $t('execution.loads.loadError')" @retry="load" />
    <template v-else>
      <aside class="loads-sidebar">
        <header><span class="eyebrow">{{ $t('execution.loads.traces', { shown: selected.length, total: data.series.length }) }}</span><div><button type="button" @click="primary">{{ $t('execution.loads.primary') }}</button><button type="button" @click="setSelected(data.series.map((series) => series.exercise_trace_id))">{{ $t('execution.loads.all') }}</button><button type="button" @click="setSelected([])">{{ $t('execution.loads.none') }}</button></div></header>
        <section v-for="group in groups" :key="group.id"><button class="loads-group" type="button" @click="toggleGroup(group.series.map((series) => series.exercise_trace_id))"><b>{{ group.name }}</b><span class="mono">{{ group.series.filter((series) => selected.includes(series.exercise_trace_id)).length }}/{{ group.series.length }}</span></button><label v-for="series in group.series" :key="series.exercise_trace_id" class="loads-series" @mouseenter="focused = series.exercise_trace_id" @mouseleave="focused = null"><input type="checkbox" :checked="selected.includes(series.exercise_trace_id)" @change="toggle(series.exercise_trace_id)" /><i :style="{ background: `hsl(${(series.exercise_trace_id * 47) % 360} 48% 62%)` }" /><span>{{ series.display_name }}</span><em class="mono">{{ series.delta_pct == null ? '—' : `${series.delta_pct > 0 ? '+' : ''}${series.delta_pct}%` }}</em></label></section>
      </aside>
      <section class="loads-content">
        <header class="loads-header"><div><span class="eyebrow">{{ $t('execution.loads.eyebrow') }}</span><h1>{{ $t('execution.loads.title') }}</h1><p>{{ $t('execution.loads.subtitle') }}</p></div><div class="loads-controls"><label>{{ $t('execution.loads.metric') }}<select class="exec-select" :value="metric" @change="updateQuery({ metric: ($event.target as HTMLSelectElement).value })"><option v-for="item in ['top_set_load', 'mean_set_load', 'volume_load']" :key="item" :value="item">{{ $t(`execution.loads.${item}`) }}</option></select></label><div class="exec-segmented" role="radiogroup" :aria-label="$t('execution.loads.scale')"><button type="button" role="radio" :aria-checked="scale === 'relative'" @click="updateQuery({ scale: undefined })">{{ $t('execution.loads.relative') }}</button><button type="button" role="radio" :aria-checked="scale === 'kg'" @click="updateQuery({ scale: 'kg' })">{{ $t('execution.loads.kg') }}</button></div></div></header>
        <div v-if="selected.length" class="loads-chart-panel"><LoadsChart :data="data" :selected="selected" :scale="scale" :focused="focused" @focus="focused = $event" /></div><section v-else class="inline-state panel"><h2>{{ $t('execution.loads.noSelection') }}</h2><p>{{ $t('execution.loads.noSelectionBody') }}</p><button class="button primary" type="button" @click="setSelected(data.series.map((series) => series.exercise_trace_id))">{{ $t('execution.loads.showAll') }}</button></section>
        <section class="unit-summary"><span class="eyebrow">{{ $t('execution.loads.byUnit') }}</span><div><button v-for="summary in data.workout_summaries" :key="summary.workout_trace_id" type="button" class="panel" @click="setSelected(data.series.filter((series) => series.workout_trace_id === summary.workout_trace_id).map((series) => series.exercise_trace_id))"><b>{{ summary.workout_name }}</b><span class="mono">{{ summary.mean_delta_pct == null ? '—' : `${summary.mean_delta_pct > 0 ? '+' : ''}${summary.mean_delta_pct}%` }}</span><small>{{ summary.series_count }}</small></button></div></section>
      </section>
    </template>
  </div>
</template>
