import 'dart:convert';

import 'package:agonez/src/api/wire_enums.dart';
import 'package:agonez/src/api/workout_models.dart';
import 'package:agonez/src/storage/app_database.dart';
import 'package:agonez/src/workout/workout_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/workout_fixtures.dart';

void main() {
  late AppDatabase database;
  late int syncRequests;
  late WorkoutRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    syncRequests = 0;
    repository = WorkoutRepository(
      database: database,
      requestSync: () => syncRequests++,
    );
  });

  tearDown(() => database.close());

  test('start is committed locally before sync is requested', () async {
    final startedAt = DateTime.utc(2026, 10, 10, 17);
    String? visibleWorkoutIdDuringKick;
    repository = WorkoutRepository(
      database: database,
      requestSync: () async {
        visibleWorkoutIdDuringKick =
            (await database.activeWorkout())?.workoutId;
        syncRequests++;
      },
    );

    final workoutId = await repository.start(
      prescription: fixturePrescription,
      planRunId: 7,
      allowMissingLoads: true,
      startedAt: startedAt,
    );
    await Future<void>.delayed(Duration.zero);

    final workout = await database.activeWorkout();
    final exercises = await database.workoutExercises(workoutId);
    final payload = StartWorkout.fromJson(
      jsonDecode(workout!.startPayloadJson) as Map<String, Object?>,
    );

    expect(visibleWorkoutIdDuringKick, workoutId);
    expect(syncRequests, 1);
    expect(workout.lifecycle, 'pending_start');
    expect(workout.syncState, 'saving');
    expect(workout.planRunId, 7);
    expect(payload.workoutId, workoutId);
    expect(payload.prescriptionVersion, 'prescription-v1');
    expect(payload.allowMissingLoads, isTrue);
    expect(exercises, hasLength(1));
    expect(exercises.single.exercisePrescriptionId, 222);
    expect(exercises.single.actualExerciseId, fixtureExercise.id);
  });

  test('set confirmation and finish remain usable without a server', () async {
    final performedAt = DateTime.utc(2026, 10, 10, 17, 2);
    final finishedAt = DateTime.utc(2026, 10, 10, 17, 40);
    final workoutId = await repository.start(
      prescription: fixturePrescription,
      startedAt: performedAt.subtract(const Duration(minutes: 2)),
    );

    await repository.confirmSet(
      workoutId: workoutId,
      exercise: fixturePrescriptionExercise,
      prescribedSet: fixtureSet,
      ordinal: 0,
      loadKg: 82.5,
      repetitions: 7,
      rir: 1,
      heartRateBpm: 148,
      nextExerciseIndex: 0,
      nextSetIndex: 1,
      performedAt: performedAt,
    );
    final afterSet = await database.activeWorkout();
    await repository.finish(
      workoutId: workoutId,
      acknowledgedIncomplete: true,
      finishedAt: finishedAt,
    );

    final workout = await database.activeWorkout();
    final sets = await database.workoutSets(workoutId);
    final operations = await database.deliverableOperations(workoutId);
    final finalize = FinalizeWorkout.fromJson(
      jsonDecode(workout!.finalizePayloadJson!) as Map<String, Object?>,
    );

    expect(syncRequests, 3);
    expect(workout.lifecycle, 'pending_finalize');
    expect(workout.currentSet, 1);
    expect(
      afterSet!.restEndsAt!.toUtc(),
      performedAt.add(const Duration(minutes: 3)),
    );
    expect(workout.restEndsAt, isNull);
    expect(sets.single.loadKg, 82.5);
    expect(sets.single.repetitions, 7);
    expect(sets.single.rir, 1);
    expect(sets.single.heartRateBpm, 148);
    expect(operations.single.type, 'upsert_set');
    expect(operations.single.seq, 1);
    expect(finalize.finalSeq, 1);
    expect(finalize.finishedAt, finishedAt);
    expect(finalize.acknowledgedIncomplete, isTrue);
  });

  test('starting an exercise now swaps it in and starts it fresh', () async {
    final workoutId = await repository.start(
      prescription: twoExercisePrescription,
      startedAt: DateTime.utc(2026, 10, 26, 17),
    );
    final planned = await database.workoutExercises(workoutId);
    final squat = planned
        .firstWhere((exercise) => exercise.exercisePrescriptionId == 222)
        .exercisePerformanceId;
    final legCurl = planned
        .firstWhere((exercise) => exercise.exercisePrescriptionId == 223)
        .exercisePerformanceId;
    // A load already dialled in for the squat.
    await repository.setCursor(
      workoutId: workoutId,
      exercisePerformanceId: squat,
      exerciseIndex: 0,
      setOrdinal: 0,
      phase: PositionPhase.set,
      draftJson: '{"load_kg":80}',
    );
    final requestsBefore = syncRequests;

    await repository.startExerciseNow(
      workoutId: workoutId,
      order: [legCurl, squat],
      exerciseIndex: 0,
    );

    final workout = await database.activeWorkout();
    final exercises = await database.workoutExercises(workoutId);
    final operations = await database.deliverableOperations(workoutId);
    final ordinals = {
      for (final exercise in exercises)
        exercise.exercisePerformanceId: exercise.performedOrdinal,
    };
    expect(ordinals, {legCurl: 0, squat: 1});
    expect(workout!.currentExercise, 0);
    expect(workout.currentSet, 0);
    expect(workout.cursorPhase, 'set');
    expect(workout.entryDraftJson, isNull);
    expect(operations.map((operation) => operation.type).toList(), [
      'set_cursor',
      'reorder_exercises',
      'set_cursor',
    ]);
    expect((jsonDecode(operations[1].dataJson) as Map)['order'], [
      legCurl,
      squat,
    ]);
    expect(
      (jsonDecode(operations.last.dataJson) as Map)['exercise_performance_id'],
      legCurl,
    );
    expect(syncRequests, requestsBefore + 1);
  });

  test('each reorder counts as a revision of every exercise', () async {
    // The server bumps every exercise's rev when it applies a reorder; a
    // note sent afterwards must expect that rev or it comes back a conflict.
    final workoutId = await repository.start(
      prescription: twoExercisePrescription,
      startedAt: DateTime.utc(2026, 10, 26, 17),
    );
    final ids = [
      for (final exercise in await database.workoutExercises(workoutId))
        exercise.exercisePerformanceId,
    ];

    await repository.reorderExercises(
      workoutId: workoutId,
      order: ids.reversed.toList(),
    );
    await repository.startExerciseNow(
      workoutId: workoutId,
      order: ids,
      exerciseIndex: 0,
    );

    final exercises = await database.workoutExercises(workoutId);
    expect(exercises.map((exercise) => exercise.localRev), [2, 2]);
  });

  test('a server-first start stores nothing when the server refuses', () async {
    final sent = <StartWorkout>[];

    await expectLater(
      repository.startAfterServerAccepts(
        prescription: fixturePrescription,
        offSchedule: const OffSchedule(
          acknowledged: true,
          selectedFrom: 'picker',
          expectedSessionId: 40,
        ),
        send: (payload) async {
          sent.add(payload);
          throw StateError('off_schedule_not_supported');
        },
      ),
      throwsStateError,
    );

    expect(sent.single.offSchedule?.selectedFrom, 'picker');
    expect(sent.single.offSchedule?.expectedSessionId, 40);
    expect(await database.activeWorkout(), isNull);
    expect(syncRequests, 0);
  });

  test('a server-first start is stored already acknowledged', () async {
    final startedAt = DateTime.utc(2026, 10, 24, 18);

    final workoutId = await repository.startAfterServerAccepts(
      prescription: fixturePrescription,
      planRunId: 1,
      startedAt: startedAt,
      offSchedule: const OffSchedule(
        acknowledged: true,
        selectedFrom: 'picker',
      ),
      send: (payload) async => fixtureSnapshot(
        workoutId: payload.workoutId,
        startedAt: payload.startedAt,
      ),
    );

    final workout = await database.activeWorkout();
    expect(workout!.workoutId, workoutId);
    expect(workout.planRunId, 1);
    expect(workout.lifecycle, 'active');
    // A stored snapshot tells the sync engine not to send the start again.
    expect(workout.serverSnapshotJson, isNotNull);
    expect(workout.leaseEpoch, 1);
    final payload = StartWorkout.fromJson(
      jsonDecode(workout.startPayloadJson) as Map<String, Object?>,
    );
    expect(payload.offSchedule?.acknowledged, isTrue);
    expect(await database.workoutExercises(workoutId), isNotEmpty);
    expect(syncRequests, 1);
  });
}
