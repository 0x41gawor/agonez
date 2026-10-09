import { describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { defineComponent } from 'vue'
import { createMemoryHistory, createRouter } from 'vue-router'

import { executionApi } from '@/api/execution'
import type { AnalysisQueue as AnalysisQueueDTO, ExerciseTraceResponse, LoadSeriesResponse } from '@/api/execution-types'
import AnalysisQueue from '@/components/execution/AnalysisQueue.vue'
import ExerciseTraceTable from '@/components/execution/ExerciseTraceTable.vue'
import LoadsChart from '@/components/execution/LoadsChart.vue'
import PrescriptionEditor from '@/components/execution/PrescriptionEditor.vue'
import SessionStatusMark from '@/components/execution/SessionStatusMark.vue'
import AppShell from '@/components/shell/AppShell.vue'
import { useExecutionCycleLabels } from '@/features/execution/cycle-labels'
import { i18n, setActiveLocale } from '@/i18n'
import router from '@/router'
import { useExecutionDraftsStore } from '@/stores/executionDrafts'

const next: NonNullable<ExerciseTraceResponse['next']> = {
  state: 'editable', blocked_reason: null,
  target: { session_id: 7, workout_trace_id: 2, scheduled_date: '2026-10-13', microcycle: { ordinal: 7, starts_on: '2026-10-13', ends_on: '2026-10-19', classification: 'normal', plan_revision_no: 2 }, session_status: 'scheduled' },
  basis: { exercise_performance_id: 11, microcycle_ordinal: 6, scheduled_date: '2026-10-06', status: 'finalized', execution_mode: 'as_prescribed' },
  plan_sets: [0, 1, 2].map((ordinal) => ({ ordinal, role: 'working', rep_min: 5, rep_max: 7, target_rir: 1 })),
  plan_comment: null,
  defaults: { from_previous_prescription: [67.5, 67.5, 67.5], from_previous_performance: [67.5, 67.5, 65], from_seed_run: null },
  prescription: null, suggestion: null,
}

const trace: ExerciseTraceResponse = {
  as_of: '2026-10-08',
  trace: {
    exercise_trace_id: 41,
    workout_trace: { workout_trace_id: 2, workout_name: 'Push A' },
    slot_ordinal: 0, display_name: 'Bench Press',
    current_plan: { plan_revision_no: 2, slot_role: 'Primary progressive', exercise: { exercise_id: 1, slug: 'bench_press', name: 'Bench Press', variant_label: 'Flat Bench' }, sets: next.plan_sets, plan_comment: null, progression_model: null, load_step_kg: null },
    continuity: { first_microcycle_ordinal: 1, revisions_spanned: [1, 2], continues_from: null, continued_by: null },
  },
  revision_transitions: [], exposures: [], next,
}

const queue: AnalysisQueueDTO = {
  as_of: '2026-10-08',
  target_microcycle: next.target!.microcycle,
  workouts: [{ workout_trace_id: 2, workout_name: 'Push A', day_ordinal: 0, target_session: { session_id: 7, scheduled_date: '2026-10-13', status: 'scheduled' }, basis_session: { session_id: 6, scheduled_date: '2026-10-06', microcycle_ordinal: 6 }, state: 'editable', blocked_reason: null, blocked_detail: null, prescription_completeness: 'partial', exercises: [{ exercise_trace_id: 41, slot_ordinal: 0, name: 'Bench Press', prescription_saved: false, last_summary: { microcycle_ordinal: 6, execution_mode: 'as_prescribed', top_load_kg: 67.5, reps: [7, 6, 5] } }] }],
}

describe('Execution critical workflows', () => {
  it('uses localized week labels only for seven-day plan runs', async () => {
    const CycleProbe = defineComponent({
      props: { duration: { type: Number, required: true } },
      setup(props) { return { cycle: useExecutionCycleLabels(() => props.duration) } },
      template: '<div :data-copy="cycle.routeCopy(\'execution.timeline.title\')">{{ cycle.label(6) }}|{{ cycle.shortLabel(6) }}|{{ cycle.text(\'execution.editor.title\', 6, { exercise: \'Bench Press\' }) }}</div>',
    })

    const weekly = mount(CycleProbe, { props: { duration: 7 } })
    expect(weekly.text()).toBe('Week 6|W6|Bench Press · W6')
    expect(weekly.attributes('data-copy')).toBe('execution.timeline.titleWeek')

    const nonWeekly = mount(CycleProbe, { props: { duration: 6 } })
    expect(nonWeekly.text()).toBe('Microcycle 6|MC6|Bench Press · MC6')
    expect(nonWeekly.attributes('data-copy')).toBe('execution.timeline.title')

    await setActiveLocale('pl', { persist: false })
    const localized = mount(CycleProbe, { props: { duration: 7 } })
    expect(localized.text()).toBe('Tydzień 6|T6|Bench Press · T6')
  })

  it('compiles the Analysis plan summary containing the literal @RIR notation', () => {
    expect(i18n.global.t('execution.analysis.plan', { sets: 3, min: 5, max: 7, rir: 1 }))
      .toBe('plan: 3 × 5–7 @RIR 1')
  })

  it('registers every bookmarkable Execution route', () => {
    const names = new Set(router.getRoutes().map((route) => route.name))
    for (const name of ['execution', 'execution-new-run', 'execution-overview', 'execution-analysis', 'execution-workout-trace', 'execution-timeline', 'execution-loads']) {
      expect(names.has(name)).toBe(true)
    }
  })

  it('shows Execution as a first-class active shell navigation item', async () => {
    const shellRouter = createRouter({
      history: createMemoryHistory(),
      routes: [
        { path: '/home', component: { template: '<div />' } },
        { path: '/atlas/exercises', component: { template: '<div />' } },
        { path: '/execution', component: { template: '<div />' } },
        { path: '/plans', component: { template: '<div />' } },
      ],
    })
    await shellRouter.push('/execution')
    await shellRouter.isReady()
    const wrapper = mount(AppShell, { slots: { default: '<div />' }, global: { plugins: [shellRouter] } })
    const link = wrapper.get('.main-nav a[href="/execution"]')
    expect(link.text()).toBe('Execution')
    expect(link.classes()).toContain('active')
  })

  it('keeps unsaved prescription drafts keyed by exercise trace', () => {
    const store = useExecutionDraftsStore()
    const draft = store.initialize(41, next)
    expect(draft.loads).toEqual(['67.5', '67.5', '67.5'])
    draft.loads[2] = '65'
    store.markDirty(41)
    expect(store.hasDirty).toBe(true)
    expect(store.initialize(41, next).loads[2]).toBe('65')
  })

  it('renders queue dirty state and changes the selected trace', async () => {
    const store = useExecutionDraftsStore()
    store.initialize(41, next).dirty = true
    const wrapper = mount(AnalysisQueue, { props: { queue, selectedTraceId: 41, drafts: store.drafts } })
    expect(wrapper.get('.queue-item').attributes('aria-current')).toBe('true')
    expect(wrapper.get('.queue-state').text()).toBe('●')
    await wrapper.get('.queue-item').trigger('click')
    expect(wrapper.emitted('select')).toEqual([[41]])
  })

  it('shows the backend-null load step as disabled while keeping direct inputs editable', () => {
    const store = useExecutionDraftsStore()
    const wrapper = mount(PrescriptionEditor, { props: { trace, draft: store.initialize(41, next), saving: false, errorCode: null } })
    expect(wrapper.findAll('.editor-action-row button').slice(-2).every((button) => button.attributes('disabled') !== undefined)).toBe(true)
    expect(wrapper.findAll('.load-input')).toHaveLength(3)
    expect(wrapper.get('.load-input').attributes('disabled')).toBeUndefined()
  })

  it('distinguishes missed and cancelled sessions by text and visual class', () => {
    const missed = mount(SessionStatusMark, { props: { status: 'missed' } })
    const cancelled = mount(SessionStatusMark, { props: { status: 'cancelled' } })
    expect(missed.text()).toBe('×')
    expect(cancelled.text()).toBe('—')
    expect(missed.classes()).toContain('is-missed')
    expect(cancelled.classes()).toContain('is-cancelled')
  })

  it('keeps analysis set columns compact instead of stretching each set across the workspace', () => {
    const store = useExecutionDraftsStore()
    const wrapper = mount(ExerciseTraceTable, { props: { trace, draft: store.initialize(41, next) } })
    expect(wrapper.get('.exercise-trace-table').attributes('style')).toContain('repeat(3, minmax(142px, 156px))')
    expect(wrapper.get('.exercise-trace-table').attributes('style')).toContain('minmax(320px, 1fr)')
  })

  it('breaks load chart paths across null substitution points', () => {
    const data: LoadSeriesResponse = {
      as_of: '2026-10-08', metric: 'top_set_load',
      x_domain: [1, 2, 3].map((ordinal) => ({ microcycle_ordinal: ordinal, starts_on: `2026-09-${String(ordinal).padStart(2, '0')}`, classification: 'normal', plan_revision_no: 1 })),
      series: [{ exercise_trace_id: 41, display_name: 'Bench Press', workout_trace_id: 2, workout_name: 'Push A', points: [
        { microcycle_ordinal: 1, date: '2026-09-01', value: 65, set_count: 3, reps: [7, 6, 5], status: 'finalized', execution_mode: 'as_prescribed' },
        { microcycle_ordinal: 2, date: '2026-09-08', value: null, set_count: 3, reps: [8, 8, 8], status: 'finalized', execution_mode: 'substituted' },
        { microcycle_ordinal: 3, date: '2026-09-15', value: 67.5, set_count: 3, reps: [7, 5, 5], status: 'finalized', execution_mode: 'as_prescribed' },
      ], first_value: 65, latest_value: 67.5, delta_pct: 3.8 }], workout_summaries: [],
    }
    const wrapper = mount(LoadsChart, { props: { data, selected: [41], scale: 'kg', focused: null } })
    expect(wrapper.findAll('path.series-line')).toHaveLength(2)
    expect(wrapper.findAll('circle.gap-point')).toHaveLength(1)
  })

  it('sends the exact save path/body and exposes stable error codes', async () => {
    const fetchMock = vi.fn().mockResolvedValue(new Response(JSON.stringify({ error: { code: 'stale_basis', message: 'Newer performance', details: {} } }), { status: 409, headers: { 'Content-Type': 'application/json' } }))
    vi.stubGlobal('fetch', fetchMock)
    const payload = { based_on_exercise_performance_id: 11, sets: [{ ordinal: 0, load_kg: 67.5, comment: null }], prescription_comment: null, expected_version: null }
    await expect(executionApi.savePrescription(3, 7, 41, payload)).rejects.toMatchObject({ status: 409, code: 'stale_basis' })
    expect(fetchMock.mock.calls[0]?.[0]).toContain('/api/v1/exec/plan-runs/3/sessions/7/exercise-prescriptions/41')
    expect(JSON.parse(String((fetchMock.mock.calls[0]?.[1] as RequestInit).body))).toEqual(payload)
    vi.unstubAllGlobals()
  })
})
