<script setup lang="ts">
import { computed, nextTick, onMounted, ref, watch } from 'vue'

import { fetchAnatomySource } from '@/api/anatomy'
import { SVG_TO_DB, heatmapMix, jointStyle, type VisualizationMode } from '@/utils/vectors'
import { formatNumber, prettyToken } from '@/utils/format'

const props = withDefaults(
  defineProps<{
    selectedSlug?: string | null
    vector?: Record<string, number> | null
    mode?: VisualizationMode
    joints?: Record<string, number> | null
    tooltipValues?: Record<string, number> | null
    tooltipValueLabel?: string
    tooltipValueUnit?: string
    tooltipValueDigits?: number
    showJoints?: boolean
    interactive?: boolean
  }>(),
  {
    selectedSlug: null,
    vector: null,
    mode: 'etu',
    joints: null,
    tooltipValues: null,
    tooltipValueLabel: 'Relative intensity',
    tooltipValueUnit: '',
    tooltipValueDigits: 2,
    showJoints: false,
    interactive: true,
  },
)

const emit = defineEmits<{
  hover: [slug: string | null]
  select: [slug: string]
}>()

const front = ref<HTMLElement | null>(null)
const rear = ref<HTMLElement | null>(null)
const loading = ref(true)
const error = ref(false)
const tip = ref<{ visible: boolean; x: number; y: number; title: string; detail: string }>({
  visible: false,
  x: 0,
  y: 0,
  title: '',
  detail: '',
})

let svgSource: SVGSVGElement | null = null

const ANATOMY_SHEET_VIEW_BOX = {
  front: '20 15 495 990',
  rear: '505 15 530 990',
} as const

const heatColor = computed(() => {
  if (props.mode === 'recovery') return 'var(--rec)'
  if (props.mode === 'propulsive') return 'var(--accent)'
  return 'var(--etu)'
})

function cleanClone(view: 'front' | 'rear'): SVGSVGElement {
  if (!svgSource) throw new Error('Anatomy SVG unavailable')
  const clone = svgSource.cloneNode(true) as SVGSVGElement
  clone.querySelectorAll('style,script,foreignObject,text,metadata,title,desc,.ground,sodipodi\\:namedview').forEach((node) => node.remove())
  clone.querySelectorAll('g').forEach((group) => {
    if (group.querySelector('[data-view]') || group.closest('[data-type]') || group.dataset.type) return
    const simpleShapes = group.querySelectorAll('circle,rect')
    if (simpleShapes.length && !group.querySelector('path')) group.remove()
  })
  clone.querySelectorAll('[data-view]').forEach((node) => {
    if (node.getAttribute('data-view') !== view) node.remove()
  })
  clone.querySelectorAll<HTMLElement>('[style]').forEach((node) => {
    node.style.removeProperty('fill')
    node.style.removeProperty('stroke')
    node.style.removeProperty('display')
  })
  clone.querySelectorAll('g').forEach((group) => {
    if (group.dataset.type) {
      group.setAttribute('tabindex', props.interactive ? '0' : '-1')
      group.setAttribute('role', props.interactive ? 'button' : 'img')
      const slug = SVG_TO_DB[group.id] ?? group.id
      group.setAttribute('aria-label', prettyToken(slug))
    }
  })
  clone.classList.add('agz-body')
  clone.dataset.bodyView = view
  clone.removeAttribute('width')
  clone.removeAttribute('height')
  // The supplied anatomy SVG has one untagged raster sheet containing the
  // front, rear, and side figures. The muscle overlays are view-tagged, but
  // the shared sheet is not, so it must be clipped to a stable per-view box.
  if (clone.querySelector('image:not([data-view])')) {
    clone.setAttribute('viewBox', ANATOMY_SHEET_VIEW_BOX[view])
    clone.dataset.fixedViewBox = 'true'
  }
  clone.setAttribute('preserveAspectRatio', 'xMidYMid meet')
  clone.style.width = '100%'
  clone.style.height = 'auto'
  return clone
}

function cropSvg(svg: SVGSVGElement, view: 'front' | 'rear', attempt = 0): void {
  let bounds: { x1: number; y1: number; x2: number; y2: number } | null = null
  try {
    for (const shape of svg.querySelectorAll<SVGGraphicsElement>('.body-base,.body-far,.region')) {
      const box = shape.getBBox()
      if (!(box.width > 0)) continue
      if (!bounds) bounds = { x1: box.x, y1: box.y, x2: box.x + box.width, y2: box.y + box.height }
      else {
        bounds.x1 = Math.min(bounds.x1, box.x)
        bounds.y1 = Math.min(bounds.y1, box.y)
        bounds.x2 = Math.max(bounds.x2, box.x + box.width)
        bounds.y2 = Math.max(bounds.y2, box.y + box.height)
      }
    }
  } catch {
    // getBBox can be unavailable until a frame after insertion.
  }
  if (bounds && bounds.x2 - bounds.x1 > 50) {
    svg.setAttribute('viewBox', `${bounds.x1 - 12} ${bounds.y1 - 12} ${bounds.x2 - bounds.x1 + 24} ${bounds.y2 - bounds.y1 + 24}`)
  } else if (attempt < 8) {
    requestAnimationFrame(() => cropSvg(svg, view, attempt + 1))
  } else {
    svg.setAttribute('viewBox', ANATOMY_SHEET_VIEW_BOX[view])
  }
}

function mountViews(): void {
  if (!front.value || !rear.value || !svgSource) return
  front.value.replaceChildren()
  rear.value.replaceChildren()
  const frontSvg = cleanClone('front')
  const rearSvg = cleanClone('rear')
  front.value.append(frontSvg)
  rear.value.append(rearSvg)
  if (!frontSvg.dataset.fixedViewBox) cropSvg(frontSvg, 'front')
  if (!rearSvg.dataset.fixedViewBox) cropSvg(rearSvg, 'rear')
  paint()
}

function paint(): void {
  for (const root of [front.value, rear.value]) {
    const svg = root?.querySelector<SVGSVGElement>('svg.agz-body')
    if (!svg) continue
    svg.classList.toggle('agz-joints-on', props.showJoints)
    svg.querySelectorAll<SVGGElement>('g[data-type="muscle"]').forEach((group) => {
      const slug = SVG_TO_DB[group.id] ?? group.id
      const selected = props.selectedSlug === slug
      const intensity = props.vector?.[slug] ?? 0
      const regions = group.querySelectorAll<SVGElement>('.region')
      const hasVector = props.vector != null
      const visible = selected || (hasVector && intensity > 0.02)
      const dimmed = Boolean(props.selectedSlug) && !selected
      const mix = selected ? 100 : heatmapMix(intensity)
      regions.forEach((region) => {
        region.style.fill = visible ? `color-mix(in oklab, var(--anatMuscle), ${heatColor.value} ${mix}%)` : ''
        region.style.opacity = selected ? '1' : dimmed ? '0.5' : hasVector && !visible ? '0.55' : ''
      })
      group.classList.toggle('is-selected', selected)
    })
    svg.querySelectorAll<SVGGElement>('g[data-type="joint"]').forEach((group) => {
      const value = props.joints?.[group.id] ?? 0
      const style = jointStyle(value)
      group.querySelectorAll<SVGElement>('.joint-region,.spine-region').forEach((region) => {
        region.style.opacity = String(style.opacity)
        region.style.strokeWidth = String(style.strokeWidth)
      })
    })
  }
}

function eventGroup(event: Event): SVGGElement | null {
  return (event.target as Element | null)?.closest<SVGGElement>('g[data-type]') ?? null
}

function showTooltip(group: SVGGElement, event?: MouseEvent): void {
  const type = group.dataset.type
  const slug = SVG_TO_DB[group.id] ?? group.id
  const value = type === 'joint' ? props.joints?.[slug] : props.vector?.[slug]
  const tooltipValue = props.tooltipValues?.[slug]
  let detail = value == null ? prettyToken(type) : `${prettyToken(type)} · ${(value * 100).toFixed(1)}% relative intensity`
  if (tooltipValue != null) {
    detail =
      props.mode === 'recovery' && tooltipValue <= 0.005
        ? `${props.tooltipValueLabel} · fresh (0 h)`
        : props.mode === 'recovery'
          ? `${props.tooltipValueLabel} · ${formatNumber(tooltipValue, tooltipValue < 10 ? 1 : 0)} h to fresh`
          : `${props.tooltipValueLabel} · ${formatNumber(tooltipValue, props.tooltipValueDigits)}${props.tooltipValueUnit ? ` ${props.tooltipValueUnit}` : ''}`
  }
  tip.value = {
    visible: true,
    x: event ? Math.min(event.clientX + 14, window.innerWidth - 248) : 24,
    y: event ? Math.min(event.clientY + 14, window.innerHeight - 84) : 70,
    title: prettyToken(slug),
    detail,
  }
  if (type === 'muscle') emit('hover', slug)
}

function onOver(event: MouseEvent): void {
  const group = eventGroup(event)
  if (group) showTooltip(group, event)
}

function onOut(event: MouseEvent): void {
  const group = eventGroup(event)
  const related = event.relatedTarget as Node | null
  if (group && related && group.contains(related)) return
  tip.value.visible = false
  emit('hover', null)
}

function onMove(event: MouseEvent): void {
  if (!tip.value.visible) return
  tip.value.x = Math.min(event.clientX + 14, window.innerWidth - 248)
  tip.value.y = Math.min(event.clientY + 14, window.innerHeight - 84)
}

function onClick(event: MouseEvent): void {
  if (!props.interactive) return
  const group = eventGroup(event)
  if (group?.dataset.type === 'muscle') emit('select', SVG_TO_DB[group.id] ?? group.id)
}

function onKeydown(event: KeyboardEvent): void {
  if (!props.interactive || (event.key !== 'Enter' && event.key !== ' ')) return
  const group = eventGroup(event)
  if (group?.dataset.type === 'muscle') {
    event.preventDefault()
    emit('select', SVG_TO_DB[group.id] ?? group.id)
  }
}

onMounted(async () => {
  try {
    const raw = await fetchAnatomySource()
    const documentNode = new DOMParser().parseFromString(raw, 'image/svg+xml')
    if (documentNode.querySelector('parsererror')) throw new Error('Invalid anatomy SVG')
    svgSource = documentNode.documentElement as unknown as SVGSVGElement
    loading.value = false
    await nextTick()
    mountViews()
  } catch {
    loading.value = false
    error.value = true
  }
})

watch(
  () => [props.selectedSlug, props.vector, props.mode, props.joints, props.showJoints] as const,
  () => paint(),
  { deep: true },
)
</script>

<template>
  <div
    class="body-viewer"
    :class="{ loading, error }"
    @mouseover="onOver"
    @mouseout="onOut"
    @mousemove="onMove"
    @click="onClick"
    @keydown="onKeydown"
  >
    <template v-if="loading">
      <div class="body-skeleton skeleton" />
      <div class="body-skeleton skeleton" />
    </template>
    <p v-else-if="error" class="anatomy-error">Anatomy unavailable</p>
    <template v-else>
      <div class="body-view"><div ref="front" /><span>FRONT</span></div>
      <div class="body-view"><div ref="rear" /><span>REAR</span></div>
    </template>
  </div>
  <div
    v-if="tip.visible"
    class="body-tooltip"
    role="tooltip"
    :style="{ left: `${tip.x}px`, top: `${tip.y}px` }"
  >
    <strong>{{ tip.title }}</strong>
    <span>{{ tip.detail }}</span>
  </div>
</template>
