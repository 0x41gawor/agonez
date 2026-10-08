<script setup lang="ts">
import { computed, inject, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'

import { executionApi } from '@/api/execution'
import ClassificationTag from '@/components/execution/ClassificationTag.vue'
import SessionStatusMark from '@/components/execution/SessionStatusMark.vue'
import { executionContextKey } from '@/features/execution/context'
import { executionDate, executionDateTime, loadValue } from '@/features/execution/format'

const context = inject(executionContextKey)!
const router = useRouter()
const { t } = useI18n()
const observation = ref('')
const posting = ref(false)
const postError = ref<string | null>(null)
const data = computed(() => context.overview.value!)
const current = computed(() => data.value.microcycles.find((mc) => mc.is_current) ?? null)
const due = computed(() => data.value.attendance.reduce((sum, row) => sum + row.due, 0))
const completed = computed(() => data.value.attendance.reduce((sum, row) => sum + row.completed, 0))
const firstReady = computed(() => data.value.analysis_readiness.workouts.find((item) => item.state === 'editable'))
function flagLabel(flag: string): string { const key = `execution.analysis.flags.${flag}`; return t(key) === key ? flag : t(key) }

function statusToday(date: string): boolean {
  return date === data.value.as_of
}

function goTimeline(sessionId?: number): void {
  void router.push(sessionId
    ? { name: 'execution-timeline', params: { runId: context.runId.value }, query: { session: sessionId } }
    : { name: 'execution-timeline', params: { runId: context.runId.value } })
}

async function logObservation(): Promise<void> {
  if (!observation.value.trim() || posting.value) return
  posting.value = true
  postError.value = null
  try {
    await executionApi.createEvent(context.runId.value, { event_type: 'observation', date: data.value.as_of, body: observation.value.trim(), session_id: null, exercise_trace_id: null, metadata: {} })
    observation.value = ''
    await context.reload()
  } catch (caught) {
    postError.value = caught instanceof Error ? caught.message : null
  } finally {
    posting.value = false
  }
}
</script>

<template>
  <div class="execution-overview">
    <section class="panel exec-position-panel">
      <div class="exec-position-head">
        <div class="exec-position-copy">
          <span class="eyebrow">{{ $t('execution.overview.where') }}</span>
          <strong v-if="data.position.microcycle_ordinal">
            {{ $t('execution.overview.position', { current: data.position.microcycle_ordinal, total: data.run.microcycle_count, day: data.position.day_in_microcycle, days: data.run.microcycle_duration_days }) }}
            <small>{{ $t('execution.overview.positionSub', { runDay: data.position.run_day, runDays: data.position.run_days_total, left: data.position.days_left }) }}</small>
          </strong>
        </div>
        <div class="exec-status-legend">
          <span v-for="status in ['completed', 'in_progress', 'scheduled', 'missed', 'cancelled'] as const" :key="status"><SessionStatusMark :status="status" compact />{{ $t(`execution.status.${status}`) }}</span>
        </div>
      </div>
      <div class="exec-microcycle-strip">
        <button v-for="microcycle in data.microcycles" :key="microcycle.ordinal" type="button" class="exec-microcycle-card" :class="{ current: microcycle.is_current, revision: microcycle.revision_changed_here }" @click="goTimeline()">
          <span class="exec-mc-title mono">MC{{ microcycle.ordinal }} <ClassificationTag :classification="microcycle.classification" /><b v-if="microcycle.is_current">{{ $t('execution.common.today') }}</b></span>
          <span class="exec-mc-dates mono">{{ executionDate(microcycle.starts_on) }}–{{ executionDate(microcycle.ends_on) }}</span>
          <span class="exec-pips">
            <SessionStatusMark v-for="session in microcycle.sessions" :key="session.session_id" :status="session.status" :completion-mode="session.completion_mode" :today="statusToday(session.scheduled_date)" compact />
          </span>
          <span v-if="microcycle.revision_changed_here" class="exec-revision-tick mono">r{{ microcycle.plan_revision_no }}</span>
        </button>
      </div>
    </section>

    <div class="execution-overview-grid">
      <section class="panel exec-overview-panel">
        <header class="exec-panel-header">
          <div><span class="eyebrow">{{ $t('execution.overview.thisMicrocycle') }}<template v-if="current"> · MC{{ current.ordinal }}</template></span><h2>{{ $t('execution.overview.sessions') }}</h2></div>
          <button class="exec-link-button" type="button" @click="goTimeline()">{{ $t('execution.overview.fullCalendar') }} →</button>
        </header>
        <button v-for="session in data.current_microcycle_sessions" :key="session.session_id" type="button" class="exec-list-row exec-session-row" @click="goTimeline(session.session_id)">
          <span class="mono">{{ executionDate(session.scheduled_date, { weekday: 'short', day: '2-digit', month: 'short' }) }}</span>
          <span><b>{{ session.workout_name }}</b><small v-if="session.status === 'completed'">{{ executionDateTime(session.completed_at) }} · {{ session.exercise_count }} · {{ $t('execution.status.completed') }}</small><small v-else-if="session.status === 'in_progress'">{{ executionDateTime(session.started_at) }} · {{ session.performance?.synced_exercise_count ?? 0 }}/{{ session.exercise_count }}</small><small v-else>{{ $t(`execution.status.${session.status}`) }}</small></span>
          <span class="exec-session-state mono">{{ $t(`execution.status.${statusToday(session.scheduled_date) && session.status === 'scheduled' ? 'today' : session.status}`) }}</span>
        </button>
        <p v-if="!data.current_microcycle_sessions.length" class="exec-empty-row">{{ $t('execution.overview.noCurrentSessions') }}</p>
        <p class="exec-panel-note">{{ $t('execution.overview.readOnlyDraft') }}</p>
      </section>

      <div class="exec-overview-middle">
        <section class="panel exec-overview-panel">
          <header class="exec-panel-header">
            <div><span class="eyebrow accent">{{ $t('execution.overview.analysisEyebrow', { mc: data.analysis_readiness.target_microcycle_ordinal ?? '—' }) }}</span><h2>{{ $t('execution.overview.prescriptions') }}</h2></div>
            <RouterLink v-if="firstReady" class="button primary" :to="{ name: 'execution-analysis', params: { runId: context.runId.value } }">{{ $t('execution.overview.continue', { workout: firstReady.workout_name }) }} →</RouterLink>
          </header>
          <RouterLink v-for="workout in data.analysis_readiness.workouts" :key="workout.workout_trace_id" class="exec-list-row exec-readiness-row" :to="{ name: 'execution-workout-trace', params: { runId: context.runId.value, workoutTraceId: workout.workout_trace_id } }">
            <b>{{ workout.workout_name }}</b>
            <span>{{ workout.state === 'editable' ? $t('execution.analysis.ready') : $t(`execution.blocked.${workout.blocked_reason ?? 'unknown'}`) }}</span>
            <span class="mono" :class="workout.state">{{ workout.state === 'editable' ? $t('execution.overview.saved', { saved: workout.exercises_prescribed, total: workout.exercises_total }) : $t('execution.common.locked') }}</span>
          </RouterLink>
        </section>

        <section class="panel exec-overview-panel">
          <header class="exec-panel-header">
            <div><span class="eyebrow">{{ data.latest_exposure ? $t('execution.overview.latest', { workout: data.latest_exposure.workout_name, date: executionDate(data.latest_exposure.scheduled_date) }) : $t('execution.overview.latest', { workout: '—', date: '—' }) }}</span><h2>{{ $t('execution.overview.comparison') }}</h2></div>
          </header>
          <div v-if="data.latest_exposure" class="exec-comparison-table" role="table">
            <div class="exec-comparison-head mono" role="row"><span>{{ $t('execution.overview.exercise') }}</span><span>{{ $t('execution.overview.prescribed') }}</span><span>{{ $t('execution.overview.performed') }}</span><span>{{ $t('execution.overview.note') }}</span></div>
            <RouterLink v-for="exercise in data.latest_exposure.exercises" :key="exercise.exercise_trace_id" class="exec-comparison-row" :to="{ name: 'execution-analysis', params: { runId: context.runId.value }, query: { trace: exercise.exercise_trace_id } }">
              <b>{{ exercise.name }}</b>
              <span class="mono prescribed">{{ loadValue(exercise.prescribed_summary.top_load_kg) }} · {{ exercise.prescribed_summary.set_count }} × {{ exercise.prescribed_summary.rep_min }}–{{ exercise.prescribed_summary.rep_max }} @{{ exercise.prescribed_summary.target_rir }}</span>
              <span class="mono">{{ exercise.performed_reps.join(' · ') }} <small>@{{ exercise.performed_rir.join('/') }}</small></span>
              <span>{{ exercise.flags.map(flagLabel).join(' · ') || '—' }}</span>
            </RouterLink>
          </div>
          <p v-else class="exec-empty-row">{{ $t('execution.overview.noExposure') }}</p>
        </section>
      </div>

      <aside class="exec-overview-side">
        <section class="panel exec-adherence">
          <span class="eyebrow">{{ $t('execution.overview.adherence') }} · {{ completed }}/{{ due }}</span>
          <h2>{{ $t('execution.overview.didPlanHappen') }}</h2>
          <div v-for="row in data.attendance" :key="row.microcycle_ordinal" class="exec-attendance-row" :title="`${row.missed} ${$t('execution.status.missed')} · ${row.cancelled} ${$t('execution.status.cancelled')}`">
            <span class="mono">MC{{ row.microcycle_ordinal }}</span><span class="exec-attendance-bar"><i :class="{ missed: row.missed, cancelled: row.cancelled }" :style="{ width: `${(row.ratio ?? 0) * 100}%` }" /></span><span class="mono">{{ row.completed }}/{{ row.due }}</span>
          </div>
        </section>
        <section class="panel exec-overview-panel">
          <header class="exec-panel-header"><div><span class="eyebrow">{{ $t('execution.overview.journal') }}</span><h2>{{ $t('execution.overview.latestEvents') }}</h2></div><button class="exec-link-button" type="button" @click="goTimeline()">{{ $t('execution.overview.allEvents', { count: data.latest_events.length }) }} →</button></header>
          <div v-if="data.latest_events.length">
            <article v-for="event in data.latest_events" :key="event.event_id" class="exec-event-row"><i :class="`event-${event.event_type}`" /><span><b>{{ event.title }}</b><small>{{ event.body ?? '—' }}</small></span><time class="mono">{{ executionDate(event.date) }}<template v-if="event.microcycle_ordinal"> · MC{{ event.microcycle_ordinal }}</template></time></article>
          </div>
          <p v-else class="exec-empty-row">{{ $t('execution.overview.noEvents') }}</p>
          <form class="exec-observation-form" @submit.prevent="logObservation"><label class="sr-only" for="overview-observation">{{ $t('execution.overview.observationPlaceholder') }}</label><input id="overview-observation" v-model="observation" class="exec-input" :placeholder="$t('execution.overview.observationPlaceholder')" /><button class="button" type="submit" :disabled="!observation.trim() || posting">{{ $t('execution.overview.log') }}</button></form>
          <p v-if="postError" class="exec-inline-error" role="alert">{{ postError }}</p>
        </section>
      </aside>
    </div>
  </div>
</template>
