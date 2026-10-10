import 'atlas_models.dart';
import 'context_models.dart';
import 'json_support.dart';
import 'prescription_models.dart';
import 'wire_enums.dart';

class SetPerformance {
  const SetPerformance({
    required this.setPerformanceId,
    required this.prescribedSetId,
    required this.ordinal,
    required this.status,
    required this.loadKg,
    required this.repetitions,
    required this.rir,
    required this.comment,
    required this.heartRateBpm,
    required this.performedAt,
    required this.receivedAt,
    required this.rev,
  });

  factory SetPerformance.fromJson(JsonMap json) => SetPerformance(
    setPerformanceId: asString(
      requiredJson(json, 'set_performance_id'),
      'set_performance_id',
    ),
    prescribedSetId: asNullableInt(
      requiredJson(json, 'prescribed_set_id'),
      'prescribed_set_id',
    ),
    ordinal: asInt(requiredJson(json, 'ordinal'), 'ordinal'),
    status: decodePerformedSetStatus(requiredJson(json, 'status')),
    loadKg: asNullableDouble(requiredJson(json, 'load_kg'), 'load_kg'),
    repetitions: asNullableInt(
      requiredJson(json, 'repetitions'),
      'repetitions',
    ),
    rir: asNullableInt(requiredJson(json, 'rir'), 'rir'),
    comment: asNullableString(requiredJson(json, 'comment'), 'comment'),
    heartRateBpm: asNullableInt(
      requiredJson(json, 'heart_rate_bpm'),
      'heart_rate_bpm',
    ),
    performedAt: asNullableDateTime(
      requiredJson(json, 'performed_at'),
      'performed_at',
    ),
    receivedAt: asDateTime(requiredJson(json, 'received_at'), 'received_at'),
    rev: asInt(requiredJson(json, 'rev'), 'rev'),
  );

  final String setPerformanceId;
  final int? prescribedSetId;
  final int ordinal;
  final PerformedSetStatus status;
  final double? loadKg;
  final int? repetitions;
  final int? rir;
  final String? comment;
  final int? heartRateBpm;
  final DateTime? performedAt;
  final DateTime receivedAt;
  final int rev;

  JsonMap toJson() => <String, Object?>{
    'set_performance_id': setPerformanceId,
    'prescribed_set_id': prescribedSetId,
    'ordinal': ordinal,
    'status': status.wireName,
    'load_kg': loadKg,
    'repetitions': repetitions,
    'rir': rir,
    'comment': comment,
    'heart_rate_bpm': heartRateBpm,
    'performed_at': performedAt == null ? null : encodeDateTime(performedAt!),
    'received_at': encodeDateTime(receivedAt),
    'rev': rev,
  };
}

class ExercisePerformance {
  const ExercisePerformance({
    required this.exercisePerformanceId,
    required this.exercisePrescriptionId,
    required this.performedOrdinal,
    required this.mode,
    required this.actualExercise,
    required this.comment,
    required this.rev,
    required this.sets,
  });

  factory ExercisePerformance.fromJson(JsonMap json) => ExercisePerformance(
    exercisePerformanceId: asString(
      requiredJson(json, 'exercise_performance_id'),
      'exercise_performance_id',
    ),
    exercisePrescriptionId: asNullableInt(
      requiredJson(json, 'exercise_prescription_id'),
      'exercise_prescription_id',
    ),
    performedOrdinal: asInt(
      requiredJson(json, 'performed_ordinal'),
      'performed_ordinal',
    ),
    mode: decodeExercisePerformanceMode(requiredJson(json, 'mode')),
    actualExercise: requiredJson(json, 'actual_exercise') == null
        ? null
        : ExerciseIdentity.fromJson(
            asJsonMap(json['actual_exercise'], 'actual_exercise'),
          ),
    comment: asNullableString(requiredJson(json, 'comment'), 'comment'),
    rev: asInt(requiredJson(json, 'rev'), 'rev'),
    sets: decodeList(
      requiredJson(json, 'sets'),
      (value) => SetPerformance.fromJson(asJsonMap(value, 'sets[]')),
      'sets',
    ),
  );

  final String exercisePerformanceId;
  final int? exercisePrescriptionId;
  final int performedOrdinal;
  final ExercisePerformanceMode mode;
  final ExerciseIdentity? actualExercise;
  final String? comment;
  final int rev;
  final List<SetPerformance> sets;

  JsonMap toJson() => <String, Object?>{
    'exercise_performance_id': exercisePerformanceId,
    'exercise_prescription_id': exercisePrescriptionId,
    'performed_ordinal': performedOrdinal,
    'mode': mode.wireName,
    'actual_exercise': actualExercise?.toJson(),
    'comment': comment,
    'rev': rev,
    'sets': sets.map((item) => item.toJson()).toList(growable: false),
  };
}

class PerformanceTree {
  const PerformanceTree({required this.comment, required this.exercises});

  factory PerformanceTree.fromJson(JsonMap json) => PerformanceTree(
    comment: asNullableString(requiredJson(json, 'comment'), 'comment'),
    exercises: decodeList(
      requiredJson(json, 'exercises'),
      (value) => ExercisePerformance.fromJson(asJsonMap(value, 'exercises[]')),
      'exercises',
    ),
  );

  final String? comment;
  final List<ExercisePerformance> exercises;

  JsonMap toJson() => <String, Object?>{
    'comment': comment,
    'exercises': exercises.map((item) => item.toJson()).toList(growable: false),
  };
}

class WorkoutSnapshot {
  const WorkoutSnapshot({
    required this.workoutId,
    required this.sessionId,
    required this.status,
    required this.startedAt,
    required this.finishedAt,
    required this.lease,
    required this.appliedSeq,
    required this.revision,
    required this.positionHint,
    required this.prescription,
    required this.performance,
  });

  factory WorkoutSnapshot.fromJson(JsonMap json) => WorkoutSnapshot(
    workoutId: asString(requiredJson(json, 'workout_id'), 'workout_id'),
    sessionId: asInt(requiredJson(json, 'session_id'), 'session_id'),
    status: decodeWorkoutStatus(requiredJson(json, 'status')),
    startedAt: asDateTime(requiredJson(json, 'started_at'), 'started_at'),
    finishedAt: asNullableDateTime(
      requiredJson(json, 'finished_at'),
      'finished_at',
    ),
    lease: Lease.fromJson(asJsonMap(requiredJson(json, 'lease'), 'lease')),
    appliedSeq: asInt(requiredJson(json, 'applied_seq'), 'applied_seq'),
    revision: asInt(requiredJson(json, 'revision'), 'revision'),
    positionHint: requiredJson(json, 'position_hint') == null
        ? null
        : PositionHint.fromJson(
            asJsonMap(json['position_hint'], 'position_hint'),
          ),
    prescription: WorkoutPrescription.fromJson(
      asJsonMap(requiredJson(json, 'prescription'), 'prescription'),
    ),
    performance: PerformanceTree.fromJson(
      asJsonMap(requiredJson(json, 'performance'), 'performance'),
    ),
  );

  final String workoutId;
  final int sessionId;
  final WorkoutStatus status;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final Lease lease;
  final int appliedSeq;
  final int revision;
  final PositionHint? positionHint;
  final WorkoutPrescription prescription;
  final PerformanceTree performance;

  JsonMap toJson() => <String, Object?>{
    'workout_id': workoutId,
    'session_id': sessionId,
    'status': status.wireName,
    'started_at': encodeDateTime(startedAt),
    'finished_at': finishedAt == null ? null : encodeDateTime(finishedAt!),
    'lease': lease.toJson(),
    'applied_seq': appliedSeq,
    'revision': revision,
    'position_hint': positionHint?.toJson(),
    'prescription': prescription.toJson(),
    'performance': performance.toJson(),
  };
}

class OffSchedule {
  const OffSchedule({
    required this.acknowledged,
    required this.selectedFrom,
    this.expectedSessionId,
  });

  factory OffSchedule.fromJson(JsonMap json) => OffSchedule(
    acknowledged: asBool(requiredJson(json, 'acknowledged'), 'acknowledged'),
    selectedFrom: asString(
      requiredJson(json, 'selected_from'),
      'selected_from',
    ),
    expectedSessionId: asNullableInt(
      json['expected_session_id'],
      'expected_session_id',
    ),
  );

  final bool acknowledged;
  final String selectedFrom;
  final int? expectedSessionId;

  JsonMap toJson() => <String, Object?>{
    'acknowledged': acknowledged,
    'selected_from': selectedFrom,
    'expected_session_id': expectedSessionId,
  };
}

class StartWorkout {
  StartWorkout({
    required this.workoutId,
    required this.sessionId,
    required this.prescriptionVersion,
    required this.startedAt,
    this.allowMissingLoads = false,
    this.offSchedule,
  }) {
    if (sessionId < 1) {
      throw ArgumentError.value(sessionId, 'sessionId', 'must be positive');
    }
  }

  factory StartWorkout.fromJson(JsonMap json) => StartWorkout(
    workoutId: asString(requiredJson(json, 'workout_id'), 'workout_id'),
    sessionId: asInt(requiredJson(json, 'session_id'), 'session_id'),
    prescriptionVersion: asString(
      requiredJson(json, 'prescription_version'),
      'prescription_version',
    ),
    startedAt: asDateTime(requiredJson(json, 'started_at'), 'started_at'),
    allowMissingLoads: json.containsKey('allow_missing_loads')
        ? asBool(json['allow_missing_loads'], 'allow_missing_loads')
        : false,
    offSchedule: json['off_schedule'] == null
        ? null
        : OffSchedule.fromJson(asJsonMap(json['off_schedule'], 'off_schedule')),
  );

  final String workoutId;
  final int sessionId;
  final String prescriptionVersion;
  final DateTime startedAt;
  final bool allowMissingLoads;
  final OffSchedule? offSchedule;

  JsonMap toJson() => <String, Object?>{
    'workout_id': workoutId,
    'session_id': sessionId,
    'prescription_version': prescriptionVersion,
    'started_at': encodeDateTime(startedAt),
    'allow_missing_loads': allowMissingLoads,
    'off_schedule': offSchedule?.toJson(),
  };
}

class ClaimWorkout {
  ClaimWorkout({required this.deviceId, required this.observedAppliedSeq}) {
    if (observedAppliedSeq < 0) {
      throw ArgumentError.value(
        observedAppliedSeq,
        'observedAppliedSeq',
        'must not be negative',
      );
    }
  }

  factory ClaimWorkout.fromJson(JsonMap json) => ClaimWorkout(
    deviceId: asString(requiredJson(json, 'device_id'), 'device_id'),
    observedAppliedSeq: asInt(
      requiredJson(json, 'observed_applied_seq'),
      'observed_applied_seq',
    ),
  );

  final String deviceId;
  final int observedAppliedSeq;

  JsonMap toJson() => <String, Object?>{
    'device_id': deviceId,
    'observed_applied_seq': observedAppliedSeq,
  };
}

class FinalizeWorkout {
  FinalizeWorkout({
    required this.leaseEpoch,
    required this.finalSeq,
    required this.finishedAt,
    this.unrecorded = 'mark_not_performed',
    this.acknowledgedIncomplete = false,
  }) {
    if (leaseEpoch < 1) {
      throw ArgumentError.value(leaseEpoch, 'leaseEpoch', 'must be positive');
    }
    if (finalSeq < 0) {
      throw ArgumentError.value(finalSeq, 'finalSeq', 'must not be negative');
    }
    if (unrecorded != 'mark_not_performed') {
      throw ArgumentError.value(unrecorded, 'unrecorded');
    }
  }

  factory FinalizeWorkout.fromJson(JsonMap json) => FinalizeWorkout(
    leaseEpoch: asInt(requiredJson(json, 'lease_epoch'), 'lease_epoch'),
    finalSeq: asInt(requiredJson(json, 'final_seq'), 'final_seq'),
    finishedAt: asDateTime(requiredJson(json, 'finished_at'), 'finished_at'),
    unrecorded:
        asNullableString(json['unrecorded'], 'unrecorded') ??
        'mark_not_performed',
    acknowledgedIncomplete: json.containsKey('acknowledged_incomplete')
        ? asBool(json['acknowledged_incomplete'], 'acknowledged_incomplete')
        : false,
  );

  final int leaseEpoch;
  final int finalSeq;
  final DateTime finishedAt;
  final String unrecorded;
  final bool acknowledgedIncomplete;

  JsonMap toJson() => <String, Object?>{
    'lease_epoch': leaseEpoch,
    'final_seq': finalSeq,
    'finished_at': encodeDateTime(finishedAt),
    'unrecorded': unrecorded,
    'acknowledged_incomplete': acknowledgedIncomplete,
  };
}

class CompletionSummary {
  const CompletionSummary({
    required this.prescribedSets,
    required this.performedSets,
    required this.skippedSets,
    required this.notPerformedSets,
    required this.additionalSets,
    required this.substitutions,
    required this.skippedExercises,
    required this.addedExercises,
    required this.reordered,
  });

  factory CompletionSummary.fromJson(JsonMap json) => CompletionSummary(
    prescribedSets: asInt(
      requiredJson(json, 'prescribed_sets'),
      'prescribed_sets',
    ),
    performedSets: asInt(
      requiredJson(json, 'performed_sets'),
      'performed_sets',
    ),
    skippedSets: asInt(requiredJson(json, 'skipped_sets'), 'skipped_sets'),
    notPerformedSets: asInt(
      requiredJson(json, 'not_performed_sets'),
      'not_performed_sets',
    ),
    additionalSets: asInt(
      requiredJson(json, 'additional_sets'),
      'additional_sets',
    ),
    substitutions: asInt(requiredJson(json, 'substitutions'), 'substitutions'),
    skippedExercises: asInt(
      requiredJson(json, 'skipped_exercises'),
      'skipped_exercises',
    ),
    addedExercises: asInt(
      requiredJson(json, 'added_exercises'),
      'added_exercises',
    ),
    reordered: asBool(requiredJson(json, 'reordered'), 'reordered'),
  );

  final int prescribedSets;
  final int performedSets;
  final int skippedSets;
  final int notPerformedSets;
  final int additionalSets;
  final int substitutions;
  final int skippedExercises;
  final int addedExercises;
  final bool reordered;

  JsonMap toJson() => <String, Object?>{
    'prescribed_sets': prescribedSets,
    'performed_sets': performedSets,
    'skipped_sets': skippedSets,
    'not_performed_sets': notPerformedSets,
    'additional_sets': additionalSets,
    'substitutions': substitutions,
    'skipped_exercises': skippedExercises,
    'added_exercises': addedExercises,
    'reordered': reordered,
  };
}

class FinalizeResponse {
  const FinalizeResponse({
    required this.workoutId,
    required this.finishedAt,
    required this.summary,
    this.status = 'completed',
  });

  factory FinalizeResponse.fromJson(JsonMap json) => FinalizeResponse(
    workoutId: asString(requiredJson(json, 'workout_id'), 'workout_id'),
    status: asString(requiredJson(json, 'status'), 'status'),
    finishedAt: asDateTime(requiredJson(json, 'finished_at'), 'finished_at'),
    summary: CompletionSummary.fromJson(
      asJsonMap(requiredJson(json, 'summary'), 'summary'),
    ),
  );

  final String workoutId;
  final String status;
  final DateTime finishedAt;
  final CompletionSummary summary;

  JsonMap toJson() => <String, Object?>{
    'workout_id': workoutId,
    'status': status,
    'finished_at': encodeDateTime(finishedAt),
    'summary': summary.toJson(),
  };
}
