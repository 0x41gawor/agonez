<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'

import type { PlanGuidanceItem } from '@/features/plans/guidance'

const props = defineProps<{
  active: boolean
  items: PlanGuidanceItem[]
}>()

const emit = defineEmits<{
  review: [target: PlanGuidanceItem['target']]
}>()
const { t } = useI18n()

function itemCopy(item: PlanGuidanceItem, field: 'label' | 'title' | 'message' | 'rationale' | 'actionLabel'): string {
  if (item.id !== 'missing-rest-day') return item[field]
  const key = field === 'actionLabel' ? 'action' : field
  if (field === 'message') {
    return t(item.dayCount === 1 ? 'plans.guidance.missingRest.one' : 'plans.guidance.missingRest.many', { count: item.dayCount })
  }
  return t(`plans.guidance.missingRest.${key}`)
}

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
        :aria-label="$t('plans.guidance.aria')"
        @keydown.esc="open = false"
      >
        <header>
          <span class="plan-guidance-signal" aria-hidden="true"><i /></span>
          <div>
            <span class="eyebrow">{{ $t('plans.guidance.check') }}</span>
            <strong>{{ $t('plans.guidance.suggestions', { count: items.length }) }}</strong>
          </div>
          <button type="button" :aria-label="$t('plans.guidance.minimize')" :title="$t('plans.guidance.minimizeTitle')" @click="open = false">−</button>
        </header>

        <article v-for="item in items" :key="item.id">
          <span class="plan-guidance-label mono">{{ itemCopy(item, 'label') }}</span>
          <h2>{{ itemCopy(item, 'title') }}</h2>
          <p>{{ itemCopy(item, 'message') }}</p>
          <p class="plan-guidance-rationale"><span aria-hidden="true">↳</span>{{ itemCopy(item, 'rationale') }}</p>
          <button class="button" type="button" @click="review(item)">{{ itemCopy(item, 'actionLabel') }} <span aria-hidden="true">↑</span></button>
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
        <span>{{ $t('plans.guidance.check') }}</span>
        <b class="mono">{{ items.length }}</b>
      </button>
    </Transition>
  </div>
</template>
