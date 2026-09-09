# PlanCreator contextual guidance

## Purpose

Prevent easy-to-miss structural mistakes without inserting another step into the plan
creation flow. Guidance is advisory: it must never block editing or saving and it must
not silently mutate a plan.

## V1: missing rest day

- Evaluate the live editor draft in the browser.
- Stay hidden for a plan with no days; the existing empty state already explains how
  to begin.
- Show one suggestion when every modeled day contains a workout unit.
- Explain that rest days belong in the ordered microcycle and that Analysis uses them
  to preserve intended recovery intervals.
- Provide a `Review days` action that only returns the user to the day list.
- Disappear immediately when any day becomes an explicit rest day.

## Interaction

The coach is a fixed, bottom-right companion on the `PLAN` tab. A newly detected
suggestion opens once so that it cannot be missed. The user can minimize it into a
small `Plan check · 1` control and reopen it without losing editor position. Switching
tabs temporarily hides it while preserving that open/minimized choice.

The component receives an array of rule results rather than knowing plan semantics.
This keeps future checks separate from presentation and allows several suggestions to
share the same surface later.

## Visual treatment

- Neutral panel surfaces from the existing theme tokens.
- A restrained amber signal communicates attention, not failure.
- No red error styling, modal backdrop, chat metaphor, or animated pulse.
- Compact copy and one non-destructive action.
- On narrow screens the panel becomes a bottom sheet-sized card with safe-area spacing.

