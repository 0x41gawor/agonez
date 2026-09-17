# Module dependencies

## Backend dependency direction

```mermaid
flowchart LR
    Main["main"] --> App["app factory"]
    App --> Core["core config/db/media/localization"]
    App --> AtlasRouter["atlas.router"]
    App --> AtlasService["atlas.service"]
    App --> AtlasRepo["atlas.repository"]
    App --> PlansRouter["plans.router"]
    App --> PlansService["plans.service"]
    App --> PlansRepo["plans.repository"]
    App --> AnalysisService["plans.analysis.service"]

    AtlasRouter --> AtlasSchemas["atlas.schemas"]
    AtlasRouter --> AtlasService
    AtlasService --> AtlasRepo
    AtlasService --> MediaResolver["core.media"]
    AtlasRepo --> DBPool["core.database"]

    PlansRouter --> PlansSchemas["plans.schemas"]
    PlansRouter --> PlansService
    PlansRouter --> AnalysisSchemas["analysis.schemas"]
    PlansRouter --> AnalysisService
    PlansService --> PlansRepo
    PlansRepo --> DBPool
    PlansRepo --> AnalysisSchemas
    AnalysisService --> PlansRepo
    AnalysisService --> PlansService
    AnalysisService --> Resolver["analysis.resolver"]
    AnalysisService --> Evaluator["analysis.evaluator"]
    Resolver --> Domain["analysis.domain"]
    Resolver --> AnalysisSchemas
    Evaluator --> Domain
    Evaluator --> Parameters["analysis.parameters"]
    Evaluator --> AnalysisSchemas
```

The principal runtime direction is router → service → repository → Psycopg. The analysis path adds service → resolver/evaluator after a repository snapshot.

### Notable coupling

- `PlanRepository` imports `PlanAIImportDocument` from `plans.analysis.schemas`. Persistence therefore depends on a schema module inside the analysis package, even though import is not analysis execution.
- `PlanAnalysisService` calls `PlanService.assemble_draft()` rather than owning a separate row-to-domain mapper.
- Analysis domain and schemas import `ExerciseSlotRole`/`RepRange` from the plan API schema module.

These are directed dependencies, not a Python import cycle in the current graph. They do make the `analysis` package broader than its name suggests.

## Frontend dependency direction

```mermaid
flowchart LR
    Router["Vue Router"] --> Views["views"]
    Views --> Components["components"]
    Views --> Composables["composables"]
    Views --> Stores["Pinia stores"]
    Composables --> API["typed API clients"]
    Stores --> API
    Components --> Features["pure feature helpers"]
    Composables --> Features
    API --> Fetch["fetch + URL + locale"]
    Components --> Shared["anatomy/common/detail"]
```

Key paths:

- Atlas views call `atlasApi` and use `useAtlasStore` for browse/hover/capacity state.
- `PlanCreatorView` composes `usePlanDraft`, `usePlanAnalysis`, catalog stores, editor components, and export/import dialogs.
- `usePlanDraft` owns the editable in-memory aggregate and turns HTTP 409 into an explicit conflict state.
- `usePlanAnalysis` owns a persisted-draft snapshot, detects staleness against local dirty state and `lock_version`, and indexes contribution provenance for UI lookup.
- `features/plans/editor.ts` is the pure conversion/validation layer between API DTOs and UI editor state.

## Database dependencies by repository

```mermaid
flowchart TB
    AtlasRepo["AtlasRepository"] --> CoreCatalog["core exercises/muscles/translations"]
    AtlasRepo --> EngineVectors["engine.exercises"]
    PlansRepo["PlanRepository"] --> PlansSchema["plans.*"]
    PlansRepo --> CoreCatalog
    PlansRepo --> EngineVectors
    MigrationRunner["migration runner"] --> Ledger["public.agonez_schema_migrations"]
    MigrationRunner --> PlansSchema
    MigrationRunner --> CoreCatalog
```

There is no repository abstraction between plans and Atlas catalog tables: plan slug validation and analysis enrichment query `core`/`engine` directly.

## Dependency-cycle assessment

No direct Python or TypeScript import cycle was found in the inspected source. The higher-level conceptual cycle is intentional: the frontend edits a server artifact, the server returns stable IDs/version, and the frontend rehydrates that artifact as its new baseline. This is a data round-trip, not a module cycle.
