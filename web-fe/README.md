# Agonez Atlas Web Frontend

Responsive Vue 3 frontend for the public Agonez exercise and muscle Atlas. It consumes
the FastAPI application in `/home/agonez/be`, renders API-provided media, and implements
the Claude-designed anatomy, list/grid indexes, detail pages, heatmaps, and dark/light
themes.

Exercise detail pages embed stored YouTube demonstrations through the privacy-enhanced
YouTube domain. The compact `Add video` action accepts a pasted YouTube URL, saves it
through the Atlas API, and refreshes the section immediately.

Muscle detail pages show up to four gallery previews above the Muscle Bible. A regular
click opens the in-page lightbox with wraparound arrows, keyboard navigation, swipe,
and a scrollable thumbnail rail; Ctrl/Cmd-click retains native new-tab image behavior.

## Architecture

- Vue 3 + TypeScript + Vite
- Vue Router for the four linkable Atlas routes
- Pinia for Atlas metadata, per-index browse state, hover state, and muscle capacities
- Focused API, anatomy, index, detail, and shell components
- Nginx production image with SPA fallback and a same-origin reverse proxy

The design source bundle and implementation handoffs are preserved in
`docs/reference/`. They are reference material only; production code has no mock-data
dependency.

## Required services and environment

The frontend Compose project starts one container: `atlas-web`. The FastAPI backend and
PostgreSQL remain separate services managed from `/home/agonez/be`.

The shell environment must contain:

- `MAMMOONE`: FastAPI host port
- `MERSAA`: frontend host port

The frontend never receives `NOME`, `AGANDSKODE`, or `MINA`; those database values are
backend-only.

If the variables are configured in `.bashrc`, load them before Compose in shells where
they are not already exported:

```bash
source ~/.bashrc
```

## Local development

Start the backend first:

```bash
cd /home/agonez/be
docker compose up --build -d
curl "http://127.0.0.1:${MAMMOONE}/health/ready"
```

Then run Vite:

```bash
cd /home/agonez/web-fe
npm install
npm run dev
```

Open `http://127.0.0.1:5173/atlas/exercises`. Vite proxies `/api`, `/assets`, `/media`,
and health/docs requests to `http://127.0.0.1:${MAMMOONE}`, so browser code remains
same-origin and contains no backend port.

`VITE_API_BASE_URL` is optional. Set it only when the browser must call the API origin
directly; the empty default is preferred for both Vite proxy and Docker.

## Docker deployment

```bash
source ~/.bashrc
cd /home/agonez/web-fe
docker compose up --build -d
docker compose ps
curl "http://127.0.0.1:${MERSAA}/"
```

Open `http://127.0.0.1:${MERSAA}/atlas/exercises`. Nginx listens on port 8080 inside
the container and Compose publishes it on `MERSAA`. It proxies public backend paths to
the host port in `MAMMOONE` through `host.docker.internal`.

Stop the frontend without affecting the backend/database:

```bash
cd /home/agonez/web-fe
docker compose down
```

## Routes

- `/atlas/exercises`
- `/atlas/exercises/:slug`
- `/atlas/muscles`
- `/atlas/muscles/:slug`

Search, filters, sort, view, and pagination are represented in route query parameters.
The exercise and muscle indexes retain separate in-memory browsing state when switching
tabs.

## Theme testing

Use the header toggle to persist the chosen theme in local storage. For deterministic
visual tests, force a theme without changing the stored preference:

```text
/atlas/exercises?theme=dark
/atlas/exercises?theme=light
```

Theme values live in `src/styles/tokens.css`; component and responsive rules consume
only those variables. The main responsive transition is at 700 px, where tables become
compact and the anatomy rail becomes a full-screen sheet opened by a floating button.

## Quality commands

```bash
npm run typecheck
npm run lint
npm test
npm run build
```

## Extension points

Atlas remains public and has no authentication. `My Plans` and `Dashboard` in the shell
are deliberately inert placeholders. Future modules can be added as route-level
features with their own stores/API clients, or deployed separately behind the same
reverse proxy, without changing Atlas internals.

Implementation status and handoff notes are maintained in `IMPLEMENTATION_PLAN.md`.
