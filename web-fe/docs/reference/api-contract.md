# Handoff: Agonez Atlas (Exercises + Muscles knowledge atlas)

## Overview
High-fidelity product design for **Agonez**, a strength-training / musculoskeletal knowledge system. This package covers the **Atlas module**: Exercises index (list + grid), Muscles index (list + grid), Muscle detail, and Exercise detail with interactive anatomical load visualization (ETU / Recovery / Joint-load). Dual light/dark themes, an interactive anatomical SVG as a first-class data surface, and a complete REST API contract.

Target implementation: **Vue.js 3 SPA consuming a REST API** (see `api-contract.md`).

## About the Design Files
The files in this bundle are **design references created in HTML** — a working prototype showing intended look and behavior, not production code to copy directly. The task is to **recreate this design in Vue** (SFCs + Pinia/composables + vue-router) using the project's established patterns. Two pieces ARE directly portable as-is: the CSS custom-property theme block and the SVG injection/painting logic (plain DOM code, framework-agnostic).

- `Agonez Atlas.dc.html` — the full prototype. Markup is inside `<x-dc>…</x-dc>` (all inline styles); behavior is in the `class Component` script at the bottom. Ignore the `support.js` runtime and `sc-if`/`sc-for` tags — they map to `v-if`/`v-for`.
- `data.js` — real records extracted from the SQL dump (47 muscles, 48 exercises, engine vectors for `dragon_flag` and `weighted_russian_twist`). Use as API mock data.
- `assets/human.svg` — the interactive anatomy asset (canonical: `<g id="{slug}" data-type="muscle|joint">`, child geometry `data-view="front|rear"`).
- `assets/logo-mark.png`, `assets/agonez-logo.png` — brand mark (crop) and the full 9-variant logo sheet.
- `api-contract.md` — REST endpoints + JSON shapes the frontend expects.

## Fidelity
**High-fidelity.** Colors, typography, spacing, and interactions are final intent. Recreate pixel-perfectly. Primary target widths 1440–1920 px; lists gain `overflow-x:auto` below ~1250 px content width.

## Routing
- `/atlas/exercises` and `/atlas/muscles` — index screens (one component, tab param)
- `/atlas/exercises/:slug`, `/atlas/muscles/:slug` — detail screens
- Top nav also reserves `My Plans` and `Dashboard` (inert, `title="Planned module"`, color `--text3`).

## Design Tokens
Everything themes through CSS custom properties on `body[data-theme]`. Copy verbatim:

Dark (default):
```
--bg:#0e1013  --bg2:#12151a  --panel:#14181d  --panel2:#191e24
--border:#232930  --border2:#2e353d
--text:#e7eaed  --text2:#9aa3ac  --text3:#66717b
--accent:#d0b487  --accent2:#e6d3b0  --accentDim:rgba(208,180,135,.13)
--etu:#25b581  --rec:#f4635e  --joint:#e5a13c
--anatBody:#1c2127 --anatFar:#171c21 --anatLine:#3d4650 --anatMuscle:#2b333c --anatStroke:#505b66
--rowHover:#1a2028 --inputBg:#101419 --chipBg:#1c2229 --shadow:0 10px 28px rgba(0,0,0,.45)
```
Light:
```
--bg:#f7f6f3  --bg2:#f0eeea  --panel:#fdfdfc  --panel2:#f3f1ed
--border:#e5e2db  --border2:#d3cfc6
--text:#22262b  --text2:#5b636c  --text3:#8d949c
--accent:#8f6f38  --accent2:#6e5527  --accentDim:rgba(143,111,56,.11)
--etu:#0d9d6d  --rec:#dd4f4a  --joint:#bf7c14
--anatBody:#edeae5 --anatFar:#f5f3ef --anatLine:#b6b1a8 --anatMuscle:#d9d5cd --anatStroke:#98928a
--rowHover:#f0eee9 --inputBg:#fbfaf8 --chipBg:#efece7 --shadow:0 10px 28px rgba(40,32,15,.09)
```
Semantics: `--accent` (warm stone, logo-derived) is chrome-only (active nav/tabs, filter count, links, propulsive bars). Data colors are reserved: **ETU → `--etu` emerald**, **recovery → `--rec` coral**, **joint load → `--joint` amber**. Never mix chrome accent into heatmaps.

Typography: **Geist** (UI; weights 400/500/600/700, base 13px, line-height 1.45) + **Geist Mono** (all numerals, units, slugs, micro-labels). Google Fonts. Headings: detail H1 24px/650/-.3px; section titles 13px/600; group labels 10.5px/600/uppercase/1px tracking; article headings 19px (H1-equivalent, bottom border) and 15px.

Spacing/shape: page gutter 20px, max content width 1560px; card radius 10–12px, chips 5px, pills 20px; panels `1px solid var(--border)` on `var(--panel)`; column gap 18px; row padding 8px 14px. No shadows except popovers (`var(--shadow)`).

## Screens / Views

### 1. App shell
- 52px sticky header: logo tile 26px (rounded 6, bg `#efe6d8`) + `AGONEZ` wordmark (700, 3px tracking) + nav (active = `--accentDim` pill) + right side mono status `ATLAS v0.1 · 48 exercises · 47 muscles` + theme toggle button (bordered, dot indicator).
- Theme toggle flips `document.body.dataset.theme`.

### 2. Atlas index (`/atlas/exercises`, `/atlas/muscles`)
Toolbar row: segmented Exercises/Muscles tabs with mono counts → search input 240px → Filter button with active-count badge → Sort select + direction button (`↑`/`↓`) → List/Grid segmented toggle.
- **Filter popover** (anchored under Filter button, radius 10, `--shadow`): checkbox groups — exercises: Body part / Target category / Mechanics tier / Resistance; muscles: Body part / Complex. Active filters render as removable chips row + "Clear all".
- **Main split**: `grid-template-columns: minmax(0,1fr) 372px`, right column sticky (`top:68px`) = **Anatomy rail**.
- **Exercise list columns**: `minmax(200px,1.7fr) 64px 118px 118px 128px 80px 158px` → Exercise (name 600 + full-name sub in `--text3`, green 6px dot when engine vectors exist), Body, Target (chip), Mechanics, Resistance, Load kg (mono, right), FCSA demand (inline bar `--accent` @ .75 + mono value). Wrap in `min-width:900px` inside `overflow-x:auto` panel.
- **Muscle list columns**: `minmax(200px,1.7fr) 64px 100px 138px 84px 118px 148px` → Muscle (display name + italic Latin sub), Body, Complex chip, Mass g (bar), Vol cm³, Fiber I/II (stacked two-color bar: `--text3` / `--rec` @ .8 + mono `II 55%`), Proj. FCSA (bar `--etu`).
- **Grid cards** (`repeat(auto-fill,minmax(230px,1fr))`): 16:9 placeholder → name → sub → chips → mono footer (load/demand or mass/FCSA). Hover: border `--border2` + translateY(-1px).
- **Placeholder system** (all missing imagery, everywhere): `repeating-linear-gradient(45deg, var(--panel2) 0 9px, var(--panel) 9px 18px)` + centered mono 10px `--text3` label (e.g. `exercise visual · pending`). Dimensions always identical to the final image slot.
- **Empty results state**: dashed border box, "No entries match", clear-filters button.
- **Rail behavior**: hover exercise row → paint its ETU (or propulsive fallback) vector on the body + show legend gradient + status line; hover muscle row → highlight that muscle `--etu`; active muscle filters → matching muscles tinted 26% etu, rest at opacity .45; SVG hover → row highlight (bidirectional); SVG click → open muscle. Footer status line always explains current paint.

### 3. Muscle detail
Left column + sticky rail (selected muscle filled `--etu`, all others opacity .5).
- Header card: 108px placeholder, H1 display name, mono slug chip, italic Latin name, chips (body/complex/architecture), hero stats (mono 16px + uppercase 10.5px labels): Mass g, Volume cm³, Proj. FCSA cm², Type II bias %.
- Structured data: 4 group cards (auto-fit minmax 240px) — Morphology (mass, volume, mass reference), Architecture (type, optimal fiber length cm, pennation °, cos), Capacity (PCSA, PCSA fiber, projected FCSA cm²), Programming traits (SMH factor, strength curve, leverage peak). Rows: label `--text2` left, mono value right, dotted separators.
- Fiber composition: 14px two-segment bar + mono captions.
- Related exercises panel: header notes `endpoint pending · computed client-side`; rows show `--etu` bar + `NN cm²` when `relation=measured`, mono `by target category` otherwise. Row click → exercise detail.
- Media: Image gallery (3 square placeholders labeled origin/insertion, fiber architecture, cross section), Videos (16:9 placeholders with ▶ ring — activate to YouTube embeds when real URLs exist), References (link cards: title + mono domain ↗).
- **Muscle Bible**: article panel, content max-width 720px, 14px/1.7. Markdown renderer supports h1–h3, lists, tables (uppercase mono-ish header row), blockquote → accent-left-border callout, bold/italic/code. Headings with no body render a dashed "Section not yet written." chip — sparse DB content is shown honestly, never faked. (`latissimus_dorsi` carries a written draft article marked `draft article · pending review`.)

### 4. Exercise detail
- Header card: placeholder, H1 + mono slug chip, full name, chips (body/target/tier/resistance/execution pattern), stats: Load capacity kg, Systemic FCSA demand cm², Total ETU cm², Peak joint exposure (joint name).
- Split: sticky viz panel (`minmax(380px,460px)`) + data column.
- **Viz panel**: segmented ETU/Recovery mode (active bg = 22% mix of mode color into panel) + "Joint load" checkbox overlay + front/rear body + legend (gradient `var(--anatMuscle) → mode color`, `0 → max`) + joint legend (amber ring, "ring weight ∝ exposure index") + hint line.
- **Heatmap math** (critical, keep exact):
  - ETU mode: `etu_vector[m]`; Recovery mode: `active_tension_exposure_vector[m] × muscle_recovery_cost_modifier_vector[m]`.
  - Normalize: `rel[m] = value[m] / muscle.pcsa_projected_fcsa_cm2`, then divide by max rel → 0..1.
  - Fill: `color-mix(in oklab, var(--anatMuscle), <modeColor> P%)` with `P = 12 + 88·i^0.75`. Intensity ≤ .02 → stays neutral (opacity .55). Uninvolved muscles dim to .55.
  - Joints: separate grammar — show joint groups, `opacity = .35 + .65·v`, `stroke-width = 1.5 + 4·v`, amber. Never painted like muscles.
- **Muscle exposure table**: columns Muscle / Raw cm² / ÷ capacity % / relative-intensity bar (mode color). Hover ⇄ body highlight bidirectional; click → muscle detail. Title/subtitle per mode ("effective training units per muscle" / "active tension × recovery cost modifier").
- Joint table (visible with overlay): name / index (2 decimals) / amber bar; subtitle `model-derived index · not a safety score`.
- No engine vectors: viz panel shows "Engine vectors pending" empty state; if only core `propulsive_fcsa_contribution_vector` exists, show that table labeled `from core schema · engine vectors pending` with `--accent` bars.
- Metadata group cards (Classification / Quantitative), Technique + Comments as separate dashed empty-state cards (they're distinct concepts), video placeholder row.

## The anatomical SVG (BodyViewer component)
This is the product's core component. Contract & pipeline (port from `buildView`/`mountBody`/`cropViews`/`paint*` in the prototype):
1. Fetch `human.svg` once, `DOMParser` it.
2. Per view (`front`, `rear`): deep-clone root; remove `<style> <text> metadata title desc .ground` and the legend group (a `<g>` of classless circles); remove every element whose `data-view` ≠ view; strip inline `fill`, `stroke`, `display` from all `[style]` elements (theming happens via CSS classes + custom properties); add class `agz-body`.
3. Restyle via a global stylesheet (see helmet `<style>` in the prototype): `.muscle{fill:var(--anatMuscle)}`, `.region{stroke:var(--anatStroke)}`, `.deep .region{opacity:.32;dasharray}`, `.joint{display:none}` until `agz-joints-on`, `.gap-mask{fill:var(--panel)}`.
4. Crop: union `getBBox()` of `.region` elements (retry over rAF up to 8 frames; fallback viewBoxes front `20 15 495 990`, rear `505 15 530 990`), pad 12, set `viewBox`.
5. Paint by setting `group.style.fill` / `.opacity` per slug; clear by resetting to ''.
6. Events: delegated mouseover/out/click on the container; tooltip = fixed-position singleton (muscle name, raw cm², ÷capacity %, "click to open muscle").
7. **Slug aliases** (SVG → DB): `anterior_deltoid→deltoid_anterior`, `lateral_deltoid→deltoid_lateral`, `posterior_deltoid→deltoid_posterior`, `rotator_cuff→rotator_cuffs`. Recommend fixing the SVG ids at the source instead.
8. Side view: architecture accepts a third view value (`data-view="side"` already reserved); add a view toggle when the asset lands.
Transitions: fill/opacity `.18s`; nothing else animates.

## Suggested Vue decomposition
`AppShell` / `AtlasIndexView` / `MuscleDetailView` / `ExerciseDetailView`; components: `SegmentedTabs`, `FilterPopover`, `FilterChips`, `SortControl`, `ViewToggle`, `ExerciseListRow`, `MuscleListRow`, `EntityCard`, `PlaceholderVisual`, `BodyViewer` (front/rear pair + legend + tooltip), `HeatmapLegend`, `MetadataGroupCard`, `HeroStats`, `RelatedExercises`, `MediaGallery`, `MarkdownArticle`, `EmptyState`. State: Pinia store for tab/filters/sort/view/search + hover linkage (`hoverSlug`, `hoverExercise`); theme in a composable persisting to localStorage.

## State management (as prototyped)
- Per-tab: `view (list|grid)`, `search`, `filters`, `sort {key, dir}` — exercises and muscles keep independent state.
- Cross-cutting: `hoverExercise`, `hoverMuscle`, `hoverSlug` (SVG⇄table sync), `vizMode (etu|rec)`, `showJoints`, `theme`.
- States to honor: loading skeletons (restrained), empty filter results, missing image/video/article, missing engine vectors, no related exercises, active filters, selected anatomical element.

## Data & API
- `api-contract.md` in this folder is the source of truth for endpoints and JSON.
- `data.js` (window.AGONEZ_DATA) mirrors the SQL dump for mocking: `{muscles[], exercises[], engine{slug→vectors}, coreVectors{slug→vector}}`.
- Numbers: mono font, `toLocaleString('en-US')`, units always visible (g, cm³, cm², kg, °).

## Assets
- `assets/human.svg` — provided asset (do not redraw anatomy).
- `assets/agonez-logo.png` — provided 3×3 logo sheet; `assets/logo-mark.png` is a crop of the primary (top-left) variant. Product may later let users switch variants.
- Fonts: Geist + Geist Mono (Google Fonts or self-hosted).

## Files in this bundle
- `Agonez Atlas.dc.html` — full prototype (markup + logic)
- `data.js`, `api-contract.md`
- `assets/human.svg`, `assets/logo-mark.png`, `assets/agonez-logo.png`
