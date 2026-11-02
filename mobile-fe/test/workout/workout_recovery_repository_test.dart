import 'dart:convert';

import 'package:agonez/src/api/agonez_api_client.dart';
import 'package:agonez/src/api/conditional_response.dart';
import 'package:agonez/src/api/context_models.dart';
import 'package:agonez/src/api/prescription_models.dart';
import 'package:agonez/src/api/workout_models.dart';
import 'package:agonez/src/storage/app_database.dart';
import 'package:agonez/src/workout/workout_recovery_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/workout_fixtures.dart';

class _MockApi extends Mock implements AgonezApiClient {}

class _FakeClaimWorkout extends Fake implements ClaimWorkout {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeClaimWorkout());
  });

  test(
    'same-device recovery imports snapshot without claiming again',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final api = _MockApi();
      const workoutId = '3d594650-3436-4fd4-9e14-60f7c27e17b8';
      final snapshot = fixtureSnapshot(
        workoutId: workoutId,
        startedAt: DateTime.utc(2026, 10, 10, 17),
      );
      when(() => api.getWorkout(workoutId)).thenAnswer(
        (_) async => ModifiedResponse(value: snapshot, etag: '"v1"'),
      );
      final repository = WorkoutRecoveryRepository(
        database: database,
        api: api,
        deviceId: 'test-device',
      );

      final recovered = await repository.claim(workoutId);

      expect(recovered, same(snapshot));
      expect((await database.activeWorkout())!.workoutId, workoutId);
      verifyNever(() => api.claimWorkout(any(), any()));
      await database.close();
    },
  );

  test('an imported workout has its setup notes as they stand now', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = WorkoutRecoveryRepository(
      database: database,
      api: _MockApi(),
      deviceId: 'test-device',
    );
    // The frozen prescription has none; the athlete wrote one since.
    final snapshot = fixtureSnapshot(
      workoutId: '3d594650-3436-4fd4-9e14-60f7c27e17b8',
      startedAt: DateTime.utc(2026, 11, 2, 17),
      setupNotes: [
        SlotSetupNote(
          exerciseTrackId: 10,
          note: SetupNote(
            exerciseId: 18,
            text: 'Seat 3',
            rev: 2,
            updatedAt: DateTime.utc(2026, 11, 2, 18),
          ),
        ),
      ],
    );

    await repository.importSnapshot(snapshot);

    final stored = WorkoutPrescription.fromJson(
      jsonDecode((await database.activeWorkout())!.prescriptionJson)
          as Map<String, Object?>,
    );
    expect(stored.exercises.single.setupNotes.single.text, 'Seat 3');
    expect(stored.exercises.single.setupNotes.single.rev, 2);
  });

  test('other-device recovery explicitly claims before importing', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final api = _MockApi();
    const workoutId = '3d594650-3436-4fd4-9e14-60f7c27e17b8';
    final startedAt = DateTime.utc(2026, 10, 10, 17);
    final observed = fixtureSnapshot(
      workoutId: workoutId,
      startedAt: startedAt,
      lease: const Lease(
        deviceId: 'other-device',
        epoch: 1,
        isThisDevice: false,
      ),
    );
    final claimed = fixtureSnapshot(
      workoutId: workoutId,
      startedAt: startedAt,
      lease: const Lease(deviceId: 'test-device', epoch: 2, isThisDevice: true),
    );
    when(
      () => api.getWorkout(workoutId),
    ).thenAnswer((_) async => ModifiedResponse(value: observed, etag: '"v1"'));
    when(
      () => api.claimWorkout(workoutId, any()),
    ).thenAnswer((_) async => claimed);
    final repository = WorkoutRecoveryRepository(
      database: database,
      api: api,
      deviceId: 'test-device',
    );

    final recovered = await repository.claim(workoutId);

    expect(recovered.lease.epoch, 2);
    expect((await database.activeWorkout())!.leaseEpoch, 2);
    verify(() => api.claimWorkout(workoutId, any())).called(1);
    await database.close();
  });
}
