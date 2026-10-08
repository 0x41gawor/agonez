<script setup lang="ts">
import { computed, onMounted, provide, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import { executionApi } from '@/api/execution'
import type { PlanRunListItem, PlanRunOverview } from '@/api/execution-types'
import ErrorState from '@/components/common/ErrorState.vue'
import ExecutionSkeleton from '@/components/execution/ExecutionSkeleton.vue'
import { executionContextKey } from '@/features/execution/context'
import { executionDate } from '@/features/execution/format'

const props = defineProps<{ runId: string }>()
const route = useRoute()
const router = useRouter()
const numericRunId = computed(() => Number(props.runId))
const runIdRef = ref(numericRunId.value)
const overview = ref<PlanRunOverview | null>(null)
const runs = ref<PlanRunListItem[]>([])
const loading = ref(true)
const error = ref<string | null>(null)

const activeTab = computed(() => {
  if (route.name === 'execution-overview') return 'overview'
  if (route.name === 'execution-timeline') return 'timeline'
  if (route.name === 'execution-loads') return 'loads'
  return 'analysis'
})

async function load(): Promise<void> {
  loading.value = true
  error.value = null
  try {
    const [runOverview, runList] = await Promise.all([
      executionApi.overview(numericRunId.value),
      executionApi.runs(),
    ])
    overview.value = runOverview
    runs.value = runList.items
  } catch (caught) {
    error.value = caught instanceof Error ? caught.message : null
  } finally {
    loading.value = false
  }
}

function selectRun(event: Event): void {
  const id = Number((event.target as HTMLSelectElement).value)
  if (id && id !== numericRunId.value) void router.push({ name: 'execution-overview', params: { runId: id } })
}

provide(executionContextKey, { runId: runIdRef, overview, runs, loading, error, reload: load })
onMounted(() => void load())
watch(numericRunId, (value) => { runIdRef.value = value; void load() })
</script>

<template>
  <div class="execution-module">
    <header class="execution-runbar">
      <div class="execution-runbar-inner" :class="{ wide: activeTab !== 'overview' }">
        <div class="execution-run-summary">
          <span class="eyebrow">{{ $t('execution.run.eyebrow') }} · <b v-if="overview" :class="`run-${overview.run.status}`">● {{ $t(`execution.run.status.${overview.run.status}`) }}</b></span>
          <h1>{{ overview?.run.name ?? $t('execution.common.loading') }}</h1>
          <p v-if="overview">
            {{ $t('execution.run.from', { plan: `${overview.run.plan.code} · ${overview.run.plan.name}` }) }} ·
            {{ $t('execution.run.meta', { start: executionDate(overview.run.starts_on), end: executionDate(overview.run.ends_on, { day: '2-digit', month: 'short', year: 'numeric' }), count: overview.run.microcycle_count, days: overview.run.microcycle_duration_days }) }}
          </p>
        </div>
        <div class="execution-run-actions">
          <label class="sr-only" for="execution-run-select">{{ $t('execution.run.all', { count: runs.length }) }}</label>
          <select id="execution-run-select" class="exec-select" :value="numericRunId" @change="selectRun">
            <option v-for="run in runs" :key="run.plan_run_id" :value="run.plan_run_id">{{ run.name }} · {{ $t(`execution.run.status.${run.status}`) }}</option>
          </select>
          <RouterLink class="button primary" :to="{ name: 'execution-new-run' }">+ {{ $t('execution.run.new') }}</RouterLink>
        </div>
      </div>
      <nav class="execution-tabs" :aria-label="$t('execution.nav')">
        <RouterLink :to="{ name: 'execution-overview', params: { runId: numericRunId } }" :aria-current="activeTab === 'overview' ? 'page' : undefined">{{ $t('execution.tabs.overview') }}</RouterLink>
        <RouterLink :to="{ name: 'execution-analysis', params: { runId: numericRunId } }" :aria-current="activeTab === 'analysis' ? 'page' : undefined">{{ $t('execution.tabs.analysis') }}<span v-if="overview" class="tab-count"> · {{ overview.analysis_readiness.workouts.reduce((sum, item) => sum + Math.max(0, item.exercises_total - item.exercises_prescribed), 0) }}</span></RouterLink>
        <RouterLink :to="{ name: 'execution-timeline', params: { runId: numericRunId } }" :aria-current="activeTab === 'timeline' ? 'page' : undefined">{{ $t('execution.tabs.timeline') }}</RouterLink>
        <RouterLink :to="{ name: 'execution-loads', params: { runId: numericRunId } }" :aria-current="activeTab === 'loads' ? 'page' : undefined">{{ $t('execution.tabs.loads') }}</RouterLink>
      </nav>
    </header>
    <ExecutionSkeleton v-if="loading" class="page-wrap" />
    <ErrorState v-else-if="error || !overview" class="page-wrap" :title="$t('execution.run.loadError')" :message="error || $t('execution.run.listError')" @retry="load" />
    <RouterView v-else />
  </div>
</template>
