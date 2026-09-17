# API guide

## Contract source

The API is FastAPI. [openapi.yaml](openapi.yaml) was generated from `agonez_api.app.create_app()` with inert documentation settings; no database connection is opened during schema generation. It is OpenAPI 3.1 and contains 17 paths / 20 operations.

Health routes, the `/media` static mount, Swagger UI (`/docs`), ReDoc (`/redoc`), and the JSON schema endpoint (`/openapi.json`) are reachable but are not all represented as application operations in OpenAPI.

## Base paths

- Atlas: `/api/atlas`
- Plans: `/api/plans`
- Anatomy SVG: `/assets/anatomy.svg`
- Static media: `/media/...` by default
- Health: `/health/live`, `/health/ready`

There is no API-wide version segment. The FastAPI metadata version defaults to `0.1.0`; analysis separately emits `model_version = "plan-analysis-v2"`.

## Serialization and validation

- Request/response DTOs are Pydantic v2 models with `extra="forbid"`; unknown JSON fields are rejected.
- Integers, bounds, enums, slug patterns, nested ordinals, rep ranges, loading cycles, and DEFAULT-variant rules are validated before services run.
- FastAPI returns its standard 422 validation response for malformed input.
- JSON numeric values are serialized as numbers. PostgreSQL `numeric` values are accepted by Pydantic and emitted as floats in declared response fields.
- Missing optional values are `null`, not omitted.

## Localization

Localized read/export endpoints negotiate `Accept-Language`. Current code supports:

```text
en, pl, fr, es, de, it, nl, sv, pt-BR, uk
```

Exact tags are preferred; regional tags are reduced to a supported language (`pt` maps to `pt-BR`), quality weights are honored, and fallback is English. Responses set `Content-Language` and `Vary: Accept-Language`.

Exercise translations overlay `name`, `name_full`, `technique`, and `comments` only when `status = 'published'`. Muscle translations overlay `display_name` and `bible_markdown`. Progression-model catalog/export text uses a locale-specific row when present. Stable IDs, slugs, enums, and metrics are not translated.

## Pagination, filters, and sorting

Atlas list endpoints are one-based and default to `page=1`, `per_page=50`; the maximum page size is 100. Repeat a filter query key to select multiple values. Facet counts are calculated over the currently filtered set.

Sort expressions are selected from hard-coded maps/literals, not interpolated from arbitrary client SQL. Filter values are parameterized.

## Media contract

- Exercise hero: `media/exercises/{slug}.{avif|webp|png|jpg|jpeg}`
- Muscle hero: `media/muscles/{slug}.{extension}`
- Muscle gallery: `media/galleries/muscles/{slug}/*.{extension}`
- Anatomy: `media/anatomy.svg`, exposed at `/assets/anatomy.svg`

The service checks hero/gallery files before returning URLs. A missing hero becomes `null`; a missing gallery becomes `[]`. A configured `PUBLIC_MEDIA_BASE_URL` changes generated media URLs but not database rows.

## Errors

| Status | Source | Shape/meaning |
| ---: | --- | --- |
| 404 | Atlas entity handler | `{"detail": "Exercise 'slug' was not found"}` or muscle equivalent |
| 404 | Plan handlers | `{"detail": "..."}` for missing plan or DRAFT |
| 404 | Anatomy route | Missing installed SVG |
| 409 | Draft optimistic lock | Detail plus submitted/current lock versions |
| 422 | FastAPI/Pydantic | Standard validation issues |
| 422 | Plan domain handler | `{"detail": "..."}` for identity/ownership/catalog errors |
| 503 | Readiness | Database is unavailable |
| 500 | Unhandled DB/infrastructure error | No module-specific response contract |

OpenAPI automatically documents validation responses but does not enumerate every custom 404/409/422 path response declared through exception handlers.

## Authentication and mutation warning

There is no authentication or ownership check. `POST /api/atlas/exercises/{slug}/videos` mutates shared catalog data; all plan mutations operate on global application data. Network-level restriction is required until identity/authorization is implemented.

## Examples

- [Exercise detail response](examples/exercise.detail.response.json)
- [Add exercise video request](examples/exercise-video.create.request.json)
- [Create plan request](examples/plan.create.request.json)
- [Plan draft artifact](examples/plan.draft.response.json)
- [Draft save request](examples/plan.draft.update.request.json)
- [Plan analysis request](examples/plan.analysis.request.json)
- [Plan analysis response](examples/plan.analysis.response.json)
- [Compact plan import](examples/plan.import.request.json)
- [Compact plan export](examples/plan.export.response.json)
