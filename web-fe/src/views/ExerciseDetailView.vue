<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, ref, watch } from 'vue'
import { useRouter } from 'vue-router'

import { atlasApi } from '@/api/atlas'
import { ApiError } from '@/api/client'
import type { ExerciseDetail, Vector } from '@/api/types'
import BodyViewer from '@/components/anatomy/BodyViewer.vue'
import ErrorState from '@/components/common/ErrorState.vue'
import DataGroup from '@/components/detail/DataGroup.vue'
import DetailHero from '@/components/detail/DetailHero.vue'
import DetailLoading from '@/components/detail/DetailLoading.vue'
import ObjectDataCard from '@/components/detail/ObjectDataCard.vue'
import { useAtlasStore } from '@/stores/atlas'
import { domainLabel, formatNumber, prettyToken } from '@/utils/format'
import { exerciseVector, normalizeVector, type VisualizationMode } from '@/utils/vectors'
import { youtubeEmbedUrl } from '@/utils/youtube'

const props = defineProps<{ slug: string }>()
const router = useRouter()
const atlas = useAtlasStore()
const exercise = ref<ExerciseDetail | null>(null)
const loading = ref(true)
const error = ref<Error | null>(null)
const mode = ref<VisualizationMode>('etu')
const showJoints = ref(false)
const hoverSlug = ref<string | null>(null)
const addingVideo = ref(false)
const videoUrl = ref('')
const videoSaving = ref(false)
const videoError = ref('')
const videoInput = ref<HTMLInputElement | null>(null)
let controller: AbortController | null = null

async function load(): Promise<void> {
  controller?.abort()
  controller = new AbortController()
  loading.value = true
  error.value = null
  addingVideo.value = false
  videoUrl.value = ''
  videoError.value = ''
  try {
    const [detail] = await Promise.all([
      atlasApi.exercise(props.slug, controller.signal),
      atlas.loadCapacities(),
    ])
    exercise.value = detail
    mode.value = detail.engine?.etu_vector ? 'etu' : detail.propulsive_fcsa_contribution_vector ? 'propulsive' : 'etu'
  } catch (caught) {
    if ((caught as Error).name !== 'AbortError') error.value = caught instanceof Error ? caught : new Error('Exercise data is unavailable.')
  } finally {
    if (!controller.signal.aborted) loading.value = false
  }
}

watch(() => props.slug, () => void load(), { immediate: true })
onBeforeUnmount(() => controller?.abort())

const notFound = computed(() => error.value instanceof ApiError && error.value.status === 404)
const rawVector = computed<Vector | null>(() => exercise.value ? exerciseVector(exercise.value, mode.value) : null)
const normalizedVector = computed(() => rawVector.value ? normalizeVector(rawVector.value, atlas.capacities) : null)
const jointVector = computed(() => exercise.value?.engine?.joint_load_exposure_vector ?? null)
const hasEtu = computed(() => Boolean(exercise.value?.engine?.etu_vector))
const hasRecovery = computed(() => Boolean(exercise.value?.engine?.active_tension_exposure_vector && exercise.value?.engine?.muscle_recovery_cost_modifier_vector))
const vectorRows = computed(() => Object.entries(rawVector.value ?? {}).sort((a, b) => b[1] - a[1]).map(([slug, raw]) => {
  const capacity = atlas.capacities[slug]
  return { slug, raw, capacityRatio: capacity && capacity > 0 ? raw / capacity : null, intensity: normalizedVector.value?.[slug] ?? 0 }
}))
const videos = computed(() => (exercise.value?.video_links ?? []).map((link) => ({
  link,
  embedUrl: youtubeEmbedUrl(link),
})))
const jointRows = computed(() => Object.entries(jointVector.value ?? {}).sort((a, b) => b[1] - a[1]))
const totalEtu = computed(() => Object.values(exercise.value?.engine?.etu_vector ?? {}).reduce((sum, value) => sum + value, 0))
const peakJoint = computed(() => jointRows.value[0]?.[0] ?? '—')
const vectorTitle = computed(() => mode.value === 'recovery' ? 'Muscle recovery exposure' : mode.value === 'propulsive' ? 'Propulsive FCSA contribution' : 'Muscle ETU exposure')
const vectorSubtitle = computed(() => mode.value === 'recovery' ? 'active tension × recovery cost modifier' : mode.value === 'propulsive' ? 'from core schema · engine vectors pending' : 'effective training units per muscle')
const vectorColor = computed(() => mode.value === 'recovery' ? 'var(--rec)' : mode.value === 'propulsive' ? 'var(--accent)' : 'var(--etu)')
const groups = computed(() => exercise.value ? [
  { title: 'Classification', rows: [
    { label: 'Body part', value: exercise.value.body_part },
    { label: 'Target category', value: prettyToken(exercise.value.target_category) },
    { label: 'Mechanics tier', value: prettyToken(exercise.value.mechanics_tier) },
    { label: 'Resistance source', value: prettyToken(exercise.value.resistance_source) },
    { label: 'Execution pattern', value: prettyToken(exercise.value.execution_pattern) },
  ] },
  { title: 'Quantitative', rows: [
    { label: 'Load capacity', value: formatNumber(exercise.value.load_capacity, 0), unit: 'kg' },
    { label: 'Systemic FCSA demand', value: formatNumber(exercise.value.systemic_propulsive_fcsa_demand), unit: 'cm²' },
    { label: 'Total ETU', value: hasEtu.value ? formatNumber(totalEtu.value) : 'pending', unit: hasEtu.value ? 'cm²' : '' },
    { label: 'Muscles exposed', value: String(Object.keys(exercise.value.engine?.active_tension_exposure_vector ?? exercise.value.propulsive_fcsa_contribution_vector).length) },
  ] },
] : [])

function selectMuscle(slug: string): void {
  if (slug in atlas.capacities) void router.push({ name: 'muscle-detail', params: { slug } })
}

async function openVideoForm(): Promise<void> {
  addingVideo.value = true
  videoError.value = ''
  await nextTick()
  videoInput.value?.focus()
}

function closeVideoForm(): void {
  addingVideo.value = false
  videoUrl.value = ''
  videoError.value = ''
}

async function saveVideo(): Promise<void> {
  const url = videoUrl.value.trim()
  if (!url || !exercise.value) return
  videoSaving.value = true
  videoError.value = ''
  try {
    const response = await atlasApi.addExerciseVideo(exercise.value.slug, url)
    exercise.value.video_links = response.video_links
    closeVideoForm()
  } catch (caught) {
    videoError.value = caught instanceof ApiError && caught.status === 422
      ? 'Paste a valid YouTube video link.'
      : caught instanceof Error ? caught.message : 'The video could not be saved.'
  } finally {
    videoSaving.value = false
  }
}
</script>

<template>
  <div class="page-wrap detail-page exercise-detail-page">
    <nav class="breadcrumbs" aria-label="Breadcrumb">
      <RouterLink to="/atlas/exercises">Atlas</RouterLink><span>/</span>
      <RouterLink to="/atlas/exercises">Exercises</RouterLink><span>/</span>
      <span>{{ exercise?.name ?? prettyToken(slug) }}</span>
    </nav>

    <DetailLoading v-if="loading" />
    <section v-else-if="notFound" class="state-page compact">
      <span class="eyebrow">404 · Exercise</span><h1>Exercise not found</h1>
      <p>No exercise with slug “{{ slug }}” exists in the current Atlas.</p>
      <RouterLink class="button" to="/atlas/exercises">Browse exercises</RouterLink>
    </section>
    <ErrorState v-else-if="error" :message="error.message" @retry="load" />

    <template v-else-if="exercise">
      <DetailHero
        :image-url="exercise.image_url"
        :title="exercise.name"
        :subtitle="exercise.name_full"
        :slug="exercise.slug"
        :chips="[`${exercise.body_part} body`, prettyToken(exercise.target_category), prettyToken(exercise.mechanics_tier), prettyToken(exercise.resistance_source), prettyToken(exercise.execution_pattern)]"
        :stats="[
          { label: 'Load capacity', value: formatNumber(exercise.load_capacity, 0), unit: 'kg' },
          { label: 'Systemic FCSA demand', value: formatNumber(exercise.systemic_propulsive_fcsa_demand), unit: 'cm²' },
          ...(hasEtu ? [{ label: 'Total ETU', value: formatNumber(totalEtu), unit: 'cm²' }, { label: 'Peak joint exposure', value: prettyToken(peakJoint) }] : []),
        ]"
      />

      <div class="exercise-viz-grid">
        <section class="viz-panel panel">
          <header class="viz-controls">
            <div v-if="hasEtu || hasRecovery" class="mode-control">
              <button type="button" :class="{ active: mode === 'etu' }" :disabled="!hasEtu" @click="mode = 'etu'">ETU</button>
              <button type="button" :class="{ active: mode === 'recovery' }" :disabled="!hasRecovery" @click="mode = 'recovery'">Recovery</button>
            </div>
            <label v-if="jointVector"><input v-model="showJoints" type="checkbox" /> Joint load</label>
            <span class="mono">normalized / proj. FCSA</span>
          </header>
          <div v-if="rawVector && Object.keys(rawVector).length" class="viz-body">
            <BodyViewer
              :selected-slug="hoverSlug"
              :vector="normalizedVector"
              :mode="mode"
              :joints="jointVector"
              :show-joints="showJoints"
              @hover="hoverSlug = $event"
              @select="selectMuscle"
            />
          </div>
          <div v-else class="engine-pending">
            <strong>Engine vectors pending</strong>
            <p>ETU, recovery and joint-load exposure have not been evaluated for this exercise yet.</p>
          </div>
          <footer v-if="rawVector && Object.keys(rawVector).length">
            <div class="viz-legend"><strong>{{ vectorTitle }}</strong><span :style="{ background: `linear-gradient(to right, var(--anatMuscle), ${vectorColor})` }" /><small class="mono">0 → max</small></div>
            <div v-if="showJoints" class="joint-legend"><strong>Joint load</strong><i /><span class="mono">ring weight ∝ exposure index</span></div>
            <p>Hover the body or table — both stay in sync. Near-zero values recede into neutral anatomy.</p>
          </footer>
        </section>

        <div class="exercise-data-column">
          <section v-if="vectorRows.length" class="vector-panel panel">
            <header><h2>{{ vectorTitle }}</h2><span class="mono">{{ vectorSubtitle }}</span></header>
            <div class="vector-head"><span>Muscle</span><span>Raw cm²</span><span>/ capacity</span><span>Relative intensity</span></div>
            <button
              v-for="row in vectorRows"
              :key="row.slug"
              class="vector-row"
              :class="{ hovered: hoverSlug === row.slug }"
              type="button"
              @mouseenter="hoverSlug = row.slug"
              @mouseleave="hoverSlug = null"
              @focus="hoverSlug = row.slug"
              @blur="hoverSlug = null"
              @click="selectMuscle(row.slug)"
            >
              <span>{{ prettyToken(row.slug) }}</span><span class="mono">{{ formatNumber(row.raw) }}</span><span class="mono">{{ row.capacityRatio == null ? '—' : `${(row.capacityRatio * 100).toFixed(1)}%` }}</span>
              <i><b :style="{ width: `${row.intensity * 100}%`, background: vectorColor }" /></i>
            </button>
          </section>

          <section v-if="showJoints && jointRows.length" class="joint-panel panel">
            <header><h2>Joint load exposure</h2><span class="mono">model-derived index · not a safety score</span></header>
            <div v-for="[joint, value] in jointRows" :key="joint" class="joint-row"><span>{{ prettyToken(joint) }}</span><span class="mono">{{ value.toFixed(2) }}</span><i><b :style="{ width: `${Math.min(100, value * 100)}%` }" /></i></div>
          </section>

          <div class="data-groups exercise-groups"><DataGroup v-for="group in groups" :key="group.title" :title="group.title" :rows="group.rows" /></div>
          <div class="object-columns">
            <ObjectDataCard title="Technique" :data="exercise.technique" empty-message="Canonical execution instructions have not been authored for this exercise yet." />
            <ObjectDataCard title="Comments" :data="exercise.comments" empty-message="No contextual comments or caveats are stored yet — kept separate from canonical technique." />
          </div>
          <section class="media-section panel">
            <header>
              <h2>Demonstration videos</h2>
              <button
                v-if="!addingVideo"
                class="media-add-button"
                type="button"
                aria-label="Add a demonstration video"
                @click="openVideoForm"
              ><span aria-hidden="true">+</span> Add video</button>
            </header>
            <form v-if="addingVideo" class="video-add-form" @submit.prevent="saveVideo">
              <label for="exercise-video-url">YouTube link</label>
              <input
                id="exercise-video-url"
                ref="videoInput"
                v-model="videoUrl"
                type="url"
                inputmode="url"
                autocomplete="url"
                placeholder="Paste a YouTube link"
                required
              />
              <button class="button primary" type="submit" :disabled="videoSaving || !videoUrl.trim()">
                {{ videoSaving ? 'Saving…' : 'Save' }}
              </button>
              <button class="button ghost" type="button" :disabled="videoSaving" @click="closeVideoForm">Cancel</button>
              <p v-if="videoError" role="alert">{{ videoError }}</p>
            </form>
            <div v-if="videos.length" class="video-grid">
              <article v-for="(video, index) in videos" :key="video.link" class="video-card">
                <div v-if="video.embedUrl" class="video-frame">
                  <iframe
                    :src="video.embedUrl"
                    :title="`${exercise.name} demonstration video ${index + 1}`"
                    loading="lazy"
                    referrerpolicy="strict-origin-when-cross-origin"
                    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                    allowfullscreen
                  />
                </div>
                <a :href="video.link" target="_blank" rel="noopener noreferrer">
                  <span>{{ video.embedUrl ? 'Watch on YouTube' : domainLabel(video.link) }}</span><b>↗</b>
                </a>
              </article>
            </div>
            <p v-else class="honest-empty">No video links stored for this exercise yet.</p>
          </section>
        </div>
      </div>
    </template>
  </div>
</template>
