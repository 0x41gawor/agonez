import { getJson, postJson } from './client'
import type {
  AtlasMeta,
  ExerciseDetail,
  ExerciseListQuery,
  ExerciseListResponse,
  ExerciseVideoLinks,
  MuscleDetail,
  MuscleListQuery,
  MuscleListResponse,
  QueryRecord,
  RelatedExerciseResponse,
} from './types'

export const atlasApi = {
  meta: (signal?: AbortSignal) => getJson<AtlasMeta>('/api/atlas/meta', undefined, signal),
  exercises: (query: ExerciseListQuery, signal?: AbortSignal) =>
    getJson<ExerciseListResponse>('/api/atlas/exercises', query as QueryRecord, signal),
  exercise: (slug: string, signal?: AbortSignal) =>
    getJson<ExerciseDetail>(`/api/atlas/exercises/${encodeURIComponent(slug)}`, undefined, signal),
  addExerciseVideo: (slug: string, url: string, signal?: AbortSignal) =>
    postJson<ExerciseVideoLinks>(
      `/api/atlas/exercises/${encodeURIComponent(slug)}/videos`,
      { url },
      signal,
    ),
  muscles: (query: MuscleListQuery, signal?: AbortSignal) =>
    getJson<MuscleListResponse>('/api/atlas/muscles', query as QueryRecord, signal),
  muscle: (slug: string, signal?: AbortSignal) =>
    getJson<MuscleDetail>(`/api/atlas/muscles/${encodeURIComponent(slug)}`, undefined, signal),
  relatedExercises: (slug: string, signal?: AbortSignal) =>
    getJson<RelatedExerciseResponse>(
      `/api/atlas/muscles/${encodeURIComponent(slug)}/exercises`,
      { limit: 8, sort: 'etu' },
      signal,
    ),
}
