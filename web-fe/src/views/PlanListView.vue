<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'

import { plansApi } from '@/api/plans'
import type { PlanAIImportDocument } from '@/api/plan-export-types'
import type { PlanDraftArtifact, PlanSummary } from '@/api/plan-types'
import ErrorState from '@/components/common/ErrorState.vue'
import PlanImportDialog from '@/components/plans/PlanImportDialog.vue'
import {
  PLAN_IMPORT_MAX_BYTES,
  PlanImportValidationError,
  parsePlanImportJson,
} from '@/features/plans/import'

const router = useRouter()
const plans = ref<PlanSummary[]>([])
const loading = ref(true)
const error = ref<string | null>(null)
const creating = ref(false)
const createOpen = ref(false)
const name = ref('')
const description = ref('')
const duplicatingPlanId = ref<number | null>(null)
const duplicatedPlan = ref<Pick<PlanDraftArtifact, 'id' | 'name'> | null>(null)
const importInput = ref<HTMLInputElement | null>(null)
const importDocument = ref<PlanAIImportDocument | null>(null)
const importFilename = ref('')
const importing = ref(false)
const importError = ref<string | null>(null)
const importValidationIssues = ref<string[]>([])

async function loadPlans(): Promise<void> {
  loading.value = true
  error.value = null
  try {
    plans.value = (await plansApi.list()).items
  } catch (caught) {
    error.value = caught instanceof Error ? caught.message : 'Plans could not be loaded.'
  } finally {
    loading.value = false
  }
}

async function createPlan(): Promise<void> {
  if (!name.value.trim() || creating.value) return
  creating.value = true
  error.value = null
  try {
    const plan = await plansApi.create({
      name: name.value.trim(),
      description: description.value.trim() || null,
    })
    await router.push({ name: 'plan-editor', params: { planId: plan.id } })
  } catch (caught) {
    error.value = caught instanceof Error ? caught.message : 'The plan could not be created.'
  } finally {
    creating.value = false
  }
}

async function deletePlan(plan: PlanSummary): Promise<void> {
  if (!window.confirm(`Delete “${plan.name}” and its complete draft?`)) return
  try {
    await plansApi.delete(plan.id)
    plans.value = plans.value.filter((item) => item.id !== plan.id)
  } catch (caught) {
    error.value = caught instanceof Error ? caught.message : 'The plan could not be deleted.'
  }
}

async function duplicatePlan(plan: PlanSummary): Promise<void> {
  if (duplicatingPlanId.value !== null) return
  duplicatingPlanId.value = plan.id
  duplicatedPlan.value = null
  error.value = null
  try {
    const duplicate = await plansApi.duplicate(plan.id)
    plans.value = (await plansApi.list()).items
    duplicatedPlan.value = { id: duplicate.id, name: duplicate.name }
  } catch (caught) {
    error.value = caught instanceof Error ? caught.message : 'The plan could not be duplicated.'
  } finally {
    duplicatingPlanId.value = null
  }
}

function chooseImportFile(): void {
  createOpen.value = false
  importValidationIssues.value = []
  importInput.value?.click()
}

async function readImportFile(event: Event): Promise<void> {
  const input = event.currentTarget as HTMLInputElement
  const file = input.files?.[0]
  input.value = ''
  if (!file) return
  importError.value = null
  importValidationIssues.value = []
  if (file.size > PLAN_IMPORT_MAX_BYTES) {
    importValidationIssues.value = ['The JSON file must be 1 MiB or smaller.']
    return
  }
  try {
    importDocument.value = parsePlanImportJson(await file.text())
    importFilename.value = file.name
  } catch (caught) {
    importDocument.value = null
    importValidationIssues.value =
      caught instanceof PlanImportValidationError
        ? caught.issues
        : ['The selected JSON file could not be read.']
  }
}

function closeImport(): void {
  if (importing.value) return
  importDocument.value = null
  importFilename.value = ''
  importError.value = null
}

async function importPlan(): Promise<void> {
  if (!importDocument.value || importing.value) return
  importing.value = true
  importError.value = null
  try {
    const plan = await plansApi.importPlan(importDocument.value)
    await router.push({ name: 'plan-editor', params: { planId: plan.id } })
  } catch (caught) {
    importError.value = caught instanceof Error ? caught.message : 'The plan could not be imported.'
  } finally {
    importing.value = false
  }
}

function updatedLabel(value: string): string {
  return new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeStyle: 'short' }).format(
    new Date(value),
  )
}

onMounted(() => void loadPlans())
</script>

<template>
  <div class="page-wrap plans-index">
    <header class="plans-index-header">
      <div>
        <span class="eyebrow">PlanCreator</span>
        <h1>My Plans</h1>
        <p>Build the stable structure of each training microcycle.</p>
      </div>
      <div class="plans-index-actions">
        <button class="button" type="button" @click="chooseImportFile">Import JSON</button>
        <button class="button primary" type="button" @click="createOpen = !createOpen">
          {{ createOpen ? 'Close' : '+ New plan' }}
        </button>
        <input
          ref="importInput"
          type="file"
          accept="application/json,.json"
          hidden
          @change="readImportFile"
        />
      </div>
    </header>

    <form v-if="createOpen" class="create-plan-panel panel" @submit.prevent="createPlan">
      <div>
        <span class="eyebrow">New draft</span>
        <h2>Create a workout plan</h2>
      </div>
      <label class="field">
        <span class="field-label">Plan name</span>
        <input v-model="name" class="text-input" maxlength="200" placeholder="PPLPP" autofocus />
      </label>
      <label class="field">
        <span class="field-label">Description</span>
        <input v-model="description" class="text-input" placeholder="Optional training intent" />
      </label>
      <button class="button primary" type="submit" :disabled="!name.trim() || creating">
        {{ creating ? 'Creating…' : 'Create and open' }}
      </button>
    </form>

    <div v-if="error && !loading" class="plan-inline-error" role="alert">
      <span>{{ error }}</span>
      <button type="button" @click="error = null">Dismiss</button>
    </div>
    <div v-if="importValidationIssues.length" class="plan-import-errors panel" role="alert">
      <div>
        <strong>The JSON file is not importable.</strong>
        <ul>
          <li v-for="issue in importValidationIssues.slice(0, 8)" :key="issue">{{ issue }}</li>
        </ul>
        <small v-if="importValidationIssues.length > 8">
          And {{ importValidationIssues.length - 8 }} more issues.
        </small>
      </div>
      <button type="button" aria-label="Dismiss import errors" @click="importValidationIssues = []">×</button>
    </div>
    <div v-if="duplicatedPlan" class="plan-inline-success" role="status">
      <span>Created “{{ duplicatedPlan.name }}” as an independent deep copy.</span>
      <RouterLink :to="{ name: 'plan-editor', params: { planId: duplicatedPlan.id } }">
        Open copy →
      </RouterLink>
    </div>

    <div v-if="loading" class="plans-loading panel" aria-label="Loading plans">
      <div v-for="index in 3" :key="index" class="skeleton" />
    </div>
    <ErrorState
      v-else-if="error && !plans.length"
      title="Plans could not be loaded"
      :message="error"
      @retry="loadPlans"
    />
    <div v-else-if="plans.length" class="plan-card-grid">
      <article v-for="plan in plans" :key="plan.id" class="plan-card panel">
        <RouterLink :to="{ name: 'plan-editor', params: { planId: plan.id } }" class="plan-card-link">
          <span class="plan-card-mark mono">P{{ String(plan.id).padStart(3, '0') }}</span>
          <span>
            <strong>{{ plan.name }}</strong>
            <small>{{ plan.description || 'No description' }}</small>
          </span>
          <span class="plan-card-meta mono">
            Draft v{{ plan.draft_lock_version ?? '—' }}<br />{{ updatedLabel(plan.updated_at) }}
          </span>
        </RouterLink>
        <div class="plan-card-actions">
          <button
            class="plan-card-action plan-duplicate"
            type="button"
            :disabled="duplicatingPlanId !== null"
            :aria-label="`Duplicate ${plan.name}`"
            :title="`Duplicate ${plan.name}`"
            @click="duplicatePlan(plan)"
          >
            {{ duplicatingPlanId === plan.id ? '…' : '⧉' }}
          </button>
          <button
            class="plan-card-action plan-delete"
            type="button"
            :disabled="duplicatingPlanId !== null"
            :aria-label="`Delete ${plan.name}`"
            :title="`Delete ${plan.name}`"
            @click="deletePlan(plan)"
          >×</button>
        </div>
      </article>
    </div>
    <div v-else class="new-plan-empty panel">
      <span class="empty-plan-mark mono">PLAN</span>
      <h2>No workout plans yet</h2>
      <p>Create the source artifact that Analysis and Modulation will eventually consume.</p>
      <div class="new-plan-empty-actions">
        <button class="button" type="button" @click="chooseImportFile">Import JSON</button>
        <button class="button primary" type="button" @click="createOpen = true">Create first plan</button>
      </div>
    </div>
    <PlanImportDialog
      v-if="importDocument"
      :document="importDocument"
      :filename="importFilename"
      :importing="importing"
      :error="importError"
      @close="closeImport"
      @confirm="importPlan"
    />
  </div>
</template>
