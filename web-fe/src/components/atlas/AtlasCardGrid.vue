<script setup lang="ts">
import type { ExerciseListItem, MuscleListItem } from '@/api/types'
import MediaImage from '@/components/common/MediaImage.vue'
import { formatNumber, prettyToken } from '@/utils/format'

defineProps<{
  kind: 'exercises' | 'muscles'
  exerciseItems: ExerciseListItem[]
  muscleItems: MuscleListItem[]
  hovered: string | null
}>()
const emit = defineEmits<{ hover: [slug: string | null]; select: [slug: string] }>()
</script>

<template>
  <div class="atlas-grid">
    <template v-if="kind === 'exercises'">
      <article
        v-for="item in exerciseItems"
        :key="item.slug"
        class="atlas-card panel"
        :class="{ hovered: hovered === item.slug }"
        tabindex="0"
        @mouseenter="emit('hover', item.slug)" @mouseleave="emit('hover', null)" @focus="emit('hover', item.slug)" @blur="emit('hover', null)"
        @click="emit('select', item.slug)" @keydown.enter="emit('select', item.slug)" @keydown.space.prevent="emit('select', item.slug)"
      >
        <MediaImage :src="item.image_url" :alt="item.name" label="exercise visual unavailable" />
        <div class="atlas-card-body">
          <h2>{{ item.name }} <span v-if="item.has_engine_vectors" class="status-dot" /></h2>
          <p>{{ item.name_full }}</p>
          <div class="card-chips"><span class="chip">{{ prettyToken(item.target_category) }}</span><span class="chip">{{ prettyToken(item.mechanics_tier) }}</span></div>
          <footer class="mono"><span>{{ formatNumber(item.load_capacity, 0) }} kg</span><span>{{ formatNumber(item.systemic_propulsive_fcsa_demand) }} cm²</span></footer>
        </div>
      </article>
    </template>
    <template v-else>
      <article
        v-for="item in muscleItems"
        :key="item.slug"
        class="atlas-card panel"
        :class="{ hovered: hovered === item.slug }"
        tabindex="0"
        @mouseenter="emit('hover', item.slug)" @mouseleave="emit('hover', null)" @focus="emit('hover', item.slug)" @blur="emit('hover', null)"
        @click="emit('select', item.slug)" @keydown.enter="emit('select', item.slug)" @keydown.space.prevent="emit('select', item.slug)"
      >
        <MediaImage :src="item.image_url" :alt="item.display_name" label="muscle visual unavailable" />
        <div class="atlas-card-body">
          <h2>{{ item.display_name }}</h2>
          <p><i>{{ item.name }}</i></p>
          <div class="card-chips"><span class="chip">{{ prettyToken(item.complex) }}</span><span class="chip">{{ item.body_part }}</span></div>
          <footer class="mono"><span>{{ formatNumber(item.mass_g, 0) }} g</span><span>{{ formatNumber(item.pcsa_projected_fcsa_cm2) }} cm²</span></footer>
        </div>
      </article>
    </template>
  </div>
</template>
