import type {
  DayDraft,
  ExerciseSlotDraft,
  ExerciseSlotRole,
  ExerciseVariantDraft,
  ExerciseVariantType,
  LoadingMode,
  LoadSpec,
  PlanDraftArtifact,
  PlanDraftUpdate,
  SetInfraDraft,
  WorkoutUnitDraft,
} from '@/api/plan-types'
import type { RecommendedRepProfile } from '@/api/types'
import { i18n } from '@/i18n'

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

export interface ExerciseUnitOption {
  clientKey: string
  progressionId: string
  label: string
}

let clientKeyCounter = 0

function clientKey(kind: string, id: number | null): string {
  clientKeyCounter += 1
  return id == null ? `${kind}-new-${clientKeyCounter}` : `${kind}-${id}`
}

export function newProgressionId(): string {
  return globalThis.crypto.randomUUID()
}

function remapProgressionId(source: string, mapping: Map<string, string>): string {
  const existing = mapping.get(source)
  if (existing) return existing
  const created = newProgressionId()
  mapping.set(source, created)
  return created
}

function editorSet(item: SetInfraDraft): EditorSet {
  return {
    ...item,
    reps: { ...item.reps },
    role: item.role ?? 'working',
    load_spec: item.load_spec ? { ...item.load_spec } : { kind: 'absolute' },
    loading_cycle: item.loading_cycle ? [...item.loading_cycle] : null,
    clientKey: clientKey('set', item.id),
  }
}

function editorVariant(item: ExerciseVariantDraft): EditorVariant {
  return {
    ...item,
    clientKey: clientKey('variant', item.id),
    progression_id: item.progression_id || newProgressionId(),
    active_working_sets: item.active_working_sets ? { ...item.active_working_sets } : null,
    sets: item.sets.map(editorSet),
  }
}

function editorSlot(item: ExerciseSlotDraft): EditorSlot {
  return {
    ...item,
    clientKey: clientKey('slot', item.id),
    loading_cycle: item.loading_cycle ? [...item.loading_cycle] : null,
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
              loading_mode: slot.loading_mode,
              loading_cycle: slot.loading_cycle ? [...slot.loading_cycle] : null,
              target_muscle_slugs: [...slot.target_muscle_slugs],
              variants: slot.variants.map((variant, variantIndex) => ({
                id: variant.id,
                ordinal: variantIndex,
                variant_type: variant.variant_type,
                exercise_slug: variant.exercise_slug,
                progression_model_slug: variant.progression_model_slug,
                progression_id: variant.progression_id,
                active_working_sets: variant.active_working_sets
                  ? { ...variant.active_working_sets }
                  : null,
                sets: variant.sets.map((item, setIndex) => ({
                  id: item.id,
                  ordinal: setIndex,
                  reps: { ...item.reps },
                  rir: item.rir,
                  role: item.role,
                  load_spec: { ...item.load_spec },
                  min_volume_level: item.min_volume_level,
                  loading_mode: item.loading_mode,
                  loading_cycle: item.loading_cycle ? [...item.loading_cycle] : null,
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
    name: i18n.global.t('plans.editor.defaultDay', { number: ordinal + 1 }),
    description: null,
    workout_unit: null,
  }
}

export function createWorkout(dayName: string): EditorWorkoutUnit {
  return {
    id: null,
    clientKey: clientKey('workout', null),
    name: dayName.trim() || i18n.global.t('plans.editor.trainingSession'),
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
    loading_mode: 'moderate_load',
    loading_cycle: null,
    target_muscle_slugs: [],
    variants: [],
  }
}

export function createVariant(
  variantType: ExerciseVariantType,
  ordinal: number,
  exerciseSlug = '',
  progressionModelSlug: string | null = null,
): EditorVariant {
  return {
    id: null,
    clientKey: clientKey('variant', null),
    ordinal,
    variant_type: variantType,
    exercise_slug: exerciseSlug,
    progression_model_slug: progressionModelSlug,
    progression_id: newProgressionId(),
    active_working_sets: null,
    sets: [],
  }
}

export const LOADING_MODES: readonly LoadingMode[] = [
  'high_load',
  'moderate_load',
  'low_load',
]

export function loadingModeLabel(mode: LoadingMode): string {
  return i18n.global.t(`plans.loadingModes.${mode}`)
}

export function loadingModeShortLabel(mode: LoadingMode): string {
  return {
    high_load: 'H',
    moderate_load: 'M',
    low_load: 'L',
  }[mode]
}

export function effectiveLoadingPattern(
  slotMode: LoadingMode,
  slotCycle: LoadingMode[] | null,
  setMode: LoadingMode | null = null,
  setCycle: LoadingMode[] | null = null,
): LoadingMode[] {
  if (setCycle?.length) return setCycle
  if (setMode) return [setMode]
  if (slotCycle?.length) return slotCycle
  return [slotMode]
}

export function recommendedRepRange(
  profile: RecommendedRepProfile | null | undefined,
  mode: LoadingMode,
): { min: number; max: number } | null {
  const recommendation = profile?.[mode]
  return recommendation ? { ...recommendation } : null
}

function fallbackRepRange(mode: LoadingMode): { min: number; max: number } {
  return {
    high_load: { min: 5, max: 8 },
    moderate_load: { min: 8, max: 12 },
    low_load: { min: 12, max: 20 },
  }[mode]
}

export function initialRepRange(
  profile: RecommendedRepProfile | null | undefined,
  mode: LoadingMode,
): { min: number; max: number; semantics: 'undefined' } {
  return {
    ...(recommendedRepRange(profile, mode) ?? fallbackRepRange(mode)),
    semantics: 'undefined',
  }
}

export function createSet(
  ordinal: number,
  source?: EditorSet,
  loadingMode: LoadingMode = 'moderate_load',
  recommendedProfile?: RecommendedRepProfile | null,
): EditorSet {
  return {
    id: null,
    clientKey: clientKey('set', null),
    ordinal,
    reps: source ? { ...source.reps } : initialRepRange(recommendedProfile, loadingMode),
    rir: source?.rir ?? 'RIR2',
    role: source?.role ?? 'working',
    load_spec: source?.load_spec ? { ...source.load_spec } : { kind: 'absolute' },
    min_volume_level: source?.min_volume_level ?? 0,
    loading_mode: source ? source.loading_mode : loadingMode,
    loading_cycle: source?.loading_cycle ? [...source.loading_cycle] : null,
  }
}

function duplicatedDayName(name: string, days: EditorDay[]): string {
  const suffixText = i18n.global.t('plans.editor.copySuffix')
  const trimmed = name.trim() || i18n.global.t('plans.editor.defaultDayRoot')
  const root = trimmed.replace(/ (?:copy|kopia)(?: \d+)?$/i, '')
  const existing = new Set(days.map((day) => day.name.trim().toLocaleLowerCase()))
  let candidate = `${root}${suffixText}`
  let suffix = 2
  while (existing.has(candidate.toLocaleLowerCase())) {
    candidate = `${root}${suffixText} ${suffix}`
    suffix += 1
  }
  return candidate
}

function duplicatedSlotName(name: string | null, slots: EditorSlot[]): string {
  const suffixText = i18n.global.t('plans.editor.copySuffix')
  const untitled = i18n.global.t('plans.slot.untitled')
  const trimmed = name?.trim() || untitled
  const root = trimmed.replace(/ (?:copy|kopia)(?: \d+)?$/i, '')
  const existing = new Set(
    slots.map((slot) => (slot.name?.trim() || untitled).toLocaleLowerCase()),
  )
  let suffix = suffixText
  let candidate = `${root.slice(0, 200 - suffix.length)}${suffix}`
  let copyNumber = 2
  while (existing.has(candidate.toLocaleLowerCase())) {
    suffix = `${suffixText} ${copyNumber}`
    candidate = `${root.slice(0, 200 - suffix.length)}${suffix}`
    copyNumber += 1
  }
  return candidate
}

function duplicateSlotTree(
  source: EditorSlot,
  ordinal: number,
  name: string | null = source.name,
  progressionIds: Map<string, string> = new Map(),
): EditorSlot {
  return {
    ...source,
    id: null,
    clientKey: clientKey('slot', null),
    ordinal,
    name,
    loading_cycle: source.loading_cycle ? [...source.loading_cycle] : null,
    target_muscle_slugs: [...source.target_muscle_slugs],
    variants: source.variants.map((variant, variantIndex) => ({
      ...variant,
      id: null,
      clientKey: clientKey('variant', null),
      ordinal: variantIndex,
      progression_id: remapProgressionId(variant.progression_id, progressionIds),
      active_working_sets: variant.active_working_sets
        ? { ...variant.active_working_sets }
        : null,
      sets: variant.sets.map((item, setIndex) => ({
        ...item,
        id: null,
        clientKey: clientKey('set', null),
        ordinal: setIndex,
        reps: { ...item.reps },
        load_spec: { ...item.load_spec },
        loading_cycle: item.loading_cycle ? [...item.loading_cycle] : null,
      })),
    })),
  }
}

function duplicateWorkout(source: EditorWorkoutUnit, dayName: string, copyName: string): EditorWorkoutUnit {
  const progressionIds = new Map<string, string>()
  return {
    ...source,
    id: null,
    clientKey: clientKey('workout', null),
    name: source.name.trim() === dayName.trim() ? copyName : source.name,
    exercise_slots: source.exercise_slots.map((slot, slotIndex) =>
      duplicateSlotTree(slot, slotIndex, slot.name, progressionIds),
    ),
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

export function duplicateSlot(slots: EditorSlot[], index: number): EditorSlot | null {
  const source = slots[index]
  if (!source) return null
  const duplicate = duplicateSlotTree(source, index + 1, duplicatedSlotName(source.name, slots))
  slots.splice(index + 1, 0, duplicate)
  slots.forEach((slot, ordinal) => {
    slot.ordinal = ordinal
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

function referencesSet(spec: LoadSpec): spec is Extract<LoadSpec, { ref_set_idx: number }> {
  return spec.kind === 'relative_to_set' || spec.kind === 'table_derived'
}

function setReferenceTargets(sets: EditorSet[]): Map<string, string> {
  const targets = new Map<string, string>()
  for (const item of sets) {
    if (!referencesSet(item.load_spec)) continue
    const target = sets[item.load_spec.ref_set_idx]
    if (target) targets.set(item.clientKey, target.clientKey)
  }
  return targets
}

function restoreSetReferences(sets: EditorSet[], targets: Map<string, string>): void {
  sets.forEach((item, ordinal) => {
    item.ordinal = ordinal
    if (!referencesSet(item.load_spec)) return
    const targetKey = targets.get(item.clientKey)
    const targetIndex = sets.findIndex((candidate) => candidate.clientKey === targetKey)
    if (targetIndex < 0 || targetIndex === ordinal) {
      item.load_spec = { kind: 'absolute' }
    } else {
      item.load_spec.ref_set_idx = targetIndex
    }
  })
}

export function moveSetPrescription(
  sets: EditorSet[],
  index: number,
  direction: -1 | 1,
): void {
  const destination = index + direction
  if (destination < 0 || destination >= sets.length) return
  const targets = setReferenceTargets(sets)
  const [item] = sets.splice(index, 1)
  if (!item) return
  sets.splice(destination, 0, item)
  restoreSetReferences(sets, targets)
}

export function removeSetPrescription(sets: EditorSet[], index: number): void {
  const targets = setReferenceTargets(sets)
  sets.splice(index, 1)
  restoreSetReferences(sets, targets)
}

export function duplicateSetPrescription(sets: EditorSet[], index: number): void {
  const source = sets[index]
  if (!source) return
  const targets = setReferenceTargets(sets)
  const duplicate = createSet(index + 1, source)
  const sourceTarget = targets.get(source.clientKey)
  if (sourceTarget) targets.set(duplicate.clientKey, sourceTarget)
  sets.splice(index + 1, 0, duplicate)
  restoreSetReferences(sets, targets)
}

export function roleLabel(role: ExerciseSlotRole): string {
  return i18n.global.t(`plans.roles.${role}`)
}

export function validatePlanEditor(editor: PlanEditorState): PlanValidationIssue[] {
  const issues: PlanValidationIssue[] = []
  if (!editor.name.trim()) issues.push({ path: 'name', message: i18n.global.t('plans.editor.validation.planName') })

  editor.days.forEach((day) => {
    const dayPath = `days.${day.clientKey}`
    if (!day.name.trim()) issues.push({ path: `${dayPath}.name`, message: i18n.global.t('plans.editor.validation.dayName') })
    if (!day.workout_unit) return
    if (!day.workout_unit.name.trim()) {
      issues.push({ path: `${dayPath}.workout.name`, message: i18n.global.t('plans.editor.validation.workoutName') })
    }
    day.workout_unit.exercise_slots.forEach((slot) => {
      const slotPath = `${dayPath}.slots.${slot.clientKey}`
      const defaults = slot.variants.filter((variant) => variant.variant_type === 'DEFAULT')
      if (slot.variants.length && defaults.length !== 1) {
        issues.push({
          path: `${slotPath}.variants`,
          message: i18n.global.t('plans.editor.validation.defaultExercise'),
        })
      }
      slot.variants.forEach((variant) => {
        const variantPath = `${slotPath}.variants.${variant.clientKey}`
        if (!variant.exercise_slug) {
          issues.push({ path: variantPath, message: i18n.global.t('plans.editor.validation.chooseExercise') })
        }
        const workingCount = variant.sets.filter((item) => item.role !== 'rampup').length
        if (
          variant.active_working_sets
          && (
            variant.active_working_sets.min < 0
            || variant.active_working_sets.max < variant.active_working_sets.min
            || variant.active_working_sets.max > workingCount
          )
        ) {
          issues.push({
            path: variantPath,
            message: i18n.global.t('plans.editor.validation.activeWorkingSets'),
          })
        }
        variant.sets.forEach((item, setIndex) => {
          const setPath = `${variantPath}.sets.${item.clientKey}`
          if (!Number.isInteger(item.reps.min) || item.reps.min <= 0) {
            issues.push({ path: setPath, message: i18n.global.t('plans.editor.validation.minReps') })
          }
          if (!Number.isInteger(item.reps.max) || item.reps.max < item.reps.min) {
            issues.push({ path: setPath, message: i18n.global.t('plans.editor.validation.maxReps') })
          }
          if (!['RIR0', 'RIR1', 'RIR2', 'RIR3', 'RIR4', 'NOT_APPLICABLE', 'UNDEFINED'].includes(item.rir)) {
            issues.push({ path: setPath, message: i18n.global.t('plans.editor.validation.rir') })
          }
          if (referencesSet(item.load_spec)) {
            if (
              item.load_spec.ref_set_idx < 0
              || item.load_spec.ref_set_idx >= variant.sets.length
              || (item.load_spec.kind === 'relative_to_set' && item.load_spec.ref_set_idx === setIndex)
            ) {
              issues.push({ path: setPath, message: i18n.global.t('plans.editor.validation.setReference') })
            }
          }
        })
      })
    })
  })
  return issues
}
