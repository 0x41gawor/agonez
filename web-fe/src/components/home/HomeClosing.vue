<template>
  <section class="home-section home-final-cta">
    <img class="home-watermark home-final-mark" src="/img/home/brand/agonez-mark-final.png" alt="" aria-hidden="true" />
    <div class="home-glow" aria-hidden="true" />
    <div class="home-final-content">
      <h2>{{ $t('home.cta.title') }}</h2>
      <p>{{ $t('home.cta.body') }}</p>
      <div class="home-actions home-centered-actions">
        <RouterLink class="home-button home-button-primary" to="/atlas/exercises">{{ $t('home.cta.primary') }}</RouterLink>
        <RouterLink class="home-button home-button-secondary" to="/plans">{{ $t('home.cta.secondary') }}</RouterLink>
      </div>
    </div>
  </section>

  <footer class="home-footer">
    <div class="home-container home-footer-inner">
      <RouterLink class="home-footer-brand" to="/home" :aria-label="$t('app.home')">
        <img src="/img/home/brand/agonez-mark.png" alt="" />
        <span>{{ $t('home.brand.name') }}</span>
      </RouterLink>
      <nav class="home-footer-nav" :aria-label="$t('home.footer.navigation')">
        <RouterLink to="/atlas/exercises">{{ $t('home.footer.links.exerciseAtlas') }}</RouterLink>
        <RouterLink to="/atlas/muscles">{{ $t('home.footer.links.muscleAtlas') }}</RouterLink>
        <RouterLink to="/plans">{{ $t('home.footer.links.planBuilder') }}</RouterLink>
        <a href="#analiza">{{ $t('home.footer.links.analysis') }}</a>
        <a href="#model">{{ $t('home.footer.links.model') }}</a>
      </nav>
      <p class="home-footer-disclaimer">{{ $t('home.footer.disclaimer') }}</p>
    </div>
  </footer>
</template>
