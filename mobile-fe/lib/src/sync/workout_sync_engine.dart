import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';

import '../api/agonez_api_client.dart';
import '../api/api_error.dart';
import '../api/conditional_response.dart';
import '../api/json_support.dart';
import '../api/operation_models.dart';
import '../api/wire_enums.dart';
import '../api/workout_models.dart';
import '../storage/app_database.dart';

typedef BackoffForAttempt = Duration Function(int attempt);

class WorkoutSyncEngine {
  WorkoutSyncEngine({
    required AppDatabase database,
    required AgonezApiClient api,
    Connectivity? connectivity,
    BackoffForAttempt? backoffForAttempt,
    void Function()? onWorkoutFinalized,
  }) : _database = database,
       _api = api,
       _connectivity = connectivity ?? Connectivity(),
       _backoffForAttempt = backoffForAttempt ?? _defaultBackoff,
       _onWorkoutFinalized = onWorkoutFinalized;

  final AppDatabase _database;
  final AgonezApiClient _api;
  final Connectivity _connectivity;
  final BackoffForAttempt _backoffForAttempt;
  final void Function()? _onWorkoutFinalized;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _retryTimer;
  bool _running = false;
  bool _requested = false;
  bool _disposed = false;
  Completer<void>? _idleCompleter;

  void start() {
    if (_disposed || _connectivitySubscription != null) return;
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((_) {
      // A connectivity signal only wakes the outbox. Request success remains
      // the source of truth for reachability.
      kick();
    });
    kick();
  }

  void kick() {
    if (_disposed) return;
    _requested = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    unawaited(_drain());
  }

  Future<void> syncNow() async {
    if (_disposed) return;
    kick();
    if (_running) {
      _idleCompleter ??= Completer<void>();
      await _idleCompleter!.future;
    }
  }

  Future<void> _drain() async {
    if (_running || _disposed) return;
    _running = true;
    try {
      while (!_disposed) {
        _requested = false;
        final progressed = await _syncOneStep();
        if (!progressed && !_requested) break;
      }
    } finally {
      _running = false;
      _idleCompleter?.complete();
      _idleCompleter = null;
      if (_requested && !_disposed) unawaited(_drain());
    }
  }

  Future<bool> _syncOneStep() async {
    final workout = await _database.activeWorkout();
    if (workout == null ||
        workout.lifecycle == 'completed' ||
        workout.syncState == 'conflict' ||
        workout.syncState == 'superseded' ||
        workout.syncState == 'recovery_required') {
      return false;
    }
    if (workout.nextSyncAt?.isAfter(DateTime.now().toUtc()) ?? false) {
      _scheduleAt(workout.nextSyncAt!);
      return false;
    }

    try {
      // Finishing before the initial request succeeds changes the lifecycle to
      // pending_finalize. The missing snapshot is the durable indication that
      // the server still needs the idempotent start before any queued ops.
      if (workout.serverSnapshotJson == null) {
        await _deliverStart(workout);
        return true;
      }

      final pending = await _database.deliverableOperations(workout.workoutId);
      if (pending.isNotEmpty) {
        await _deliverOperations(workout, pending);
        return true;
      }

      if (workout.lifecycle == 'pending_finalize' &&
          workout.finalizePayloadJson != null) {
        return _deliverFinalize(workout);
      }

      final unresolved = await _database.pendingOperationCount(
        workout.workoutId,
      );
      if (workout.syncState != 'saved' && unresolved == 0) {
        await _database.markSyncIssue(
          workoutId: workout.workoutId,
          state: 'saved',
          attempts: 0,
        );
      }
      return false;
    } on AgonezApiException catch (error, stackTrace) {
      developer.log(
        'Workout sync API failure: ${error.error?.code ?? error.cause.type.name}',
        name: 'agonez.sync',
        error: error,
        stackTrace: stackTrace,
      );
      return _handleApiError(workout, error);
    } on Object catch (error, stackTrace) {
      developer.log(
        'Workout sync failure',
        name: 'agonez.sync',
        error: error,
        stackTrace: stackTrace,
      );
      await _retryLater(workout, errorCode: 'client_sync_error');
      return false;
    }
  }

  Future<void> _deliverStart(LocalWorkout workout) async {
    await _database.markSyncIssue(
      workoutId: workout.workoutId,
      state: 'saving',
    );
    final payload = StartWorkout.fromJson(
      asJsonMap(jsonDecode(workout.startPayloadJson), 'start payload'),
    );
    final snapshot = await _api.startWorkout(payload);
    await _database.markStartAcknowledged(
      workoutId: workout.workoutId,
      leaseEpoch: snapshot.lease.epoch,
      appliedSeq: snapshot.appliedSeq,
      revision: snapshot.revision,
      snapshot: snapshot.toJson(),
    );
    developer.log(
      'Start acknowledged for ${workout.workoutId}',
      name: 'agonez.sync',
    );
  }

  Future<void> _deliverOperations(
    LocalWorkout workout,
    List<PendingOperation> pending,
  ) async {
    if (pending.first.seq != workout.appliedSeq + 1) {
      await _snapshotAndBlock(workout, 'seq_mismatch');
      return;
    }
    final operations = pending
        .map((operation) {
          return WorkoutOperation.fromJson(<String, Object?>{
            'op_id': operation.opId,
            'seq': operation.seq,
            'at': operation.occurredAt.toUtc().toIso8601String(),
            'type': operation.type,
            'data': asJsonMap(jsonDecode(operation.dataJson), 'operation data'),
          });
        })
        .toList(growable: false);
    final batch = OperationBatch(
      leaseEpoch: workout.leaseEpoch,
      baseSeq: workout.appliedSeq,
      ops: operations,
    );
    await _database.markSyncIssue(
      workoutId: workout.workoutId,
      state: 'saving',
    );
    final response = await _api.applyOperations(workout.workoutId, batch);
    await _database.acknowledgeOperations(
      workoutId: workout.workoutId,
      leaseEpoch: workout.leaseEpoch,
      appliedSeq: response.appliedSeq,
      revision: response.revision,
      resultsBySeq: <int, Map<String, Object?>>{
        for (final result in response.results) result.seq: result.toJson(),
      },
    );
    developer.log(
      'Applied through seq ${response.appliedSeq} for ${workout.workoutId}',
      name: 'agonez.sync',
    );
  }

  Future<bool> _deliverFinalize(LocalWorkout workout) async {
    final pendingCount = await _database.pendingOperationCount(
      workout.workoutId,
    );
    if (pendingCount != 0) return false;
    final payload = FinalizeWorkout.fromJson(
      asJsonMap(jsonDecode(workout.finalizePayloadJson!), 'finalize payload'),
    );
    if (payload.finalSeq != workout.appliedSeq) {
      await _snapshotAndBlock(workout, 'ops_pending');
      return false;
    }
    await _database.markSyncIssue(
      workoutId: workout.workoutId,
      state: 'saving',
    );
    final response = await _api.finalizeWorkout(workout.workoutId, payload);
    await _database.markCompleted(
      workoutId: workout.workoutId,
      finishedAt: response.finishedAt,
      response: response.toJson(),
    );
    _onWorkoutFinalized?.call();
    developer.log('Finalized ${workout.workoutId}', name: 'agonez.sync');
    return true;
  }

  Future<bool> _handleApiError(
    LocalWorkout workout,
    AgonezApiException exception,
  ) async {
    final code = exception.error?.code;
    if (exception.isTransportFailure) {
      await _retryLater(workout, errorCode: 'offline', state: 'offline');
      return false;
    }
    if ((exception.statusCode ?? 0) >= 500) {
      await _retryLater(workout, errorCode: code ?? 'server_error');
      return false;
    }
    switch (code) {
      case 'seq_gap':
        final expected = exception.error?.details['expected_seq'];
        if (expected is int && await _hasQueuedSequence(workout, expected)) {
          await _database.reconcileExpectedSequence(
            workoutId: workout.workoutId,
            expectedSeq: expected,
          );
          return true;
        }
        await _snapshotAndBlock(workout, 'seq_gap');
        return false;
      case 'seq_mismatch':
        await _snapshotAndBlock(workout, 'seq_mismatch');
        return false;
      case 'superseded':
        await _database.markSyncIssue(
          workoutId: workout.workoutId,
          state: 'superseded',
          errorCode: code,
        );
        return false;
      case 'workout_finalized':
        await _recoverFinalizedWorkout(workout);
        return false;
      case 'workout_not_found':
        await (_database.update(
          _database.localWorkouts,
        )..where((row) => row.workoutId.equals(workout.workoutId))).write(
          LocalWorkoutsCompanion(
            lifecycle: const Value('pending_start'),
            syncState: const Value('saving'),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
        return true;
      case 'ops_pending':
        await _snapshotAndBlock(workout, 'ops_pending');
        return false;
      case 'active_workout_exists':
      case 'prescription_changed':
      case 'session_not_startable':
      case 'prescription_missing':
      case 'off_schedule_not_supported':
      case 'incomplete_not_acknowledged':
        await _database.markSyncIssue(
          workoutId: workout.workoutId,
          state: 'recovery_required',
          errorCode: code,
        );
        return false;
      default:
        await _database.markSyncIssue(
          workoutId: workout.workoutId,
          state: 'failed',
          errorCode: code ?? 'request_failed',
        );
        return false;
    }
  }

  Future<bool> _hasQueuedSequence(LocalWorkout workout, int sequence) async {
    final row =
        await (_database.select(_database.pendingOperations)..where(
              (candidate) =>
                  candidate.workoutId.equals(workout.workoutId) &
                  candidate.leaseEpoch.equals(workout.leaseEpoch) &
                  candidate.seq.equals(sequence) &
                  candidate.deliveryState.isIn(['queued', 'in_flight']),
            ))
            .getSingleOrNull();
    return row != null;
  }

  Future<void> _snapshotAndBlock(LocalWorkout workout, String errorCode) async {
    try {
      final response = await _api.getWorkout(workout.workoutId);
      if (response is ModifiedResponse<WorkoutSnapshot>) {
        await _database.storeServerSnapshot(
          workoutId: workout.workoutId,
          snapshot: response.value.toJson(),
          etag: response.etag,
        );
      }
    } on Object catch (error, stackTrace) {
      developer.log(
        'Snapshot recovery failed',
        name: 'agonez.sync',
        error: error,
        stackTrace: stackTrace,
      );
    }
    await _database.markSyncIssue(
      workoutId: workout.workoutId,
      state: 'conflict',
      errorCode: errorCode,
    );
  }

  Future<void> _recoverFinalizedWorkout(LocalWorkout workout) async {
    final response = await _api.getWorkout(workout.workoutId);
    if (response is ModifiedResponse<WorkoutSnapshot>) {
      final snapshot = response.value;
      if (snapshot.status == WorkoutStatus.completed) {
        await _database.markCompleted(
          workoutId: workout.workoutId,
          finishedAt: snapshot.finishedAt ?? DateTime.now().toUtc(),
          response: snapshot.toJson(),
        );
        _onWorkoutFinalized?.call();
        return;
      }
    }
    await _database.markSyncIssue(
      workoutId: workout.workoutId,
      state: 'conflict',
      errorCode: 'workout_finalized',
    );
  }

  Future<void> _retryLater(
    LocalWorkout workout, {
    required String errorCode,
    String state = 'failed',
  }) async {
    final attempts = workout.syncAttempts + 1;
    final delay = _backoffForAttempt(attempts);
    final at = DateTime.now().toUtc().add(delay);
    await _database.markSyncIssue(
      workoutId: workout.workoutId,
      state: state,
      errorCode: errorCode,
      attempts: attempts,
      nextAttemptAt: at,
    );
    _scheduleAt(at);
  }

  void _scheduleAt(DateTime at) {
    if (_disposed) return;
    _retryTimer?.cancel();
    final delay = at.difference(DateTime.now().toUtc());
    _retryTimer = Timer(delay.isNegative ? Duration.zero : delay, kick);
  }

  static Duration _defaultBackoff(int attempt) {
    final seconds = min(60, pow(2, max(0, attempt - 1)).toInt());
    final jitter = 0.85 + Random().nextDouble() * 0.3;
    return Duration(milliseconds: (seconds * 1000 * jitter).round());
  }

  Future<void> dispose() async {
    _disposed = true;
    _retryTimer?.cancel();
    await _connectivitySubscription?.cancel();
  }
}
