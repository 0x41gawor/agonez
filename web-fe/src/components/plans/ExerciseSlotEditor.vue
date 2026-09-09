<script setup lang="ts">
import { computed, ref } from 'vue'

import type { LoadingMode } from '@/api/plan-types'
import type { ExerciseCatalogItem, MuscleListItem } from '@/api/types'
import BodyViewer from '@/components/anatomy/BodyViewer.vue'
import MediaImage from '@/components/common/MediaImage.vue'
import ExerciseSelector from '@/components/plans/ExerciseSelector.vue'
import ExerciseVariantEditor from '@/components/plans/ExerciseVariantEditor.vue'
import LoadingCycleEditor from '@/components/plans/LoadingCycleEditor.vue'
import LoadingModePicker from '@/components/plans/LoadingModePicker.vue'
import MuscleTargetSelector from '@/components/plans/MuscleTargetSelector.vue'
import {
  createSet,
  createVariant,
  effectiveLoadingPattern,
  initialRepRange,
  loadingModeLabel,
  loadingModeShortLabel,
  LOADING_MODES,
  roleLabel,
  type EditorSlot,
  type PlanValidationIssue,
} from '@/features/plans/editor'

const model = defineModel<EditorSlot>({ required: true })
const props = defineProps<{
  index: number
  count: number
  exercises: ExerciseCatalogItem[]
  muscles: MuscleListItem[]
  path: string
  issues: PlanValidationIssue[]
}>()
defineEmits<{
  move: [direction: -1 | 1]
  duplicate: []
  remove: []
}>()

const expanded = ref(false)
const pendingExerciseSlug = ref('')
const defaultIndex = computed(() =>
  model.value.variants.findIndex((variant) => variant.variant_type === 'DEFAULT'),
)
const fallbackIndices = computed(() =>
  model.value.variants
    .map((variant, index) => ({ variant, index }))
    .filter(({ variant }) => variant.variant_type === 'FALLBACK')
    .map(({ index }) => index),
)
const defaultExercise = computed(() => {
  const variant = model.value.variants[defaultIndex.value]
  return props.exercises.find((exercise) => exercise.slug === variant?.exercise_slug)
})
const pendingExercise = computed(() =>
  props.exercises.find((exercise) => exercise.slug === pendingExerciseSlug.value),
)
const displayedExercise = computed(() => defaultExercise.value ?? pendingExercise.value)
const setCount = computed(() =>
  model.value.variants.reduce((total, variant) => total + variant.sets.length, 0),
)
const roleClass = computed(() => `role-${model.value.role.toLowerCase().replaceAll('_', '-')}`)
const targetVector = computed<Record<string, number>>(() =>
  Object.fromEntries(model.value.target_muscle_slugs.map((slug) => [slug, 1])),
)
const slotLoadingPattern = computed(() => effectiveLoadingPattern(
  model.value.loading_mode,
  model.value.loading_cycle,
))
const slotCycleModel = computed<LoadingMode[] | null>({
  get: () => model.value.loading_cycle,
  set: (cycle) => {
    model.value.loading_cycle = cycle ? [...cycle] : null
    for (const variant of model.value.variants) {
      for (const set of variant.sets) {
        set.loading_mode = model.value.loading_mode
        set.loading_cycle = cycle ? [...cycle] : null
      }
    }
  },
})

function applySlotLoadingMode(mode: LoadingMode): void {
  model.value.loading_mode = mode
  model.value.loading_cycle = null
  for (const variant of model.value.variants) {
    for (const set of variant.sets) {
      set.loading_mode = mode
      set.loading_cycle = null
    }
  }
}

function chooseInitialExercise(slug: string): void {
  if (!slug) return
  pendingExerciseSlug.value = slug
}

function initialRange(mode: LoadingMode): { min: number; max: number } {
  return initialRepRange(pendingExercise.value?.recommended_rep_profile, mode)
}

function completeInitialSetup(mode: LoadingMode): void {
  const exercise = pendingExercise.value
  if (!exercise) return

  applySlotLoadingMode(mode)
  const variant = createVariant('DEFAULT', 0, exercise.slug)
  variant.sets = Array.from({ length: 3 }, (_, ordinal) =>
    createSet(ordinal, undefined, mode, exercise.recommended_rep_profile),
  )
  model.value.variants.unshift(variant)
  model.value.variants.forEach((variant, ordinal) => {
    variant.ordinal = ordinal
  })
  pendingExerciseSlug.value = ''
}

function addFallback(): void {
  model.value.variants.push(createVariant('FALLBACK', model.value.variants.length))
}

function removeVariant(index: number): void {
  model.value.variants.splice(index, 1)
  model.value.variants.forEach((variant, ordinal) => {
    variant.ordinal = ordinal
  })
}

function moveFallback(fallbackIndex: number, direction: -1 | 1): void {
  const destination = fallbackIndex + direction
  const sourceArrayIndex = fallbackIndices.value[fallbackIndex]
  const destinationArrayIndex = fallbackIndices.value[destination]
  if (sourceArrayIndex == null || destinationArrayIndex == null) return
  const source = model.value.variants[sourceArrayIndex]
  const target = model.value.variants[destinationArrayIndex]
  if (!source || !target) return
  model.value.variants[sourceArrayIndex] = target
  model.value.variants[destinationArrayIndex] = source
  model.value.variants.forEach((variant, ordinal) => {
    variant.ordinal = ordinal
  })
}
</script>

<template>
  <article class="slot-editor panel" :class="roleClass">
    <header class="slot-summary">
      <span class="slot-order mono">{{ index + 1 }}</span>
      <div class="slot-exercise-thumb">
        <MediaImage
          :src="displayedExercise?.image_url"
          :alt="displayedExercise ? `${displayedExercise.name_full || displayedExercise.name} exercise` : 'No default exercise selected'"
          label="No image"
        />
      </div>
      <button class="slot-summary-main" type="button" :aria-expanded="expanded" @click="expanded = !expanded">
        <span class="slot-title-copy">
          <span class="slot-role-badge">
            <i aria-hidden="true" />{{ roleLabel(model.role) }}
          </span>
          <span v-if="defaultIndex >= 0" class="slot-loading-badge" :class="`loading-${slotLoadingPattern[0]}`">
            <i v-for="(mode, patternIndex) in slotLoadingPattern" :key="patternIndex" :class="`loading-${mode}`" aria-hidden="true" />
            {{ slotLoadingPattern.length === 1 ? loadingModeLabel(slotLoadingPattern[0]!) : slotLoadingPattern.map(loadingModeShortLabel).join('·') }}
          </span>
          <strong>{{ model.name?.trim() || 'Untitled exercise slot' }}</strong>
          <small>{{ displayedExercise?.name_full || displayedExercise?.name || 'Choose default exercise' }}</small>
        </span>
        <span class="slot-set-count mono">{{ setCount }} {{ setCount === 1 ? 'set' : 'sets' }}</span>
      </button>
      <div class="ordered-actions">
        <button type="button" :disabled="index === 0" title="Move slot up" @click="$emit('move', -1)">↑</button>
        <button type="button" :disabled="index === count - 1" title="Move slot down" @click="$emit('move', 1)">↓</button>
        <button type="button" title="Duplicate exercise slot" aria-label="Duplicate exercise slot" @click="$emit('duplicate')">⧉</button>
        <button class="danger-action" type="button" title="Remove slot" @click="$emit('remove')">×</button>
      </div>
    </header>

    <div class="slot-body">
      <template v-if="defaultIndex >= 0">
        <ExerciseVariantEditor
          v-model="model.variants[defaultIndex]!"
          :exercises="exercises"
          :path="`${path}.variants.${model.variants[defaultIndex]!.clientKey}`"
          :issues="issues"
          :slot-loading-mode="model.loading_mode"
          :slot-loading-cycle="model.loading_cycle"
        />
      </template>
      <div v-else class="empty-default initial-slot-setup">
        <span class="section-label">Set up default exercise</span>
        <section class="initial-setup-step">
          <span class="initial-step-number mono">1</span>
          <div class="initial-step-content">
            <div class="initial-step-heading">
              <strong>Choose exercise</strong>
              <small>Find the movement this slot should perform.</small>
            </div>
            <ExerciseSelector
              :model-value="pendingExerciseSlug"
              :exercises="exercises"
              label="Exercise"
              @update:model-value="chooseInitialExercise"
            />
          </div>
        </section>
        <section class="initial-setup-step" :class="{ unavailable: !pendingExercise }">
          <span class="initial-step-number mono">2</span>
          <div class="initial-step-content">
            <div class="initial-step-heading">
              <strong>Choose load</strong>
              <small v-if="pendingExercise">This creates three editable sets.</small>
              <small v-else>Select an exercise first.</small>
            </div>
            <div v-if="pendingExercise" class="initial-load-options">
              <button
                v-for="mode in LOADING_MODES"
                :key="mode"
                type="button"
                :class="[`loading-${mode}`, { unprofiled: !pendingExercise.recommended_rep_profile[mode] }]"
                :aria-label="`Choose ${loadingModeLabel(mode)} and create three sets`"
                @click="completeInitialSetup(mode)"
              >
                <i aria-hidden="true" />
                <span>{{ loadingModeLabel(mode) }}</span>
                <small class="mono">
                  {{ initialRange(mode).min }}–{{ initialRange(mode).max }} reps
                  <template v-if="!pendingExercise.recommended_rep_profile[mode]"> · generic</template>
                </small>
              </button>
            </div>
            <div v-else class="initial-load-placeholder" aria-hidden="true">
              <span v-for="mode in LOADING_MODES" :key="mode" />
            </div>
          </div>
        </section>
      </div>

      <div v-if="expanded" class="slot-details">
        <div class="form-grid two-columns">
          <label class="field">
            <span class="field-label">Slot name</span>
            <input v-model="model.name" class="text-input" maxlength="200" placeholder="Primary chest press" />
          </label>
          <label class="field">
            <span class="field-label">Role</span>
            <select v-model="model.role" class="select-input">
              <option value="PRIMARY_PROGRESSIVE">Primary progressive</option>
              <option value="SECONDARY_PROGRESSIVE">Secondary progressive</option>
              <option value="VOLUME_ACCUMULATION">Volume accumulation</option>
              <option value="ACCESSORY">Accessory</option>
            </select>
          </label>
        </div>
        <section class="slot-loading-prescription">
          <div class="slot-loading-heading">
            <span class="field-label">Loading</span>
            <p>Apply one mode or cycle to every set.</p>
          </div>
          <LoadingModePicker
            :model-value="model.loading_mode"
            @select="applySlotLoadingMode"
          />
          <LoadingCycleEditor v-model="slotCycleModel" :fallback-mode="model.loading_mode" />
        </section>
        <label class="field">
          <span class="field-label">Goal</span>
          <input v-model="model.goal" class="text-input" placeholder="Why this slot exists in the plan" />
        </label>
        <label class="field">
          <span class="field-label">Description</span>
          <textarea v-model="model.description" class="text-area" rows="2" placeholder="Optional execution or programming context" />
        </label>
        <div class="slot-intent-layout">
          <div class="field">
            <span class="field-label">Intentional target muscles</span>
            <MuscleTargetSelector v-model="model.target_muscle_slugs" :muscles="muscles" />
            <p class="intent-help">This is the purpose of the slot, not calculated recruitment.</p>
          </div>
          <aside v-if="model.target_muscle_slugs.length" class="slot-muscle-map" aria-label="Target muscle preview">
            <header>
              <span class="section-label">Intent map</span>
              <span class="mono">{{ model.target_muscle_slugs.length }} targets</span>
            </header>
            <BodyViewer :vector="targetVector" mode="etu" :interactive="false" />
          </aside>
        </div>

        <div class="fallback-heading">
          <div>
            <span class="section-label">Fallback exercises</span>
            <p>Alternatives keep this slot's purpose and identity.</p>
          </div>
          <button class="button" type="button" @click="addFallback">+ Add fallback</button>
        </div>
        <ExerciseVariantEditor
          v-for="(arrayIndex, fallbackIndex) in fallbackIndices"
          :key="model.variants[arrayIndex]!.clientKey"
          v-model="model.variants[arrayIndex]!"
          :exercises="exercises"
          :path="`${path}.variants.${model.variants[arrayIndex]!.clientKey}`"
          :issues="issues"
          :fallback-index="fallbackIndex"
          :fallback-count="fallbackIndices.length"
          :slot-loading-mode="model.loading_mode"
          :slot-loading-cycle="model.loading_cycle"
          @remove="removeVariant(arrayIndex)"
          @move="moveFallback(fallbackIndex, $event)"
        />
        <p v-if="issues.some((issue) => issue.path === `${path}.variants`)" class="field-error">
          {{ issues.find((issue) => issue.path === `${path}.variants`)?.message }}
        </p>
      </div>
      <button class="slot-disclosure" type="button" @click="expanded = !expanded">
        {{ expanded ? 'Hide slot details' : `Edit role, intent${fallbackIndices.length ? ', and fallbacks' : ', targets, and fallbacks'}` }}
        <span aria-hidden="true">{{ expanded ? '↑' : '↓' }}</span>
      </button>
    </div>
  </article>
</template>
