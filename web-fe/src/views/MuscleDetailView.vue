<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { useRouter } from 'vue-router'

import { atlasApi } from '@/api/atlas'
import { ApiError } from '@/api/client'
import type { MuscleDetail, RelatedExercise } from '@/api/types'
import AnatomyPanel from '@/components/anatomy/AnatomyPanel.vue'
import ErrorState from '@/components/common/ErrorState.vue'
import MediaImage from '@/components/common/MediaImage.vue'
import DataGroup from '@/components/detail/DataGroup.vue'
import DetailHero from '@/components/detail/DetailHero.vue'
import DetailLoading from '@/components/detail/DetailLoading.vue'
import MarkdownArticle from '@/components/detail/MarkdownArticle.vue'
import { domainLabel, formatNumber, percentage, prettyToken } from '@/utils/format'

const props = defineProps<{ slug: string }>()
const router = useRouter()
const muscle = ref<MuscleDetail | null>(null)
const related = ref<RelatedExercise[]>([])
const loading = ref(true)
const error = ref<Error | null>(null)
let controller: AbortController | null = null

async function load(): Promise<void> {
  controller?.abort()
  controller = new AbortController()
  loading.value = true
  error.value = null
  try {
    const [detail, relations] = await Promise.all([
      atlasApi.muscle(props.slug, controller.signal),
      atlasApi.relatedExercises(props.slug, controller.signal),
    ])
    muscle.value = detail
    related.value = relations.items
  } catch (caught) {
    if ((caught as Error).name !== 'AbortError') error.value = caught instanceof Error ? caught : new Error('Muscle data is unavailable.')
  } finally {
    if (!controller.signal.aborted) loading.value = false
  }
}

watch(() => props.slug, () => void load(), { immediate: true })
onBeforeUnmount(() => controller?.abort())

const notFound = computed(() => error.value instanceof ApiError && error.value.status === 404)
const maximumEtu = computed(() => Math.max(1, ...related.value.map((item) => item.etu_cm2 ?? 0)))
const groups = computed(() => muscle.value ? [
  { title: 'Morphology', rows: [
    { label: 'Mass', value: formatNumber(muscle.value.mass_g, 0), unit: 'g' },
    { label: 'Muscle volume', value: formatNumber(muscle.value.mv_cm3, 0), unit: 'cm³' },
    { label: 'Mass reference', value: muscle.value.mass_reference || '—' },
  ] },
  { title: 'Architecture', rows: [
    { label: 'Type', value: muscle.value.architecture || '—' },
    { label: 'Optimal fiber length', value: formatNumber(muscle.value.optimal_fiber_length_cm), unit: 'cm' },
    { label: 'Pennation angle', value: formatNumber(muscle.value.pennation_angle_deg), unit: '°' },
    { label: 'cos(pennation)', value: muscle.value.pennation_cos == null ? '—' : muscle.value.pennation_cos.toFixed(3) },
  ] },
  { title: 'Capacity', rows: [
    { label: 'PCSA', value: formatNumber(muscle.value.pcsa), unit: 'cm²' },
    { label: 'PCSA (fiber)', value: formatNumber(muscle.value.pcsa_fiber_cm2), unit: 'cm²' },
    { label: 'Projected FCSA', value: formatNumber(muscle.value.pcsa_projected_fcsa_cm2), unit: 'cm²' },
  ] },
  { title: 'Programming traits', rows: [
    { label: 'SMH factor', value: prettyToken(muscle.value.smh_factor) },
    { label: 'Strength curve', value: muscle.value.strength_curve || '—' },
    { label: 'Leverage peak', value: prettyToken(muscle.value.leverage_peak) },
  ] },
] : [])
</script>

<template>
  <div class="page-wrap detail-page">
    <nav class="breadcrumbs" aria-label="Breadcrumb">
      <RouterLink to="/atlas/exercises">Atlas</RouterLink><span>/</span>
      <RouterLink to="/atlas/muscles">Muscles</RouterLink><span>/</span>
      <span>{{ muscle?.display_name ?? prettyToken(slug) }}</span>
    </nav>

    <DetailLoading v-if="loading" />
    <section v-else-if="notFound" class="state-page compact">
      <span class="eyebrow">404 · Muscle</span><h1>Muscle not found</h1>
      <p>No muscle with slug “{{ slug }}” exists in the current Atlas.</p>
      <RouterLink class="button" to="/atlas/muscles">Browse muscles</RouterLink>
    </section>
    <ErrorState v-else-if="error" :message="error.message" @retry="load" />

    <div v-else-if="muscle" class="muscle-detail-grid">
      <div class="detail-main">
        <DetailHero
          :image-url="muscle.image_url"
          :title="muscle.display_name"
          :subtitle="muscle.name"
          :slug="muscle.slug"
          :chips="[`${muscle.body_part} body`, `${prettyToken(muscle.complex)} complex`, muscle.architecture].filter(Boolean)"
          :stats="[
            { label: 'Mass', value: formatNumber(muscle.mass_g, 0), unit: 'g' },
            { label: 'Volume', value: formatNumber(muscle.mv_cm3, 0), unit: 'cm³' },
            { label: 'Proj. FCSA', value: formatNumber(muscle.pcsa_projected_fcsa_cm2), unit: 'cm²' },
            { label: 'Type II bias', value: formatNumber(muscle.fiber_bias_type_ii * 100, 0), unit: '%' },
          ]"
        />

        <div class="data-groups">
          <DataGroup v-for="group in groups" :key="group.title" :title="group.title" :rows="group.rows" />
        </div>

        <section class="fiber-panel panel">
          <h2 class="section-label">Fiber composition</h2>
          <div class="fiber-meter"><i :style="{ width: percentage(muscle.fiber_bias_type_i) }" /><b :style="{ width: percentage(muscle.fiber_bias_type_ii) }" /></div>
          <div class="fiber-legend mono"><span>Type I · {{ percentage(muscle.fiber_bias_type_i) }}</span><span>Type II · {{ percentage(muscle.fiber_bias_type_ii) }}</span></div>
        </section>

        <section class="related-panel panel">
          <header><h2>Exercises targeting this muscle</h2><span class="mono">measured ETU · target fallback</span></header>
          <div v-if="related.length">
            <button v-for="item in related" :key="item.slug" class="related-row" type="button" @click="router.push({ name: 'exercise-detail', params: { slug: item.slug } })">
              <span><strong>{{ item.name }}</strong><small>{{ prettyToken(item.mechanics_tier) }} · {{ item.name_full }}</small></span>
              <span class="chip">{{ prettyToken(item.target_category) }}</span>
              <span v-if="item.relation === 'measured' && item.etu_cm2 != null" class="related-value"><i><b :style="{ width: `${100 * item.etu_cm2 / maximumEtu}%` }" /></i><span class="mono">{{ formatNumber(item.etu_cm2) }} cm²</span></span>
              <small v-else class="relation-fallback mono">by target category</small>
            </button>
          </div>
          <p v-else class="honest-empty">No measured or target-category exercise relationships are available.</p>
        </section>

        <section v-if="muscle.gallery.length" class="media-section panel">
          <header><h2>Gallery</h2><span class="mono">{{ muscle.gallery.length }} images</span></header>
          <div class="gallery-grid"><MediaImage v-for="image in muscle.gallery" :key="image" :src="image" :alt="`${muscle.display_name} anatomy`" /></div>
        </section>

        <div class="media-columns">
          <section class="media-section panel">
            <header><h2>Demonstration videos</h2></header>
            <div v-if="muscle.video_links.length" class="link-list">
              <a v-for="link in muscle.video_links" :key="link" :href="link" target="_blank" rel="noopener noreferrer"><span class="play-icon">▶</span><span>{{ domainLabel(link) }}</span><b>↗</b></a>
            </div>
            <p v-else class="honest-empty">No video links stored for this muscle yet.</p>
          </section>
          <section class="media-section panel">
            <header><h2>References</h2></header>
            <div v-if="muscle.article_links.length" class="link-list">
              <a v-for="link in muscle.article_links" :key="link" :href="link" target="_blank" rel="noopener noreferrer"><span>External reference</span><small>{{ domainLabel(link) }}</small><b>↗</b></a>
            </div>
            <p v-else class="honest-empty">No external references stored yet.</p>
          </section>
        </div>

        <section class="bible-panel panel">
          <header><div><span class="eyebrow">Muscle Bible</span><h2>{{ muscle.display_name }}</h2></div><span class="chip mono">database content</span></header>
          <MarkdownArticle v-if="muscle.bible_markdown.trim()" :markdown="muscle.bible_markdown" />
          <p v-else class="honest-empty">Editorial content for this muscle has not been authored yet.</p>
        </section>
      </div>

      <AnatomyPanel
        :selected-slug="muscle.slug"
        :status="`${muscle.display_name} highlighted · unrelated anatomy de-emphasized`"
      />
    </div>
  </div>
</template>
