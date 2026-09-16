import { computed, ref, type Ref } from 'vue'

import { ApiError } from '@/api/client'
import { i18n } from '@/i18n'
import { plansApi } from '@/api/plans'
import {
  toPlanDraftUpdate,
  toPlanEditorState,
  validatePlanEditor,
  type PlanEditorState,
  type PlanValidationIssue,
} from '@/features/plans/editor'

export function usePlanDraft(planId: Ref<number>) {
  const draft = ref<PlanEditorState | null>(null)
  const baseline = ref('')
  const loading = ref(true)
  const saving = ref(false)
  const loadError = ref<string | null>(null)
  const saveError = ref<string | null>(null)
  const conflict = ref(false)
  const savedAt = ref<Date | null>(null)
  const validationIssues = ref<PlanValidationIssue[]>([])

  const serialized = computed(() =>
    draft.value ? JSON.stringify(toPlanDraftUpdate(draft.value)) : '',
  )
  const dirty = computed(() => Boolean(draft.value) && serialized.value !== baseline.value)

  function acceptServerDraft(artifact: Parameters<typeof toPlanEditorState>[0]): void {
    draft.value = toPlanEditorState(artifact)
    baseline.value = JSON.stringify(toPlanDraftUpdate(draft.value))
    validationIssues.value = []
    saveError.value = null
    conflict.value = false
  }

  async function load(): Promise<void> {
    loading.value = true
    loadError.value = null
    try {
      const artifact = await plansApi.draft(planId.value)
      acceptServerDraft(artifact)
    } catch (error) {
      loadError.value = error instanceof Error ? error.message : i18n.global.t('plans.editor.validation.loadFailed')
    } finally {
      loading.value = false
    }
  }

  async function save(): Promise<boolean> {
    if (!draft.value || saving.value) return false
    validationIssues.value = validatePlanEditor(draft.value)
    if (validationIssues.value.length) {
      saveError.value = i18n.global.t('plans.editor.validation.fixFields')
      return false
    }

    saving.value = true
    saveError.value = null
    conflict.value = false
    try {
      const saved = await plansApi.saveDraft(planId.value, toPlanDraftUpdate(draft.value))
      acceptServerDraft(saved)
      savedAt.value = new Date()
      return true
    } catch (error) {
      if (error instanceof ApiError && error.status === 409) {
        conflict.value = true
        saveError.value = i18n.global.t('plans.editor.validation.conflict')
      } else {
        saveError.value = error instanceof Error ? error.message : i18n.global.t('plans.editor.validation.saveFailed')
      }
      return false
    } finally {
      saving.value = false
    }
  }

  async function reloadLatest(): Promise<void> {
    await load()
  }

  function issuesAt(path: string): PlanValidationIssue[] {
    return validationIssues.value.filter((issue) => issue.path === path)
  }

  return {
    draft,
    loading,
    saving,
    loadError,
    saveError,
    conflict,
    savedAt,
    validationIssues,
    dirty,
    load,
    save,
    reloadLatest,
    issuesAt,
  }
}
