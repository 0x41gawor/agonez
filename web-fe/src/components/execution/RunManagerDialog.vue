<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from 'vue'

import { ApiError } from '@/api/client'
import { executionApi } from '@/api/execution'
import type { PlanRunListItem } from '@/api/execution-types'
import { executionDate } from '@/features/execution/format'

interface RunImpact { sessions: number; recorded: number; version: string }

const props = defineProps<{ runs: PlanRunListItem[]; currentRunId: number }>()
const emit = defineEmits<{ close: []; deleted: [runId: number]; cancelled: [runId: number] }>()

const confirming = ref<number | null>(null)
const typedName = ref('')
const impact = ref<RunImpact | null>(null)
const impactLoading = ref(false)
const busy = ref(false)
const error = ref<string | null>(null)
const blockedByWorkout = ref(false)

function closeConfirm(): void {
  confirming.value = null
  typedName.value = ''
  impact.value = null
  error.value = null
  blockedByWorkout.value = false
}

async function startConfirm(run: PlanRunListItem): Promise<void> {
  if (busy.value) return
  if (confirming.value === run.plan_run_id) { closeConfirm(); return }
  closeConfirm()
  confirming.value = run.plan_run_id
  impactLoading.value = true
  try {
    const overview = await executionApi.overview(run.plan_run_id)
    const sessions = overview.microcycles.flatMap((microcycle) => microcycle.sessions)
    impact.value = {
      sessions: sessions.length,
      recorded: sessions.filter((session) => session.status === 'completed').length,
      version: overview.run.version,
    }
  } catch (caught) {
    error.value = caught instanceof Error ? caught.message : null
  } finally {
    impactLoading.value = false
  }
}

function deletable(run: PlanRunListItem): boolean {
  if (busy.value || impactLoading.value || !impact.value) return false
  return impact.value.recorded === 0 || typedName.value.trim() === run.name
}

function reportFailure(caught: unknown): void {
  if (caught instanceof ApiError && caught.code === 'plan_run_session_in_progress') {
    blockedByWorkout.value = true
    error.value = null
    return
  }
  blockedByWorkout.value = false
  error.value = caught instanceof Error ? caught.message : null
}

async function confirmDelete(run: PlanRunListItem): Promise<void> {
  if (!deletable(run)) return
  busy.value = true
  error.value = null
  blockedByWorkout.value = false
  try {
    await executionApi.deleteRun(run.plan_run_id)
    closeConfirm()
    emit('deleted', run.plan_run_id)
  } catch (caught) {
    reportFailure(caught)
  } finally {
    busy.value = false
  }
}

async function cancelRun(run: PlanRunListItem): Promise<void> {
  const current = impact.value
  if (busy.value || !current) return
  busy.value = true
  error.value = null
  blockedByWorkout.value = false
  try {
    await executionApi.updateRun(run.plan_run_id, { status: 'cancelled', expected_version: current.version })
    closeConfirm()
    emit('cancelled', run.plan_run_id)
  } catch (caught) {
    reportFailure(caught)
  } finally {
    busy.value = false
  }
}

function handleKeydown(event: KeyboardEvent): void {
  if (event.key !== 'Escape' || busy.value) return
  if (confirming.value !== null) closeConfirm()
  else emit('close')
}

onMounted(() => window.addEventListener('keydown', handleKeydown))
onBeforeUnmount(() => window.removeEventListener('keydown', handleKeydown))
</script>

<template>
  <div class="exec-modal-backdrop" @click.self="!busy && emit('close')">
    <section class="exec-modal panel" role="dialog" aria-modal="true" aria-labelledby="exec-run-manager-title">
      <header class="exec-modal-head">
        <div>
          <span class="eyebrow">{{ $t('execution.run.eyebrow') }}</span>
          <h2 id="exec-run-manager-title">{{ $t('execution.run.manage.title') }}</h2>
          <p>{{ $t('execution.run.manage.lead') }}</p>
        </div>
        <button class="exec-modal-close" type="button" :aria-label="$t('execution.common.close')" @click="emit('close')">×</button>
      </header>

      <ul class="exec-run-list">
        <li
          v-for="run in props.runs"
          :key="run.plan_run_id"
          class="exec-run-item"
          :class="{ confirming: confirming === run.plan_run_id }"
        >
          <div class="exec-run-row">
            <div class="exec-run-identity">
              <strong>
                {{ run.name }}
                <span v-if="run.plan_run_id === props.currentRunId" class="exec-run-current mono">{{ $t('execution.run.manage.current') }}</span>
              </strong>
              <small>
                <b :class="`run-${run.status}`">● {{ $t(`execution.run.status.${run.status}`) }}</b>
                · {{ run.plan.code }} · {{ run.plan.name }}
                · {{ executionDate(run.starts_on) }} → {{ executionDate(run.ends_on, { day: '2-digit', month: 'short', year: 'numeric' }) }}
              </small>
            </div>
            <button
              class="exec-run-delete"
              type="button"
              :disabled="busy"
              :aria-expanded="confirming === run.plan_run_id"
              :aria-label="$t('execution.run.manage.delete', { name: run.name })"
              :title="$t('execution.run.manage.delete', { name: run.name })"
              @click="startConfirm(run)"
            >🗑</button>
          </div>

          <div v-if="confirming === run.plan_run_id" class="exec-run-confirm">
            <p v-if="impactLoading" class="exec-run-impact">{{ $t('execution.common.loading') }}</p>
            <template v-else-if="impact">
              <p class="exec-run-impact">
                {{ $t('execution.run.manage.impact', { sessions: impact.sessions, recorded: impact.recorded }) }}
                <b v-if="impact.recorded > 0">{{ $t('execution.run.manage.irreversible') }}</b>
              </p>
              <label v-if="impact.recorded > 0" class="exec-run-typed">
                <span>{{ $t('execution.run.manage.typeName', { name: run.name }) }}</span>
                <input v-model="typedName" class="exec-input" type="text" autocomplete="off" :disabled="busy" />
              </label>
              <p v-if="blockedByWorkout" class="exec-run-error">{{ $t('execution.run.manage.inProgress') }}</p>
              <p v-else-if="error" class="exec-run-error">{{ error }}</p>
              <div class="exec-run-confirm-actions">
                <button class="button exec-danger" type="button" :disabled="!deletable(run)" @click="confirmDelete(run)">
                  {{ busy ? $t('execution.run.manage.deleting') : $t('execution.run.manage.confirm') }}
                </button>
                <button v-if="run.status !== 'cancelled'" class="button" type="button" :disabled="busy" @click="cancelRun(run)">
                  {{ $t('execution.run.manage.cancelInstead') }}
                </button>
                <button class="button ghost" type="button" :disabled="busy" @click="closeConfirm">{{ $t('execution.common.cancel') }}</button>
              </div>
            </template>
            <p v-else-if="error" class="exec-run-error">{{ error }}</p>
          </div>
        </li>
      </ul>
    </section>
  </div>
</template>
