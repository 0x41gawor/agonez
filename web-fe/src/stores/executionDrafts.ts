import { computed, reactive } from 'vue'
import { defineStore } from 'pinia'

import type { NextPrescription } from '@/api/execution-types'

export interface PrescriptionDraft {
  traceId: number
  loads: string[]
  comments: string[]
  prescriptionComment: string
  selected: boolean[]
  dirty: boolean
  savedVersion: string | null
}

function value(load: number | null): string {
  return load == null ? '' : String(load)
}

export const useExecutionDraftsStore = defineStore('execution-drafts', () => {
  const drafts = reactive<Record<number, PrescriptionDraft>>({})
  const hasDirty = computed(() => Object.values(drafts).some((draft) => draft.dirty))

  function initialize(traceId: number, next: NextPrescription, force = false): PrescriptionDraft {
    const existing = drafts[traceId]
    if (existing && !force) return existing
    const loads = next.prescription?.sets.map((set) => set.load_kg)
      ?? next.defaults.from_previous_prescription
    const comments = next.prescription?.sets.map((set) => set.comment ?? '')
      ?? next.plan_sets.map(() => '')
    const draft: PrescriptionDraft = {
      traceId,
      loads: next.plan_sets.map((_, index) => value(loads[index] ?? null)),
      comments: next.plan_sets.map((_, index) => comments[index] ?? ''),
      prescriptionComment: next.prescription?.prescription_comment ?? '',
      selected: next.plan_sets.map(() => false),
      dirty: false,
      savedVersion: next.prescription?.version ?? null,
    }
    drafts[traceId] = draft
    return draft
  }

  function markDirty(traceId: number): void {
    if (drafts[traceId]) drafts[traceId].dirty = true
  }

  function clear(traceId: number): void {
    delete drafts[traceId]
  }

  return { drafts, hasDirty, initialize, markDirty, clear }
})
