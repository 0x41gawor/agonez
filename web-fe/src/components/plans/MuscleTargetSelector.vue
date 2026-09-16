<script setup lang="ts">
import { computed, ref } from 'vue'

import type { MuscleListItem } from '@/api/types'

const props = defineProps<{
  modelValue: string[]
  muscles: MuscleListItem[]
}>()
const emit = defineEmits<{ 'update:modelValue': [slugs: string[]] }>()

const open = ref(false)
const query = ref('')
const selected = computed(() =>
  props.modelValue.map((slug) => props.muscles.find((item) => item.slug === slug)).filter(Boolean),
)
const filtered = computed(() => {
  const needle = query.value.trim().toLowerCase()
  return props.muscles
    .filter((item) =>
      !needle
        ? true
        : `${item.display_name} ${item.name} ${item.slug}`.toLowerCase().includes(needle),
    )
    .slice(0, 30)
})

function toggle(slug: string): void {
  emit(
    'update:modelValue',
    props.modelValue.includes(slug)
      ? props.modelValue.filter((value) => value !== slug)
      : [...props.modelValue, slug],
  )
}
</script>

<template>
  <div class="muscle-target-selector">
    <div class="target-chip-row">
      <button
        v-for="muscle in selected"
        :key="muscle?.slug"
        class="chip target-chip"
        type="button"
        :title="$t('plans.targets.remove', { name: muscle?.display_name })"
        @click="muscle && toggle(muscle.slug)"
      >
        {{ muscle?.display_name }} <span aria-hidden="true">×</span>
      </button>
      <button class="button ghost compact" type="button" @click="open = !open">
        {{ open ? $t('plans.targets.close') : modelValue.length ? $t('plans.targets.edit') : $t('plans.targets.add') }}
      </button>
    </div>
    <div v-if="open" class="target-selector-panel">
      <input
        v-model="query"
        class="text-input"
        type="search"
        :placeholder="$t('plans.targets.find')"
        :aria-label="$t('plans.targets.findAria')"
      />
      <div class="target-options">
        <label v-for="muscle in filtered" :key="muscle.slug" class="target-option">
          <input
            type="checkbox"
            :checked="modelValue.includes(muscle.slug)"
            @change="toggle(muscle.slug)"
          />
          <span><strong>{{ muscle.display_name }}</strong><small>{{ muscle.slug }}</small></span>
        </label>
      </div>
    </div>
  </div>
</template>
