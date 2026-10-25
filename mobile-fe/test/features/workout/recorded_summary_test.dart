import 'dart:convert';

import 'package:agonez/src/api/atlas_models.dart';
import 'package:agonez/src/api/prescription_models.dart';
import 'package:agonez/src/app/app_providers.dart';
import 'package:agonez/src/design/design.dart';
import 'package:agonez/src/features/workout/recorded_summary.dart';
import 'package:agonez/src/features/workout/workout_recorded_screen.dart';
import 'package:agonez/src/l10n/generated/app_localizations.dart';
import 'package:agonez/src/storage/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/today_fixtures.dart';
import '../../support/workout_fixtures.dart';

void main() {
  // Planned: Bench (1), Row (2), Curl (3), Dip (4); three sets each.
  final prescription = _prescription(['Bench', 'Row', 'Curl', 'Dip']);

  test('each exercise carries how it departed from the plan', () {
    final rows = recordedExercises(
      prescription: prescription,
      exercises: [
        _exercise('bench', 1, position: 0, comment: 'elbow'),
        // Dip was done second ("Do next").
        _exercise('dip', 4, position: 1),
        _exercise(
          'row',
          2,
          position: 2,
          mode: 'substituted',
          actual: 'Machine Row',
        ),
        _exercise('curl', 3, position: 3, mode: 'skipped'),
        _exercise(
          'face',
          null,
          position: 4,
          mode: 'added',
          actual: 'Face Pull',
        ),
      ],
      sets: [
        _set('bench', 0, 80, 8),
        _set('bench', 1, 82.5, 6),
        for (var ordinal = 0; ordinal < 3; ordinal++) ...[
          _set('dip', ordinal, 0, 10),
          _set('row', ordinal, 60, 10),
        ],
        _set('face', 0, 20, 15),
      ],
    );

    expect(rows.map((row) => row.name), [
      'Bench',
      'Dip',
      'Machine Row',
      'Curl',
      'Face Pull',
    ]);
    expect(rows.map((row) => row.tags), [
      [RecordedTag.incomplete, RecordedTag.note],
      // Only the moved exercise, not the two it was moved past.
      [RecordedTag.reordered],
      [RecordedTag.substituted],
      [RecordedTag.skipped],
      [RecordedTag.unplanned],
    ]);
    expect(rows.first.sets, [
      (loadKg: 80.0, repetitions: 8),
      (loadKg: 82.5, repetitions: 6),
    ]);
  });

  test('a workout done as planned has no tags', () {
    final rows = recordedExercises(
      prescription: prescription,
      exercises: [
        for (final (index, id) in ['bench', 'row', 'curl', 'dip'].indexed)
          _exercise(id, index + 1, position: index),
      ],
      sets: [
        for (final id in ['bench', 'row', 'curl', 'dip'])
          for (var ordinal = 0; ordinal < 3; ordinal++)
            _set(id, ordinal, 50, 10),
      ],
    );

    expect(rows.every((row) => row.tags.isEmpty), isTrue);
  });

  testWidgets('the summary lists exercises with their sets and tags', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final workout = startedLegs().copyWith(
      lifecycle: 'completed',
      prescriptionJson: jsonEncode(prescription.toJson()),
    );
    final harness = TodayHarness();
    addTearDown(harness.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appRuntimeProvider.overrideWithValue(harness.runtime),
          workoutProvider(
            workout.workoutId,
          ).overrideWith((ref) => Stream.value(workout)),
          workoutExercisesProvider(workout.workoutId).overrideWith(
            (ref) async => [
              _exercise('bench', 1, position: 0),
              _exercise('row', 2, position: 1, mode: 'skipped'),
            ],
          ),
          workoutSetsProvider(workout.workoutId).overrideWith(
            (ref) => Stream.value([
              _set('bench', 0, 80, 8),
              _set('bench', 1, 82.5, 6),
              _set('bench', 2, 82.5, 6),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: AgonezTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WorkoutRecordedScreen(workoutId: workout.workoutId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bench'), findsOneWidget);
    expect(find.text('80×8 / 82.5×6 / 82.5×6'), findsOneWidget);
    expect(find.text('Row'), findsOneWidget);
    expect(find.text('SKIPPED'), findsOneWidget);
  });
}

WorkoutPrescription _prescription(List<String> names) => WorkoutPrescription(
  sessionId: fixturePrescription.sessionId,
  prescriptionId: fixturePrescription.prescriptionId,
  prescriptionVersion: fixturePrescription.prescriptionVersion,
  workoutUnitName: fixturePrescription.workoutUnitName,
  workoutTrackId: fixturePrescription.workoutTrackId,
  microcycle: fixturePrescription.microcycle,
  planComment: null,
  prescriptionComment: null,
  exercises: [
    for (final (index, name) in names.indexed)
      PrescriptionExercise(
        exercisePrescriptionId: index + 1,
        ordinal: index + 1,
        exerciseTrackId: index + 1,
        slot: fixturePrescriptionExercise.slot,
        exercise: ExerciseIdentity(
          id: index + 1,
          slug: name.toLowerCase(),
          name: name,
          fullName: name,
        ),
        variantLabel: null,
        planComment: null,
        prescriptionComment: null,
        loadStepKg: 2.5,
        defaultRestS: 120,
        sets: [
          for (var ordinal = 0; ordinal < 3; ordinal++)
            PrescriptionSet(
              setPrescriptionId: (index + 1) * 10 + ordinal,
              ordinal: ordinal,
              role: 'working',
              prescribedLoadKg: null,
              repMin: 8,
              repMax: 10,
              targetRir: 2,
              comment: null,
            ),
        ],
        alternatives: const [],
        history: fixturePrescriptionExercise.history,
        atlasPeek: fixturePrescriptionExercise.atlasPeek,
      ),
  ],
);

LocalExercise _exercise(
  String id,
  int? prescriptionId, {
  required int position,
  String mode = 'as_prescribed',
  String? actual,
  String? comment,
}) => LocalExercise(
  exercisePerformanceId: id,
  workoutId: 'workout-1',
  exercisePrescriptionId: prescriptionId,
  actualExerciseJson: actual == null
      ? null
      : jsonEncode(
          ExerciseIdentity(
            id: 900 + position,
            slug: actual.toLowerCase(),
            name: actual,
            fullName: actual,
          ).toJson(),
        ),
  performedOrdinal: position,
  mode: mode,
  comment: comment,
  serverRev: 0,
  localRev: 0,
  updatedAt: DateTime.utc(2026, 10, 19, 18),
);

LocalSet _set(String exercise, int ordinal, double load, int reps) => LocalSet(
  setPerformanceId: '$exercise-$ordinal',
  workoutId: 'workout-1',
  exercisePerformanceId: exercise,
  ordinal: ordinal,
  status: 'performed',
  loadKg: load,
  repetitions: reps,
  rir: 2,
  serverRev: 0,
  localRev: 0,
  updatedAt: DateTime.utc(2026, 10, 19, 18),
);
