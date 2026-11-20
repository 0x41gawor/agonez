<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'

import { plansApi } from '@/api/plans'
import { mediaUrl } from '@/api/url'
import { CoverImageError, prepareCoverImage } from '@/features/plans/cover-image'

const props = defineProps<{ planId: number; planName: string }>()
const model = defineModel<string | null>({ required: true })
const { t } = useI18n()

const fileInput = ref<HTMLInputElement | null>(null)
const busy = ref(false)
const error = ref<string | null>(null)
const viewing = ref(false)
const confirmingDelete = ref(false)

const previewSrc = computed(() => mediaUrl(model.value))

function closeOnEscape(event: KeyboardEvent): void {
  if (event.key === 'Escape') viewing.value = false
}

watch(viewing, (open) => {
  if (open) document.addEventListener('keydown', closeOnEscape)
  else document.removeEventListener('keydown', closeOnEscape)
})

onBeforeUnmount(() => document.removeEventListener('keydown', closeOnEscape))

function choosePicture(): void {
  confirmingDelete.value = false
  fileInput.value?.click()
}

/** The picture itself is the one thing here that cannot lose anything: it only looks. */
function openPicture(): void {
  if (model.value) viewing.value = true
  else choosePicture()
}

async function uploadPicture(event: Event): Promise<void> {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  // Clearing the input lets the same file be chosen again after a failure.
  input.value = ''
  if (!file || busy.value) return

  busy.value = true
  error.value = null
  try {
    const prepared = await prepareCoverImage(file)
    const written = await plansApi.uploadImage(props.planId, prepared)
    model.value = written.image_url
  } catch (cause) {
    error.value = cause instanceof CoverImageError
      ? t('plans.editor.coverUnreadable')
      : cause instanceof Error ? cause.message : t('plans.editor.coverFailed')
  } finally {
    busy.value = false
  }
}

async function removePicture(): Promise<void> {
  if (busy.value) return
  busy.value = true
  error.value = null
  try {
    await plansApi.deleteImage(props.planId)
    model.value = null
    confirmingDelete.value = false
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : t('plans.editor.coverFailed')
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <div class="plan-cover">
    <div class="plan-cover-frame">
      <button
        type="button"
        class="plan-cover-preview"
        :disabled="busy"
        :title="model ? $t('plans.editor.coverView') : $t('plans.editor.coverChoose')"
        :aria-label="model ? $t('plans.editor.coverView') : $t('plans.editor.coverChoose')"
        @click="openPicture"
      >
        <img v-if="previewSrc" :src="previewSrc" :alt="$t('plans.editor.coverAlt', { name: planName })" />
        <span v-else class="plan-cover-empty mono" aria-hidden="true">
          P{{ String(planId).padStart(3, '0') }}
        </span>
        <span class="plan-cover-hint" aria-hidden="true">
          <svg v-if="model" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
            <path d="M2.6 12S6.4 5.4 12 5.4 21.4 12 21.4 12 17.6 18.6 12 18.6 2.6 12 2.6 12z" />
            <circle cx="12" cy="12" r="3.1" />
          </svg>
          <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
            <path d="M4 20h4.5L19 9.5a2.1 2.1 0 0 0-3-3L5.5 17 4 20z" />
          </svg>
        </span>
      </button>

      <div v-if="model" class="plan-cover-actions">
        <button
          type="button"
          :disabled="busy"
          :title="$t('plans.editor.coverReplace')"
          :aria-label="$t('plans.editor.coverReplace')"
          @click="choosePicture"
        >
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="M4 20h4.5L19 9.5a2.1 2.1 0 0 0-3-3L5.5 17 4 20z" />
          </svg>
        </button>
        <button
          type="button"
          class="danger"
          :disabled="busy"
          :title="$t('plans.editor.coverRemove')"
          :aria-label="$t('plans.editor.coverRemove')"
          @click="confirmingDelete = true"
        >
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="M4.5 6.5h15" />
            <path d="M9.5 6.5V4.8h5v1.7" />
            <path d="M6.6 6.5l.9 12.1c.1.9.8 1.6 1.7 1.6h5.6c.9 0 1.6-.7 1.7-1.6l.9-12.1" />
          </svg>
        </button>
      </div>

      <span v-if="busy" class="plan-cover-busy">{{ $t('plans.editor.coverWorking') }}</span>
    </div>

    <div v-if="confirmingDelete" class="plan-cover-confirm" role="alertdialog" :aria-label="$t('plans.editor.coverRemoveQuestion')">
      <span>{{ $t('plans.editor.coverRemoveQuestion') }}</span>
      <button type="button" class="danger" :disabled="busy" @click="removePicture">
        {{ $t('plans.editor.coverRemoveConfirm') }}
      </button>
      <button type="button" :disabled="busy" @click="confirmingDelete = false">
        {{ $t('plans.editor.coverRemoveCancel') }}
      </button>
    </div>

    <p v-if="error" class="field-error">{{ error }}</p>

    <input
      ref="fileInput"
      class="visually-hidden"
      type="file"
      accept="image/*"
      @change="uploadPicture"
    />

    <Teleport to="body">
      <div
        v-if="viewing && previewSrc"
        class="plan-cover-viewer"
        role="dialog"
        aria-modal="true"
        :aria-label="$t('plans.editor.coverAlt', { name: planName })"
        @click="viewing = false"
      >
        <img :src="previewSrc" :alt="$t('plans.editor.coverAlt', { name: planName })" @click.stop />
        <button type="button" class="plan-cover-viewer-close" :aria-label="$t('common.close')" @click="viewing = false">×</button>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.plan-cover { display: grid; gap: 6px; justify-items: start; }
.plan-cover-frame { position: relative; width: 76px; height: 76px; }

.plan-cover-preview {
  position: relative;
  display: grid;
  place-items: center;
  width: 100%;
  height: 100%;
  padding: 0;
  overflow: hidden;
  border: 1px solid var(--border);
  border-radius: 12px;
  background: color-mix(in srgb, var(--planAccent, var(--accent)) 6%, var(--inputBg));
  cursor: zoom-in;
}
.plan-cover-preview:hover { border-color: var(--border2); }
.plan-cover-preview:focus-visible { outline: 2px solid var(--focus); outline-offset: 2px; }
.plan-cover-preview img { width: 100%; height: 100%; object-fit: cover; }
.plan-cover-empty { font-size: 12px; color: var(--planAccent, var(--accent)); letter-spacing: 0.04em; }

.plan-cover-hint {
  position: absolute;
  inset: 0;
  display: grid;
  place-items: center;
  background: color-mix(in srgb, var(--bg) 58%, transparent);
  color: var(--text);
  opacity: 0;
  transition: opacity 120ms ease;
}
.plan-cover-hint svg { width: 20px; height: 20px; }
.plan-cover-frame:hover .plan-cover-hint,
.plan-cover-preview:focus-visible .plan-cover-hint { opacity: 1; }

/* Replace and delete are their own targets, so looking at the picture cannot
   become changing or losing it. */
.plan-cover-actions {
  position: absolute;
  right: 4px;
  bottom: 4px;
  display: flex;
  gap: 4px;
  opacity: 0;
  transition: opacity 120ms ease;
}
.plan-cover-frame:hover .plan-cover-actions,
.plan-cover-actions:focus-within { opacity: 1; }

.plan-cover-actions button {
  display: grid;
  place-items: center;
  width: 24px;
  height: 24px;
  padding: 0;
  border: 1px solid var(--border2);
  border-radius: 7px;
  background: color-mix(in srgb, var(--bg) 82%, transparent);
  color: var(--text2);
  cursor: pointer;
}
.plan-cover-actions button svg { width: 14px; height: 14px; }
.plan-cover-actions button:hover { border-color: var(--border2); color: var(--text); }
.plan-cover-actions button.danger { color: var(--rec); }
.plan-cover-actions button.danger:hover { border-color: var(--rec); }
.plan-cover-actions button:focus-visible { outline: 2px solid var(--focus); outline-offset: 1px; }

.plan-cover-busy {
  position: absolute;
  inset: 0;
  display: grid;
  place-items: center;
  border-radius: 12px;
  background: color-mix(in srgb, var(--panel) 78%, transparent);
  font-size: 11px;
  color: var(--text2);
}

.plan-cover-confirm {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 8px;
  border: 1px solid color-mix(in srgb, var(--rec) 45%, var(--border));
  border-radius: 8px;
  background: var(--panel2);
  font-size: 11.5px;
  color: var(--text2);
}
.plan-cover-confirm button {
  padding: 3px 8px;
  border: 1px solid var(--border2);
  border-radius: 6px;
  background: transparent;
  color: var(--text2);
  font-size: 11px;
  cursor: pointer;
}
.plan-cover-confirm button.danger { border-color: var(--rec); color: var(--rec); }

.plan-cover-viewer {
  position: fixed;
  z-index: 100;
  inset: 0;
  display: grid;
  place-items: center;
  padding: 32px;
  background: color-mix(in srgb, var(--bg) 88%, transparent);
  cursor: zoom-out;
}
.plan-cover-viewer img {
  max-width: min(960px, 100%);
  max-height: 100%;
  border-radius: 12px;
  box-shadow: var(--shadow);
  object-fit: contain;
  cursor: default;
}
.plan-cover-viewer-close {
  position: absolute;
  top: 16px;
  right: 18px;
  width: 32px;
  height: 32px;
  border: 1px solid var(--border2);
  border-radius: 8px;
  background: var(--panel2);
  color: var(--text2);
  font-size: 17px;
  line-height: 1;
  cursor: pointer;
}
.plan-cover-viewer-close:hover { color: var(--text); }

.visually-hidden {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip: rect(0 0 0 0);
  white-space: nowrap;
}
</style>
