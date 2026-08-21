# Agonez Atlas — REST API contract (v0.1)

Derived from the UI as built. All list endpoints support the browsing controls the UI exposes; all field names mirror the `core` / `engine` schemas so the backend can map rows 1:1.

---

## 1. GET /api/atlas/exercises

Index list. Server-side filtering/sorting once the library grows; UI currently does it client-side.

Query params:
- `q` — free-text over name / name_full / slug
- `body_part`, `target_category`, `mechanics_tier`, `resistance_source` — repeatable
- `sort` — one of `name | name_full | load_capacity | systemic_propulsive_fcsa_demand | created_at | updated_at`
- `order` — `asc | desc`; `page`, `per_page`

```json
{
  "items": [
    {
      "slug": "dragon_flag",
      "name": "Dragon Flag",
      "name_full": "Flat Bench Dragon Flag",
      "body_part": "Core",
      "target_category": "Core",
      "mechanics_tier": "Secondary_Compound",
      "resistance_source": "Bodyweight",
      "execution_pattern": "Bilateral",
      "load_capacity": 55.0,
      "systemic_propulsive_fcsa_demand": 115.0,
      "created_at": "2026-08-20T10:00:00Z",
      "updated_at": "2026-08-21T10:00:00Z",
      "has_engine_vectors": true,
      "image_url": null
    }
  ],
  "total": 48,
  "facets": {
    "body_part": {"Upper": 31, "Lower": 9, "Core": 8},
    "target_category": {"Biceps": 5, "Back_V": 4},
    "mechanics_tier": {"Isolation": 22},
    "resistance_source": {"Cable": 9}
  }
}
```

Notes:
- `has_engine_vectors` drives the green dot + whether hover-preview paints the body.
- `facets` optional but lets filter checkboxes show counts.
- `image_url: null` is the contract for the placeholder state — never omit the key.

## 2. GET /api/atlas/exercises/:slug

Detail page. One call returns core row + engine vectors.

```json
{
  "slug": "dragon_flag",
  "name": "Dragon Flag",
  "name_full": "Flat Bench Dragon Flag",
  "body_part": "Core",
  "target_category": "Core",
  "mechanics_tier": "Secondary_Compound",
  "resistance_source": "Bodyweight",
  "execution_pattern": "Bilateral",
  "load_capacity": 55.0,
  "systemic_propulsive_fcsa_demand": 115.0,
  "created_at": "2026-08-20T10:00:00Z",
  "updated_at": "2026-08-21T10:00:00Z",
  "technique": {},
  "comments": {},
  "video_links": [],
  "image_url": null,
  "engine": {
    "propulsive_fcsa_contribution_vector": {"obliques": 37.35, "iliopsoas": 27.97},
    "active_tension_exposure_vector":      {"obliques": 37.35, "rotator_cuffs": 5.0},
    "etu_vector":                          {"obliques": 33.62, "iliopsoas": 26.57},
    "muscle_recovery_cost_modifier_vector":{"obliques": 1.05, "rectus_abdominis": 1.10},
    "joint_load_exposure_vector":          {"lumbar_spine": 0.68, "hip_joint": 0.52}
  }
}
```

Notes:
- `engine: null` when not yet evaluated → UI shows the "Engine vectors pending" state (and falls back to `propulsive_fcsa_contribution_vector` from core if present).
- Muscle keys are muscle slugs; joint keys are the SVG joint slugs (`lumbar_spine`, `glenohumeral_joint`, …).
- Recovery heatmap is computed client-side as `active_tension × recovery_cost_modifier`; alternatively precompute and add `recovery_exposure_vector`.
- Eval-notes JSONBs (`*_eval_notes`) are NOT needed by the current UI — omit or expose behind `?include=eval_notes`.

### POST /api/atlas/exercises/:slug/videos

Adds a demonstration video. The API accepts YouTube watch, short, Shorts, Live, and
embed URLs, stores a canonical watch URL, and deduplicates equivalent URL forms by
video ID.

Appending a new link updates the exercise's `updated_at`; submitting an already stored
video leaves the timestamp unchanged.

```json
{
  "url": "https://youtu.be/1Z-aEpjdphU"
}
```

Response (`201 Created`):

```json
{
  "video_links": ["https://www.youtube.com/watch?v=1Z-aEpjdphU"]
}
```

## 3. GET /api/atlas/muscles

Query params: `q`, `body_part`, `complex` (repeatable),
`sort` = `name | mass_g | mv_cm3 | fiber_bias_type_ii | pcsa_fiber_cm2 | pcsa_projected_fcsa_cm2`, `order`, `page`, `per_page`.

```json
{
  "items": [
    {
      "slug": "latissimus_dorsi",
      "name": "Musculus latissimus dorsi",
      "display_name": "Latissimus dorsi",
      "body_part": "Upper",
      "complex": "Back",
      "mass_g": 1260.0,
      "mv_cm3": 1193.18,
      "fiber_bias_type_i": 0.5,
      "fiber_bias_type_ii": 0.5,
      "pcsa_projected_fcsa_cm2": 43.85,
      "image_url": null
    }
  ],
  "total": 47,
  "facets": {"body_part": {"Upper": 27}, "complex": {"Back": 7}}
}
```

`display_name` optional (UI can derive from slug), but keeping the Latin `name` verbatim matters — it's shown as the subtitle.

## 4. GET /api/atlas/muscles/:slug

```json
{
  "slug": "latissimus_dorsi",
  "name": "Musculus latissimus dorsi",
  "body_part": "Upper",
  "complex": "Back",
  "mass_g": 1260.0,
  "mv_cm3": 1193.18,
  "mass_reference": "Bilateral",
  "architecture": "Parallel/Convergent",
  "fiber_bias_type_i": 0.5,
  "fiber_bias_type_ii": 0.5,
  "optimal_fiber_length_cm": 25.25,
  "pennation_angle_deg": 21.89,
  "pennation_cos": 0.928,
  "pcsa": 32.0,
  "pcsa_fiber_cm2": 47.25,
  "pcsa_projected_fcsa_cm2": 43.85,
  "smh_factor": "very_high",
  "strength_curve": "Bell-shaped",
  "leverage_peak": "Mid_Range",
  "bible_markdown": "# Overview\n...",
  "article_links": ["https://exrx.net/"],
  "video_links": ["https://youtu.be/..."],
  "image_url": null,
  "gallery": [
    "/media/galleries/muscles/latissimus_dorsi/01-origin.webp",
    "/media/galleries/muscles/latissimus_dorsi/02-insertion.jpg"
  ]
}
```

`gallery` is populated only on muscle detail. Files are discovered from
`media/galleries/muscles/{slug}/`, filtered to supported image formats, and returned
in case-insensitive filename order. Prefix filenames numerically when presentation
order matters.

## 5. GET /api/atlas/muscles/:slug/exercises

The "Related exercises" endpoint (currently mocked client-side from target-category mapping + available vectors).

Query params: `limit` (UI uses 8), `sort=etu|name`.

```json
{
  "items": [
    {
      "slug": "neutral_grip_lat_pulldown",
      "name": "Neutral-Grip Lat Pulldown",
      "name_full": "Selectorized Neutral-Grip Lat Pulldown",
      "target_category": "Back_V",
      "mechanics_tier": "Secondary_Compound",
      "relation": "measured",
      "etu_cm2": 41.2,
      "normalized_etu": 0.31
    },
    {
      "slug": "wide_pronated_grip_pull_up",
      "name": "Wide-Grip Pull-Up",
      "relation": "by_target",
      "etu_cm2": null,
      "normalized_etu": null
    }
  ]
}
```

`relation: "measured" | "by_target"` — the UI renders a bar for measured, a muted label otherwise. When `muscle_exercise_mappings` gets populated, add `complexity` and `resistance_profile` here.

## 6. Supporting endpoints

- `GET /api/atlas/meta` — enum values + counts for filter construction (or rely on `facets`):
  ```json
  {"body_part": ["Upper","Lower","Core"], "target_category": [...], "mechanics_tier": [...],
   "resistance_source": [...], "muscle_complex": [...], "counts": {"exercises": 48, "muscles": 47}}
  ```
- `GET /assets/anatomy.svg` — versioned static asset. Contract: every muscle/joint is a `<g id="{slug}" data-slug data-type="muscle|joint">`, child geometry carries `data-view="front|rear|side"`. Frontend aliases to resolve today: `anterior_deltoid→deltoid_anterior`, `lateral_deltoid→deltoid_lateral`, `posterior_deltoid→deltoid_posterior`, `rotator_cuff→rotator_cuffs` (ideally fix the SVG ids to match DB slugs and drop the alias map).

## Conventions

- All numerics as JSON numbers (not strings); units are fixed by field name (`_g`, `_cm3`, `_cm2`, `_deg`, kg for `load_capacity`).
- Missing optional metric → `null`, never absent, so the UI can render "—" deterministically.
- Vectors are always objects keyed by slug; empty object `{}` means "evaluated, nothing exposed", `null` means "not evaluated yet" — the UI distinguishes these two states.
- Slugs are the canonical cross-reference everywhere (routes, SVG, vector keys).
