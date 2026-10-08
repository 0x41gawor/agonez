<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'

import { executionApi } from '@/api/execution'
import ErrorState from '@/components/common/ErrorState.vue'
import ExecutionSkeleton from '@/components/execution/ExecutionSkeleton.vue'

const router = useRouter()
const loading = ref(true)
const error = ref<string | null>(null)
const empty = ref(false)

async function load(): Promise<void> {
  loading.value = true
  error.value = null
  try {
    const response = await executionApi.runs()
    const selected = response.items.find((run) => run.status === 'active')
      ?? response.items.find((run) => run.status === 'scheduled')
      ?? response.items[0]
    if (selected) {
      await router.replace({ name: 'execution-overview', params: { runId: selected.plan_run_id } })
      return
    }
    empty.value = true
  } catch (caught) {
    error.value = caught instanceof Error ? caught.message : null
  } finally {
    loading.value = false
  }
}

onMounted(() => void load())
</script>

<template>
  <div class="execution-landing page-wrap">
    <ExecutionSkeleton v-if="loading" :rows="5" />
    <ErrorState v-else-if="error" :title="$t('execution.run.loadError')" :message="error" @retry="load" />
    <section v-else-if="empty" class="inline-state panel">
      <span class="exec-empty-mark mono">RUN</span>
      <h1>{{ $t('execution.run.emptyTitle') }}</h1>
      <p>{{ $t('execution.run.emptyBody') }}</p>
      <RouterLink class="button primary" :to="{ name: 'execution-new-run' }">+ {{ $t('execution.run.new') }}</RouterLink>
    </section>
  </div>
</template>
