<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'

import type { PlanAIExportResult } from '@/api/plan-export-types'
import { planExportFilename } from '@/features/plans/export'

const props = defineProps<{
  document: PlanAIExportResult
  editorDirty: boolean
}>()
const emit = defineEmits<{ close: [] }>()
const { t } = useI18n()

const copied = ref(false)
const copyError = ref<string | null>(null)
let copiedTimer: number | undefined

const json = computed(() => JSON.stringify(props.document, null, 2))
const exerciseCount = computed(() =>
  props.document.days.reduce((total, day) => total + day.exercises.length, 0),
)

async function copyJson(): Promise<void> {
  copyError.value = null
  try {
    if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(json.value)
    } else {
      const textarea = window.document.createElement('textarea')
      textarea.value = json.value
      textarea.style.position = 'fixed'
      textarea.style.opacity = '0'
      window.document.body.append(textarea)
      textarea.select()
      const copiedWithFallback = window.document.execCommand('copy')
      textarea.remove()
      if (!copiedWithFallback) throw new Error('Copy command was rejected')
    }
    copied.value = true
    window.clearTimeout(copiedTimer)
    copiedTimer = window.setTimeout(() => (copied.value = false), 1800)
  } catch {
    copyError.value = t('plans.export.copyUnavailable')
  }
}

function downloadJson(): void {
  const blob = new Blob([json.value], { type: 'application/json;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const link = window.document.createElement('a')
  link.href = url
  link.download = planExportFilename(props.document.plan_name)
  link.click()
  URL.revokeObjectURL(url)
}

function handleKeydown(event: KeyboardEvent): void {
  if (event.key === 'Escape') emit('close')
}

onMounted(() => window.addEventListener('keydown', handleKeydown))
onBeforeUnmount(() => {
  window.removeEventListener('keydown', handleKeydown)
  window.clearTimeout(copiedTimer)
})
</script>

<template>
  <div class="plan-export-backdrop" @click.self="$emit('close')">
    <section
      class="plan-export-dialog panel"
      role="dialog"
      aria-modal="true"
      aria-labelledby="plan-export-title"
    >
      <header>
        <div>
          <span class="eyebrow">{{ $t('plans.export.eyebrow') }}</span>
          <h2 id="plan-export-title">{{ $t('plans.export.title') }}</h2>
          <p>{{ $t('plans.export.summary', { days: document.days.length, exercises: exerciseCount }) }}</p>
        </div>
        <button class="plan-export-close" type="button" :aria-label="$t('plans.export.close')" @click="$emit('close')">×</button>
      </header>

      <div v-if="editorDirty" class="plan-export-warning" role="status">
        <strong>{{ $t('plans.export.unsavedTitle') }}</strong>
        {{ $t('plans.export.unsavedBody') }}
      </div>

      <div class="plan-export-schema">
        <span class="mono">{{ document.format }}</span>
        <span>{{ $t('plans.export.schema') }}</span>
      </div>
      <pre class="plan-export-preview"><code>{{ json }}</code></pre>

      <footer>
        <p v-if="copyError" role="alert">{{ copyError }}</p>
        <span v-else>{{ $t('plans.export.ready') }}</span>
        <div>
          <button class="button" type="button" @click="copyJson">
            {{ copied ? $t('plans.export.copied') : $t('plans.export.copy') }}
          </button>
          <button class="button primary" type="button" @click="downloadJson">{{ $t('plans.export.download') }}</button>
        </div>
      </footer>
    </section>
  </div>
</template>
