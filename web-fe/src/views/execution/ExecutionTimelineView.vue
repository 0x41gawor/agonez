<script setup lang="ts">
import { computed, inject, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import { ApiError } from '@/api/client'
import { executionApi } from '@/api/execution'
import type { CalendarResponse, CalendarSession, EventDTO, EventListResponse, MicrocycleTimeline, SessionStatus, TimelineMicrocycle } from '@/api/execution-types'
import ErrorState from '@/components/common/ErrorState.vue'
import ClassificationTag from '@/components/execution/ClassificationTag.vue'
import ExecutionSkeleton from '@/components/execution/ExecutionSkeleton.vue'
import SessionStatusMark from '@/components/execution/SessionStatusMark.vue'
import { executionContextKey } from '@/features/execution/context'
import { useExecutionCycleLabels } from '@/features/execution/cycle-labels'
import { executionDate, executionDateTime, loadValue, weekdayShort } from '@/features/execution/format'

const context = inject(executionContextKey)!
const cycle = useExecutionCycleLabels()
const route = useRoute()
const router = useRouter()
const timeline = ref<MicrocycleTimeline | null>(null)
const calendar = ref<CalendarResponse | null>(null)
const events = ref<EventListResponse | null>(null)
const loading = ref(true)
const error = ref<string | null>(null)
const actionError = ref<string | null>(null)
const noteEditing = ref<number | null>(null)
const noteDraft = ref('')
const eventFilter = ref<'all' | 'plan' | 'phases' | 'breaks' | 'notes'>('all')
const expandedEvent = ref<number | null>(null)
const composerType = ref<'observation' | 'vacation' | 'training_break'>('observation')
const composerDate = ref('')
const composerText = ref('')
const confirmAction = ref<'cancel' | 'reclassify' | null>(null)
const reason = ref('')
const logEvent = ref(false)
const editingEvent = ref<number | null>(null)
const editingEventBody = ref('')

const axis = computed(() => route.query.axis === 'weeks' ? 'weeks' : 'microcycles')
const selectedId = computed(() => Number(route.query.session) || null)
const selected = computed(() => calendar.value?.sessions.find((session) => session.session_id === selectedId.value) ?? null)
const filteredEvents = computed(() => (events.value?.items ?? []).filter((event) => {
  if (eventFilter.value === 'all') return true
  if (eventFilter.value === 'plan') return event.event_type === 'plan_revision_changed'
  if (eventFilter.value === 'phases') return ['deload_started', 'reload_started'].includes(event.event_type)
  if (eventFilter.value === 'breaks') return ['vacation', 'training_break'].includes(event.event_type)
  return ['observation', 'personal_record'].includes(event.event_type)
}))
const calendarWeeks = computed(() => {
  const sessions = calendar.value?.sessions ?? []
  if (!sessions.length) return []
  const byDate = new Map(sessions.map((session) => [session.scheduled_date, session]))
  const first = new Date(`${context.overview.value?.run.starts_on ?? sessions[0]?.scheduled_date}T12:00:00Z`)
  const last = new Date(`${context.overview.value?.run.ends_on ?? sessions[sessions.length - 1]?.scheduled_date}T12:00:00Z`)
  const monday = new Date(first); monday.setUTCDate(first.getUTCDate() - ((first.getUTCDay() + 6) % 7))
  const weeks: Array<{ starts: string; days: Array<{ date: string; session: CalendarSession | null }> }> = []
  for (let cursor = new Date(monday); cursor <= last; cursor.setUTCDate(cursor.getUTCDate() + 7)) {
    const days = Array.from({ length: 7 }, (_, index) => { const date = new Date(cursor); date.setUTCDate(cursor.getUTCDate() + index); const iso = date.toISOString().slice(0, 10); return { date: iso, session: byDate.get(iso) ?? null } })
    weeks.push({ starts: days[0]?.date ?? '', days })
  }
  return weeks
})

async function load(): Promise<void> {
  loading.value = true; error.value = null
  try { const [timelineResponse, calendarResponse, eventResponse] = await Promise.all([executionApi.timeline(context.runId.value), executionApi.calendar(context.runId.value), executionApi.events(context.runId.value)]); timeline.value = timelineResponse; calendar.value = calendarResponse; events.value = eventResponse; composerDate.value ||= timelineResponse.as_of }
  catch (caught) { error.value = caught instanceof Error ? caught.message : null }
  finally { loading.value = false }
}
function setAxis(value: 'microcycles' | 'weeks'): void { void router.replace({ query: { ...route.query, axis: value === 'weeks' ? 'weeks' : undefined } }) }
function selectSession(id: number | null): void { const query = { ...route.query }; if (id) query.session = String(id); else delete query.session; void router.replace({ query }) }
function startNote(mc: TimelineMicrocycle): void { noteEditing.value = mc.ordinal; noteDraft.value = mc.notes ?? '' }
async function saveMicrocycle(mc: TimelineMicrocycle, classification?: TimelineMicrocycle['classification']): Promise<void> {
  actionError.value = null
  try { await executionApi.updateMicrocycle(context.runId.value, mc.ordinal, { ...(classification ? { classification } : { notes: noteDraft.value.trim() || null }), expected_version: mc.version }); noteEditing.value = null; await load() }
  catch (caught) { actionError.value = caught instanceof ApiError && caught.code === 'microcycle_started' ? caught.message : caught instanceof Error ? caught.message : null }
}
async function updateSelected(status: SessionStatus): Promise<void> {
  if (!selected.value) return
  actionError.value = null
  try { await executionApi.updateSession(context.runId.value, selected.value.session_id, { status, reason: reason.value.trim() || null, log_event: logEvent.value }); confirmAction.value = null; reason.value = ''; await load() }
  catch (caught) { actionError.value = caught instanceof Error ? caught.message : null }
}
async function createEvent(): Promise<void> {
  if (!composerText.value.trim()) return
  actionError.value = null
  try { await executionApi.createEvent(context.runId.value, { event_type: composerType.value, date: composerDate.value, body: composerText.value.trim(), session_id: null, exercise_trace_id: null, metadata: {} }); composerText.value = ''; await load() }
  catch (caught) { actionError.value = caught instanceof Error ? caught.message : null }
}
async function removeEvent(event: EventDTO): Promise<void> { if (event.source !== 'user') return; try { await executionApi.deleteEvent(context.runId.value, event.event_id); await load() } catch (caught) { actionError.value = caught instanceof Error ? caught.message : null } }
function startEventEdit(event: EventDTO): void { editingEvent.value = event.event_id; editingEventBody.value = event.body ?? '' }
async function saveEvent(event: EventDTO): Promise<void> { try { await executionApi.updateEvent(context.runId.value, event.event_id, { body: editingEventBody.value.trim() || null }); editingEvent.value = null; await load() } catch (caught) { actionError.value = caught instanceof Error ? caught.message : null } }
function classificationFor(date: string): string | null { return calendar.value?.microcycle_bounds.find((bound) => date >= bound.starts_on && date <= bound.ends_on)?.classification ?? null }

onMounted(() => void load())
</script>

<template>
  <div class="timeline-view exec-page">
    <ExecutionSkeleton v-if="loading" :rows="10" />
    <ErrorState v-else-if="error || !timeline || !calendar || !events" :title="$t('execution.timeline.loadError')" :message="error || $t('execution.timeline.loadError')" @retry="load" />
    <template v-else>
      <header class="timeline-toolbar"><div><span class="eyebrow">{{ $t(cycle.routeCopy('execution.timeline.eyebrow')) }}</span><h1>{{ $t(cycle.routeCopy('execution.timeline.title'), { count: timeline.microcycles.length, start: executionDate(context.overview.value!.run.starts_on), end: executionDate(context.overview.value!.run.ends_on) }) }}</h1><p>{{ $t(cycle.routeCopy(axis === 'weeks' ? 'execution.timeline.helpWeeks' : 'execution.timeline.helpMicrocycles')) }}</p></div><div class="exec-segmented" role="radiogroup" :aria-label="$t('execution.timeline.axis')"><button type="button" role="radio" :aria-checked="axis === 'microcycles'" @click="setAxis('microcycles')">{{ $t(cycle.routeCopy('execution.timeline.microcycles')) }}</button><button type="button" role="radio" :aria-checked="axis === 'weeks'" @click="setAxis('weeks')">{{ $t('execution.timeline.weeks') }}</button></div></header>
      <p v-if="actionError" class="exec-inline-error" role="alert">{{ actionError }}</p>
      <div class="timeline-layout">
        <section class="timeline-grid-area">
          <div v-if="axis === 'microcycles'" class="timeline-grid-scroll panel">
            <table class="timeline-grid"><thead><tr><th>{{ $t(cycle.routeCopy('execution.timeline.microcycles')) }}</th><th v-for="day in timeline.day_columns" :key="day.day_ordinal"><span>D{{ day.day_ordinal + 1 }}</span><small>{{ day.workout_name ?? '—' }}</small></th><th>{{ $t('execution.timeline.attendance') }}</th><th>{{ $t('execution.timeline.volume') }}</th><th>{{ $t('execution.common.marker') }}</th></tr></thead><tbody><tr v-for="mc in timeline.microcycles" :key="mc.ordinal" :class="{ current: mc.is_current, revision: mc.revision_changed_here }"><th><span><b class="mono">{{ cycle.shortLabel(mc.ordinal) }}</b><ClassificationTag :classification="mc.classification" /></span><small class="mono">{{ executionDate(mc.starts_on) }}–{{ executionDate(mc.ends_on) }} · r{{ mc.plan_revision_no }}</small><span v-if="noteEditing === mc.ordinal" class="timeline-note-editor"><textarea v-model="noteDraft" class="exec-textarea" :placeholder="cycle.text('execution.timeline.notePlaceholder', mc.ordinal)" /><button class="button" type="button" @click="saveMicrocycle(mc)">{{ $t('execution.timeline.saveNote') }}</button><button class="button ghost" type="button" @click="noteEditing = null">{{ $t('execution.common.cancel') }}</button></span><button v-else type="button" class="timeline-note" @click="startNote(mc)">{{ mc.notes || $t('execution.timeline.note') }}</button><span class="classification-actions"><button type="button" :disabled="mc.classification === 'deload'" @click="saveMicrocycle(mc, 'deload')">{{ $t('execution.classification.deload') }}</button><button type="button" :disabled="mc.classification === 'reload'" @click="saveMicrocycle(mc, 'reload')">{{ $t('execution.classification.reload') }}</button></span></th><td v-for="day in mc.days" :key="day.day_ordinal"><button v-if="day.session" type="button" class="timeline-session-cell" :class="[`is-${day.session.status}`, { selected: day.session.session_id === selectedId, fallback: day.session.completion_mode === 'fallback' }]" :aria-pressed="day.session.session_id === selectedId" @click="selectSession(day.session.session_id)"><span>{{ day.session.workout_name }}</span><small class="mono">{{ executionDate(day.date, { day: '2-digit', month: 'short' }) }}</small><SessionStatusMark :status="day.session.status" :completion-mode="day.session.completion_mode" :today="day.date === timeline.as_of" compact /></button><span v-else class="timeline-rest">—</span></td><td class="mono">{{ mc.attendance.completed }}/{{ mc.attendance.due }}<small v-if="mc.attendance.missed">{{ mc.attendance.missed }} × {{ $t('execution.status.missed') }}</small><small v-if="mc.attendance.cancelled">{{ mc.attendance.cancelled }} × {{ $t('execution.status.cancelled') }}</small></td><td class="mono">{{ loadValue(mc.volume_load_kg) }}</td><td class="mono">—</td></tr></tbody></table>
          </div>
          <div v-else class="week-calendar panel"><div class="week-calendar-head"><span>{{ $t('execution.timeline.weeks') }}</span><span v-for="day in 7" :key="day" class="mono">{{ weekdayShort(day - 1) }}</span></div><div v-for="week in calendarWeeks" :key="week.starts" class="week-calendar-row"><strong class="mono">{{ executionDate(week.starts) }}</strong><div v-for="day in week.days" :key="day.date" :class="['week-day', `class-${classificationFor(day.date)}`]"><small class="mono">{{ executionDate(day.date, { day: '2-digit', month: 'short' }) }}</small><button v-if="day.session" type="button" class="timeline-session-cell" :class="[`is-${day.session.status}`, { selected: day.session.session_id === selectedId, fallback: day.session.completion_mode === 'fallback' }]" :aria-pressed="day.session.session_id === selectedId" @click="selectSession(day.session.session_id)"><span>{{ day.session.workout_name }}</span><SessionStatusMark :status="day.session.status" :completion-mode="day.session.completion_mode" :today="day.date === calendar.as_of" compact /></button></div></div></div>
        </section>
        <aside class="timeline-rail">
          <section class="session-details">
            <button v-if="selected" class="session-close" type="button" :aria-label="$t('execution.common.close')" @click="selectSession(null)">×</button>
            <template v-if="selected"><span class="eyebrow">{{ cycle.text('execution.timeline.session', selected.microcycle_ordinal, { day: selected.day_ordinal + 1 }) }}</span><h2>{{ selected.workout_name }}</h2><p><SessionStatusMark :status="selected.status" :completion-mode="selected.completion_mode" /> {{ $t(`execution.status.${selected.status}`) }}<template v-if="selected.completion_mode"> · {{ $t(`execution.completion.${selected.completion_mode}`) }}</template></p><p>{{ $t('execution.timeline.prescription', { state: selected.prescription_completeness }) }}</p><div class="session-actions"><RouterLink class="button" :to="{ name: 'execution-workout-trace', params: { runId: context.runId.value, workoutTraceId: selected.workout_trace_id } }">{{ $t('execution.analysis.workoutTrace') }}</RouterLink><button v-if="selected.status === 'scheduled'" class="button" type="button" @click="confirmAction = 'cancel'">{{ $t('execution.timeline.cancelSession') }}</button><button v-if="selected.status === 'missed'" class="button" type="button" @click="confirmAction = 'reclassify'">{{ $t('execution.timeline.reclassify') }}</button><button v-if="selected.status === 'cancelled'" class="button" type="button" :disabled="selected.scheduled_date < calendar.as_of" :title="selected.scheduled_date < calendar.as_of ? $t('execution.timeline.restorePast') : undefined" @click="updateSelected('scheduled')">{{ $t('execution.timeline.restore') }}</button></div><form v-if="confirmAction" class="session-confirm" @submit.prevent="updateSelected('cancelled')"><label>{{ $t('execution.timeline.reason') }}<input v-model="reason" class="exec-input" :placeholder="$t('execution.timeline.reasonPlaceholder')" /></label><label><input v-model="logEvent" type="checkbox" />{{ $t('execution.timeline.logEvent') }}</label><div><button class="button primary" type="submit">{{ $t('execution.timeline.confirm') }}</button><button class="button ghost" type="button" @click="confirmAction = null">{{ $t('execution.common.cancel') }}</button></div></form></template>
            <p v-else>{{ $t('execution.timeline.selectSession') }}</p>
          </section>
          <section class="journal-panel"><header><span class="eyebrow">{{ $t('execution.overview.journal') }} · {{ events.items.length }}</span><h2>{{ $t('execution.timeline.journal') }}</h2></header><div class="journal-filters"><button v-for="filter in ['all', 'plan', 'phases', 'breaks', 'notes'] as const" :key="filter" type="button" :aria-pressed="eventFilter === filter" @click="eventFilter = filter">{{ $t(`execution.timeline.filters.${filter}`) }}</button></div><article v-for="event in filteredEvents" :key="event.event_id" class="journal-event"><button type="button" @click="expandedEvent = expandedEvent === event.event_id ? null : event.event_id"><time class="mono">{{ executionDate(event.date) }}</time><span><b>{{ event.title }}</b><small>{{ event.body ?? '—' }}</small></span><i>{{ expandedEvent === event.event_id ? '▾' : '▸' }}</i></button><div v-if="expandedEvent === event.event_id" class="journal-event-detail"><p>{{ executionDateTime(event.occurred_at) }} · {{ $t(`execution.timeline.${event.source}`) }}<template v-if="event.microcycle_ordinal"> · {{ cycle.shortLabel(event.microcycle_ordinal) }}</template></p><template v-if="event.source === 'user'"><textarea v-if="editingEvent === event.event_id" v-model="editingEventBody" class="exec-textarea" /><button v-if="editingEvent === event.event_id" type="button" @click="saveEvent(event)">{{ $t('execution.common.save') }}</button><button v-else type="button" @click="startEventEdit(event)">{{ $t('execution.common.edit') }}</button><button type="button" @click="removeEvent(event)">{{ $t('common.remove') }}</button></template></div></article><p v-if="!filteredEvents.length" class="exec-empty-row">{{ $t('execution.timeline.noEvents') }}</p><form class="journal-composer" @submit.prevent="createEvent"><label class="sr-only" for="journal-event-type">{{ $t('execution.timeline.eventType') }}</label><select id="journal-event-type" v-model="composerType" class="exec-select"><option value="observation">{{ $t('execution.timeline.eventTypes.observation') }}</option><option value="vacation">{{ $t('execution.timeline.eventTypes.vacation') }}</option><option value="training_break">{{ $t('execution.timeline.eventTypes.training_break') }}</option></select><label class="sr-only" for="journal-event-date">{{ $t('execution.timeline.date') }}</label><input id="journal-event-date" v-model="composerDate" class="exec-input" type="date" /><label class="sr-only" for="journal-event-text">{{ $t('execution.timeline.text') }}</label><textarea id="journal-event-text" v-model="composerText" class="exec-textarea" :placeholder="$t('execution.timeline.eventPlaceholder')" /><button class="button primary" type="submit" :disabled="!composerText.trim()">{{ $t('execution.timeline.log') }}</button></form></section>
        </aside>
      </div>
    </template>
  </div>
</template>
