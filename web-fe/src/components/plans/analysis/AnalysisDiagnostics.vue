<script setup lang="ts">
import type { AnalysisDiagnostic } from '@/api/plan-analysis-types'
import type { MuscleListItem } from '@/api/types'
import { diagnosticTitle, jointLabel, muscleLabel } from '@/features/plans/analysis'

defineProps<{
  diagnostics: AnalysisDiagnostic[]
  muscles: MuscleListItem[]
}>()

function exerciseHref(slug: string): string {
  return `/atlas/exercises/${encodeURIComponent(slug)}`
}
</script>

<template>
  <section v-if="diagnostics.length" class="analysis-section diagnostics-section">
    <header class="analysis-section-heading">
      <div><span class="section-label">{{ $t('analysis.diagnostics.label') }}</span><h2>{{ $t('analysis.diagnostics.title') }}</h2><p>{{ $t('analysis.diagnostics.subtitle') }}</p></div>
      <span class="mono analysis-count">{{ $t('analysis.diagnostics.notices', { count: diagnostics.length }) }}</span>
    </header>
    <div class="diagnostic-list">
      <details
        v-for="diagnostic in diagnostics"
        :key="`${diagnostic.code}:${diagnostic.exercise_slug || ''}`"
        class="diagnostic-card panel"
        :class="`severity-${diagnostic.severity.toLowerCase()}`"
        :open="diagnostic.code === 'RECOVERY_DIVERGENCE'"
      >
        <summary>
          <span><small>{{ diagnostic.severity }}</small><strong>{{ diagnosticTitle(diagnostic) }}</strong></span>
          <code>{{ diagnostic.code }}</code>
        </summary>
        <div>
          <p>{{ diagnostic.message }}</p>
          <p v-if="diagnostic.exercise_slug">
            <strong>{{ $t('analysis.diagnostics.exercise') }}</strong>
            <a class="analysis-exercise-link" :href="exerciseHref(diagnostic.exercise_slug)">
              {{ diagnostic.exercise_slug }}
            </a>
          </p>
          <div v-if="diagnostic.affected_muscle_slugs.length" class="diagnostic-resources">
            <strong>{{ $t('analysis.diagnostics.muscles') }}</strong>
            <span v-for="slug in diagnostic.affected_muscle_slugs" :key="slug">{{ muscleLabel(slug, muscles) }}</span>
          </div>
          <div v-if="diagnostic.affected_joint_slugs.length" class="diagnostic-resources">
            <strong>{{ $t('analysis.diagnostics.joints') }}</strong>
            <span v-for="slug in diagnostic.affected_joint_slugs" :key="slug">{{ jointLabel(slug) }}</span>
          </div>
        </div>
      </details>
    </div>
  </section>
</template>
