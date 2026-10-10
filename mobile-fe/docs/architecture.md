# Mobile architecture

## Shape of the app

`lib/main.dart` bootstraps one `AppRuntime`, then Riverpod exposes its services
to the UI. The package is split by responsibility:

- `src/config`: required compile-time configuration.
- `src/api`: Dio transport, request headers, wire enums, typed DTOs, and API
  error decoding.
- `src/data`: cached read models for context, prescriptions, and atlas data.
- `src/storage`: Drift schema and transactional local mutations.
- `src/workout`: workout IDs, local-first commands, recovery, and rest timing.
- `src/sync`: the single-writer workout outbox drain.
- `src/platform`: Android notification integration.
- `src/features`: Home, Focus workout, Atlas, and account/settings surfaces.
- `src/design`, `src/widgets`, and `src/l10n`: shared visual and language
  foundations.

The API client is injected into repositories rather than called by widgets.
Feature code observes Drift/Riverpod state, issues repository commands, and
renders sync state without treating network reachability as truth.

## API boundary

The base URL comes only from `--dart-define=API_BASE_URL=...`. Mobile endpoints
live under `/api/v1/mobile`; full atlas articles use `/api/atlas/exercises/...`.
Every request carries:

- `X-Agonez-Device-Id`: stable installation UUID stored in Drift;
- `X-Agonez-Client`: application version and Android build;
- `Accept-Language`: `en` or `pl` from the current app setting.

Context and workout snapshots use ETags. A `304 Not Modified` reuses the cached
document. Prescriptions and atlas content are cached after successful reads so
already-seen material remains available offline.

## Local database

`AppDatabase` owns seven durable concerns:

| Table | Responsibility |
| --- | --- |
| `app_key_values` | Installation identity and user settings |
| `cached_documents` | Locale-aware API JSON and ETags |
| `local_workouts` | Frozen prescription, lifecycle, lease, cursor, timer, and sync state |
| `local_exercises` | Performed exercise order, substitutions, comments, and revisions |
| `local_sets` | Confirmed, skipped, or cleared set values |
| `pending_operations` | Ordered, retryable server command outbox |
| `atlas_workspaces` | Offline quick-peek workspace data |

A workout is created locally before the start request is attempted. Its
prescription is frozen into the row, so a later plan edit cannot rewrite a
workout already in progress. Generated workout and additional-item IDs are
UUIDv4; IDs derived from prescribed records use deterministic UUIDv5 values so
retries and reopen flows reference the same records.

## Mutation and outbox rules

Workout changes commit the local projection and its corresponding outbox
operation in one Drift transaction. UI success therefore means "saved on this
device," not "the server answered." The sync engine is the only network writer
and preserves the protocol order:

1. Send the idempotent workout start if no server snapshot exists.
2. Send pending operations in ascending sequence order.
3. Finalize only after the server has applied the declared final sequence.

Operations are ordered by `(lease_epoch, seq, op_id)`. Duplicate delivery is
safe. A server result consumes its sequence even when the individual command is
reported as a conflict or rejection; the local result remains inspectable.
Missing set data is not converted into skipped data—unfinished values remain
missing until the athlete confirms, skips, or clears them explicitly.

Connectivity events merely wake the drain. A successful request is the only
proof that the server is reachable. Transport and server failures retain the
outbox and retry with capped exponential backoff plus jitter.

## Lifecycle and recovery

The durable lifecycle is `pending_start` → `active` → `pending_finalize` →
`completed`. App termination at any point is safe because the frozen
prescription, cursor, rest-timer deadline, local projection, and unsent commands
are stored before network delivery.

Recovery behavior is conservative:

- A sequence gap is reconciled only when the expected queued command exists;
  otherwise a fresh snapshot is stored and sync stops for review.
- A sequence mismatch, unresolved pending operations at finalize, or another
  contradictory server state stores a snapshot and marks a conflict.
- A superseded lease stops delivery immediately.
- An already-finalized server workout is imported as completed when confirmed
  by its snapshot.
- Claiming a server-active workout is explicit. It sends the observed applied
  sequence, imports the returned snapshot, adopts the new lease epoch, and
  retires queued commands from older epochs rather than replaying them.
- Startability, changed-prescription, and incomplete-acknowledgement errors are
  marked `recovery_required`; the app does not guess a destructive resolution.

The sync badge reflects these persisted states (`saving`, `saved`, `offline`,
`failed`, `conflict`, `superseded`, or `recovery_required`) after a restart.

## Rest notifications

The in-app rest deadline is authoritative and persisted as UTC time. Android
notifications are a convenience layer. They use inexact scheduling, so the app
does not request `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM`. The manifest does
declare notification, vibration, reboot, and plugin receivers so an opted-in
timer can be restored after reboot. Core-library desugaring is enabled for the
notification plugin while the project remains on JDK 17, AGP 8.11, and Android
compile/target SDK 36.

## Localization and offline assets

Flutter gen-l10n generates strongly typed English and Polish messages from the
two ARB files. Persisted locale selection controls both the widget tree and API
localization. New message keys must be added to both files before generation.

The anatomy SVG and logo are packaged application assets, not runtime web
downloads. Atlas quick peeks use the packaged semantic SVG plus cached exercise
metadata, which keeps the primary anatomy interaction available without a
network connection.
