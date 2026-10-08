<script setup lang="ts">
import { computed } from 'vue'

import type { ExerciseTraceResponse } from '@/api/execution-types'
import type { PrescriptionDraft } from '@/stores/executionDrafts'
import { loadValue, parseLoad } from '@/features/execution/format'

const props = defineProps<{ trace: ExerciseTraceResponse; draft: PrescriptionDraft | undefined }>()
const width = 760
const height = 138
const points = computed(() => {
  const result: Array<{ mc: number; set: number; load: number; reps: number | null; kind: string }> = []
  props.trace.exposures.forEach((exposure) => {
    exposure.performance?.sets.forEach((set) => {
      if (set.load_kg != null && set.status === 'performed') result.push({ mc: exposure.microcycle.ordinal, set: set.ordinal, load: set.load_kg, reps: set.repetitions, kind: set.divergence.reps ?? 'in_range' })
    })
  })
  return result
})
const loads = computed(() => {
  const performed = points.value.map((point) => point.load)
  const prescribed = props.trace.exposures.flatMap((exposure) => exposure.prescription.sets.map((set) => set.load_kg).filter((load): load is number => load != null))
  const draft = props.draft?.loads.map(parseLoad).filter((load): load is number => typeof load === 'number') ?? []
  return [...performed, ...prescribed, ...draft]
})
const min = computed(() => loads.value.length ? Math.max(0, Math.min(...loads.value) - 2.5) : 0)
const max = computed(() => loads.value.length ? Math.max(...loads.value) + 2.5 : 1)
const mcs = computed(() => props.trace.exposures.map((exposure) => exposure.microcycle.ordinal))
function x(mc: number): number { const index = mcs.value.indexOf(mc); return 58 + (index / Math.max(1, mcs.value.length)) * 640 }
function y(load: number): number { return 102 - ((load - min.value) / Math.max(1, max.value - min.value)) * 82 }
function color(kind: string): string { return ['below_range'].includes(kind) ? 'var(--execNegative)' : ['top_of_range', 'above_range'].includes(kind) ? 'var(--execPositive)' : 'var(--text)' }
</script>

<template>
  <section class="load-strip" :aria-label="$t('execution.analysis.loadStrip')">
    <header><b class="mono">{{ $t('execution.analysis.loadStrip') }}</b><span><i class="prescribed" />{{ $t('execution.analysis.prescribedLegend') }} <i class="performed" />{{ $t('execution.analysis.performedLegend') }} <i class="next" />{{ $t('execution.analysis.nextLegend') }}</span></header>
    <svg :viewBox="`0 0 ${width} ${height}`" role="img">
      <line x1="48" y1="20" x2="48" y2="106" class="chart-axis" />
      <text x="2" y="25">{{ loadValue(max) }} kg</text><text x="2" y="105">{{ loadValue(min) }} kg</text>
      <g v-for="exposure in trace.exposures" :key="exposure.session.session_id">
        <line v-for="set in exposure.prescription.sets.filter((item) => item.load_kg != null)" :key="set.ordinal" :x1="x(exposure.microcycle.ordinal) - 10" :x2="x(exposure.microcycle.ordinal) + 10" :y1="y(set.load_kg!)" :y2="y(set.load_kg!)" class="prescribed-tick" />
        <text :x="x(exposure.microcycle.ordinal) - 14" y="129">MC{{ exposure.microcycle.ordinal }}</text>
      </g>
      <circle v-for="point in points" :key="`${point.mc}-${point.set}`" :cx="x(point.mc) + (point.set - 1) * 7" :cy="y(point.load)" r="4" :fill="color(point.kind)" tabindex="0"><title>MC{{ point.mc }} · {{ $t('execution.analysis.set', { set: point.set + 1 }) }} · {{ loadValue(point.load) }} kg × {{ point.reps }}</title></circle>
      <template v-if="draft && trace.next?.target">
        <line v-for="(load, index) in draft.loads" :key="index" :x1="710" :x2="734" :y1="y(parseLoad(load) ?? 0)" :y2="y(parseLoad(load) ?? 0)" class="next-tick" />
        <text x="700" y="129">MC{{ trace.next.target.microcycle.ordinal }}</text>
      </template>
    </svg>
  </section>
</template>
