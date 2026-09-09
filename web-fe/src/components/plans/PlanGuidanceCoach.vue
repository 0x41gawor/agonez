<script setup lang="ts">
import { computed, ref, watch } from 'vue'

import type { PlanGuidanceItem } from '@/features/plans/guidance'

const props = defineProps<{
  active: boolean
  items: PlanGuidanceItem[]
}>()

const emit = defineEmits<{
  review: [target: PlanGuidanceItem['target']]
}>()

const open = ref(true)
const issueKey = computed(() => props.items.map((item) => item.id).join('|'))

watch(issueKey, (next, previous) => {
  if (next && next !== previous) open.value = true
})

function review(item: PlanGuidanceItem): void {
  open.value = false
  emit('review', item.target)
}
</script>

<template>
  <div v-show="active && items.length" class="plan-guidance">
    <Transition name="plan-guidance-card" mode="out-in">
      <aside
        v-if="open"
        id="plan-guidance-panel"
        key="panel"
        class="plan-guidance-panel"
        aria-live="polite"
        aria-label="Plan guidance"
        @keydown.esc="open = false"
      >
        <header>
          <span class="plan-guidance-signal" aria-hidden="true"><i /></span>
          <div>
            <span class="eyebrow">Plan check</span>
            <strong>{{ items.length }} {{ items.length === 1 ? 'suggestion' : 'suggestions' }}</strong>
          </div>
          <button type="button" aria-label="Minimize plan guidance" title="Minimize" @click="open = false">−</button>
        </header>

        <article v-for="item in items" :key="item.id">
          <span class="plan-guidance-label mono">{{ item.label }}</span>
          <h2>{{ item.title }}</h2>
          <p>{{ item.message }}</p>
          <p class="plan-guidance-rationale"><span aria-hidden="true">↳</span>{{ item.rationale }}</p>
          <button class="button" type="button" @click="review(item)">{{ item.actionLabel }} <span aria-hidden="true">↑</span></button>
        </article>
      </aside>

      <button
        v-else
        key="trigger"
        class="plan-guidance-trigger"
        type="button"
        aria-controls="plan-guidance-panel"
        :aria-expanded="false"
        @click="open = true"
      >
        <span class="plan-guidance-signal" aria-hidden="true"><i /></span>
        <span>Plan check</span>
        <b class="mono">{{ items.length }}</b>
      </button>
    </Transition>
  </div>
</template>

