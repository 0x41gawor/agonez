<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'

type ReferenceRow = { k: string; v: string }

const { tm } = useI18n()
const chain = computed(() => tm('home.model.chain') as string[])
const referenceRows = computed(() => tm('home.model.reference.rows') as ReferenceRow[])
const limits = computed(() => tm('home.model.limits.items') as string[])
const modelItems = ['etu', 'fcsa', 'recovery'] as const
</script>

<template>
  <section id="model" class="home-section home-model-section">
    <div class="home-model-grid-bg" aria-hidden="true" />
    <div class="home-container home-model-content">
      <span class="home-eyebrow">{{ $t('home.model.eyebrow') }}</span>
      <h2>{{ $t('home.model.title') }}</h2>
      <p class="home-section-copy">{{ $t('home.model.body') }}</p>

      <div class="home-chain">
        <template v-for="(item, index) in chain" :key="item">
          <span class="home-chain-node" :class="{ 'is-etu': index === 2, 'is-recovery': index === 3, 'is-brand': index === 5 }">{{ item }}</span>
          <span v-if="index < chain.length - 1" class="home-chain-arrow" aria-hidden="true">→</span>
        </template>
      </div>

      <p class="home-expand-hint">{{ $t('home.model.expandHint') }}</p>
      <div class="home-details-list">
        <details v-for="item in modelItems" :key="item" class="home-model-detail" :class="`is-${item}`">
          <summary>
            <span class="home-detail-dot" />
            <strong>{{ $t(`home.model.${item}.title`) }}</strong>
            <span class="home-detail-summary">{{ $t(`home.model.${item}.summary`) }}</span>
            <span class="home-detail-toggle" aria-hidden="true">+</span>
          </summary>
          <div class="home-detail-body">
            <p>{{ $t(`home.model.${item}.body`) }}</p>
            <pre>{{ $t(`home.model.${item}.formula`) }}</pre>
            <small>{{ $t(`home.model.${item}.caveat`) }}</small>
          </div>
        </details>

        <details class="home-model-detail is-reference">
          <summary>
            <img src="/img/home/brand/agonez-mark.png" alt="" aria-hidden="true" />
            <strong>{{ $t('home.model.reference.title') }}</strong>
            <span class="home-detail-summary">{{ $t('home.model.reference.summary') }}</span>
            <span class="home-detail-toggle" aria-hidden="true">+</span>
          </summary>
          <div class="home-detail-body">
            <p>{{ $t('home.model.reference.body') }}</p>
            <dl class="home-reference-rows">
              <div v-for="row in referenceRows" :key="row.k"><dt>{{ row.k }}</dt><dd>{{ row.v }}</dd></div>
            </dl>
            <small>{{ $t('home.model.reference.caveat') }}</small>
          </div>
        </details>

        <details class="home-model-detail is-limits">
          <summary>
            <span class="home-detail-dot" />
            <strong>{{ $t('home.model.limits.title') }}</strong>
            <span class="home-detail-summary">{{ $t('home.model.limits.summary') }}</span>
            <span class="home-detail-toggle" aria-hidden="true">+</span>
          </summary>
          <div class="home-detail-body">
            <div class="home-limits-grid"><p v-for="item in limits" :key="item">{{ item }}</p></div>
            <small>{{ $t('home.model.limits.note') }}</small>
          </div>
        </details>
      </div>
    </div>
  </section>
</template>
