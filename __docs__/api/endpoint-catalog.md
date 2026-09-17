# Endpoint catalog

All handlers below are registered by `agonez_api.app.create_app()`. Handler names refer to `be/src/agonez_api/modules/*/router.py` unless stated otherwise.

## Atlas operations

| Method | Path | Handler | Input | Output | Database/service flow | Side effects and visible errors |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/api/atlas/exercises` | `list_exercises()` | Search; repeatable body/target/mechanics/resistance filters; sort/order; page/per_page; locale header | `ExerciseListResponse` | `AtlasService.list_exercises()` → `AtlasRepository.list_exercises()`; joins `core.exercises`, published translation, `engine.exercises`; separate facet/count query | Read-only; 422 for invalid query values |
| GET | `/api/atlas/exercises/catalog` | `list_exercise_catalog()` | Locale header | `ExerciseCatalogResponse` | Complete lightweight selector query over core translation + engine demand | Read-only |
| GET | `/api/atlas/exercises/{slug}` | `get_exercise()` | Validated slug; locale header | `ExerciseDetail` | Loads core + translation + engine row; service decides whether `engine` is null and resolves image URL | 404 unknown slug; read-only |
| POST | `/api/atlas/exercises/{slug}/videos` | `add_exercise_video()` | `ExerciseVideoCreate` (`url`) | `ExerciseVideoLinks`, 201 | Service canonicalizes YouTube URL, loads exercise, deduplicates by video ID, then repository array-appends | Writes `core.exercises.video_links`/`updated_at`; 404 unknown exercise; 422 non-YouTube/invalid URL |
| GET | `/api/atlas/muscles` | `list_muscles()` | Search; repeatable body/complex filters; sort/order; page/per_page; locale | `MuscleListResponse` | `core.muscles` + translation; separate facets/count | Read-only |
| GET | `/api/atlas/muscles/{slug}/exercises` | `get_related_exercises()` | Slug; `limit` 1–50; `sort=etu|name`; locale | `RelatedExerciseResponse` | Confirms muscle; reads numeric ETU JSON key from engine; supplements with target-category fallback from core | 404 unknown muscle; read-only |
| GET | `/api/atlas/muscles/{slug}` | `get_muscle()` | Slug; locale | `MuscleDetail` | Core + translation; service resolves hero/gallery files | 404 unknown muscle; DB read plus filesystem reads |
| GET | `/api/atlas/meta` | `get_meta()` | None | `AtlasMeta` | Reads enum ranges and exercise/muscle counts | Read-only |

Ordering matters: `/exercises/catalog` is registered before `/exercises/{slug}`, and `/muscles/{slug}/exercises` before `/muscles/{slug}`.

## Plan operations

| Method | Path | Handler | Input | Output | Database/service flow | Side effects and visible errors |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/api/plans` | `create_plan()` | `PlanCreate` | `PlanDraftArtifact`, 201 | `PlanRepository.create_plan()` inserts plan + DRAFT revision transactionally; service assembles empty nested draft | Creates two rows; 422 invalid name |
| POST | `/api/plans/import` | `import_plan()` | `PlanAIImportDocument` v1/v2 | `PlanDraftArtifact`, 201 | Resolves exercise/progression slugs, inserts full tree in one transaction, derives roles by exercise order | Atomic create; 422 unknown catalog slug/domain validation |
| GET | `/api/plans` | `list_plans()` | None | `PlanListResponse` | Lists plan roots and left joins current DRAFT metadata | Read-only; unauthenticated/global |
| GET | `/api/plans/catalog/progression-models` | `list_progression_models()` | Locale header | `ProgressionModelCatalogResponse` | Reads `core.progression_models` + translation ordered by projected `display_order` | Read-only; fails at DB level if migration `0004` absent |
| POST | `/api/plans/{plan_id}/duplicate` | `duplicate_plan()` | Positive plan ID; empty body tolerated/unused | `PlanDraftArtifact`, 201 | Locks source for share, loads DRAFT, derives unique `copy` name, inserts plan/revision, copies full child tree | Creates independent rows; 404 source plan/draft |
| GET | `/api/plans/{plan_id}` | `get_plan()` | Positive plan ID | `PlanDetail` | Loads root and all revisions | 404 unknown plan; read-only |
| DELETE | `/api/plans/{plan_id}` | `delete_plan()` | Positive plan ID | Empty 204 | Deletes aggregate root; FK cascades revision tree | Destructive/global; 404 unknown plan |
| GET | `/api/plans/{plan_id}/draft` | `get_draft()` | Positive plan ID | `PlanDraftArtifact` | Checks plan, loads DRAFT with a fixed sequence of relational queries, assembles nesting | 404 plan or draft; read-only |
| PUT | `/api/plans/{plan_id}/draft` | `save_draft()` | `PlanDraftUpdate` | `PlanDraftArtifact` | Row-locks plan/revision; validates identity/version/nested IDs/slugs; upserts; deletes omissions; increments lock; reloads | Transactional write; 404, 409 stale lock, 422 domain/Pydantic errors |
| POST | `/api/plans/{plan_id}/draft/analysis` | `analyze_draft()` | `PlanAnalysisRequest` | `PlanAnalysisResult` | Repeatable-read read-only draft/catalog snapshot → assemble → resolve → evaluate/simulate | Read-only; 404; calculation diagnostics are returned in 200 body |
| POST | `/api/plans/{plan_id}/draft/export` | `export_draft()` | `PlanExportRequest`; locale | `PlanAIExportResult` | Same source snapshot/resolution; reads localized progression catalog; produces compact v2 document | Read-only; 404; assumes every referenced progression model is in catalog |

## Application/static operations

| Method | Path | Registration | Output / behavior |
| --- | --- | --- | --- |
| GET | `/assets/anatomy.svg` | `app.py:anatomy_asset()` | `image/svg+xml`; 404 when file absent; included in OpenAPI |
| GET | `/health/live` | `app.py:liveness()` | `{"status":"ok"}`; excluded from OpenAPI |
| GET | `/health/ready` | `app.py:readiness()` | DB `SELECT 1`; 200 ok or 503 unavailable; excluded from OpenAPI |
| GET | `/media/{path}` | FastAPI `StaticFiles` mount | Direct file serving; no per-file OpenAPI operation |
| GET | `/openapi.json` | FastAPI built-in | Generated JSON contract |
| GET | `/docs`, `/redoc` | FastAPI built-ins | Interactive documentation |

## Reachability notes

No dead or unregistered router function was found. Revision statuses other than DRAFT, `snapshot`, loading-cycle resolution, fallback-variant selection, and progression execution are data-model capabilities without corresponding runtime workflows.
