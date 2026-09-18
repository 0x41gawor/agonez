<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'

import HomeImage from '@/components/home/HomeImage.vue'

type Spec = { k: string; v: string }

const { tm } = useI18n()
const chips = computed(() => tm('home.exerciseAtlas.chips') as string[])
const muscleSpecs = computed(() => tm('home.muscleAtlas.specs') as Spec[])
const features = [
  { key: 'technique', tone: 'outline', planned: false },
  { key: 'io', tone: 'diamond', planned: false },
  { key: 'mobile', tone: 'planned', planned: true },
  { key: 'progress', tone: 'planned', planned: true },
  { key: 'knowledge', tone: 'planned', planned: true },
] as const
</script>

<template>
  <section id="atlas" class="home-section home-showcase">
    <div class="home-container">
      <header class="home-split-heading">
        <div>
          <span class="home-eyebrow">{{ $t('home.exerciseAtlas.eyebrow') }}</span>
          <h2>{{ $t('home.exerciseAtlas.title') }}</h2>
        </div>
        <div>
          <p>{{ $t('home.exerciseAtlas.body') }}</p>
          <div class="home-chip-row">
            <span v-for="chip in chips" :key="chip" class="home-chip">{{ chip }}</span>
          </div>
        </div>
      </header>

      <div class="home-browser home-showcase-frame">
        <div class="home-browser-bar">
          <span class="home-window-dot home-window-dot-red" />
          <span class="home-window-dot home-window-dot-amber" />
          <span class="home-window-dot home-window-dot-green" />
          <span class="home-browser-label">{{ $t('home.exerciseAtlas.frameLabel') }}</span>
        </div>
        <HomeImage class="home-product-image" path="atlas-exercises/atlas-grid.png" :alt="$t('home.images.atlasGrid')" :width="1590" :height="1218" />
      </div>

      <div class="home-detail-grid">
        <div class="home-media-panel home-exercise-identity">
          <HomeImage path="atlas-exercises/exercise-name.png" :alt="$t('home.images.exerciseName')" :width="475" :height="171" />
        </div>
        <article class="home-media-panel home-exercise-etu">
          <header class="home-panel-heading home-panel-heading-inline">
            <strong>{{ $t('home.exerciseAtlas.etuRows.title') }}</strong>
            <span>{{ $t('home.exerciseAtlas.etuRows.body') }}</span>
          </header>
          <HomeImage path="atlas-exercises/etu-rows.png" :alt="$t('home.images.etuRows')" :width="709" :height="225" />
        </article>
        <article class="home-media-panel">
          <header class="home-panel-heading">
            <strong>{{ $t('home.exerciseAtlas.etuAnatomy.title') }}</strong>
            <span>{{ $t('home.exerciseAtlas.etuAnatomy.body') }}</span>
          </header>
          <HomeImage path="atlas-exercises/etu-anatomy.png" :alt="$t('home.images.etuAnatomy')" :width="452" :height="372" />
        </article>
        <div class="home-panel-stack">
          <article class="home-media-panel">
            <header class="home-panel-heading">
              <strong>{{ $t('home.exerciseAtlas.technique.title') }}</strong>
              <span>{{ $t('home.exerciseAtlas.technique.body') }}</span>
            </header>
            <HomeImage path="atlas-exercises/technique-tldr.png" :alt="$t('home.images.technique')" :width="538" :height="218" />
          </article>
          <article class="home-media-panel">
            <header class="home-panel-heading">
              <strong>{{ $t('home.exerciseAtlas.classification.title') }}</strong>
              <span>{{ $t('home.exerciseAtlas.classification.body') }}</span>
            </header>
            <HomeImage path="atlas-exercises/classification.png" :alt="$t('home.images.classification')" :width="548" :height="176" />
          </article>
        </div>
      </div>
      <p class="home-disclaimer">{{ $t('home.exerciseAtlas.disclaimer') }}</p>
    </div>
  </section>

  <section id="kreator" class="home-section home-showcase home-alt-section">
    <div class="home-container home-builder-grid">
      <div>
        <span class="home-eyebrow">{{ $t('home.planBuilder.eyebrow') }}</span>
        <h2>{{ $t('home.planBuilder.title') }}</h2>
        <p class="home-section-copy">{{ $t('home.planBuilder.body') }}</p>
        <div class="home-definition-list">
          <div v-for="item in ['roles', 'slot', 'rest']" :key="item">
            <span>{{ $t(`home.planBuilder.${item}.label`) }}</span>
            <p>{{ $t(`home.planBuilder.${item}.body`) }}</p>
          </div>
        </div>
        <div class="home-actions">
          <RouterLink class="home-button home-button-primary" to="/plans">{{ $t('home.planBuilder.ctaPrimary') }}</RouterLink>
          <a class="home-button home-button-secondary" href="#analiza">{{ $t('home.planBuilder.ctaSecondary') }}</a>
        </div>
      </div>
      <div class="home-builder-panels">
        <article class="home-media-panel home-elevated-panel">
          <header class="home-panel-heading home-panel-heading-between">
            <span>{{ $t('home.planBuilder.panelDays.left') }}</span><span>{{ $t('home.planBuilder.panelDays.right') }}</span>
          </header>
          <HomeImage path="plan-builder/microcycle-days.png" :alt="$t('home.images.builderDays')" :width="690" :height="320" />
        </article>
        <article class="home-media-panel home-elevated-panel home-elevated-panel-strong">
          <header class="home-panel-heading home-panel-heading-between">
            <span>{{ $t('home.planBuilder.panelSlot.left') }}</span><span>{{ $t('home.planBuilder.panelSlot.right') }}</span>
          </header>
          <HomeImage path="plan-builder/slot-set-prescription.png" :alt="$t('home.images.builderSlot')" :width="660" :height="450" />
        </article>
      </div>
    </div>
  </section>

  <section id="analiza" class="home-section home-showcase">
    <div class="home-container">
      <div class="home-badged-eyebrow">
        <span class="home-eyebrow">{{ $t('home.planAnalysis.eyebrow') }}</span>
        <span class="home-badge home-badge-experimental">{{ $t('home.badges.experimental') }}</span>
      </div>
      <header class="home-split-heading home-analysis-heading">
        <h2>{{ $t('home.planAnalysis.title') }}</h2>
        <p>{{ $t('home.planAnalysis.body') }}</p>
      </header>

      <article class="home-media-panel">
        <header class="home-panel-heading home-panel-heading-between">
          <span>{{ $t('home.planAnalysis.strip.left') }}</span><span>{{ $t('home.planAnalysis.strip.right') }}</span>
        </header>
        <div class="home-strip-scroller" tabindex="0">
          <HomeImage path="plan-analysis/microcycle-strip-wide.png" :alt="$t('home.images.analysisStrip')" :width="1290" :height="138" />
        </div>
      </article>

      <div class="home-analysis-grid">
        <article class="home-media-panel">
          <header class="home-panel-heading home-metric-heading"><span class="home-metric-dot is-recovery" /><strong>{{ $t('home.planAnalysis.recovery.title') }}</strong><span>{{ $t('home.planAnalysis.recovery.meta') }}</span></header>
          <HomeImage path="plan-analysis/recovery-anatomy.png" :alt="$t('home.images.recoveryAnatomy')" :width="858" :height="772" />
        </article>
        <article class="home-media-panel">
          <header class="home-panel-heading home-metric-heading"><span class="home-metric-dot is-etu" /><strong>{{ $t('home.planAnalysis.ranking.title') }}</strong><span>{{ $t('home.planAnalysis.ranking.meta') }}</span></header>
          <HomeImage path="plan-analysis/muscle-ranking.png" :alt="$t('home.images.ranking')" :width="706" :height="575" />
        </article>
      </div>

      <div class="home-debt-grid">
        <article class="home-media-panel">
          <header class="home-panel-heading"><strong>{{ $t('home.planAnalysis.debts.title') }}</strong><span>{{ $t('home.planAnalysis.debts.body') }}</span></header>
          <HomeImage path="plan-analysis/recovery-debts.png" :alt="$t('home.images.debts')" :width="408" :height="372" />
        </article>
        <article class="home-copy-card is-etu"><h3>{{ $t('home.planAnalysis.targeted.title') }}</h3><p>{{ $t('home.planAnalysis.targeted.body') }}</p></article>
        <article class="home-copy-card"><h3>{{ $t('home.planAnalysis.provenance.title') }}</h3><p>{{ $t('home.planAnalysis.provenance.body') }}</p></article>
      </div>
      <p class="home-disclaimer">{{ $t('home.planAnalysis.disclaimer') }}</p>
    </div>
  </section>

  <section class="home-section home-showcase home-alt-section">
    <div class="home-container home-muscle-grid">
      <article class="home-media-panel home-muscle-visual">
        <HomeImage path="atlas-muscles/muscle-cards.png" :alt="$t('home.images.muscleCards')" :width="592" :height="588" />
      </article>
      <div class="home-muscle-copy">
        <span class="home-eyebrow">{{ $t('home.muscleAtlas.eyebrow') }}</span>
        <h2>{{ $t('home.muscleAtlas.title') }}</h2>
        <p class="home-section-copy">{{ $t('home.muscleAtlas.body') }}</p>
        <dl class="home-spec-grid">
          <div v-for="spec in muscleSpecs" :key="spec.k"><dt>{{ spec.k }}</dt><dd>{{ spec.v }}</dd></div>
        </dl>
        <p class="home-model-note">{{ $t('home.muscleAtlas.note') }}</p>
        <RouterLink class="home-text-link" to="/atlas/muscles">{{ $t('home.muscleAtlas.link') }} <span aria-hidden="true">→</span></RouterLink>
      </div>
    </div>
  </section>

  <section class="home-section home-section-compact">
    <div class="home-container">
      <header class="home-inline-heading">
        <span class="home-eyebrow">{{ $t('home.features.eyebrow') }}</span>
        <h2>{{ $t('home.features.title') }}</h2>
      </header>
      <div class="home-feature-grid">
        <article v-for="feature in features" :key="feature.key" class="home-feature-card">
          <div class="home-feature-title">
            <span class="home-feature-icon" :class="`is-${feature.tone}`" />
            <h3>{{ $t(`home.features.${feature.key}.title`) }}</h3>
            <span v-if="feature.planned" class="home-badge home-badge-planned">{{ $t('home.badges.comingSoon') }}</span>
          </div>
          <p>{{ $t(`home.features.${feature.key}.body`) }}</p>
        </article>
      </div>
    </div>
  </section>
</template>
