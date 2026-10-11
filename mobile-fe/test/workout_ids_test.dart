import 'package:agonez/src/workout/workout_ids.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ids = WorkoutIds();
  const workoutId = '3d594650-3436-4fd4-9e14-60f7c27e17b8';

  test('prescribed exercise and set ids are stable UUIDv5 identities', () {
    final exercise = ids.prescribedExercisePerformanceId(workoutId, 42);
    final sameExercise = ids.prescribedExercisePerformanceId(workoutId, 42);
    final anotherExercise = ids.prescribedExercisePerformanceId(workoutId, 43);
    final set = ids.prescribedSetPerformanceId(workoutId, 42);

    expect(exercise, sameExercise);
    expect(exercise, isNot(anotherExercise));
    expect(exercise, isNot(set));
    expect(exercise[14], '5');
  });

  test('unplanned facts and operations use new UUIDv4 identities', () {
    final first = ids.newAdditionalEntityId();
    final second = ids.newAdditionalEntityId();
    final op = ids.newOperationId();

    expect(first, isNot(second));
    expect(first[14], '4');
    expect(op[14], '4');
  });
}
