import 'dart:convert';

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
}
