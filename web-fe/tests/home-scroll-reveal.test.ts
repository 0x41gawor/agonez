import { afterEach, describe, expect, it, vi } from 'vitest'

import { installHomeScrollReveal } from '@/utils/scrollReveal'

class IntersectionObserverMock {
  static instances: IntersectionObserverMock[] = []

  readonly observed: Element[] = []
  readonly unobserve = vi.fn((element: Element) => {
    const index = this.observed.indexOf(element)
    if (index >= 0) this.observed.splice(index, 1)
  })
  readonly disconnect = vi.fn()

  constructor(private readonly callback: IntersectionObserverCallback) {
    IntersectionObserverMock.instances.push(this)
  }

  observe(element: Element) {
    this.observed.push(element)
  }

  reveal(element: Element) {
    this.callback([{ isIntersecting: true, target: element } as IntersectionObserverEntry], this as unknown as IntersectionObserver)
  }
}

function setReducedMotion(matches: boolean) {
  vi.stubGlobal('matchMedia', vi.fn(() => ({ matches })))
}

afterEach(() => {
  IntersectionObserverMock.instances = []
  vi.unstubAllGlobals()
})

describe('Home scroll reveal', () => {
  it('reveals observed cards once with a short stagger and cleans up', () => {
    setReducedMotion(false)
    vi.stubGlobal('IntersectionObserver', IntersectionObserverMock)
    const root = document.createElement('div')
    root.innerHTML = `
      <header class="home-inline-heading"></header>
      <div class="home-audience-grid"><article></article><article></article></div>
    `

    const cleanup = installHomeScrollReveal(root)
    const cards = root.querySelectorAll<HTMLElement>('.home-audience-grid > article')
    const observer = IntersectionObserverMock.instances[0]

    expect(root.classList.contains('home-reveal-ready')).toBe(true)
    expect(cards[0]?.style.getPropertyValue('--home-reveal-delay')).toBe('0ms')
    expect(cards[1]?.style.getPropertyValue('--home-reveal-delay')).toBe('55ms')
    expect(observer?.observed).toHaveLength(3)

    observer?.reveal(cards[0]!)
    expect(cards[0]?.classList.contains('is-visible')).toBe(true)
    expect(observer?.unobserve).toHaveBeenCalledWith(cards[0])

    cleanup()
    expect(observer?.disconnect).toHaveBeenCalledOnce()
    expect(root.classList.contains('home-reveal-ready')).toBe(false)
    expect(cards[0]?.classList.contains('home-reveal')).toBe(false)
  })

  it('leaves content untouched when reduced motion is requested', () => {
    setReducedMotion(true)
    vi.stubGlobal('IntersectionObserver', IntersectionObserverMock)
    const root = document.createElement('div')
    root.innerHTML = '<div class="home-audience-grid"><article></article></div>'

    installHomeScrollReveal(root)

    expect(root.classList.contains('home-reveal-ready')).toBe(false)
    expect(root.querySelector('article')?.classList.contains('home-reveal')).toBe(false)
    expect(IntersectionObserverMock.instances).toHaveLength(0)
  })
})
