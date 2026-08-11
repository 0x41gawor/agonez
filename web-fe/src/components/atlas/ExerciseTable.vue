<script setup lang="ts">
import type { ExerciseListItem } from '@/api/types'
import { formatNumber, prettyToken } from '@/utils/format'

defineProps<{ items: ExerciseListItem[]; maximumDemand: number; hovered: string | null }>()
const emit = defineEmits<{ hover: [slug: string | null]; select: [slug: string] }>()
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
          tabindex="0"
          @mouseenter="emit('hover', item.slug)"
          @mouseleave="emit('hover', null)"
          @focus="emit('hover', item.slug)"
          @blur="emit('hover', null)"
          @click="emit('select', item.slug)"
          @keydown.enter="emit('select', item.slug)"
          @keydown.space.prevent="emit('select', item.slug)"
        >
          <td><strong>{{ item.name }} <span v-if="item.has_engine_vectors" class="status-dot" title="Engine vectors available" /></strong><small>{{ item.name_full }}</small></td>
          <td>{{ item.body_part }}</td>
          <td><span class="chip">{{ prettyToken(item.target_category) }}</span></td>
          <td>{{ prettyToken(item.mechanics_tier) }}</td>
          <td>{{ prettyToken(item.resistance_source) }}</td>
          <td class="number mono">{{ formatNumber(item.load_capacity, 0) }}</td>
          <td><div class="metric-cell"><span class="metric-bar"><i :style="{ width: `${Math.max(3, 100 * item.systemic_propulsive_fcsa_demand / maximumDemand)}%` }" /></span><span class="mono">{{ formatNumber(item.systemic_propulsive_fcsa_demand) }}</span></div></td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
