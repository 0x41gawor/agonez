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
  <div class="plan-cover-editor">
    <button
      type="button"
      class="plan-cover-preview"
      :disabled="busy"
      :aria-label="$t('plans.editor.coverChoose')"
      @click="choosePicture"
    >
      <img v-if="previewSrc" :src="previewSrc" :alt="$t('plans.editor.coverAlt', { name: planName })" />
      <span v-else class="plan-cover-empty mono" aria-hidden="true">
        P{{ String(planId).padStart(3, '0') }}
      </span>
      <span v-if="busy" class="plan-cover-busy">{{ $t('plans.editor.coverWorking') }}</span>
    </button>
    <div class="plan-cover-actions">
      <button class="plan-cover-action" type="button" :disabled="busy" @click="choosePicture">
        {{ model ? $t('plans.editor.coverReplace') : $t('plans.editor.coverChoose') }}
      </button>
      <button
        v-if="model"
        class="plan-cover-action danger"
        type="button"
        :disabled="busy"
        @click="removePicture"
      >{{ $t('plans.editor.coverRemove') }}</button>
      <p v-if="error" class="field-error">{{ error }}</p>
    </div>
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
.plan-cover-editor { display: flex; align-items: flex-start; gap: 12px; }
.plan-cover-preview {
  position: relative;
  display: grid;
  place-items: center;
  width: 76px;
  height: 76px;
  flex: none;
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
.plan-cover-busy {
  position: absolute;
  inset: 0;
  display: grid;
  place-items: center;
  background: color-mix(in srgb, var(--panel) 78%, transparent);
  font-size: 11px;
  color: var(--text2);
}
.plan-cover-actions { display: grid; gap: 4px; align-content: start; }
.plan-cover-action {
  padding: 0;
  border: 0;
  background: none;
  color: var(--accent);
  font-size: 12px;
  text-align: left;
  text-decoration: underline;
  cursor: pointer;
}
.plan-cover-action:disabled { color: var(--text3); cursor: default; }
.plan-cover-action.danger { color: var(--rec); }
.visually-hidden {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip: rect(0 0 0 0);
  white-space: nowrap;
}
</style>
