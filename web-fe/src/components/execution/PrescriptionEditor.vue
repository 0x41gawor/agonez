<script setup lang="ts">
import { computed, ref } from 'vue'

import type { ExerciseTraceResponse } from '@/api/execution-types'
import type { PrescriptionDraft } from '@/stores/executionDrafts'
import { executionDate, loadValue, parseLoad } from '@/features/execution/format'

const props = defineProps<{ trace: ExerciseTraceResponse; draft: PrescriptionDraft | undefined; saving: boolean; errorCode: string | null }>()
const emit = defineEmits<{
  load: [index: number, value: string]; comment: [index: number, value: string]; prescriptionComment: [value: string]; selected: [index: number, value: boolean];
  replaceLoads: [values: Array<number | null>]; stepAll: [direction: number]; apply: [value: string]; discard: []; save: []; saveNext: []; reload: [];
}>()
const bulk = ref('')
const next = computed(() => props.trace.next)
const editable = computed(() => next.value?.state === 'editable' && !!next.value.target && !!props.draft)
const invalid = computed(() => props.draft?.loads.some((load) => parseLoad(load) === undefined) ?? false)
const selectedCount = computed(() => props.draft?.selected.filter(Boolean).length ?? 0)
const status = computed(() => props.saving ? 'saving' : props.draft?.dirty ? 'dirty' : next.value?.prescription ? 'saved' : editable.value ? 'clean' : 'locked')
const errorKey = computed(() => props.errorCode && ['stale_basis', 'version_conflict', 'prescription_blocked', 'session_locked', 'not_next_session', 'set_count_mismatch', 'invalid_load'].includes(props.errorCode) ? props.errorCode : 'genericError')
const basisExposure = computed(() => props.trace.exposures.find((exposure) => exposure.microcycle.ordinal === next.value?.basis?.microcycle_ordinal))
const evidence = computed(() => {
  const sets = basisExposure.value?.performance?.sets.filter((set) => set.status === 'performed') ?? []
  return {
    reps: sets.map((set) => set.repetitions ?? '—').join('/'),
    loads: sets.map((set) => loadValue(set.load_kg)).join('/'),
    top: sets.filter((set) => set.divergence.reps === 'top_of_range').length,
    floor: sets.filter((set) => set.divergence.reps === 'at_floor' || set.divergence.reps === 'below_range').length,
    deeper: sets.filter((set) => set.divergence.rir === 'deeper').length,
  }
})
function lastSet(index: number): string {
  const set = basisExposure.value?.performance?.sets.find((item) => item.prescribed_set_ordinal === index)
  return set && set.status === 'performed' ? `${loadValue(set.load_kg)} × ${set.repetitions ?? '—'} @${set.rir ?? '—'}` : '—'
}
</script>

<template>
  <aside class="prescription-editor">
    <header class="editor-header">
      <span><span class="eyebrow accent">{{ $t('execution.editor.eyebrow') }}</span><h2>{{ $t('execution.editor.title', { exercise: trace.trace.display_name, mc: next?.target?.microcycle.ordinal ?? '—' }) }}</h2><small v-if="next?.target">{{ $t('execution.editor.scheduled', { workout: trace.trace.workout_trace.workout_name, date: executionDate(next.target.scheduled_date) }) }}</small></span>
      <b class="editor-status mono" :class="status">{{ $t(`execution.editor.status.${status}`) }}</b>
    </header>
    <div v-if="errorCode" class="editor-error" role="alert"><b>{{ $t(`execution.editor.${errorKey}`) }}</b><button v-if="['stale_basis', 'version_conflict', 'set_count_mismatch'].includes(errorCode)" type="button" @click="emit('reload')">{{ $t('execution.editor.reload') }}</button></div>

    <template v-if="editable && draft && next?.target">
      <section class="editor-section editor-basis"><p v-if="next.basis">{{ $t('execution.editor.basis', { mc: next.basis.microcycle_ordinal, date: executionDate(next.basis.scheduled_date) }) }}<br /><span>{{ $t('execution.editor.evidence', evidence) }}</span></p><p v-else>{{ $t('execution.editor.firstExposure') }}</p></section>
      <section class="editor-section">
        <span class="editor-label mono">{{ $t('execution.editor.startFrom') }}</span>
        <div class="editor-action-row"><button class="button" type="button" :disabled="!next.defaults.from_previous_prescription.some((value) => value != null)" @click="emit('replaceLoads', next.defaults.from_previous_prescription)">{{ $t('execution.editor.previousPrescription', { mc: next.basis?.microcycle_ordinal ?? '—' }) }}</button><button class="button" type="button" :disabled="!next.defaults.from_previous_performance.some((value) => value != null)" @click="emit('replaceLoads', next.defaults.from_previous_performance)">{{ $t('execution.editor.previousPerformance', { mc: next.basis?.microcycle_ordinal ?? '—' }) }}</button></div>
        <div class="editor-action-row"><button class="button" type="button" :disabled="trace.trace.current_plan.load_step_kg == null" :title="trace.trace.current_plan.load_step_kg == null ? $t('execution.editor.noLoadStep') : undefined" @click="emit('stepAll', -1)">{{ $t('execution.editor.allMinus', { step: trace.trace.current_plan.load_step_kg ?? '—' }) }}</button><button class="button" type="button" :disabled="trace.trace.current_plan.load_step_kg == null" :title="trace.trace.current_plan.load_step_kg == null ? $t('execution.editor.noLoadStep') : undefined" @click="emit('stepAll', 1)">{{ $t('execution.editor.allPlus', { step: trace.trace.current_plan.load_step_kg ?? '—' }) }}</button></div>
      </section>
      <section class="editor-suggestion"><span class="editor-label mono">{{ $t('execution.editor.suggestion') }}</span><b class="mono">{{ $t('execution.editor.suggestionNone') }}</b><p>{{ $t('execution.editor.suggestionBody') }}</p></section>
      <section class="editor-section editor-sets">
        <div v-for="(set, index) in next.plan_sets" :key="set.ordinal" class="editor-set">
          <div class="editor-set-line"><input :id="`select-set-${set.ordinal}`" type="checkbox" :checked="draft.selected[index]" :aria-label="$t('execution.editor.selectSet', { set: index + 1 })" @change="emit('selected', index, ($event.target as HTMLInputElement).checked)" /><label :for="`load-set-${set.ordinal}`" class="mono">S{{ index + 1 }}</label><span class="set-plan mono">{{ set.role }} · {{ set.rep_min }}–{{ set.rep_max }} @{{ set.target_rir ?? '—' }}</span><button type="button" :disabled="trace.trace.current_plan.load_step_kg == null" :aria-label="$t('execution.editor.minus', { set: index + 1, step: trace.trace.current_plan.load_step_kg ?? '—' })" @click="emit('load', index, String(Math.max(0, (parseLoad(draft.loads[index] ?? '') ?? 0) - (trace.trace.current_plan.load_step_kg ?? 0))))">−</button><input :id="`load-set-${set.ordinal}`" class="exec-input load-input mono" :class="{ invalid: parseLoad(draft.loads[index] ?? '') === undefined }" inputmode="decimal" :value="draft.loads[index]" @input="emit('load', index, ($event.target as HTMLInputElement).value)" /><button type="button" :disabled="trace.trace.current_plan.load_step_kg == null" :aria-label="$t('execution.editor.plus', { set: index + 1, step: trace.trace.current_plan.load_step_kg ?? '—' })" @click="emit('load', index, String((parseLoad(draft.loads[index] ?? '') ?? 0) + (trace.trace.current_plan.load_step_kg ?? 0)))">+</button></div>
          <input class="exec-input set-comment-input" :value="draft.comments[index]" :placeholder="$t('execution.editor.comment')" @input="emit('comment', index, ($event.target as HTMLInputElement).value)" />
          <small class="set-last mono">{{ $t('execution.editor.last', { load: lastSet(index) }) }}</small>
          <p v-if="parseLoad(draft.loads[index] ?? '') === undefined" class="field-error">{{ $t('execution.editor.invalid', { set: index + 1 }) }}</p>
        </div>
        <div class="editor-bulk"><input v-model="bulk" class="exec-input mono" inputmode="decimal" placeholder="kg" /><button class="button" type="button" :disabled="!selectedCount || parseLoad(bulk) === undefined" @click="emit('apply', bulk)">{{ $t('execution.editor.apply') }}</button><span>{{ $t('execution.editor.selected', { count: selectedCount }) }}</span></div>
        <p class="editor-plan-owned">{{ $t('execution.editor.planOwned', { revision: trace.trace.current_plan.plan_revision_no }) }}</p>
      </section>
      <section class="editor-section"><label class="editor-label" for="prescription-comment">{{ $t('execution.editor.prescriptionComment') }}</label><textarea id="prescription-comment" class="exec-textarea" :value="draft.prescriptionComment" :placeholder="$t('execution.editor.commentPlaceholder')" @input="emit('prescriptionComment', ($event.target as HTMLTextAreaElement).value)" /></section>
      <footer class="editor-footer"><span v-if="invalid" class="field-error">{{ $t('execution.editor.fix') }}</span><button class="button ghost" type="button" :disabled="saving || !draft.dirty" @click="emit('discard')">{{ $t('execution.editor.discard') }}</button><button class="button" type="button" :disabled="saving || invalid || !draft.dirty" @click="emit('save')">{{ $t('execution.editor.save') }}</button><button class="button primary" type="button" :disabled="saving || invalid || !draft.dirty" @click="emit('saveNext')">{{ $t('execution.editor.saveNext') }}</button></footer>
    </template>
    <section v-else class="editor-locked"><span aria-hidden="true">▣</span><h3>{{ $t(`execution.blocked.${next?.blocked_reason ?? 'unknown'}`) }}</h3><p>{{ $t('execution.editor.lockedHelp') }}</p></section>
  </aside>
</template>
