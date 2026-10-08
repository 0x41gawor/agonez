<script setup lang="ts">
import { computed, inject, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { onBeforeRouteLeave, useRoute, useRouter } from 'vue-router'

import { ApiError } from '@/api/client'
import { executionApi } from '@/api/execution'
import type { AnalysisQueue as AnalysisQueueDTO, ExerciseTraceResponse } from '@/api/execution-types'
import AnalysisQueue from '@/components/execution/AnalysisQueue.vue'
import ErrorState from '@/components/common/ErrorState.vue'
import ExerciseTraceTable from '@/components/execution/ExerciseTraceTable.vue'
import ExecutionSkeleton from '@/components/execution/ExecutionSkeleton.vue'
import LoadPerSetStrip from '@/components/execution/LoadPerSetStrip.vue'
import PrescriptionEditor from '@/components/execution/PrescriptionEditor.vue'
import { executionContextKey } from '@/features/execution/context'
import { parseLoad } from '@/features/execution/format'
import { useExecutionDraftsStore } from '@/stores/executionDrafts'

const context = inject(executionContextKey)!
const route = useRoute()
const router = useRouter()
const { t } = useI18n()
const drafts = useExecutionDraftsStore()
const queue = ref<AnalysisQueueDTO | null>(null)
const trace = ref<ExerciseTraceResponse | null>(null)
const loadingQueue = ref(true)
const loadingTrace = ref(false)
const error = ref<string | null>(null)
const saving = ref(false)
const saveErrorCode = ref<string | null>(null)
const queueOpen = ref(false)
const savedMessage = ref('')
const selectedTraceId = computed(() => {
  const value = Number(route.query.trace)
  return Number.isFinite(value) && value > 0 ? value : null
})
const draft = computed(() => selectedTraceId.value ? drafts.drafts[selectedTraceId.value] : undefined)
const ordered = computed(() => queue.value?.workouts.flatMap((workout) => workout.exercises.map((exercise) => ({ ...exercise, workoutTraceId: workout.workout_trace_id }))) ?? [])
const selectedIndex = computed(() => ordered.value.findIndex((item) => item.exercise_trace_id === selectedTraceId.value))

async function loadQueue(): Promise<void> {
  loadingQueue.value = true
  error.value = null
  try {
    queue.value = await executionApi.queue(context.runId.value)
    if (!selectedTraceId.value) {
      const first = queue.value.workouts.find((workout) => workout.state === 'editable')?.exercises[0]
        ?? queue.value.workouts[0]?.exercises[0]
      if (first) await selectTrace(first.exercise_trace_id, true)
    }
  } catch (caught) {
    error.value = caught instanceof Error ? caught.message : t('execution.analysis.loadError')
  } finally {
    loadingQueue.value = false
  }
}

async function loadTrace(preserveDraft = true): Promise<void> {
  if (!selectedTraceId.value) return
  loadingTrace.value = true
  saveErrorCode.value = null
  try {
    const response = await executionApi.exerciseTrace(context.runId.value, selectedTraceId.value)
    trace.value = response
    if (response.next) drafts.initialize(response.trace.exercise_trace_id, response.next, !preserveDraft)
  } catch (caught) {
    error.value = caught instanceof Error ? caught.message : t('execution.analysis.loadError')
  } finally {
    loadingTrace.value = false
  }
}

async function selectTrace(traceId: number, replace = false): Promise<void> {
  queueOpen.value = false
  const navigation = { name: 'execution-analysis', params: { runId: context.runId.value }, query: { trace: traceId } }
  if (replace) await router.replace(navigation)
  else await router.push(navigation)
}

function selectRelative(direction: number, unsavedOnly = false): void {
  if (!ordered.value.length) return
  const start = selectedIndex.value < 0 ? 0 : selectedIndex.value
  for (let offset = 1; offset <= ordered.value.length; offset += 1) {
    const index = (start + direction * offset + ordered.value.length) % ordered.value.length
    const candidate = ordered.value[index]
    if (candidate && (!unsavedOnly || !candidate.prescription_saved)) { void selectTrace(candidate.exercise_trace_id); return }
  }
}

function markDirty(): void { if (selectedTraceId.value) drafts.markDirty(selectedTraceId.value) }
function setLoad(index: number, value: string): void { if (!draft.value) return; draft.value.loads[index] = value; markDirty() }
function setComment(index: number, value: string): void { if (!draft.value) return; draft.value.comments[index] = value; markDirty() }
function setPrescriptionComment(value: string): void { if (!draft.value) return; draft.value.prescriptionComment = value; markDirty() }
function setSelected(index: number, value: boolean): void { if (draft.value) draft.value.selected[index] = value }
function replaceLoads(values: Array<number | null>): void { if (!draft.value) return; draft.value.loads = draft.value.loads.map((_, index) => values[index] == null ? '' : String(values[index])); markDirty() }
function stepAll(direction: number): void { const step = trace.value?.trace.current_plan.load_step_kg; if (!draft.value || step == null) return; draft.value.loads = draft.value.loads.map((load) => String(Math.max(0, (parseLoad(load) ?? 0) + direction * step))); markDirty() }
function applyBulk(value: string): void { if (!draft.value || parseLoad(value) === undefined) return; draft.value.loads = draft.value.loads.map((load, index) => draft.value?.selected[index] ? value : load); markDirty() }
function discard(): void { if (trace.value?.next && selectedTraceId.value) drafts.initialize(selectedTraceId.value, trace.value.next, true) }

async function save(advance = false): Promise<void> {
  if (!trace.value?.next?.target || !draft.value || saving.value) return
  const values = draft.value.loads.map(parseLoad)
  if (values.some((value) => value === undefined)) return
  saving.value = true
  saveErrorCode.value = null
  try {
    const result = await executionApi.savePrescription(context.runId.value, trace.value.next.target.session_id, trace.value.trace.exercise_trace_id, {
      based_on_exercise_performance_id: trace.value.next.basis?.exercise_performance_id ?? null,
      sets: values.map((value, index) => ({ ordinal: index, load_kg: value ?? null, comment: draft.value?.comments[index]?.trim() || null })),
      prescription_comment: draft.value.prescriptionComment.trim() || null,
      expected_version: draft.value.savedVersion,
    })
    trace.value.next = result.next
    drafts.initialize(trace.value.trace.exercise_trace_id, result.next, true)
    savedMessage.value = t('execution.editor.savedToast', { exercise: trace.value.trace.display_name, mc: result.next.target?.microcycle.ordinal ?? '—' })
    await loadQueue()
    await context.reload()
    if (advance) selectRelative(1, true)
  } catch (caught) {
    saveErrorCode.value = caught instanceof ApiError ? caught.code : 'genericError'
    if (caught instanceof ApiError && ['prescription_blocked', 'session_locked', 'not_next_session'].includes(caught.code ?? '')) await loadTrace(true)
  } finally {
    saving.value = false
  }
}

function handleKey(event: KeyboardEvent): void {
  const target = event.target as HTMLElement | null
  const typing = !!target?.closest('input, textarea, select, [contenteditable="true"]')
  if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 's') { event.preventDefault(); void save(false); return }
  if ((event.ctrlKey || event.metaKey) && event.key === 'Enter') { event.preventDefault(); void save(true); return }
  if (typing) return
  if (event.key.toLowerCase() === 'j') { event.preventDefault(); selectRelative(1) }
  if (event.key.toLowerCase() === 'k') { event.preventDefault(); selectRelative(-1) }
  if (event.key === 'Escape') queueOpen.value = false
}

onBeforeRouteLeave(() => !drafts.hasDirty || window.confirm(t('execution.analysis.confirmLeave')))
onMounted(() => { window.addEventListener('keydown', handleKey); void loadQueue() })
onBeforeUnmount(() => window.removeEventListener('keydown', handleKey))
watch(selectedTraceId, () => void loadTrace(), { immediate: true })
</script>

<template>
  <div class="analysis-workspace">
    <div v-if="savedMessage" class="exec-toast" role="status" aria-live="polite">{{ savedMessage }}<button type="button" :aria-label="$t('common.dismiss')" @click="savedMessage = ''">×</button></div>
    <button class="queue-drawer-toggle button" type="button" @click="queueOpen = true">☰ {{ $t('execution.analysis.queueToggle') }}</button>
    <div v-if="queueOpen" class="queue-drawer-backdrop" @click.self="queueOpen = false">
      <AnalysisQueue v-if="queue" :queue="queue" :selected-trace-id="selectedTraceId" :drafts="drafts.drafts" @select="selectTrace" @workout="(id) => router.push({ name: 'execution-workout-trace', params: { runId: context.runId.value, workoutTraceId: id } })" />
    </div>
    <AnalysisQueue v-if="queue" class="queue-desktop" :queue="queue" :selected-trace-id="selectedTraceId" :drafts="drafts.drafts" @select="selectTrace" @workout="(id) => router.push({ name: 'execution-workout-trace', params: { runId: context.runId.value, workoutTraceId: id } })" />
    <div v-else-if="loadingQueue" class="analysis-queue"><ExecutionSkeleton :rows="10" /></div>

    <section class="analysis-trace">
      <ErrorState v-if="error && !trace" :title="$t('execution.analysis.loadError')" :message="error" @retry="loadQueue" />
      <ExecutionSkeleton v-else-if="loadingTrace || !trace" mode="analysis" :rows="12" />
      <template v-else>
        <header class="trace-header">
          <div><span class="eyebrow">{{ $t('execution.analysis.traceEyebrow', { workout: trace.trace.workout_trace.workout_name, slot: trace.trace.slot_ordinal + 1 }) }}</span><h1>{{ trace.trace.display_name }} <small>{{ trace.trace.current_plan.slot_role }}</small></h1><p>{{ trace.trace.current_plan.exercise.variant_label }} · <span class="mono">{{ $t('execution.analysis.plan', { sets: trace.trace.current_plan.sets.length, min: trace.trace.current_plan.sets[0]?.rep_min ?? '—', max: trace.trace.current_plan.sets[0]?.rep_max ?? '—', rir: trace.trace.current_plan.sets[0]?.target_rir ?? '—' }) }}</span></p><p v-if="trace.trace.current_plan.plan_comment" class="trace-plan-note"><b class="mono">{{ $t('execution.analysis.planNote') }}</b>{{ trace.trace.current_plan.plan_comment }}</p></div>
          <div class="trace-navigation"><button class="icon-button" type="button" :aria-label="$t('execution.analysis.previous')" @click="selectRelative(-1)">↑</button><span class="mono">{{ $t('execution.analysis.position', { current: selectedIndex + 1, total: ordered.length }) }}</span><button class="icon-button" type="button" :aria-label="$t('execution.analysis.next')" @click="selectRelative(1)">↓</button></div>
        </header>
        <LoadPerSetStrip :trace="trace" :draft="draft" />
        <ExerciseTraceTable :trace="trace" :draft="draft" />
      </template>
    </section>
    <PrescriptionEditor v-if="trace" :trace="trace" :draft="draft" :saving="saving" :error-code="saveErrorCode" @load="setLoad" @comment="setComment" @prescription-comment="setPrescriptionComment" @selected="setSelected" @replace-loads="replaceLoads" @step-all="stepAll" @apply="applyBulk" @discard="discard" @save="save(false)" @save-next="save(true)" @reload="loadTrace(true)" />
  </div>
</template>
