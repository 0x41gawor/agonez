# Agonez Atlas Web Frontend Implementation Plan

Status: complete  
Started: 2026-08-11  
Completed: 2026-08-11  
Target directory: `/home/agonez/web-fe`

## Objective

Build the public Agonez Atlas as a production-quality Vue 3 SPA. The application must
faithfully reproduce the supplied Claude design, consume the existing FastAPI Atlas
contract, use the API-provided exercise and muscle media, remain usable on phones and
tablets, and run as a Docker image exposed on the host through `MERSAA`.

Atlas is intentionally public and has no authentication or per-user behavior. The
shell reserves space for future My Plans and Dashboard modules without coupling them
to this implementation.

## Source priority

1. `docs/reference/claude-template.html` and `Agonez Atlas.dc.html` for visual and
   interaction fidelity.
2. `/home/agonez/be/src/agonez_api/modules/atlas/schemas.py` for actual response types.
3. `/home/agonez/be/docs/frontend-handoff.md` and the copied API contract for behavior.
4. API-provided media URLs and `/assets/anatomy.svg` for production content.

The Claude mock data is reference-only. No production feature may depend on it.

## Architecture

- Vue 3, TypeScript, Vite, Vue Router, and Pinia.
- A small typed API layer with repeated-query serialization, abortable requests, and
  same-origin operation by default.
- One Atlas store for live metadata, independent exercise/muscle browsing state, and
  a reusable muscle-capacity cache.
- Route views for indexes and details; focused components for toolbar, tables/cards,
  anatomy, detail panels, media, and asynchronous states.
- Theme tokens split from component/layout styles. Dark and light are first-class,
  persisted themes and can also be forced with `?theme=dark|light` for visual testing.
- Heatmap/recovery/vector behavior lives in tested pure utilities, not in views.
- BodyViewer owns anatomy loading, cloning, sanitizing, cropping, painting, delegated
  interactions, and tooltips.

## Delivery phases

### 1. Discovery and references

- [x] Inspect the backend contract, schema, media structure, and deployment model.
- [x] Unpack the attached Claude bundle and preserve readable source references.
- [x] Record exact theme tokens, responsive breakpoints, and vector math.
- [x] Save this durable plan before application implementation.

### 2. Foundation

- [x] Scaffold strict Vue/TypeScript/Vite tooling and install locked dependencies.
- [x] Implement router, app shell, theme persistence/test override, and global styles.
- [x] Implement API types/client, media URL resolution, and Atlas Pinia state.
- [x] Add reusable UI primitives and accessible loading/error/empty states.

### 3. Atlas indexes

- [x] Implement `/atlas/exercises` and `/atlas/muscles` with independent URL-backed
  search, repeatable filters, sorting, pagination, and list/grid preferences.
- [x] Match Claude table/card structure and replace placeholders with API media.
- [x] Add the sticky desktop anatomy rail and mobile anatomy sheet/FAB.

### 4. Detail routes

- [x] Implement `/atlas/muscles/:slug`: hero, quantitative panels, fiber composition,
  related exercises, media, sanitized Markdown Bible, references, and selected anatomy.
- [x] Implement `/atlas/exercises/:slug`: hero, classifications, technique/comments,
  ETU/recovery heatmaps, capacity-normalized vector table, joints, and pending fallback.
- [x] Implement honest 404, sparse-data, null-vector, and network-error states.

### 5. Deployment and documentation

- [x] Add multi-stage Docker image, SPA-safe Nginx configuration, and same-origin proxy
  to the separately running backend using `MAMMOONE`.
- [x] Add Compose deployment exposing `${MERSAA}:8080` without hard-coded host ports.
- [x] Document local development, environment variables, Docker operation, themes,
  architecture, and future-module extension points.

### 6. Verification

- [x] Unit-test query serialization, URL resolution, themes, filters, vector math,
  aliases, and pending/related semantics.
- [x] Pass lint, strict type checking, unit tests, and production build.
- [x] Validate Compose configuration and run the production container.
- [x] Open the deployed application for responsive/theme review and smoke all SPA,
  API, anatomy, and media paths through the production proxy.

## Definition of done

- All four routes work through direct refresh and client navigation.
- API data is authoritative and no mock data ships in production code.
- Current exercise/muscle images resolve from API URLs and missing media has stable,
  accessible fallback presentation.
- Anatomy interaction and capacity-normalized ETU/recovery/joint rendering match the
  documented behavior.
- Dark/light themes, desktop split views, and <=700 px mobile behavior closely match
  the Claude design.
- `docker compose up --build -d` serves the frontend on the host port in `MERSAA` and
  proxies the backend using `MAMMOONE`.
- Tests, lint, type checking, build, and runtime smoke checks pass.

## Handoff notes

Update the checkboxes and Status as work progresses. If implementation is interrupted,
start with `git status`, this plan, and `README.md`; do not discard unrelated work in
the parent repository.

## Final verification record

- `npm run lint`: passed with zero warnings.
- `npm test`: 8 files / 24 tests passed.
- `npm run build`: strict Vue TypeScript check and Vite production build passed.
- `docker compose config -q`: passed using shell-provided `MERSAA` and `MAMMOONE`.
- Production container: healthy at `http://127.0.0.1:${MERSAA}`.
- HTTP smoke: SPA root/direct detail refresh, metadata proxy, 1.99 MB anatomy SVG,
  and representative 600 KB muscle media all returned complete HTTP 200 responses.
- Deployment fix: the pre-existing public `/home/agonez/media/anatomy.svg` permission
  was changed from `600` to `644` so the non-root FastAPI process can read it.
- Post-deployment fix: narrowed `/assets` proxying to the exact anatomy endpoint so
  Vite's local hashed JS/CSS retain their correct MIME types, and normalized built
  static-file permissions for the non-root Nginx worker.
- Exercise videos: added a compact paste-and-save control, privacy-enhanced YouTube
  embeds, immediate response-state refresh, URL parser tests, and responsive styling.
- Muscle galleries: added a maximum-four responsive preview immediately above Muscle
  Bible, remaining-image count, accessible modal lightbox, wraparound arrow/keyboard
  navigation, touch swipe, scrollable thumbnails, and native modified-click behavior.
- Exercise technique: moved demonstration videos before editorial content; replaced
  the two-column raw-object view with full-width ordered technique and comments;
  added nested structured values, canonical sequence groups, semantic heading cues,
  list rendering, future-field fallback, and ordering/nesting tests.
- Native Atlas navigation: converted table cells, grid cards, and related-exercise
  rows to semantic RouterLink anchors, restoring Ctrl/Cmd-click, middle-click, context
  menu, and standard keyboard navigation while retaining SPA routing on normal clicks.
