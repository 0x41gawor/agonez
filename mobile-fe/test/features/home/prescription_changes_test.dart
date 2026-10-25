import 'package:agonez/src/api/atlas_models.dart';
import 'package:agonez/src/api/prescription_models.dart';
import 'package:agonez/src/features/home/prescription_changes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/workout_fixtures.dart';

void main() {
  test('a changed load names the exercise, set and both loads', () {
    final changes = PrescriptionChanges.between(
      prescriptionWith([_set(0, 80), _set(1, 80), _set(2, 65)]),
      prescriptionWith([_set(0, 80), _set(1, 80), _set(2, 67.5)]),
    );

    expect(changes.other, 0);
    expect(changes.loads.single.exerciseName, 'Barbell squat');
    expect(changes.loads.single.setNumber, 3);
    expect(changes.loads.single.before, 65);
    expect(changes.loads.single.after, 67.5);
  });

  test('other differences are counted', () {
    final changes = PrescriptionChanges.between(
      prescriptionWith([_set(0, 80), _set(1, 80)]),
      prescriptionWith([_set(0, 80, repMax: 10), _set(1, 80), _set(2, 80)]),
    );

    // A wider rep range and an added set.
    expect(changes.loads, isEmpty);
    expect(changes.other, 2);
  });

  test('added and removed exercises are counted', () {
    final squat = prescriptionWith([_set(0, 80)]);
    final row = prescriptionWith(
      [_set(0, 60)],
      exercisePrescriptionId: 333,
      exercise: const ExerciseIdentity(
        id: 77,
        slug: 'row',
        name: 'Row',
        fullName: 'Row',
      ),
    );

    final changes = PrescriptionChanges.between(squat, row);

    expect(changes.other, 2);
  });

  test('the same prescription has no changes', () {
    final same = prescriptionWith([_set(0, 80), _set(1, 82.5)]);

    expect(PrescriptionChanges.between(same, same).isEmpty, isTrue);
  });
}

PrescriptionSet _set(int ordinal, double? load, {int repMax = 8}) =>
    PrescriptionSet(
      setPrescriptionId: 500 + ordinal,
      ordinal: ordinal,
      role: 'working',
      prescribedLoadKg: load,
      repMin: 6,
      repMax: repMax,
      targetRir: 2,
      comment: null,
    );
