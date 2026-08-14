<script setup lang="ts">
import type { MuscleListItem } from '@/api/types'
import { formatNumber, percentage, prettyToken } from '@/utils/format'

defineProps<{ items: MuscleListItem[]; maximumMass: number; maximumCapacity: number; hovered: string | null }>()
const emit = defineEmits<{ hover: [slug: string | null] }>()
</script>

<template>
  <div class="atlas-table-wrap panel">
    <table class="atlas-table muscle-table">
      <thead><tr><th>Muscle</th><th>Body</th><th>Complex</th><th>Mass g</th><th class="number">Vol cm³</th><th>Fiber I / II</th><th>Proj. FCSA cm²</th></tr></thead>
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
          <td><RouterLink class="atlas-cell-link atlas-cell-primary" :to="{ name: 'muscle-detail', params: { slug: item.slug } }"><span><strong>{{ item.display_name }}</strong><small><i>{{ item.name }}</i></small></span></RouterLink></td>
          <td><RouterLink class="atlas-cell-link" tabindex="-1" aria-hidden="true" :to="{ name: 'muscle-detail', params: { slug: item.slug } }">{{ item.body_part }}</RouterLink></td>
          <td><RouterLink class="atlas-cell-link" tabindex="-1" aria-hidden="true" :to="{ name: 'muscle-detail', params: { slug: item.slug } }"><span class="chip">{{ prettyToken(item.complex) }}</span></RouterLink></td>
          <td><RouterLink class="atlas-cell-link" tabindex="-1" aria-hidden="true" :to="{ name: 'muscle-detail', params: { slug: item.slug } }"><span class="metric-cell"><span class="metric-bar"><i :style="{ width: `${Math.max(3, 100 * item.mass_g / maximumMass)}%` }" /></span><span class="mono">{{ formatNumber(item.mass_g, 0) }}</span></span></RouterLink></td>
          <td class="number mono"><RouterLink class="atlas-cell-link" tabindex="-1" aria-hidden="true" :to="{ name: 'muscle-detail', params: { slug: item.slug } }">{{ formatNumber(item.mv_cm3, 0) }}</RouterLink></td>
          <td><RouterLink class="atlas-cell-link" tabindex="-1" aria-hidden="true" :to="{ name: 'muscle-detail', params: { slug: item.slug } }"><span class="fiber-cell" :title="`Type I ${percentage(item.fiber_bias_type_i)}, Type II ${percentage(item.fiber_bias_type_ii)}`"><span><i :style="{ width: percentage(item.fiber_bias_type_i) }" /><b :style="{ width: percentage(item.fiber_bias_type_ii) }" /></span><small class="mono">II {{ percentage(item.fiber_bias_type_ii) }}</small></span></RouterLink></td>
          <td><RouterLink class="atlas-cell-link" tabindex="-1" aria-hidden="true" :to="{ name: 'muscle-detail', params: { slug: item.slug } }"><span class="metric-cell green"><span class="metric-bar"><i :style="{ width: `${Math.max(3, 100 * (item.pcsa_projected_fcsa_cm2 ?? 0) / maximumCapacity)}%` }" /></span><span class="mono">{{ formatNumber(item.pcsa_projected_fcsa_cm2) }}</span></span></RouterLink></td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
