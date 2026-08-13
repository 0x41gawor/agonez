<script setup lang="ts">
import { computed } from 'vue'

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

// Canonical UI order. This intentionally lives in frontend code rather than
// configuration or the database, so JSON key ordering cannot change the guide.
const TLDR_SEQUENCE: TechniqueFieldDefinition[] = [
  { key: 'setup', label: 'Setup', icon: '🧰' },
  { key: 'execution', label: 'Execution', icon: '▶' },
  { key: 'focus', label: 'Focus', icon: '🎯', tone: 'cue' },
  { key: 'stop_when', label: 'Stop when', icon: '✋', tone: 'warning' },
]

const TECHNIQUE_GROUPS: TechniqueGroupDefinition[] = [
  {
    key: 'overview',
    label: 'Movement overview',
    icon: '🧭',
    description: 'What the movement is and how the joints travel.',
    fields: [
      { key: 'overview', label: 'Overview', icon: '◎' },
      { key: 'plane_of_movement', label: 'Plane of movement', icon: '↗', tone: 'motion' },
      { key: 'primary_joint_actions', label: 'Primary joint actions', icon: '⚙', tone: 'motion' },
    ],
  },
  {
    key: 'preparation',
    label: 'Preparation',
    icon: '🧰',
    description: 'Build a repeatable base before the first repetition.',
    fields: [
      { key: 'equipment_setup', label: 'Equipment setup', icon: '🔧' },
      { key: 'starting_position', label: 'Starting position', icon: '📍' },
      { key: 'grip', label: 'Grip', icon: '✊' },
      { key: 'stance', label: 'Stance', icon: '🦶' },
      { key: 'bracing', label: 'Bracing', icon: '🛡', tone: 'safety' },
    ],
  },
  {
    key: 'execution',
    label: 'The repetition',
    icon: '🔁',
    description: 'How to move through one complete, controlled repetition.',
    fields: [
      { key: 'concentric', label: 'Concentric', icon: '↑', tone: 'motion' },
      { key: 'eccentric', label: 'Eccentric', icon: '↓', tone: 'motion' },
      { key: 'end_position', label: 'End position', icon: '◎' },
      { key: 'range_of_motion', label: 'Range of motion', icon: '↔', tone: 'motion' },
      { key: 'tempo_notes', label: 'Tempo notes', icon: '⏱' },
    ],
  },
  {
    key: 'cues',
    label: 'Coaching cues',
    icon: '💡',
    description: 'Short attention anchors for keeping the movement on track.',
    fields: [
      { key: 'internal_cues', label: 'Internal cues', icon: '🧠', tone: 'cue' },
      { key: 'external_cues', label: 'External cues', icon: '👁', tone: 'cue' },
    ],
  },
  {
    key: 'effort',
    label: 'Effort and failure',
    icon: '🌡',
    description: 'Recognize the boundary between a hard repetition and a changed exercise.',
    fields: [
      { key: 'technical_failure', label: 'Technical failure', icon: '⚠', tone: 'warning' },
      { key: 'rir_1_indicators', label: 'RIR 1 indicators', icon: '😤', tone: 'effort' },
      { key: 'rir_0_definition', label: 'RIR 0 definition', icon: '😫', tone: 'danger' },
    ],
  },
  {
    key: 'troubleshooting',
    label: 'Troubleshooting',
    icon: '🧩',
    description: 'Common corrections, safety boundaries, and acceptable variation.',
    fields: [
      { key: 'common_mistakes', label: 'Common mistakes', icon: '⚠', tone: 'warning' },
      { key: 'safety_notes', label: 'Safety notes', icon: '🛡', tone: 'safety' },
      { key: 'individualization', label: 'Individualization', icon: '🧬' },
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
  return [...desired, ...extras].map((field) => ({ ...field, value: record[field.key] }))
})

const groups = computed(() => TECHNIQUE_GROUPS.map((group) => ({
  ...group,
  fields: group.fields
    .filter((field) => hasContent(props.data[field.key]))
    .map((field) => ({ ...field, value: props.data[field.key] })),
})).filter((group) => group.fields.length))

const extras = computed(() => Object.keys(props.data)
  .filter((key) => !knownKeys.has(key) && hasContent(props.data[key]))
  .map((key) => ({ key, label: fallbackLabel(key), icon: '•', value: props.data[key] })))

const empty = computed(() => !tldr.value.length && !groups.value.length && !extras.value.length)
</script>

<template>
  <section class="technique-guide panel">
    <header>
      <div><h2>Technique</h2><span>Canonical execution guide</span></div>
      <span class="chip mono">ordered protocol</span>
    </header>

    <p v-if="empty" class="honest-empty">Canonical execution instructions have not been authored for this exercise yet.</p>
    <div v-else class="technique-guide-body">
      <section v-if="tldr.length" class="technique-tldr">
        <header><span>⚡</span><div><h3>TL;DR</h3><p>The shortest useful version before you start.</p></div></header>
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
        <header><span aria-hidden="true">＋</span><div><h3>Additional notes</h3><p>Further technique fields supplied by the exercise record.</p></div></header>
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
