import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/', redirect: '/atlas/exercises' },
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
    { path: '/:pathMatch(.*)*', name: 'not-found', component: () => import('@/views/NotFoundView.vue') },
  ],
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) return savedPosition
    if (to.path !== from.path) return { top: 0 }
    return false
  },
})

export default router
