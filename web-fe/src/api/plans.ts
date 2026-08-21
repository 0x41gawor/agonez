import { deleteRequest, getJson, postJson, putJson } from './client'
import type {
  PlanCreate,
  PlanDetail,
  PlanDraftArtifact,
  PlanDraftUpdate,
  PlanListResponse,
} from './plan-types'
import type { PlanAnalysisRequest, PlanAnalysisResult } from './plan-analysis-types'
import type { PlanAIExportResult, PlanExportRequest } from './plan-export-types'

export const plansApi = {
  list: (signal?: AbortSignal) => getJson<PlanListResponse>('/api/plans', undefined, signal),
  create: (payload: PlanCreate, signal?: AbortSignal) =>
    postJson<PlanDraftArtifact>('/api/plans', payload, signal),
  duplicate: (planId: number, signal?: AbortSignal) =>
    postJson<PlanDraftArtifact>(`/api/plans/${planId}/duplicate`, {}, signal),
  detail: (planId: number, signal?: AbortSignal) =>
    getJson<PlanDetail>(`/api/plans/${planId}`, undefined, signal),
  draft: (planId: number, signal?: AbortSignal) =>
    getJson<PlanDraftArtifact>(`/api/plans/${planId}/draft`, undefined, signal),
  saveDraft: (planId: number, payload: PlanDraftUpdate, signal?: AbortSignal) =>
    putJson<PlanDraftArtifact>(`/api/plans/${planId}/draft`, payload, signal),
  analyzeDraft: (planId: number, payload: PlanAnalysisRequest, signal?: AbortSignal) =>
    postJson<PlanAnalysisResult>(`/api/plans/${planId}/draft/analysis`, payload, signal),
  exportDraft: (planId: number, payload: PlanExportRequest, signal?: AbortSignal) =>
    postJson<PlanAIExportResult>(`/api/plans/${planId}/draft/export`, payload, signal),
  delete: (planId: number, signal?: AbortSignal) =>
    deleteRequest(`/api/plans/${planId}`, signal),
}
