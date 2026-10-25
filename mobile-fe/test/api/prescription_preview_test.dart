import 'dart:convert';
import 'dart:io';

import 'package:agonez/src/api/prescription_preview.dart';
import 'package:agonez/src/features/home/exercise_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The live preview of session 31 (4 of 8 exercises analysed), with Atlas
  // peeks, alternatives and history trimmed.
  final preview = PrescriptionPreview.fromJson(
    jsonDecode(
          File(
            'test/fixtures/prescription_preview_session_31.json',
          ).readAsStringSync(),
        )
        as Map<String, Object?>,
  );

  test('parses every exercise of the live preview in order', () {
    expect(preview.exercises.map((exercise) => exercise.name), [
      'Bench Press',
      'Converging Incline Chest Press',
      'Low-to-High Cable Fly',
      'Dumbbell Overhead Press',
      'Cable Lateral Raise',
      'California Press',
      'Neck Curl',
      'Dead Hang',
    ]);
    expect(preview.exercises.map((exercise) => exercise.generated), [
      false,
      false,
      false,
      false,
      true,
      true,
      true,
      true,
    ]);
    final lateralRaise = preview.exercises[4];
    expect(lateralRaise.sets.map((set) => (set.loadKg, set.loadSource)), [
      (19.0, 'last_exposure'),
      (19.0, 'last_exposure'),
    ]);
  });

  test('rows note where generated loads come from', () {
    final rows = [
      for (final exercise in preview.exercises)
        ExerciseSummary.ofPreview(exercise),
    ];

    // Analysed exercises need no note, not even one without a load.
    expect(rows.take(4).map((row) => row.loads), everyElement(isNull));
    expect(rows[4].loads, PlannedLoads.lastSession);
    expect(rows[5].loads, PlannedLoads.lastSession);
    // Prescribed without sets: the row already says "no sets".
    expect(rows[6].loads, isNull);
    expect(rows[6].prescriptionLabel, isNull);
  });
}
