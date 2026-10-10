import 'package:agonez/domain/ids.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prescribed identities are deterministic and namespaced', () {
    const workout = '6f4c3c1e-9b0d-4b55-8a3e-0d6d2f4b7a10';
    expect(
      AgonezIds.prescribedSet(workout, 42),
      AgonezIds.prescribedSet(workout, 42),
    );
    expect(
      AgonezIds.prescribedSet(workout, 42),
      isNot(AgonezIds.prescribedExercise(workout, 42)),
    );
  });
}
