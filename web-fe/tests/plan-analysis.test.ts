import { defineComponent } from 'vue'
import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import type { MuscleContribution } from '@/api/plan-analysis-types'
import PlanAnalysis from '@/components/plans/analysis/PlanAnalysis.vue'
import MuscleSummary from '@/components/plans/analysis/MuscleSummary.vue'
import WorkoutAnalysis from '@/components/plans/analysis/WorkoutAnalysis.vue'
import { recoveryBandIntensity } from '@/features/plans/analysis'
import { analysisResult, largeMuscleProvenance } from './fixtures/analysis'
import { exercise, muscle } from './fixtures/plans'

const BodyViewerStub = defineComponent({
  name: 'BodyViewer',
  props: {
    selectedSlug: { type: String, default: null },
    vector: { type: Object, default: null },
    tooltipValues: { type: Object, default: null },
    tooltipValueLabel: { type: String, default: '' },
    tooltipValueUnit: { type: String, default: '' },
    mode: { type: String, default: '' },
  },
  emits: ['hover', 'select'],
  template: '<div class="body-viewer-stub" />',
})

function mountAnalysis(result = analysisResult()) {
  return mount(PlanAnalysis, {
    props: {
      phase: 'BEFORE',
      etuMode: 'ABSOLUTE',
      etuTimeBasis: 'MICROCYCLE',
      result,
      loading: false,
      error: null,
      stale: false,
      dirty: false,
      lockMismatch: false,
      selectedDay: result.timeline[0] ?? null,
      selectedDayId: result.timeline[0]?.day_id ?? null,
      muscleContributionsBySlug: new Map([
        [
          muscle.slug,
          result.contributions.filter(
            (item): item is MuscleContribution => item.type === 'MUSCLE',
          ),
        ],
      ]),
      jointContributionsBySlug: new Map(),
      muscles: [muscle],
      exercises: [exercise],
    },
    global: { stubs: { BodyViewer: BodyViewerStub } },
  })
}

describe('Plan Analysis presentation', () => {
  it('shows the frozen snapshot and preserves returned timeline order including rest', () => {
    const wrapper = mountAnalysis()

    expect(wrapper.text()).toContain('Default · Level 0')
    expect(wrapper.text()).toContain('None')
    expect(wrapper.findAll('.timeline-day').map((day) => day.text())).toEqual([
      expect.stringContaining('Push A workout'),
      expect.stringContaining('Rest'),
    ])
    expect(wrapper.findAll('.timeline-day')[1]?.classes()).toContain('rest')
  })

  it('groups a multi-week cycle and can normalize ETU to seven days', async () => {
    const base = analysisResult()
    const timeline = Array.from({ length: 14 }, (_, index) => {
      const source = base.timeline[index % base.timeline.length]!
      return {
        ...source,
        day_id: 100 + index,
        day_ordinal: index,
        weekday: (index % 7) + 1,
        hour_offset: index * 24,
        elapsed_hours_since_previous_entry: 24,
      }
    })
    const result = analysisResult({
      model_parameters: {
        ...base.model_parameters,
        microcycle_days: 14,
        microcycle_hours: 336,
        microcycle_weeks: 2,
        weekly_normalization_factor: 0.5,
      },
      plan_summary: {
        ...base.plan_summary,
        total_etu_scalar: 63,
        weekly_etu_scalar: 31.5,
        muscles: base.plan_summary.muscles.map((item) => ({
          ...item,
          total_etu: 49,
          weekly_etu: 24.5,
          etu_per_fcsa_cm2: 0.924,
          weekly_etu_per_fcsa_cm2: 0.462,
          intentional_etu: 24,
          weekly_intentional_etu: 12,
          incidental_etu: 16,
          weekly_incidental_etu: 8,
          unclassified_etu: 9,
          weekly_unclassified_etu: 4.5,
        })),
      },
      timeline,
    })
    const wrapper = mountAnalysis(result)

    expect(wrapper.findAll('.timeline-week-group')).toHaveLength(2)
    expect(wrapper.text()).toContain('14 days · 2 weeks')
    expect(wrapper.text()).toContain('Week 1')
    expect(wrapper.text()).toContain('Week 2')
    expect(wrapper.get('.analysis-overview-grid > div').text()).toContain('63')

    await wrapper.findAll('.snapshot-control-basis button')[1]!.trigger('click')
    expect(wrapper.emitted('update:etuTimeBasis')).toEqual([['WEEKLY']])
    await wrapper.setProps({ etuTimeBasis: 'WEEKLY' })

    expect(wrapper.get('.analysis-overview-grid > div').text()).toContain('31.5')
    expect(wrapper.text()).toContain('Weekly stimulus distribution')
    expect(wrapper.get('.primary-analysis-metric').text()).toContain('24.5')
  })

  it('emits timeline selection and keeps the returned Analysis inspectable under divergence', async () => {
    const wrapper = mountAnalysis()
    await wrapper.findAll('.timeline-day')[1]!.trigger('click')

    expect(wrapper.emitted('selectDay')).toEqual([[32]])
    expect(wrapper.text()).toContain('Recovery debt diverges')
    expect(wrapper.text()).toContain('Complete microcycle stimulus')
    expect(wrapper.text()).toContain('RECOVERY_DIVERGENCE')
    expect(wrapper.text()).toContain('MISSING_ETU_VECTOR')
  })

  it('uses returned BEFORE/AFTER recovery values locally without deriving them', async () => {
    const result = analysisResult()
    const wrapper = mount(WorkoutAnalysis, {
      props: {
        phase: 'BEFORE',
        etuMode: 'ABSOLUTE',
        selectedMuscleSlug: null,
        day: result.timeline[0]!,
        timeline: result.timeline,
        contributionsBySlug: new Map([
          [
            muscle.slug,
            result.contributions.filter(
              (item): item is MuscleContribution => item.type === 'MUSCLE',
            ),
          ],
        ]),
        muscles: [muscle],
        exercises: [exercise],
        summaries: result.plan_summary.muscles,
      },
      global: { stubs: { BodyViewer: BodyViewerStub } },
    })
    const beforeViewer = wrapper.findComponent(BodyViewerStub)

    expect(beforeViewer.props('tooltipValues')).toEqual({ [muscle.slug]: 18 })
    expect(beforeViewer.props('vector')).toEqual({
      [muscle.slug]: recoveryBandIntensity(18),
    })

    await wrapper.findAll('.phase-switch button')[1]!.trigger('click')
    expect(wrapper.emitted('update:phase')).toEqual([['AFTER']])
    await wrapper.setProps({ phase: 'AFTER' })

    expect(wrapper.findComponent(BodyViewerStub).props('tooltipValues')).toEqual({
      [muscle.slug]: 80,
    })
    expect(wrapper.findComponent(BodyViewerStub).props('vector')).toEqual({
      [muscle.slug]: 1,
    })
  })

  it('switches selected-day analysis to a workout-scoped stimulus explorer', async () => {
    const result = analysisResult()
    const contributions = result.contributions.filter(
      (item): item is MuscleContribution => item.type === 'MUSCLE',
    )
    const wrapper = mount(WorkoutAnalysis, {
      props: {
        phase: 'BEFORE',
        etuMode: 'ABSOLUTE',
        selectedMuscleSlug: null,
        day: result.timeline[0]!,
        timeline: result.timeline,
        contributionsBySlug: new Map([[muscle.slug, contributions]]),
        muscles: [muscle],
        exercises: [exercise],
        summaries: result.plan_summary.muscles,
      },
      global: { stubs: { BodyViewer: BodyViewerStub } },
    })

    await wrapper.findAll('.selected-day-tabs button')[1]!.trigger('click')

    expect(wrapper.find('.phase-switch').exists()).toBe(false)
    expect(wrapper.text()).toContain('Workout target bias')
    expect(wrapper.text()).toContain('31.5 total ETU')
    expect(wrapper.find('.workout-analysis-data').exists()).toBe(false)
    expect(wrapper.findComponent(BodyViewerStub).props('tooltipValues')).toEqual({
      [muscle.slug]: 24.5,
    })
    expect(wrapper.findComponent(BodyViewerStub).props('tooltipValueUnit')).toBe(
      'ETU/workout',
    )

    await wrapper.find('.stimulus-ranking-row').trigger('click')
    expect(wrapper.text()).toContain('D01')
    expect(wrapper.text()).toContain('Barbell Bench Press')
    expect(wrapper.text()).toContain('Primary progressive')

    await wrapper.findAll('.selected-day-toolbar .metric-switch button')[1]!.trigger('click')
    expect(wrapper.emitted('update:etuMode')).toEqual([['NORMALIZED']])
  })

  it('keeps workout stimulus unavailable on rest days and returns to recovery', async () => {
    const result = analysisResult()
    const wrapper = mount(WorkoutAnalysis, {
      props: {
        phase: 'BEFORE',
        etuMode: 'NORMALIZED',
        selectedMuscleSlug: null,
        day: result.timeline[0]!,
        timeline: result.timeline,
        contributionsBySlug: new Map(),
        muscles: [muscle],
        exercises: [exercise],
        summaries: result.plan_summary.muscles,
      },
      global: { stubs: { BodyViewer: BodyViewerStub } },
    })

    await wrapper.findAll('.selected-day-tabs button')[1]!.trigger('click')
    expect(wrapper.text()).toContain('Workout target bias')

    await wrapper.setProps({ day: result.timeline[1]! })

    expect(wrapper.findAll('.selected-day-tabs button')[1]!.attributes('disabled')).toBeDefined()
    expect(wrapper.find('.phase-switch').exists()).toBe(true)
    expect(wrapper.text()).not.toContain('Workout target bias')
  })

  it('renders backend muscle values and keeps all intent classes distinct', async () => {
    const result = analysisResult()
    const contributions = result.contributions.filter(
      (item): item is MuscleContribution => item.type === 'MUSCLE',
    )
    const wrapper = mount(MuscleSummary, {
      props: {
        mode: 'ABSOLUTE',
        selectedSlug: null,
        etuBasis: 'MICROCYCLE',
        weeklyNormalizationFactor: result.model_parameters.weekly_normalization_factor,
        timeline: result.timeline,
        summaries: result.plan_summary.muscles,
        contributionsBySlug: new Map([[muscle.slug, contributions]]),
        muscles: [muscle],
        exercises: [exercise],
      },
      global: { stubs: { BodyViewer: BodyViewerStub } },
    })

    expect(wrapper.get('.primary-analysis-metric').text()).toContain('24.5')
    expect(wrapper.get('.intent-stack').attributes('aria-label')).toContain('12 intentional')
    expect(wrapper.get('.intent-stack').attributes('aria-label')).toContain('8 incidental')
    expect(wrapper.get('.intent-stack').attributes('aria-label')).toContain('4.5 unclassified')

    const viewer = wrapper.findComponent(BodyViewerStub)
    expect(viewer.props('tooltipValues')).toEqual({ [muscle.slug]: 24.5 })
    expect(viewer.props('tooltipValueUnit')).toBe('ETU/cycle')

    await wrapper.findAll('.metric-switch button')[1]!.trigger('click')
    expect(wrapper.emitted('update:mode')).toEqual([['NORMALIZED']])
    await wrapper.setProps({ mode: 'NORMALIZED' })
    expect(wrapper.get('.primary-analysis-metric').text()).toContain('0.46')
  })

  it('renders joint recovery and backend contribution provenance on demand', async () => {
    const wrapper = mountAnalysis()
    expect(wrapper.text()).toContain('Glenohumeral joint')
    expect(wrapper.text()).toContain('9.25')
    expect(wrapper.text()).toContain('4.2')

    await wrapper.find('.stimulus-ranking-row').trigger('click')
    expect(wrapper.text()).toContain('Contribution provenance')
    expect(wrapper.text()).toContain('D01')
    expect(wrapper.text()).toContain('MON')
    expect(wrapper.text()).toContain('Push A workout')
    expect(wrapper.text()).toContain('Primary progressive')
    expect(wrapper.text()).toContain('Barbell Bench Press')
    expect(wrapper.text()).toContain('set records')
  })

  it('caps mounted provenance details for a 2,000-record response', async () => {
    const result = analysisResult({ contributions: largeMuscleProvenance() })
    const contributions = result.contributions as MuscleContribution[]
    const wrapper = mount(MuscleSummary, {
      props: {
        mode: 'ABSOLUTE',
        selectedSlug: muscle.slug,
        etuBasis: 'MICROCYCLE',
        weeklyNormalizationFactor: result.model_parameters.weekly_normalization_factor,
        timeline: result.timeline,
        summaries: result.plan_summary.muscles,
        contributionsBySlug: new Map([[muscle.slug, contributions]]),
        muscles: [muscle],
        exercises: [exercise],
      },
      global: { stubs: { BodyViewer: BodyViewerStub } },
    })

    expect(wrapper.findAll('.provenance-set-list > div').length).toBeLessThanOrEqual(288)
    expect(wrapper.text()).toContain('additional set records omitted')
  })

  it('uses a transport error state only when no result is available', async () => {
    const result = analysisResult()
    const wrapper = mountAnalysis(result)
    await wrapper.setProps({ error: 'Gateway unavailable' })
    expect(wrapper.text()).toContain('previous snapshot remains visible')
    expect(wrapper.text()).toContain('Push A workout')
  })

  it('marks saved-only snapshots out of date and offers a PLAN path', async () => {
    const wrapper = mountAnalysis()
    await wrapper.setProps({ stale: true, dirty: true })
    expect(wrapper.text()).toContain('Out of date')
    expect(wrapper.text()).toContain('Plan has unsaved changes')
    expect(wrapper.text()).toContain('Save PLAN')
  })

  it('does not render zero-heavy summaries when there are no training sessions', () => {
    const base = analysisResult()
    const result = analysisResult({
      timeline: [base.timeline[1]!],
    })
    const wrapper = mountAnalysis(result)

    expect(wrapper.text()).toContain('No timeline boundary is available')
    expect(wrapper.find('.muscle-summary-section').exists()).toBe(false)
    expect(wrapper.find('.joint-summary-section').exists()).toBe(false)
  })
})
