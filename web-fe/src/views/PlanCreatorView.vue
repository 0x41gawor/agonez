<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { onBeforeRouteLeave } from 'vue-router'

import type { PlanAIExportResult } from '@/api/plan-export-types'
import { plansApi } from '@/api/plans'
import ErrorState from '@/components/common/ErrorState.vue'
import PlanExportDialog from '@/components/plans/PlanExportDialog.vue'
import PlanEditor from '@/components/plans/PlanEditor.vue'
import PlanGuidanceCoach from '@/components/plans/PlanGuidanceCoach.vue'
import PlanAnalysis from '@/components/plans/analysis/PlanAnalysis.vue'
import { usePlanAnalysis } from '@/composables/usePlanAnalysis'
import { usePlanDraft } from '@/composables/usePlanDraft'
import { DEFAULT_PLAN_EXPORT_REQUEST } from '@/features/plans/export'
import { evaluatePlanGuidance, type PlanGuidanceTarget } from '@/features/plans/guidance'
import { useAtlasCatalogStore } from '@/stores/atlasCatalog'
import { useLocaleStore } from '@/stores/locale'

const props = defineProps<{ planId: string }>()
const { t } = useI18n()
const numericPlanId = computed(() => Number(props.planId))
const editor = usePlanDraft(numericPlanId)
const catalog = useAtlasCatalogStore()
const locale = useLocaleStore()
const activeTab = ref<'PLAN' | 'ANALYSIS'>('PLAN')
const analysisVisited = ref(false)
const persistedLockVersion = computed(() => editor.draft.value?.lock_version ?? null)
const analysis = usePlanAnalysis(numericPlanId, persistedLockVersion, editor.dirty)
const exporting = ref(false)
const exportError = ref<string | null>(null)
const exportDocument = ref<PlanAIExportResult | null>(null)
const exportOpen = ref(false)
const guidanceItems = computed(() =>
  editor.draft.value ? evaluatePlanGuidance(editor.draft.value) : [],
)
const initialLoading = computed(() =>
  editor.loading.value || (catalog.loading && catalog.loadedLocale === null),
)
const initialLoadError = computed(() => editor.loadError.value ?? (
  catalog.loadedLocale === null ? catalog.error?.message ?? null : null
))

const saveStatus = computed(() => {
  if (editor.saving.value) return t('plans.creatorView.statuses.saving')
  if (editor.conflict.value) return t('plans.creatorView.statuses.conflict')
  if (editor.saveError.value) return t('plans.creatorView.statuses.failed')
  if (editor.dirty.value) return t('plans.creatorView.statuses.unsaved')
  if (editor.savedAt.value) return t('plans.creatorView.statuses.saved')
  return t('plans.creatorView.statuses.current')
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
      caught instanceof Error ? caught.message : t('plans.creatorView.exportFallbackError')
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
  if (!window.confirm(t('plans.creatorView.confirmReload'))) return
  void editor.reloadLatest()
}

function reviewGuidance(target: PlanGuidanceTarget): void {
  showPlan()
  requestAnimationFrame(() => {
    const element = document.getElementById(`plan-${target}`)
    if (!element) return
    const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    element.scrollIntoView({ behavior: reduceMotion ? 'auto' : 'smooth', block: 'start' })
    element.focus({ preventScroll: true })
  })
}

function loadPage(): void {
  void Promise.all([editor.load(), catalog.load()])
}

onBeforeRouteLeave(() => {
  if (!editor.dirty.value) return true
  return window.confirm(t('plans.creatorView.confirmLeave'))
})

onMounted(() => {
  window.addEventListener('keydown', handleShortcut)
  loadPage()
})
onBeforeUnmount(() => window.removeEventListener('keydown', handleShortcut))

watch(() => locale.current, () => void catalog.load(true))
</script>

<template>
  <div class="plan-creator-page">
    <div class="plan-creator-sticky">
      <div class="plan-creator-toolbar page-wrap">
        <div class="plan-title-cluster">
          <RouterLink class="plan-back" to="/plans" :aria-label="$t('plans.creatorView.back')">←</RouterLink>
          <div>
            <span class="eyebrow">{{ $t('plans.creator') }}</span>
            <h1>{{ editor.draft.value?.name || $t('plans.creatorView.fallbackTitle') }}</h1>
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
            :title="$t('plans.creatorView.exportTitle')"
            @click="exportPlan"
          >
            {{ exporting ? $t('plans.creatorView.preparing') : $t('plans.creatorView.exportJson') }}
          </button>
          <button
            class="button primary save-button"
            type="button"
            :disabled="!editor.draft.value || editor.saving.value || !editor.dirty.value"
            @click="savePlan"
          >
            {{ editor.saving.value ? $t('plans.creatorView.statuses.saving') : $t('plans.creatorView.savePlan') }}
            <span class="save-shortcut mono">Ctrl S</span>
          </button>
        </div>
      </div>
      <nav class="plan-tabs" :aria-label="$t('plans.creatorView.navigation')">
        <button
          type="button"
          :class="{ active: activeTab === 'PLAN' }"
          :aria-current="activeTab === 'PLAN' ? 'page' : undefined"
          @click="showPlan"
        >
          {{ $t('plans.creatorView.planTab') }}
        </button>
        <button
          type="button"
          :class="{ active: activeTab === 'ANALYSIS' }"
          :aria-current="activeTab === 'ANALYSIS' ? 'page' : undefined"
          @click="showAnalysis"
        >
          {{ $t('plans.creatorView.analysisTab') }}
          <small v-if="analysis.stale.value">{{ $t('plans.creatorView.stale') }}</small>
        </button>
        <button type="button" disabled :title="$t('plans.creatorView.modulationPlanned')">
          {{ $t('plans.creatorView.modulationTab') }} <small>{{ $t('plans.creatorView.later') }}</small>
        </button>
      </nav>
    </div>

    <main class="page-wrap plan-creator-content">
      <div v-if="editor.conflict.value" class="conflict-banner" role="alert">
        <div>
          <strong>{{ $t('plans.creatorView.conflictTitle') }}</strong>
          <p>{{ $t('plans.creatorView.conflictBody') }}</p>
        </div>
        <button class="button" type="button" @click="reloadAfterConflict">{{ $t('plans.creatorView.reloadLatest') }}</button>
      </div>
      <div v-else-if="editor.saveError.value" class="plan-inline-error" role="alert">
        <span>{{ editor.saveError.value }}</span>
        <button type="button" @click="editor.saveError.value = null">{{ $t('common.dismiss') }}</button>
      </div>
      <div v-else-if="exportError" class="plan-inline-error" role="alert">
        <span>{{ $t('plans.creatorView.exportFailed', { message: exportError }) }}</span>
        <button type="button" @click="exportError = null">{{ $t('common.dismiss') }}</button>
      </div>

      <div v-if="initialLoading" class="plan-editor-loading" :aria-label="$t('plans.creatorView.loading')">
        <div class="skeleton" />
        <div class="skeleton tall" />
      </div>
      <ErrorState
        v-else-if="initialLoadError"
        :title="$t('plans.creatorView.loadError')"
        :message="initialLoadError"
        @retry="loadPage"
      />
      <template v-else-if="editor.draft.value">
        <PlanEditor
          v-show="activeTab === 'PLAN'"
          v-model="editor.draft.value"
          :exercises="catalog.exercises"
          :muscles="catalog.muscles"
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
          :muscles="catalog.muscles"
          :exercises="catalog.exercises"
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
    <PlanGuidanceCoach
      :active="activeTab === 'PLAN'"
      :items="guidanceItems"
      @review="reviewGuidance"
    />
  </div>
</template>
