import 'json_support.dart';

enum PrescriptionReadinessStatus { ready, missing, notApplicable }

enum PrescriptionMicrocycleClassification { normal, deload, reload }

enum SessionRelation { earlierMissed, laterInMicrocycle }

enum PerformedSetStatus { performed, skipped, notPerformed }

enum PositionPhase { set, exerciseComplete }

enum WorkoutStatus { inProgress, completed }

enum ExercisePerformanceMode {
  asPrescribed,
  substituted,
  skipped,
  notPerformed,
  added,
}

enum OperationResultStatus { applied, duplicate, conflict, rejected }

enum SubstitutionSource { planVariant, atlas }

extension PrescriptionReadinessStatusWire on PrescriptionReadinessStatus {
  String get wireName => switch (this) {
    PrescriptionReadinessStatus.ready => 'ready',
    PrescriptionReadinessStatus.missing => 'missing',
    PrescriptionReadinessStatus.notApplicable => 'not_applicable',
  };
}

PrescriptionReadinessStatus decodePrescriptionReadiness(Object? value) =>
    switch (asString(value, 'readiness')) {
      'ready' => PrescriptionReadinessStatus.ready,
      'missing' => PrescriptionReadinessStatus.missing,
      'not_applicable' => PrescriptionReadinessStatus.notApplicable,
      final value => throw FormatException(
        'Unknown prescription readiness "$value"',
      ),
    };

extension PrescriptionMicrocycleClassificationWire
    on PrescriptionMicrocycleClassification {
  String get wireName => name;
}

PrescriptionMicrocycleClassification decodeMicrocycleClassification(
  Object? value,
) => switch (asString(value, 'classification')) {
  'normal' => PrescriptionMicrocycleClassification.normal,
  'deload' => PrescriptionMicrocycleClassification.deload,
  'reload' => PrescriptionMicrocycleClassification.reload,
  final value => throw FormatException(
    'Unknown microcycle classification "$value"',
  ),
};

extension SessionRelationWire on SessionRelation {
  String get wireName => switch (this) {
    SessionRelation.earlierMissed => 'earlier_missed',
    SessionRelation.laterInMicrocycle => 'later_in_microcycle',
  };
}

SessionRelation decodeSessionRelation(Object? value) =>
    switch (asString(value, 'relation')) {
      'earlier_missed' => SessionRelation.earlierMissed,
      'later_in_microcycle' => SessionRelation.laterInMicrocycle,
      final value => throw FormatException('Unknown session relation "$value"'),
    };

extension PerformedSetStatusWire on PerformedSetStatus {
  String get wireName => switch (this) {
    PerformedSetStatus.performed => 'performed',
    PerformedSetStatus.skipped => 'skipped',
    PerformedSetStatus.notPerformed => 'not_performed',
  };
}

PerformedSetStatus decodePerformedSetStatus(Object? value) => switch (asString(
  value,
  'status',
)) {
  'performed' => PerformedSetStatus.performed,
  'skipped' => PerformedSetStatus.skipped,
  'not_performed' => PerformedSetStatus.notPerformed,
  final value => throw FormatException('Unknown performed-set status "$value"'),
};

extension PositionPhaseWire on PositionPhase {
  String get wireName => switch (this) {
    PositionPhase.set => 'set',
    PositionPhase.exerciseComplete => 'exercise_complete',
  };
}

PositionPhase decodePositionPhase(Object? value) =>
    switch (asString(value, 'phase')) {
      'set' => PositionPhase.set,
      'exercise_complete' => PositionPhase.exerciseComplete,
      final value => throw FormatException('Unknown position phase "$value"'),
    };

extension WorkoutStatusWire on WorkoutStatus {
  String get wireName => switch (this) {
    WorkoutStatus.inProgress => 'in_progress',
    WorkoutStatus.completed => 'completed',
  };
}

WorkoutStatus decodeWorkoutStatus(Object? value) =>
    switch (asString(value, 'status')) {
      'in_progress' => WorkoutStatus.inProgress,
      'completed' => WorkoutStatus.completed,
      final value => throw FormatException('Unknown workout status "$value"'),
    };

extension ExercisePerformanceModeWire on ExercisePerformanceMode {
  String get wireName => switch (this) {
    ExercisePerformanceMode.asPrescribed => 'as_prescribed',
    ExercisePerformanceMode.substituted => 'substituted',
    ExercisePerformanceMode.skipped => 'skipped',
    ExercisePerformanceMode.notPerformed => 'not_performed',
    ExercisePerformanceMode.added => 'added',
  };
}

ExercisePerformanceMode decodeExercisePerformanceMode(Object? value) =>
    switch (asString(value, 'mode')) {
      'as_prescribed' => ExercisePerformanceMode.asPrescribed,
      'substituted' => ExercisePerformanceMode.substituted,
      'skipped' => ExercisePerformanceMode.skipped,
      'not_performed' => ExercisePerformanceMode.notPerformed,
      'added' => ExercisePerformanceMode.added,
      final value => throw FormatException('Unknown exercise mode "$value"'),
    };

extension OperationResultStatusWire on OperationResultStatus {
  String get wireName => name;
}

OperationResultStatus decodeOperationResultStatus(Object? value) =>
    switch (asString(value, 'status')) {
      'applied' => OperationResultStatus.applied,
      'duplicate' => OperationResultStatus.duplicate,
      'conflict' => OperationResultStatus.conflict,
      'rejected' => OperationResultStatus.rejected,
      final value => throw FormatException(
        'Unknown operation result status "$value"',
      ),
    };

extension SubstitutionSourceWire on SubstitutionSource {
  String get wireName => switch (this) {
    SubstitutionSource.planVariant => 'plan_variant',
    SubstitutionSource.atlas => 'atlas',
  };
}

SubstitutionSource decodeSubstitutionSource(Object? value) => switch (asString(
  value,
  'source',
)) {
  'plan_variant' => SubstitutionSource.planVariant,
  'atlas' => SubstitutionSource.atlas,
  final value => throw FormatException('Unknown substitution source "$value"'),
};
