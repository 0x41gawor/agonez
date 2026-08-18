<script setup lang="ts">
import { computed } from 'vue'

import type { JointContribution, MuscleContribution } from '@/api/plan-analysis-types'
import type { ExerciseListItem, MuscleListItem } from '@/api/types'
import {
  exerciseLabel,
  groupJointSources,
  groupMuscleSources,
  jointLabel,
  muscleLabel,
} from '@/features/plans/analysis'
import { formatNumber, prettyToken } from '@/utils/format'

const props = defineProps<{
  muscleSlug?: string | null
  jointSlug?: string | null
  muscleContributions?: MuscleContribution[]
  jointContributions?: JointContribution[]
  muscles: MuscleListItem[]
  exercises: ExerciseListItem[]
}>()

const muscleGroups = computed(() =>
  groupMuscleSources(props.muscleContributions ?? []).slice(0, 12),
)
const jointGroups = computed(() =>
  groupJointSources(props.jointContributions ?? []).slice(0, 12),
)
</script>

<template>
  <aside v-if="muscleSlug" class="provenance-inspector panel">
    <header>
      <div>
        <span class="section-label">Contribution provenance</span>
        <strong>{{ muscleLabel(muscleSlug, muscles) }}</strong>
        <p>Backend-returned sources for this muscle's ETU and MRU.</p>
      </div>
      <span class="mono">{{ muscleContributions?.length || 0 }} set records</span>
    </header>
    <div class="provenance-groups">
      <details v-for="group in muscleGroups" :key="group.key">
        <summary>
          <span>
            <strong>{{ exerciseLabel(group.exercise_slug, exercises) }}</strong>
            <small :class="`intent-${group.intent_classification.toLowerCase()}`">{{ prettyToken(group.intent_classification) }}</small>
          </span>
          <span class="provenance-totals mono">
            {{ formatNumber(group.etu, 2) }} ETU · {{ formatNumber(group.mru, 2) }} MRU
          </span>
        </summary>
        <div class="provenance-set-list">
          <div v-for="(item, index) in group.sets.slice(0, 24)" :key="`${item.set_id}:${index}`">
            <span>Set {{ index + 1 }} <small class="mono">#{{ item.set_id }}</small></span>
            <strong>{{ formatNumber(item.etu_contribution, 3) }} ETU</strong>
            <em>{{ formatNumber(item.mru_contribution, 3) }} MRU</em>
          </div>
          <p v-if="group.sets.length > 24">{{ group.sets.length - 24 }} additional set records omitted from this compact view.</p>
        </div>
      </details>
    </div>
  </aside>

  <aside v-else-if="jointSlug" class="provenance-inspector panel">
    <header>
      <div>
        <span class="section-label">Contribution provenance</span>
        <strong>{{ jointLabel(jointSlug) }}</strong>
        <p>Backend-returned sources for joint-load exposure and JRU.</p>
      </div>
      <span class="mono">{{ jointContributions?.length || 0 }} set records</span>
    </header>
    <div class="provenance-groups">
      <details v-for="group in jointGroups" :key="group.exercise_slug">
        <summary>
          <strong>{{ exerciseLabel(group.exercise_slug, exercises) }}</strong>
          <span class="provenance-totals mono">
            {{ formatNumber(group.joint_load, 3) }} load · {{ formatNumber(group.jru, 3) }} JRU
          </span>
        </summary>
        <div class="provenance-set-list">
          <div v-for="(item, index) in group.sets.slice(0, 24)" :key="`${item.set_id}:${index}`">
            <span>Set {{ index + 1 }} <small class="mono">#{{ item.set_id }}</small></span>
            <strong>{{ formatNumber(item.joint_load_exposure, 3) }} load</strong>
            <em>{{ formatNumber(item.jru_contribution, 3) }} JRU</em>
          </div>
          <p v-if="group.sets.length > 24">{{ group.sets.length - 24 }} additional set records omitted from this compact view.</p>
        </div>
      </details>
    </div>
  </aside>
</template>
