# Mobile architecture

Agonez Mobile uses Riverpod for composition/state, `go_router` for the persistent four-destination shell and immersive Focus route, Dio for one API boundary, and Drift/SQLite as part of workout correctness.

## Offline execution

A start tap first stores a client UUID and frozen prescription. Confirming a set atomically updates the local performance tree, allocates a durable `(epoch, seq, op_id)`, and inserts the operation. The UI advances immediately. `SyncEngine` delivers dependencies in strict order: start, contiguous operation batches, then finalize. Requests are retried with the same identifiers; duplicate acknowledgement is safe. Finalize intent remains local until all earlier operations are acknowledged.

Prescribed performance IDs are UUIDv5 values derived from the workout UUID and server prescription ID. Additional entities and operations use UUIDv4.

## State boundaries

- Server facts: plan run, session, frozen prescription, acknowledged performance.
- Durable phone state: installation device ID, selected plan run, active workout, prescription, performance draft, cursor, rest timestamp, ordered queue, finalize intent and Atlas workspaces.
- Transient UI: current unconfirmed load/reps/RIR and open sheets.

The canonical `anatomy.svg` is bundled. Embedded Atlas peek data stays available offline; full articles use the existing slug endpoint.
