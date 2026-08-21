import type {
  DayDraft,
  ExerciseSlotDraft,
  ExerciseSlotRole,
  ExerciseVariantDraft,
  ExerciseVariantType,
  PlanDraftArtifact,
  PlanDraftUpdate,
  SetInfraDraft,
  WorkoutUnitDraft,
} from '@/api/plan-types'

interface EditorIdentity {
  clientKey: string
}

export interface EditorSet extends SetInfraDraft, EditorIdentity {}

export interface EditorVariant extends Omit<ExerciseVariantDraft, 'sets'>, EditorIdentity {
  sets: EditorSet[]
}

export interface EditorSlot extends Omit<ExerciseSlotDraft, 'variants'>, EditorIdentity {
  variants: EditorVariant[]
}

export interface EditorWorkoutUnit
  extends Omit<WorkoutUnitDraft, 'exercise_slots'>,
    EditorIdentity {
  exercise_slots: EditorSlot[]
}

export interface EditorDay extends Omit<DayDraft, 'workout_unit'>, EditorIdentity {
  workout_unit: EditorWorkoutUnit | null
}

export interface PlanEditorState
  extends Omit<PlanDraftUpdate, 'days'> {
  days: EditorDay[]
}

export interface PlanValidationIssue {
  path: string
  message: string
}

let clientKeyCounter = 0

function clientKey(kind: string, id: number | null): string {
  clientKeyCounter += 1
  return id == null ? `${kind}-new-${clientKeyCounter}` : `${kind}-${id}`
}

function editorSet(item: SetInfraDraft): EditorSet {
  return { ...item, reps: { ...item.reps }, clientKey: clientKey('set', item.id) }
}

function editorVariant(item: ExerciseVariantDraft): EditorVariant {
  return {
    ...item,
    clientKey: clientKey('variant', item.id),
    sets: item.sets.map(editorSet),
  }
}

function editorSlot(item: ExerciseSlotDraft): EditorSlot {
  return {
    ...item,
    clientKey: clientKey('slot', item.id),
    target_muscle_slugs: [...item.target_muscle_slugs],
    variants: item.variants.map(editorVariant),
  }
}

function editorWorkout(item: WorkoutUnitDraft): EditorWorkoutUnit {
  return {
    ...item,
    clientKey: clientKey('workout', item.id),
    exercise_slots: item.exercise_slots.map(editorSlot),
  }
}

function editorDay(item: DayDraft): EditorDay {
  return {
    ...item,
    clientKey: clientKey('day', item.id),
    workout_unit: item.workout_unit ? editorWorkout(item.workout_unit) : null,
  }
}

export function toPlanEditorState(artifact: PlanDraftArtifact): PlanEditorState {
  return {
    id: artifact.id,
    revision_id: artifact.revision_id,
    revision_no: artifact.revision_no,
    lock_version: artifact.lock_version,
    name: artifact.name,
    description: artifact.description,
    days: artifact.days.map(editorDay),
  }
}

export function toPlanDraftUpdate(editor: PlanEditorState): PlanDraftUpdate {
  return {
    id: editor.id,
    revision_id: editor.revision_id,
    revision_no: editor.revision_no,
    lock_version: editor.lock_version,
    name: editor.name,
    description: editor.description,
    days: editor.days.map((day, dayIndex) => ({
      id: day.id,
      ordinal: dayIndex,
      weekday: day.weekday,
      name: day.name,
      description: day.description,
      workout_unit: day.workout_unit
        ? {
            id: day.workout_unit.id,
            name: day.workout_unit.name,
            description: day.workout_unit.description,
            warmup_notes: day.workout_unit.warmup_notes,
            stretch_notes: day.workout_unit.stretch_notes,
            exercise_slots: day.workout_unit.exercise_slots.map((slot, slotIndex) => ({
              id: slot.id,
              ordinal: slotIndex,
              name: slot.name,
              description: slot.description,
              goal: slot.goal,
              role: slot.role,
              volume_axis: slot.volume_axis,
              target_muscle_slugs: [...slot.target_muscle_slugs],
              variants: slot.variants.map((variant, variantIndex) => ({
                id: variant.id,
                ordinal: variantIndex,
                variant_type: variant.variant_type,
                exercise_slug: variant.exercise_slug,
                sets: variant.sets.map((item, setIndex) => ({
                  id: item.id,
                  ordinal: setIndex,
                  reps: { ...item.reps },
                  rir: item.rir,
                  min_volume_level: item.min_volume_level,
                })),
              })),
            })),
          }
        : null,
    })),
  }
}

export function createDay(ordinal: number): EditorDay {
  return {
    id: null,
    clientKey: clientKey('day', null),
    ordinal,
    weekday: null,
    name: `Day ${ordinal + 1}`,
    description: null,
    workout_unit: null,
  }
}

export function createWorkout(dayName: string): EditorWorkoutUnit {
  return {
    id: null,
    clientKey: clientKey('workout', null),
    name: dayName.trim() || 'Training session',
    description: null,
    warmup_notes: null,
    stretch_notes: null,
    exercise_slots: [],
  }
}

export function createSlot(ordinal: number): EditorSlot {
  return {
    id: null,
    clientKey: clientKey('slot', null),
    ordinal,
    name: null,
    description: null,
    goal: null,
    role: 'ACCESSORY',
    volume_axis: null,
    target_muscle_slugs: [],
    variants: [],
  }
}

export function createVariant(
  variantType: ExerciseVariantType,
  ordinal: number,
  exerciseSlug = '',
): EditorVariant {
  return {
    id: null,
    clientKey: clientKey('variant', null),
    ordinal,
    variant_type: variantType,
    exercise_slug: exerciseSlug,
    sets: [],
  }
}

export function createSet(ordinal: number, source?: EditorSet): EditorSet {
  return {
    id: null,
    clientKey: clientKey('set', null),
    ordinal,
    reps: source ? { ...source.reps } : { min: 8, max: 12 },
    rir: source?.rir ?? 2,
    min_volume_level: source?.min_volume_level ?? 0,
  }
}

function duplicatedDayName(name: string, days: EditorDay[]): string {
  const trimmed = name.trim() || 'Day'
  const root = trimmed.replace(/ copy(?: \d+)?$/i, '')
  const existing = new Set(days.map((day) => day.name.trim().toLocaleLowerCase()))
  let candidate = `${root} copy`
  let suffix = 2
  while (existing.has(candidate.toLocaleLowerCase())) {
    candidate = `${root} copy ${suffix}`
    suffix += 1
  }
  return candidate
}

function duplicateWorkout(source: EditorWorkoutUnit, dayName: string, copyName: string): EditorWorkoutUnit {
  return {
    ...source,
    id: null,
    clientKey: clientKey('workout', null),
    name: source.name.trim() === dayName.trim() ? copyName : source.name,
    exercise_slots: source.exercise_slots.map((slot, slotIndex) => ({
      ...slot,
      id: null,
      clientKey: clientKey('slot', null),
      ordinal: slotIndex,
      target_muscle_slugs: [...slot.target_muscle_slugs],
      variants: slot.variants.map((variant, variantIndex) => ({
        ...variant,
        id: null,
        clientKey: clientKey('variant', null),
        ordinal: variantIndex,
        sets: variant.sets.map((item, setIndex) => ({
          ...item,
          id: null,
          clientKey: clientKey('set', null),
          ordinal: setIndex,
          reps: { ...item.reps },
        })),
      })),
    })),
  }
}

export function duplicateDay(days: EditorDay[], index: number): EditorDay | null {
  const source = days[index]
  if (!source) return null
  const name = duplicatedDayName(source.name, days)
  const duplicate: EditorDay = {
    ...source,
    id: null,
    clientKey: clientKey('day', null),
    ordinal: index + 1,
    name,
    workout_unit: source.workout_unit
      ? duplicateWorkout(source.workout_unit, source.name, name)
      : null,
  }
  days.splice(index + 1, 0, duplicate)
  days.forEach((day, ordinal) => {
    day.ordinal = ordinal
  })
  return duplicate
}

export function moveOrdered<T extends { ordinal: number }>(
  items: T[],
  index: number,
  direction: -1 | 1,
): void {
  const destination = index + direction
  if (destination < 0 || destination >= items.length) return
  const [item] = items.splice(index, 1)
  if (!item) return
  items.splice(destination, 0, item)
  items.forEach((entry, ordinal) => {
    entry.ordinal = ordinal
  })
}

export function removeOrdered<T extends { ordinal: number }>(items: T[], index: number): void {
  items.splice(index, 1)
  items.forEach((entry, ordinal) => {
    entry.ordinal = ordinal
  })
}

export function roleLabel(role: ExerciseSlotRole): string {
  return {
    PRIMARY_PROGRESSIVE: 'Primary progressive',
    SECONDARY_PROGRESSIVE: 'Secondary progressive',
    VOLUME_ACCUMULATION: 'Volume accumulation',
    ACCESSORY: 'Accessory',
  }[role]
}

export function validatePlanEditor(editor: PlanEditorState): PlanValidationIssue[] {
  const issues: PlanValidationIssue[] = []
  if (!editor.name.trim()) issues.push({ path: 'name', message: 'Plan name is required.' })

  editor.days.forEach((day) => {
    const dayPath = `days.${day.clientKey}`
    if (!day.name.trim()) issues.push({ path: `${dayPath}.name`, message: 'Day name is required.' })
    if (!day.workout_unit) return
    if (!day.workout_unit.name.trim()) {
      issues.push({ path: `${dayPath}.workout.name`, message: 'Workout name is required.' })
    }
    day.workout_unit.exercise_slots.forEach((slot) => {
      const slotPath = `${dayPath}.slots.${slot.clientKey}`
      const defaults = slot.variants.filter((variant) => variant.variant_type === 'DEFAULT')
      if (slot.variants.length && defaults.length !== 1) {
        issues.push({
          path: `${slotPath}.variants`,
          message: 'A populated slot needs exactly one default exercise.',
        })
      }
      slot.variants.forEach((variant) => {
        const variantPath = `${slotPath}.variants.${variant.clientKey}`
        if (!variant.exercise_slug) {
          issues.push({ path: variantPath, message: 'Choose an exercise before saving.' })
        }
        variant.sets.forEach((item) => {
          const setPath = `${variantPath}.sets.${item.clientKey}`
          if (!Number.isInteger(item.reps.min) || item.reps.min <= 0) {
            issues.push({ path: setPath, message: 'Minimum reps must be a positive whole number.' })
          }
          if (!Number.isInteger(item.reps.max) || item.reps.max < item.reps.min) {
            issues.push({ path: setPath, message: 'Maximum reps must be at least the minimum.' })
          }
          if (!Number.isInteger(item.rir) || item.rir < 0 || item.rir > 4) {
            issues.push({ path: setPath, message: 'RIR must be between 0 and 4.' })
          }
        })
      })
    })
  })
  return issues
}
