import 'package:uuid/uuid.dart';

/// Centralizes every client identity used by the mobile execution protocol.
/// Prescribed performance identities are UUIDv5 values in the workout UUID
/// namespace; genuinely new facts and operations use UUIDv4.
class WorkoutIds {
  const WorkoutIds({Uuid uuid = const Uuid()}) : _uuid = uuid;

  final Uuid _uuid;

  String newWorkoutId() => _uuid.v4();

  String prescribedExercisePerformanceId(
    String workoutId,
    int exercisePrescriptionId,
  ) => _uuid.v5(workoutId, 'ex:$exercisePrescriptionId');

  String prescribedSetPerformanceId(String workoutId, int setPrescriptionId) =>
      _uuid.v5(workoutId, 'set:$setPrescriptionId');

  String newAdditionalEntityId() => _uuid.v4();

  String newOperationId() => _uuid.v4();
}
