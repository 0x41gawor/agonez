<script setup lang="ts">
import type { ExerciseListItem } from '@/api/types'
import { formatNumber, prettyToken } from '@/utils/format'

defineProps<{ items: ExerciseListItem[]; maximumDemand: number; hovered: string | null }>()
const emit = defineEmits<{ hover: [slug: string | null] }>()
</script>

<template>
  <div class="atlas-table-wrap panel">
    <table class="atlas-table exercise-table">
      <thead>
        <tr><th>Exercise</th><th>Body</th><th>Target</th><th>Mechanics</th><th>Resistance</th><th class="number">Load kg</th><th>FCSA demand cm²</th></tr>
      </thead>
      <tbody>
        <tr
          v-for="item in items"
          :key="item.slug"
          :class="{ hovered: hovered === item.slug }"
          @mouseenter="emit('hover', item.slug)"
          @mouseleave="emit('hover', null)"
          @focusin="emit('hover', item.slug)"
          @focusout="emit('hover', null)"
        >
          <td><RouterLink class="atlas-cell-link atlas-cell-primary" :to="{ name: 'exercise-detail', params: { slug: item.slug } }"><span><strong>{{ item.name }} <span v-if="item.has_engine_vectors" class="status-dot" title="Engine vectors available" /></strong><small>{{ item.name_full }}</small></span></RouterLink></td>
          <td><RouterLink class="atlas-cell-link" tabindex="-1" aria-hidden="true" :to="{ name: 'exercise-detail', params: { slug: item.slug } }">{{ item.body_part }}</RouterLink></td>
          <td><RouterLink class="atlas-cell-link" tabindex="-1" aria-hidden="true" :to="{ name: 'exercise-detail', params: { slug: item.slug } }"><span class="chip">{{ prettyToken(item.target_category) }}</span></RouterLink></td>
          <td><RouterLink class="atlas-cell-link" tabindex="-1" aria-hidden="true" :to="{ name: 'exercise-detail', params: { slug: item.slug } }">{{ prettyToken(item.mechanics_tier) }}</RouterLink></td>
          <td><RouterLink class="atlas-cell-link" tabindex="-1" aria-hidden="true" :to="{ name: 'exercise-detail', params: { slug: item.slug } }">{{ prettyToken(item.resistance_source) }}</RouterLink></td>
          <td class="number mono"><RouterLink class="atlas-cell-link" tabindex="-1" aria-hidden="true" :to="{ name: 'exercise-detail', params: { slug: item.slug } }">{{ formatNumber(item.load_capacity, 0) }}</RouterLink></td>
          <td><RouterLink class="atlas-cell-link" tabindex="-1" aria-hidden="true" :to="{ name: 'exercise-detail', params: { slug: item.slug } }"><span class="metric-cell"><span class="metric-bar"><i :style="{ width: `${Math.max(3, 100 * item.systemic_propulsive_fcsa_demand / maximumDemand)}%` }" /></span><span class="mono">{{ formatNumber(item.systemic_propulsive_fcsa_demand) }}</span></span></RouterLink></td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
