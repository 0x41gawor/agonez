const revealGroups = [
  '.home-audience-grid > *',
  '.home-loop-grid > *',
  '.home-detail-grid > *',
  '.home-builder-panels > *',
  '.home-analysis-grid > *',
  '.home-debt-grid > *',
  '.home-feature-grid > *',
  '.home-details-list > *',
  '.home-coach-grid > article',
  '.home-roadmap-grid > article',
] as const

const revealSingles = [
  '.home-inline-heading',
  '.home-split-heading',
  '.home-badged-eyebrow',
  '.home-showcase-frame',
  '.home-builder-grid > :first-child',
  '.home-analysis-heading',
  '#analiza > .home-container > .home-media-panel',
  '.home-muscle-visual',
  '.home-muscle-copy',
  '.home-model-content > .home-eyebrow',
  '.home-model-content > h2',
  '.home-model-content > .home-section-copy',
  '.home-chain',
  '.home-coach-action',
  '.home-final-content',
] as const

const revealClass = 'home-reveal'
const visibleClass = 'is-visible'

export function installHomeScrollReveal(root: HTMLElement): () => void {
  if (
    typeof IntersectionObserver === 'undefined'
    || window.matchMedia('(prefers-reduced-motion: reduce)').matches
  ) {
    return () => undefined
  }

  const targets = new Set<HTMLElement>()

  for (const selector of revealSingles) {
    root.querySelectorAll<HTMLElement>(selector).forEach((element) => targets.add(element))
  }

  for (const selector of revealGroups) {
    root.querySelectorAll<HTMLElement>(selector).forEach((element, index) => {
      element.style.setProperty('--home-reveal-delay', `${Math.min(index, 5) * 55}ms`)
      targets.add(element)
    })
  }

  root.classList.add('home-reveal-ready')
  targets.forEach((element) => element.classList.add(revealClass))

  const observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue
        entry.target.classList.add(visibleClass)
        observer.unobserve(entry.target)
      }
    },
    { rootMargin: '0px 0px -8% 0px', threshold: 0.08 },
  )

  targets.forEach((element) => observer.observe(element))

  return () => {
    observer.disconnect()
    root.classList.remove('home-reveal-ready')
    targets.forEach((element) => {
      element.classList.remove(revealClass, visibleClass)
      element.style.removeProperty('--home-reveal-delay')
    })
  }
}
