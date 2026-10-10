import 'package:uuid/uuid.dart';

abstract final class AgonezIds {
  static const _uuid = Uuid();
  static String workout() => _uuid.v4();
  static String operation() => _uuid.v4();
  static String prescribedExercise(String workoutId, int prescriptionId) =>
      _uuid.v5(workoutId, 'ex:$prescriptionId');
  static String prescribedSet(String workoutId, int prescriptionId) =>
      _uuid.v5(workoutId, 'set:$prescriptionId');
}
