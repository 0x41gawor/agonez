<script setup lang="ts">
import type { AnalysisDiagnostic } from '@/api/plan-analysis-types'
import type { MuscleListItem } from '@/api/types'
import { diagnosticTitle, jointLabel, muscleLabel } from '@/features/plans/analysis'

defineProps<{
  diagnostics: AnalysisDiagnostic[]
  muscles: MuscleListItem[]
}>()
</script>

<template>
  <section v-if="diagnostics.length" class="analysis-section diagnostics-section">
    <header class="analysis-section-heading">
      <div><span class="section-label">Diagnostics</span><h2>Model and data notices</h2><p>Diagnostics remain inspectable and do not replace partial Analysis results.</p></div>
      <span class="mono analysis-count">{{ diagnostics.length }} notices</span>
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
          <p v-if="diagnostic.exercise_slug"><strong>Exercise:</strong> {{ diagnostic.exercise_slug }}</p>
          <div v-if="diagnostic.affected_muscle_slugs.length" class="diagnostic-resources">
            <strong>Affected muscles</strong>
            <span v-for="slug in diagnostic.affected_muscle_slugs" :key="slug">{{ muscleLabel(slug, muscles) }}</span>
          </div>
          <div v-if="diagnostic.affected_joint_slugs.length" class="diagnostic-resources">
            <strong>Affected joints</strong>
            <span v-for="slug in diagnostic.affected_joint_slugs" :key="slug">{{ jointLabel(slug) }}</span>
          </div>
        </div>
      </details>
    </div>
  </section>
</template>
