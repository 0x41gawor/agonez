import { describe, expect, it } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createMemoryHistory, createRouter } from 'vue-router'

import type { ExerciseListItem, MuscleListItem } from '@/api/types'
import AtlasCardGrid from '@/components/atlas/AtlasCardGrid.vue'
import ExerciseTable from '@/components/atlas/ExerciseTable.vue'
import MuscleTable from '@/components/atlas/MuscleTable.vue'

const exercise: ExerciseListItem = {
  slug: 'barbell_bench_press',
  name: 'Bench Press',
  name_full: 'Barbell Bench Press',
  body_part: 'Upper',
  target_category: 'Chest_Sternal',
  mechanics_tier: 'Heavy_Compound',
  resistance_source: 'Barbell',
  execution_pattern: 'Bilateral',
  load_capacity: 72,
  systemic_propulsive_fcsa_demand: 175.61,
  has_engine_vectors: true,
  image_url: null,
}

const muscle: MuscleListItem = {
  slug: 'pectoralis_major',
  name: 'Musculus pectoralis major',
  display_name: 'Pectoralis major',
  body_part: 'Upper',
  complex: 'Chest',
  mass_g: 500,
  mv_cm3: 480,
  fiber_bias_type_i: 0.45,
  fiber_bias_type_ii: 0.55,
  pcsa_projected_fcsa_cm2: 53,
  image_url: null,
}

function testRouter() {
  return createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/atlas/exercises', name: 'exercise-index', component: { template: '<div />' } },
      { path: '/atlas/exercises/:slug', name: 'exercise-detail', component: { template: '<div />' } },
      { path: '/atlas/muscles', name: 'muscle-index', component: { template: '<div />' } },
      { path: '/atlas/muscles/:slug', name: 'muscle-detail', component: { template: '<div />' } },
    ],
  })
}

describe('Atlas native navigation links', () => {
  it('makes every exercise table cell a link without adding extra tab stops', async () => {
    const router = testRouter()
    await router.push('/atlas/exercises')
    const wrapper = mount(ExerciseTable, {
      props: { items: [exercise], maximumDemand: 200, hovered: null },
      global: { plugins: [router] },
    })

    const links = wrapper.findAll('tbody a')
    expect(links).toHaveLength(7)
    expect(links.every((link) => link.attributes('href') === '/atlas/exercises/barbell_bench_press')).toBe(true)
    expect(links[0]?.attributes('tabindex')).toBeUndefined()
    expect(links.slice(1).every((link) => link.attributes('tabindex') === '-1')).toBe(true)

    const modifiedClick = new MouseEvent('click', { bubbles: true, cancelable: true, ctrlKey: true })
    modifiedClick.preventDefault()
    links[0]?.element.dispatchEvent(modifiedClick)
    expect(router.currentRoute.value.path).toBe('/atlas/exercises')
  })

  it('makes every muscle table cell a native detail link', async () => {
    const router = testRouter()
    await router.push('/atlas/muscles')
    const wrapper = mount(MuscleTable, {
      props: { items: [muscle], maximumMass: 600, maximumCapacity: 60, hovered: null },
      global: { plugins: [router] },
    })

    const links = wrapper.findAll('tbody a')
    expect(links).toHaveLength(7)
    expect(links.every((link) => link.attributes('href') === '/atlas/muscles/pectoralis_major')).toBe(true)
  })

  it('renders grid cards as links while retaining normal Vue Router navigation', async () => {
    const router = testRouter()
    await router.push('/atlas/exercises')
    const wrapper = mount(AtlasCardGrid, {
      props: {
        kind: 'exercises',
        exerciseItems: [exercise],
        muscleItems: [],
        hovered: null,
      },
      global: { plugins: [router] },
    })

    const card = wrapper.get('a.atlas-card')
    expect(card.attributes('href')).toBe('/atlas/exercises/barbell_bench_press')
    await card.trigger('click')
    await flushPromises()
    expect(router.currentRoute.value.path).toBe('/atlas/exercises/barbell_bench_press')
  })
})
