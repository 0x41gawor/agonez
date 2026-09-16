<template>
  <section class="state-page">
    <span class="eyebrow">404</span>
    <h1>{{ $t('notFound.title') }}</h1>
    <p>{{ $t('notFound.message') }}</p>
    <RouterLink class="button primary" to="/atlas/exercises">{{ $t('notFound.action') }}</RouterLink>
  </section>
</template>
