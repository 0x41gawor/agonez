<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'

import type { TraceSetupNote } from '@/api/execution-types'
import { executionDateTime } from '@/features/execution/format'

const props = defineProps<{
  notes: TraceSetupNote[]
  currentExerciseId: number
  savingExerciseId: number | null
  errorCode: string | null
}>()
const emit = defineEmits<{
  close: []
  dirty: [value: boolean]
  reload: []
  save: [payload: { exerciseId: number; text: string | null; expectedRev: number }]
}>()

const { t } = useI18n()
const selectedExerciseId = ref(props.notes.find((note) => note.exercise_id === props.currentExerciseId)?.exercise_id ?? props.notes[0]?.exercise_id ?? null)
const draft = ref('')
const selectedNote = computed(() => props.notes.find((note) => note.exercise_id === selectedExerciseId.value) ?? null)

function normalized(value: string): string | null {
  return value.trim() ? value : null
}

const dirty = computed(() => normalized(draft.value) !== (selectedNote.value?.text ?? null))
const saving = computed(() => props.savingExerciseId === selectedExerciseId.value)
const errorKey = computed(() => ['version_conflict', 'setup_note_too_long'].includes(props.errorCode ?? '') ? props.errorCode : 'genericError')

function syncDraft(): void {
  draft.value = selectedNote.value?.text ?? ''
}

function confirmDiscard(): boolean {
  return !dirty.value || window.confirm(t('execution.setup.confirmDiscard'))
}

function selectNote(exerciseId: number): void {
  if (exerciseId === selectedExerciseId.value || !confirmDiscard()) return
  selectedExerciseId.value = exerciseId
  syncDraft()
}

function close(): void {
  if (!confirmDiscard()) return
  emit('dirty', false)
  emit('close')
}

function discard(): void {
  syncDraft()
}

function save(): void {
  const note = selectedNote.value
  if (!note || !dirty.value || saving.value) return
  emit('save', { exerciseId: note.exercise_id, text: normalized(draft.value), expectedRev: note.rev })
}

watch(selectedExerciseId, syncDraft, { immediate: true })
watch(() => props.notes, () => {
  if (!selectedNote.value) selectedExerciseId.value = props.notes.find((note) => note.exercise_id === props.currentExerciseId)?.exercise_id ?? props.notes[0]?.exercise_id ?? null
  syncDraft()
}, { deep: true })
watch(dirty, (value) => emit('dirty', value), { immediate: true })
onBeforeUnmount(() => emit('dirty', false))
</script>

<template>
  <section class="setup-note-panel" role="region" :aria-labelledby="`setup-note-title-${currentExerciseId}`" @keydown.esc.stop="close">
    <header>
      <div>
        <span class="eyebrow accent">{{ $t('execution.setup.eyebrow') }}</span>
        <h2 :id="`setup-note-title-${currentExerciseId}`">{{ $t('execution.setup.title') }}</h2>
        <p>{{ $t('execution.setup.help') }}</p>
      </div>
      <button class="exec-modal-close" type="button" :aria-label="$t('execution.common.close')" @click="close">×</button>
    </header>

    <div v-if="notes.length > 1" class="setup-note-tabs" role="group" :aria-label="$t('execution.setup.exercisePicker')">
      <button
        v-for="note in notes"
        :key="note.exercise_id"
        type="button"
        :aria-pressed="note.exercise_id === selectedExerciseId"
        :class="{ active: note.exercise_id === selectedExerciseId, filled: !!note.text }"
        @click="selectNote(note.exercise_id)"
      >
        <i aria-hidden="true" />{{ note.exercise.name }}
      </button>
    </div>

    <form v-if="selectedNote" class="setup-note-form" @submit.prevent="save">
      <div class="setup-note-identity">
        <span><b>{{ selectedNote.exercise.name }}</b><small class="mono">{{ selectedNote.exercise.slug }}</small></span>
        <em>{{ $t(selectedNote.exercise_id === currentExerciseId ? 'execution.setup.current' : 'execution.setup.variant') }}</em>
      </div>
      <label :for="`setup-note-${selectedNote.exercise_id}`">{{ $t('execution.setup.label') }}</label>
      <textarea
        :id="`setup-note-${selectedNote.exercise_id}`"
        v-model="draft"
        class="exec-textarea"
        maxlength="2000"
        :placeholder="$t('execution.setup.placeholder')"
        :disabled="saving"
      />
      <div class="setup-note-meta">
        <span>{{ selectedNote.updated_at ? $t('execution.setup.updated', { date: executionDateTime(selectedNote.updated_at) }) : $t('execution.setup.neverSet') }}</span>
        <span class="mono">{{ draft.length }} / 2000</span>
      </div>
      <div v-if="errorCode" class="editor-error" role="alert">
        <b>{{ $t(`execution.setup.${errorKey}`) }}</b>
        <button v-if="errorCode === 'version_conflict'" type="button" @click="emit('reload')">{{ $t('execution.setup.loadCurrent') }}</button>
      </div>
      <footer>
        <button class="button ghost setup-note-clear" type="button" :disabled="!draft || saving" @click="draft = ''">{{ $t('execution.setup.clear') }}</button>
        <span />
        <button class="button ghost" type="button" :disabled="!dirty || saving" @click="discard">{{ $t('execution.editor.discard') }}</button>
        <button class="button primary" type="submit" :disabled="!dirty || saving">{{ $t(saving ? 'execution.setup.saving' : 'execution.common.save') }}</button>
      </footer>
    </form>
    <p v-else class="exec-empty-row">{{ $t('execution.setup.unavailable') }}</p>
  </section>
</template>
