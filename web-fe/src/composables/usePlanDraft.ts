import { computed, ref, type Ref } from 'vue'

import { ApiError } from '@/api/client'
import { atlasApi } from '@/api/atlas'
import { plansApi } from '@/api/plans'
import type { ExerciseListItem, MuscleListItem } from '@/api/types'
import {
  toPlanDraftUpdate,
  toPlanEditorState,
  validatePlanEditor,
  type PlanEditorState,
  type PlanValidationIssue,
} from '@/features/plans/editor'

export function usePlanDraft(planId: Ref<number>) {
  const draft = ref<PlanEditorState | null>(null)
  const exercises = ref<ExerciseListItem[]>([])
  const muscles = ref<MuscleListItem[]>([])
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
      const [artifact, exerciseResult, muscleResult] = await Promise.all([
        plansApi.draft(planId.value),
        atlasApi.exercises({ page: 1, per_page: 100, sort: 'name_full', order: 'asc' }),
        atlasApi.muscles({ page: 1, per_page: 100, sort: 'name', order: 'asc' }),
      ])
      exercises.value = exerciseResult.items
      muscles.value = muscleResult.items
      acceptServerDraft(artifact)
    } catch (error) {
      loadError.value = error instanceof Error ? error.message : 'The plan could not be loaded.'
    } finally {
      loading.value = false
    }
  }

  async function save(): Promise<boolean> {
    if (!draft.value || saving.value) return false
    validationIssues.value = validatePlanEditor(draft.value)
    if (validationIssues.value.length) {
      saveError.value = 'Fix the highlighted plan fields before saving.'
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
        saveError.value = 'This plan changed after you loaded it. Your local edits were not overwritten.'
      } else {
        saveError.value = error instanceof Error ? error.message : 'The plan could not be saved.'
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
    exercises,
    muscles,
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
