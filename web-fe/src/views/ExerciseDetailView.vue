<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'

import { atlasApi } from '@/api/atlas'
import { ApiError } from '@/api/client'
import type { ExerciseDetail, RepRange, Vector } from '@/api/types'
import BodyViewer from '@/components/anatomy/BodyViewer.vue'
import ErrorState from '@/components/common/ErrorState.vue'
import DataGroup from '@/components/detail/DataGroup.vue'
import DetailHero from '@/components/detail/DetailHero.vue'
import DetailLoading from '@/components/detail/DetailLoading.vue'
import ObjectDataCard from '@/components/detail/ObjectDataCard.vue'
import TechniqueGuide from '@/components/detail/TechniqueGuide.vue'
import { useAtlasStore } from '@/stores/atlas'
import { useLocaleStore } from '@/stores/locale'
import { domainLabel, formatNumber, prettyToken } from '@/utils/format'
import { exerciseVector, normalizeVector, type VisualizationMode } from '@/utils/vectors'
import { youtubeEmbedUrl } from '@/utils/youtube'

const props = defineProps<{ slug: string }>()
const router = useRouter()
const atlas = useAtlasStore()
const locale = useLocaleStore()
const { t } = useI18n()
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
    if ((caught as Error).name !== 'AbortError') error.value = caught instanceof Error ? caught : new Error(t('atlas.detail.exerciseUnavailable'))
  } finally {
    if (!controller.signal.aborted) loading.value = false
  }
}

watch(() => [props.slug, locale.current], () => void load(), { immediate: true })
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
const vectorTitle = computed(() => t(mode.value === 'recovery' ? 'atlas.detail.muscleRecoveryExposure' : mode.value === 'propulsive' ? 'atlas.detail.propulsiveFcsa' : 'atlas.detail.muscleEtu'))
const vectorSubtitle = computed(() => t(mode.value === 'recovery' ? 'atlas.detail.recoverySubtitle' : mode.value === 'propulsive' ? 'atlas.detail.propulsiveSubtitle' : 'atlas.detail.etuSubtitle'))
const vectorColor = computed(() => mode.value === 'recovery' ? 'var(--rec)' : mode.value === 'propulsive' ? 'var(--accent)' : 'var(--etu)')
function formatRecommendedRange(range: RepRange | null): string {
  return range ? t('atlas.detail.reps', { min: range.min, max: range.max }) : t('atlas.detail.notRecommended')
}
const groups = computed(() => exercise.value ? [
  { title: t('atlas.detail.classification'), rows: [
    { label: t('atlas.detail.bodyPart'), value: exercise.value.body_part },
    { label: t('atlas.detail.targetCategory'), value: prettyToken(exercise.value.target_category) },
    { label: t('atlas.detail.mechanicsTier'), value: prettyToken(exercise.value.mechanics_tier) },
    { label: t('atlas.detail.resistanceSource'), value: prettyToken(exercise.value.resistance_source) },
    { label: t('atlas.detail.executionPattern'), value: prettyToken(exercise.value.execution_pattern) },
  ] },
  { title: t('atlas.detail.recommendedRanges'), rows: [
    { label: t('atlas.detail.highLoad'), value: formatRecommendedRange(exercise.value.recommended_rep_profile.high_load) },
    { label: t('atlas.detail.moderateLoad'), value: formatRecommendedRange(exercise.value.recommended_rep_profile.moderate_load) },
    { label: t('atlas.detail.lowLoad'), value: formatRecommendedRange(exercise.value.recommended_rep_profile.low_load) },
  ] },
  { title: t('atlas.detail.quantitative'), rows: [
    { label: t('atlas.loadCapacity'), value: formatNumber(exercise.value.load_capacity, 0), unit: 'kg' },
    { label: t('atlas.detail.systemicFcsa'), value: formatNumber(exercise.value.systemic_propulsive_fcsa_demand), unit: 'cm²' },
    { label: t('atlas.detail.totalEtu'), value: hasEtu.value ? formatNumber(totalEtu.value) : t('atlas.detail.pending'), unit: hasEtu.value ? 'cm²' : '' },
    { label: t('atlas.detail.musclesExposed'), value: String(Object.keys(exercise.value.engine?.active_tension_exposure_vector ?? exercise.value.propulsive_fcsa_contribution_vector ?? {}).length) },
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
      ? t('atlas.detail.invalidYoutube')
      : caught instanceof Error ? caught.message : t('atlas.detail.videoSaveFailed')
  } finally {
    videoSaving.value = false
  }
}
</script>

<template>
  <div class="page-wrap detail-page exercise-detail-page">
    <nav class="breadcrumbs" :aria-label="$t('atlas.detail.breadcrumb')">
      <RouterLink to="/atlas/exercises">{{ $t('app.atlas') }}</RouterLink><span>/</span>
      <RouterLink to="/atlas/exercises">{{ $t('atlas.exercises') }}</RouterLink><span>/</span>
      <span>{{ exercise?.name ?? prettyToken(slug) }}</span>
    </nav>

    <DetailLoading v-if="loading" />
    <section v-else-if="notFound" class="state-page compact">
      <span class="eyebrow">404 · {{ $t('atlas.table.exercise') }}</span><h1>{{ $t('atlas.detail.exercise404') }}</h1>
      <p>{{ $t('atlas.detail.exercise404Message', { slug }) }}</p>
      <RouterLink class="button" to="/atlas/exercises">{{ $t('atlas.detail.browseExercises') }}</RouterLink>
    </section>
    <ErrorState v-else-if="error" :message="error.message" @retry="load" />

    <template v-else-if="exercise">
      <DetailHero
        :image-url="exercise.image_url"
        :title="exercise.name"
        :subtitle="exercise.name_full"
        :slug="exercise.slug"
        :chips="[$t('atlas.detail.bodyChip', { body: exercise.body_part }), prettyToken(exercise.target_category), prettyToken(exercise.mechanics_tier), prettyToken(exercise.resistance_source), prettyToken(exercise.execution_pattern)]"
        :stats="[
          { label: $t('atlas.loadCapacity'), value: formatNumber(exercise.load_capacity, 0), unit: 'kg' },
          { label: $t('atlas.detail.systemicFcsa'), value: formatNumber(exercise.systemic_propulsive_fcsa_demand), unit: 'cm²' },
          ...(hasEtu ? [{ label: $t('atlas.detail.totalEtu'), value: formatNumber(totalEtu), unit: 'cm²' }, { label: $t('atlas.detail.peakJoint'), value: prettyToken(peakJoint) }] : []),
        ]"
      />

      <div class="exercise-viz-grid">
        <section class="viz-panel panel">
          <header class="viz-controls">
            <div v-if="hasEtu || hasRecovery" class="mode-control">
              <button type="button" :class="{ active: mode === 'etu' }" :disabled="!hasEtu" @click="mode = 'etu'">ETU</button>
              <button type="button" :class="{ active: mode === 'recovery' }" :disabled="!hasRecovery" @click="mode = 'recovery'">{{ $t('atlas.detail.recovery') }}</button>
            </div>
            <label v-if="jointVector"><input v-model="showJoints" type="checkbox" /> {{ $t('atlas.detail.jointLoad') }}</label>
            <span class="mono">{{ $t('atlas.detail.normalizedFcsa') }}</span>
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
            <strong>{{ $t('atlas.detail.enginePending') }}</strong>
            <p>{{ $t('atlas.detail.enginePendingMessage') }}</p>
          </div>
          <footer v-if="rawVector && Object.keys(rawVector).length">
            <div class="viz-legend"><strong>{{ vectorTitle }}</strong><span :style="{ background: `linear-gradient(to right, var(--anatMuscle), ${vectorColor})` }" /><small class="mono">{{ $t('atlas.detail.zeroMax') }}</small></div>
            <div v-if="showJoints" class="joint-legend"><strong>{{ $t('atlas.detail.jointLoad') }}</strong><i /><span class="mono">{{ $t('atlas.detail.ringExposure') }}</span></div>
            <p>{{ $t('atlas.detail.syncHint') }}</p>
          </footer>
        </section>

        <div class="exercise-data-column">
          <section v-if="vectorRows.length" class="vector-panel panel">
            <header><h2>{{ vectorTitle }}</h2><span class="mono">{{ vectorSubtitle }}</span></header>
            <div class="vector-head"><span>{{ $t('atlas.detail.muscle') }}</span><span>{{ $t('atlas.detail.rawCm2') }}</span><span>{{ $t('atlas.detail.capacity') }}</span><span>{{ $t('atlas.detail.relativeIntensity') }}</span></div>
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
            <header><h2>{{ $t('atlas.detail.jointLoadExposure') }}</h2><span class="mono">{{ $t('atlas.detail.jointDisclaimer') }}</span></header>
            <div v-for="[joint, value] in jointRows" :key="joint" class="joint-row"><span>{{ prettyToken(joint) }}</span><span class="mono">{{ value.toFixed(2) }}</span><i><b :style="{ width: `${Math.min(100, value * 100)}%` }" /></i></div>
          </section>

          <div class="data-groups exercise-groups"><DataGroup v-for="group in groups" :key="group.title" :title="group.title" :rows="group.rows" /></div>
          <section class="media-section panel">
            <header>
              <h2>{{ $t('atlas.detail.videos') }}</h2>
              <button
                v-if="!addingVideo"
                class="media-add-button"
                type="button"
                :aria-label="$t('atlas.detail.addVideoLabel')"
                @click="openVideoForm"
              ><span aria-hidden="true">+</span> {{ $t('atlas.detail.addVideo') }}</button>
            </header>
            <form v-if="addingVideo" class="video-add-form" @submit.prevent="saveVideo">
              <label for="exercise-video-url">{{ $t('atlas.detail.youtubeLink') }}</label>
              <input
                id="exercise-video-url"
                ref="videoInput"
                v-model="videoUrl"
                type="url"
                inputmode="url"
                autocomplete="url"
                :placeholder="$t('atlas.detail.pasteYoutube')"
                required
              />
              <button class="button primary" type="submit" :disabled="videoSaving || !videoUrl.trim()">
                {{ videoSaving ? $t('atlas.detail.saving') : $t('atlas.detail.save') }}
              </button>
              <button class="button ghost" type="button" :disabled="videoSaving" @click="closeVideoForm">{{ $t('atlas.detail.cancel') }}</button>
              <p v-if="videoError" role="alert">{{ videoError }}</p>
            </form>
            <div v-if="videos.length" class="video-grid">
              <article v-for="(video, index) in videos" :key="video.link" class="video-card">
                <div v-if="video.embedUrl" class="video-frame">
                  <iframe
                    :src="video.embedUrl"
                    :title="$t('atlas.detail.videoTitle', { name: exercise.name, index: index + 1 })"
                    loading="lazy"
                    referrerpolicy="strict-origin-when-cross-origin"
                    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                    allowfullscreen
                  />
                </div>
                <a :href="video.link" target="_blank" rel="noopener noreferrer">
                  <span>{{ video.embedUrl ? $t('atlas.detail.watchYoutube') : domainLabel(video.link) }}</span><b>↗</b>
                </a>
              </article>
            </div>
            <p v-else class="honest-empty">{{ $t('atlas.detail.noExerciseVideos') }}</p>
          </section>
          <TechniqueGuide :data="exercise.technique" />
          <ObjectDataCard
            class="exercise-comments"
            :title="$t('atlas.detail.comments')"
            :data="exercise.comments"
            :empty-message="$t('atlas.detail.noComments')"
          />
        </div>
      </div>
    </template>
  </div>
</template>
