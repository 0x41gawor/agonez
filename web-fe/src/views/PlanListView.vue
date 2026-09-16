<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
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
import { formatDateTime } from '@/utils/format'

const router = useRouter()
const { t } = useI18n()
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
    error.value = caught instanceof Error ? caught.message : t('plans.list.loadFailed')
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
    error.value = caught instanceof Error ? caught.message : t('plans.list.createFailed')
  } finally {
    creating.value = false
  }
}

async function deletePlan(plan: PlanSummary): Promise<void> {
  if (!window.confirm(t('plans.list.confirmDelete', { name: plan.name }))) return
  try {
    await plansApi.delete(plan.id)
    plans.value = plans.value.filter((item) => item.id !== plan.id)
  } catch (caught) {
    error.value = caught instanceof Error ? caught.message : t('plans.list.deleteFailed')
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
    error.value = caught instanceof Error ? caught.message : t('plans.list.duplicateFailed')
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
    importValidationIssues.value = [t('plans.list.fileTooLarge')]
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
        : [t('plans.list.fileUnreadable')]
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
    importError.value = caught instanceof Error ? caught.message : t('plans.list.importFailed')
  } finally {
    importing.value = false
  }
}

function updatedLabel(value: string): string {
  return formatDateTime(value)
}

onMounted(() => void loadPlans())
</script>

<template>
  <div class="page-wrap plans-index">
    <header class="plans-index-header">
      <div>
        <span class="eyebrow">{{ $t('plans.creator') }}</span>
        <h1>{{ $t('plans.title') }}</h1>
        <p>{{ $t('plans.list.subtitle') }}</p>
      </div>
      <div class="plans-index-actions">
        <button class="button" type="button" @click="chooseImportFile">{{ $t('plans.list.importJson') }}</button>
        <button class="button primary" type="button" @click="createOpen = !createOpen">
          {{ createOpen ? $t('common.close') : $t('plans.list.newPlan') }}
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
        <span class="eyebrow">{{ $t('plans.list.newDraft') }}</span>
        <h2>{{ $t('plans.list.createTitle') }}</h2>
      </div>
      <label class="field">
        <span class="field-label">{{ $t('plans.list.planName') }}</span>
        <input v-model="name" class="text-input" maxlength="200" placeholder="PPLPP" autofocus />
      </label>
      <label class="field">
        <span class="field-label">{{ $t('plans.list.description') }}</span>
        <input v-model="description" class="text-input" :placeholder="$t('plans.list.descriptionPlaceholder')" />
      </label>
      <button class="button primary" type="submit" :disabled="!name.trim() || creating">
        {{ creating ? $t('plans.list.creating') : $t('plans.list.createAndOpen') }}
      </button>
    </form>

    <div v-if="error && !loading" class="plan-inline-error" role="alert">
      <span>{{ error }}</span>
      <button type="button" @click="error = null">{{ $t('common.dismiss') }}</button>
    </div>
    <div v-if="importValidationIssues.length" class="plan-import-errors panel" role="alert">
      <div>
        <strong>{{ $t('plans.list.importInvalid') }}</strong>
        <ul>
          <li v-for="issue in importValidationIssues.slice(0, 8)" :key="issue">{{ issue }}</li>
        </ul>
        <small v-if="importValidationIssues.length > 8">
          {{ $t('plans.list.moreIssues', { count: importValidationIssues.length - 8 }) }}
        </small>
      </div>
      <button type="button" :aria-label="$t('plans.list.dismissImportErrors')" @click="importValidationIssues = []">×</button>
    </div>
    <div v-if="duplicatedPlan" class="plan-inline-success" role="status">
      <span>{{ $t('plans.list.duplicateCreated', { name: duplicatedPlan.name }) }}</span>
      <RouterLink :to="{ name: 'plan-editor', params: { planId: duplicatedPlan.id } }">
        {{ $t('plans.list.openCopy') }}
      </RouterLink>
    </div>

    <div v-if="loading" class="plans-loading panel" :aria-label="$t('plans.list.loading')">
      <div v-for="index in 3" :key="index" class="skeleton" />
    </div>
    <ErrorState
      v-else-if="error && !plans.length"
      :title="$t('plans.list.loadError')"
      :message="error"
      @retry="loadPlans"
    />
    <div v-else-if="plans.length" class="plan-card-grid">
      <article v-for="plan in plans" :key="plan.id" class="plan-card panel">
        <RouterLink :to="{ name: 'plan-editor', params: { planId: plan.id } }" class="plan-card-link">
          <span class="plan-card-mark mono">P{{ String(plan.id).padStart(3, '0') }}</span>
          <span>
            <strong>{{ plan.name }}</strong>
            <small>{{ plan.description || $t('common.noDescription') }}</small>
          </span>
          <span class="plan-card-meta mono">
            {{ $t('plans.list.draftVersion', { version: plan.draft_lock_version ?? '—' }) }}<br />{{ updatedLabel(plan.updated_at) }}
          </span>
        </RouterLink>
        <div class="plan-card-actions">
          <button
            class="plan-card-action plan-duplicate"
            type="button"
            :disabled="duplicatingPlanId !== null"
            :aria-label="$t('plans.list.duplicate', { name: plan.name })"
            :title="$t('plans.list.duplicate', { name: plan.name })"
            @click="duplicatePlan(plan)"
          >
            {{ duplicatingPlanId === plan.id ? '…' : '⧉' }}
          </button>
          <button
            class="plan-card-action plan-delete"
            type="button"
            :disabled="duplicatingPlanId !== null"
            :aria-label="$t('plans.list.delete', { name: plan.name })"
            :title="$t('plans.list.delete', { name: plan.name })"
            @click="deletePlan(plan)"
          >×</button>
        </div>
      </article>
    </div>
    <div v-else class="new-plan-empty panel">
      <span class="empty-plan-mark mono">PLAN</span>
      <h2>{{ $t('plans.list.emptyTitle') }}</h2>
      <p>{{ $t('plans.list.emptyMessage') }}</p>
      <div class="new-plan-empty-actions">
        <button class="button" type="button" @click="chooseImportFile">{{ $t('plans.list.importJson') }}</button>
        <button class="button primary" type="button" @click="createOpen = true">{{ $t('plans.list.createFirst') }}</button>
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
