import 'dart:convert';
import 'dart:io';

import 'package:agonez/src/storage/app_database.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:uuid/uuid.dart';

void main() {
  late Directory tempDirectory;
  late File databaseFile;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('agonez-db-test-');
    databaseFile = File('${tempDirectory.path}/agonez.sqlite');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test(
    'repairs an empty version-one database without clearing app data',
    () async {
      final legacy = sqlite.sqlite3.open(databaseFile.path);
      legacy.execute('PRAGMA user_version = 1');
      legacy.dispose();

      final database = AppDatabase(NativeDatabase(databaseFile));
      await database.writeSetting('locale', 'pl');

      expect(await database.readSetting('locale'), 'pl');
      expect(await database.installationId(), isNotEmpty);
      await database.close();
    },
  );

  test(
    'migrates prototype tables and preserves durable workout data',
    () async {
      const workoutId = '3d594650-3436-4fd4-9e14-60f7c27e17b8';
      const legacyDeviceId = '4957826c-249b-4559-9a67-73e16972edde';
      const uuid = Uuid();
      final exercisePerformanceId = uuid.v5(workoutId, 'ex:201');
      final setPerformanceId = uuid.v5(workoutId, 'set:301');
      final prescription = jsonEncode(<String, Object?>{
        'session_id': 28,
        'prescription_version': 'legacy-v1',
        'exercises': <Object?>[
          <String, Object?>{
            'exercise_prescription_id': 201,
            'ordinal': 0,
            'exercise': <String, Object?>{'id': 18},
            'sets': <Object?>[
              <String, Object?>{'set_prescription_id': 301, 'ordinal': 0},
            ],
          },
        ],
      });
      final performance = jsonEncode(<String, Object?>{
        'sets': <String, Object?>{
          setPerformanceId: <String, Object?>{
            'status': 'performed',
            'load_kg': 42.5,
            'repetitions': 9,
            'rir': 1,
          },
        },
      });

      final legacy = sqlite.sqlite3.open(databaseFile.path);
      legacy.execute('''
      CREATE TABLE settings (
        key TEXT NOT NULL PRIMARY KEY,
        value TEXT NOT NULL
      );
      CREATE TABLE local_workouts (
        id TEXT NOT NULL PRIMARY KEY,
        session_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        prescription_json TEXT NOT NULL,
        performance_json TEXT NOT NULL DEFAULT '{}',
        started_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending_start',
        lease_epoch INTEGER NOT NULL DEFAULT 1,
        applied_seq INTEGER NOT NULL DEFAULT 0,
        next_seq INTEGER NOT NULL DEFAULT 1,
        exercise_index INTEGER NOT NULL DEFAULT 0,
        set_index INTEGER NOT NULL DEFAULT 0,
        rest_ends_at TEXT NULL,
        finalize_json TEXT NULL
      );
      CREATE TABLE pending_ops (
        op_id TEXT NOT NULL PRIMARY KEY,
        workout_id TEXT NOT NULL REFERENCES local_workouts (id),
        epoch INTEGER NOT NULL,
        seq INTEGER NOT NULL,
        type TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        at TEXT NOT NULL,
        state TEXT NOT NULL DEFAULT 'pending',
        error_code TEXT NULL,
        UNIQUE (workout_id, epoch, seq)
      );
      CREATE TABLE atlas_workspaces (
        slug TEXT NOT NULL PRIMARY KEY,
        title TEXT NOT NULL,
        exercise_id INTEGER NOT NULL,
        position INTEGER NOT NULL,
        scroll_offset REAL NOT NULL DEFAULT 0.0
      );
      PRAGMA user_version = 1;
    ''');
      legacy.execute(
        'INSERT INTO settings (key, value) VALUES (?, ?)',
        <Object?>['device_id', legacyDeviceId],
      );
      legacy.execute(
        'INSERT INTO local_workouts '
        '(id, session_id, name, prescription_json, performance_json, '
        'started_at, status, lease_epoch, applied_seq, next_seq, '
        'exercise_index, set_index, rest_ends_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          workoutId,
          28,
          'Legs',
          prescription,
          performance,
          '2026-10-10T17:00:00Z',
          'active',
          2,
          0,
          2,
          0,
          1,
          '2026-10-10T17:03:00Z',
        ],
      );
      legacy.execute(
        'INSERT INTO pending_ops '
        '(op_id, workout_id, epoch, seq, type, payload_json, at, state) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          'e205ee8c-6a0b-43ea-8f6e-c7b2bb1845ae',
          workoutId,
          2,
          1,
          'set_workout_comment',
          '{"comment":"legacy"}',
          '2026-10-10T17:01:00Z',
          'pending',
        ],
      );
      legacy.execute(
        'INSERT INTO atlas_workspaces '
        '(slug, title, exercise_id, position, scroll_offset) '
        'VALUES (?, ?, ?, ?, ?)',
        <Object?>['leg_press', 'Leg Press', 18, 0, 42.0],
      );
      legacy.dispose();

      final database = AppDatabase(NativeDatabase(databaseFile));
      expect(await database.installationId(), legacyDeviceId);
      final workout = await database.activeWorkout();
      final exercises = await database.workoutExercises(workoutId);
      final sets = await database.workoutSets(workoutId);
      final operations = await database.deliverableOperations(workoutId);
      final workspaces = await database.select(database.atlasWorkspaces).get();
      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();

      expect(version.data['user_version'], 3);
      expect(workout, isNotNull);
      expect(workout!.workoutId, workoutId);
      expect(workout.leaseEpoch, 2);
      expect(workout.currentSet, 1);
      expect(exercises.single.exercisePerformanceId, exercisePerformanceId);
      expect(sets.single.setPerformanceId, setPerformanceId);
      expect(sets.single.loadKg, 42.5);
      expect(operations.single.seq, 1);
      expect(operations.single.dataJson, '{"comment":"legacy"}');
      expect(workspaces.single.slug, 'leg_press');
      expect(workspaces.single.scrollOffset, 42);
      await database.close();
    },
  );

  test('installation identity is stable across database reopen', () async {
    var database = AppDatabase(NativeDatabase(databaseFile));
    final first = await database.installationId();
    await database.close();

    database = AppDatabase(NativeDatabase(databaseFile));
    final second = await database.installationId();
    await database.close();

    expect(second, first);
    expect(first[14], '4');
  });

  test('confirmed set and its sequence survive reconstruction', () async {
    const workoutId = '3d594650-3436-4fd4-9e14-60f7c27e17b8';
    const exerciseId = 'b22469d3-d9f0-53bf-81f7-7278d0d94d10';
    const setId = 'b520567e-88d9-57de-a425-c568b80028fb';
    final now = DateTime.utc(2026, 10, 10, 17);
    var database = AppDatabase(NativeDatabase(databaseFile));

    await database.createLocalWorkout(
      workout: LocalWorkoutsCompanion.insert(
        workoutId: workoutId,
        sessionId: 28,
        workoutUnitName: 'Legs',
        startedAt: now,
        prescriptionJson: '{"session_id":28}',
        startPayloadJson: '{"workout_id":"$workoutId"}',
        updatedAt: now,
      ),
      exercises: [
        LocalExercisesCompanion.insert(
          exercisePerformanceId: exerciseId,
          workoutId: workoutId,
          exercisePrescriptionId: const Value(222),
          prescribedExerciseId: const Value(18),
          performedOrdinal: 0,
          updatedAt: now,
        ),
      ],
    );

    await database.recordSetAndEnqueue(
      workoutId: workoutId,
      set: LocalSetsCompanion.insert(
        setPerformanceId: setId,
        workoutId: workoutId,
        exercisePerformanceId: exerciseId,
        exercisePrescriptionId: const Value(222),
        prescribedSetId: const Value(477),
        ordinal: 0,
        status: 'performed',
        loadKg: const Value(34.5),
        repetitions: const Value(8),
        rir: const Value(1),
        performedAt: Value(now),
        updatedAt: now,
      ),
      operationData: const {
        'set_performance_id': setId,
        'exercise_performance_id': exerciseId,
        'exercise_prescription_id': 222,
        'prescribed_set_id': 477,
        'ordinal': 0,
        'status': 'performed',
        'load_kg': 34.5,
        'repetitions': 8,
        'rir': 1,
        'performed_at': '2026-10-10T17:00:00.000Z',
      },
      restEndsAt: now.add(const Duration(minutes: 3)),
      restDurationS: 180,
      nextSetIndex: 1,
    );
    await database.close();

    database = AppDatabase(NativeDatabase(databaseFile));
    final workout = await database.activeWorkout();
    final sets = await database.select(database.localSets).get();
    final operations = await database.deliverableOperations(workoutId);
    await database.close();

    expect(workout, isNotNull);
    expect(workout!.nextSeq, 2);
    expect(workout.currentSet, 1);
    expect(workout.restEndsAt!.toUtc(), now.add(const Duration(minutes: 3)));
    expect(sets.single.loadKg, 34.5);
    expect(operations.single.seq, 1);
    expect(operations.single.type, 'upsert_set');
  });

  test('sequence allocation stays contiguous across actions', () async {
    final database = AppDatabase(NativeDatabase.memory());
    const workoutId = '3d594650-3436-4fd4-9e14-60f7c27e17b8';
    final now = DateTime.utc(2026, 10, 10);
    await database.createLocalWorkout(
      workout: LocalWorkoutsCompanion.insert(
        workoutId: workoutId,
        sessionId: 28,
        workoutUnitName: 'Legs',
        startedAt: now,
        prescriptionJson: '{}',
        startPayloadJson: '{}',
        updatedAt: now,
      ),
      exercises: const [],
    );

    await database.enqueueOperation(
      workoutId: workoutId,
      type: 'set_workout_comment',
      data: const {'comment': 'first'},
    );
    await database.enqueueOperation(
      workoutId: workoutId,
      type: 'set_workout_comment',
      data: const {'comment': 'second'},
    );

    final operations = await database.deliverableOperations(workoutId);
    final workout = await database.activeWorkout();
    await database.close();
    expect(operations.map((operation) => operation.seq), [1, 2]);
    expect(workout!.nextSeq, 3);
  });

  test(
    'sequence recovery retires commands already consumed by server',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      const workoutId = '3d594650-3436-4fd4-9e14-60f7c27e17b8';
      final now = DateTime.utc(2026, 10, 10);
      await database.createLocalWorkout(
        workout: LocalWorkoutsCompanion.insert(
          workoutId: workoutId,
          sessionId: 28,
          workoutUnitName: 'Legs',
          startedAt: now,
          prescriptionJson: '{}',
          startPayloadJson: '{}',
          updatedAt: now,
        ),
        exercises: const [],
      );
      await database.enqueueOperation(
        workoutId: workoutId,
        type: 'set_workout_comment',
        data: const {'comment': 'already stored'},
      );
      await database.enqueueOperation(
        workoutId: workoutId,
        type: 'set_workout_comment',
        data: const {'comment': 'still pending'},
      );

      await database.reconcileExpectedSequence(
        workoutId: workoutId,
        expectedSeq: 2,
      );

      final operations = await (database.select(
        database.pendingOperations,
      )..orderBy([(row) => OrderingTerm.asc(row.seq)])).get();
      final workout = await database.activeWorkout();
      expect(operations.first.deliveryState, 'acknowledged');
      expect(operations.first.errorCode, 'server_already_applied');
      expect(operations.last.deliveryState, 'queued');
      expect(workout!.appliedSeq, 1);
      expect(await database.pendingOperationCount(workoutId), 1);
      expect((await database.deliverableOperations(workoutId)).single.seq, 2);
      await database.close();
    },
  );

  test('acknowledgement is lease-scoped and ignores retired epochs', () async {
    final database = AppDatabase(NativeDatabase.memory());
    const workoutId = '3d594650-3436-4fd4-9e14-60f7c27e17b8';
    final now = DateTime.utc(2026, 10, 10);
    await database.createLocalWorkout(
      workout: LocalWorkoutsCompanion.insert(
        workoutId: workoutId,
        sessionId: 28,
        workoutUnitName: 'Legs',
        startedAt: now,
        prescriptionJson: '{}',
        startPayloadJson: '{}',
        updatedAt: now,
      ),
      exercises: const [],
    );
    await database.enqueueOperation(
      workoutId: workoutId,
      type: 'set_workout_comment',
      data: const {'comment': 'old lease'},
    );
    await (database.update(
      database.localWorkouts,
    )..where((row) => row.workoutId.equals(workoutId))).write(
      const LocalWorkoutsCompanion(leaseEpoch: Value(2), nextSeq: Value(1)),
    );
    await database.enqueueOperation(
      workoutId: workoutId,
      type: 'set_workout_comment',
      data: const {'comment': 'current lease'},
    );

    await database.acknowledgeOperations(
      workoutId: workoutId,
      leaseEpoch: 2,
      appliedSeq: 1,
      revision: 4,
      resultsBySeq: const {
        1: {'status': 'applied'},
      },
    );

    final operations = await (database.select(
      database.pendingOperations,
    )..orderBy([(row) => OrderingTerm.asc(row.leaseEpoch)])).get();
    final workout = await database.activeWorkout();
    expect(operations.first.leaseEpoch, 1);
    expect(operations.first.deliveryState, 'queued');
    expect(operations.last.leaseEpoch, 2);
    expect(operations.last.deliveryState, 'acknowledged');
    expect(await database.pendingOperationCount(workoutId), 0);
    expect(workout!.syncState, 'saved');
    await database.close();
  });

  test('consumed conflicts stop sync without remaining pending work', () async {
    final database = AppDatabase(NativeDatabase.memory());
    const workoutId = '3d594650-3436-4fd4-9e14-60f7c27e17b8';
    final now = DateTime.utc(2026, 10, 10);
    await database.createLocalWorkout(
      workout: LocalWorkoutsCompanion.insert(
        workoutId: workoutId,
        sessionId: 28,
        workoutUnitName: 'Legs',
        startedAt: now,
        prescriptionJson: '{}',
        startPayloadJson: '{}',
        updatedAt: now,
      ),
      exercises: const [],
    );
    await database.enqueueOperation(
      workoutId: workoutId,
      type: 'set_workout_comment',
      data: const {'comment': 'conflicting edit'},
    );

    await database.acknowledgeOperations(
      workoutId: workoutId,
      leaseEpoch: 1,
      appliedSeq: 1,
      revision: 2,
      resultsBySeq: const {
        1: {
          'status': 'conflict',
          'entity_rev': 7,
          'error': {'code': 'revision_conflict', 'message': 'stale'},
        },
      },
    );

    final operation = await database
        .select(database.pendingOperations)
        .getSingle();
    final workout = await database.activeWorkout();
    expect(operation.deliveryState, 'conflict');
    expect(await database.pendingOperationCount(workoutId), 0);
    expect(workout!.syncState, 'conflict');
    expect(workout.syncErrorCode, 'revision_conflict');

    expect(await database.retryLatestConflict(workoutId), isTrue);
    final retried = await (database.select(
      database.pendingOperations,
    )..orderBy([(row) => OrderingTerm.asc(row.seq)])).get();
    final retryData = jsonDecode(retried.last.dataJson) as Map<String, dynamic>;
    expect(retried.first.deliveryState, 'resolved_keep_phone');
    expect(retried.last.seq, 2);
    expect(retryData['if_rev'], 7);
    expect((await database.activeWorkout())!.syncState, 'saving');
    await database.close();
  });

  test('consumed rejection requires recovery rather than retrying', () async {
    final database = AppDatabase(NativeDatabase.memory());
    const workoutId = '3d594650-3436-4fd4-9e14-60f7c27e17b8';
    final now = DateTime.utc(2026, 10, 10);
    await database.createLocalWorkout(
      workout: LocalWorkoutsCompanion.insert(
        workoutId: workoutId,
        sessionId: 28,
        workoutUnitName: 'Legs',
        startedAt: now,
        prescriptionJson: '{}',
        startPayloadJson: '{}',
        updatedAt: now,
      ),
      exercises: const [],
    );
    await database.enqueueOperation(
      workoutId: workoutId,
      type: 'set_workout_comment',
      data: const {'comment': 'invalid edit'},
    );

    await database.acknowledgeOperations(
      workoutId: workoutId,
      leaseEpoch: 1,
      appliedSeq: 1,
      revision: 2,
      resultsBySeq: const {
        1: {
          'status': 'rejected',
          'error': {'code': 'invalid_comment', 'message': 'invalid'},
        },
      },
    );

    final workout = await database.activeWorkout();
    expect(await database.pendingOperationCount(workoutId), 0);
    expect(workout!.syncState, 'recovery_required');
    expect(workout.syncErrorCode, 'invalid_comment');
    await database.close();
  });
}
