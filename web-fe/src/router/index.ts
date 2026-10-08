import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/', redirect: '/home' },
    {
      path: '/home',
      name: 'home',
      component: () => import('@/views/HomeView.vue'),
    },
    {
      path: '/atlas/exercises',
      name: 'exercises',
      component: () => import('@/views/AtlasIndexView.vue'),
      props: { kind: 'exercises' },
    },
    {
      path: '/atlas/muscles',
      name: 'muscles',
      component: () => import('@/views/AtlasIndexView.vue'),
      props: { kind: 'muscles' },
    },
    {
      path: '/atlas/exercises/:slug',
      name: 'exercise-detail',
      component: () => import('@/views/ExerciseDetailView.vue'),
      props: true,
    },
    {
      path: '/atlas/muscles/:slug',
      name: 'muscle-detail',
      component: () => import('@/views/MuscleDetailView.vue'),
      props: true,
    },
    {
      path: '/plans',
      name: 'plans',
      component: () => import('@/views/PlanListView.vue'),
    },
    {
      path: '/plans/:planId(\\d+)',
      name: 'plan-editor',
      component: () => import('@/views/PlanCreatorView.vue'),
      props: true,
    },
    {
      path: '/execution',
      name: 'execution',
      component: () => import('@/views/execution/ExecutionLandingView.vue'),
    },
    {
      path: '/execution/runs/new',
      name: 'execution-new-run',
      component: () => import('@/views/execution/NewPlanRunView.vue'),
    },
    {
      path: '/execution/runs/:runId(\\d+)',
      component: () => import('@/views/execution/ExecutionLayout.vue'),
      props: true,
      children: [
        { path: '', name: 'execution-overview', component: () => import('@/views/execution/ExecutionOverviewView.vue') },
        { path: 'analysis', name: 'execution-analysis', component: () => import('@/views/execution/ExecutionAnalysisView.vue') },
        { path: 'analysis/workouts/:workoutTraceId(\\d+)', name: 'execution-workout-trace', component: () => import('@/views/execution/WorkoutTraceView.vue'), props: true },
        { path: 'timeline', name: 'execution-timeline', component: () => import('@/views/execution/ExecutionTimelineView.vue') },
        { path: 'loads', name: 'execution-loads', component: () => import('@/views/execution/ExecutionLoadsView.vue') },
      ],
    },
    { path: '/:pathMatch(.*)*', name: 'not-found', component: () => import('@/views/NotFoundView.vue') },
  ],
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) return savedPosition
    if (to.path !== from.path) return { top: 0 }
    return false
  },
})

export default router
