import 'dart:convert';

import 'package:drift/drift.dart';

import '../api/atlas_models.dart';
import '../api/operation_models.dart';
import '../api/prescription_models.dart';
import '../api/wire_enums.dart';
import '../api/workout_models.dart';
import '../storage/app_database.dart';
import 'workout_ids.dart';

class WorkoutRepository {
  WorkoutRepository({
    required AppDatabase database,
    WorkoutIds ids = const WorkoutIds(),
    void Function()? requestSync,
  }) : _database = database,
       _ids = ids,
       _requestSync = requestSync;

  final AppDatabase _database;
  final WorkoutIds _ids;
  final void Function()? _requestSync;

  /// Starts locally and queues the start request, so a scheduled workout can
  /// begin offline.
  Future<String> start({
    required WorkoutPrescription prescription,
    int? planRunId,
    bool allowMissingLoads = false,
    OffSchedule? offSchedule,
    DateTime? startedAt,
  }) async {
    final payload = _startPayload(
      prescription: prescription,
      allowMissingLoads: allowMissingLoads,
      offSchedule: offSchedule,
      startedAt: startedAt,
    );
    await _createLocalWorkout(prescription, planRunId, payload);
    _requestSync?.call();
    return payload.workoutId;
  }

  /// Starts a workout only once the server has accepted it.
  ///
  /// Off-schedule starts depend on scheduling rules that only the server
  /// knows, and it may refuse them (`off_schedule_not_supported`). A queued
  /// local-first start would leave a workout on the phone that can never
  /// sync, so nothing is stored until the start is acknowledged; a refusal
  /// simply throws from [send].
  Future<String> startAfterServerAccepts({
    required WorkoutPrescription prescription,
    required Future<WorkoutSnapshot> Function(StartWorkout payload) send,
    int? planRunId,
    bool allowMissingLoads = false,
    OffSchedule? offSchedule,
    DateTime? startedAt,
  }) async {
    final payload = _startPayload(
      prescription: prescription,
      allowMissingLoads: allowMissingLoads,
      offSchedule: offSchedule,
      startedAt: startedAt,
    );
    final snapshot = await send(payload);
    await _createLocalWorkout(prescription, planRunId, payload);
    await _database.markStartAcknowledged(
      workoutId: payload.workoutId,
      leaseEpoch: snapshot.lease.epoch,
      appliedSeq: snapshot.appliedSeq,
      revision: snapshot.revision,
      snapshot: snapshot.toJson(),
    );
    _requestSync?.call();
    return payload.workoutId;
  }

  StartWorkout _startPayload({
    required WorkoutPrescription prescription,
    required bool allowMissingLoads,
    required OffSchedule? offSchedule,
    required DateTime? startedAt,
  }) => StartWorkout(
    workoutId: _ids.newWorkoutId(),
    sessionId: prescription.sessionId,
    prescriptionVersion: prescription.prescriptionVersion,
    startedAt: (startedAt ?? DateTime.now()).toUtc(),
    allowMissingLoads: allowMissingLoads,
    offSchedule: offSchedule,
  );

  Future<void> _createLocalWorkout(
    WorkoutPrescription prescription,
    int? planRunId,
    StartWorkout payload,
  ) {
    final workoutId = payload.workoutId;
    final started = payload.startedAt;
    return _database.createLocalWorkout(
      workout: LocalWorkoutsCompanion.insert(
        workoutId: workoutId,
        sessionId: prescription.sessionId,
        planRunId: Value(planRunId),
        workoutUnitName: prescription.workoutUnitName,
        startedAt: started,
        prescriptionJson: jsonEncode(prescription.toJson()),
        startPayloadJson: jsonEncode(payload.toJson()),
        updatedAt: started,
      ),
      exercises: prescription.exercises.map((exercise) {
        final performanceId = _ids.prescribedExercisePerformanceId(
          workoutId,
          exercise.exercisePrescriptionId,
        );
        return LocalExercisesCompanion.insert(
          exercisePerformanceId: performanceId,
          workoutId: workoutId,
          exercisePrescriptionId: Value(exercise.exercisePrescriptionId),
          prescribedExerciseId: Value(exercise.exercise.id),
          actualExerciseId: Value(exercise.exercise.id),
          actualExerciseJson: Value(jsonEncode(exercise.exercise.toJson())),
          performedOrdinal: exercise.ordinal,
          updatedAt: started,
        );
      }),
    );
  }

  Future<void> confirmSet({
    required String workoutId,
    required PrescriptionExercise exercise,
    required PrescriptionSet? prescribedSet,
    required int ordinal,
    required double? loadKg,
    required int repetitions,
    required int rir,
    String? setPerformanceId,
    String? comment,
    int? heartRateBpm,
    int? ifRev,
    required int nextExerciseIndex,
    required int nextSetIndex,
    DateTime? performedAt,
    int? restSeconds,
  }) async {
    final exercisePerformanceId = _ids.prescribedExercisePerformanceId(
      workoutId,
      exercise.exercisePrescriptionId,
    );
    final setId =
        setPerformanceId ??
        (prescribedSet == null
            ? _ids.newAdditionalEntityId()
            : _ids.prescribedSetPerformanceId(
                workoutId,
                prescribedSet.setPrescriptionId,
              ));
    final occurredAt = (performedAt ?? DateTime.now()).toUtc();
    final data = UpsertSetData(
      setPerformanceId: setId,
      exercisePerformanceId: exercisePerformanceId,
      exercisePrescriptionId: exercise.exercisePrescriptionId,
      prescribedSetId: prescribedSet?.setPrescriptionId,
      ordinal: ordinal,
      loadKg: loadKg,
      repetitions: repetitions,
      rir: rir,
      comment: comment,
      heartRateBpm: heartRateBpm,
      performedAt: occurredAt,
      ifRev: ifRev,
    );
    final duration = restSeconds ?? exercise.defaultRestS;
    await _database.recordSetAndEnqueue(
      workoutId: workoutId,
      set: LocalSetsCompanion.insert(
        setPerformanceId: setId,
        workoutId: workoutId,
        exercisePerformanceId: exercisePerformanceId,
        exercisePrescriptionId: Value(exercise.exercisePrescriptionId),
        prescribedSetId: Value(prescribedSet?.setPrescriptionId),
        ordinal: ordinal,
        status: 'performed',
        loadKg: Value(loadKg),
        repetitions: Value(repetitions),
        rir: Value(rir),
        comment: Value(comment),
        heartRateBpm: Value(heartRateBpm),
        performedAt: Value(occurredAt),
        localRev: Value((ifRev ?? 0) + 1),
        updatedAt: occurredAt,
      ),
      operationData: data.toJson(),
      restEndsAt: occurredAt.add(Duration(seconds: duration)),
      restDurationS: duration,
      nextExerciseIndex: nextExerciseIndex,
      nextSetIndex: nextSetIndex,
    );
    _requestSync?.call();
  }

  Future<void> skipSet({
    required String workoutId,
    required PrescriptionExercise exercise,
    required PrescriptionSet set,
    String? comment,
    int? ifRev,
    required int nextExerciseIndex,
    required int nextSetIndex,
  }) async {
    final exercisePerformanceId = _ids.prescribedExercisePerformanceId(
      workoutId,
      exercise.exercisePrescriptionId,
    );
    final setId = _ids.prescribedSetPerformanceId(
      workoutId,
      set.setPrescriptionId,
    );
    final now = DateTime.now().toUtc();
    final data = SkipSetData(
      setPerformanceId: setId,
      exercisePerformanceId: exercisePerformanceId,
      exercisePrescriptionId: exercise.exercisePrescriptionId,
      prescribedSetId: set.setPrescriptionId,
      ordinal: set.ordinal,
      comment: comment,
      ifRev: ifRev,
    );
    await _database.recordSetAndEnqueue(
      workoutId: workoutId,
      operationType: 'skip_set',
      set: LocalSetsCompanion.insert(
        setPerformanceId: setId,
        workoutId: workoutId,
        exercisePerformanceId: exercisePerformanceId,
        exercisePrescriptionId: Value(exercise.exercisePrescriptionId),
        prescribedSetId: Value(set.setPrescriptionId),
        ordinal: set.ordinal,
        status: 'skipped',
        comment: Value(comment),
        localRev: Value((ifRev ?? 0) + 1),
        updatedAt: now,
      ),
      operationData: data.toJson(),
      nextExerciseIndex: nextExerciseIndex,
      nextSetIndex: nextSetIndex,
    );
    _requestSync?.call();
  }

  Future<String> confirmUnplannedSet({
    required String workoutId,
    required String exercisePerformanceId,
    required int ordinal,
    required double? loadKg,
    required int repetitions,
    required int rir,
    String? setPerformanceId,
    String? comment,
    int? heartRateBpm,
    int? ifRev,
    int restSeconds = 90,
    DateTime? performedAt,
  }) async {
    final setId = setPerformanceId ?? _ids.newAdditionalEntityId();
    final occurredAt = (performedAt ?? DateTime.now()).toUtc();
    final data = UpsertSetData(
      setPerformanceId: setId,
      exercisePerformanceId: exercisePerformanceId,
      ordinal: ordinal,
      loadKg: loadKg,
      repetitions: repetitions,
      rir: rir,
      comment: comment,
      heartRateBpm: heartRateBpm,
      performedAt: occurredAt,
      ifRev: ifRev,
    );
    await _database.recordSetAndEnqueue(
      workoutId: workoutId,
      set: LocalSetsCompanion.insert(
        setPerformanceId: setId,
        workoutId: workoutId,
        exercisePerformanceId: exercisePerformanceId,
        ordinal: ordinal,
        status: 'performed',
        loadKg: Value(loadKg),
        repetitions: Value(repetitions),
        rir: Value(rir),
        comment: Value(comment),
        heartRateBpm: Value(heartRateBpm),
        performedAt: Value(occurredAt),
        localRev: Value((ifRev ?? 0) + 1),
        updatedAt: occurredAt,
      ),
      operationData: data.toJson(),
      restEndsAt: occurredAt.add(Duration(seconds: restSeconds)),
      restDurationS: restSeconds,
    );
    _requestSync?.call();
    return setId;
  }

  Future<void> clearSet({
    required String workoutId,
    required String setPerformanceId,
    int? ifRev,
  }) async {
    final data = ClearSetData(setPerformanceId: setPerformanceId, ifRev: ifRev);
    await _database.deleteSetAndEnqueue(
      workoutId: workoutId,
      setPerformanceId: setPerformanceId,
      operationData: data.toJson(),
    );
    _requestSync?.call();
  }

  Future<void> setExerciseComment({
    required String workoutId,
    required String exercisePerformanceId,
    int? exercisePrescriptionId,
    String? comment,
    int? ifRev,
  }) async {
    final data = SetExerciseCommentData(
      exercisePerformanceId: exercisePerformanceId,
      exercisePrescriptionId: exercisePrescriptionId,
      comment: comment,
      ifRev: ifRev,
    );
    await _database.updateExerciseAndEnqueue(
      workoutId: workoutId,
      exercisePerformanceId: exercisePerformanceId,
      updateValue: LocalExercisesCompanion(
        comment: Value(comment),
        localRev: Value((ifRev ?? 0) + 1),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
      operationType: 'set_exercise_comment',
      operationData: data.toJson(),
    );
    _requestSync?.call();
  }

  Future<void> skipExercise({
    required String workoutId,
    required String exercisePerformanceId,
    required int exercisePrescriptionId,
    String? comment,
    int? ifRev,
  }) async {
    final data = SkipExerciseData(
      exercisePerformanceId: exercisePerformanceId,
      exercisePrescriptionId: exercisePrescriptionId,
      comment: comment,
      ifRev: ifRev,
    );
    await _database.updateExerciseAndEnqueue(
      workoutId: workoutId,
      exercisePerformanceId: exercisePerformanceId,
      updateValue: LocalExercisesCompanion(
        mode: const Value('skipped'),
        comment: Value(comment),
        localRev: Value((ifRev ?? 0) + 1),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
      operationType: 'skip_exercise',
      operationData: data.toJson(),
    );
    _requestSync?.call();
  }

  Future<void> substituteExercise({
    required String workoutId,
    required String exercisePerformanceId,
    required int exercisePrescriptionId,
    required ExerciseIdentity actualExercise,
    required SubstitutionSource source,
    int? variantOrdinal,
    int? ifRev,
  }) async {
    final data = SubstituteExerciseData(
      exercisePerformanceId: exercisePerformanceId,
      exercisePrescriptionId: exercisePrescriptionId,
      actualExerciseId: actualExercise.id,
      source: source,
      variantOrdinal: variantOrdinal,
      ifRev: ifRev,
    );
    await _database.updateExerciseAndEnqueue(
      workoutId: workoutId,
      exercisePerformanceId: exercisePerformanceId,
      updateValue: LocalExercisesCompanion(
        mode: const Value('substituted'),
        actualExerciseId: Value(actualExercise.id),
        actualExerciseJson: Value(jsonEncode(actualExercise.toJson())),
        localRev: Value((ifRev ?? 0) + 1),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
      operationType: 'substitute_exercise',
      operationData: data.toJson(),
    );
    _requestSync?.call();
  }

  Future<String> addUnplannedExercise({
    required String workoutId,
    required ExerciseIdentity actualExercise,
    required int performedOrdinal,
  }) async {
    final exercisePerformanceId = _ids.newAdditionalEntityId();
    final now = DateTime.now().toUtc();
    final data = AddUnplannedExerciseData(
      exercisePerformanceId: exercisePerformanceId,
      actualExerciseId: actualExercise.id,
      performedOrdinal: performedOrdinal,
    );
    await _database.transaction(() async {
      await _database
          .into(_database.localExercises)
          .insert(
            LocalExercisesCompanion.insert(
              exercisePerformanceId: exercisePerformanceId,
              workoutId: workoutId,
              actualExerciseId: Value(actualExercise.id),
              actualExerciseJson: Value(jsonEncode(actualExercise.toJson())),
              performedOrdinal: performedOrdinal,
              mode: const Value('added'),
              updatedAt: now,
            ),
          );
      await _database.enqueueOperation(
        workoutId: workoutId,
        type: 'add_unplanned_exercise',
        data: data.toJson(),
        occurredAt: now,
      );
    });
    _requestSync?.call();
    return exercisePerformanceId;
  }

  Future<void> reorderExercises({
    required String workoutId,
    required List<String> order,
  }) async {
    await _database.transaction(() => _writeOrder(workoutId, order));
    _requestSync?.call();
  }

  /// Starts the exercise that [order] puts at [exerciseIndex], the cursor's
  /// slot, from its first set.
  ///
  /// One local commit, so the screen never pairs that exercise with the
  /// entry draft typed for the one it displaced.
  Future<void> startExerciseNow({
    required String workoutId,
    required List<String> order,
    required int exerciseIndex,
  }) async {
    await _database.transaction(() async {
      await _writeOrder(workoutId, order);
      await _writeCursor(
        workoutId: workoutId,
        exercisePerformanceId: order[exerciseIndex],
        exerciseIndex: exerciseIndex,
        setOrdinal: 0,
        phase: PositionPhase.set,
      );
    });
    _requestSync?.call();
  }

  Future<void> _writeOrder(String workoutId, List<String> order) async {
    final data = ReorderExercisesData(order: order);
    final exercises = _database.localExercises;
    for (var index = 0; index < order.length; index++) {
      // The server counts a reorder as one revision of every exercise in
      // it, so the next note, skip or substitution of any of them must
      // expect one more.
      await (_database.update(
        exercises,
      )..where((row) => row.exercisePerformanceId.equals(order[index]))).write(
        LocalExercisesCompanion.custom(
          performedOrdinal: Variable(index),
          localRev: exercises.localRev + const Constant(1),
          updatedAt: Variable(DateTime.now().toUtc()),
        ),
      );
    }
    await _database.enqueueOperation(
      workoutId: workoutId,
      type: 'reorder_exercises',
      data: data.toJson(),
    );
  }

  Future<void> setCursor({
    required String workoutId,
    required String exercisePerformanceId,
    required int exerciseIndex,
    required int setOrdinal,
    required PositionPhase phase,
    String? draftJson,
  }) async {
    await _database.transaction(
      () => _writeCursor(
        workoutId: workoutId,
        exercisePerformanceId: exercisePerformanceId,
        exerciseIndex: exerciseIndex,
        setOrdinal: setOrdinal,
        phase: phase,
        draftJson: draftJson,
      ),
    );
    _requestSync?.call();
  }

  Future<void> _writeCursor({
    required String workoutId,
    required String exercisePerformanceId,
    required int exerciseIndex,
    required int setOrdinal,
    required PositionPhase phase,
    String? draftJson,
  }) async {
    final data = SetCursorData(
      exercisePerformanceId: exercisePerformanceId,
      setOrdinal: setOrdinal,
      phase: phase,
    );
    await _database.setWorkoutCursor(
      workoutId: workoutId,
      exerciseIndex: exerciseIndex,
      setIndex: setOrdinal,
      phase: phase.wireName,
      draftJson: draftJson,
    );
    await _database.enqueueOperation(
      workoutId: workoutId,
      type: 'set_cursor',
      data: data.toJson(),
    );
  }

  Future<void> setWorkoutComment({
    required String workoutId,
    String? comment,
  }) async {
    final data = SetWorkoutCommentData(comment: comment);
    await _database.transaction(() async {
      await (_database.update(
        _database.localWorkouts,
      )..where((row) => row.workoutId.equals(workoutId))).write(
        LocalWorkoutsCompanion(
          workoutComment: Value(comment),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
      await _database.enqueueOperation(
        workoutId: workoutId,
        type: 'set_workout_comment',
        data: data.toJson(),
      );
    });
    _requestSync?.call();
  }

  Future<void> finish({
    required String workoutId,
    required bool acknowledgedIncomplete,
    DateTime? finishedAt,
  }) async {
    final workout = await (_database.select(
      _database.localWorkouts,
    )..where((row) => row.workoutId.equals(workoutId))).getSingle();
    final finished = (finishedAt ?? DateTime.now()).toUtc();
    final payload = FinalizeWorkout(
      leaseEpoch: workout.leaseEpoch,
      finalSeq: workout.nextSeq - 1,
      finishedAt: finished,
      acknowledgedIncomplete: acknowledgedIncomplete,
    );
    await _database.queueFinalize(
      workoutId: workoutId,
      payload: payload.toJson(),
      finishedAt: finished,
    );
    _requestSync?.call();
  }
}
