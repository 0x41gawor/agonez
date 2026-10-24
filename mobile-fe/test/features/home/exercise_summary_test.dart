import 'package:agonez/src/api/prescription_models.dart';
import 'package:agonez/src/features/home/exercise_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/workout_fixtures.dart';

void main() {
  test('reads as sets × rep range, without loads', () {
    final summary = ExerciseSummary.of(
      _exercise([_set(80, 6, 8), _set(80, 6, 8), _set(80, 6, 8)]),
    );

    expect(summary.name, 'Barbell squat');
    expect(summary.prescriptionLabel, '3 × 6–8');
  });

  test('a single rep target reads as one number', () {
    final summary = ExerciseSummary.of(
      _exercise([_set(70, 5, 5), _set(72.5, 5, 5), _set(75, 5, 5)]),
    );

    expect(summary.prescriptionLabel, '3 × 5');
  });

  test('the rep range spans every working set', () {
    final summary = ExerciseSummary.of(
      _exercise([_set(null, 10, 12), _set(null, 8, 10)]),
    );

    expect(summary.prescriptionLabel, '2 × 8–12');
  });

  test('an exercise prescribed without sets has no label', () {
    expect(ExerciseSummary.of(_exercise([])).prescriptionLabel, isNull);
  });

  test('ramp-up sets count but do not widen the rep range', () {
    final summary = ExerciseSummary.of(
      _exercise([
        _set(40, 10, 10, role: 'rampup'),
        _set(80, 6, 8),
        _set(80, 6, 8),
      ]),
    );

    expect(summary.prescriptionLabel, '3 × 6–8');
  });
}

PrescriptionSet _set(
  double? load,
  int repMin,
  int repMax, {
  String role = 'working',
}) => PrescriptionSet(
  setPrescriptionId: 1,
  ordinal: 0,
  role: role,
  prescribedLoadKg: load,
  repMin: repMin,
  repMax: repMax,
  targetRir: 2,
  comment: null,
);

PrescriptionExercise _exercise(List<PrescriptionSet> sets) {
  final base = fixturePrescriptionExercise;
  return PrescriptionExercise(
    exercisePrescriptionId: base.exercisePrescriptionId,
    ordinal: base.ordinal,
    exerciseTrackId: base.exerciseTrackId,
    slot: base.slot,
    exercise: base.exercise,
    variantLabel: base.variantLabel,
    planComment: base.planComment,
    prescriptionComment: base.prescriptionComment,
    loadStepKg: base.loadStepKg,
    defaultRestS: base.defaultRestS,
    sets: sets,
    alternatives: base.alternatives,
    history: base.history,
    atlasPeek: base.atlasPeek,
  );
}
