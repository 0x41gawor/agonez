<script setup lang="ts">
import type { ProgressionModelCatalogItem } from '@/api/plan-types'

withDefaults(defineProps<{
  model: ProgressionModelCatalogItem
  closable?: boolean
  compact?: boolean
}>(), {
  closable: false,
  compact: false,
})

defineEmits<{ close: [] }>()
</script>

<template>
  <aside class="progression-model-info" :class="{ compact }">
    <header>
      <div>
        <span class="section-label">{{ model.name }}</span>
        <strong>{{ model.name_full }}</strong>
      </div>
      <button
        v-if="closable"
        type="button"
        :aria-label="$t('common.close')"
        @click="$emit('close')"
      >×</button>
    </header>
    <div class="progression-info-grid">
      <section>
        <span>{{ $t('plans.progression.whenToUse') }}</span>
        <p>{{ model.when_to_use }}</p>
      </section>
      <section>
        <span>{{ $t('plans.progression.howToApply') }}</span>
        <p>{{ model.how_to_apply }}</p>
      </section>
    </div>
    <small>{{ $t('plans.progression.metadataOnly') }}</small>
  </aside>
</template>

<style scoped>
.progression-model-info {
  margin-top: 7px;
  padding: 10px 11px;
  border: 1px solid var(--border);
  border-radius: 7px;
  background: color-mix(in srgb, var(--panel2) 55%, transparent);
}

.progression-model-info.compact {
  grid-column: 1 / -1;
  margin: 2px 5px 6px;
  border-color: var(--border2);
  background: color-mix(in srgb, var(--panel2) 72%, transparent);
}

.progression-model-info header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
  padding-bottom: 8px;
  border-bottom: 1px solid var(--border);
}

.progression-model-info header div {
  display: grid;
  gap: 2px;
}

.progression-model-info header strong {
  font-size: 11.5px;
}

.progression-model-info header button {
  border: 0;
  background: transparent;
  color: var(--text3);
}

.progression-info-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
  padding: 10px 0;
}

.progression-info-grid section > span {
  color: var(--text3);
  font-size: 9px;
  font-weight: 650;
  letter-spacing: 0.7px;
  text-transform: uppercase;
}

.progression-info-grid p {
  margin: 4px 0 0;
  color: var(--text2);
  font-size: 10.5px;
  line-height: 1.55;
}

.progression-model-info > small {
  color: var(--text3);
  font-size: 9.5px;
}

@media (max-width: 700px) {
  .progression-info-grid {
    grid-template-columns: 1fr;
  }
}
</style>
