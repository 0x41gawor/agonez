<script setup lang="ts">
import { computed, ref } from 'vue'

import type { LoadingMode, LoadSpec, SetRole } from '@/api/plan-types'
import LoadingCycleEditor from '@/components/plans/LoadingCycleEditor.vue'
import LoadingModePicker from '@/components/plans/LoadingModePicker.vue'
import {
  effectiveLoadingPattern,
  type EditorSet,
  type PlanValidationIssue,
} from '@/features/plans/editor'

const model = defineModel<EditorSet>({ required: true })
const props = defineProps<{
  index: number
  count: number
  path: string
  issues: PlanValidationIssue[]
  slotLoadingMode: LoadingMode
  slotLoadingCycle: LoadingMode[] | null
}>()
defineEmits<{
  move: [direction: -1 | 1]
  remove: []
  duplicate: []
}>()

const error = computed(() => props.issues.find((issue) => issue.path === props.path)?.message)
const effectivePattern = computed(() => effectiveLoadingPattern(
  props.slotLoadingMode,
  props.slotLoadingCycle,
  model.value.loading_mode,
  model.value.loading_cycle,
))
const visibleLoadingMode = computed<LoadingMode>({
  get: () => effectivePattern.value[0]!,
  set: (value) => {
    model.value.loading_mode = value
    model.value.loading_cycle = null
  },
})
const metadataOpen = ref(false)

const roleOptions: SetRole[] = [
  'rampup',
  'working',
  'working_topset',
  'working_backoff',
  'working_amrap',
]
const loadKinds: LoadSpec['kind'][] = [
  'absolute',
  'athlete_selected',
  'relative_to_set',
  'relative_to_working',
  'table_derived',
  'ordinal_variant',
]

function selectRole(role: SetRole): void {
  model.value.role = role
  if (role === 'rampup' && model.value.rir.startsWith('RIR')) {
    model.value.rir = 'NOT_APPLICABLE'
  } else if (role !== 'rampup' && model.value.rir === 'NOT_APPLICABLE') {
    model.value.rir = 'UNDEFINED'
  }
}

function selectLoadKind(kind: LoadSpec['kind']): void {
  const firstReference = Array.from({ length: props.count }, (_, index) => index)
    .find((index) => index !== props.index) ?? 0
  const specs: Record<LoadSpec['kind'], LoadSpec> = {
    absolute: { kind: 'absolute' },
    athlete_selected: { kind: 'athlete_selected' },
    relative_to_set: { kind: 'relative_to_set', ref_set_idx: firstReference, pct: 100 },
    relative_to_working: { kind: 'relative_to_working', pct: 100 },
    table_derived: { kind: 'table_derived', ref_set_idx: firstReference, table: 'apre10' },
    ordinal_variant: { kind: 'ordinal_variant', level: 1 },
  }
  model.value.load_spec = specs[kind]
}
</script>

<template>
  <div class="set-editor" :class="[{ invalid: error }, `loading-${effectivePattern[0]}`]">
    <span class="set-number mono">{{ index + 1 }}</span>
    <label class="set-role-control">
      <span>{{ $t('plans.setEditor.role') }}</span>
      <select :value="model.role" @change="selectRole(($event.target as HTMLSelectElement).value as SetRole)">
        <option v-for="role in roleOptions" :key="role" :value="role">{{ $t(`plans.setRoles.${role}`) }}</option>
      </select>
    </label>
    <label>
      <span>{{ $t('plans.setEditor.minReps') }}</span>
      <input v-model.number="model.reps.min" type="number" min="1" max="32767" inputmode="numeric" />
    </label>
    <span class="set-range-separator" aria-hidden="true">–</span>
    <label>
      <span>{{ $t('plans.setEditor.maxReps') }}</span>
      <input v-model.number="model.reps.max" type="number" min="1" max="32767" inputmode="numeric" />
    </label>
    <label>
      <span>RIR</span>
      <select v-model="model.rir">
        <option v-for="rir in ['RIR0', 'RIR1', 'RIR2', 'RIR3', 'RIR4']" :key="rir" :value="rir">{{ rir.replace('RIR', '') }}</option>
        <option value="NOT_APPLICABLE">{{ $t('plans.rir.notApplicable') }}</option>
        <option value="UNDEFINED">{{ $t('plans.rir.undefined') }}</option>
      </select>
    </label>
    <div class="set-loading-control">
      <span class="set-loading-label">{{ $t('plans.setEditor.load') }}</span>
      <LoadingModePicker v-model="visibleLoadingMode" compact />
      <LoadingCycleEditor
        v-model="model.loading_cycle"
        :fallback-mode="effectivePattern[0]!"
        compact
      />
    </div>
    <div class="ordered-actions" :aria-label="$t('plans.setEditor.actions')">
      <button type="button" :class="{ active: metadataOpen }" :title="$t('plans.setEditor.metadata')" @click="metadataOpen = !metadataOpen">⋯</button>
      <button type="button" :disabled="index === 0" :title="$t('plans.setEditor.moveUp')" @click="$emit('move', -1)">↑</button>
      <button type="button" :disabled="index === count - 1" :title="$t('plans.setEditor.moveDown')" @click="$emit('move', 1)">↓</button>
      <button type="button" :title="$t('plans.setEditor.duplicate')" @click="$emit('duplicate')">⧉</button>
      <button class="danger-action" type="button" :title="$t('plans.setEditor.remove')" @click="$emit('remove')">×</button>
    </div>
    <section v-if="metadataOpen" class="set-metadata-drawer">
      <label>
        <span>{{ $t('plans.setEditor.repSemantics') }}</span>
        <select v-model="model.reps.semantics">
          <option value="undefined">{{ $t('plans.repSemantics.undefined') }}</option>
          <option value="estimate">{{ $t('plans.repSemantics.estimate') }}</option>
          <option value="gating">{{ $t('plans.repSemantics.gating') }}</option>
        </select>
      </label>
      <label class="load-spec-kind">
        <span>{{ $t('plans.setEditor.loadSpec') }}</span>
        <select :value="model.load_spec.kind" @change="selectLoadKind(($event.target as HTMLSelectElement).value as LoadSpec['kind'])">
          <option v-for="kind in loadKinds" :key="kind" :value="kind">{{ $t(`plans.loadSpecs.${kind}`) }}</option>
        </select>
      </label>
      <label v-if="model.load_spec.kind === 'relative_to_set' || model.load_spec.kind === 'table_derived'">
        <span>{{ $t('plans.setEditor.referenceSet') }}</span>
        <select v-model.number="model.load_spec.ref_set_idx">
          <option v-for="setIndex in count" :key="setIndex - 1" :value="setIndex - 1" :disabled="model.load_spec.kind === 'relative_to_set' && setIndex - 1 === index">
            {{ $t('plans.setEditor.setNumber', { number: setIndex }) }}
          </option>
        </select>
      </label>
      <label v-if="model.load_spec.kind === 'relative_to_set' || model.load_spec.kind === 'relative_to_working'">
        <span>{{ $t('plans.setEditor.percent') }}</span>
        <input v-model.number="model.load_spec.pct" type="number" min="0.01" step="0.5" />
      </label>
      <label v-if="model.load_spec.kind === 'table_derived'">
        <span>{{ $t('plans.setEditor.table') }}</span>
        <input v-model.trim="model.load_spec.table" maxlength="100" placeholder="apre10" />
      </label>
      <label v-if="model.load_spec.kind === 'ordinal_variant'">
        <span>{{ $t('plans.setEditor.level') }}</span>
        <input v-model.number="model.load_spec.level" type="number" min="1" max="32767" />
      </label>
      <p>{{ $t('plans.setEditor.metadataHelp') }}</p>
    </section>
    <p v-if="error" class="field-error">{{ error }}</p>
  </div>
</template>
