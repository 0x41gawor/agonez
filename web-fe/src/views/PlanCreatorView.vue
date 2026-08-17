<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted } from 'vue'
import { onBeforeRouteLeave } from 'vue-router'

import ErrorState from '@/components/common/ErrorState.vue'
import PlanEditor from '@/components/plans/PlanEditor.vue'
import { usePlanDraft } from '@/composables/usePlanDraft'

const props = defineProps<{ planId: string }>()
const numericPlanId = computed(() => Number(props.planId))
const editor = usePlanDraft(numericPlanId)

const saveStatus = computed(() => {
  if (editor.saving.value) return 'Saving…'
  if (editor.conflict.value) return 'Conflict'
  if (editor.saveError.value) return 'Save failed'
  if (editor.dirty.value) return 'Unsaved changes'
  if (editor.savedAt.value) return 'Saved'
  return 'Up to date'
})

function handleShortcut(event: KeyboardEvent): void {
  if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 's') {
    event.preventDefault()
    void editor.save()
  }
}

function reloadAfterConflict(): void {
  if (!window.confirm('Reload the latest server draft and discard your unsaved local changes?')) return
  void editor.reloadLatest()
}

onBeforeRouteLeave(() => {
  if (!editor.dirty.value) return true
  return window.confirm('Leave this plan and discard unsaved changes?')
})

onMounted(() => {
  window.addEventListener('keydown', handleShortcut)
  void editor.load()
})
onBeforeUnmount(() => window.removeEventListener('keydown', handleShortcut))
</script>

<template>
  <div class="plan-creator-page">
    <div class="plan-creator-sticky">
      <div class="plan-creator-toolbar page-wrap">
        <div class="plan-title-cluster">
          <RouterLink class="plan-back" to="/plans" aria-label="Back to My Plans">←</RouterLink>
          <div>
            <span class="eyebrow">PlanCreator</span>
            <h1>{{ editor.draft.value?.name || 'Workout plan' }}</h1>
          </div>
        </div>
        <div class="save-cluster">
          <span class="save-state" :class="{ dirty: editor.dirty.value, conflict: editor.conflict.value }">
            <span class="status-dot" />{{ saveStatus }}
          </span>
          <button
            class="button primary save-button"
            type="button"
            :disabled="!editor.draft.value || editor.saving.value || !editor.dirty.value"
            @click="editor.save"
          >
            {{ editor.saving.value ? 'Saving…' : 'Save plan' }}
            <span class="save-shortcut mono">Ctrl S</span>
          </button>
        </div>
      </div>
      <nav class="plan-tabs" aria-label="PlanCreator sections">
        <span class="active" aria-current="page">PLAN</span>
        <span aria-disabled="true" title="Planned for the next PlanCreator stage">ANALYSIS <small>Later</small></span>
        <span aria-disabled="true" title="Planned for the next PlanCreator stage">MODULATION <small>Later</small></span>
      </nav>
    </div>

    <main class="page-wrap plan-creator-content">
      <div v-if="editor.conflict.value" class="conflict-banner" role="alert">
        <div>
          <strong>A newer draft exists on the server.</strong>
          <p>Your local edits are still here and were not overwritten. Reload only when you are ready to discard them.</p>
        </div>
        <button class="button" type="button" @click="reloadAfterConflict">Reload latest draft</button>
      </div>
      <div v-else-if="editor.saveError.value" class="plan-inline-error" role="alert">
        <span>{{ editor.saveError.value }}</span>
        <button type="button" @click="editor.saveError.value = null">Dismiss</button>
      </div>

      <div v-if="editor.loading.value" class="plan-editor-loading" aria-label="Loading plan editor">
        <div class="skeleton" />
        <div class="skeleton tall" />
      </div>
      <ErrorState
        v-else-if="editor.loadError.value"
        title="The plan could not be loaded"
        :message="editor.loadError.value"
        @retry="editor.load"
      />
      <PlanEditor
        v-else-if="editor.draft.value"
        v-model="editor.draft.value"
        :exercises="editor.exercises.value"
        :muscles="editor.muscles.value"
        :issues="editor.validationIssues.value"
      />
    </main>
  </div>
</template>
