<script setup lang="ts">
import { computed, ref } from 'vue'
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

const previewSrc = computed(() => mediaUrl(model.value))

function choosePicture(): void {
  fileInput.value?.click()
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
        :title="model ? $t('plans.editor.coverReplace') : $t('plans.editor.coverChoose')"
        :aria-label="model ? $t('plans.editor.coverReplace') : $t('plans.editor.coverChoose')"
        @click="choosePicture"
      >
        <img v-if="previewSrc" :src="previewSrc" :alt="$t('plans.editor.coverAlt', { name: planName })" />
        <span v-else class="plan-cover-empty mono" aria-hidden="true">
          P{{ String(planId).padStart(3, '0') }}
        </span>
        <span class="plan-cover-hint" aria-hidden="true">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
            <path d="M4 20h4.5L19 9.5a2.1 2.1 0 0 0-3-3L5.5 17 4 20z" />
          </svg>
        </span>
      </button>

      <button
        v-if="model"
        type="button"
        class="plan-cover-delete"
        :disabled="busy"
        :title="$t('plans.editor.coverRemove')"
        :aria-label="$t('plans.editor.coverRemove')"
        @click="removePicture"
      >
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <path d="M4.5 6.5h15" />
          <path d="M9.5 6.5V4.8h5v1.7" />
          <path d="M6.6 6.5l.9 12.1c.1.9.8 1.6 1.7 1.6h5.6c.9 0 1.6-.7 1.7-1.6l.9-12.1" />
        </svg>
      </button>

      <span v-if="busy" class="plan-cover-busy">{{ $t('plans.editor.coverWorking') }}</span>
    </div>

    <p v-if="error" class="field-error">{{ error }}</p>

    <input
      ref="fileInput"
      class="visually-hidden"
      type="file"
      accept="image/*"
      @change="uploadPicture"
    />
  </div>
</template>

<style scoped>
.plan-cover { display: grid; gap: 5px; justify-items: start; }
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
  cursor: pointer;
}
.plan-cover-preview:hover { border-color: var(--border2); }
.plan-cover-preview:focus-visible { outline: 2px solid var(--focus); outline-offset: 2px; }
.plan-cover-preview img { width: 100%; height: 100%; object-fit: cover; }
.plan-cover-empty { font-size: 12px; color: var(--planAccent, var(--accent)); letter-spacing: 0.04em; }

/* The controls stay out of the way until the cover is pointed at. */
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

.plan-cover-delete {
  position: absolute;
  right: 4px;
  bottom: 4px;
  display: grid;
  place-items: center;
  width: 24px;
  height: 24px;
  padding: 0;
  border: 1px solid var(--border2);
  border-radius: 7px;
  background: color-mix(in srgb, var(--bg) 78%, transparent);
  color: var(--rec);
  opacity: 0;
  transition: opacity 120ms ease, border-color 120ms ease;
  cursor: pointer;
}
.plan-cover-delete svg { width: 14px; height: 14px; }
.plan-cover-delete:hover { border-color: var(--rec); }
.plan-cover-delete:focus-visible { outline: 2px solid var(--focus); outline-offset: 1px; }
.plan-cover-frame:hover .plan-cover-delete,
.plan-cover-delete:focus-visible { opacity: 1; }

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

.visually-hidden {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip: rect(0 0 0 0);
  white-space: nowrap;
}
</style>
