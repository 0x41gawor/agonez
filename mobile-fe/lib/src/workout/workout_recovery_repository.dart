import 'dart:convert';

import 'package:drift/drift.dart';

import '../api/agonez_api_client.dart';
import '../api/conditional_response.dart';
import '../api/wire_enums.dart';
import '../api/workout_models.dart';
import '../storage/app_database.dart';
import 'workout_ids.dart';

/// Explicitly imports or claims a server workout without replaying commands
/// produced under an older device lease.
class WorkoutRecoveryRepository {
  WorkoutRecoveryRepository({
    required AppDatabase database,
    required AgonezApiClient api,
    required String deviceId,
    WorkoutIds ids = const WorkoutIds(),
  }) : _database = database,
       _api = api,
       _deviceId = deviceId,
       _ids = ids;

  final AppDatabase _database;
  final AgonezApiClient _api;
  final String _deviceId;
  final WorkoutIds _ids;

  Future<WorkoutSnapshot> claim(String workoutId) async {
    final response = await _api.getWorkout(workoutId);
    if (response is! ModifiedResponse<WorkoutSnapshot>) {
      throw const FormatException('Workout snapshot was not returned');
    }
    final observed = response.value;
    final claimed = observed.lease.isThisDevice
        ? observed
        : await _api.claimWorkout(
            workoutId,
            ClaimWorkout(
              deviceId: _deviceId,
              observedAppliedSeq: observed.appliedSeq,
            ),
          );
    await importSnapshot(claimed);
    return claimed;
  }

  Future<void> importSnapshot(WorkoutSnapshot snapshot) async {
    final prescriptionById = {
      for (final exercise in snapshot.prescription.exercises)
        exercise.exercisePrescriptionId: exercise,
    };
    final performances = [...snapshot.performance.exercises];
    final presentPrescriptionIds = performances
        .map((item) => item.exercisePrescriptionId)
        .whereType<int>()
        .toSet();

    for (final prescribed in snapshot.prescription.exercises) {
      if (presentPrescriptionIds.contains(prescribed.exercisePrescriptionId)) {
        continue;
      }
      performances.add(
        ExercisePerformance(
          exercisePerformanceId: _ids.prescribedExercisePerformanceId(
            snapshot.workoutId,
            prescribed.exercisePrescriptionId,
          ),
          exercisePrescriptionId: prescribed.exercisePrescriptionId,
          performedOrdinal: prescribed.ordinal,
          mode: ExercisePerformanceMode.asPrescribed,
          actualExercise: prescribed.exercise,
          comment: null,
          rev: 0,
          sets: const [],
        ),
      );
    }
    performances.sort(
      (left, right) => left.performedOrdinal.compareTo(right.performedOrdinal),
    );
    final cursorExercise = snapshot.positionHint == null
        ? 0
        : performances.indexWhere(
            (item) =>
                item.exercisePerformanceId ==
                snapshot.positionHint!.exercisePerformanceId,
          );
    final now = DateTime.now().toUtc();
    final start = StartWorkout(
      workoutId: snapshot.workoutId,
      sessionId: snapshot.sessionId,
      prescriptionVersion: snapshot.prescription.prescriptionVersion,
      startedAt: snapshot.startedAt,
    );

    await _database.transaction(() async {
      final existing =
          await (_database.select(_database.localWorkouts)
                ..where((row) => row.workoutId.equals(snapshot.workoutId)))
              .getSingleOrNull();
      if (existing == null) {
        final other = await _database.activeWorkout();
        if (other != null) {
          throw StateError('A different local workout is still active');
        }
        await _database
            .into(_database.localWorkouts)
            .insert(
              LocalWorkoutsCompanion.insert(
                workoutId: snapshot.workoutId,
                sessionId: snapshot.sessionId,
                workoutUnitName: snapshot.prescription.workoutUnitName,
                lifecycle: const Value('active'),
                startedAt: snapshot.startedAt,
                prescriptionJson: jsonEncode(snapshot.prescription.toJson()),
                startPayloadJson: jsonEncode(start.toJson()),
                serverSnapshotJson: Value(jsonEncode(snapshot.toJson())),
                leaseEpoch: Value(snapshot.lease.epoch),
                appliedSeq: Value(snapshot.appliedSeq),
                nextSeq: Value(snapshot.appliedSeq + 1),
                revision: Value(snapshot.revision),
                currentExercise: Value(cursorExercise < 0 ? 0 : cursorExercise),
                currentSet: Value(snapshot.positionHint?.setOrdinal ?? 0),
                cursorPhase: Value(
                  snapshot.positionHint?.phase.wireName ?? 'set',
                ),
                workoutComment: Value(snapshot.performance.comment),
                syncState: const Value('saved'),
                updatedAt: now,
              ),
            );
      } else {
        final sameLease = existing.leaseEpoch == snapshot.lease.epoch;
        final snapshotNextSeq = snapshot.appliedSeq + 1;
        final nextSeq = sameLease && existing.nextSeq > snapshotNextSeq
            ? existing.nextSeq
            : snapshotNextSeq;
        await (_database.update(
          _database.localWorkouts,
        )..where((row) => row.workoutId.equals(snapshot.workoutId))).write(
          LocalWorkoutsCompanion(
            lifecycle: const Value('active'),
            prescriptionJson: Value(jsonEncode(snapshot.prescription.toJson())),
            serverSnapshotJson: Value(jsonEncode(snapshot.toJson())),
            leaseEpoch: Value(snapshot.lease.epoch),
            appliedSeq: Value(snapshot.appliedSeq),
            nextSeq: Value(nextSeq),
            revision: Value(snapshot.revision),
            currentExercise: Value(cursorExercise < 0 ? 0 : cursorExercise),
            currentSet: Value(snapshot.positionHint?.setOrdinal ?? 0),
            cursorPhase: Value(snapshot.positionHint?.phase.wireName ?? 'set'),
            workoutComment: Value(snapshot.performance.comment),
            syncState: const Value('saved'),
            syncErrorCode: const Value(null),
            syncAttempts: const Value(0),
            nextSyncAt: const Value(null),
            updatedAt: Value(now),
          ),
        );
        await (_database.update(_database.pendingOperations)..where(
              (row) =>
                  row.workoutId.equals(snapshot.workoutId) &
                  row.leaseEpoch.isSmallerThanValue(snapshot.lease.epoch) &
                  row.deliveryState.isIn(['queued', 'in_flight']),
            ))
            .write(
              const PendingOperationsCompanion(
                deliveryState: Value('superseded_epoch'),
                errorCode: Value('lease_replaced'),
              ),
            );
        await (_database.update(_database.pendingOperations)..where(
              (row) =>
                  row.workoutId.equals(snapshot.workoutId) &
                  row.leaseEpoch.equals(snapshot.lease.epoch) &
                  row.seq.isSmallerOrEqualValue(snapshot.appliedSeq) &
                  row.deliveryState.isIn(['queued', 'in_flight']),
            ))
            .write(
              const PendingOperationsCompanion(
                deliveryState: Value('acknowledged'),
                errorCode: Value('server_already_applied'),
              ),
            );
        await (_database.delete(
          _database.localSets,
        )..where((row) => row.workoutId.equals(snapshot.workoutId))).go();
        await (_database.delete(
          _database.localExercises,
        )..where((row) => row.workoutId.equals(snapshot.workoutId))).go();
      }

      for (final performance in performances) {
        final prescribed = performance.exercisePrescriptionId == null
            ? null
            : prescriptionById[performance.exercisePrescriptionId];
        await _database
            .into(_database.localExercises)
            .insert(
              LocalExercisesCompanion.insert(
                exercisePerformanceId: performance.exercisePerformanceId,
                workoutId: snapshot.workoutId,
                exercisePrescriptionId: Value(
                  performance.exercisePrescriptionId,
                ),
                prescribedExerciseId: Value(prescribed?.exercise.id),
                actualExerciseId: Value(performance.actualExercise?.id),
                actualExerciseJson: Value(
                  performance.actualExercise == null
                      ? null
                      : jsonEncode(performance.actualExercise!.toJson()),
                ),
                performedOrdinal: performance.performedOrdinal,
                mode: Value(performance.mode.wireName),
                comment: Value(performance.comment),
                serverRev: Value(performance.rev),
                localRev: Value(performance.rev),
                updatedAt: now,
              ),
            );
        for (final set in performance.sets) {
          await _database
              .into(_database.localSets)
              .insert(
                LocalSetsCompanion.insert(
                  setPerformanceId: set.setPerformanceId,
                  workoutId: snapshot.workoutId,
                  exercisePerformanceId: performance.exercisePerformanceId,
                  exercisePrescriptionId: Value(
                    performance.exercisePrescriptionId,
                  ),
                  prescribedSetId: Value(set.prescribedSetId),
                  ordinal: set.ordinal,
                  status: set.status.wireName,
                  loadKg: Value(set.loadKg),
                  repetitions: Value(set.repetitions),
                  rir: Value(set.rir),
                  comment: Value(set.comment),
                  heartRateBpm: Value(set.heartRateBpm),
                  performedAt: Value(set.performedAt),
                  serverRev: Value(set.rev),
                  localRev: Value(set.rev),
                  updatedAt: now,
                ),
              );
        }
      }
    });
  }
}
