# Documentation gaps and follow-up priorities

This is a documentation-quality backlog, not a code-quality scorecard.

## High

### Establish a canonical database bootstrap source

Document or migrate creation/seeding of `core.progression_models`, progression translations, catalog translations, and engine data. Today the packaged migration chain is not sufficient to construct the schema expected by later migrations and code.

### Record analysis model v2 rationale and calibration

Replace or supersede the stale v1 handoff with a versioned model note explaining:

- ordinal/variable-length microcycle timing;
- the change to 0.70 muscle and 1.05 joint recovery velocities;
- why rep ranges/loading cycles are excluded;
- expected interpretation and safe use of ETU/MRU/JRU outputs.

### Define JSONB contracts

Publish machine-readable schemas and example/version policy for:

- exercise technique/comments;
- recommended rep profiles;
- all engine vectors and evaluation notes;
- any intended revision snapshot.

### Define units and formulas for engine data

Document how `load_capacity_kg`, systemic propulsive FCSA demand, active tension, ETU, recovery modifiers, and joint load are produced. Mark model indices separately from physical units.

### Document security boundary before external exposure

Specify authentication, ownership, authorization, and migration strategy for existing global plan data. Include the shared exercise-video mutation.

## Medium

### Create joint identifier governance

Provide a canonical joint slug list, labels, anatomy mapping, and lifecycle/versioning rules shared by engine data, API, and frontend.

### Document revision state transitions

Define creation, release, archive, branching/duplication, snapshot semantics, and whether ancestry may cross plan roots.

### Consolidate locale documentation

Update backend README and older API docs to the ten-locale current set, document translation coverage expectations, and clarify publication workflow/status values.

### Generate frontend DTOs or add contract comparison

Either generate TypeScript types from OpenAPI or add a CI check that compares important schemas. Current interfaces duplicate Pydantic contracts manually.

### Add database drift verification

Add a documentation/CI check that restores the latest dump, runs migrations, and asserts expected columns/constraints. At minimum, compare the migration ledger with packaged migration filenames.

### Document operational restore procedure

Write a tested workflow for restoring a dump, applying pending migrations, verifying media mounts, and running readiness/contract smoke tests without exposing secrets.

## Low

### Annotate source symbols with domain docstrings

High-value targets are `resolve_plan()`, `evaluate_plan()`, engine vector fields, `focus_area`, and `snapshot`. Current behavior is readable but meaning is scattered across older handoffs/tests.

### Inventory static anatomy identifiers

Generate a small checked report comparing SVG group IDs, muscle slugs, engine muscle keys, and frontend joint labels.

### Retire or label historical artifacts

Clearly mark `json-scheme.json`, root `api-contract.md`, legacy database scripts, and old analysis handoffs as design/history where they are not current runtime contracts.

### Add OpenAPI examples and custom error responses at source

The examples in this package are external to generated OpenAPI. Adding Pydantic/FastAPI examples and declared 404/409/domain-422 responses would improve interactive documentation.
