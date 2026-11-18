import type { DayIcon } from '@/api/plan-types'

/**
 * The glyph for each training-day goal, as the inner markup of a 24x24 SVG.
 *
 * The set follows the Agonez mark: a body carved in marble with the worked muscle lit.
 * So every glyph is built from two tones of `currentColor` — the stone at `MARBLE`
 * opacity, the trained part at full strength — which means a day icon inherits the
 * plan's accent, works in both themes, and says at a glance *what today is for*.
 *
 * Shapes are filled, not hairlined: they have to survive 20px, where only mass reads.
 * The body icons deliberately share one bust and one pair of legs, exactly as the
 * app's own body map does, so the eye learns the silhouette once and then only reads
 * the light.
 */
const MARBLE = '.26'

const stone = (markup: string): string =>
  markup.replace(/<(path|rect|circle|ellipse)/g, `<$1 fill-opacity="${MARBLE}"`)

/**
 * Draw a body as an inked contour rather than a filled mass, the way the Agonez mark
 * is drawn. An outlined body reads as a body at 20px; a filled one reads as a blob,
 * and it swallows the muscle sitting on top of it.
 */
const outline = (markup: string): string =>
  markup.replace(
    /<(path|rect|circle|ellipse)/g,
    '<$1 fill="none" stroke="currentColor" stroke-opacity=".55" stroke-width="1.3"'
    + ' stroke-linejoin="round" stroke-linecap="round"',
  )

/** Head and shoulders, inked. The torso muscles are read against this. */
const TORSO = outline(
  '<circle cx="12" cy="4.4" r="2.5" />'
  + '<path d="M12 8.6c-3.1 0-5.9 1.2-7 2.9-.6.8-.8 1.7-.8 2.6v6.4h15.6v-6.4c0-.9-.2-1.8-.8-2.6-1.1-1.7-3.9-2.9-7-2.9z" />',
)

const FIGURE_TOP =
  '<circle cx="12" cy="3.7" r="2.5" />'
  + '<path d="M8.7 7.6h6.6l-.8 7h-5z" />'
  + '<rect x="4.3" y="7.6" width="2.7" height="7.6" rx="1.35" transform="rotate(-11 5.65 11.4)" />'
  + '<rect x="17" y="7.6" width="2.7" height="7.6" rx="1.35" transform="rotate(11 18.35 11.4)" />'

const FIGURE_BOTTOM =
  '<rect x="8.7" y="14" width="2.9" height="7.2" rx="1.45" />'
  + '<rect x="12.4" y="14" width="2.9" height="7.2" rx="1.45" />'

/** The whole standing figure in stone; upper and lower each light their own half of it. */
const FIGURE = stone(FIGURE_TOP + FIGURE_BOTTOM)

export const DAY_ICON_GLYPHS: Record<DayIcon, string> = {
  // The whole figure, lit end to end: everything is on the table today.
  full_body: FIGURE_TOP + FIGURE_BOTTOM,

  // The same body in both, with the other half lit. Read side by side they are a pair.
  upper: FIGURE + FIGURE_TOP,
  lower: FIGURE + FIGURE_BOTTOM,

  // Movements, not muscles: the stone body and the direction of the effort.
  push:
    stone('<rect x="2.8" y="4.4" width="5.4" height="15.2" rx="2.2" />')
    + '<path d="M10.4 9.4h4.4V6.2L21.2 12l-6.4 5.8v-3.2h-4.4z" />',
  pull:
    stone('<rect x="15.8" y="4.4" width="5.4" height="15.2" rx="2.2" />')
    + '<path d="M13.6 9.4H9.2V6.2L2.8 12l6.4 5.8v-3.2h4.4z" />',

  // Single leg, inspired by the reference: bent thigh, distinct knee, calf and foot.
  // One solid silhouette with no internal muscle highlighting. `lower` remains both legs.
  legs:
    '<path d="M17.63 1.60 C17.50,1.52,17.76,1.11,17.06,1.50 C16.36,1.89,13.37,3.69,12.19,4.65 '
    + 'C11.01,5.61,8.45,8.22,7.90,8.95 C7.34,9.67,7.80,9.94,7.90,10.28 C7.99,10.62,8.50,11.20,8.66,11.62 '
    + 'C8.82,12.03,9.05,12.77,9.14,13.53 C9.22,14.29,9.40,16.83,9.33,17.54 '
    + 'C9.25,18.25,8.89,18.63,8.56,19.06 C8.23,19.49,7.20,20.58,6.75,20.88 '
    + 'C6.30,21.17,5.24,21.23,5.03,21.35 C4.82,21.48,5.05,21.72,5.13,21.83 '
    + 'C5.20,21.94,5.43,22.13,5.60,22.21 C5.78,22.30,6.29,22.49,6.46,22.50 '
    + 'C6.64,22.51,6.77,22.32,6.94,22.31 C7.11,22.30,7.38,22.55,7.80,22.40 '
    + 'C8.22,22.26,9.68,21.37,10.19,21.16 C10.69,20.96,11.44,20.89,11.71,20.78 '
    + 'C11.98,20.67,12.20,20.44,12.29,20.30 C12.37,20.17,12.47,19.99,12.38,19.73 '
    + 'C12.30,19.47,11.74,18.73,11.62,18.30 C11.50,17.87,11.37,17.03,11.43,16.39 '
    + 'C11.49,15.75,12.03,14.01,12.10,13.34 C12.16,12.66,11.73,11.57,11.90,11.14 '
    + 'C12.08,10.71,12.81,10.36,13.43,10.00 C14.06,9.63,16.09,8.72,16.77,8.28 '
    + 'C17.46,7.84,18.50,6.84,18.78,6.56 C19.06,6.28,18.97,6.44,18.97,6.08 '
    + 'C18.97,5.73,18.89,4.31,18.78,3.79 C18.67,3.28,18.26,2.35,18.11,2.07 '
    + 'C17.96,1.79,17.77,1.67,17.63,1.60 Z" />',
  glutes:
    stone(
      '<path d="M8.4 2.4h7.2c.8 0 1.4.7 1.3 1.5l-.6 4H7.7l-.6-4c-.1-.8.5-1.5 1.3-1.5z" />'
      + '<rect x="4.8" y="16.4" width="5.4" height="5.2" rx="2.5" />'
      + '<rect x="13.8" y="16.4" width="5.4" height="5.2" rx="2.5" />',
    )
    + '<ellipse cx="7.9" cy="12.4" rx="4.5" ry="5" transform="rotate(-8 7.9 12.4)" />'
    + '<ellipse cx="16.1" cy="12.4" rx="4.5" ry="5" transform="rotate(8 16.1 12.4)" />',
  // A heavy lower leg: the belly swells wide under the knee, then runs to a thin ankle.
  calves:
    outline(
      '<path d="M10.8 2.6h3.6c.5 0 .9.4.9.9v15.4h-4.4v-2.4c0-.9-.4-1.6-1.1-2.3-1.6-1.6-2.8-3.4-2.8-5.6'
      + 'c0-2.2 1.1-3.9 2.5-5.1.4-.4.5-.9.5-1.4 0-.5.4-.9.9-.9z" />'
      + '<path d="M10.4 18.9h4.9l3.3 1c.6.2 1 .7 1 1.3h-9.2z" />',
    )
    + '<path d="M11.6 5c1.4 0 2.4 1.4 2.4 3.4 0 1.7-.4 3-.4 4.5 0 1 .2 1.8.4 2.5-.7.4-1.6.6-2.4.6'
    + '-2.2 0-3.8-1.6-3.8-4.2 0-1.6.5-3.1 1.2-4.5.7-1.4 1.6-2.3 2.6-2.3z" />',

  // A single-muscle day draws the muscle itself, big and solid, with only enough stone
  // around it to say where on the body it sits. The muscle is the whole point, so it
  // owns the glyph rather than glowing somewhere inside a bust.
  // Flat slabs under the collarbone, not two round lamps.
  chest:
    TORSO
    + '<path d="M11.4 10.9v3.1c0 .5-.4.9-.9.9-1.7 0-3.2-.2-4.3-.7-.6-.2-.9-.8-.9-1.4v-.9c0-.5.4-1 .9-1.1 1.7-.4 3.5-.6 5.2-.7z" />'
    + '<path d="M12.6 10.9v3.1c0 .5.4.9.9.9 1.7 0 3.2-.2 4.3-.7.6-.2.9-.8.9-1.4v-.9c0-.5-.4-1-.9-1.1-1.7-.4-3.5-.6-5.2-.7z" />',
  // The whole back: lats flaring from the armpits, down past a narrow waist.
  back:
    TORSO
    + '<path d="M11.4 10.6v8.2c0 .5-.4.9-.9.9h-.3c-.4 0-.8-.2-1-.6-1.6-2.9-2.4-5.1-2.4-6.4 0-1 1.5-1.9 4.6-2.1z" />'
    + '<path d="M12.6 10.6v8.2c0 .5.4.9.9.9h.3c.4 0 .8-.2 1-.6 1.6-2.9 2.4-5.1 2.4-6.4 0-1-1.5-1.9-4.6-2.1z" />'
    + outline('<path d="M12 10.8v8.8" />'),
  // Caps angled down and out over the point of the shoulder, where a front or side
  // raise puts them, rather than sitting behind the body like a rear delt.
  shoulders:
    TORSO
    + '<path d="M8.6 10.1c-2.2.5-3.8 1.5-4.5 2.7-.5.8-.6 1.8-.4 2.7.1.5.6.8 1.1.6 1.7-.6 3-1.6 3.9-3 .5-.8.6-1.8.4-2.5-.1-.4-.3-.6-.5-.5z" />'
    + '<path d="M15.4 10.1c2.2.5 3.8 1.5 4.5 2.7.5.8.6 1.8.4 2.7-.1.5-.6.8-1.1.6-1.7-.6-3-1.6-3.9-3-.5-.8-.6-1.8-.4-2.5.1-.4.3-.6.5-.5z" />',
  // Single flexed arm, inspired by the reference: fist, forearm, elbow and biceps contour.
  // One solid silhouette with no internal muscle highlighting.
  arms:
    '<path d="M8.50 1.50 C7.79,1.55,7.25,2.61,6.88,3.12 C6.52,3.62,5.84,4.69,5.63,5.45 '
    + 'C5.42,6.21,5.55,7.89,5.27,9.04 C4.99,10.19,3.75,12.79,3.47,14.42 C3.20,16.06,3.05,20.77,3.12,21.78 '
    + 'C3.18,22.80,2.65,22.23,4.01,22.32 C5.37,22.41,11.95,22.57,13.71,22.50 '
    + 'C15.46,22.43,16.89,22.01,17.65,21.78 C18.41,21.55,19.21,21.05,19.63,20.71 '
    + 'C20.04,20.36,20.72,19.60,20.88,19.09 C21.05,18.58,21.11,17.33,20.88,16.76 '
    + 'C20.65,16.18,19.69,15.02,19.09,14.60 C18.49,14.19,17.00,13.66,16.22,13.53 '
    + 'C15.43,13.39,13.66,13.41,12.99,13.53 C12.32,13.64,11.57,14.05,11.01,14.42 '
    + 'C10.46,14.79,8.96,16.63,8.68,16.40 C8.40,16.17,8.88,13.55,8.86,12.63 C8.84,11.71,8.45,9.77,8.50,9.22 '
    + 'C8.55,8.67,8.90,8.53,9.22,8.32 C9.54,8.11,10.58,7.90,11.01,7.60 C11.45,7.30,12.37,6.31,12.63,5.99 '
    + 'C12.88,5.66,13.03,5.32,12.99,5.09 C12.94,4.86,12.29,4.40,12.27,4.19 '
    + 'C12.25,3.99,12.78,3.66,12.81,3.47 C12.83,3.29,13.00,3.01,12.45,2.76 C11.90,2.50,9.21,1.45,8.50,1.50 '
    + 'Z" />',
  core:
    stone(
      '<path d="M7.6 3.6h8.8c.9 0 1.6.8 1.5 1.7l-.9 11.2c-.2 2.5-2.2 4.4-4.6 4.4h-.8c-2.4 0-4.4-1.9-4.6-4.4L6.1 5.3c-.1-.9.6-1.7 1.5-1.7z" />',
    )
    + '<rect x="8.3" y="5.6" width="3.1" height="2.8" rx="1" />'
    + '<rect x="12.6" y="5.6" width="3.1" height="2.8" rx="1" />'
    + '<rect x="8.3" y="9.2" width="3.1" height="2.8" rx="1" />'
    + '<rect x="12.6" y="9.2" width="3.1" height="2.8" rx="1" />'
    + '<rect x="8.3" y="12.8" width="3.1" height="2.8" rx="1" />'
    + '<rect x="12.6" y="12.8" width="3.1" height="2.8" rx="1" />'
    + '<path d="M9.5 16.6h5l-2.5 3.5z" />',

  cardio:
    '<path d="M12 20.3C6.8 16.4 3.6 13.3 3.6 9.8 3.6 7 5.8 5.1 8.4 5.1c1.6 0 3 .8 3.6 2 .6-1.2 2-2 3.6-2 2.6 0 4.8 1.9 4.8 4.7 0 3.5-3.2 6.6-8.4 10.5z" />',
  // Running figure in mid-stride. Connected joints, opposing arms and a clear stride.
  liss:
    '<circle cx="16.6" cy="3.8" r="2.1" />'
    + '<path d="M14.6 6.7 11.8 11.4 10.5 13.6" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" />'
    + '<path d="M13.9 8.1 17.1 10.2 20.5 9.2" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" />'
    + '<path d="M12.8 8 9.4 7.5 7 10.6" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" />'
    + '<path d="M10.5 13.5 15.5 15.5 17.9 20.7" fill="none" stroke="currentColor" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round" />'
    + '<path d="M10.5 13.5 7.2 17.3 3.6 17.4" fill="none" stroke="currentColor" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round" />',
  hiit: '<path d="M13.8 2.3 5.6 13.4h4.8L9.2 21.7 18.4 10h-5.4z" />',
  conditioning:
    stone('<circle cx="12" cy="14" r="7" />')
    + '<rect x="9.5" y="2.2" width="5" height="2.4" rx="1.2" />'
    + '<rect x="10.8" y="4.2" width="2.4" height="3.1" rx="1" />'
    + '<rect x="11.1" y="8.8" width="1.9" height="5.8" rx=".95" transform="rotate(36 12.05 11.7)" />'
    + '<circle cx="12" cy="14" r="1.5" />',
  // Range of motion: one arc, travelled both ways.
  mobility:
    '<path d="M5.8 15.2A7 7 0 0 1 18.2 8.8" fill="none" stroke="currentColor" stroke-width="2.7" stroke-linecap="round" />'
    + '<path d="M3.2 16.6 4 11.8l4.3 2z" />'
    + '<path d="M20.8 7.4 20 12.2l-4.3-2z" />',
  rest:
    '<path d="M20.3 14.7A8.7 8.7 0 0 1 9.3 3.7a8.3 8.3 0 1 0 11 11z" />',
  // Three more ways to say the same thing, so consecutive rest days need not look alike.
  bed:
    outline(
      '<path d="M2.8 19.8V9.4" />'
      + '<path d="M2.8 13h16.4c1.1 0 2 .9 2 2v4.8" />'
      + '<path d="M2.8 17.2h18.4" />',
    )
    + '<rect x="4.6" y="13.9" width="4.6" height="2.6" rx="1.2" />',
  recharge:
    outline('<rect x="2.6" y="7.2" width="15.8" height="9.6" rx="2.6" /><path d="M20.4 10.6v2.8" />')
    + '<path d="M11.4 8.6 7 12.8h3.2l-.6 3.4 4.4-4.4h-3.2z" />',
  sleep: outline('<path d="M12.6 4.2h7.4l-7.4 7.2h7.4" /><path d="M4.4 13h6.2l-6.2 6h6.2" />'),
  // The bar stays loaded; what comes down is the weight on it.
  deload:
    stone('<rect x="3.4" y="4" width="17.2" height="3.1" rx="1.55" />')
    + '<path d="M10.2 9h3.6v5.3h3.5L12 21 6.7 14.3h3.5z" />',
  // A summit attempt: the stone climbs, the top is lit, the flag is planted.
  test:
    stone('<path d="M12 6.4 20.8 20.6H3.2z" />')
    + '<path d="M12 6.4l3.7 6H8.3z" />'
    + '<rect x="11.2" y="1.8" width="1.7" height="5.4" rx=".85" />'
    + '<path d="M12.9 2.2h5.3l-1.7 2.1 1.7 2.1h-5.3z" />',
  // Whatever the athlete actually plays on a sport day.
  sport:
    stone('<circle cx="12" cy="12" r="8.6" />')
    + '<path d="M12 7.4 15.8 10.2 14.3 14.7H9.7L8.2 10.2z" />'
    + '<path d="M12 7.4V3.6M15.8 10.2l3.6-1.2M14.3 14.7l2.3 3.1M9.7 14.7l-2.3 3.1M8.2 10.2 4.6 9"'
    + ' fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />',
}

/** The order the picker offers, grouped the way a plan is actually written. */
export const DAY_ICON_ORDER: readonly DayIcon[] = [
  'full_body', 'upper', 'lower', 'push', 'pull',
  'legs', 'glutes', 'calves', 'chest', 'back', 'shoulders', 'arms', 'core',
  'cardio', 'liss', 'hiit', 'conditioning', 'mobility',
  'rest', 'bed', 'recharge', 'sleep', 'deload', 'test', 'sport',
]
