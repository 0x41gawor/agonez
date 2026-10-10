# Agonez Mobile — Full Flutter Implementation

You are entering the Agonez project for the first time.

Agonez is a strength-training platform with three main product domains:

```text
Atlas
    exercise / biomechanics / anatomy knowledge

Plans
    workout-plan definition

Execution
    real-world execution of prescribed training over time
```

The web application already covers plan creation, Execution analysis and prescription workflows.

The mobile application has a narrower and different responsibility:

> guide the athlete through a concrete workout prescription, record what actually happened set by set, preserve workout state reliably offline, and provide contextual access to the Agonez Atlas.

The mobile UX/product design is already finished.

The mobile FastAPI backend is already finished.

You are not being asked to redesign the product or backend.

Your task is to implement the **complete Android Flutter application** inside:

```text
mobile-fe/
```

The repository already contains:

```text
be/
web-fe/
mobile-fe/
```

`mobile-fe/` contains a basic Flutter application created in Android Studio.

You may inspect `web-fe/` for Agonez visual identity, Atlas assets and existing product language, and inspect `be/` only when useful for understanding actual API behaviour.

Do not modify the backend or Vue application unless an unavoidable integration issue is discovered; this task should stay inside `mobile-fe/`.

The attached design, implementation handoff, API contract and OpenAPI specification are intentionally detailed. Use them as the primary implementation specification rather than inventing missing product behaviour.

---

# 2. Attached artifacts

You are receiving:

```text
mobile-design-reference.html
mobile-implementation-handoff.md
mobile-api-contract.md
api/openapi.yaml
api-mobile-backend.md
dictionary.md
```

Read all of them completely before implementation.

---

# 3. Source-of-truth precedence

Use the following precedence when documents overlap.

## Actual backend behaviour

```text
api/openapi.yaml
api-mobile-backend.md
```

These describe the backend that actually exists.

They are authoritative for:

* real endpoints,
* request/response DTOs,
* enums,
* headers,
* error shapes,
* nullability,
* backend adaptations.

## Intended mobile protocol semantics

```text
mobile-api-contract.md
```

Use this for:

* offline execution semantics,
* ordered operations,
* UUID strategy,
* lease/epoch behaviour,
* retries,
* conflicts,
* recovery,
* finalization semantics.

If the original contract differs from the actual implementation, follow OpenAPI + backend handoff.

## Product UX / interaction

```text
mobile-design-reference.html
mobile-implementation-handoff.md
```

These are authoritative for:

* visual design,
* navigation,
* workout Focus Mode,
* one-thumb interaction,
* Atlas workspaces,
* structural-deviation friction,
* sync states,
* screen hierarchy,
* interaction details.

The standalone HTML is a **visual and interaction reference**, not Flutter source code.

Do not mechanically translate its HTML/CSS.

## Terminology

```text
dictionary.md
```

Use established Agonez domain terminology.

---

# 4. Existing repository discovery

Before implementing, inspect the repository.

Understand:

* Agonez branding,
* desktop typography,
* colours,
* spacing,
* icons,
* Atlas visual language,
* anatomy asset,
* exercise metadata presentation.

Pay particular attention to the existing Vue Atlas.

Find the real anatomy SVG used by the product.

The backend implementation states that the real asset is:

```text
/assets/anatomy.svg
```

rather than a hypothetical `human.svg`.

Reuse that actual anatomy asset and its existing region identifiers.

Bundle the appropriate SVG inside the Flutter application so Atlas Quick Peek can work offline.

Do not invent a second anatomy model or rasterize exercise-specific body maps.

---

# 5. Existing Flutter project

Work with the Flutter project already present in:

```text
mobile-fe/
```

Do not recreate the project.

Current environment:

```text
Flutter 3.38.7 stable
Dart 3.10.7
JDK 17
Android SDK available
```

Do not upgrade Flutter, Dart, Gradle, Android Studio, JDK or Android SDK unless implementation is genuinely impossible without it.

Avoid unnecessary toolchain churn.

---

# 6. Target platform

V1 target:

```text
Android only
```

Do not spend implementation time supporting:

* iOS,
* Web,
* Windows,
* macOS,
* Linux.

Keep ordinary Flutter portability where it comes naturally, but validation and Definition of Done concern Android.

Android package/application id:

```text
com.gawor.agonez
```

Preserve it.

---

# 7. Real validation device

Primary physical device:

```text
Motorola Edge 50 Fusion
Android 16 / API 36
device id: ZY22LNTRJ6
```

It is visible to Flutter/ADB.

An Android 16 emulator is also available as fallback.

The physical Motorola is the primary acceptance environment.

---

# 8. Real backend

Development backend:

```text
http://192.46.236.119:33287
```

Swagger is reachable from the physical phone.

The backend currently runs on a public VPS without authentication.

This is an intentional **v1 development convenience**.

Do not invent authentication.

Do not treat:

```text
X-Agonez-Device-Id
```

as authentication.

It is only a workout write-lease/device identity.

Security/TLS/Caddy will be introduced later.

---

# 9. API base URL configuration

Do not hardcode the VPS address inside application business logic.

Use compile-time configuration, preferably:

```dart
const String.fromEnvironment('API_BASE_URL')
```

or an equivalent clean configuration abstraction.

The application must be runnable using:

```powershell
flutter run -d ZY22LNTRJ6 --dart-define=API_BASE_URL=http://192.46.236.119:33287
```

Changing later to something such as:

```text
https://api.agonez.com
```

must require only configuration, not source-code changes.

Fail clearly in development if no base URL is configured.

Tests must be able to inject a fake/test API endpoint.

---

# 10. Temporary cleartext HTTP support

The development API uses HTTP.

Allow cleartext HTTP on Android for development.

Prefer limiting this permission to:

```text
debug/development builds
```

rather than weakening release networking globally.

For example use appropriate Android debug manifest/network-security configuration.

Do not make the IP address itself part of Android networking policy.

This is temporary infrastructure.

---

# 11. Flutter architecture

Use:

```text
Riverpod
go_router
Dio
Drift + SQLite
Flutter localization / ARB
```

as the baseline stack.

You may add other focused dependencies where they materially improve the implementation.

Examples may include:

* UUID support,
* package metadata,
* SVG rendering,
* immutable/model serialization,
* local notifications,
* connectivity status,
* haptics helpers.

Avoid dependency sprawl.

Do not introduce a second state-management or HTTP framework.

---

# 12. Architecture quality

This is a substantial application.

Do not implement it as:

```text
one giant main.dart
one giant workout_screen.dart
global mutable variables
```

Create coherent boundaries for concepts such as:

```text
app shell
configuration
routing
API client
API DTOs
local persistence
sync engine
workout domain/client state
Home
Workout
Atlas
workspace management
plan-run context
localization
```

Use feature-oriented decomposition where useful.

Follow Flutter/Dart conventions rather than copying Vue architecture.

---

# 13. Server state vs local state

Be explicit about ownership.

## Server/domain facts

Examples:

* plan run,
* session,
* prescription,
* confirmed set performance,
* skip,
* substitution,
* exercise comment,
* additional set,
* finalization.

## Durable local state

Examples:

* pending start,
* pending operations,
* pending finalize,
* locally known active workout,
* current lease/epoch,
* applied sequence,
* cached workout snapshot,
* timer timestamp,
* current workout position,
* open Atlas workspaces if the handoff requires persistence.

## Transient UI state

Examples:

* currently edited unconfirmed load,
* open sheet,
* focused field,
* animations.

Do not conflate these layers.

---

# 14. Drift is part of correctness

The local SQLite database is not merely a cache.

It is part of the workout reliability model.

The user must not lose workout data because:

* the API is temporarily unreachable,
* the app is backgrounded,
* Android kills the process,
* the app crashes,
* the phone temporarily loses network connectivity.

Use Drift to durably store the state required to recover.

Design the schema intentionally.

---

# 15. Device identity

Create a stable installation-level:

```text
device_id = UUID
```

on first run.

Persist it locally.

Reuse the same value on every API request until app data is removed/reinstalled.

Every mobile API request must send:

```text
X-Agonez-Device-Id
```

Also send:

```text
X-Agonez-Client
Accept-Language
```

according to the backend contract.

Construct `X-Agonez-Client` using actual application/platform information where practical, for example:

```text
agonez-mobile/<version> (android)
```

Centralize these headers in Dio configuration/interceptors.

Do not manually attach them throughout widgets.

---

# 16. Localization

Implement UI localization using Flutter's normal localization/ARB infrastructure.

V1 locales:

```text
English
Polish
```

Use a structure that makes additional locales easy later.

Do not hardcode user-facing strings throughout widgets.

Backend content requests should use current application locale through:

```text
Accept-Language
```

Backend `error.message` is for logs.

Flutter user-facing errors should be localized from stable:

```text
error.code
```

---

# 17. API client

Build one coherent typed mobile API layer over Dio.

Use:

```text
api/openapi.yaml
```

to verify every DTO and endpoint.

Do not expose raw dynamic JSON to presentation widgets.

Use explicit typed models.

You may use code generation such as:

```text
freezed
json_serializable
```

if useful.

Do not introduce a massive generated REST client merely for the sake of generation if it makes the custom sync protocol harder to reason about.

A thin typed Dio layer is acceptable and likely appropriate.

---

# 18. Real backend adaptations

Respect adaptations documented by the implemented backend.

In particular:

* unresolved-load prescription read behaviour follows the actual backend rather than assumptions in the earlier proposal,
* body maps use the installed `anatomy.svg`,
* API execution mode `added` maps to existing backend/domain `additional`,
* full Atlas article uses the existing Atlas endpoint rather than a duplicated mobile route,
* off-schedule/fallback execution remains unsupported,
* authentication remains deferred.

Do not accidentally code against obsolete assumptions from the original proposal.

---

# 19. App navigation

Implement the navigation model from the mobile design/handoff.

The main product domains should conceptually expose:

```text
Home
Atlas
Workout
You
```

or the exact final structure supplied by the design.

Use `go_router`.

Routes/state should behave correctly across:

* app startup,
* deep navigation inside Atlas,
* active workout,
* process recreation.

An active workout must survive navigation away from the Workout section.

---

# 20. Active workout as persistent workspace

Once a workout starts, it becomes a persistent app-level workspace.

The user may:

* inspect Atlas,
* go Home,
* inspect profile/context,

and then return immediately to the current exercise/set.

A generic back action must not cancel or destroy the workout.

The workout is ended only through its explicit Finish flow.

---

# 21. Home

Implement the designed Home screen against:

```text
GET /api/v1/mobile/context
```

It should answer immediately:

* active plan run,
* today,
* today's expected workout,
* prescription readiness,
* active workout if one exists,
* recent workouts,
* relevant alternatives.

If an active workout exists:

```text
Resume
```

must dominate over starting another workout.

Do not turn Home into a desktop analytics dashboard.

---

# 22. Plan-run context

Implement the plan-run selector using the mobile plan-run endpoint.

Selected plan run is client-local in v1.

Persist selection locally.

Switching must be disabled while an active workout exists.

Do not build account/profile synchronization for this yet.

---

# 23. Alternative workout selector

Implement the selector designed by Claude.

The scheduled workout remains the primary recommendation.

Other current-microcycle sessions may be browsed.

However, off-schedule execution is intentionally not implemented backend-side.

If start returns:

```text
off_schedule_not_supported
```

show the designed "not available yet" / equivalent product state.

Do not invent client semantics for:

* executing early,
* replacing sessions,
* extra exposure,
* fallback.

---

# 24. Prescription loading

Before workout start, obtain the real prescription from:

```text
GET /api/v1/mobile/sessions/{session_id}/prescription
```

Cache enough data locally to support the designed offline behaviour.

The execution payload includes:

* exercise identities,
* exercise tracks,
* prescription IDs,
* set IDs,
* loads,
* rep targets,
* RIR,
* comments,
* variants,
* previous exposure,
* load step,
* rest hint,
* Atlas peek.

Preserve prescription data as immutable/read-only client state for that started workout.

Never write actual performance values into prescription objects.

---

# 25. Workout start

Implement:

```text
POST /api/v1/mobile/workouts
```

correctly.

Before the network request:

1. generate the client workout UUID,
2. persist the local workout draft,
3. persist the start intent.

Only then attempt network delivery.

This ordering is critical for offline reliability.

Start is idempotent by workout UUID.

Retry the same start.

Never generate a second UUID merely because a request timed out.

---

# 26. Offline workout start

If the phone has a cached valid prescription but the API cannot currently be reached:

* allow the product behaviour described by the handoff/contract,
* create/persist the local workout,
* queue the start request first,
* allow workout interaction,
* queue subsequent operations behind start.

When connectivity returns:

```text
start
→ ops
→ finalize
```

must be delivered in dependency order.

Do not lose locally recorded field data if delayed start is later rejected.

Surface the required recovery UI for cases such as:

```text
active_workout_exists
prescription_changed
```

according to the handoff.

---

# 27. Prescription version

Send the prescription version the user accepted.

If start returns:

```text
409 prescription_changed
```

do not silently continue with stale targets.

Preserve the local state and show the designed recovery/refresh flow using the fresh prescription supplied by the backend.

---

# 28. Workout Focus Mode

Implement the central workout-running experience with particular care.

The athlete must remain oriented around:

```text
current workout
→ current exercise
→ current set
```

Prominently show:

* exercise name,
* current exercise number,
* current set number,
* prescription,
* actual input,
* workout progress,
* appropriate contextual history.

The UI must match the supplied design closely.

---

# 29. One-thumb logging

This is a hard UX requirement.

Load / reps / RIR entry must work comfortably:

* one-handed,
* while fatigued,
* with large touch targets,
* with minimal keyboard use.

Use design-provided interactions and intelligent defaults.

The common case should require very few actions.

Do not replace the designed interaction with generic `TextField` forms merely because they are easier to code.

---

# 30. Actual performance

Recording a set captures the real field observation.

Support:

```text
load
repetitions
RIR
optional set comment
optional heart_rate_bpm
```

Normal divergence from prescription is not an error.

Examples:

```text
lower load
reps outside target
different RIR
```

must remain easy to record.

Use API data/semantics rather than duplicating desktop divergence logic unnecessarily.

---

# 31. Confirm set: local-first behaviour

When the athlete confirms a set:

1. persist the set state locally,
2. create the deterministic/client IDs required by the protocol,
3. enqueue the appropriate operation,
4. update the UI immediately,
5. start the local rest timer if appropriate,
6. synchronize asynchronously.

Never wait for a network roundtrip before letting the athlete proceed to rest/next interaction.

The gym workflow is local-first.

---

# 32. Deterministic IDs

Implement client identifiers exactly according to the mobile protocol.

Especially:

* workout UUIDv4,
* deterministic UUIDv5 for prescribed exercise performance,
* deterministic UUIDv5 for prescribed set performance,
* UUIDv4 for genuinely additional/unplanned entities,
* UUIDv4 operation ID.

Centralize identity generation and test it.

The same inputs must always produce the same prescribed entity UUIDs.

---

# 33. Ordered operation queue

Implement the real backend protocol:

```text
POST /workouts/{workout_id}/ops
```

as a durable FIFO synchronization engine.

Track:

```text
lease_epoch
base_seq
seq
op_id
applied_seq
```

correctly.

Do not model each workout interaction as an unrelated REST request.

The queue is central to application correctness.

---

# 34. Sequence allocation

Sequence numbers must remain deterministic and durable across app restarts.

Do not allocate them only in memory.

An operation is assigned its identity/order as part of the durable local transaction that records the user's confirmed action.

Process death after Confirm must not make the operation disappear or get another conflicting sequence number.

---

# 35. Operation catalogue

Support all implemented backend operation types:

```text
upsert_set
skip_set
clear_set
set_exercise_comment
skip_exercise
substitute_exercise
add_unplanned_exercise
reorder_exercises
set_cursor
set_workout_comment
```

Use the exact DTOs from actual OpenAPI/backend handoff.

Do not invent REST endpoints such as `/skip-set`.

---

# 36. Structural deviations

Implement the designed friction for:

* skip set,
* additional set,
* skip exercise,
* substitution,
* reorder,
* unplanned exercise.

Ordinary performance divergence remains frictionless.

Structural changes must use the supplied hold-to-confirm / deliberate interaction patterns.

Do not replace these with repetitive generic confirmation dialogs unless the design explicitly does so.

---

# 37. Skip vs not performed

Preserve backend semantics.

```text
skipped
```

means the athlete explicitly skipped something.

```text
not_performed
```

is produced by finalization for planned work that was never reached/recorded.

The client must not automatically convert unrecorded work into explicit skips.

---

# 38. Exercise substitution

Implement substitution through the real Atlas/search data.

The UI must keep visible:

```text
Prescribed exercise
Actual exercise
```

Substitution does not mutate the prescription.

If the backend rejects:

```text
substitution_after_sets
```

show a useful localized explanation and preserve the user's current workout state.

---

# 39. Additional/unplanned exercise

Support the designed Add Exercise flow.

Search the Atlas.

Create a new client UUID.

Record it through:

```text
add_unplanned_exercise
```

and record its sets using `upsert_set` with no prescribed set reference, as defined by the backend.

---

# 40. Workout reordering

Implement actual exercise-order changes separately from prescription order.

Use:

```text
reorder_exercises
```

with the complete performance order required by the API.

Preserve the prescribed order for historical comparison.

---

# 41. Exercise comments

Support exercise-level performance comments.

Keep these distinct from:

* plan comments,
* prescription comments,
* set comments.

Do not overwrite or conflate those concepts in local models.

---

# 42. Rest timer

The rest timer is client-only.

Do not call a backend timer endpoint.

Persist timestamp-based timer information so it survives:

* navigation,
* backgrounding,
* process death.

Do not implement the timer only as an in-memory decrementing integer.

Use actual timestamps.

If the design/handoff calls for:

* local notifications,
* vibration,
* haptics,

implement them appropriately and keep them local.

---

# 43. Current position

The local app is authoritative for the immediate workout UI position.

Mirror useful resume position using:

```text
set_cursor
```

as defined by the API.

Treat server position as a hint for another-device recovery, not proof of completed field data.

---

# 44. Durable sync engine

Create a clear synchronization subsystem.

It must be able to process durable commands in dependency order:

```text
pending start
↓
ordered workout ops
↓
pending finalize
```

It should continue/retry when appropriate as the app remains alive.

It must also recover and restart synchronization after app process recreation.

Use exponential backoff for transient failures consistent with the contract.

Avoid tight retry loops.

---

# 45. Connectivity

Do not equate a connectivity plugin saying "online" with the API actually being reachable.

Treat actual request success/failure as authoritative.

Connectivity information may help wake the queue but should not be the sole truth.

Workout logging must remain available during failures.

---

# 46. Sync status UI

Implement the designed subtle states, for example:

```text
Saving…
Saved
Offline
N pending
Conflict
Continued on another device
```

Do not make synchronization dominate the workout UI.

But do not hide data-integrity problems.

---

# 47. Duplicate delivery

A timeout may occur after the server committed a batch.

Retry the same operations with the same:

```text
epoch
seq
op_id
```

Do not construct replacement operations merely because the response was lost.

Handle backend:

```text
duplicate
```

as successful acknowledgement.

---

# 48. Sequence errors

Handle:

```text
seq_gap
seq_mismatch
```

explicitly.

For `seq_gap`, reconcile with the authoritative expected sequence and local durable queue.

For `seq_mismatch`, treat it as a serious local protocol inconsistency:

* stop blindly writing,
* fetch authoritative workout snapshot,
* preserve local unsent information,
* surface/report appropriately.

Do not erase local workout data automatically.

---

# 49. Entity conflicts

Handle per-operation:

```text
conflict
```

including supplied server state.

Implement the designed conflict-resolution UX:

```text
This phone
vs
Server
```

with actions equivalent to:

```text
Keep this phone's value
Use server value
```

A conflict in one operation does not mean the whole workout is broken.

Respect backend sequencing semantics: the conflicting op may already be consumed.

---

# 50. Rejected operations

Backend product/validation violations may arrive as consumed:

```text
rejected
```

operation results.

Handle them separately from transport failure.

Do not endlessly retry a rejected operation.

Persist/display enough information to ensure the athlete's locally entered data is not silently lost.

---

# 51. Device lease

Respect:

```text
lease_device_id
lease_epoch
```

semantics.

When the current device no longer owns the lease:

```text
superseded
```

stop normal writes.

Show the designed state:

```text
Continued on another device
```

and allow explicit:

```text
Resume here
```

through the claim endpoint.

Do not auto-claim.

---

# 52. Claim behaviour

After successful claim:

* accept the canonical server snapshot,
* move to the new lease epoch,
* reconcile/replace stale server-known workout state as required by the contract,
* restart sequencing from the correct epoch semantics.

Do not blindly replay old-epoch queued operations into the new epoch.

Preserve unresolved local data for inspection/recovery rather than silently deleting it.

---

# 53. Snapshot recovery

Treat:

```text
GET /workouts/{workout_id}
```

as the authoritative server recovery snapshot.

Use it for:

* lost local cache,
* process recovery when needed,
* claim,
* conflict recovery,
* protocol errors.

Remember:

```text
prescription
```

and:

```text
performance
```

are separate trees.

Keep them separate in Dart models.

---

# 54. ETag

Support backend ETag / `If-None-Match` behaviour for:

```text
/context
/workouts/{workout_id}
```

Store enough local information to make `304 Not Modified` useful.

Do not treat HTTP 304 as an error.

Reuse cached typed/local data when the server confirms it is current.

---

# 55. Cold start recovery

On application startup:

1. inspect durable local workout state,
2. inspect queued lifecycle/sync work,
3. obtain/revalidate mobile context when network is available,
4. identify any active server workout,
5. reconcile carefully,
6. present Resume rather than accidentally creating another workout.

App startup must not discard a local workout merely because the network is temporarily unavailable.

---

# 56. Server-active but local-missing workout

If the server reports an active workout but the phone has no useful local draft:

* show the designed resume flow,
* fetch the authoritative snapshot,
* claim explicitly if the lease belongs to another device,
* reconstruct local durable workout state,
* continue.

This is a required recovery path.

---

# 57. Local workout whose delayed start failed

If a workout was started offline locally and delayed server start later fails due to:

```text
active_workout_exists
```

or:

```text
prescription_changed
```

do not delete local workout data.

Implement the recovery UX described by the handoff/contract.

Data loss is worse than temporarily requiring human resolution.

---

# 58. Workout outline

Implement the designed whole-workout outline.

Clearly indicate:

* completed work,
* current exercise,
* upcoming work,
* skipped work,
* substitutions,
* added work,
* actual order.

The athlete should be able to inspect upcoming exercises without losing Focus Mode state.

---

# 59. Finish flow

Implement explicit Finish.

Before finalization:

1. persist current local state,
2. flush all required start/ops when network allows,
3. ensure server `applied_seq` reaches intended `final_seq`,
4. send finalize.

If work is incomplete, require the deliberate acknowledgement interaction from the design.

Send:

```text
acknowledged_incomplete
```

correctly.

---

# 60. Offline finish

If the athlete finishes while offline:

* persist finalization intent locally,
* mark the local UX appropriately,
* queue finalize behind all pending operations,
* deliver later when possible.

Do not claim server finalization until it has actually succeeded.

The UI must distinguish something like:

```text
Saved on this phone
```

from:

```text
Synced / finalized
```

according to the handoff.

---

# 61. Finalize errors

Handle:

```text
ops_pending
incomplete_not_acknowledged
workout_finalized
```

and other actual OpenAPI responses.

Do not simply show a generic Snackbar.

Use domain-specific recovery.

---

# 62. Completed workout

After successful finalize:

* update local durable state,
* stop active-workout mode,
* stop/clear workout timer state,
* preserve useful completed summary,
* refresh/revalidate `/context`,
* return to the designed completion/Home experience.

Do not delete useful data before confirmation from the server.

---

# 63. Atlas Quick Peek

Implement the supplied Quick Peek interaction using:

```text
GET /api/v1/mobile/atlas/exercises/{exercise_id}/peek
```

and the copy embedded inside prescription payloads.

Prefer the embedded data while offline.

Render:

* exercise information,
* technique TL;DR,
* top muscles,
* anatomical highlighting,

according to the design.

---

# 64. Anatomy SVG

Find the canonical existing anatomy SVG in the Agonez repo.

Copy/bundle it into:

```text
mobile-fe/assets/
```

or another appropriate local asset path.

Use the backend-provided region IDs/intensities to render/highlight the existing SVG.

Do not create exercise-specific bitmap images.

Do not rename anatomical region identity arbitrarily.

Make this work offline for embedded workout peeks.

---

# 65. Atlas search

Implement mobile Atlas search using the actual endpoint.

Use it for:

* substitution,
* add unplanned exercise,
* normal Atlas browsing where appropriate.

When `plan_run_id` is supplied, display useful previous run-local performance context if provided.

---

# 66. Full Atlas article

The backend handoff states that full Atlas data is served by the existing:

```text
/api/atlas/exercises/{slug}
```

route.

Reuse it.

Do not expect a duplicate `/api/v1/mobile/.../full` endpoint.

Implement full mobile Atlas rendering based on the actual response/OpenAPI/repository structures available.

---

# 67. Atlas mobile adaptation

Use the web Atlas only as a visual/domain reference.

Do not embed the Vue page or create a WebView as the main solution.

Build a native Flutter representation.

Preserve:

* Agonez identity,
* technical information hierarchy,
* anatomy semantics,
* technique content,
* exercise metadata.

---

# 68. Atlas quick peek vs full workspace

Implement both levels from the final design.

## Quick Peek

Fast contextual overlay/sheet from current workout.

Workout remains active underneath.

## Full Atlas

Persistent workspace for deeper browsing.

Do not collapse these into one awkward screen if the design explicitly distinguishes them.

---

# 69. Persistent workspaces/tabs

Implement the design's mobile workspace/tab concept.

Expected properties:

* active workout workspace remains persistent,
* workout cannot be closed using generic Atlas-tab close,
* multiple Atlas articles may stay open,
* Atlas workspaces can be closed,
* switching workspaces does not destroy workout state,
* tabs do not permanently steal excessive screen height.

This state is client-only.

Persist it locally if the handoff specifies process-restart persistence.

---

# 70. Bottom navigation

Implement the final navigation from the design.

While workout is active, the Workout destination should visibly indicate active state.

Tapping Workout must return immediately to current workout position.

Do not show a generic workout landing page first when a workout is already active.

---

# 71. User/Profile section

Do only what the design/handoff defines.

Do not invent account/authentication flows.

Plan-run context/settings may live there if designed.

Authentication is explicitly outside v1 backend scope.

---

# 72. Visual implementation

Reproduce:

```text
mobile-design-reference.html
```

faithfully.

Pay attention to:

* typography hierarchy,
* spacing,
* information density,
* bottom navigation,
* sheets,
* workout controls,
* set-entry controls,
* status indicators,
* Atlas layout,
* workspace switcher,
* progress states.

Do not turn it into generic Material-default UI.

Use Flutter widgets to reproduce the design while retaining native interaction quality.

---

# 73. Existing Agonez visual identity

Inspect `web-fe` for:

* fonts,
* colours,
* logos,
* icon language,
* Atlas styling.

Reuse assets and values where appropriate.

Do not create an unrelated mobile brand.

However, mobile interactions must remain mobile-native.

Do not shrink desktop components.

---

# 74. Theme

Create a coherent Flutter theme/design-token layer.

Avoid hard-coded visual values scattered across feature widgets.

Centralize appropriate:

* colours,
* typography,
* spacing,
* radii,
* component styling.

Follow the design reference rather than inventing a large abstract design system.

---

# 75. Haptics

Implement meaningful haptics where the final design calls for them, for example:

* confirmed set,
* completed hold-to-confirm,
* timer completion,
* workout completion.

Use sparingly.

Do not make every tap vibrate.

---

# 76. Android back behaviour

Be careful with Android system back.

During an active workout, Back must not accidentally:

* cancel workout,
* discard draft,
* clear progress.

Respect nested navigation/sheets/workspaces while keeping the workout alive.

Use explicit finish for workout termination.

---

# 77. Android lifecycle

Test:

* foreground → background → foreground,
* process killed/restarted,
* screen lock where practical.

Workout state and timer must recover from durable/timestamp state.

Do not rely on widgets/providers remaining alive.

---

# 78. Loading states

Implement design-consistent:

* initial loading,
* revalidation,
* cached/offline state,
* API error state.

Do not block an already loaded active workout behind a full-screen network spinner just because background sync is happening.

---

# 79. Error model

Centralize mapping of backend:

```text
error.code
```

to localized user-facing behaviour.

Important errors include at minimum:

```text
active_workout_exists
prescription_changed
session_not_startable
prescription_missing
off_schedule_not_supported
seq_gap
seq_mismatch
superseded
workout_finalized
workout_not_found
ops_pending
incomplete_not_acknowledged
```

plus operation rejection codes.

Do not show raw backend English diagnostic messages to users.

Log them where useful.

---

# 80. Logging

Add sensible debug logging for:

* API requests,
* workout lifecycle,
* queue state transitions,
* operation delivery,
* sequence reconciliation,
* lease changes,
* conflicts.

Never log massive irrelevant payloads continuously.

Do not log secrets; there are currently no auth credentials.

Make it possible to diagnose sync failures during development.

---

# 81. Tests

Build meaningful automated tests.

At minimum cover the following areas.

## Models / protocol

* API serialization/deserialization,
* deterministic UUID generation,
* enum adaptations,
* nullable prescription fields.

## Local persistence

* workout survives database reopen,
* queued operations survive process-equivalent reconstruction,
* sequence allocation remains correct,
* timer timestamps restore correctly.

## Sync engine

* start before ops,
* contiguous ops,
* duplicate acknowledgement,
* retry after timeout,
* sequence gap,
* superseded lease,
* conflict,
* rejected operation,
* finalize after queue drains.

## State/UI

* Home expected workout,
* Resume state,
* Focus Mode,
* Confirm Set,
* structural deviation confirmation,
* offline indicator,
* finish incomplete flow,
* Atlas Quick Peek,
* workspace persistence where practical.

Do not target meaningless 100% coverage.

Test correctness boundaries.

---

# 82. Fake API testing

Make the API layer injectable.

Automated tests should not depend exclusively on the public VPS.

Use fake/mock API transport where appropriate.

However, mocks are not sufficient for final integration acceptance.

---

# 83. Formatting/static analysis quality gate

Before finishing, run:

```powershell
dart format .
flutter analyze
flutter test
```

Resolve real warnings/errors.

Do not suppress analyzer rules merely to achieve green output unless justified.

---

# 84. Android build

Run:

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=http://192.46.236.119:33287
```

The Android APK must build successfully.

Do not consider successful Dart unit tests alone sufficient.

---

# 85. Physical-device execution

Run the application on:

```text
ZY22LNTRJ6
```

using:

```powershell
flutter run -d ZY22LNTRJ6 --dart-define=API_BASE_URL=http://192.46.236.119:33287
```

Verify that it installs, launches and can communicate with the real backend.

Do not stop at compile/build if the physical device is available.

---

# 86. Real-backend smoke test

Against:

```text
http://192.46.236.119:33287
```

validate at least:

```text
cold launch
→ mobile context loads
→ active plan run renders
→ expected workout renders
→ prescription can be opened
→ Atlas Quick Peek loads
```

Then, where the current backend/demo state provides a safely startable workout, test the live execution path.

Do not modify backend source or database manually to manufacture a passing UI test.

---

# 87. Real execution acceptance flow

When backend state permits, validate:

```text
open app
↓
load /context
↓
open today's workout
↓
start workout
↓
record multiple real set operations
↓
observe sync acknowledgement
↓
background/terminate and relaunch app
↓
resume the same workout
↓
continue recording
↓
finish
↓
flush operations
↓
finalize
↓
refresh Home/context
```

Use the real mobile API.

If the actual VPS dataset contains no safe startable session, do not corrupt unrelated data to force this scenario.

Instead report the environmental blocker and validate the mutation protocol through automated integration/fake tests plus all available real read-only/device checks.

---

# 88. Offline acceptance test

Validate offline behaviour, either with controlled network disabling or an injectable transport failure.

Required scenario:

```text
active workout
↓
network unavailable
↓
confirm several sets
↓
UI continues normally
↓
operations remain durable
↓
app restart
↓
workout and queue still exist
↓
network returns
↓
same operations synchronize
↓
no duplicated performance
```

This is a core product requirement, not an optional enhancement.

---

# 89. Timeout/retry correctness

Test the logical equivalent of:

```text
request committed by server
but response lost
↓
same batch retried
↓
backend returns duplicate
↓
client acknowledges it
↓
no duplicate local/server performance
```

The app must be comfortable with at-least-once delivery.

---

# 90. Physical visual check

Compare the running Motorola UI against:

```text
mobile-design-reference.html
```

Pay particular attention to:

* Focus Mode,
* touch-target sizes,
* one-thumb usability,
* screen density,
* SafeArea behaviour,
* bottom navigation,
* sheets,
* Atlas view,
* workout progress,
* timer,
* workspace strip,
* sync indicators.

Fix obvious divergence before finishing.

---

# 91. Android 16

The target physical phone uses Android 16.

Ensure:

* safe areas/insets are handled,
* keyboard does not break set-entry layout,
* edge-to-edge behaviour is sane,
* bottom navigation is not hidden by system UI,
* back behaviour is correct.

---

# 92. No unnecessary platform work

Do not spend time making:

```text
flutter build web
flutter build windows
iOS signing
```

work.

Those platforms are outside the current Definition of Done.

---

# 93. Documentation

Add concise documentation under `mobile-fe/`, for example:

```text
mobile-fe/README.md
mobile-fe/docs/architecture.md
```

Document:

* architecture,
* selected libraries,
* configuration,
* how to run,
* how to set `API_BASE_URL`,
* local DB role,
* workout sync model,
* device ID,
* offline lifecycle,
* conflict handling,
* Atlas asset strategy,
* localization,
* tests.

Do not duplicate the full external API contract.

---

# 94. Development run documentation

The README should clearly contain the current development command:

```powershell
flutter run -d ZY22LNTRJ6 --dart-define=API_BASE_URL=http://192.46.236.119:33287
```

and build command:

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=http://192.46.236.119:33287
```

Explain that this is currently HTTP development infrastructure and will later move behind HTTPS/Caddy.

---

# 95. Keep changes inside mobile-fe

At the end verify Git diff.

Production changes from this task should be under:

```text
mobile-fe/
```

Do not casually commit modifications to:

```text
be/
web-fe/
```

Copy required assets into `mobile-fe` instead of introducing runtime coupling to sibling frontend directories.

---

# 96. Final audit against the design

Review every P0/P1/P2 item in:

```text
mobile-implementation-handoff.md
```

Mark internally:

```text
implemented
implemented with justified adaptation
not implemented
```

P0 omissions should be treated as blockers.

Document any remaining P1/P2 adaptation.

---

# 97. Final audit against backend contract

Compare implementation with:

```text
api/openapi.yaml
api-mobile-backend.md
mobile-api-contract.md
```

Verify at minimum:

* every consumed endpoint,
* required headers,
* all ten operation types,
* lease/epoch handling,
* sequence handling,
* duplicate handling,
* ETag handling,
* conflict handling,
* finalize handling,
* Atlas reads,
* actual backend adaptations.

There should be no silent protocol assumptions.

---

# 98. Final report

When complete, provide a concise implementation report covering:

1. Flutter architecture created,
2. packages/dependencies added,
3. major directories/components,
4. navigation architecture,
5. local Drift schema,
6. API client architecture,
7. device-id implementation,
8. sync queue design,
9. sequence/idempotency implementation,
10. lease/claim implementation,
11. conflict handling,
12. offline start/resume/finalize behaviour,
13. Atlas implementation,
14. anatomy SVG implementation,
15. localization implementation,
16. files/assets added,
17. automated tests added,
18. `flutter analyze` result,
19. `flutter test` result,
20. APK build result,
21. physical-device run result,
22. real-backend smoke-test result,
23. offline/restart test result,
24. any design adaptations,
25. any backend-contract adaptations,
26. remaining blockers/issues.

---

# Definition of Done

The application is complete when this experience works coherently:

```text
Launch Agonez on the physical Android phone
↓
Home loads the real mobile context
↓
Today's prescribed workout is obvious
↓
Start workout
↓
Workout becomes a persistent Focus Mode workspace
↓
Prescription is visible but immutable
↓
Actual Load / Reps / RIR can be recorded quickly with one thumb
↓
Confirming a set persists locally first
↓
The athlete immediately continues regardless of network latency
↓
Rest timer starts locally
↓
Confirmed field data synchronizes through the ordered op protocol
↓
Normal prescription divergence is frictionless
↓
Structural deviations require deliberate interaction
↓
Atlas Quick Peek works from the workout
↓
Full Atlas can be opened without destroying workout state
↓
Network may disappear
↓
Workout continues and queued data remains durable
↓
App may be killed
↓
App reopens and resumes the correct workout/set
↓
Network returns
↓
Pending operations synchronize exactly once in effect
↓
Workout finishes explicitly
↓
All queued operations flush before finalize
↓
Server finalizes the same Execution performance
↓
Home refreshes and the workout is no longer active
```

The core technical acceptance criterion is:

> Can the athlete treat the phone as a reliable workout notebook even with intermittent connectivity and process death, while the Flutter client safely synchronizes the same normalized Execution facts to the existing Agonez backend without duplication, silent data loss or accidental mutation of the prescription?

The core UX acceptance criterion is:

> During a hard set, does the application keep the athlete focused on exactly what to do and make truthful recording of Load / Reps / RIR faster than writing it down manually?

If either answer is not cleanly **yes**, continue implementation and validation.
