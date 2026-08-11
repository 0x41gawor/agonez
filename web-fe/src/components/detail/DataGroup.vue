<script setup lang="ts">
defineProps<{ title: string; rows: Array<{ label: string; value: string; unit?: string }> }>()
</script>

<template>
  <section class="data-group panel">
    <h2 class="section-label">{{ title }}</h2>
    <dl>
      <div v-for="row in rows" :key="row.label">
        <dt>{{ row.label }}</dt>
        <dd class="mono">{{ row.value }}<small v-if="row.unit"> {{ row.unit }}</small></dd>
      </div>
    </dl>
  </section>
</template>
