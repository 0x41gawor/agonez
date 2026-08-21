<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { onBeforeRouteLeave } from 'vue-router'

import type { PlanAIExportResult } from '@/api/plan-export-types'
import { plansApi } from '@/api/plans'
import ErrorState from '@/components/common/ErrorState.vue'
import PlanExportDialog from '@/components/plans/PlanExportDialog.vue'
import PlanEditor from '@/components/plans/PlanEditor.vue'
import PlanAnalysis from '@/components/plans/analysis/PlanAnalysis.vue'
import { usePlanAnalysis } from '@/composables/usePlanAnalysis'
import { usePlanDraft } from '@/composables/usePlanDraft'
import { DEFAULT_PLAN_EXPORT_REQUEST } from '@/features/plans/export'

const props = defineProps<{ planId: string }>()
const numericPlanId = computed(() => Number(props.planId))
const editor = usePlanDraft(numericPlanId)
const activeTab = ref<'PLAN' | 'ANALYSIS'>('PLAN')
const analysisVisited = ref(false)
const persistedLockVersion = computed(() => editor.draft.value?.lock_version ?? null)
const analysis = usePlanAnalysis(numericPlanId, persistedLockVersion, editor.dirty)
const exporting = ref(false)
const exportError = ref<string | null>(null)
const exportDocument = ref<PlanAIExportResult | null>(null)
const exportOpen = ref(false)

const saveStatus = computed(() => {
  if (editor.saving.value) return 'Saving…'
  if (editor.conflict.value) return 'Conflict'
  if (editor.saveError.value) return 'Save failed'
  if (editor.dirty.value) return 'Unsaved changes'
  if (editor.savedAt.value) return 'Saved'
  return 'Up to date'
})

function handleShortcut(event: KeyboardEvent): void {
  if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 's') {
    event.preventDefault()
    void savePlan()
  }
}

async function savePlan(): Promise<void> {
  const saved = await editor.save()
  if (saved) {
    analysis.markStale()
    exportDocument.value = null
    exportOpen.value = false
  }
}

async function exportPlan(): Promise<void> {
  if (exporting.value || !editor.draft.value) return
  exporting.value = true
  exportError.value = null
  try {
    exportDocument.value = await plansApi.exportDraft(
      numericPlanId.value,
      DEFAULT_PLAN_EXPORT_REQUEST,
    )
    exportOpen.value = true
  } catch (caught) {
    exportError.value =
      caught instanceof Error ? caught.message : 'The saved plan could not be exported.'
  } finally {
    exporting.value = false
  }
}

function showPlan(): void {
  activeTab.value = 'PLAN'
}

function showAnalysis(): void {
  activeTab.value = 'ANALYSIS'
  analysisVisited.value = true
  void analysis.activate()
}

function reloadAfterConflict(): void {
  if (!window.confirm('Reload the latest server draft and discard your unsaved local changes?')) return
  void editor.reloadLatest()
}

onBeforeRouteLeave(() => {
  if (!editor.dirty.value) return true
  return window.confirm('Leave this plan and discard unsaved changes?')
})

onMounted(() => {
  window.addEventListener('keydown', handleShortcut)
  void editor.load()
})
onBeforeUnmount(() => window.removeEventListener('keydown', handleShortcut))
</script>

<template>
  <div class="plan-creator-page">
    <div class="plan-creator-sticky">
      <div class="plan-creator-toolbar page-wrap">
        <div class="plan-title-cluster">
          <RouterLink class="plan-back" to="/plans" aria-label="Back to My Plans">←</RouterLink>
          <div>
            <span class="eyebrow">PlanCreator</span>
            <h1>{{ editor.draft.value?.name || 'Workout plan' }}</h1>
          </div>
        </div>
        <div class="save-cluster">
          <span class="save-state" :class="{ dirty: editor.dirty.value, conflict: editor.conflict.value }">
            <span class="status-dot" />{{ saveStatus }}
          </span>
          <button
            class="button export-plan-button"
            type="button"
            :disabled="!editor.draft.value || exporting"
            title="Export the saved basic plan as AI-friendly JSON"
            @click="exportPlan"
          >
            {{ exporting ? 'Preparing…' : 'Export JSON' }}
          </button>
          <button
            class="button primary save-button"
            type="button"
            :disabled="!editor.draft.value || editor.saving.value || !editor.dirty.value"
            @click="savePlan"
          >
            {{ editor.saving.value ? 'Saving…' : 'Save plan' }}
            <span class="save-shortcut mono">Ctrl S</span>
          </button>
        </div>
      </div>
      <nav class="plan-tabs" aria-label="PlanCreator sections">
        <button
          type="button"
          :class="{ active: activeTab === 'PLAN' }"
          :aria-current="activeTab === 'PLAN' ? 'page' : undefined"
          @click="showPlan"
        >
          PLAN
        </button>
        <button
          type="button"
          :class="{ active: activeTab === 'ANALYSIS' }"
          :aria-current="activeTab === 'ANALYSIS' ? 'page' : undefined"
          @click="showAnalysis"
        >
          ANALYSIS
          <small v-if="analysis.stale.value">Stale</small>
        </button>
        <button type="button" disabled title="Planned for the next PlanCreator stage">
          MODULATION <small>Later</small>
        </button>
      </nav>
    </div>

    <main class="page-wrap plan-creator-content">
      <div v-if="editor.conflict.value" class="conflict-banner" role="alert">
        <div>
          <strong>A newer draft exists on the server.</strong>
          <p>Your local edits are still here and were not overwritten. Reload only when you are ready to discard them.</p>
        </div>
        <button class="button" type="button" @click="reloadAfterConflict">Reload latest draft</button>
      </div>
      <div v-else-if="editor.saveError.value" class="plan-inline-error" role="alert">
        <span>{{ editor.saveError.value }}</span>
        <button type="button" @click="editor.saveError.value = null">Dismiss</button>
      </div>
      <div v-else-if="exportError" class="plan-inline-error" role="alert">
        <span>Plan export failed: {{ exportError }}</span>
        <button type="button" @click="exportError = null">Dismiss</button>
      </div>

      <div v-if="editor.loading.value" class="plan-editor-loading" aria-label="Loading plan editor">
        <div class="skeleton" />
        <div class="skeleton tall" />
      </div>
      <ErrorState
        v-else-if="editor.loadError.value"
        title="The plan could not be loaded"
        :message="editor.loadError.value"
        @retry="editor.load"
      />
      <template v-else-if="editor.draft.value">
        <PlanEditor
          v-show="activeTab === 'PLAN'"
          v-model="editor.draft.value"
          :exercises="editor.exercises.value"
          :muscles="editor.muscles.value"
          :issues="editor.validationIssues.value"
        />
        <PlanAnalysis
          v-if="analysisVisited"
          v-show="activeTab === 'ANALYSIS'"
          v-model:phase="analysis.selectedPhase.value"
          v-model:etu-mode="analysis.etuMode.value"
          v-model:etu-time-basis="analysis.etuTimeBasis.value"
          :result="analysis.result.value"
          :loading="analysis.loading.value"
          :error="analysis.error.value"
          :stale="analysis.stale.value"
          :dirty="editor.dirty.value"
          :lock-mismatch="analysis.lockVersionMismatch.value"
          :selected-day="analysis.selectedDay.value"
          :selected-day-id="analysis.selectedDayId.value"
          :muscle-contributions-by-slug="analysis.muscleContributionsBySlug.value"
          :joint-contributions-by-slug="analysis.jointContributionsBySlug.value"
          :muscles="editor.muscles.value"
          :exercises="editor.exercises.value"
          @refresh="analysis.refresh"
          @save="savePlan"
          @show-plan="showPlan"
          @select-day="analysis.selectDay"
        />
      </template>
    </main>
    <PlanExportDialog
      v-if="exportOpen && exportDocument"
      :document="exportDocument"
      :editor-dirty="editor.dirty.value"
      @close="exportOpen = false"
    />
  </div>
</template>
