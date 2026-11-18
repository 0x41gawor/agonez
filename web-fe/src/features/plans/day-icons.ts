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

  // Both legs, hip to feet, with the quads lit inside them.
  legs:
    outline(
      '<path d="M6.2 3h11.6v3.4c0 1-.3 1.8-.8 2.6l.8 8.6c.1.9-.6 1.7-1.5 1.7h-2c-.8 0-1.5-.6-1.6-1.4'
      + 'l-.7-6.8-.7 6.8c-.1.8-.8 1.4-1.6 1.4h-2c-.9 0-1.6-.8-1.5-1.7l.8-8.6c-.5-.8-.8-1.6-.8-2.6z" />'
      + '<path d="M6.3 19.3H4.6c-.6 0-1 .5-1 1v.6c0 .4.3.7.7.7h4.9" />'
      + '<path d="M17.7 19.3h1.7c.6 0 1 .5 1 1v.6c0 .4-.3.7-.7.7h-4.9" />',
    )
    + '<path d="M7.8 8.4h3l-.5 5.2c0 .6-.5 1-1 1s-1-.4-1-1z" />'
    + '<path d="M16.2 8.4h-3l.5 5.2c0 .6.5 1 1 1s1-.4 1-1z" />',
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
  // The arm bent at the elbow, forearm up, with the bicep filled inside it.
  arms:
    outline(
      '<path d="M2.5 20.9v-5.8c0-3.9 3-6.9 6.9-6.9h1.2l-2-4.8c-.7-1.6.1-3.5 1.7-4.2 1.6-.7 3.5.1 4.2 1.7'
      + 'l2.6 6.7c.5 1 .3 2.2-.2 3.1l-4 7.4c-.6 1-1.6 1.6-2.8 1.6z" />',
    )
    + '<ellipse cx="7.5" cy="15.1" rx="4" ry="3.7" />',
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
  // A runner mid-stride, built as a pictogram: lean limbs at the angles the eye expects.
  liss:
    '<circle cx="16" cy="3.6" r="2.1" />'
    + '<rect x="11.6" y="5.6" width="2.8" height="8.2" rx="1.4" transform="rotate(26 13 9.7)" />'
    + '<rect x="15" y="6.4" width="2" height="6" rx="1" transform="rotate(-74 16 9.4)" />'
    + '<rect x="9.4" y="6.6" width="2" height="5.8" rx="1" transform="rotate(46 10.4 9.5)" />'
    + '<rect x="11.4" y="12.4" width="2.4" height="5.8" rx="1.2" transform="rotate(-56 12.6 15.3)" />'
    + '<rect x="14.8" y="15.4" width="2.3" height="6" rx="1.15" transform="rotate(-18 16 18.4)" />'
    + '<rect x="7.4" y="12.8" width="2.4" height="5.4" rx="1.2" transform="rotate(46 8.6 15.5)" />'
    + '<rect x="4" y="15.8" width="2.3" height="5.4" rx="1.15" transform="rotate(14 5.2 18.5)" />',
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
