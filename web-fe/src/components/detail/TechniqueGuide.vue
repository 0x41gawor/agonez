<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'

import TechniqueValue from '@/components/detail/TechniqueValue.vue'

type TechniqueTone = 'neutral' | 'motion' | 'cue' | 'warning' | 'effort' | 'danger' | 'safety'

interface TechniqueFieldDefinition {
  key: string
  label: string
  icon: string
  tone?: TechniqueTone
}

interface TechniqueGroupDefinition {
  key: string
  label: string
  icon: string
  description: string
  fields: TechniqueFieldDefinition[]
}

const props = defineProps<{ data: Record<string, unknown> }>()
const { t } = useI18n()

// Canonical UI order. This intentionally lives in frontend code rather than
// configuration or the database, so JSON key ordering cannot change the guide.
const TLDR_SEQUENCE: TechniqueFieldDefinition[] = [
  { key: 'setup', label: 'atlas.technique.setup', icon: '🧰' },
  { key: 'execution', label: 'atlas.technique.execution', icon: '▶' },
  { key: 'focus', label: 'atlas.technique.focus', icon: '🎯', tone: 'cue' },
  { key: 'stop_when', label: 'atlas.technique.stopWhen', icon: '✋', tone: 'warning' },
]

const TECHNIQUE_GROUPS: TechniqueGroupDefinition[] = [
  {
    key: 'overview',
    label: 'atlas.technique.movementOverview',
    icon: '🧭',
    description: 'atlas.technique.movementOverviewDescription',
    fields: [
      { key: 'overview', label: 'atlas.technique.overview', icon: '◎' },
      { key: 'plane_of_movement', label: 'atlas.technique.plane', icon: '↗', tone: 'motion' },
      { key: 'primary_joint_actions', label: 'atlas.technique.jointActions', icon: '⚙', tone: 'motion' },
    ],
  },
  {
    key: 'preparation',
    label: 'atlas.technique.preparation',
    icon: '🧰',
    description: 'atlas.technique.preparationDescription',
    fields: [
      { key: 'equipment_setup', label: 'atlas.technique.equipment', icon: '🔧' },
      { key: 'starting_position', label: 'atlas.technique.startingPosition', icon: '📍' },
      { key: 'grip', label: 'atlas.technique.grip', icon: '✊' },
      { key: 'stance', label: 'atlas.technique.stance', icon: '🦶' },
      { key: 'bracing', label: 'atlas.technique.bracing', icon: '🛡', tone: 'safety' },
    ],
  },
  {
    key: 'execution',
    label: 'atlas.technique.repetition',
    icon: '🔁',
    description: 'atlas.technique.repetitionDescription',
    fields: [
      { key: 'concentric', label: 'atlas.technique.concentric', icon: '↑', tone: 'motion' },
      { key: 'eccentric', label: 'atlas.technique.eccentric', icon: '↓', tone: 'motion' },
      { key: 'end_position', label: 'atlas.technique.endPosition', icon: '◎' },
      { key: 'range_of_motion', label: 'atlas.technique.range', icon: '↔', tone: 'motion' },
      { key: 'tempo_notes', label: 'atlas.technique.tempo', icon: '⏱' },
    ],
  },
  {
    key: 'cues',
    label: 'atlas.technique.cues',
    icon: '💡',
    description: 'atlas.technique.cuesDescription',
    fields: [
      { key: 'internal_cues', label: 'atlas.technique.internalCues', icon: '🧠', tone: 'cue' },
      { key: 'external_cues', label: 'atlas.technique.externalCues', icon: '👁', tone: 'cue' },
    ],
  },
  {
    key: 'effort',
    label: 'atlas.technique.effort',
    icon: '🌡',
    description: 'atlas.technique.effortDescription',
    fields: [
      { key: 'technical_failure', label: 'atlas.technique.technicalFailure', icon: '⚠', tone: 'warning' },
      { key: 'rir_1_indicators', label: 'atlas.technique.rir1', icon: '😤', tone: 'effort' },
      { key: 'rir_0_definition', label: 'atlas.technique.rir0', icon: '😫', tone: 'danger' },
    ],
  },
  {
    key: 'troubleshooting',
    label: 'atlas.technique.troubleshooting',
    icon: '🧩',
    description: 'atlas.technique.troubleshootingDescription',
    fields: [
      { key: 'common_mistakes', label: 'atlas.technique.commonMistakes', icon: '⚠', tone: 'warning' },
      { key: 'safety_notes', label: 'atlas.technique.safetyNotes', icon: '🛡', tone: 'safety' },
      { key: 'individualization', label: 'atlas.technique.individualization', icon: '🧬' },
    ],
  },
]

const knownKeys = new Set(['tldr', ...TECHNIQUE_GROUPS.flatMap((group) => group.fields.map((field) => field.key))])

function hasContent(value: unknown): boolean {
  if (value == null) return false
  if (typeof value === 'string') return Boolean(value.trim())
  if (Array.isArray(value)) return value.length > 0
  if (typeof value === 'object') return Object.keys(value).length > 0
  return true
}

function fallbackLabel(key: string): string {
  return key.replaceAll('_', ' ').replace(/^./, (letter) => letter.toUpperCase())
}

const tldr = computed(() => {
  const value = props.data.tldr
  const record = value && typeof value === 'object' && !Array.isArray(value)
    ? value as Record<string, unknown>
    : {}
  const desired = TLDR_SEQUENCE.filter((field) => hasContent(record[field.key]))
  const known = new Set(TLDR_SEQUENCE.map((field) => field.key))
  const extras = Object.keys(record)
    .filter((key) => !known.has(key) && hasContent(record[key]))
    .map((key) => ({ key, label: fallbackLabel(key), icon: '•', tone: 'neutral' as TechniqueTone }))
  return [...desired, ...extras].map((field) => ({
    ...field,
    label: field.label.startsWith('atlas.') ? t(field.label) : field.label,
    value: record[field.key],
  }))
})

const groups = computed(() => TECHNIQUE_GROUPS.map((group) => ({
  ...group,
  label: t(group.label),
  description: t(group.description),
  fields: group.fields
    .filter((field) => hasContent(props.data[field.key]))
    .map((field) => ({ ...field, label: t(field.label), value: props.data[field.key] })),
})).filter((group) => group.fields.length))

const extras = computed(() => Object.keys(props.data)
  .filter((key) => !knownKeys.has(key) && hasContent(props.data[key]))
  .map((key) => ({ key, label: fallbackLabel(key), icon: '•', value: props.data[key] })))

const empty = computed(() => !tldr.value.length && !groups.value.length && !extras.value.length)
</script>

<template>
  <section class="technique-guide panel">
    <header>
      <div><h2>{{ $t('atlas.technique.title') }}</h2><span>{{ $t('atlas.technique.subtitle') }}</span></div>
      <span class="chip mono">{{ $t('atlas.technique.protocol') }}</span>
    </header>

    <p v-if="empty" class="honest-empty">{{ $t('atlas.technique.empty') }}</p>
    <div v-else class="technique-guide-body">
      <section v-if="tldr.length" class="technique-tldr">
        <header><span>⚡</span><div><h3>TL;DR</h3><p>{{ $t('atlas.technique.tldrDescription') }}</p></div></header>
        <div>
          <article v-for="field in tldr" :key="field.key" :class="`tone-${field.tone ?? 'neutral'}`">
            <h4><span aria-hidden="true">{{ field.icon }}</span>{{ field.label }}</h4>
            <TechniqueValue :value="field.value" />
          </article>
        </div>
      </section>

      <section v-for="group in groups" :key="group.key" class="technique-group">
        <header><span aria-hidden="true">{{ group.icon }}</span><div><h3>{{ group.label }}</h3><p>{{ group.description }}</p></div></header>
        <div class="technique-field-list">
          <article v-for="field in group.fields" :key="field.key" :class="`tone-${field.tone ?? 'neutral'}`">
            <h4><span aria-hidden="true">{{ field.icon }}</span>{{ field.label }}</h4>
            <TechniqueValue :value="field.value" />
          </article>
        </div>
      </section>

      <section v-if="extras.length" class="technique-group">
        <header><span aria-hidden="true">＋</span><div><h3>{{ $t('atlas.technique.additional') }}</h3><p>{{ $t('atlas.technique.additionalDescription') }}</p></div></header>
        <div class="technique-field-list">
          <article v-for="field in extras" :key="field.key">
            <h4><span aria-hidden="true">{{ field.icon }}</span>{{ field.label }}</h4>
            <TechniqueValue :value="field.value" />
          </article>
        </div>
      </section>
    </div>
  </section>
</template>
