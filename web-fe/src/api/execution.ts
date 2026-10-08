import { deleteRequest, getJson, patchJson, postJson, putJson } from './client'
import type {
  AnalysisQueue, CalendarResponse, EventDTO, EventListResponse, ExerciseTraceResponse,
  LoadSeriesResponse, MicrocycleClassification, MicrocycleTimeline, PlanRunListResponse,
  PlanRunOverview, PlanRunPreview, PrescriptionPut, PrescriptionWriteResponse,
  SessionStatus, WorkoutTraceList, WorkoutTraceResponse,
} from './execution-types'

const root = '/api/v1/exec/plan-runs'

export const executionApi = {
  runs: (statuses?: string[], signal?: AbortSignal) => getJson<PlanRunListResponse>(root, { status: statuses }, signal),
  overview: (runId: number, signal?: AbortSignal) => getJson<PlanRunOverview>(`${root}/${runId}/overview`, undefined, signal),
  preview: (params: { plan_revision_id: number; starts_on: string; microcycle_count: number }, signal?: AbortSignal) => getJson<PlanRunPreview>(`${root}/preview`, params, signal),
  createRun: (payload: { plan_revision_id: number; name: string; starts_on: string; microcycle_count: number }, signal?: AbortSignal) => postJson<PlanRunOverview>(root, payload, signal),
  queue: (runId: number, signal?: AbortSignal) => getJson<AnalysisQueue>(`${root}/${runId}/analysis/queue`, undefined, signal),
  exerciseTrace: (runId: number, traceId: number, signal?: AbortSignal) => getJson<ExerciseTraceResponse>(`${root}/${runId}/exercise-traces/${traceId}`, undefined, signal),
  savePrescription: (runId: number, sessionId: number, traceId: number, payload: PrescriptionPut, signal?: AbortSignal) => putJson<PrescriptionWriteResponse>(`${root}/${runId}/sessions/${sessionId}/exercise-prescriptions/${traceId}`, payload, signal),
  deletePrescription: (runId: number, sessionId: number, traceId: number, signal?: AbortSignal) => deleteRequest(`${root}/${runId}/sessions/${sessionId}/exercise-prescriptions/${traceId}`, signal),
  workoutTraces: (runId: number, signal?: AbortSignal) => getJson<WorkoutTraceList>(`${root}/${runId}/workout-traces`, undefined, signal),
  workoutTrace: (runId: number, traceId: number, signal?: AbortSignal) => getJson<WorkoutTraceResponse>(`${root}/${runId}/workout-traces/${traceId}`, undefined, signal),
  timeline: (runId: number, signal?: AbortSignal) => getJson<MicrocycleTimeline>(`${root}/${runId}/microcycles`, undefined, signal),
  updateMicrocycle: (runId: number, ordinal: number, payload: { notes?: string | null; classification?: MicrocycleClassification; expected_version: string }, signal?: AbortSignal) => patchJson<MicrocycleTimeline['microcycles'][number]>(`${root}/${runId}/microcycles/${ordinal}`, payload, signal),
  calendar: (runId: number, signal?: AbortSignal) => getJson<CalendarResponse>(`${root}/${runId}/calendar`, undefined, signal),
  updateSession: (runId: number, sessionId: number, payload: { status: SessionStatus; reason: string | null; log_event: boolean; details?: Record<string, unknown> }, signal?: AbortSignal) => patchJson<{ session_id: number; status: SessionStatus; notes: string | null }>(`${root}/${runId}/sessions/${sessionId}`, payload, signal),
  events: (runId: number, types?: string[], signal?: AbortSignal) => getJson<EventListResponse>(`${root}/${runId}/events`, { type: types }, signal),
  createEvent: (runId: number, payload: { event_type: string; date: string; body: string | null; session_id: number | null; exercise_trace_id: number | null; metadata: Record<string, unknown> }, signal?: AbortSignal) => postJson<EventDTO>(`${root}/${runId}/events`, payload, signal),
  updateEvent: (runId: number, eventId: number, payload: { date?: string; body?: string | null }, signal?: AbortSignal) => patchJson<EventDTO>(`${root}/${runId}/events/${eventId}`, payload, signal),
  deleteEvent: (runId: number, eventId: number, signal?: AbortSignal) => deleteRequest(`${root}/${runId}/events/${eventId}`, signal),
  loadSeries: (runId: number, metric: string, signal?: AbortSignal) => getJson<LoadSeriesResponse>(`${root}/${runId}/load-series`, { metric }, signal),
}
