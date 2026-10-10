import 'dart:io';

import 'package:agonez/src/api/agonez_api_client.dart';
import 'package:agonez/src/api/api_error.dart';
import 'package:agonez/src/api/conditional_response.dart';
import 'package:agonez/src/api/operation_models.dart';
import 'package:agonez/src/api/wire_enums.dart';
import 'package:agonez/src/api/workout_models.dart';
import 'package:agonez/src/storage/app_database.dart';
import 'package:agonez/src/sync/workout_sync_engine.dart';
import 'package:agonez/src/workout/workout_repository.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/workout_fixtures.dart';

class _MockApi extends Mock implements AgonezApiClient {}

class _FakeStartWorkout extends Fake implements StartWorkout {}

class _FakeOperationBatch extends Fake implements OperationBatch {}

class _FakeFinalizeWorkout extends Fake implements FinalizeWorkout {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeStartWorkout());
    registerFallbackValue(_FakeOperationBatch());
    registerFallbackValue(_FakeFinalizeWorkout());
  });

  test('transport failure keeps the local workout and outbox intact', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final api = _MockApi();
    final repository = WorkoutRepository(database: database);
    final workoutId = await repository.start(
      prescription: fixturePrescription,
      startedAt: DateTime.utc(2026, 10, 10, 17),
    );
    await repository.confirmSet(
      workoutId: workoutId,
      exercise: fixturePrescriptionExercise,
      prescribedSet: fixtureSet,
      ordinal: 0,
      loadKg: 80,
      repetitions: 8,
      rir: 2,
      nextExerciseIndex: 0,
      nextSetIndex: 1,
      performedAt: DateTime.utc(2026, 10, 10, 17, 2),
    );
    when(() => api.startWorkout(any())).thenThrow(_transportFailure());
    final engine = WorkoutSyncEngine(
      database: database,
      api: api,
      backoffForAttempt: (_) => const Duration(hours: 1),
    );

    await engine.syncNow();

    final workout = await database.activeWorkout();
    final sets = await database.workoutSets(workoutId);
    final operations = await database.deliverableOperations(workoutId);
    expect(workout!.lifecycle, 'pending_start');
    expect(workout.syncState, 'offline');
    expect(workout.syncAttempts, 1);
    expect(workout.serverSnapshotJson, isNull);
    expect(sets.single.repetitions, 8);
    expect(operations.single.deliveryState, 'queued');
    verify(() => api.startWorkout(any())).called(1);
    verifyNever(() => api.applyOperations(any(), any()));

    await engine.dispose();
    await database.close();
  });

  test(
    'restart replays start, operations, and finalize in protocol order',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'agonez-sync-restart-',
      );
      final databaseFile = File('${tempDirectory.path}/agonez.sqlite');
      final firstApi = _MockApi();
      var database = AppDatabase(NativeDatabase(databaseFile));
      final repository = WorkoutRepository(database: database);
      final startedAt = DateTime.utc(2026, 10, 10, 17);
      final finishedAt = DateTime.utc(2026, 10, 10, 17, 40);
      final workoutId = await repository.start(
        prescription: fixturePrescription,
        startedAt: startedAt,
      );
      await repository.confirmSet(
        workoutId: workoutId,
        exercise: fixturePrescriptionExercise,
        prescribedSet: fixtureSet,
        ordinal: 0,
        loadKg: 82.5,
        repetitions: 7,
        rir: 1,
        nextExerciseIndex: 0,
        nextSetIndex: 1,
        performedAt: startedAt.add(const Duration(minutes: 2)),
      );
      await repository.finish(
        workoutId: workoutId,
        acknowledgedIncomplete: false,
        finishedAt: finishedAt,
      );
      when(() => firstApi.startWorkout(any())).thenThrow(_transportFailure());
      final firstEngine = WorkoutSyncEngine(
        database: database,
        api: firstApi,
        backoffForAttempt: (_) => const Duration(hours: 1),
      );

      await firstEngine.syncNow();
      final offlineWorkout = await database.activeWorkout();
      expect(offlineWorkout!.syncState, 'offline');
      expect(offlineWorkout.serverSnapshotJson, isNull);
      verify(() => firstApi.startWorkout(any())).called(1);
      await firstEngine.dispose();
      await database.close();

      database = AppDatabase(NativeDatabase(databaseFile));
      await database.markSyncIssue(
        workoutId: workoutId,
        state: 'offline',
        attempts: 1,
        nextAttemptAt: DateTime.utc(2000),
      );
      final secondApi = _MockApi();
      when(() => secondApi.startWorkout(any())).thenAnswer((invocation) async {
        final payload = invocation.positionalArguments.single as StartWorkout;
        return fixtureSnapshot(
          workoutId: payload.workoutId,
          startedAt: payload.startedAt,
        );
      });
      when(() => secondApi.applyOperations(any(), any())).thenAnswer((
        invocation,
      ) async {
        final batch = invocation.positionalArguments[1] as OperationBatch;
        return fixtureOperationResponse(batch);
      });
      when(() => secondApi.finalizeWorkout(any(), any())).thenAnswer(
        (_) async => FinalizeResponse(
          workoutId: workoutId,
          finishedAt: finishedAt,
          summary: emptyCompletionSummary,
        ),
      );
      final secondEngine = WorkoutSyncEngine(
        database: database,
        api: secondApi,
      );

      await secondEngine.syncNow();

      final stored = await (database.select(
        database.localWorkouts,
      )..where((row) => row.workoutId.equals(workoutId))).getSingle();
      final operation = await database
          .select(database.pendingOperations)
          .getSingle();
      expect(stored.lifecycle, 'completed');
      expect(stored.syncState, 'saved');
      expect(stored.appliedSeq, 1);
      expect(stored.finalizedAt!.toUtc(), finishedAt);
      expect(operation.deliveryState, 'acknowledged');
      verifyInOrder([
        () => secondApi.startWorkout(any()),
        () => secondApi.applyOperations(workoutId, any()),
        () => secondApi.finalizeWorkout(workoutId, any()),
      ]);

      await secondEngine.dispose();
      await database.close();
      await tempDirectory.delete(recursive: true);
    },
  );

  test(
    'a non-contiguous local outbox snapshots and blocks the workout',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final api = _MockApi();
      final repository = WorkoutRepository(database: database);
      final startedAt = DateTime.utc(2026, 10, 10, 17);
      final workoutId = await repository.start(
        prescription: fixturePrescription,
        startedAt: startedAt,
      );
      await database.markStartAcknowledged(
        workoutId: workoutId,
        leaseEpoch: 1,
        appliedSeq: 0,
        revision: 1,
        snapshot: fixtureSnapshot(
          workoutId: workoutId,
          startedAt: startedAt,
        ).toJson(),
      );
      await repository.setWorkoutComment(workoutId: workoutId, comment: 'one');
      await repository.setWorkoutComment(workoutId: workoutId, comment: 'two');
      await (database.delete(
        database.pendingOperations,
      )..where((row) => row.seq.equals(1))).go();
      final snapshot = fixtureSnapshot(
        workoutId: workoutId,
        startedAt: startedAt,
        revision: 3,
      );
      when(() => api.getWorkout(workoutId)).thenAnswer(
        (_) async => ModifiedResponse(value: snapshot, etag: '"v3"'),
      );
      final engine = WorkoutSyncEngine(database: database, api: api);

      await engine.syncNow();

      final workout = await database.activeWorkout();
      expect(workout!.syncState, 'conflict');
      expect(workout.syncErrorCode, 'seq_mismatch');
      expect(workout.serverSnapshotJson, isNotNull);
      verify(() => api.getWorkout(workoutId)).called(1);
      verifyNever(() => api.applyOperations(any(), any()));

      await engine.dispose();
      await database.close();
    },
  );

  test('lost response retries identical op and accepts duplicate', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final api = _MockApi();
    final repository = WorkoutRepository(database: database);
    final startedAt = DateTime.utc(2026, 10, 10, 17);
    final workoutId = await repository.start(
      prescription: fixturePrescription,
      startedAt: startedAt,
    );
    await database.markStartAcknowledged(
      workoutId: workoutId,
      leaseEpoch: 1,
      appliedSeq: 0,
      revision: 1,
      snapshot: fixtureSnapshot(
        workoutId: workoutId,
        startedAt: startedAt,
      ).toJson(),
    );
    await repository.setWorkoutComment(
      workoutId: workoutId,
      comment: 'survives timeout',
    );
    final batches = <OperationBatch>[];
    var attempt = 0;
    when(() => api.applyOperations(workoutId, any())).thenAnswer((invocation) {
      final batch = invocation.positionalArguments[1] as OperationBatch;
      batches.add(batch);
      attempt++;
      if (attempt == 1) throw _transportFailure();
      return Future.value(
        OperationBatchResponse(
          appliedSeq: batch.ops.single.seq,
          revision: 2,
          results: [
            OperationResult(
              seq: batch.ops.single.seq,
              opId: batch.ops.single.opId,
              status: OperationResultStatus.duplicate,
            ),
          ],
          serverTime: DateTime.utc(2026, 10, 10, 17, 5),
        ),
      );
    });
    final engine = WorkoutSyncEngine(
      database: database,
      api: api,
      backoffForAttempt: (_) => const Duration(hours: 1),
    );

    await engine.syncNow();
    await database.markSyncIssue(
      workoutId: workoutId,
      state: 'offline',
      attempts: 1,
      nextAttemptAt: DateTime.utc(2000),
    );
    await engine.syncNow();

    expect(batches, hasLength(2));
    expect(batches[1].ops.single.opId, batches[0].ops.single.opId);
    expect(batches[1].ops.single.seq, batches[0].ops.single.seq);
    final operation = await database
        .select(database.pendingOperations)
        .getSingle();
    expect(operation.deliveryState, 'acknowledged');
    expect((await database.activeWorkout())!.syncState, 'saved');
    await engine.dispose();
    await database.close();
  });

  test('seq gap retires server-consumed prefix and continues', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final api = _MockApi();
    final repository = WorkoutRepository(database: database);
    final startedAt = DateTime.utc(2026, 10, 10, 17);
    final workoutId = await repository.start(
      prescription: fixturePrescription,
      startedAt: startedAt,
    );
    await database.markStartAcknowledged(
      workoutId: workoutId,
      leaseEpoch: 1,
      appliedSeq: 0,
      revision: 1,
      snapshot: fixtureSnapshot(
        workoutId: workoutId,
        startedAt: startedAt,
      ).toJson(),
    );
    await repository.setWorkoutComment(workoutId: workoutId, comment: 'one');
    await repository.setWorkoutComment(workoutId: workoutId, comment: 'two');
    var attempt = 0;
    when(() => api.applyOperations(workoutId, any())).thenAnswer((invocation) {
      attempt++;
      if (attempt == 1) {
        throw _requestFailure('seq_gap', details: const {'expected_seq': 2});
      }
      final batch = invocation.positionalArguments[1] as OperationBatch;
      return Future.value(fixtureOperationResponse(batch));
    });
    final engine = WorkoutSyncEngine(database: database, api: api);

    await engine.syncNow();

    final operations = await (database.select(
      database.pendingOperations,
    )..orderBy([(row) => OrderingTerm.asc(row.seq)])).get();
    expect(operations.first.errorCode, 'server_already_applied');
    expect(operations.last.deliveryState, 'acknowledged');
    expect((await database.activeWorkout())!.appliedSeq, 2);
    verify(() => api.applyOperations(workoutId, any())).called(2);
    await engine.dispose();
    await database.close();
  });

  for (final scenario in const [
    (status: OperationResultStatus.conflict, state: 'conflict'),
    (status: OperationResultStatus.rejected, state: 'recovery_required'),
  ]) {
    test(
      'consumed ${scenario.status.wireName} stops automatic replay',
      () async {
        final database = AppDatabase(NativeDatabase.memory());
        final api = _MockApi();
        final repository = WorkoutRepository(database: database);
        final startedAt = DateTime.utc(2026, 10, 10, 17);
        final workoutId = await repository.start(
          prescription: fixturePrescription,
          startedAt: startedAt,
        );
        await database.markStartAcknowledged(
          workoutId: workoutId,
          leaseEpoch: 1,
          appliedSeq: 0,
          revision: 1,
          snapshot: fixtureSnapshot(
            workoutId: workoutId,
            startedAt: startedAt,
          ).toJson(),
        );
        await repository.setWorkoutComment(
          workoutId: workoutId,
          comment: 'candidate',
        );
        when(() => api.applyOperations(workoutId, any())).thenAnswer((
          invocation,
        ) {
          final batch = invocation.positionalArguments[1] as OperationBatch;
          return Future.value(
            OperationBatchResponse(
              appliedSeq: batch.ops.single.seq,
              revision: 2,
              results: [
                OperationResult(
                  seq: batch.ops.single.seq,
                  opId: batch.ops.single.opId,
                  status: scenario.status,
                  entityRev: 4,
                ),
              ],
              serverTime: DateTime.utc(2026, 10, 10, 17, 5),
            ),
          );
        });
        final engine = WorkoutSyncEngine(database: database, api: api);

        await engine.syncNow();
        await engine.syncNow();

        expect((await database.activeWorkout())!.syncState, scenario.state);
        verify(() => api.applyOperations(workoutId, any())).called(1);
        await engine.dispose();
        await database.close();
      },
    );
  }

  test('superseded lease stops writes until explicit claim', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final api = _MockApi();
    final repository = WorkoutRepository(database: database);
    final startedAt = DateTime.utc(2026, 10, 10, 17);
    final workoutId = await repository.start(
      prescription: fixturePrescription,
      startedAt: startedAt,
    );
    await database.markStartAcknowledged(
      workoutId: workoutId,
      leaseEpoch: 1,
      appliedSeq: 0,
      revision: 1,
      snapshot: fixtureSnapshot(
        workoutId: workoutId,
        startedAt: startedAt,
      ).toJson(),
    );
    await repository.setWorkoutComment(workoutId: workoutId, comment: 'one');
    when(
      () => api.applyOperations(workoutId, any()),
    ).thenThrow(_requestFailure('superseded'));
    final engine = WorkoutSyncEngine(database: database, api: api);

    await engine.syncNow();
    await engine.syncNow();

    final workout = await database.activeWorkout();
    expect(workout!.syncState, 'superseded');
    expect(workout.syncErrorCode, 'superseded');
    verify(() => api.applyOperations(workoutId, any())).called(1);
    await engine.dispose();
    await database.close();
  });
}

AgonezApiException _transportFailure() => AgonezApiException(
  statusCode: null,
  error: null,
  responseData: null,
  cause: DioException(
    requestOptions: RequestOptions(path: '/api/v1/mobile/workouts'),
    type: DioExceptionType.connectionError,
    message: 'offline in test',
  ),
);

AgonezApiException _requestFailure(
  String code, {
  Map<String, Object?> details = const {},
}) => AgonezApiException(
  statusCode: 409,
  error: ApiErrorBody(code: code, message: code, details: details),
  responseData: null,
  cause: DioException(
    requestOptions: RequestOptions(path: '/api/v1/mobile/workouts/id/ops'),
    type: DioExceptionType.badResponse,
    message: code,
  ),
);
