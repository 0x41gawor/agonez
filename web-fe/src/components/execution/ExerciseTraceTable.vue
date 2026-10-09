<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import type { ExerciseExposure, ExerciseTraceResponse, SetPerformance } from '@/api/execution-types'
import type { PrescriptionDraft } from '@/stores/executionDrafts'
import { useExecutionCycleLabels } from '@/features/execution/cycle-labels'
import { executionDate, executionDateTime, loadValue, parseLoad } from '@/features/execution/format'
import ClassificationTag from './ClassificationTag.vue'

const props = defineProps<{ trace: ExerciseTraceResponse; draft: PrescriptionDraft | undefined }>()
const { t } = useI18n()
const cycle = useExecutionCycleLabels()
const expanded = ref<Set<number>>(new Set())
const columns = computed(() => Math.max(props.trace.trace.current_plan.sets.length, ...props.trace.exposures.map((item) => Math.max(item.prescription.sets.length, item.performance?.sets.length ?? 0))))
const gridStyle = computed(() => ({ gridTemplateColumns: `160px 64px repeat(${columns.value}, minmax(142px, 156px)) minmax(320px, 1fr)` }))

function toggle(id: number): void { const next = new Set(expanded.value); if (next.has(id)) next.delete(id); else next.add(id); expanded.value = next }
function performedFor(exposure: ExerciseExposure, ordinal: number): SetPerformance | undefined { return exposure.performance?.sets.find((set) => (set.prescribed_set_ordinal ?? set.ordinal) === ordinal) }
function divergence(set: SetPerformance | undefined): string { if (!set) return ''; return [set.divergence.load === 'below' || set.divergence.reps === 'below_range' || set.divergence.rir === 'deeper' ? 'negative' : '', set.divergence.load === 'above' || set.divergence.reps === 'top_of_range' || set.divergence.reps === 'above_range' ? 'positive' : ''].filter(Boolean).join(' ') }
function sessionLabel(exposure: ExerciseExposure): string { return exposure.session.status === 'completed' ? t(`execution.completion.${exposure.session.completion_mode ?? 'as_prescribed'}`) : t(`execution.status.${exposure.session.status}`) }
</script>

<template>
  <section class="trace-table-scroll">
    <div class="exercise-trace-table" role="table" :style="gridStyle">
      <div class="trace-table-head" role="row" :style="gridStyle"><span>{{ $t('execution.analysis.exposure') }}</span><span /><span v-for="index in columns" :key="index">{{ $t('execution.analysis.set', { set: index }) }}</span><span>{{ $t('execution.analysis.comments') }}</span></div>
      <template v-for="exposure in trace.exposures" :key="exposure.session.session_id">
        <div v-if="trace.revision_transitions.some((transition) => transition.before_microcycle_ordinal === exposure.microcycle.ordinal)" class="trace-revision-row" :style="{ gridColumn: `1 / span ${columns + 3}` }">
          <template v-for="transition in trace.revision_transitions.filter((item) => item.before_microcycle_ordinal === exposure.microcycle.ordinal)" :key="transition.to_revision_no"><b class="mono">{{ $t('execution.analysis.revision', { from: transition.from_revision_no, to: transition.to_revision_no }) }}</b><span>{{ cycle.text('execution.analysis.revisionBody', transition.before_microcycle_ordinal, { date: executionDate(transition.effective_on), changes: transition.slot_changes.join(', ') || '—' }) }}</span></template>
        </div>
        <div class="trace-exposure-label" role="rowheader">
          <button type="button" :aria-label="cycle.text(expanded.has(exposure.session.session_id) ? 'execution.analysis.collapse' : 'execution.analysis.expand', exposure.microcycle.ordinal)" @click="toggle(exposure.session.session_id)">{{ expanded.has(exposure.session.session_id) ? '▾' : '▸' }}</button>
          <span><b class="mono">{{ cycle.shortLabel(exposure.microcycle.ordinal) }}</b><small class="mono">{{ executionDate(exposure.session.scheduled_date, { weekday: 'short', day: '2-digit', month: 'short' }) }}</small><ClassificationTag :classification="exposure.microcycle.classification" /></span>
        </div>
        <span class="trace-row-label prescribed mono">{{ $t('execution.analysis.prescription') }}</span>
        <span v-for="index in columns" :key="`p-${index}`" class="trace-set-cell prescribed mono">{{ exposure.prescription.sets[index - 1] ? `${loadValue(exposure.prescription.sets[index - 1]?.load_kg ?? null)} × ${exposure.prescription.sets[index - 1]?.rep_min}–${exposure.prescription.sets[index - 1]?.rep_max} @${exposure.prescription.sets[index - 1]?.target_rir ?? '—'}` : '—' }}</span>
        <span class="trace-comment-cell prescribed"><small v-if="exposure.prescription.prescription_comment">{{ $t('execution.analysis.prescription') }}</small>{{ exposure.prescription.prescription_comment ?? $t('execution.analysis.noComment') }}</span>

        <span class="trace-row-label actual mono">{{ exposure.performance?.status === 'draft' ? $t('execution.analysis.draft') : $t('execution.analysis.actual') }}</span>
        <template v-if="exposure.performance?.execution_mode === 'skipped'"><span class="trace-span-state skipped" :style="{ gridColumn: `3 / span ${columns}` }">{{ $t('execution.analysis.exerciseSkipped') }}</span></template>
        <template v-else-if="['missed', 'cancelled', 'scheduled'].includes(exposure.session.status)"><span class="trace-span-state" :class="exposure.session.status" :style="{ gridColumn: `3 / span ${columns}` }">{{ $t(`execution.analysis.${exposure.session.status}`) }} · {{ executionDate(exposure.session.scheduled_date) }}</span></template>
        <template v-else>
          <span v-for="index in columns" :key="`a-${index}`" class="trace-set-cell actual mono" :class="[divergence(performedFor(exposure, index - 1)), { draft: exposure.performance?.status === 'draft' }]">
            <template v-if="performedFor(exposure, index - 1)?.status === 'skipped'">{{ $t('execution.analysis.setSkipped') }}</template>
            <template v-else-if="performedFor(exposure, index - 1)">{{ loadValue(performedFor(exposure, index - 1)?.load_kg ?? null) }} × <b>{{ performedFor(exposure, index - 1)?.repetitions }}</b> @{{ performedFor(exposure, index - 1)?.rir }}<i v-if="performedFor(exposure, index - 1)?.is_additional">{{ $t('execution.analysis.additional') }}</i></template>
            <template v-else-if="exposure.performance?.status === 'draft'">{{ $t('execution.analysis.notSynced') }}</template><template v-else>—</template>
          </span>
        </template>
        <span class="trace-comment-cell actual"><small>{{ sessionLabel(exposure) }}</small><template v-if="exposure.performance?.execution_mode === 'substituted'">{{ $t('execution.analysis.substituted', { exercise: exposure.performance.actual_exercise?.name ?? '—' }) }} · </template>{{ exposure.performance?.comment ?? $t('execution.analysis.noComment') }}</span>
        <div v-if="expanded.has(exposure.session.session_id)" class="trace-exposure-detail" :style="{ gridColumn: `1 / span ${columns + 3}` }">
          <p><b>{{ $t('execution.analysis.session') }}</b> {{ executionDate(exposure.session.scheduled_date) }} · {{ $t(`execution.status.${exposure.session.status}`) }} · r{{ exposure.microcycle.plan_revision_no }}</p>
          <table><thead><tr><th>{{ $t('execution.analysis.set', { set: '' }) }}</th><th>{{ $t('execution.overview.prescribed') }}</th><th>{{ $t('execution.overview.performed') }}</th><th>{{ $t('execution.analysis.recorded') }}</th><th>{{ $t('execution.analysis.setComment') }}</th></tr></thead><tbody><tr v-for="set in exposure.performance?.sets ?? []" :key="set.ordinal"><td>{{ set.ordinal + 1 }}</td><td>{{ loadValue(exposure.prescription.sets[set.prescribed_set_ordinal ?? -1]?.load_kg ?? null) }}</td><td>{{ loadValue(set.load_kg) }} × {{ set.repetitions }} @{{ set.rir }}</td><td>{{ executionDateTime(set.recorded_at) }}</td><td>{{ set.comment ?? '—' }}</td></tr></tbody></table>
        </div>
      </template>

      <template v-if="trace.next?.target">
        <div class="trace-exposure-label next-row"><span><b class="mono">{{ cycle.shortLabel(trace.next.target.microcycle.ordinal) }} · NEXT</b><small class="mono">{{ executionDate(trace.next.target.scheduled_date) }}</small></span></div>
        <span class="trace-row-label next-row mono">{{ $t('execution.analysis.prescription') }}</span>
        <template v-if="trace.next.state === 'editable' && draft"><span v-for="index in columns" :key="`n-${index}`" class="trace-set-cell next-row mono">{{ index <= draft.loads.length ? `${loadValue(parseLoad(draft.loads[index - 1] ?? '') ?? null)} kg` : '—' }}</span><span class="trace-comment-cell next-row">{{ draft.prescriptionComment || $t('execution.analysis.noComment') }}</span></template>
        <template v-else><span class="trace-span-state locked" :style="{ gridColumn: `3 / span ${columns + 1}` }">{{ $t(`execution.blocked.${trace.next.blocked_reason ?? 'unknown'}`) }}</span></template>
        <span class="trace-row-label actual mono">{{ $t('execution.analysis.actual') }}</span><span class="trace-span-state" :style="{ gridColumn: `3 / span ${columns + 1}` }">{{ $t('execution.analysis.performanceAfterSync') }}</span>
      </template>
    </div>
  </section>
</template>
