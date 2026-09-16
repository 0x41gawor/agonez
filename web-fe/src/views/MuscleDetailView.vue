<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'

import { atlasApi } from '@/api/atlas'
import { ApiError } from '@/api/client'
import type { MuscleDetail, RelatedExercise } from '@/api/types'
import AnatomyPanel from '@/components/anatomy/AnatomyPanel.vue'
import ErrorState from '@/components/common/ErrorState.vue'
import DataGroup from '@/components/detail/DataGroup.vue'
import DetailHero from '@/components/detail/DetailHero.vue'
import DetailLoading from '@/components/detail/DetailLoading.vue'
import MarkdownArticle from '@/components/detail/MarkdownArticle.vue'
import MuscleGallery from '@/components/detail/MuscleGallery.vue'
import { domainLabel, formatNumber, percentage, prettyToken } from '@/utils/format'
import { useLocaleStore } from '@/stores/locale'

const props = defineProps<{ slug: string }>()
const locale = useLocaleStore()
const { t } = useI18n()
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
    if ((caught as Error).name !== 'AbortError') error.value = caught instanceof Error ? caught : new Error(t('atlas.detail.muscleUnavailable'))
  } finally {
    if (!controller.signal.aborted) loading.value = false
  }
}

watch(() => [props.slug, locale.current], () => void load(), { immediate: true })
onBeforeUnmount(() => controller?.abort())

const notFound = computed(() => error.value instanceof ApiError && error.value.status === 404)
const maximumEtu = computed(() => Math.max(1, ...related.value.map((item) => item.etu_cm2 ?? 0)))
const groups = computed(() => muscle.value ? [
  { title: t('atlas.detail.morphology'), rows: [
    { label: t('atlas.mass'), value: formatNumber(muscle.value.mass_g, 0), unit: 'g' },
    { label: t('atlas.volume'), value: formatNumber(muscle.value.mv_cm3, 0), unit: 'cm³' },
    { label: t('atlas.detail.massReference'), value: muscle.value.mass_reference || '—' },
  ] },
  { title: t('atlas.detail.architecture'), rows: [
    { label: t('atlas.detail.type'), value: muscle.value.architecture || '—' },
    { label: t('atlas.detail.optimalFiberLength'), value: formatNumber(muscle.value.optimal_fiber_length_cm), unit: 'cm' },
    { label: t('atlas.detail.pennationAngle'), value: formatNumber(muscle.value.pennation_angle_deg), unit: '°' },
    { label: 'cos(pennation)', value: muscle.value.pennation_cos == null ? '—' : muscle.value.pennation_cos.toFixed(3) },
  ] },
  { title: t('atlas.detail.capacityGroup'), rows: [
    { label: 'PCSA', value: formatNumber(muscle.value.pcsa), unit: 'cm²' },
    { label: 'PCSA (fiber)', value: formatNumber(muscle.value.pcsa_fiber_cm2), unit: 'cm²' },
    { label: t('atlas.projectedFcsa'), value: formatNumber(muscle.value.pcsa_projected_fcsa_cm2), unit: 'cm²' },
  ] },
  { title: t('atlas.detail.programmingTraits'), rows: [
    { label: t('atlas.detail.smhFactor'), value: prettyToken(muscle.value.smh_factor) },
    { label: t('atlas.detail.strengthCurve'), value: muscle.value.strength_curve || '—' },
    { label: t('atlas.detail.leveragePeak'), value: prettyToken(muscle.value.leverage_peak) },
  ] },
] : [])
</script>

<template>
  <div class="page-wrap detail-page">
    <nav class="breadcrumbs" :aria-label="$t('atlas.detail.breadcrumb')">
      <RouterLink to="/atlas/exercises">{{ $t('app.atlas') }}</RouterLink><span>/</span>
      <RouterLink to="/atlas/muscles">{{ $t('atlas.muscles') }}</RouterLink><span>/</span>
      <span>{{ muscle?.display_name ?? prettyToken(slug) }}</span>
    </nav>

    <DetailLoading v-if="loading" />
    <section v-else-if="notFound" class="state-page compact">
      <span class="eyebrow">404 · {{ $t('atlas.table.muscle') }}</span><h1>{{ $t('atlas.detail.muscle404') }}</h1>
      <p>{{ $t('atlas.detail.muscle404Message', { slug }) }}</p>
      <RouterLink class="button" to="/atlas/muscles">{{ $t('atlas.detail.browseMuscles') }}</RouterLink>
    </section>
    <ErrorState v-else-if="error" :message="error.message" @retry="load" />

    <div v-else-if="muscle" class="muscle-detail-grid">
      <div class="detail-main">
        <DetailHero
          :image-url="muscle.image_url"
          :title="muscle.display_name"
          :subtitle="muscle.name"
          :slug="muscle.slug"
          :chips="[$t('atlas.detail.bodyChip', { body: muscle.body_part }), $t('atlas.detail.complexChip', { complex: prettyToken(muscle.complex) }), muscle.architecture].filter(Boolean)"
          :stats="[
            { label: $t('atlas.mass'), value: formatNumber(muscle.mass_g, 0), unit: 'g' },
            { label: $t('atlas.volume'), value: formatNumber(muscle.mv_cm3, 0), unit: 'cm³' },
            { label: $t('atlas.detail.projectedFcsaShort'), value: formatNumber(muscle.pcsa_projected_fcsa_cm2), unit: 'cm²' },
            { label: $t('atlas.typeIIBias'), value: formatNumber(muscle.fiber_bias_type_ii * 100, 0), unit: '%' },
          ]"
        />

        <div class="data-groups">
          <DataGroup v-for="group in groups" :key="group.title" :title="group.title" :rows="group.rows" />
        </div>

        <section class="fiber-panel panel">
          <h2 class="section-label">{{ $t('atlas.detail.fiberComposition') }}</h2>
          <div class="fiber-meter"><i :style="{ width: percentage(muscle.fiber_bias_type_i) }" /><b :style="{ width: percentage(muscle.fiber_bias_type_ii) }" /></div>
          <div class="fiber-legend mono"><span>{{ $t('atlas.detail.typeI') }} · {{ percentage(muscle.fiber_bias_type_i) }}</span><span>{{ $t('atlas.detail.typeII') }} · {{ percentage(muscle.fiber_bias_type_ii) }}</span></div>
        </section>

        <section class="related-panel panel">
          <header><h2>{{ $t('atlas.detail.relatedTitle') }}</h2><span class="mono">{{ $t('atlas.detail.relatedSubtitle') }}</span></header>
          <div v-if="related.length">
            <RouterLink v-for="item in related" :key="item.slug" class="related-row" :to="{ name: 'exercise-detail', params: { slug: item.slug } }">
              <span><strong>{{ item.name }}</strong><small>{{ prettyToken(item.mechanics_tier) }} · {{ item.name_full }}</small></span>
              <span class="chip">{{ prettyToken(item.target_category) }}</span>
              <span v-if="item.relation === 'measured' && item.etu_cm2 != null" class="related-value"><i><b :style="{ width: `${100 * item.etu_cm2 / maximumEtu}%` }" /></i><span class="mono">{{ formatNumber(item.etu_cm2) }} cm²</span></span>
              <small v-else class="relation-fallback mono">{{ $t('atlas.detail.byTarget') }}</small>
            </RouterLink>
          </div>
          <p v-else class="honest-empty">{{ $t('atlas.detail.noRelations') }}</p>
        </section>

        <div class="media-columns">
          <section class="media-section panel">
            <header><h2>{{ $t('atlas.detail.videos') }}</h2></header>
            <div v-if="muscle.video_links.length" class="link-list">
              <a v-for="link in muscle.video_links" :key="link" :href="link" target="_blank" rel="noopener noreferrer"><span class="play-icon">▶</span><span>{{ domainLabel(link) }}</span><b>↗</b></a>
            </div>
            <p v-else class="honest-empty">{{ $t('atlas.detail.noMuscleVideos') }}</p>
          </section>
          <section class="media-section panel">
            <header><h2>{{ $t('atlas.detail.references') }}</h2></header>
            <div v-if="muscle.article_links.length" class="link-list">
              <a v-for="link in muscle.article_links" :key="link" :href="link" target="_blank" rel="noopener noreferrer"><span>{{ $t('atlas.detail.externalReference') }}</span><small>{{ domainLabel(link) }}</small><b>↗</b></a>
            </div>
            <p v-else class="honest-empty">{{ $t('atlas.detail.noReferences') }}</p>
          </section>
        </div>

        <MuscleGallery
          v-if="muscle.gallery.length"
          :images="muscle.gallery"
          :title="muscle.display_name"
        />

        <section class="bible-panel panel">
          <header><div><span class="eyebrow">{{ $t('atlas.detail.muscleBible') }}</span><h2>{{ muscle.display_name }}</h2></div><span class="chip mono">{{ $t('atlas.detail.databaseContent') }}</span></header>
          <MarkdownArticle v-if="muscle.bible_markdown.trim()" :markdown="muscle.bible_markdown" />
          <p v-else class="honest-empty">{{ $t('atlas.detail.noBible') }}</p>
        </section>
      </div>

      <AnatomyPanel
        :selected-slug="muscle.slug"
        :status="$t('atlas.detail.highlightedStatus', { name: muscle.display_name })"
      />
    </div>
  </div>
</template>
