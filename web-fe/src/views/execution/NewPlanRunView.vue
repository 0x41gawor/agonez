<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'

import { executionApi } from '@/api/execution'
import type { PlanRunPreview } from '@/api/execution-types'
import type { PlanDetail, PlanSummary, RevisionSummary } from '@/api/plan-types'
import { plansApi } from '@/api/plans'
import ErrorState from '@/components/common/ErrorState.vue'
import ExecutionSkeleton from '@/components/execution/ExecutionSkeleton.vue'
import { useExecutionCycleLabels } from '@/features/execution/cycle-labels'
import { executionDate } from '@/features/execution/format'

const router = useRouter()
const { t } = useI18n()
const plans = ref<PlanSummary[]>([])
const details = ref<Record<number, PlanDetail>>({})
const loading = ref(true)
const error = ref<string | null>(null)
const preview = ref<PlanRunPreview | null>(null)
const cycle = useExecutionCycleLabels(() => preview.value?.microcycle_duration_days)
const previewError = ref<string | null>(null)
const creating = ref(false)
const planId = ref<number | null>(null)
const revisionId = ref<number | null>(null)
const name = ref('')
const startsOn = ref(new Date().toISOString().slice(0, 10))
const count = ref(8)
let timer: ReturnType<typeof setTimeout> | null = null

const plan = computed(() => plans.value.find((item) => item.id === planId.value) ?? null)
const revisions = computed(() => planId.value ? details.value[planId.value]?.revisions ?? [] : [])
const revision = computed<RevisionSummary | null>(() => revisions.value.find((item) => item.id === revisionId.value) ?? null)
const valid = computed(() => !!revisionId.value && !!name.value.trim() && /^\d{4}-\d{2}-\d{2}$/.test(startsOn.value) && count.value >= 1 && count.value <= 52)

async function load(): Promise<void> {
  loading.value = true; error.value = null
  try {
    plans.value = (await plansApi.list()).items
    const planDetails = await Promise.all(plans.value.map((item) => plansApi.detail(item.id)))
    details.value = Object.fromEntries(planDetails.map((item) => [item.id, item]))
    const first = plans.value[0]
    if (first) { planId.value = first.id; selectDefaultRevision(); name.value = t('execution.newRun.defaultName', { plan: first.name }) }
  } catch (caught) { error.value = caught instanceof Error ? caught.message : null }
  finally { loading.value = false }
}
function selectDefaultRevision(): void { const candidates = revisions.value; revisionId.value = candidates.find((item) => item.status === 'RELEASED')?.id ?? candidates.find((item) => item.status === 'DRAFT')?.id ?? candidates[0]?.id ?? null }
function changePlan(): void { selectDefaultRevision(); if (plan.value) name.value = t('execution.newRun.defaultName', { plan: plan.value.name }) }
async function loadPreview(): Promise<void> {
  if (!revisionId.value || !startsOn.value || count.value < 1 || count.value > 52) { preview.value = null; return }
  previewError.value = null
  try { preview.value = await executionApi.preview({ plan_revision_id: revisionId.value, starts_on: startsOn.value, microcycle_count: count.value }) }
  catch (caught) { preview.value = null; previewError.value = caught instanceof Error ? caught.message : null }
}
function schedulePreview(): void { if (timer) clearTimeout(timer); timer = setTimeout(() => void loadPreview(), 300) }
async function create(): Promise<void> {
  if (!valid.value || !revisionId.value || creating.value) return
  creating.value = true; error.value = null
  try { const created = await executionApi.createRun({ plan_revision_id: revisionId.value, name: name.value.trim(), starts_on: startsOn.value, microcycle_count: count.value }); await router.push({ name: 'execution-overview', params: { runId: created.run.plan_run_id } }) }
  catch (caught) { error.value = caught instanceof Error ? caught.message : null }
  finally { creating.value = false }
}

watch([revisionId, startsOn, count], schedulePreview)
onMounted(() => void load())
onBeforeUnmount(() => { if (timer) clearTimeout(timer) })
</script>

<template>
  <div class="new-run-view page-wrap exec-page">
    <ExecutionSkeleton v-if="loading" :rows="8" />
    <ErrorState v-else-if="error && !plans.length" :title="$t('execution.newRun.loadError')" :message="error" @retry="load" />
    <template v-else>
      <header class="new-run-header"><RouterLink :to="{ name: 'execution' }">← {{ $t('execution.newRun.back') }}</RouterLink><span class="eyebrow">{{ $t('execution.run.eyebrow') }}</span><h1>{{ $t('execution.newRun.title') }}</h1><p>{{ $t('execution.newRun.subtitle') }}</p></header>
      <section v-if="!plans.length" class="inline-state panel"><h2>{{ $t('execution.newRun.noPlans') }}</h2><RouterLink class="button primary" to="/plans">{{ $t('app.myPlans') }}</RouterLink></section>
      <div v-else class="new-run-grid">
        <form class="panel new-run-form" @submit.prevent="create">
          <label>{{ $t('execution.newRun.plan') }}<select v-model="planId" class="exec-select" @change="changePlan"><option v-for="item in plans" :key="item.id" :value="item.id">{{ item.name }}</option></select></label>
          <label>{{ $t('execution.newRun.revision') }}<select v-model="revisionId" class="exec-select"><option v-for="item in revisions" :key="item.id" :value="item.id">r{{ item.revision_no }} · {{ $t(`execution.newRun.revisionStatus.${item.status.toLowerCase()}`) }}</option></select></label>
          <p v-if="revision?.status === 'DRAFT'" class="exec-warning">{{ $t('execution.newRun.draftWarning') }}</p>
          <label>{{ $t('execution.newRun.name') }}<input v-model="name" class="exec-input" maxlength="200" /></label>
          <div class="new-run-fields"><label>{{ $t('execution.newRun.start') }}<input v-model="startsOn" class="exec-input" type="date" /></label><label>{{ $t(cycle.routeCopy('execution.newRun.count')) }}<input v-model.number="count" class="exec-input mono" type="number" min="1" max="52" /></label></div>
          <label>{{ $t('execution.newRun.end') }}<output class="exec-output mono">{{ preview ? executionDate(preview.ends_on, { day: '2-digit', month: 'short', year: 'numeric' }) : '—' }}</output></label>
          <p v-if="error" class="exec-inline-error" role="alert">{{ error }}</p><p v-if="previewError" class="exec-inline-error" role="alert">{{ previewError }}</p>
          <footer><RouterLink class="button ghost" :to="{ name: 'execution' }">{{ $t('execution.common.cancel') }}</RouterLink><button class="button primary" type="submit" :disabled="!valid || !preview || creating">{{ creating ? $t('execution.newRun.creating') : $t('execution.newRun.create') }}</button></footer>
        </form>
        <aside class="panel new-run-preview"><span class="eyebrow accent">{{ $t('execution.newRun.preview') }}</span><template v-if="preview"><div class="preview-stats"><span><b class="mono">{{ count }}</b>{{ $t(cycle.routeCopy('execution.newRun.microcycles')) }}</span><span><b class="mono">{{ preview.session_count }}</b>{{ $t('execution.newRun.sessions') }}</span><span><b class="mono">{{ preview.workout_track_count }}</b>{{ $t('execution.newRun.workouts') }}</span><span><b class="mono">{{ preview.exercise_track_count }}</b>{{ $t('execution.newRun.exercises') }}</span></div><div class="preview-days"><span v-for="day in preview.first_microcycle" :key="day.day_ordinal"><b class="mono">D{{ day.day_ordinal + 1 }} · {{ executionDate(day.date) }}</b><small>{{ day.workout_unit_name ?? '—' }}</small></span></div><p v-if="preview.overlapping_runs.length" class="exec-warning">{{ $t('execution.newRun.overlap', { count: preview.overlapping_runs.length }) }}<br /><b v-for="item in preview.overlapping_runs" :key="item.plan_run_id">{{ item.name }} · {{ executionDate(item.starts_on) }}–{{ executionDate(item.ends_on) }}</b></p></template><p v-else>{{ $t('execution.newRun.invalid') }}</p></aside>
      </div>
    </template>
  </div>
</template>
