<script setup lang="ts">
import { computed } from 'vue'

import type { LoadSeriesResponse } from '@/api/execution-types'
import { executionDate, loadValue } from '@/features/execution/format'

const props = defineProps<{ data: LoadSeriesResponse; selected: number[]; scale: 'relative' | 'kg'; focused: number | null }>()
const emit = defineEmits<{ focus: [id: number | null] }>()
const width = 920
const height = 420
const palette = ['#d0b487', '#64a0e8', '#2bc28a', '#e85aad', '#a77ce8', '#f07855', '#86d1c4', '#9db8da', '#c98259', '#7f9ac2', '#cf7598', '#89a96d', '#b48bd6', '#d0cb70', '#6fb0a5']
const visible = computed(() => props.data.series.filter((series) => props.selected.includes(series.exercise_trace_id)))
function value(series: typeof props.data.series[number], point: typeof series.points[number]): number | null { if (point.value == null) return null; return props.scale === 'kg' ? point.value : series.first_value ? (point.value / series.first_value) * 100 : null }
const values = computed(() => visible.value.flatMap((series) => series.points.map((point) => value(series, point)).filter((item): item is number => item != null)))
const min = computed(() => values.value.length ? Math.min(...values.value, props.scale === 'kg' ? Infinity : 95) : 0)
const max = computed(() => values.value.length ? Math.max(...values.value, props.scale === 'kg' ? -Infinity : 105) : 1)
function x(mc: number): number { const index = props.data.x_domain.findIndex((item) => item.microcycle_ordinal === mc); return 62 + (index / Math.max(1, props.data.x_domain.length - 1)) * 826 }
function y(v: number): number { return 352 - ((v - min.value) / Math.max(1, max.value - min.value)) * 292 }
function paths(series: typeof props.data.series[number]): string[] {
  const result: string[] = []; let active = ''
  series.points.forEach((point) => { const v = value(series, point); if (v == null) { if (active) result.push(active); active = ''; return }; const command = active ? 'L' : 'M'; active += `${command}${x(point.microcycle_ordinal)},${y(v)} ` })
  if (active) result.push(active)
  return result
}
function color(id: number): string { return palette[Math.abs(id) % palette.length] ?? palette[0]! }
</script>

<template>
  <div class="loads-chart" role="img" :aria-label="$t('execution.loads.chart')">
    <svg :viewBox="`0 0 ${width} ${height}`">
      <rect v-for="domain in data.x_domain.filter((item) => item.classification !== 'normal')" :key="domain.microcycle_ordinal" :x="x(domain.microcycle_ordinal) - 34" y="24" width="68" height="330" :class="`band-${domain.classification}`"><title>{{ $t(`execution.classification.${domain.classification}`) }}</title></rect>
      <line v-for="tick in 5" :key="tick" x1="62" x2="888" :y1="40 + (tick - 1) * 78" :y2="40 + (tick - 1) * 78" class="chart-grid" />
      <text x="8" y="45">{{ loadValue(max) }}{{ scale === 'relative' ? '%' : ' kg' }}</text><text x="8" y="354">{{ loadValue(min) }}{{ scale === 'relative' ? '%' : ' kg' }}</text>
      <g v-for="(domain, index) in data.x_domain" :key="domain.microcycle_ordinal"><line v-if="index && domain.plan_revision_no !== data.x_domain[index - 1]?.plan_revision_no" :x1="x(domain.microcycle_ordinal)" :x2="x(domain.microcycle_ordinal)" y1="24" y2="354" class="revision-line" /><text :x="x(domain.microcycle_ordinal) - 12" y="382">MC{{ domain.microcycle_ordinal }}</text><text :x="x(domain.microcycle_ordinal) - 22" y="399">{{ executionDate(domain.starts_on) }}</text></g>
      <g v-for="series in visible" :key="series.exercise_trace_id" :class="{ muted: focused != null && focused !== series.exercise_trace_id, focused: focused === series.exercise_trace_id }" @mouseenter="emit('focus', series.exercise_trace_id)" @mouseleave="emit('focus', null)">
        <path v-for="(path, index) in paths(series)" :key="index" :d="path" fill="none" :stroke="color(series.exercise_trace_id)" class="series-line" />
        <circle v-for="point in series.points.filter((item) => value(series, item) != null)" :key="point.microcycle_ordinal" :cx="x(point.microcycle_ordinal)" :cy="y(value(series, point)!)" r="4" :fill="color(series.exercise_trace_id)" tabindex="0"><title>{{ series.display_name }} · MC{{ point.microcycle_ordinal }} · {{ executionDate(point.date) }} · {{ loadValue(point.value) }} kg · {{ series.first_value ? loadValue((point.value! / series.first_value) * 100) : '—' }}% · {{ point.reps.join('/') }} {{ $t('execution.common.reps') }}</title></circle>
        <circle v-for="point in series.points.filter((item) => item.value == null)" :key="`gap-${point.microcycle_ordinal}`" :cx="x(point.microcycle_ordinal)" cy="372" r="3" class="gap-point" tabindex="0"><title>{{ series.display_name }} · MC{{ point.microcycle_ordinal }} · {{ $t('execution.loads.gap', { reason: point.execution_mode }) }}</title></circle>
      </g>
    </svg>
  </div>
</template>
