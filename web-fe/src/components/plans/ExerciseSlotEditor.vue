<script setup lang="ts">
import { computed, ref } from 'vue'

import type { ExerciseListItem, MuscleListItem } from '@/api/types'
import BodyViewer from '@/components/anatomy/BodyViewer.vue'
import MediaImage from '@/components/common/MediaImage.vue'
import ExerciseSelector from '@/components/plans/ExerciseSelector.vue'
import ExerciseVariantEditor from '@/components/plans/ExerciseVariantEditor.vue'
import MuscleTargetSelector from '@/components/plans/MuscleTargetSelector.vue'
import {
  createVariant,
  roleLabel,
  type EditorSlot,
  type PlanValidationIssue,
} from '@/features/plans/editor'

const model = defineModel<EditorSlot>({ required: true })
const props = defineProps<{
  index: number
  count: number
  exercises: ExerciseListItem[]
  muscles: MuscleListItem[]
  path: string
  issues: PlanValidationIssue[]
}>()
defineEmits<{
  move: [direction: -1 | 1]
  remove: []
}>()

const expanded = ref(false)
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
const setCount = computed(() =>
  model.value.variants.reduce((total, variant) => total + variant.sets.length, 0),
)
const roleClass = computed(() => `role-${model.value.role.toLowerCase().replaceAll('_', '-')}`)
const targetVector = computed<Record<string, number>>(() =>
  Object.fromEntries(model.value.target_muscle_slugs.map((slug) => [slug, 1])),
)

function chooseInitialDefault(slug: string): void {
  if (!slug) return
  model.value.variants.unshift(createVariant('DEFAULT', 0, slug))
  model.value.variants.forEach((variant, ordinal) => {
    variant.ordinal = ordinal
  })
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
          :src="defaultExercise?.image_url"
          :alt="defaultExercise ? `${defaultExercise.name_full || defaultExercise.name} exercise` : 'No default exercise selected'"
          label="No image"
        />
      </div>
      <button class="slot-summary-main" type="button" :aria-expanded="expanded" @click="expanded = !expanded">
        <span class="slot-title-copy">
          <span class="slot-role-badge">
            <i aria-hidden="true" />{{ roleLabel(model.role) }}
          </span>
          <strong>{{ model.name?.trim() || 'Untitled exercise slot' }}</strong>
          <small>{{ defaultExercise?.name_full || defaultExercise?.name || 'Choose default exercise' }}</small>
        </span>
        <span class="slot-set-count mono">{{ setCount }} {{ setCount === 1 ? 'set' : 'sets' }}</span>
      </button>
      <div class="ordered-actions">
        <button type="button" :disabled="index === 0" title="Move slot up" @click="$emit('move', -1)">↑</button>
        <button type="button" :disabled="index === count - 1" title="Move slot down" @click="$emit('move', 1)">↓</button>
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
        />
      </template>
      <div v-else class="empty-default">
        <span class="section-label">Default exercise required for a populated slot</span>
        <ExerciseSelector
          model-value=""
          :exercises="exercises"
          label="Choose default exercise"
          @update:model-value="chooseInitialDefault"
        />
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
