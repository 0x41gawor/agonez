<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, ref, watch } from 'vue'

import { mediaUrl } from '@/api/url'
import MediaImage from '@/components/common/MediaImage.vue'

const props = defineProps<{
  images: string[]
  title: string
}>()

const previewImages = computed(() => props.images.slice(0, 4))
const activeIndex = ref(0)
const open = ref(false)
const dialog = ref<HTMLElement | null>(null)
const closeButton = ref<HTMLButtonElement | null>(null)
let returnFocus: HTMLElement | null = null
let previousBodyOverflow = ''
let touchStartX: number | null = null

const activeImage = computed(() => props.images[activeIndex.value] ?? '')
const activeImageUrl = computed(() => mediaUrl(activeImage.value) ?? activeImage.value)

function openFromPreview(event: MouseEvent, index: number): void {
  if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey || event.button !== 0) return
  event.preventDefault()
  returnFocus = event.currentTarget as HTMLElement
  activeIndex.value = index
  open.value = true
}

async function closeGallery(): Promise<void> {
  open.value = false
  await nextTick()
  returnFocus?.focus()
}

function show(index: number): void {
  const total = props.images.length
  if (!total) return
  activeIndex.value = (index + total) % total
}

function previous(): void {
  show(activeIndex.value - 1)
}

function next(): void {
  show(activeIndex.value + 1)
}

function onKeydown(event: KeyboardEvent): void {
  if (!open.value) return
  if (event.key === 'Escape') {
    event.preventDefault()
    void closeGallery()
  } else if (event.key === 'ArrowLeft') {
    event.preventDefault()
    previous()
  } else if (event.key === 'ArrowRight') {
    event.preventDefault()
    next()
  } else if (event.key === 'Home') {
    event.preventDefault()
    show(0)
  } else if (event.key === 'End') {
    event.preventDefault()
    show(props.images.length - 1)
  } else if (event.key === 'Tab') {
    const focusable = Array.from(
      dialog.value?.querySelectorAll<HTMLElement>('a[href], button:not(:disabled)') ?? [],
    )
    if (!focusable.length) return
    const first = focusable[0]
    const last = focusable.at(-1)
    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault()
      last?.focus()
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault()
      first?.focus()
    }
  }
}

function onTouchStart(event: TouchEvent): void {
  touchStartX = event.changedTouches[0]?.clientX ?? null
}

function onTouchEnd(event: TouchEvent): void {
  const endX = event.changedTouches[0]?.clientX
  if (touchStartX == null || endX == null) return
  const distance = endX - touchStartX
  touchStartX = null
  if (Math.abs(distance) < 48) return
  if (distance > 0) previous()
  else next()
}

watch(open, async (isOpen) => {
  if (isOpen) {
    previousBodyOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    window.addEventListener('keydown', onKeydown)
    await nextTick()
    closeButton.value?.focus()
  } else {
    document.body.style.overflow = previousBodyOverflow
    window.removeEventListener('keydown', onKeydown)
  }
})

watch(activeIndex, async () => {
  if (!open.value) return
  await nextTick()
  const thumbnail = dialog.value?.querySelector<HTMLElement>(`[data-gallery-index="${activeIndex.value}"]`)
  thumbnail?.scrollIntoView?.({ behavior: 'smooth', block: 'nearest', inline: 'center' })
})

onBeforeUnmount(() => {
  window.removeEventListener('keydown', onKeydown)
  if (open.value) document.body.style.overflow = previousBodyOverflow
})
</script>

<template>
  <section class="media-section muscle-gallery panel">
    <header>
      <h2>Gallery</h2>
      <span class="mono">{{ images.length }} {{ images.length === 1 ? 'image' : 'images' }}</span>
    </header>
    <div class="gallery-preview-grid">
      <a
        v-for="(image, index) in previewImages"
        :key="image"
        class="gallery-preview-item"
        :href="mediaUrl(image) ?? image"
        target="_blank"
        rel="noopener noreferrer"
        @click="openFromPreview($event, index)"
      >
        <MediaImage :src="image" :alt="`${title} gallery image ${index + 1}`" />
        <span v-if="index === 3 && images.length > 4" class="gallery-more">
          +{{ images.length - 4 }} more
        </span>
        <span class="sr-only">Open image {{ index + 1 }} in gallery. Control-click opens it in a new tab.</span>
      </a>
    </div>
  </section>

  <Teleport to="body">
    <div v-if="open" class="gallery-lightbox-backdrop" @click.self="closeGallery">
      <section
        ref="dialog"
        class="gallery-lightbox"
        role="dialog"
        aria-modal="true"
        :aria-label="`${title} image gallery`"
      >
        <header>
          <div>
            <strong>{{ title }}</strong>
            <span class="mono">{{ activeIndex + 1 }} / {{ images.length }}</span>
          </div>
          <div class="gallery-lightbox-actions">
            <a :href="activeImageUrl" target="_blank" rel="noopener noreferrer">Open original ↗</a>
            <button ref="closeButton" type="button" aria-label="Close gallery" @click="closeGallery">×</button>
          </div>
        </header>

        <div class="gallery-lightbox-stage" @touchstart.passive="onTouchStart" @touchend.passive="onTouchEnd">
          <button type="button" aria-label="Previous image" @click="previous">‹</button>
          <div class="gallery-lightbox-image">
            <MediaImage
              :key="activeImage"
              :src="activeImage"
              :alt="`${title} gallery image ${activeIndex + 1} of ${images.length}`"
              loading="eager"
            />
          </div>
          <button type="button" aria-label="Next image" @click="next">›</button>
        </div>

        <footer v-if="images.length > 1" class="gallery-thumbnail-rail" aria-label="Gallery thumbnails">
          <button
            v-for="(image, index) in images"
            :key="image"
            type="button"
            :data-gallery-index="index"
            :class="{ active: index === activeIndex }"
            :aria-label="`View image ${index + 1}`"
            :aria-current="index === activeIndex ? 'true' : undefined"
            @click="show(index)"
          >
            <MediaImage :src="image" alt="" />
          </button>
        </footer>
      </section>
    </div>
  </Teleport>
</template>

<style scoped>
.gallery-preview-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 8px;
  padding: 12px;
}

.gallery-preview-item {
  position: relative;
  display: block;
  min-width: 0;
  overflow: hidden;
  border: 1px solid var(--border);
  border-radius: 8px;
  background: var(--panel2);
}

.gallery-preview-item:hover,
.gallery-preview-item:focus-visible { border-color: var(--accent); }
.gallery-preview-item :deep(img),
.gallery-preview-item :deep(.placeholder-media) {
  display: block;
  width: 100%;
  aspect-ratio: 4 / 3;
  object-fit: contain;
}

.gallery-more {
  position: absolute;
  inset: 0;
  display: grid;
  place-items: center;
  background: rgba(8, 10, 13, 0.68);
  color: #fff;
  font-size: 14px;
  font-weight: 650;
  letter-spacing: 0.2px;
  backdrop-filter: blur(2px);
}

.gallery-lightbox-backdrop {
  position: fixed;
  z-index: 1000;
  inset: 0;
  display: grid;
  place-items: center;
  padding: 12px;
  background: rgba(5, 7, 9, 0.88);
  backdrop-filter: blur(8px);
}

.gallery-lightbox {
  display: flex;
  flex-direction: column;
  width: min(1280px, calc(100vw - 24px));
  height: min(900px, calc(100dvh - 24px));
  overflow: hidden;
  border: 1px solid var(--border2);
  border-radius: 12px;
  background: var(--panel);
  box-shadow: var(--shadow);
}

.gallery-lightbox > header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  min-height: 52px;
  padding: 8px 12px 8px 16px;
  border-bottom: 1px solid var(--border);
}

.gallery-lightbox > header strong,
.gallery-lightbox > header span { display: block; }
.gallery-lightbox > header strong { font-size: 13px; }
.gallery-lightbox > header span { color: var(--text3); font-size: 10px; }
.gallery-lightbox-actions { display: flex; align-items: center; gap: 10px; }
.gallery-lightbox-actions a { color: var(--text2); font-size: 11px; }
.gallery-lightbox-actions button,
.gallery-lightbox-stage > button {
  border: 1px solid var(--border2);
  background: var(--panel2);
  color: var(--text2);
}
.gallery-lightbox-actions button {
  width: 34px;
  height: 34px;
  border-radius: 7px;
  font-size: 22px;
  line-height: 1;
}

.gallery-lightbox-stage {
  display: grid;
  grid-template-columns: 48px minmax(0, 1fr) 48px;
  align-items: stretch;
  flex: 1;
  min-height: 0;
  padding: 10px;
  background: var(--bg2);
}

.gallery-lightbox-stage > button {
  align-self: center;
  z-index: 1;
  width: 38px;
  height: 58px;
  border-radius: 8px;
  font-size: 32px;
  line-height: 1;
}
.gallery-lightbox-stage > button:hover,
.gallery-lightbox-stage > button:focus-visible,
.gallery-lightbox-actions button:hover { border-color: var(--accent); color: var(--text); }
.gallery-lightbox-stage > button:last-child { justify-self: end; }

.gallery-lightbox-image {
  position: relative;
  min-width: 0;
  min-height: 0;
  overflow: hidden;
}
.gallery-lightbox-image :deep(img) {
  position: absolute;
  inset: 0;
  display: block;
  width: 100%;
  height: 100%;
  max-width: none;
  max-height: none;
  object-fit: contain;
  object-position: center;
}
.gallery-lightbox-image :deep(.placeholder-media) {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
}

.gallery-thumbnail-rail {
  display: flex;
  gap: 7px;
  min-height: 86px;
  padding: 8px 12px;
  overflow-x: auto;
  border-top: 1px solid var(--border);
  scroll-snap-type: x proximity;
}
.gallery-thumbnail-rail > button {
  flex: 0 0 92px;
  overflow: hidden;
  padding: 0;
  border: 2px solid transparent;
  border-radius: 7px;
  background: var(--panel2);
  opacity: 0.58;
  scroll-snap-align: center;
}
.gallery-thumbnail-rail > button.active { border-color: var(--accent); opacity: 1; }
.gallery-thumbnail-rail :deep(img),
.gallery-thumbnail-rail :deep(.placeholder-media) { display: block; width: 100%; height: 66px; object-fit: contain; }

@media (max-width: 700px) {
  .gallery-preview-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .gallery-lightbox-backdrop { padding: 0; }
  .gallery-lightbox { width: 100vw; height: 100dvh; border: 0; border-radius: 0; }
  .gallery-lightbox-actions a { display: none; }
  .gallery-lightbox-stage { grid-template-columns: 38px minmax(0, 1fr) 38px; padding: 6px; }
  .gallery-lightbox-stage > button { width: 34px; height: 52px; }
  .gallery-thumbnail-rail { min-height: 76px; padding: 7px; }
  .gallery-thumbnail-rail > button { flex-basis: 78px; }
  .gallery-thumbnail-rail :deep(img),
  .gallery-thumbnail-rail :deep(.placeholder-media) { height: 56px; }
}
</style>
