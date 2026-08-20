# Handoff: Agonez Atlas Vue Frontend

Status: ready for frontend implementation  
Prepared: 2026-08-11  
Suggested frontend directory: `/home/agonez/fe`

## Mission

Build a production-quality Vue 3 SPA for the public Agonez Atlas. It must consume the
existing FastAPI backend and reproduce the supplied Claude design closely: exercise and
muscle indexes, muscle detail, exercise detail, interactive anatomy, light/dark themes,
filters, sorting, list/grid views, engine heatmaps, media, and honest empty states.

This task is frontend-only. Do not add authentication or per-user behavior to Atlas.
`My Plans` and `Dashboard` remain visibly reserved/inert until their separate modules
are designed.

## Read these first

Use this priority when sources differ:

1. Visual/interaction intent:
   [`be/docs/frontend-handoff.md`](/home/agonez/be/docs/frontend-handoff.md)
2. REST contract and expected JSON:
   [`be/docs/api-contract.md`](/home/agonez/be/docs/api-contract.md)
3. Actual backend response models:
   [`be/src/agonez_api/modules/atlas/schemas.py`](/home/agonez/be/src/agonez_api/modules/atlas/schemas.py)
4. Backend operation/deployment:
   [`be/README.md`](/home/agonez/be/README.md)
5. Earlier design brief and assets:
   - `/home/agonez/prompts/UI/Agonez - UI/UX design brief/design_brief.md`
   - `/home/agonez/prompts/UI/Agonez - UI/UX design brief/human.svg`
   - `/home/agonez/prompts/UI/Agonez - UI/UX design brief/agonez.logo.png`

The Claude handoff mentions `Agonez Atlas.dc.html`, `data.js`, and cropped logo assets.
Those files are not currently present in this workspace. Do not block on them: the
handoff, API contract, design brief, backend, anatomy SVG endpoint, and media library
are sufficient. If those files are supplied later, treat them as additional visual
references, not production code to copy verbatim.

## Running backend

The backend lives in `/home/agonez/be` and Docker Compose starts one `atlas-api`
container. PostgreSQL already runs separately.

Required exported shell variables:

- `NOME`: database user
- `AGANDSKODE`: database password
- `MINA`: PostgreSQL port exposed on the host
- `MAMMOONE`: API port exposed on the host

Start and verify:

```bash
source ~/.bashrc
cd /home/agonez/be
docker compose up --build -d
curl "http://127.0.0.1:${MAMMOONE}/health/ready"
```

The API listens on port `8000` inside its container and is exposed on the host as
`MAMMOONE`. Do not hard-code the numeric host port in frontend source.

For development, use a configurable `VITE_API_BASE_URL`, for example:

```text
VITE_API_BASE_URL=http://127.0.0.1:<value-of-MAMMOONE>
```

Prefer one API client that resolves API and relative media URLs against this origin.
For production, support an empty base URL so a reverse proxy can serve frontend, API,
and media from the same origin.

The backend CORS default permits `http://localhost:5173` and
`http://127.0.0.1:5173`. Update exported `CORS_ORIGINS` before starting the backend if
the frontend dev server uses a different origin.

## Implemented API

All Atlas endpoints are public GET endpoints:

| Endpoint | Frontend use |
|---|---|
| `/api/atlas/exercises` | Exercise index, filters, sorting, pagination, facets |
| `/api/atlas/exercises/{slug}` | Exercise detail and engine vectors |
| `/api/atlas/muscles` | Muscle index, filters, sorting, pagination, facets |
| `/api/atlas/muscles/{slug}` | Muscle detail, article links, video links, gallery |
| `/api/atlas/muscles/{slug}/exercises` | Related exercises |
| `/api/atlas/meta` | Enum options and live counts |
| `/assets/anatomy.svg` | Canonical anatomy SVG |
| `/health/live`, `/health/ready` | Operational status, not normal SPA traffic |
| `/docs`, `/openapi.json` | Interactive/generated API reference |

Current live inventory is 49 exercises, 47 muscles, 49 exercise hero images, and 47
muscle hero images. Always render counts returned by `/api/atlas/meta`; do not hard-code
these values.

### List request rules

- Exercise repeatable filters: `body_part`, `target_category`, `mechanics_tier`,
  `resistance_source`.
- Muscle repeatable filters: `body_part`, `complex`.
- Encode arrays as repeated query keys, not comma-separated strings:

```text
?body_part=Upper&body_part=Core
```

- Lists accept `q`, `sort`, `order`, `page`, and `per_page`.
- Default page size is 50; maximum is 100.
- List responses contain `items`, `total`, `page`, `per_page`, and `facets`.
- Use server results as authoritative. Debounce search and cancel stale requests.

### Actual-contract notes

- API numeric values are JSON numbers.
- Optional values are `null`; optional vectors can be `null` or `{}` and those states
  are intentionally different.
- Exercise detail includes the core
  `propulsive_fcsa_contribution_vector` at the top level.
- `engine: null` means engine evaluation is pending. When present, individual vectors
  may still be `null`.
- Muscle detail includes `display_name`, `image_url`, and `gallery`.
- Media URLs are normally relative, for example
  `/media/muscles/latissimus_dorsi.png`. Resolve them against the API origin, not the
  Vite frontend origin when those origins differ.
- A missing entity returns HTTP 404 with `{ "detail": "..." }`.
- Invalid route/query input returns FastAPI HTTP 422. Render a friendly UI message;
  keep diagnostics available in development.

## Related-exercise semantics

`GET /api/atlas/muscles/{slug}/exercises?limit=8&sort=etu` currently resolves:

1. `relation="measured"` when the muscle slug exists in an exercise's
   `engine.exercises.etu_vector`. These rows contain `etu_cm2` and `normalized_etu`.
2. `relation="by_target"` as a conservative category fallback. These rows contain
   `etu_cm2=null` and `normalized_etu=null`.

The backend does not currently use `core.muscle_exercise_mappings` for this endpoint,
and it does not use `active_tension_exposure_vector` as the relation predicate. The UI
must distinguish the two relation types exactly as the Claude handoff describes: show
an ETU bar/value only for `measured`, and a muted “by target category” label otherwise.

## Media

The backend mounts `/home/agonez/media` read-only:

```text
/home/agonez/media/exercises/{exercise_slug}.png
/home/agonez/media/muscles/{muscle_slug}.png
/home/agonez/media/muscles/{muscle_slug}/*.{png|webp|jpg|jpeg|avif}  # optional gallery
/home/agonez/media/anatomy.svg
```

Use `image_url` and `gallery` from the API. Do not construct hero URLs in the SPA and do
not assume PNG forever. If an API URL is `null`, render the specified striped
placeholder at the exact final media dimensions to avoid layout shift.

New files in the bind mount appear without rebuilding either application.

## Recommended Vue structure

Use Vue 3, TypeScript, Vite, Vue Router, and Pinia. Keep API types and DTO-to-view-model
logic centralized.

```text
fe/
  src/
    api/
      client.ts
      atlas.ts
      types.ts
      url.ts
    assets/
    components/
      atlas/
      anatomy/
      common/
    composables/
      useTheme.ts
      useAtlasQuery.ts
      useMediaUrl.ts
    stores/
      atlas.ts
    views/
      AtlasIndexView.vue
      ExerciseDetailView.vue
      MuscleDetailView.vue
    router/
    styles/
      tokens.css
      global.css
    App.vue
    main.ts
```

Do not create one giant view component. In particular, keep `BodyViewer` isolated; it
owns SVG loading, sanitizing, view cropping, painting, delegated events, and tooltips.

## Routes

Implement:

```text
/atlas/exercises
/atlas/exercises/:slug
/atlas/muscles
/atlas/muscles/:slug
```

Use route params/query state so pages are linkable. Preserve useful index state when
navigating to a detail and back. Unknown entity slugs should render a proper not-found
state with a link back to the appropriate index.

## State model

Keep independent browsing state per tab:

- view: `list | grid`
- search text
- selected filters
- sort key and direction
- current page/page size

Cross-cutting state:

- `hoverExercise`
- `hoverMuscle` / `hoverSlug`
- `vizMode: etu | recovery`
- `showJoints`
- `theme: dark | light`

Persist theme and optionally list/grid preference in local storage. Do not persist
server data indefinitely; normal request caching/deduplication is enough.

## BodyViewer and heatmaps

The anatomy is a first-class interactive data surface, not a decorative image. Fetch
`/assets/anatomy.svg` once and follow the transformation pipeline in
`be/docs/frontend-handoff.md` exactly:

1. Parse with `DOMParser`.
2. Clone per front/rear view.
3. Remove metadata, labels, legend artifacts, and geometry for the other view.
4. Strip inline presentation properties that conflict with theme classes.
5. Apply the global `.agz-body` style rules.
6. Crop using the union of `.region` bounding boxes with documented fallbacks.
7. Paint by muscle/joint slug and reset cleanly between states.
8. Use delegated hover/out/click events and one fixed-position tooltip.

Keep the documented aliases until the SVG is normalized:

```text
anterior_deltoid -> deltoid_anterior
lateral_deltoid  -> deltoid_lateral
posterior_deltoid -> deltoid_posterior
rotator_cuff -> rotator_cuffs
```

### Exercise visualization math

- ETU mode value: `etu_vector[muscle]`.
- Recovery mode value:
  `active_tension_exposure_vector[muscle] *
  muscle_recovery_cost_modifier_vector[muscle]`.
- Capacity normalization:
  `value / muscle.pcsa_projected_fcsa_cm2`.
- Divide those ratios by the maximum ratio in the displayed vector for 0..1 display
  intensity.
- Color interpolation and exponent must match the Claude handoff:
  `P = 12 + 88 * intensity^0.75`.
- Joints are an amber ring/stroke overlay derived from
  `joint_load_exposure_vector`; never paint them with the muscle heatmap grammar.

The exercise detail call does not contain muscle capacities. Load the muscle index once
(up to 100 rows) or maintain a reusable muscle-capacity cache keyed by slug. Do not
silently normalize by the maximum raw vector value; that would change the intended
visual meaning.

## Required screens

### App shell

- 52 px sticky header, logo/wordmark, Atlas navigation, live counts, and theme toggle.
- `My Plans` and `Dashboard` visible but inert with `title="Planned module"`.
- Copy the dark/light CSS variables and typography rules from the Claude handoff.

### Atlas indexes

- Shared Exercises/Muscles index view.
- Search, repeatable filters with facet counts, sort/order, list/grid toggle.
- Active-filter chips and clear-all action.
- Responsive overflowing data table and grid cards.
- Sticky anatomy rail with bidirectional row/SVG hover and click navigation.
- Loading skeleton, network error, no-results, and missing-image states.
- Use API pagination even if all current records fit on one page.

### Muscle detail

- Hero with actual muscle image, identity/chips, and quantitative stats.
- Morphology, architecture, capacity, programming traits, fiber composition.
- Related exercises with measured versus category-fallback presentation.
- Gallery, videos, references, and Markdown Bible.
- Sanitize rendered Markdown/links. Sparse content must produce documented honest empty
  states; never generate or invent anatomy copy in the UI.
- Sticky anatomy rail highlighting the selected muscle.

### Exercise detail

- Hero with actual exercise image, identity/chips, and summary stats.
- ETU/Recovery modes plus optional joint overlay.
- Bidirectional heatmap/table interaction and muscle-detail navigation.
- Joint table and disclaimer that joint exposure is not a safety score.
- When `engine` is null, show “Engine vectors pending” and render the core propulsive
  vector fallback if available.
- Technique and Comments remain distinct cards, even when both are empty objects.

## Interaction and quality requirements

- Match the high-fidelity spacing, tokens, typography, colors, and responsive behavior;
  do not substitute a generic component-library visual language.
- Keyboard-accessible tabs, buttons, popovers, rows/cards, SVG targets, and theme toggle.
- Visible focus states, correct labels/ARIA, Escape-to-close popovers, and reduced-motion
  support.
- Use semantic tables where practical and preserve horizontal scrolling below the
  target content width.
- Avoid layout shift while API/media content loads.
- Do not expose credentials or database variables to browser code. The frontend needs
  only the public API origin.
- Never derive scientific values in multiple components. Put heatmap/recovery math in
  tested pure utilities.

## Suggested implementation sequence

1. Scaffold Vue/TypeScript/Vite, router, tokens, API client, and response types.
2. Implement AppShell, theme persistence, index state, and both API-backed indexes.
3. Build and test BodyViewer independently with `/assets/anatomy.svg`.
4. Add muscle detail, related exercises, Markdown/media, and selected-muscle anatomy.
5. Add exercise detail, capacity cache, heatmap utilities, tables, and joint overlay.
6. Add responsive/accessibility/error/loading polish.
7. Add tests and run a production build against the real backend.

## Minimum tests

- API query serialization uses repeated filter keys.
- API/media URL resolution works for separate and same-origin deployments.
- Theme persistence and initial theme application avoid a flash.
- Index state remains independent between exercises and muscles.
- ETU and recovery calculations, capacity normalization, zero/null vectors.
- Related exercise rendering for `measured` and `by_target`.
- BodyViewer alias mapping, clearing/repainting, front/rear filtering, and event mapping.
- Route-level loading, 404, 422/network error, and engine-pending states.
- Production `vite build` succeeds with strict TypeScript checks.

## Definition of done

- All four routes work on refresh and client navigation.
- Every implemented backend endpoint is integrated; no mock data remains in production
  code.
- Current 49 exercise and 47 muscle images render from API-provided URLs.
- Interactive anatomy behavior and heatmap math match the documented contract.
- Dark/light themes and primary responsive layouts match the design intent.
- Missing data and pending engine evaluations are represented honestly.
- No authentication is introduced into Atlas.
- Automated tests, lint/type checks, and the production build pass.
- A frontend README documents environment, local development, build, and backend start
  commands without copying backend secrets into frontend configuration.
