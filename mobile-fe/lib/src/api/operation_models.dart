import 'json_support.dart';
import 'wire_enums.dart';

abstract class OperationData {
  OperationData({this.ifRev}) {
    if (ifRev != null && ifRev! < 0) {
      throw ArgumentError.value(ifRev, 'ifRev', 'must not be negative');
    }
  }

  final int? ifRev;

  JsonMap toJson();

  JsonMap baseJson() => <String, Object?>{'if_rev': ifRev};
}

class UpsertSetData extends OperationData {
  UpsertSetData({
    required this.setPerformanceId,
    required this.exercisePerformanceId,
    required this.ordinal,
    required this.repetitions,
    required this.performedAt,
    this.exercisePrescriptionId,
    this.prescribedSetId,
    this.loadKg,
    this.rir,
    this.comment,
    this.heartRateBpm,
    super.ifRev,
  }) {
    _nonNegative(ordinal, 'ordinal');
    if (exercisePrescriptionId != null) {
      _positive(exercisePrescriptionId!, 'exercisePrescriptionId');
    }
    if (prescribedSetId != null) {
      _positive(prescribedSetId!, 'prescribedSetId');
    }
    if (loadKg != null) {
      if (loadKg! < 0 || loadKg! > 1000) {
        throw ArgumentError.value(loadKg, 'loadKg', 'must be inside 0..1000');
      }
      final scaled = loadKg! * 100;
      if ((scaled - scaled.round()).abs() > 0.0000001) {
        throw ArgumentError.value(
          loadKg,
          'loadKg',
          'supports at most 2 decimals',
        );
      }
    }
    if (repetitions < 0 || repetitions > 100) {
      throw ArgumentError.value(
        repetitions,
        'repetitions',
        'must be inside 0..100',
      );
    }
    if (rir != null && (rir! < 0 || rir! > 10)) {
      throw ArgumentError.value(rir, 'rir', 'must be inside 0..10');
    }
    if (heartRateBpm != null && (heartRateBpm! < 25 || heartRateBpm! > 250)) {
      throw ArgumentError.value(
        heartRateBpm,
        'heartRateBpm',
        'must be inside 25..250',
      );
    }
  }

  factory UpsertSetData.fromJson(JsonMap json) => UpsertSetData(
    ifRev: asNullableInt(json['if_rev'], 'if_rev'),
    setPerformanceId: asString(
      requiredJson(json, 'set_performance_id'),
      'set_performance_id',
    ),
    exercisePerformanceId: asString(
      requiredJson(json, 'exercise_performance_id'),
      'exercise_performance_id',
    ),
    exercisePrescriptionId: asNullableInt(
      json['exercise_prescription_id'],
      'exercise_prescription_id',
    ),
    prescribedSetId: asNullableInt(
      json['prescribed_set_id'],
      'prescribed_set_id',
    ),
    ordinal: asInt(requiredJson(json, 'ordinal'), 'ordinal'),
    loadKg: asNullableDouble(json['load_kg'], 'load_kg'),
    repetitions: asInt(requiredJson(json, 'repetitions'), 'repetitions'),
    rir: asNullableInt(json['rir'], 'rir'),
    comment: asNullableString(json['comment'], 'comment'),
    heartRateBpm: asNullableInt(json['heart_rate_bpm'], 'heart_rate_bpm'),
    performedAt: asDateTime(requiredJson(json, 'performed_at'), 'performed_at'),
  );

  final String setPerformanceId;
  final String exercisePerformanceId;
  final int? exercisePrescriptionId;
  final int? prescribedSetId;
  final int ordinal;
  final double? loadKg;
  final int repetitions;
  final int? rir;
  final String? comment;
  final int? heartRateBpm;
  final DateTime performedAt;

  @override
  JsonMap toJson() => baseJson()
    ..addAll(<String, Object?>{
      'set_performance_id': setPerformanceId,
      'exercise_performance_id': exercisePerformanceId,
      'exercise_prescription_id': exercisePrescriptionId,
      'prescribed_set_id': prescribedSetId,
      'ordinal': ordinal,
      'status': 'performed',
      'load_kg': loadKg,
      'repetitions': repetitions,
      'rir': rir,
      'comment': comment,
      'heart_rate_bpm': heartRateBpm,
      'performed_at': encodeDateTime(performedAt),
    });
}

class SkipSetData extends OperationData {
  SkipSetData({
    required this.setPerformanceId,
    required this.exercisePerformanceId,
    required this.prescribedSetId,
    required this.ordinal,
    this.exercisePrescriptionId,
    this.comment,
    super.ifRev,
  }) {
    _positive(prescribedSetId, 'prescribedSetId');
    _nonNegative(ordinal, 'ordinal');
    if (exercisePrescriptionId != null) {
      _positive(exercisePrescriptionId!, 'exercisePrescriptionId');
    }
  }

  factory SkipSetData.fromJson(JsonMap json) => SkipSetData(
    ifRev: asNullableInt(json['if_rev'], 'if_rev'),
    setPerformanceId: asString(
      requiredJson(json, 'set_performance_id'),
      'set_performance_id',
    ),
    exercisePerformanceId: asString(
      requiredJson(json, 'exercise_performance_id'),
      'exercise_performance_id',
    ),
    exercisePrescriptionId: asNullableInt(
      json['exercise_prescription_id'],
      'exercise_prescription_id',
    ),
    prescribedSetId: asInt(
      requiredJson(json, 'prescribed_set_id'),
      'prescribed_set_id',
    ),
    ordinal: asInt(requiredJson(json, 'ordinal'), 'ordinal'),
    comment: asNullableString(json['comment'], 'comment'),
  );

  final String setPerformanceId;
  final String exercisePerformanceId;
  final int? exercisePrescriptionId;
  final int prescribedSetId;
  final int ordinal;
  final String? comment;

  @override
  JsonMap toJson() => baseJson()
    ..addAll(<String, Object?>{
      'set_performance_id': setPerformanceId,
      'exercise_performance_id': exercisePerformanceId,
      'exercise_prescription_id': exercisePrescriptionId,
      'prescribed_set_id': prescribedSetId,
      'ordinal': ordinal,
      'comment': comment,
    });
}

class ClearSetData extends OperationData {
  ClearSetData({required this.setPerformanceId, super.ifRev});

  factory ClearSetData.fromJson(JsonMap json) => ClearSetData(
    ifRev: asNullableInt(json['if_rev'], 'if_rev'),
    setPerformanceId: asString(
      requiredJson(json, 'set_performance_id'),
      'set_performance_id',
    ),
  );

  final String setPerformanceId;

  @override
  JsonMap toJson() => baseJson()..['set_performance_id'] = setPerformanceId;
}

class SetExerciseCommentData extends OperationData {
  SetExerciseCommentData({
    required this.exercisePerformanceId,
    required this.comment,
    this.exercisePrescriptionId,
    super.ifRev,
  }) {
    if (exercisePrescriptionId != null) {
      _positive(exercisePrescriptionId!, 'exercisePrescriptionId');
    }
  }

  factory SetExerciseCommentData.fromJson(JsonMap json) =>
      SetExerciseCommentData(
        ifRev: asNullableInt(json['if_rev'], 'if_rev'),
        exercisePerformanceId: asString(
          requiredJson(json, 'exercise_performance_id'),
          'exercise_performance_id',
        ),
        exercisePrescriptionId: asNullableInt(
          json['exercise_prescription_id'],
          'exercise_prescription_id',
        ),
        comment: asNullableString(requiredJson(json, 'comment'), 'comment'),
      );

  final String exercisePerformanceId;
  final int? exercisePrescriptionId;
  final String? comment;

  @override
  JsonMap toJson() => baseJson()
    ..addAll(<String, Object?>{
      'exercise_performance_id': exercisePerformanceId,
      'exercise_prescription_id': exercisePrescriptionId,
      'comment': comment,
    });
}

class SkipExerciseData extends OperationData {
  SkipExerciseData({
    required this.exercisePerformanceId,
    required this.exercisePrescriptionId,
    this.comment,
    super.ifRev,
  }) {
    _positive(exercisePrescriptionId, 'exercisePrescriptionId');
  }

  factory SkipExerciseData.fromJson(JsonMap json) => SkipExerciseData(
    ifRev: asNullableInt(json['if_rev'], 'if_rev'),
    exercisePerformanceId: asString(
      requiredJson(json, 'exercise_performance_id'),
      'exercise_performance_id',
    ),
    exercisePrescriptionId: asInt(
      requiredJson(json, 'exercise_prescription_id'),
      'exercise_prescription_id',
    ),
    comment: asNullableString(json['comment'], 'comment'),
  );

  final String exercisePerformanceId;
  final int exercisePrescriptionId;
  final String? comment;

  @override
  JsonMap toJson() => baseJson()
    ..addAll(<String, Object?>{
      'exercise_performance_id': exercisePerformanceId,
      'exercise_prescription_id': exercisePrescriptionId,
      'comment': comment,
    });
}

class SubstituteExerciseData extends OperationData {
  SubstituteExerciseData({
    required this.exercisePerformanceId,
    required this.exercisePrescriptionId,
    required this.actualExerciseId,
    required this.source,
    this.variantOrdinal,
    super.ifRev,
  }) {
    _positive(exercisePrescriptionId, 'exercisePrescriptionId');
    _positive(actualExerciseId, 'actualExerciseId');
    if (variantOrdinal != null) {
      _nonNegative(variantOrdinal!, 'variantOrdinal');
    }
  }

  factory SubstituteExerciseData.fromJson(JsonMap json) =>
      SubstituteExerciseData(
        ifRev: asNullableInt(json['if_rev'], 'if_rev'),
        exercisePerformanceId: asString(
          requiredJson(json, 'exercise_performance_id'),
          'exercise_performance_id',
        ),
        exercisePrescriptionId: asInt(
          requiredJson(json, 'exercise_prescription_id'),
          'exercise_prescription_id',
        ),
        actualExerciseId: asInt(
          requiredJson(json, 'actual_exercise_id'),
          'actual_exercise_id',
        ),
        source: decodeSubstitutionSource(requiredJson(json, 'source')),
        variantOrdinal: asNullableInt(
          json['variant_ordinal'],
          'variant_ordinal',
        ),
      );

  final String exercisePerformanceId;
  final int exercisePrescriptionId;
  final int actualExerciseId;
  final SubstitutionSource source;
  final int? variantOrdinal;

  @override
  JsonMap toJson() => baseJson()
    ..addAll(<String, Object?>{
      'exercise_performance_id': exercisePerformanceId,
      'exercise_prescription_id': exercisePrescriptionId,
      'actual_exercise_id': actualExerciseId,
      'source': source.wireName,
      'variant_ordinal': variantOrdinal,
    });
}

class AddUnplannedExerciseData extends OperationData {
  AddUnplannedExerciseData({
    required this.exercisePerformanceId,
    required this.actualExerciseId,
    required this.performedOrdinal,
    super.ifRev,
  }) {
    _positive(actualExerciseId, 'actualExerciseId');
    _nonNegative(performedOrdinal, 'performedOrdinal');
  }

  factory AddUnplannedExerciseData.fromJson(JsonMap json) =>
      AddUnplannedExerciseData(
        ifRev: asNullableInt(json['if_rev'], 'if_rev'),
        exercisePerformanceId: asString(
          requiredJson(json, 'exercise_performance_id'),
          'exercise_performance_id',
        ),
        actualExerciseId: asInt(
          requiredJson(json, 'actual_exercise_id'),
          'actual_exercise_id',
        ),
        performedOrdinal: asInt(
          requiredJson(json, 'performed_ordinal'),
          'performed_ordinal',
        ),
      );

  final String exercisePerformanceId;
  final int actualExerciseId;
  final int performedOrdinal;

  @override
  JsonMap toJson() => baseJson()
    ..addAll(<String, Object?>{
      'exercise_performance_id': exercisePerformanceId,
      'actual_exercise_id': actualExerciseId,
      'performed_ordinal': performedOrdinal,
    });
}

class ReorderExercisesData extends OperationData {
  ReorderExercisesData({required List<String> order, super.ifRev})
    : order = List.unmodifiable(order) {
    if (order.isEmpty) {
      throw ArgumentError.value(order, 'order', 'must not be empty');
    }
    if (order.toSet().length != order.length) {
      throw ArgumentError.value(order, 'order', 'must not contain duplicates');
    }
  }

  factory ReorderExercisesData.fromJson(JsonMap json) => ReorderExercisesData(
    ifRev: asNullableInt(json['if_rev'], 'if_rev'),
    order: decodeList(
      requiredJson(json, 'order'),
      (value) => asString(value, 'order[]'),
      'order',
    ),
  );

  final List<String> order;

  @override
  JsonMap toJson() => baseJson()..['order'] = order;
}

class SetCursorData extends OperationData {
  SetCursorData({
    required this.exercisePerformanceId,
    required this.setOrdinal,
    this.phase = PositionPhase.set,
    super.ifRev,
  }) {
    _nonNegative(setOrdinal, 'setOrdinal');
  }

  factory SetCursorData.fromJson(JsonMap json) => SetCursorData(
    ifRev: asNullableInt(json['if_rev'], 'if_rev'),
    exercisePerformanceId: asString(
      requiredJson(json, 'exercise_performance_id'),
      'exercise_performance_id',
    ),
    setOrdinal: asInt(requiredJson(json, 'set_ordinal'), 'set_ordinal'),
    phase: json.containsKey('phase')
        ? decodePositionPhase(json['phase'])
        : PositionPhase.set,
  );

  final String exercisePerformanceId;
  final int setOrdinal;
  final PositionPhase phase;

  @override
  JsonMap toJson() => baseJson()
    ..addAll(<String, Object?>{
      'exercise_performance_id': exercisePerformanceId,
      'set_ordinal': setOrdinal,
      'phase': phase.wireName,
    });
}

class SetWorkoutCommentData extends OperationData {
  SetWorkoutCommentData({required this.comment, super.ifRev});

  factory SetWorkoutCommentData.fromJson(JsonMap json) => SetWorkoutCommentData(
    ifRev: asNullableInt(json['if_rev'], 'if_rev'),
    comment: asNullableString(requiredJson(json, 'comment'), 'comment'),
  );

  final String? comment;

  @override
  JsonMap toJson() => baseJson()..['comment'] = comment;
}

sealed class WorkoutOperation {
  WorkoutOperation({required this.opId, required this.seq, required this.at}) {
    _positive(seq, 'seq');
  }

  factory WorkoutOperation.fromJson(JsonMap json) {
    final opId = asString(requiredJson(json, 'op_id'), 'op_id');
    final seq = asInt(requiredJson(json, 'seq'), 'seq');
    final at = asDateTime(requiredJson(json, 'at'), 'at');
    final data = asJsonMap(requiredJson(json, 'data'), 'data');
    return switch (asString(requiredJson(json, 'type'), 'type')) {
      'upsert_set' => UpsertSetOperation(
        opId: opId,
        seq: seq,
        at: at,
        data: UpsertSetData.fromJson(data),
      ),
      'skip_set' => SkipSetOperation(
        opId: opId,
        seq: seq,
        at: at,
        data: SkipSetData.fromJson(data),
      ),
      'clear_set' => ClearSetOperation(
        opId: opId,
        seq: seq,
        at: at,
        data: ClearSetData.fromJson(data),
      ),
      'set_exercise_comment' => SetExerciseCommentOperation(
        opId: opId,
        seq: seq,
        at: at,
        data: SetExerciseCommentData.fromJson(data),
      ),
      'skip_exercise' => SkipExerciseOperation(
        opId: opId,
        seq: seq,
        at: at,
        data: SkipExerciseData.fromJson(data),
      ),
      'substitute_exercise' => SubstituteExerciseOperation(
        opId: opId,
        seq: seq,
        at: at,
        data: SubstituteExerciseData.fromJson(data),
      ),
      'add_unplanned_exercise' => AddUnplannedExerciseOperation(
        opId: opId,
        seq: seq,
        at: at,
        data: AddUnplannedExerciseData.fromJson(data),
      ),
      'reorder_exercises' => ReorderExercisesOperation(
        opId: opId,
        seq: seq,
        at: at,
        data: ReorderExercisesData.fromJson(data),
      ),
      'set_cursor' => SetCursorOperation(
        opId: opId,
        seq: seq,
        at: at,
        data: SetCursorData.fromJson(data),
      ),
      'set_workout_comment' => SetWorkoutCommentOperation(
        opId: opId,
        seq: seq,
        at: at,
        data: SetWorkoutCommentData.fromJson(data),
      ),
      final type => throw FormatException('Unknown workout operation "$type"'),
    };
  }

  final String opId;
  final int seq;
  final DateTime at;

  String get type;
  OperationData get data;

  JsonMap toJson() => <String, Object?>{
    'op_id': opId,
    'seq': seq,
    'at': encodeDateTime(at),
    'type': type,
    'data': data.toJson(),
  };
}

final class UpsertSetOperation extends WorkoutOperation {
  UpsertSetOperation({
    required super.opId,
    required super.seq,
    required super.at,
    required this.data,
  });
  @override
  final UpsertSetData data;
  @override
  String get type => 'upsert_set';
}

final class SkipSetOperation extends WorkoutOperation {
  SkipSetOperation({
    required super.opId,
    required super.seq,
    required super.at,
    required this.data,
  });
  @override
  final SkipSetData data;
  @override
  String get type => 'skip_set';
}

final class ClearSetOperation extends WorkoutOperation {
  ClearSetOperation({
    required super.opId,
    required super.seq,
    required super.at,
    required this.data,
  });
  @override
  final ClearSetData data;
  @override
  String get type => 'clear_set';
}

final class SetExerciseCommentOperation extends WorkoutOperation {
  SetExerciseCommentOperation({
    required super.opId,
    required super.seq,
    required super.at,
    required this.data,
  });
  @override
  final SetExerciseCommentData data;
  @override
  String get type => 'set_exercise_comment';
}

final class SkipExerciseOperation extends WorkoutOperation {
  SkipExerciseOperation({
    required super.opId,
    required super.seq,
    required super.at,
    required this.data,
  });
  @override
  final SkipExerciseData data;
  @override
  String get type => 'skip_exercise';
}

final class SubstituteExerciseOperation extends WorkoutOperation {
  SubstituteExerciseOperation({
    required super.opId,
    required super.seq,
    required super.at,
    required this.data,
  });
  @override
  final SubstituteExerciseData data;
  @override
  String get type => 'substitute_exercise';
}

final class AddUnplannedExerciseOperation extends WorkoutOperation {
  AddUnplannedExerciseOperation({
    required super.opId,
    required super.seq,
    required super.at,
    required this.data,
  });
  @override
  final AddUnplannedExerciseData data;
  @override
  String get type => 'add_unplanned_exercise';
}

final class ReorderExercisesOperation extends WorkoutOperation {
  ReorderExercisesOperation({
    required super.opId,
    required super.seq,
    required super.at,
    required this.data,
  });
  @override
  final ReorderExercisesData data;
  @override
  String get type => 'reorder_exercises';
}

final class SetCursorOperation extends WorkoutOperation {
  SetCursorOperation({
    required super.opId,
    required super.seq,
    required super.at,
    required this.data,
  });
  @override
  final SetCursorData data;
  @override
  String get type => 'set_cursor';
}

final class SetWorkoutCommentOperation extends WorkoutOperation {
  SetWorkoutCommentOperation({
    required super.opId,
    required super.seq,
    required super.at,
    required this.data,
  });
  @override
  final SetWorkoutCommentData data;
  @override
  String get type => 'set_workout_comment';
}

class OperationBatch {
  OperationBatch({
    required this.leaseEpoch,
    required this.baseSeq,
    required List<WorkoutOperation> ops,
  }) : ops = List.unmodifiable(ops) {
    _positive(leaseEpoch, 'leaseEpoch');
    _nonNegative(baseSeq, 'baseSeq');
    if (ops.isEmpty || ops.length > 200) {
      throw ArgumentError.value(
        ops.length,
        'ops.length',
        'must be inside 1..200',
      );
    }
    for (var index = 0; index < ops.length; index++) {
      final expected = baseSeq + index + 1;
      if (ops[index].seq != expected) {
        throw ArgumentError(
          'ops must be contiguous from baseSeq + 1; expected $expected, '
          'got ${ops[index].seq}',
        );
      }
    }
  }

  factory OperationBatch.fromJson(JsonMap json) => OperationBatch(
    leaseEpoch: asInt(requiredJson(json, 'lease_epoch'), 'lease_epoch'),
    baseSeq: asInt(requiredJson(json, 'base_seq'), 'base_seq'),
    ops: decodeList(
      requiredJson(json, 'ops'),
      (value) => WorkoutOperation.fromJson(asJsonMap(value, 'ops[]')),
      'ops',
    ),
  );

  final int leaseEpoch;
  final int baseSeq;
  final List<WorkoutOperation> ops;

  JsonMap toJson() => <String, Object?>{
    'lease_epoch': leaseEpoch,
    'base_seq': baseSeq,
    'ops': ops.map((item) => item.toJson()).toList(growable: false),
  };
}

class OperationError {
  const OperationError({required this.code, required this.message});

  factory OperationError.fromJson(JsonMap json) => OperationError(
    code: asString(requiredJson(json, 'code'), 'code'),
    message: asString(requiredJson(json, 'message'), 'message'),
  );

  final String code;
  final String message;

  JsonMap toJson() => <String, Object?>{'code': code, 'message': message};
}

class OperationResult {
  const OperationResult({
    required this.seq,
    required this.opId,
    required this.status,
    this.entityRev,
    this.serverState,
    this.error,
  });

  factory OperationResult.fromJson(JsonMap json) => OperationResult(
    seq: asInt(requiredJson(json, 'seq'), 'seq'),
    opId: asString(requiredJson(json, 'op_id'), 'op_id'),
    status: decodeOperationResultStatus(requiredJson(json, 'status')),
    entityRev: asNullableInt(json['entity_rev'], 'entity_rev'),
    serverState: json['server_state'] == null
        ? null
        : asJsonMap(json['server_state'], 'server_state'),
    error: json['error'] == null
        ? null
        : OperationError.fromJson(asJsonMap(json['error'], 'error')),
  );

  final int seq;
  final String opId;
  final OperationResultStatus status;
  final int? entityRev;
  final JsonMap? serverState;
  final OperationError? error;

  bool get isAcknowledged => switch (status) {
    OperationResultStatus.applied || OperationResultStatus.duplicate => true,
    OperationResultStatus.conflict || OperationResultStatus.rejected => false,
  };

  bool get isConsumed => true;

  JsonMap toJson() => <String, Object?>{
    'seq': seq,
    'op_id': opId,
    'status': status.wireName,
    'entity_rev': entityRev,
    'server_state': serverState,
    'error': error?.toJson(),
  };
}

class OperationBatchResponse {
  const OperationBatchResponse({
    required this.appliedSeq,
    required this.revision,
    required this.results,
    required this.serverTime,
    this.unsupportedFields = const <String>[],
  });

  factory OperationBatchResponse.fromJson(JsonMap json) =>
      OperationBatchResponse(
        appliedSeq: asInt(requiredJson(json, 'applied_seq'), 'applied_seq'),
        revision: asInt(requiredJson(json, 'revision'), 'revision'),
        results: decodeList(
          requiredJson(json, 'results'),
          (value) => OperationResult.fromJson(asJsonMap(value, 'results[]')),
          'results',
        ),
        unsupportedFields: json.containsKey('unsupported_fields')
            ? decodeList(
                json['unsupported_fields'],
                (value) => asString(value, 'unsupported_fields[]'),
                'unsupported_fields',
              )
            : const <String>[],
        serverTime: asDateTime(
          requiredJson(json, 'server_time'),
          'server_time',
        ),
      );

  final int appliedSeq;
  final int revision;
  final List<OperationResult> results;
  final List<String> unsupportedFields;
  final DateTime serverTime;

  JsonMap toJson() => <String, Object?>{
    'applied_seq': appliedSeq,
    'revision': revision,
    'results': results.map((item) => item.toJson()).toList(growable: false),
    'unsupported_fields': unsupportedFields,
    'server_time': encodeDateTime(serverTime),
  };
}

void _positive(int value, String name) {
  if (value < 1) {
    throw ArgumentError.value(value, name, 'must be positive');
  }
}

void _nonNegative(int value, String name) {
  if (value < 0) {
    throw ArgumentError.value(value, name, 'must not be negative');
  }
}
