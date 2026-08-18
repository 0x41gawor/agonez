# PlanCreator PLAN tab implementation plan

## Scope

Implement the structural PlanCreator editor against the live relational draft API:

`Plan → Day → WorkoutUnit → ExerciseSlot → ExerciseVariant → SetInfraPrescription`

The first delivery contains the PLAN tab only. ANALYSIS and MODULATION remain visible,
disabled future tabs. It does not calculate biomechanics, volume, recovery, fatigue, or
progression.

## Existing-system decisions

- Preserve Vue 3, TypeScript, Vite, Vue Router, Pinia, the same-origin API client, and
  the current Claude-derived tokens/components.
- Activate the existing `My Plans` shell position and add `/plans` plus
  `/plans/:planId` routes.
- Keep HTTP orchestration at the view/composable boundary. Nested editor components
  receive catalog data and edit the in-memory aggregate; they do not call APIs.
- Keep API DTOs separate from pure editor operations. New rows use `id: null`; IDs
  returned by the backend are retained verbatim.
- Use manual save with explicit dirty/saving/saved/failure states. This avoids noisy
  writes while users type and makes optimistic-lock conflicts easy to understand.
- Load the small exercise and muscle catalogs once per editor. Selectors filter those
  live API records locally and never hardcode exercise or muscle names.
- Normalize day, slot, variant, and set ordinals after every structural edit and again
  immediately before save.

## UX shape

- `/plans` lists persisted plans, creates a plan, opens an editor, and deletes a plan.
- `/plans/:planId` provides PLAN / ANALYSIS / MODULATION tabs, plan metadata, ordered
  day cards, optional workout units, slot cards, exercise variants, and compact set rows.
- Slot summaries emphasize their stable purpose/role, then nest DEFAULT and FALLBACK
  exercises inside. Optional description, goal, target muscles, and notes use
  progressive disclosure.
- All move controls are deterministic and work with keyboard/touch; no drag library is
  introduced.
- Conflict state never overwrites local edits. The user can explicitly reload the
  current server draft.

## Visual identity refinement

- Loaded days start collapsed so the complete microcycle remains visible as a compact
  ordered overview; new or selected days can still be expanded independently.
- Slot headers use the DEFAULT exercise's catalog `image_url` and a theme-aware role
  accent. Primary progressive, secondary progressive, volume accumulation, and
  accessory slots each have a distinct rail, frame tint, dot, and badge color.
- Intentional target muscles can be previewed on the shared Atlas `anatomy.svg` renderer
  inside expanded slot details. The map is not mounted for collapsed slots, avoiding a
  large-plan rendering cost, and is explicitly labeled as slot intent rather than
  calculated recruitment.

## Verification

- Pure editor tests cover ordering, ID preservation, variants, sets, and validation.
- Component/composable tests cover loaded rendering, add/remove operations, successful
  lock-version replacement, conflict behavior, and round-trip structure.
- Run lint, strict type checking, Vitest, production build, Docker deployment, and a
  live create/save/reload/delete smoke test through the production proxy.
